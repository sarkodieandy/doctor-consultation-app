# Chat and Video Call Implementation Guide

## 📋 Overview

This document outlines how to implement:
1. **Real-time Chat** - Only after appointment approval
2. **Video Consultation** - Using Agora or Jitsi
3. **Backend Integration** - Full Supabase integration
4. **Real-time Updates** - LiveQuery for instant messaging

---

## 1. Chat System Implementation

### Current State
✅ **Already Implemented:**
- `chat_service.dart` - Supabase operations
- `chat_controller.dart` - GetX state management
- `chat_model.dart` - Data models
- `chat_screen.dart` - UI for chat list and messages
- Database schema: `chat_sessions` & `messages` tables

⚠️ **Issues to Fix:**
- Chat can be started anytime (should be after approval)
- No real-time message sync (no WebSocket/LiveQuery)
- Doctor side of chat not fully implemented
- Missing presence indicator (online/offline status)

### Step 1: Add Approval Check to Chat Service

**File:** `lib/services/chat_service.dart`

Add method to check if chat can be initiated:

```dart
/// Check if chat can be initiated (only after appointment is approved)
Future<bool> canInitiateChat(String patientId, String doctorId) async {
  try {
    final approved = await _supabase
        .from('appointments')
        .select()
        .eq('user_id', patientId)
        .eq('doctor_id', doctorId)
        .eq('status', 'confirmed')  // Only confirmed appointments
        .count(CountOption.exact);
    
    return approved.count > 0;
  } catch (e) {
    print('Error checking chat eligibility: $e');
    return false;
  }
}
```

### Step 2: Enable Real-Time Message Updates

**File:** `lib/services/chat_service.dart`

Add real-time subscription:

```dart
/// Subscribe to new messages in real-time
Stream<List<MessageModel>> subscribeToMessages(String chatId) {
  return _supabase
      .from('messages:chat_id=eq.$chatId')
      .on(RealtimeListenTypes.all, onsuccess: (payload) {
        print('New message: ${payload.newRecord}');
      })
      .eq('chat_id', chatId)
      .asStream()
      .map((List<dynamic> data) {
        return (data as List).map((json) => MessageModel.fromJson(json)).toList();
      });
}

/// Subscribe to chat session updates (last message, unread count)
Stream<ChatModel> subscribeToChatSession(String chatId) {
  return _supabase
      .from('chat_sessions:id=eq.$chatId')
      .on(RealtimeListenTypes.all, onsuccess: (payload) {
        print('Chat updated: ${payload.newRecord}');
      })
      .asStream()
      .map((List<dynamic> data) {
        if (data.isEmpty) return null;
        return ChatModel.fromJson(data.first);
      })
      .where((chat) => chat != null)
      .cast<ChatModel>();
}
```

### Step 3: Add Presence Status (Online/Offline)

**File:** `lib/services/chat_service.dart`

```dart
/// Update user online status
Future<bool> setUserPresence(String userId, bool isOnline) async {
  try {
    await _supabase
        .from('profiles')
        .update({'is_online': isOnline})
        .eq('id', userId);
    return true;
  } catch (e) {
    print('Error updating presence: $e');
    return false;
  }
}

/// Get user presence
Future<bool> getUserPresence(String userId) async {
  try {
    final data = await _supabase
        .from('profiles')
        .select('is_online')
        .eq('id', userId)
        .single();
    return data['is_online'] ?? false;
  } catch (e) {
    return false;
  }
}
```

### Step 4: Update Chat Controller

**File:** `lib/controllers/chat_controller.dart`

```dart
// Add real-time listeners
StreamSubscription? _messageSubscription;
StreamSubscription? _presenceSubscription;

@override
void onInit() {
  super.onInit();
  _userId = _authService.resolveUserId(fallback: Get.arguments);
  fetchChats();
  _setupRealTimeListeners();
}

void _setupRealTimeListeners() {
  if (selectedChat.value != null) {
    // Listen for new messages
    _messageSubscription = 
        _chatService.subscribeToMessages(selectedChat.value!.id)
            .listen((messages) {
              messages.addAll(messages);
              scrollToBottom();
            });
    
    // Listen for chat updates
    _presenceSubscription = 
        _chatService.subscribeToChatSession(selectedChat.value!.id)
            .listen((chat) {
              selectedChat(chat);
            });
  }
}

@override
void onClose() {
  _messageSubscription?.cancel();
  _presenceSubscription?.cancel();
  super.onClose();
}

void scrollToBottom() {
  // Auto-scroll to latest message
}
```

