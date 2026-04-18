# Chat & Video Call Integration - Quick Start Guide

## ✅ What's Been Implemented

### 1. **Enhanced Chat Service** (`lib/services/chat_service.dart`)
- ✅ Approval check before allowing chat
- ✅ Auto-create chat on appointment approval
- ✅ User presence tracking (online/offline)
- ✅ Unread count management
- ✅ Doctor-side chat support

### 2. **Agora Integration Service** (`lib/services/agora_service.dart`)
- ✅ Token generation from backend
- ✅ Consultation session management
- ✅ Call quality metrics logging
- ✅ Appointment eligibility check

### 3. **Enhanced Video Call Screen** (`lib/screens/video_consultation_screen_new.dart`)
- ✅ Modern UI with call timer
- ✅ Mic/camera toggle buttons
- ✅ Call quality indicators
- ✅ Professional controls
- ✅ Duration tracking
- ✅ Local/remote video preview layouts

### 4. **Appointment Controller Update** (`lib/controllers/appointment_controller.dart`)
- ✅ Auto-approve with chat creation
- ✅ Notification on approval
- ✅ Chat session auto-initialization

---

## 🔧 Next Steps to Complete Integration

### Step 1: Add Agora SDK (CRITICAL)

Run in terminal:
```bash
flutter pub add agora_rtc_engine permission_handler wakelock_plus
flutter pub get
```

**pubspec.yaml** should now include:
```yaml
dependencies:
  agora_rtc_engine: ^6.3.0
  permission_handler: ^11.4.4
  wakelock_plus: ^1.1.0
```

### Step 2: Get Agora Credentials

