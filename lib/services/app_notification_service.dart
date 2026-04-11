import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'push_notification_service.dart';

/// Listens to the Firestore `notifications` collection for the logged-in
/// doctor and shows local notifications for new (unread) documents.
class AppNotificationService {
  static final AppNotificationService _instance =
      AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  StreamSubscription<QuerySnapshot>? _subscription;
  final Set<String> _processedIds = {};
  bool _isFirstLoad = true;

  final _push = PushNotificationService();

  // ─── Start Listening ───
  void startListening(List<String> recipientIds) {
    stopListening();

    final ids = recipientIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return;

    // Firestore whereIn only supports up to 30 elements; trim just in case.
    final query = ids.length > 30 ? ids.sublist(0, 30) : ids;

    debugPrint('📡 AppNotificationService: watching recipientIds=$query');

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', whereIn: query)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .listen(_onSnapshot, onError: _onError, cancelOnError: false);
  }

  // ─── Snapshot handler ───
  void _onSnapshot(QuerySnapshot snapshot) {
    debugPrint(
        '📩 Snapshot: ${snapshot.docs.length} unread doc(s), '
        'changes: ${snapshot.docChanges.length}');

    if (_isFirstLoad) {
      _handleFirstLoad(snapshot.docs);
      return;
    }

    // Only process newly ADDED documents to avoid duplicates on modify events
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        _processDoc(change.doc);
      }
    }
  }

  // ─── First-load seeding ───
  void _handleFirstLoad(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final rawTs = data?['createdAt'];
      final createdAt = rawTs is Timestamp ? rawTs.toDate() : null;

      // Seed old notifications (>10 min old) so we don't re-alert on app restart.
      // If createdAt is null (server timestamp still pending), treat as NEW → show it.
      if (createdAt != null && now.difference(createdAt).inMinutes > 10) {
        _processedIds.add(doc.id);
      }
    }

    _isFirstLoad = false;
    debugPrint('ℹ️ First-load: seeded ${_processedIds.length} old notifications');

    // Show any recent ones that were NOT seeded
    for (final doc in docs) {
      _processDoc(doc);
    }
  }

  // ─── Process a single document ───
  void _processDoc(DocumentSnapshot doc) {
    if (_processedIds.contains(doc.id)) return;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    // Extra guard: skip if marked as already sent via FCM (Cloud Function did it)
    if (data['fcmSent'] == true) {
      _processedIds.add(doc.id);
      return;
    }

    _processedIds.add(doc.id);

    final title = (data['title'] as String?)?.trim() ?? 'إشعار جديد';
    final body = (data['body'] as String?)?.trim() ?? 'لديك تحديث جديد';

    debugPrint('🔔 Showing local notification: $title — $body');
    _push.show(title, body);
  }

  void _onError(Object e) => debugPrint('❌ AppNotificationService error: $e');

  // ─── Test helper ───
  Future<void> showTestNotification() async {
    await _push.show('إشعار تجريبي ✅', 'نظام التنبيهات يعمل بنجاح!');
  }

  // ─── Stop Listening ───
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _processedIds.clear();
    _isFirstLoad = true;
  }
}
