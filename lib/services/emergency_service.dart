import 'package:flutter/foundation.dart';


import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of pending emergency alerts assigned to this doctor
  Stream<List<DocumentSnapshot>> watchEmergencyAlerts(List<String> doctorIds) {
    // Ensure unique IDs
    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value([]);

    return _firestore
        .collection('emergency_alerts')
        .where('doctorId', whereIn: uniqueIds)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Accept/Acknowledge an emergency alert
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _firestore.collection('emergency_alerts').doc(alertId).update({
        'status': 'acknowledged',
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error acknowledging alert: $e');
    }
  }

  /// Reject/Cancel an emergency alert (if doctor cannot take it)
  Future<void> rejectAlert(String alertId) async {
    try {
      await _firestore.collection('emergency_alerts').doc(alertId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      // (Optional) Could trigger finding another doctor if needed.
    } catch (e) {
      debugPrint('❌ Error rejecting alert: $e');
    }
  }
}
