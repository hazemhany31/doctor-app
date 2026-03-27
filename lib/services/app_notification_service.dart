import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'local_notification_service.dart';

class AppNotificationService {
  static final AppNotificationService _instance =
      AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  StreamSubscription<QuerySnapshot>? _subscription;
  final Set<String> _processedIds = {};
  bool _isFirstLoad = true; // Add this line

  // نفس نمط تطبيق المريض — نستخدم LocalNotificationService مباشرة
  final _notif = LocalNotificationService();

  void startListening(List<String> recipientIds) async {
    stopListening();
    if (recipientIds.isEmpty) return;

    debugPrint('📡 AppNotificationService: Listening for $recipientIds');

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', whereIn: recipientIds)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('📩 Snapshot: ${snapshot.docs.length} unread docs');

        // Guard for initial load: skip processing existing unread notifications
        // Only mark them as seen in _processedIds so they won't fire later
        if (_isFirstLoad) {
          _isFirstLoad = false;
          for (var doc in snapshot.docs) {
            _processedIds.add(doc.id);
          }
          debugPrint('ℹ️ Initial load: seeded ${snapshot.docs.length} existing IDs, skipping alerts.');
          return;
        }

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;
            final id = change.doc.id;
            if (_processedIds.contains(id)) continue;

            _processedIds.add(id);
            final title = data['title'] ?? 'إشعار جديد';
            final body = data['body'] ?? 'لديك تحديث جديد';

            debugPrint('🔔 Showing notification: $title — $body');
            _notif.show(title, body);
            _markAsRead(id);
          }
        }
      },
      onError: (e) => debugPrint('❌ AppNotificationService: $e'),
      cancelOnError: false,
    );
  }

  Future<void> showTestNotification() async {
    debugPrint('🔔 Sending test notification...');
    await _notif.show('إشعار تجريبي ✅', 'نظام التنبيهات يعمل بنجاح على جهازك!');
  }

  Future<void> _markAsRead(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .update({'status': 'read'});
    } catch (e) {
      debugPrint('⚠️ markAsRead failed: $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _processedIds.clear();
    _isFirstLoad = true; // Reset for next startListening call
  }
}
