import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createHmac } from 'https://deno.land/std@0.168.0/node/crypto.ts'

const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

function asString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : undefined
}

async function logAudit(
  supabase: ReturnType<typeof createClient>,
  action: string,
  details: Record<string, unknown>,
) {
  try {
    await supabase.from('audit_log').insert({
      action,
      target_type: 'payment',
      details,
    })
  } catch (_) {
    // Keep webhook resilient even if audit logging fails.
  }
}

serve(async (req) => {
  // Only Paystack POST calls are accepted — no CORS needed (server-to-server)
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  if (!PAYSTACK_SECRET || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return new Response('Server Misconfigured', { status: 500 })
  }

  const rawBody = await req.text()

  // Verify the webhook signature to prevent spoofed events
  const signature = req.headers.get('x-paystack-signature') ?? ''
  const expectedSignature = createHmac('sha512', PAYSTACK_SECRET)
    .update(rawBody)
    .digest('hex')

  if (signature !== expectedSignature) {
    console.warn('Invalid Paystack webhook signature')
    return new Response('Unauthorized', { status: 401 })
  }

  let event: Record<string, unknown>
  try {
    event = JSON.parse(rawBody)
  } catch {
    return new Response('Invalid JSON', { status: 400 })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const eventType = asString(event.event)
  const data = (event.data ?? {}) as Record<string, unknown>

  try {
    switch (eventType) {
      case 'charge.success': {
        const reference = asString(data.reference)
        if (!reference) break

        const { data: payment } = await supabase
          .from('payments')
          .select('id, status, appointment_id, doctor_id')
          .eq('gateway_reference', reference)
          .maybeSingle()

        if (!payment) {
          await logAudit(supabase, 'webhook_charge_success_unknown_payment', {
            reference,
            amount_ghs: Number(data.amount ?? 0) / 100,
          })
          break
        }

        const now = new Date().toISOString()
        const alreadyCompleted = payment.status === 'completed'
        if (!alreadyCompleted) {
          await supabase
            .from('payments')
            .update({
              status: 'completed',
              payout_status: 'pending',
              gateway_response: data,
              completed_at: now,
            })
            .eq('id', payment.id)
        }

        const meta = (data.metadata ?? {}) as Record<string, unknown>
        const appointmentId =
          asString(meta.appointment_id) ?? asString(payment.appointment_id)
        const doctorId = asString(meta.doctor_id) ?? asString(payment.doctor_id)

        if (appointmentId) {
          await supabase
            .from('appointments')
            .update({ status: 'confirmed' })
            .eq('id', appointmentId)
        }

        if (doctorId && appointmentId && !alreadyCompleted) {
          await supabase.from('notifications').insert({
            user_id: doctorId,
            title: 'Booking Confirmed',
            message: 'Payment received. Your appointment is confirmed.',
            type: 'payment',
            is_read: false,
            target_role: 'doctor',
          })
        }

        await logAudit(supabase, 'webhook_charge_success', {
          reference,
          amount_ghs: Number(data.amount ?? 0) / 100,
          channel: data.channel,
          appointment_id: appointmentId,
          was_already_completed: alreadyCompleted,
        })
        break
      }

      case 'charge.failed': {
        const reference = asString(data.reference)
        if (!reference) break

        const { data: payment } = await supabase
          .from('payments')
          .select('id, status')
          .eq('gateway_reference', reference)
          .maybeSingle()

        if (!payment) break
        if (payment.status !== 'completed' && payment.status !== 'refunded') {
          await supabase
            .from('payments')
            .update({
              status: 'failed',
              gateway_response: data,
            })
            .eq('id', payment.id)
        }

        await logAudit(supabase, 'webhook_charge_failed', {
          reference,
          gateway_response: data.gateway_response,
        })
        break
      }

      case 'refund.processed': {
        const reference = asString(data.transaction_reference ?? data.reference)
        if (!reference) break

        const now = new Date().toISOString()
        const { data: payment } = await supabase
          .from('payments')
          .select('id')
          .eq('gateway_reference', reference)
          .maybeSingle()

        if (!payment) break

        await supabase
          .from('payments')
          .update({
            status: 'refunded',
            refunded_at: now,
            payout_status: 'on_hold',
            gateway_response: data,
          })
          .eq('id', payment.id)

        await supabase
          .from('refunds')
          .update({
            status: 'refunded',
            refunded_at: now,
            gateway_reference: reference,
            updated_at: now,
          })
          .eq('payment_id', payment.id)

        await logAudit(supabase, 'webhook_refund_processed', {
          reference,
          amount_ghs: Number(data.amount ?? 0) / 100,
        })
        break
      }

      case 'transfer.success': {
        const transferCode = asString(data.transfer_code)
        if (!transferCode) break
        const now = new Date().toISOString()

        await supabase
          .from('payout_batches')
          .update({ status: 'completed', completed_at: now })
          .eq('transfer_code', transferCode)

        await supabase
          .from('payouts')
          .update({ status: 'paid', paid_at: now, updated_at: now })
          .eq('transfer_code', transferCode)

        await logAudit(supabase, 'webhook_transfer_success', {
          transfer_code: transferCode,
        })
        break
      }

      case 'transfer.failed': {
        const transferCode = asString(data.transfer_code)
        if (!transferCode) break
        const reason = asString(data.reason) ?? asString(data.failure_reason)
        const now = new Date().toISOString()

        await supabase
          .from('payout_batches')
          .update({ status: 'failed', failure_reason: reason })
          .eq('transfer_code', transferCode)

        await supabase
          .from('payouts')
          .update({
            status: 'failed',
            failure_reason: reason,
            updated_at: now,
          })
          .eq('transfer_code', transferCode)

        await logAudit(supabase, 'webhook_transfer_failed', {
          transfer_code: transferCode,
          reason,
        })
        break
      }

      default:
        await logAudit(supabase, 'webhook_unhandled_event', {
          event_type: eventType ?? 'unknown',
        })
        break
    }
  } catch (error) {
    console.error('Webhook processing error:', error)
    await logAudit(supabase, 'webhook_processing_error', {
      event_type: eventType ?? 'unknown',
      error: String(error),
    })
  }

  // Always return 200 so Paystack doesn't retry
  return new Response('ok', { status: 200 })
})
