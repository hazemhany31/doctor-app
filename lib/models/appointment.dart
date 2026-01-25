import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات الموعد
class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final int duration; // بالدقائق
  final String status; // pending, confirmed, completed, cancelled
  final String type; // new, followup
  final String? notes;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // بيانات إضافية للعرض (لا تُحفظ في Firestore)
  final String? patientName;
  final String? patientPhotoUrl;
  final String? doctorName;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    this.duration = 20,
    required this.status,
    required this.type,
    this.notes,
    this.cancelReason,
    required this.createdAt,
    this.updatedAt,
    this.patientName,
    this.patientPhotoUrl,
    this.doctorName,
  });

  /// إنشاء Appointment من Firestore DocumentSnapshot
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment.fromMap(doc.id, data);
  }

  /// إنشاء Appointment من Map
  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      duration: map['duration'] ?? 20,
      status: map['status'] ?? 'pending',
      type: map['type'] ?? 'new',
      notes: map['notes'],
      cancelReason: map['cancelReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      patientName: map['patientName'],
      patientPhotoUrl: map['patientPhotoUrl'],
      doctorName: map['doctorName'],
    );
  }

  /// تحويل Appointment إلى Map
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'dateTime': Timestamp.fromDate(dateTime),
      'duration': duration,
      'status': status,
      'type': type,
      'notes': notes,
      'cancelReason': cancelReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// التحقق من أن الموعد اليوم
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// التحقق من أن الموعد قادم
  bool get isUpcoming {
    return dateTime.isAfter(DateTime.now());
  }

  /// التحقق من أن الموعد مضى
  bool get isPast {
    return dateTime.isBefore(DateTime.now());
  }

  Appointment copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    DateTime? dateTime,
    int? duration,
    String? status,
    String? type,
    String? notes,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? patientName,
    String? patientPhotoUrl,
    String? doctorName,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      patientName: patientName ?? this.patientName,
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      doctorName: doctorName ?? this.doctorName,
    );
  }
}
