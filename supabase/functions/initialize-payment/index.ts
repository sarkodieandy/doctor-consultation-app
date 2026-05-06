import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Platform takes 15% of every consultation fee
const PLATFORM_FEE_PERCENT = 0.15

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function paystackChannels(method: string): string[] {
  const map: Record<string, string[]> = {
    mobile_money: ['mobile_money'],
    card: ['card'],
    bank_transfer: ['bank_transfer'],
    ussd: ['ussd'],
  }
  return map[method] ?? ['mobile_money', 'card', 'bank_transfer', 'ussd']
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

  // Validate the calling user
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

  const { appointmentId, amount, currency = 'GHS', paymentMethod = 'mobile_money', doctorId } = body as {
    appointmentId: string
    amount: number
    currency?: string
    paymentMethod?: string
    doctorId: string
  }

  if (!appointmentId || !amount || !doctorId) {
    return new Response(JSON.stringify({ error: 'appointmentId, amount, and doctorId are required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch user email from profiles (Paystack requires a real email)
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('email, first_name, last_name')
    .eq('id', user.id)
    .maybeSingle()

  const email = profile?.email ?? user.email
  if (!email) {
    return new Response(JSON.stringify({ error: 'User email not found' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fee split
  const platformFee = Math.round(amount * PLATFORM_FEE_PERCENT * 100) / 100
  const doctorAmount = Math.round((amount - platformFee) * 100) / 100

  // Deterministic reference: one per appointment per user — safe to retry
  const reference = `ps_${appointmentId}_${user.id.slice(0, 8)}`

  // Call Paystack Transaction Initialize
  // Paystack amounts are in the lowest currency unit (pesewas for GHS)
  const paystackBody = {
    email,
    amount: Math.round(amount * 100), // pesewas
    currency,
    reference,
    callback_url: 'docconsult://payment/callback',
    channels: paystackChannels(paymentMethod),
    metadata: {
      appointment_id: appointmentId,
      user_id: user.id,
      doctor_id: doctorId,
      platform_fee: platformFee,
      doctor_amount: doctorAmount,
      payment_method: paymentMethod,
      custom_fields: [
        { display_name: 'Appointment', variable_name: 'appointment_id', value: appointmentId },
        { display_name: 'Doctor', variable_name: 'doctor_id', value: doctorId },
      ],
    },
  }

  const paystackRes = await fetch('https://api.paystack.co/transaction/initialize', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${PAYSTACK_SECRET}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(paystackBody),
  })

  const paystackData = await paystackRes.json()

  if (!paystackData.status) {
    console.error('Paystack init failed:', paystackData)
    return new Response(JSON.stringify({ error: paystackData.message ?? 'Paystack initialization failed' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Upsert the pending payment record — safe to retry if client calls twice
  const { data: existingPayment } = await supabaseAdmin
    .from('payments')
    .select('id, status, gateway_reference')
    .eq('gateway_reference', reference)
    .maybeSingle()

  // If already completed, return the existing authorization_url from Paystack directly
  if (existingPayment?.status === 'completed') {
    return new Response(
      JSON.stringify({
        reference: existingPayment.gateway_reference,
        authorization_url: paystackData.data?.authorization_url ?? null,
        access_code: paystackData.data?.access_code ?? null,
        payment_id: existingPayment.id,
        idempotent: true,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  let payment: { id: string }
  if (existingPayment) {
    payment = existingPayment
  } else {
    const { data: insertedPayment, error: dbError } = await supabaseAdmin
      .from('payments')
      .insert({
        user_id: user.id,
        doctor_id: doctorId,
        appointment_id: appointmentId,
        amount,
        currency,
        status: 'pending',
        payment_method: paymentMethod,
        gateway_reference: reference,
        platform_fee: platformFee,
        doctor_amount: doctorAmount,
        payout_status: 'not_ready',
      })
      .select('id')
      .single()

    if (dbError) {
      console.error('DB insert failed:', dbError)
      return new Response(JSON.stringify({ error: 'Failed to create payment record' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    payment = insertedPayment
  }

  return new Response(
    JSON.stringify({
      reference,
      authorization_url: paystackData.data.authorization_url,
      access_code: paystackData.data.access_code,
      payment_id: payment.id,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  )
})
