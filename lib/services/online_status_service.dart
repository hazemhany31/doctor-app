import 'package:flutter/foundation.dart';


import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة تتبع حالة الدكتور (متصل/غير متصل)
/// يتم التحكم يدوياً عن طريق الدكتور
class OnlineStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _doctorDocId;
  bool _isInitialized = false;
  bool _currentStatus = false;

  /// Initialize online status tracking
  Future<void> initialize(String doctorDocId) async {
    if (_isInitialized) return;

    _doctorDocId = doctorDocId;
    _isInitialized = true;

    // Get current status from Firestore
    await _loadCurrentStatus();
  }

  /// Load current online status from Firestore
  Future<void> _loadCurrentStatus() async {
    if (_doctorDocId == null) return;

    try {
      final doc = await _firestore
          .collection('doctors')
          .doc(_doctorDocId)
          .get();

      if (doc.exists) {
        _currentStatus = doc.data()?['isOnline'] ?? false;
      }
    } catch (e) {
      debugPrint('❌ Error loading current status: $e');
    }
  }

  /// Get current online status
  bool get isOnline => _currentStatus;

  /// Toggle online/offline status
  Future<void> toggleOnlineStatus() async {
    await setOnlineStatus(!_currentStatus);
  }

  /// Set doctor online/offline status manually
  Future<void> setOnlineStatus(bool isOnline) async {
    if (_doctorDocId == null) {
      debugPrint('⚠️ Cannot set status: doctorDocId is null');
      return;
    }

    try {
      await _firestore.collection('doctors').doc(_doctorDocId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      _currentStatus = isOnline;
    } catch (e) {
      debugPrint('❌ Error setting online status: $e');
    }
  }

  /// Cleanup - optionally set offline when logging out
  Future<void> dispose() async {
    _isInitialized = false;
    _doctorDocId = null;
  }
}
