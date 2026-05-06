import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function asString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : undefined
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const reference = asString((body as Record<string, unknown>).reference)
  if (!reference) {
    return new Response(JSON.stringify({ error: 'reference is required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch local payment record first — used for idempotency and as metadata fallback
  const { data: existingPayment } = await supabaseAdmin
    .from('payments')
    .select('id, status, user_id, appointment_id, doctor_id, amount, currency')
    .eq('gateway_reference', reference)
    .maybeSingle()

  // Guard: only the payment owner may verify
  if (existingPayment && existingPayment.user_id !== user.id) {
    return new Response(JSON.stringify({ error: 'Forbidden' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Idempotent fast-path: already completed upstream (e.g. via webhook)
  if (existingPayment?.status === 'completed') {
    return new Response(
      JSON.stringify({
        verified: true,
        reference,
        amount: existingPayment.amount,
        currency: existingPayment.currency ?? 'GHS',
        appointment_id: existingPayment.appointment_id,
        idempotent: true,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  // Call Paystack to confirm the transaction status
  const paystackRes = await fetch(
    `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
    { headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` } },
  )
  const paystackData = await paystackRes.json()
  const txn = paystackData.data as Record<string, unknown> | null

  if (!paystackData.status || txn?.status !== 'success') {
    // Only mark failed if the payment has not already been completed/refunded
    const canMarkFailed = !existingPayment ||
      (existingPayment.status !== 'completed' && existingPayment.status !== 'refunded')

    if (canMarkFailed && existingPayment) {
      await supabaseAdmin
        .from('payments')
        .update({ status: 'failed', gateway_response: paystackData })
        .eq('id', existingPayment.id)
    }

    return new Response(
      JSON.stringify({
        verified: false,
        status: asString(txn?.status) ?? 'failed',
        message: asString(txn?.gateway_response) ?? asString(paystackData.message) ?? 'Payment not successful',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  const meta = (txn.metadata ?? {}) as Record<string, unknown>
  // Prefer DB values as authoritative fallback when metadata is missing
  const appointmentId =
    asString(meta.appointment_id) ?? asString(existingPayment?.appointment_id)
  const doctorId =
    asString(meta.doctor_id) ?? asString(existingPayment?.doctor_id)
  const amountGhs = Number(txn.amount ?? 0) / 100
  const now = new Date().toISOString()

  // Mark payment completed and queue for payout
  const { error: updateError } = await supabaseAdmin
    .from('payments')
    .update({
      status: 'completed',
      payout_status: 'pending',
      gateway_response: txn,
      completed_at: now,
    })
    .eq('gateway_reference', reference)
    .eq('user_id', user.id)

  if (updateError) {
    console.error('Payment update failed:', updateError)
    return new Response(JSON.stringify({ error: 'Failed to update payment record' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Confirm appointment
  if (appointmentId) {
    await supabaseAdmin
      .from('appointments')
      .update({ status: 'confirmed' })
      .eq('id', appointmentId)
  }

  // Notify doctor of confirmed booking
  if (doctorId) {
    await supabaseAdmin.from('notifications').insert({
      user_id: doctorId,
      title: 'New Confirmed Booking',
      message: `Payment of GHS ${amountGhs.toFixed(2)} received. Your appointment is confirmed.`,
      type: 'payment',
      target_role: 'doctor',
      is_read: false,
    })
  }

  // Notify patient of payment success
  await supabaseAdmin.from('notifications').insert({
    user_id: user.id,
    title: 'Payment Successful',
    message: `Your payment of GHS ${amountGhs.toFixed(2)} was successful${appointmentId ? ' and your appointment is confirmed' : ''}.`,
    type: 'payment',
    target_role: 'patient',
    is_read: false,
  })

  // Audit log — use performed_by (not admin_id) since this is a patient action
  await supabaseAdmin.from('audit_log').insert({
    performed_by: user.id,
    action: 'payment_verified',
    target_type: 'payment',
    details: {
      reference,
      amount_ghs: amountGhs,
      currency: txn.currency,
      channel: txn.channel,
      appointment_id: appointmentId,
    },
  })

  return new Response(
    JSON.stringify({
      verified: true,
      reference,
      amount: amountGhs,
      currency: txn.currency,
      channel: txn.channel,
      appointment_id: appointmentId,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  )
})
