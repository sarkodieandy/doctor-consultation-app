# Remove Mock Data - Complete Guide

## What's Been Done ✅

### 1. **Flutter App - Mock Data Removed**
- ✅ `lib/screens/doctor/doctor_dashboard_screen.dart` - Hardcoded appointment cards removed
- ✅ `lib/screens/doctor/doctor_earnings_screen.dart` - Mock earnings data removed, now shows "No Earnings Yet"
- ✅ `lib/screens/doctor/doctor_appointments_screen.dart` - Mock appointment list replaced with empty array

### 2. **Next: Remove Test Accounts from Database**

Run this migration in Supabase to delete the test patient and doctor accounts:

---

## Step 1: Run the Database Migration

1. **Open** [Supabase Dashboard](https://app.supabase.com)
2. **Go to** SQL Editor
3. **Copy and run** this migration:

```sql
-- Remove seed test data migration
-- This deletes patient@test.com and doctor@test.com test accounts
-- Keeps admin@test.com intact

BEGIN;

-- 1. Get the UUIDs for test accounts
DO $$
DECLARE
  patient_uid UUID;
  doctor_uid UUID;
BEGIN
  -- Find UUIDs
  SELECT id INTO patient_uid FROM auth.users WHERE email = 'patient@test.com' LIMIT 1;
  SELECT id INTO doctor_uid FROM auth.users WHERE email = 'doctor@test.com' LIMIT 1;
  
  -- Delete from all related tables first (due to foreign keys)
  DELETE FROM public.appointments WHERE user_id = patient_uid OR doctor_id = doctor_uid;
  DELETE FROM public.payments WHERE user_id = patient_uid OR doctor_id = doctor_uid;
  DELETE FROM public.reviews WHERE patient_id = patient_uid OR doctor_id = doctor_uid;
  DELETE FROM public.prescriptions WHERE patient_id = patient_uid OR doctor_id = doctor_uid;
  DELETE FROM public.health_records WHERE user_id = patient_uid;
  DELETE FROM public.doctor_schedules WHERE doctor_id = doctor_uid;
  DELETE FROM public.consultations WHERE patient_id = patient_uid OR doctor_id = doctor_uid;
  DELETE FROM public.chat_sessions WHERE user1_id = patient_uid OR user2_id = patient_uid OR user1_id = doctor_uid OR user2_id = doctor_uid;
  DELETE FROM public.notifications WHERE user_id = patient_uid OR user_id = doctor_uid;
  DELETE FROM public.doctor_verifications WHERE doctor_id = doctor_uid;
  DELETE FROM public.doctors WHERE profile_id = doctor_uid;
  
  -- Delete profiles
  DELETE FROM public.profiles WHERE id = patient_uid;
  DELETE FROM public.profiles WHERE id = doctor_uid;
  
  -- Delete from auth.identities
  DELETE FROM auth.identities WHERE user_id = patient_uid OR user_id = doctor_uid;
  
  -- Delete from auth.users
  DELETE FROM auth.users WHERE id = patient_uid OR id = doctor_uid;
  
  RAISE NOTICE 'Test accounts deleted: patient@test.com, doctor@test.com';
  RAISE NOTICE 'All related data removed from appointments, payments, reviews, etc.';
END $$;

-- Verify deletion
SELECT 'Remaining auth users:' as status, COUNT(*) as count FROM auth.users WHERE email IN ('patient@test.com', 'doctor@test.com');

COMMIT;
```

4. **Click** "Run" button
5. **Verify** - you should see:
   ```
   ✓ Test accounts deleted: patient@test.com, doctor@test.com
   ✓ All related data removed from appointments, payments, reviews, etc.
   ✓ Remaining auth users: 0
   ```

---

## Step 2: Verify Deletion

Go to **Supabase Dashboard** → **Authentication** → **Users**

You should only see:
- ✅ `admin@test.com` (KEEP THIS)
- ❌ No `patient@test.com` (DELETED)
- ❌ No `doctor@test.com` (DELETED)

---

## Step 3: Test Fresh Signups

Now you can test real signup flows:

### **Test Patient Signup:**
1. Open the Flutter mobile app
2. Click "Sign Up" → Select "Patient"
3. Create a new account with a new email
4. Add profile picture
5. Create account
6. Login and browse doctors

### **Test Doctor Signup:**
1. Click "Sign Up" → Select "Doctor"
2. Create a new account with a new email
3. Upload medical license and Ghana card
4. Upload profile picture
5. Submit registration
6. Go to **Platform Admin Dashboard**
7. Login: `admin@test.com` / `Test1234!`
8. Approve the new doctor application
9. Doctor can then login and see patients

---

## Step 4: Test Complete Workflow

**Patient Flow:**
1. ✅ Signup
2. ✅ Browse doctors
3. ✅ Schedule appointment
4. ✅ Make payment
5. ✅ View consultation history

**Doctor Flow:**
1. ✅ Signup
2. ⏳ Wait for admin approval
3. ✅ Login (after approval)
4. ✅ Set schedule
5. ✅ View appointments
6. ✅ See earnings
7. ✅ Chat with patients

**Admin Flow:**
1. ✅ Login
2. ✅ View pending doctors
3. ✅ Approve/Reject doctors
4. ✅ Monitor platform activity

---

## Important: Test Account Credentials (For Reference)

**OLD Test Accounts (To Be Deleted):**
- Patient: `patient@test.com` / `Test1234!`
- Doctor: `doctor@test.com` / `Test1234!`

**KEEP Admin Account:**
- Admin: `admin@test.com` / `Test1234!`

---

## Troubleshooting

### If migration fails:
1. Check if you're in the correct Supabase project
2. Verify the SQL syntax is correct
3. Try running migration in smaller chunks:
   - First delete appointments
   - Then delete profiles
   - Then delete auth users

### If you can't delete due to FK constraints:
- Make sure you're deleting in the correct order (children before parents)
- Check Supabase logs for error details

---

## Next Steps

Once mock data is removed and you're testing with real signups:

1. **Deploy the app** (remove dev-only features)
2. **Setup production Supabase** (separate project)
3. **Configure payments** (Paystack live mode)
4. **Setup email notifications** (Supabase emails)
5. **Monitor with logs** (App Insights, Supabase logs)

---

**Done!** Your app is now ready for real testing with fresh data. 🚀
