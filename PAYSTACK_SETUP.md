# Paystack Integration Setup Guide

## Overview
This guide walks you through setting up the complete Paystack payment integration with automatic doctor payouts.

**What it does:**
- Patients pay via Paystack checkout in the Flutter app
- Platform commission is automatically deducted
- Doctor earnings are automatically transferred to their mobile money account
- Real-time tracking of payments and payouts in Supabase

---

## Step 1: Verify Your Paystack Account

Your Paystack API Key is already configured:
- **Public Key**: `pk_live_e4fb8daa0b8b1a097fb004e672cf7fa5bb524d77`
- **Secret Key**: `PAYSTACK_SECRET_KEY_PLACEHOLDER`

### Verify at: https://dashboard.paystack.com/settings/developer

---

## Step 2: Deploy Supabase Edge Function

The webhook handler automatically processes payments and sends doctor payouts.

### Deploy the function:
```bash
cd /Users/codestcode/Desktop/doctor-consultation-app
supabase functions deploy paystack-webhook
```

### Get your function URL:
```bash
supabase functions list
# You'll see: paystack-webhook URL
```

### Example output:
```
paystack-webhook    https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/paystack-webhook
```

---

## Step 3: Configure Paystack Webhook

1. **Go to Paystack Dashboard**: https://dashboard.paystack.com/settings/developer
2. **Find "API Keys & Webhooks"** section
3. **Add Webhook URL**:
   - URL: `https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/paystack-webhook`
   - Active: Toggle ON
   - Events to receive:
     - ✅ `charge.success`
     - ✅ `transfer.success`
     - ✅ `transfer.failed`

4. **Save Webhook**

---

## Step 4: Database Migration

Run the migration that adds Paystack tables:

```bash
# This already includes:
# - payouts table (tracks doctor payouts)
# - paystack_transactions table (logs all API interactions)
# - Mobile money fields on profiles table

supabase db push
```

---

## Step 5: Doctor Setup - Add Mobile Money

Doctors need to link their mobile money account to receive payments.

### Doctor Flow in App:
1. Open app and login as doctor
2. Navigate to **Settings / Profile**
3. Tap **"Setup Mobile Money"**
4. Select provider (MTN/Vodafon/Airtel/Tigo)
5. Enter mobile number
6. Tap "Link Mobile Money Account"

### Supported Providers:
- **MTN Ghana** (Bank Code: 170057)
- **Vodafon Ghana** (Bank Code: 170014)
- **Airtel Ghana** (Bank Code: 170015)
- **Tigo Ghana** (Bank Code: 170011)

> Can be extended to other countries by updating bank codes in `PaystackService._getBankCodeForProvider()`

---

## Step 6: Commission Settings

Configure how much commission the platform takes:

### In Admin Dashboard:
1. Navigate to **Commission Settings**
2. Create a new commission rule:
   - Commission Type: `percentage` (or `fixed`)
   - Rate: `20%` (example)
   - Applies to: All doctors or specific doctor
3. Save

**Example Scenario:**
- Patient pays: GHS 100
- Platform takes (20%): GHS 20
- Doctor receives: GHS 80 → automatically sent to mobile money

---

## Step 7: Test Payment Flow

### Patient Pays:
1. Patient selects doctor for consultation
2. Tap **"Book Appointment"**
3. Tap **"Proceed to Payment"**
4. See payment breakdown:
   - Consultation Fee: GHS 50
   - Platform Commission: GHS 10 (20%)
   - Doctor Receives: GHS 40
5. Tap **"Proceed to Payment"**
6. Complete Paystack checkout (use test card)

### Test Card:
- **Card Number**: `4084 0343 0343 0343`
- **Expiry**: `12/25`
- **CVV**: `123`

### Automatic Flow:
1. ✅ Payment succeeds on Paystack
2. ✅ Webhook received by Edge Function
3. ✅ `paystack_transactions` record created
4. ✅ `payments` record created
5. ✅ Commission calculated from settings
6. ✅ `payouts` record created
7. ✅ Transfer initiated to doctor's mobile money
8. ✅ Doctor receives notification

---

## Step 8: Monitor Transactions

### Check Payments:
```sql
SELECT * FROM public.payments 
WHERE status = 'completed' 
ORDER BY created_at DESC;
```

### Check Payouts:
```sql
SELECT * FROM public.payouts 
ORDER BY created_at DESC;
```

### Check Paystack Transactions:
```sql
SELECT * FROM public.paystack_transactions 
ORDER BY created_at DESC;
```

---

## Troubleshooting

### Payment shows as pending:
- Check Supabase webhook logs: `supabase functions logs paystack-webhook`
- Verify Paystack webhook is configured correctly
- Check firewall isn't blocking webhook

### Doctor not receiving money:
1. Verify doctor has mobile money account linked
2. Check payout status: `SELECT * FROM payouts WHERE status = 'failed'`
3. Check failure reason in `failure_reason` column
4. Ensure Paystack account has sufficient balance

### Commission not calculated:
1. Check commission settings exist: `SELECT * FROM commission_settings`
2. Verify `is_active = true` and date ranges are correct
3. Doctor can have specific commission or use platform-wide setting

### Mobile money setup fails:
1. Verify phone number format (no country code)
2. Ensure provider matches network
3. Check Paystack account balance for batch payouts

---

## Security Best Practices

✅ **Done:**
- Secret keys stored in environment variables
- Paystack webhook signature verified
- RLS policies restrict data access
- Edge Function uses service role for database

✅ **Recommended:**
1. Never share your Paystack secret key
2. Regularly rotate API keys on Paystack dashboard
3. Monitor webhook logs for suspicious activity
4. Set transaction limits on Paystack account
5. Use Paystack test environment for staging

---

## File References

- **Database Migration**: `migrations/014_create_commission_settings.sql`
- **Paystack Service**: `lib/services/paystack_service.dart`
- **Payment Screen**: `lib/screens/payment_screen.dart`
- **Doctor Mobile Money Setup**: `lib/screens/doctor_mobile_money_setup_screen.dart`
- **Webhook Handler**: `supabase/functions/paystack-webhook/index.ts`

---

## Next Steps

1. ✅ Deploy Edge Function
2. ✅ Configure Paystack Webhook
3. ✅ Update commission settings
4. ✅ Have doctor setup mobile money
5. ✅ Test full payment flow
6. ✅ Monitor payouts

**Questions?** Check Paystack docs: https://paystack.com/docs/payments/