---

## 2. Video Call Implementation

### Option A: Agora (Recommended)

**Pros:**
- Low latency (100-150ms)
- Good audio quality
- Supports 1-on-1 and group calls
- Easy SDK integration

**Cons:**
- Requires backend token generation
- Monthly costs

### Option B: Jitsi (Open Source)

**Pros:**
- Free
- No backend tokens needed
- Simple integration
- Open source

**Cons:**
- UI harder to customize
- Slightly higher latency

### Option C: Daily.co

**Pros:**
- Best-in-class video quality
- No token generation needed
- Easy for 1-on-1 calls
- Pay-as-you-go pricing

**Cons:**
- More expensive than Agora
- Limited open-source

---

## 3. Agora Implementation (Recommended)

### Step 1: Add Dependencies

**File:** `pubspec.yaml`

```yaml
dependencies:
  agora_rtc_engine: ^6.3.0
  permission_handler: ^11.4.4
  wakelock_plus: ^1.1.0
```

Run: `flutter pub get`

### Step 2: Setup Agora Service

**File:** `lib/services/agora_service.dart`

```dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctor_consultation_app/models/consultation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();

  factory AgoraService() {
    return _instance;
  }

  AgoraService._internal();

  static const String agoraAppId = 'YOUR_AGORA_APP_ID';
  late RtcEngine _agoraEngine;
  final _supabase = Supabase.instance.client;

  bool _isInitialized = false;
  
  /// Initialize Agora Engine
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _agoraEngine = createAgoraRtcEngine();
      
      await _agoraEngine.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Setup event handlers
      _agoraEngine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Successfully joined: ${connection.channelId}');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Remote user joined: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('Remote user left: $remoteUid');
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: $err - $msg');
          },
        ),
      );

      await _agoraEngine.enableVideo();
      await _agoraEngine.enableAudio();
      await _agoraEngine.setDefaultAudioRouteToSpeakerphone(true);
      
      _isInitialized = true;
      print('Agora initialized successfully');
    } catch (e) {
      print('Error initializing Agora: $e');
      rethrow;
    }
  }

  /// Generate Agora token from backend
  Future<String> getToken(String channelId, String userId) async {
    try {
      // Call Supabase edge function to generate token
      final response = await _supabase.functions.invoke(
        'generate-agora-token',
        body: {
          'channelId': channelId,
          'uid': userId,
        },
      );
      
      return response['token'] ?? '';
    } catch (e) {
      print('Error getting Agora token: $e');
      return '';
    }
  }

  /// Join video call
  Future<void> joinCall({
    required String channelId,
    required String userId,
  }) async {
    try {
      final token = await getToken(channelId, userId);
      
      await _agoraEngine.joinChannel(
        token: token,
        channelId: channelId,
        options: const RtcJoinChannelOptions(),
        uid: int.parse(userId.hashCode.toString()),
      );
    } catch (e) {
      print('Error joining call: $e');
      rethrow;
    }
  }

  /// Leave video call
  Future<void> leaveCall() async {
    try {
      await _agoraEngine.leaveChannel();
      await _agoraEngine.release();
      _isInitialized = false;
    } catch (e) {
      print('Error leaving call: $e');
    }
  }

  /// Toggle camera
  Future<void> toggleCamera(bool isOn) async {
    try {
      await _agoraEngine.enableLocalVideo(isOn);
    } catch (e) {
      print('Error toggling camera: $e');
    }
  }

  /// Toggle microphone
  Future<void> toggleMicrophone(bool isOn) async {
    try {
      await _agoraEngine.muteLocalAudioStream(!isOn);
    } catch (e) {
      print('Error toggling microphone: $e');
    }
  }

  /// Get engine for UI rendering
  RtcEngine getEngine() => _agoraEngine;
}
```

### Step 3: Create Video Call Screen

**File:** `lib/screens/video_call_screen.dart`

```dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:doctor_consultation_app/services/agora_service.dart';
import 'package:doctor_consultation_app/constant.dart';

class VideoCallScreen extends StatefulWidget {
  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final agoraService = AgoraService();
  late String channelId;
  late String userId;
  
  bool isCameraOn = true;
  bool isMicOn = true;
  bool isRemoteUserJoined = false;
  int remoteUid = 0;
  
  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    channelId = args['channelId'] ?? 'default-room';
    userId = args['userId'] ?? '';
    _initializeAndJoin();
  }

  Future<void> _initializeAndJoin() async {
    try {
      await agoraService.initialize();
      await agoraService.joinCall(
        channelId: channelId,
        userId: userId,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to join call: $e');
    }
  }

  @override
  void dispose() {
    agoraService.leaveCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Local user video (top-right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: agoraService.getEngine(),
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),

          // Remote user video (full screen)
          if (isRemoteUserJoined)
            Center(
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: agoraService.getEngine(),
                  canvas: VideoCanvas(uid: remoteUid),
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Waiting for doctor to join...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Control buttons
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic toggle
                CircleAvatar(
                  backgroundColor: isMicOn ? kBlueColor : Colors.red,
                  radius: 30,
                  child: IconButton(
                    onPressed: () async {
                      setState(() => isMicOn = !isMicOn);
                      await agoraService.toggleMicrophone(isMicOn);
                    },
                    icon: Icon(
                      isMicOn ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 20),

                // End call
                CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 30,
                  child: IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.call_end, color: Colors.white),
                  ),
                ),
                SizedBox(width: 20),

                // Camera toggle
                CircleAvatar(
                  backgroundColor: isCameraOn ? kOrangeColor : Colors.red,
                  radius: 30,
                  child: IconButton(
                    onPressed: () async {
                      setState(() => isCameraOn = !isCameraOn);
                      await agoraService.toggleCamera(isCameraOn);
                    },
                    icon: Icon(
                      isCameraOn ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timer (optional)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '15:32',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 4: Create Backend Agora Token Function

**File:** `supabase/functions/generate-agora-token/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { RtcTokenBuilder, RtcRole } from "https://esm.sh/agora-token@1.0.5";

