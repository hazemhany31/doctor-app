import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/permission_helper.dart';

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

    // 1. Init flutter_local_notifications setup
    // Using named 'settings' for compatibility with latest flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // We request manually below for a better UX
        requestBadgePermission: false, 
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // 2. iOS: Explicitly request permissions (shows a proper system dialog)
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

    // 4. Android: Explicitly create the notification channel for high importance
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          'doctor_app_channel',
          'Doctor App Notifications',
          description: 'تنبيهات تطبيق الدكتور',
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
        // Here we call the localized show function below
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

  // ─── Handle notification redirection logic (Foreground taps) ───
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Local Notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint('❌ Failed to parse notification payload: $e');
      }
    }
  }

  // ─── Handle notification parsing and logic wrapper ───
  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('👉 Handling notification tap: $data');
    final type = data['type']?.toString();
    final id = data['id']?.toString() ?? data['appointmentId']?.toString();

    // Keep this method side-effect free for now; app-level navigator routing can
    // be added later once a global navigation key is introduced.
    if (type != null || id != null) {
      debugPrint('ℹ️ Notification payload resolved (type: $type, id: $id)');
    } else {
      debugPrint('ℹ️ Notification tap has no route hints, opening app only.');
    }
  }
}
