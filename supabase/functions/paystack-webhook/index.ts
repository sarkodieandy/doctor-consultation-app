import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.1";

const PAYSTACK_SECRET = "PAYSTACK_SECRET_KEY_PLACEHOLDER";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Verify Paystack webhook signature
function verifyPaystackSignature(
  signature: string,
  body: string
): boolean {
  const hash = crypto
    .subtle.digestSync("SHA-256", new TextEncoder().encode(body + PAYSTACK_SECRET))
    .toString()
    .toLowerCase();

  return hash === signature.toLowerCase();
}

// Handle charge.success event
async function handleChargeSuccess(data: Record<string, any>) {
  try {
    const reference = data.reference;
    const email = data.customer?.email;
    const amount = data.amount / 100; // Convert from kobo
    const metadata = data.metadata || {};

    // Update transaction
    await supabase
      .from("paystack_transactions")
      .update({
        status: "completed",
        response: data,
        updated_at: new Date().toISOString(),
      })
      .eq("reference", reference);

    // Update or create payment record
    const { data: existingPayment } = await supabase
      .from("payments")
      .select()
      .eq("paystack_reference", reference)
      .single();

    if (!existingPayment) {
      // Get commission for this doctor
      const doctorId = metadata.doctor_id;
      const { data: commissionSettings } = await supabase
        .from("commission_settings")
        .select()
        .eq("is_active", true)
        .or(`applies_to_all.eq.true,doctor_id.eq.${doctorId}`)
        .order("doctor_id", { ascending: false })
        .order("effective_date", { ascending: false })
        .limit(1);

      let commissionAmount = 0;
      if (commissionSettings && commissionSettings.length > 0) {
        const commission = commissionSettings[0];
        if (commission.commission_type === "percentage") {
          commissionAmount = amount * (commission.commission_rate / 100);
        } else {
          commissionAmount = commission.commission_rate;
        }

        if (commission.min_commission) {
          commissionAmount = Math.max(commissionAmount, commission.min_commission);
        }
        if (commission.max_commission) {
          commissionAmount = Math.min(commissionAmount, commission.max_commission);
        }
      }

      const doctorEarnings = amount - commissionAmount;

      // Insert payment
      await supabase.from("payments").insert({
        doctor_id: metadata.doctor_id,
        patient_id: metadata.patient_id,
        consultation_id: metadata.consultation_id,
        amount: amount,
        commission_amount: commissionAmount,
        doctor_earnings: doctorEarnings,
        status: "completed",
        payment_method: "paystack",
        paystack_reference: reference,
        created_at: new Date().toISOString(),
      });

      // Create payout to doctor
      const { data: doctor } = await supabase
        .from("profiles")
        .select("mobile_money_number,mobile_money_provider,paystack_recipient_code")
        .eq("id", metadata.doctor_id)
        .single();

      if (doctor?.paystack_recipient_code) {
        // Initiate transfer to doctor
        const transferRes = await fetch("https://api.paystack.co/transfer", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${PAYSTACK_SECRET}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            source: "balance",
            recipient: doctor.paystack_recipient_code,
            amount: Math.round(doctorEarnings * 100), // Convert to kobo
            reference: `payout_${reference}_${Date.now()}`,
            reason: "Doctor Earnings - Consultation Payment",
          }),
        });

        const transferData = await transferRes.json();

        if (transferData.status) {
          // Record payout
          await supabase.from("payouts").insert({
            doctor_id: metadata.doctor_id,
            payment_id: reference,
            amount: doctorEarnings,
            commission_amount: commissionAmount,
            status: "processing",
            paystack_transfer_code: transferData.data.transfer_code,
            paystack_reference: transferData.data.reference,
            mobile_money_provider: doctor.mobile_money_provider,
            mobile_money_number: doctor.mobile_money_number,
            created_at: new Date().toISOString(),
          });

          // Log transfer transaction
          await supabase.from("paystack_transactions").insert({
            reference: transferData.data.reference,
            type: "transfer",
            amount: doctorEarnings,
            status: "processing",
            payout_id: reference,
            metadata: {
              doctor_id: metadata.doctor_id,
              transfer_code: transferData.data.transfer_code,
            },
            created_at: new Date().toISOString(),
          });
        } else {
          // Log failed transfer
          await supabase.from("payouts").insert({
            doctor_id: metadata.doctor_id,
            payment_id: reference,
            amount: doctorEarnings,
            commission_amount: commissionAmount,
            status: "failed",
            mobile_money_provider: doctor.mobile_money_provider,
            mobile_money_number: doctor.mobile_money_number,
            failure_reason: transferData.message,
            created_at: new Date().toISOString(),
          });
        }
      }
    }

    console.log("Charge success processed for reference:", reference);
  } catch (error) {
    console.error("Error handling charge success:", error);
    throw error;
  }
}

// Handle transfer.success event
async function handleTransferSuccess(data: Record<string, any>) {
  try {
    const reference = data.reference;
    const transferCode = data.transfer_code;

    // Update payout status
    await supabase
      .from("payouts")
      .update({
        status: "completed",
        updated_at: new Date().toISOString(),
      })
      .eq("paystack_reference", reference);

    // Update transaction
    await supabase
      .from("paystack_transactions")
      .update({
        status: "completed",
        response: data,
        updated_at: new Date().toISOString(),
      })
      .eq("reference", reference);

    console.log("Transfer success processed for reference:", reference);
  } catch (error) {
    console.error("Error handling transfer success:", error);
    throw error;
  }
}

// Handle transfer.failed event
async function handleTransferFailed(data: Record<string, any>) {
  try {
    const reference = data.reference;

    // Update payout status
    await supabase
      .from("payouts")
      .update({
        status: "failed",
        failure_reason: data.reason || "Transfer failed",
        updated_at: new Date().toISOString(),
      })
      .eq("paystack_reference", reference);

    // Update transaction
    await supabase
      .from("paystack_transactions")
      .update({
        status: "failed",
        response: data,
        updated_at: new Date().toISOString(),
      })
      .eq("reference", reference);

    console.log("Transfer failed for reference:", reference);
  } catch (error) {
    console.error("Error handling transfer failed:", error);
    throw error;
  }
}

serve(async (req) => {
  try {
    // Only accept POST requests
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const body = await req.text();
    const signature = req.headers.get("x-paystack-signature");

    // Verify signature
    if (!signature || !verifyPaystackSignature(signature, body)) {
      console.warn("Invalid Paystack signature");
      return new Response("Invalid signature", { status: 403 });
    }

    const payload = JSON.parse(body);
    const event = payload.event;
    const data = payload.data;

    console.log("Processing Paystack webhook event:", event);

    // Route to appropriate handler
    switch (event) {
      case "charge.success":
        await handleChargeSuccess(data);
        break;
      case "transfer.success":
        await handleTransferSuccess(data);
        break;
      case "transfer.failed":
        await handleTransferFailed(data);
        break;
      default:
        console.log("Unhandled event:", event);
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
