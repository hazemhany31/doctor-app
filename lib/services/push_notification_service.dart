import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get localNotificationsPlugin => _localNotificationsPlugin;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle when user taps the notification
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // 3. Background messaging setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Foreground messaging setup
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // 5. App opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened via notification: ${message.data}');
    });

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via: ${initialMessage.data}');
    }

    // 6. Get and save the FCM token for the doctor
    await saveFCMToken();
  }

  Future<void> saveFCMToken() async {
    try {
      // For iOS, we need to wait for APNS token to be set
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('APNS token not set yet. Waiting 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _fcm.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('APNS token still not set. FCM token may fail.');
          }
        }
      }

      final String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Save to users collection
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
          
          // 2. Save to doctors collection (find by userId)
          final doctorQuery = await FirebaseFirestore.instance
              .collection('doctors')
              .where('userId', isEqualTo: user.uid)
              .limit(1)
              .get();
          
          if (doctorQuery.docs.isNotEmpty) {
            await doctorQuery.docs.first.reference.set(
              {'fcmToken': token}, 
              SetOptions(merge: true)
            );
            debugPrint('FCM Token saved to Doctors collection');
          }
          
          debugPrint('FCM Token saved successfully');
        }
      }
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Fallback if notification title/body are null (data-only messages)
    final String title = notification?.title ?? data['title'] ?? 'New Update';
    final String body = notification?.body ?? data['body'] ?? 'You have a new notification';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel', // id
          'High Importance Notifications', // name
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: data.isNotEmpty ? jsonEncode(data) : null,
    );
  }
}