const AGORA_APP_ID = Deno.env.get("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = Deno.env.get("AGORA_APP_CERTIFICATE");

serve(async (req) => {
  try {
    const { channelId, uid } = await req.json();

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelId,
      uid,
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

---

## 4. Automatic Chat Creation on Appointment Approval

### Update Appointment Service

**File:** `lib/services/appointment_service.dart`

Add method to create chat when appointment is approved:

```dart
/// Approve appointment and create chat session
Future<bool> approveAppointment(String appointmentId, String doctorId) async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Get appointment details
    final appt = await _supabase
        .from('appointments')
        .select()
        .eq('id', appointmentId)
        .single();

    // Update appointment status
    await _supabase
        .from('appointments')
        .update({'status': 'confirmed'})
        .eq('id', appointmentId);

    // Auto-create chat session
    final chatJson = {
      'doctor_id': doctorId,
      'doctor_name': appt['doctor_name'],
      'doctor_avatar': appt['doctor_avatar'],
      'patient_id': userId,
      'last_message': 'Chat created for appointment on ${appt['appointment_date']}',
      'last_message_time': DateTime.now().toIso8601String(),
      'unread_count': 0,
      'is_active': true,
    };

    await _supabase
        .from('chat_sessions')
        .insert(chatJson);

    // Create consultation record
    final consultJson = {
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'doctor_name': appt['doctor_name'],
      'doctor_avatar': appt['doctor_avatar'],
      'user_id': userId,
      'scheduled_time': appt['appointment_date'],
      'duration_minutes': 30,
      'status': 'scheduled',
      'consultation_type': 'video',
    };

    await _supabase
        .from('consultations')
        .insert(consultJson);

    return true;
  } catch (e) {
    print('Error approving appointment: $e');
    return false;
  }
}
```

---

## 5. Integrate Video Call Button in Chat

**File:** `lib/screens/chat_screen.dart`

Update the AppBar with video call button:

```dart
actions: [
  IconButton(
    icon: Icon(Icons.call, color: kBlueColor),
    onPressed: () {
      // Implement audio call
      _startAudioCall();
    },
  ),
  IconButton(
    icon: Icon(Icons.videocam, color: kOrangeColor),
    onPressed: () {
      // Start video call
      if (controller.selectedChat.value != null) {
        Get.toNamed('/video-call', arguments: {
          'channelId': controller.selectedChat.value!.id,
          'doctorName': controller.selectedChat.value!.doctorName,
          'userId': controller.selectedChat.value!.doctorId,
        });
      }
    },
  ),
],
```

---

## 6. Update Routes in main.dart

**File:** `lib/main.dart`

```dart
GetPage(
  name: '/video-call',
  page: () => VideoCallScreen(),
  transition: Transition.native,
),
GetPage(
  name: '/chat-detail',
  page: () => ChatDetailScreen(),
  transition: Transition.native,
  arguments: Get.arguments,
),
```

---

## 7. Update Pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies...
  
  # Video & Audio
  agora_rtc_engine: ^6.3.0
  
  # Permissions
  permission_handler: ^11.4.4
  
  # Keep screen awake during calls
  wakelock_plus: ^1.1.0
  
  # Real-time updates
  supabase_flutter: ^2.3.0
```

---

## 8. Database Schema Updates

### Update Consultations Table (if needed)

```sql
-- Add room_id to consultations for video call
ALTER TABLE consultations ADD COLUMN IF NOT EXISTS room_id TEXT;

-- Add started_at and ended_at
ALTER TABLE consultations ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE consultations ADD COLUMN IF NOT EXISTS ended_at TIMESTAMPTZ;

-- Add duration tracking
ALTER TABLE consultations ADD COLUMN IF NOT EXISTS actual_duration_minutes INTEGER;
```

---

## 9. Complete Implementation Checklist

### Backend Setup
- [ ] Create Supabase edge function for Agora token generation
- [ ] Get Agora App ID and Certificate from Agora Console
- [ ] Set environment variables in Supabase
- [ ] Deploy edge functions

### Mobile App
- [ ] Add dependencies to pubspec.yaml
- [ ] Create AgoraService
- [ ] Create VideoCallScreen
- [ ] Update ChatService with approval check
- [ ] Add real-time message listeners
- [ ] Update AppointmentService to auto-create chats
- [ ] Update routes
- [ ] Add permission requests for camera/mic

### Testing
- [ ] Test chat creation on approval
- [ ] Test real-time message delivery
- [ ] Test video call join/leave
- [ ] Test camera/mic toggle
- [ ] Test on real devices (iOS & Android)
- [ ] Test network failure scenarios

---

## 10. Implementation Priority

### Phase 1 (Critical) - Week 1
1. ✅ Fix chat approval check
2. ✅ Add real-time message sync
3. ✅ Auto-create chat on approval
4. ✅ Add Agora video call

### Phase 2 (Important) - Week 2
1. Add call history
2. Add call recording (optional)
3. Add call notifications
4. Implement call queue system

### Phase 3 (Nice-to-have) - Week 3
1. Add screen sharing
2. Add chat message reactions
3. Add prescription sharing in chat
4. Add call scheduling in chat

---

## 11. Code Examples

### Starting a Video Consultation

```dart
// From chat screen or appointment screen
void startVideoConsultation() {
  Get.toNamed('/video-call', arguments: {
    'channelId': 'consultation_${appointmentId}',
    'doctorName': doctor.name,
    'userId': currentUser.id,
  });
}
```

### Ending and Saving Consultation

```dart
Future<void> endConsultation() async {
  final duration = DateTime.now().difference(startTime).inMinutes;
  
  await _supabase
      .from('consultations')
      .update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
        'actual_duration_minutes': duration,
      })
      .eq('id', consultationId);
  
  // Update appointment
  await _supabase
      .from('appointments')
      .update({'status': 'completed'})
      .eq('id', appointmentId);
}
```

---

## 12. Troubleshooting

### Video Call Issues

| Issue | Solution |
|-------|----------|
| Black screen | Check permissions, test camera access |
| No audio | Check microphone permissions, test audio input |
| Connection drops | Check network, implement reconnection logic |
| High latency | Use regional Agora servers closer to users |
| Token expires | Regenerate token before 1-hour mark |

### Chat Issues

| Issue | Solution |
|-------|----------|
| Messages not syncing | Check Supabase RLS policies, restart stream |
| Chat not created | Verify appointment is confirmed in DB |
| Slow loading | Add pagination, implement message caching |

---

## 13. Security Considerations

✅ **Already Implemented:**
- Supabase RLS policies for chat access
- Authentication required for all operations
- Message sender verification

🔒 **To Add:**
- Encrypt sensitive messages in transit
- Add message rate limiting
- Verify user permissions before chat access
- Log all consultation sessions
- Add GDPR compliance for data retention

---

## 14. Performance Optimization

1. **Message Pagination** - Load 20 messages at a time
2. **Image Compression** - Compress avatar images
3. **Lazy Loading** - Load chats only when visible
4. **Caching** - Cache recent messages locally
5. **Connection Pooling** - Reuse Supabase connections

---

## 15. Monitoring & Analytics

Track these metrics:
- Chat creation success rate
- Message delivery time
- Video call connection success rate
- Average call duration
- Call quality metrics (latency, packet loss)
- User engagement (messages/day, calls/week)

---

**Generated:** 2026-04-18
**Status:** Implementation Guide Ready
**Estimated Development Time:** 3-4 weeks (with Phase 1 critical path)
