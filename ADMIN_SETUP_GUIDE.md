# Admin Dashboard Setup - Complete Guide

## Problem
"Database error querying schema" when trying to login to admin dashboard

## Solution
Run the diagnostic and fix migration, then clear your browser cache.

---

## Step 1: Run the Diagnostic Migration

1. **Open** [Supabase Dashboard](https://app.supabase.com)
2. **Navigate to** SQL Editor
3. **Copy the entire contents** of:
   ```
   migrations/017_diagnostic_and_fix.sql
   ```
4. **Paste** into SQL Editor
5. **Click** "Run" button
6. **Wait** for completion - you should see:
   ```
   ✓ profiles table exists
   ✓ All required columns exist in profiles table
   ✓ RLS policies recreated for profiles table
   ✓ Old admin records cleaned
   ✓ Admin auth user created
   ✓ Admin identity created
   ✓ Admin profile created
   ✓ DATABASE SETUP COMPLETE
   ```

---

## Step 2: Clear Browser Cache & Cookies

**Chrome/Edge/Firefox:**
1. Press `Ctrl+Shift+Delete` (Windows) or `Cmd+Shift+Delete` (Mac)
2. Select "All time" as time range
3. Check "Cookies and other site data"
4. Check "Cached images and files"
5. Click "Clear data"

**Or**: Simply open the admin dashboard in a **new private/incognito window**

---

## Step 3: Test Admin Login

1. **Open** the admin dashboard in a fresh browser tab
2. **Enter credentials:**
   - Email: `admin@test.com`
   - Password: `Test1234!`
3. **Click** "Sign In"
4. **Watch the browser console** (F12) for detailed logs showing:
   - Step 1: Auth successful
   - Step 2: User ID received
   - Step 3: Profile fetched
   - Step 4: Admin role verified
   - Step 5: Dashboard shown

---

## Step 4: Remove Test Seed Data (Optional)

Once admin login works, you can remove the test patient/doctor accounts by running:
```
migrations/015_remove_seed_test_data.sql
```

---

## Troubleshooting

### If you still see "Database error querying schema":

**Check browser console (F12):**
- Look for detailed error messages under "Step 3"
- Screenshot the exact error and share it

**Check Supabase:**
1. Go to Authentication → Users
2. Verify `admin@test.com` exists
3. Go to SQL Editor, run:
   ```sql
   SELECT id, email, role FROM public.profiles WHERE email = 'admin@test.com';
   ```
4. You should see one admin profile row

### If migration fails:

- Make sure you run migration 001 first (creates profiles table)
- Make sure you're in the correct Supabase project
- Try refreshing the page and running again

---

## Admin Dashboard Features After Login

Once logged in, you can:
- ✅ View all users (patients)
- ✅ View all doctors with pending approval
- ✅ Approve/reject doctor applications
- ✅ View payments and transactions
- ✅ Configure commission settings
- ✅ Monitor consultations
- ✅ Manage reviews and ratings

---

## Next: Test Patient & Doctor Signup

After admin works:
1. Close/logout from admin
2. Open the Flutter mobile app
3. Test patient signup flow
4. Test doctor signup flow
5. Login as admin to approve the new doctor
6. Then run consultations and payments

---

**Questions?** Check the browser console (F12) for detailed diagnostic logs.
