import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/permission_helper.dart';
import '../main.dart' show navigatorKey;
import '../models/appointment.dart';
import '../screens/appointments/appointment_detail_screen.dart';

/// Returns the saved language code ('ar' or 'en').
/// Falls back to 'ar' if SharedPreferences is unavailable.
Future<String> _getLang() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_code') ?? 'ar';
  } catch (_) {
    return 'ar';
  }
}

// ─── Background message handler (top-level required by FCM) ───
// IMPORTANT: This runs in a separate ISOLATE.
// It CANNOT use singletons or any un-initialized state.
// It must initialize everything it needs from scratch.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📲 [BG] FCM received: ${message.messageId}');

  // Extract title and body from notification or data payload
  final String title = message.notification?.title 
      ?? message.data['title'] 
      ?? 'إشعار جديد';
  final String body  = message.notification?.body  
      ?? message.data['body']
      ?? 'لديك تحديث جديد';

  // Initialize a fresh local notifications plugin for this isolate
  final plugin = FlutterLocalNotificationsPlugin();
  
  // Use named parameter 'settings' for modern flutter_local_notifications API
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // Use named parameters for the show method instead of positional
  await plugin.show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'doctor_app_channel',
        'Doctor App Notifications',
        channelDescription: 'تنبيهات تطبيق الدكتور',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
  );

  debugPrint('📲 [BG] Notification shown: $title');
}

/// Shared logic for emergency accept/reject — runs in both foreground and
/// background isolates. Fetches the alert doc to get patientId + doctorName,
/// updates the alert status, then writes a bilingual notification for the patient.
Future<void> _handleEmergencyActionInFirestore({
  required String alertId,
  required bool accept,
}) async {
  try {
    final lang = await _getLang();
    final isAr = lang == 'ar';

    final db = FirebaseFirestore.instance;
    final alertRef = db.collection('emergency_alerts').doc(alertId);

    // 1. Fetch alert to get patient info + doctor name
    final alertSnap = await alertRef.get();
    final alertData = alertSnap.data();
    final patientId = alertData?['patientId']?.toString() ?? '';
    final doctorName = alertData?['doctorName']?.toString() ??
        alertData?['assignedDoctorName']?.toString() ??
        (isAr ? 'الطبيب' : 'Doctor');

    // 2. Update the alert status
    await alertRef.update({
      'status': accept ? 'acknowledged' : 'rejected',
      if (accept) 'acknowledgedAt': FieldValue.serverTimestamp(),
      if (!accept) 'rejectedAt': FieldValue.serverTimestamp(),
    });

    // 3. Write a bilingual notification for the patient
    if (patientId.isNotEmpty) {
      final notifTitle = isAr
          ? (accept ? '✅ تم استلام طلب الطوارئ' : 'الطبيب غير متاح حالياً')
          : (accept ? '✅ Emergency Request Accepted' : 'Doctor Unavailable');
      final notifBody = isAr
          ? (accept
              ? 'د. $doctorName وافق على طلب الطوارئ وسيتواصل معك قريباً'
              : 'د. $doctorName اعتذر عن طلب الطوارئ، يرجى التواصل مع طبيب آخر')
          : (accept
              ? 'Dr. $doctorName accepted your emergency and will contact you shortly'
              : 'Dr. $doctorName is unavailable. Please contact another doctor');

      await db.collection('notifications').add({
        'recipientId': patientId,
        'title': notifTitle,
        'body': notifBody,
        'type': accept ? 'emergency_accepted' : 'emergency_rejected',
        'alertId': alertId,
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🔔 Patient notified of emergency ${accept ? "acceptance" : "rejection"}: $patientId');
    }

    debugPrint('✅ Emergency ${accept ? "acknowledged" : "rejected"}: $alertId');
  } catch (e) {
    debugPrint('❌ Error handling emergency action: $e');
  }
}

/// Background isolate handler — delegates to shared logic.
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  final payload = response.payload;
  if (actionId == null || payload == null) return;

  Map<String, dynamic>? data;
  try { data = jsonDecode(payload); } catch (_) { return; }

  final alertId = data?['alertId']?.toString();
  if (alertId == null || alertId.isEmpty) return;

  final accept = actionId == 'accept_emergency';
  final reject = actionId == 'reject_emergency';
  if (!accept && !reject) return;

  () async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        
        // IMPORTANT: Wait for FirebaseAuth to restore the saved user session from
        // local storage before making Firestore calls, otherwise the request 
        // will be sent as 'unauthenticated' and rejected by Security Rules.
        try {
          await FirebaseAuth.instance.authStateChanges().firstWhere((user) => user != null).timeout(const Duration(seconds: 3));
        } catch (_) {
          debugPrint('Auth state timeout or no user logged in background isolate');
        }
      }
    } catch (e) {
      debugPrint('Firebase init error in background response: $e');
    }

    await _handleEmergencyActionInFirestore(alertId: alertId, accept: accept);
  }();
}