1. Go to [Agora Console](https://console.agora.io)
2. Create new project or use existing
3. Copy **App ID**
4. Go to **Certificate** section and copy **App Certificate**
5. These will be used in Step 3

### Step 3: Update Agora Service with App ID

**File:** `lib/services/agora_service.dart`

Replace line 25:
```dart
// BEFORE:
static const String agoraAppId = ''; // TODO: Set your Agora App ID

// AFTER:
static const String agoraAppId = 'YOUR_AGORA_APP_ID_HERE';
```

### Step 4: Create Supabase Edge Function for Token Generation

**File:** `supabase/functions/generate-agora-token/index.ts`

Create this file in your Supabase project:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { RtcTokenBuilder, RtcRole } from "https://esm.sh/agora-token@1.0.5";

const AGORA_APP_ID = Deno.env.get("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = Deno.env.get("AGORA_APP_CERTIFICATE");

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const { channelId, uid } = await req.json();

    if (!channelId || !uid) {
      return new Response(
        JSON.stringify({ error: "Missing channelId or uid" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelId,
      parseInt(uid),
      RtcRole.PUBLISHER,
      3600, // Token expiration in seconds (1 hour)
      0
    );

    return new Response(
      JSON.stringify({ token }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
});
```

Deploy with:
```bash
supabase functions deploy generate-agora-token
```

### Step 5: Set Supabase Edge Function Secrets

In Supabase dashboard:
1. Go to **Edge Functions** → **generate-agora-token**
2. Click **Settings**
3. Add environment variables:
   - Key: `AGORA_APP_ID` → Value: Your Agora App ID
   - Key: `AGORA_APP_CERTIFICATE` → Value: Your Agora Certificate

### Step 6: Add Permissions (iOS & Android)

**File:** `android/app/src/main/AndroidManifest.xml`

Add these permissions:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.BLUETOOTH" />
```

**File:** `ios/Runner/Info.plist`

Add these keys:
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera for video consultations</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for video/audio consultations</string>
<key>NSLocalNetworkUsageDescription</key>
<string>We need access to your local network for better call quality</string>
<key>NSBonjourServices</key>
<array>
  <string>_airplay._tcp</string>
  <string>_raop._tcp</string>
</array>
```

### Step 7: Update Routes in main.dart

**File:** `lib/main.dart`

Add this route (if not already present):
```dart
GetPage(
  name: '/video-call',
  page: () => VideoConsultationScreenNew(),
  transition: Transition.native,
),
```

Also import:
```dart
import 'package:doctor_consultation_app/screens/video_consultation_screen_new.dart';
```

### Step 8: Update Chat Detail Screen

**File:** `lib/screens/chat_screen.dart`

Update the video call button (around line 190-195):

```dart
// BEFORE:
onPressed: () {},

// AFTER:
onPressed: () {
  if (controller.selectedChat.value != null) {
    Get.toNamed('/video-call', arguments: {
      'channelId': 'call_${controller.selectedChat.value!.id}',
      'doctorName': controller.selectedChat.value!.doctorName,
      'doctorAvatar': controller.selectedChat.value!.doctorAvatar,
      'userId': controller.selectedChat.value!.doctorId,
      'appointmentId': '', // Get from context if available
      'patientName': 'You',
    });
  }
},
```

### Step 9: Add Permission Request Handler

**File:** `lib/main.dart`

Add this before app runs:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request camera and mic permissions
  await [
    Permission.camera,
    Permission.microphone,
  ].request();
  
  // ... rest of initialization
}
```

Import:
```dart
import 'package:permission_handler/permission_handler.dart';
```

### Step 10: Update API Service (Optional)

**File:** `lib/services/api_service.dart`

Add this method (if not present):
```dart
/// Approve appointment by doctor
Future<bool> approveAppointment(String appointmentId, String doctorId) async {
  try {
    final response = await _supabase
        .from('appointments')
        .update({
          'status': 'confirmed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', appointmentId)
        .eq('doctor_id', doctorId);
    
    return response != null;
  } catch (e) {
    print('Error approving appointment: $e');
    return false;
  }
}
```

---

## 🧪 Testing the Implementation

### Test Flow:

1. **Patient Books Appointment**
   - Login as patient
   - Browse doctors → Book appointment
   - Payment successful

2. **Doctor Approves Appointment**
   - Login as doctor
   - Go to Appointments tab
   - Click "Accept" on pending appointment
   - ✅ Chat session auto-created

3. **Patient Opens Chat**
   - Go to Messages
   - Should see new chat with doctor
   - ✅ Chat only appears after approval

4. **Start Video Call**
   - In chat, click video icon
   - ✅ Redirects to video call screen
   - ✅ Call timer starts
   - ✅ Mic/camera toggles work
   - ✅ Duration saved on end

---

## 📱 Testing Commands

### Run on Device with Video Call Features:
```bash
flutter run -d 00008030-001A49020EEB402E
```

### Run with Hot Reload (after Agora setup):
```bash
flutter pub get
flutter run -d <device-id>
```

### Check Supabase Edge Function Logs:
```bash
supabase functions serve
# Then in another terminal:
supabase functions deploy generate-agora-token --no-verify-jwt
```

---

## 🐛 Troubleshooting

### "Token is empty" error
**Solution:** Check if Edge Function is deployed and secrets are set

### "Camera/Mic permission denied"
**Solution:** Manually grant permissions in device settings or reinstall app

### Video call black screen
**Solution:** 
1. Check if Agora SDK is properly initialized
2. Verify token is valid
3. Check channel ID format

### Chat not appearing after approval
**Solution:**
1. Verify `chat_sessions` table exists in Supabase
2. Check RLS policies allow INSERT
3. Verify patientId and doctorId are correct UUIDs

### App crashes on video call screen
**Solution:**
1. Make sure `video_consultation_screen_new.dart` is imported
2. Check if routes are registered in `main.dart`
3. Verify all dependencies are installed (`flutter pub get`)

---

## 📊 Database Verification

### Verify Chat Tables Exist:

```sql
-- Run in Supabase SQL Editor
SELECT * FROM chat_sessions LIMIT 1;
SELECT * FROM messages LIMIT 1;
SELECT * FROM consultations LIMIT 1;
SELECT * FROM appointments WHERE status = 'confirmed' LIMIT 1;
```

---

## 🔐 Security Checklist

- [ ] Agora App Certificate is NOT in code (use Edge Function)
- [ ] Supabase RLS policies enabled for chat_sessions
- [ ] Chat only accessible after appointment confirmation
- [ ] Token expires in 1 hour (not longer)
- [ ] Video recordings deleted after 30 days (optional)
- [ ] User presence updates on app close
- [ ] Sensitive data encrypted in transit (HTTPS/WSS)

---

## 📈 Deployment Checklist

### Before Going Live:

- [ ] Test on both iOS and Android devices
- [ ] Test with slow 3G network
- [ ] Test appointment approval flow end-to-end
- [ ] Test video call with 2 actual devices
- [ ] Verify chat sync in real-time
- [ ] Check push notifications on approval
- [ ] Test 100+ message chat
- [ ] Monitor Agora usage in console

### Monitoring:

1. **Agora Console:**
   - Monitor call quality
   - Track concurrent users
   - Check data usage

2. **Supabase:**
   - Monitor database queries
   - Check edge function logs
   - Track storage usage

---

## 📞 Complete Feature Checklist

| Feature | Status | Implementation File |
|---------|--------|-------------------|
| Chat Approval Check | ✅ | `chat_service.dart` |
| Auto-Create Chat | ✅ | `chat_service.dart` |
| Presence Tracking | ✅ | `chat_service.dart` |
| Agora Token Generation | ✅ | `agora_service.dart` |
| Video Call UI | ✅ | `video_consultation_screen_new.dart` |
| Call Timer | ✅ | `video_consultation_screen_new.dart` |
| Duration Tracking | ✅ | `agora_service.dart` |
| Appointment Approval | ✅ | `appointment_controller.dart` |
| Real-time Chat Sync | ⏳ | Needs Supabase Real-time setup |
| Agora SDK Integration | ⏳ | Needs `pubspec.yaml` update |
| Edge Function Deploy | ⏳ | Needs Supabase setup |
| Permission Handling | ⏳ | Needs `main.dart` update |
| Doctor-side Chat | ⏳ | Needs UI implementation |
| Call Recording | ⏳ | Optional feature |
| Presence Indicators | ⏳ | Needs UI update |

---

## 🚀 Performance Optimization Tips

1. **Message Pagination:** Load 20 messages at a time
2. **Image Compression:** Compress avatars before upload
3. **Connection Pooling:** Reuse Supabase connections
4. **Lazy Loading:** Load chats only when visible
5. **Message Caching:** Cache recent messages locally

---

## 💡 Future Enhancements

1. **Screen Sharing** - Share prescription/documents during call
2. **Call Recording** - Record consultations for patient records
3. **Call Scheduling** - Schedule calls from chat
4. **Prescription Sharing** - Send prescriptions via chat
5. **Message Reactions** - React to messages with emoji
6. **Call Statistics** - Show call quality metrics
7. **Group Consultations** - Multiple patients with one doctor
8. **AI Transcription** - Auto-transcribe consultations

---

**Last Updated:** 2026-04-18
**Status:** Ready for Integration
**Estimated Time to Deploy:** 30-60 minutes

---

For detailed implementation of Agora SDK features, see `CHAT_AND_VIDEO_IMPLEMENTATION.md`