class PushNotificationService {
  // Singleton pattern for the service
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Static counter to guarantee unique IDs (no collisions between rapid notifications)
  static int _notificationCounter = 0;
  static int get _nextId {
    _notificationCounter = (_notificationCounter + 1) % 2147483647;
    return _notificationCounter;
  }

  // ─── Notification channel details (defined once) ───
  static const _kEmergencyChannelId = 'emergency_alerts_channel';
  static const _kEmergencyAcceptId = 'accept_emergency';
  static const _kEmergencyRejectId = 'reject_emergency';
  static const _kIosEmergencyCategoryId = 'emergency_category';

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'doctor_app_channel',
    'Doctor App Notifications',
    channelDescription: 'تنبيهات تطبيق الدكتور',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  static const DarwinNotificationDetails _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.active,
  );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  // ─── Initialization ───
  Future<void> initialize(BuildContext? context) async {
    if (_isInitialized) return;

    // 1. Determine language for iOS bilingual action buttons
    final lang = await _getLang();
    final isAr = lang == 'ar';

    // 2. Init flutter_local_notifications setup
    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // We request manually below for a better UX
        requestBadgePermission: false, 
        requestSoundPermission: false,
        // Register the category using the standard ID so remote APNS payload matches it
        notificationCategories: [
          DarwinNotificationCategory(
            _kIosEmergencyCategoryId,
            actions: [
              DarwinNotificationAction.plain(
                _kEmergencyAcceptId,
                isAr ? '✅ قبول' : '✅ Accept',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                _kEmergencyRejectId,
                isAr ? '❌ رفض' : '❌ Reject',
                options: {DarwinNotificationActionOption.destructive},
              ),
            ],
          ),
        ],
      ),
    );

    // IMPORTANT: Call initialize exactly ONCE to avoid wiping out the native delegates!
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // 3. iOS: Request notification permissions
    if (!kIsWeb && Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // 3. Android 13+: Request notification permission
    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // 4. Android: Create both standard and emergency notification channels
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Standard channel
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          'doctor_app_channel',
          'Doctor App Notifications',
          description: 'تنبيهات تطبيق الدكتور',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ));
        // Emergency channel (separate so it can have distinct sound/LED)
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          _kEmergencyChannelId,
          'Emergency Alerts',
          description: 'تنبيهات الطوارئ الطبية',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ));
      }
    }

    // 5. FCM background handler callback setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Handle notification tap when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 FCM Tapped from Background');
      _handleNotificationTap(message.data);
    });

    // 7. Handle notification tap when app is TERMINATED
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 FCM Tapped from Terminated');
      _handleNotificationTap(initialMessage.data);
    }

    // 8. FCM foreground messages → show local notification banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 FCM Foreground: ${message.notification?.title}');
      if (message.notification != null) {
        final type = message.data['type']?.toString() ?? '';
        
        // Suppress displaying FCM directly if handled by our localized app streams
        if (type == 'new_appointment' || type == 'emergency') {
           debugPrint('🚫 Suppressing FCM foreground banner for $type (handled natively with translations)');
           return;
        }

        // Here we call the localized show function below for standard messages
        show(
          message.notification!.title ?? 'إشعار جديد',
          message.notification!.body ?? 'لديك تحديث جديد',
          payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
        );
      }
    });

    // 9. Save FCM token + listen for auth changes (re-save on login)
    await saveFCMToken();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) saveFCMToken();
    });

    // 10. FCM token refresh listener to ensure remote DB always has the latest token
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed');
      saveFCMToken();
    });

    _isInitialized = true;
    debugPrint('✅ PushNotificationService initialized');
  }

  // ─── Request permissions directly from the user ───
  Future<void> requestPermission(BuildContext context) async {
    final settings = await _fcm.getNotificationSettings();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      saveFCMToken();
      return;
    }

    if (!context.mounted) return;
    final allowed = await PermissionHelper.requestNotificationPermission(context);
    if (allowed) {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      saveFCMToken();
    }
  }

  // ─── Save the FCM token to Firestore safely ───
  Future<void> saveFCMToken() async {
    try {
      // iOS simulator has no APNS token → skip securely to avoid exceptions
      if (!kIsWeb && Platform.isIOS) {
        String? apns;
        try {
          apns = await _fcm.getAPNSToken().timeout(const Duration(seconds: 4));
        } catch (_) {}
        if (apns == null) {
          debugPrint('⚠️ APNS unavailable — skipping token save (simulator?)');
          return;
        }
      }

      final token =
          await _fcm.getToken().timeout(const Duration(seconds: 6));
      if (token == null) {
        debugPrint('⚠️ FCM token is NULL');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      debugPrint('💾 Saving FCM token for ${user.uid}');

      // Save to users/{uid} — primary lookup used by Cloud Functions
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true));

      // Also save on the doctors document (fallback implementation)
      final q = await FirebaseFirestore.instance
          .collection('doctors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        await q.docs.first.reference
            .set({'fcmToken': token}, SetOptions(merge: true));
      }

      debugPrint('✅ FCM token saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  // ─── Show a local notification ───
  Future<void> show(String title, String body, {String? payload}) async {
    if (kIsWeb) return;
    try {
      await _plugin.show(
        id: _nextId,
        title: title,
        body: body,
        notificationDetails: _notifDetails,
        payload: payload,
      );
      debugPrint('🔔 Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  // ─── Handle notification redirection logic (Foreground & Action button taps) ───
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Local Notification response: actionId=${response.actionId} payload=${response.payload}');

    final actionId = response.actionId;
    final payload = response.payload;
    Map<String, dynamic>? data;
    if (payload != null) {
      try { data = jsonDecode(payload); } catch (_) {}
    }

    // Handle emergency action buttons directly (no app open needed for the action)
    if (actionId == _kEmergencyAcceptId || actionId == _kEmergencyRejectId) {
      final alertId = data?['alertId']?.toString();
      if (alertId != null && alertId.isNotEmpty) {
        _handleEmergencyAction(alertId: alertId, accept: actionId == _kEmergencyAcceptId);
      }
      // Even on action press, open app if foreground action needed
      return;
    }

    // Normal notification tap → navigate
    if (data != null) {
      _handleNotificationTap(data);
    }
  }

  // ─── Handle notification parsing and logic wrapper ───
  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('👉 Handling notification tap: $data');
    final type = data['type']?.toString();
    final appointmentId = data['appointmentId']?.toString() ?? data['id']?.toString();

    if (appointmentId != null && appointmentId.isNotEmpty) {
      debugPrint('📅 Navigating to appointment: $appointmentId');
      _navigateToAppointment(appointmentId);
    } else if (type != null) {
      debugPrint('ℹ️ Notification tap — type: $type, no appointmentId to navigate to.');
    } else {
      debugPrint('ℹ️ Notification tap has no route hints, opening app only.');
    }
  }

  // ─── Navigate to AppointmentDetailScreen by appointment ID ───
  void _navigateToAppointment(String appointmentId) async {
    try {
      // Small delay to ensure the navigator is ready (especially on cold start)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!snap.exists) {
        debugPrint('⚠️ Appointment $appointmentId not found in Firestore');
        return;
      }

      final appointment = Appointment.fromFirestore(snap);

      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('⚠️ navigatorKey has no context yet — deferring navigation');
        // Retry once after a longer delay (app still loading)
        await Future.delayed(const Duration(seconds: 1));
        final retryCtx = navigatorKey.currentContext;
        if (retryCtx == null) return;
        _pushAppointmentDetail(appointment);
        return;
      }
      _pushAppointmentDetail(appointment);
    } catch (e) {
      debugPrint('❌ Error navigating to appointment: $e');
    }
  }

  void _pushAppointmentDetail(Appointment appointment) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
  }

  // ─── Show Emergency Notification with Accept / Reject action buttons ───
  Future<void> showEmergencyNotification({
    required String alertId,
    required String patientName,
    String? description,
    required DateTime time,
  }) async {
    if (kIsWeb) return;
    try {
      final lang = await _getLang();
      final isAr = lang == 'ar';

      final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = isAr ? (time.hour < 12 ? 'ص' : 'م') : (time.hour < 12 ? 'AM' : 'PM');
      final timeLabel = '$hour12:$minute $period';

      final title = isAr ? '🚨 طارئة طبية' : '🚨 Medical Emergency';
      final body = StringBuffer();
      body.write(isAr ? '$patientName • الساعة $timeLabel' : '$patientName • $timeLabel');
      if (description != null && description.trim().isNotEmpty) {
        body.write(' • ${description.trim()}');
      }

      final acceptLabel = isAr ? '✅ قبول' : '✅ Accept';
      final rejectLabel = isAr ? '❌ رفض' : '❌ Reject';

      final payload = jsonEncode({'alertId': alertId, 'type': 'emergency'});

      final androidDetails = AndroidNotificationDetails(
        _kEmergencyChannelId,
        isAr ? 'تنبيهات الطوارئ' : 'Emergency Alerts',
        channelDescription: isAr ? 'تنبيهات الطوارئ الطبية' : 'Medical emergency alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFE53935),
        actions: [
          AndroidNotificationAction(
            _kEmergencyAcceptId,
            acceptLabel,
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _kEmergencyRejectId,
            rejectLabel,
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: _kIosEmergencyCategoryId,
      );

      await _plugin.show(
        id: alertId.hashCode.abs() % 2147483647,
        title: title,
        body: body.toString(),
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );

      debugPrint('🔔 Emergency notification shown for alertId=$alertId [lang=$lang]');
    } catch (e) {
      debugPrint('❌ Failed to show emergency notification: $e');
    }
  }

  // ─── Handle emergency action button press (foreground) ───
  void _handleEmergencyAction({required String alertId, required bool accept}) {
    debugPrint('🚨 Emergency action: ${accept ? "ACCEPT" : "REJECT"} alertId=$alertId');
    // Delegate to shared top-level function (also handles patient notification)
    _handleEmergencyActionInFirestore(alertId: alertId, accept: accept);
  }
}

