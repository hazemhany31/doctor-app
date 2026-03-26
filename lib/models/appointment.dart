
import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج الدواء في الوصفة الطبية
class AppointmentMedicine {
  final String name;
  final String dosage;
  final String frequency;
  final int? frequencyHours; // e.g., 8 for "Every 8 hours"
  final String duration;
  DateTime? reminderTime;
  final bool isTaken;

  AppointmentMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.frequencyHours,
    required this.duration,
    this.reminderTime,
    this.isTaken = false,
  });

  factory AppointmentMedicine.fromMap(Map<String, dynamic> map) {
    return AppointmentMedicine(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      frequencyHours: map['frequencyHours'] is int ? map['frequencyHours'] : null,
      duration: map['duration'] ?? '',
      reminderTime: map['reminderTime'] != null
          ? (map['reminderTime'] as Timestamp).toDate()
          : null,
      isTaken: map['isTaken'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'frequencyHours': frequencyHours,
      'duration': duration,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'isTaken': isTaken,
    };
  }
}

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

  // تقرير المريض (يكتبه المريض عند الحجز)
  final String? patientReport;

  // الوصفة الطبية (يكتبها الدكتور)
  final List<AppointmentMedicine> prescriptions;

  // ملاحظات الدكتور
  final String? doctorNotes;

  // وقت تنبيه الدواء (يضبطه الدكتور)
  final DateTime? medicationReminderTime;

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
    this.patientReport,
    this.prescriptions = const [],
    this.doctorNotes,
    this.medicationReminderTime,
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
    // محاولة الحصول على الوقت والتاريخ بشكل مرن
    DateTime appointmentDateTime = DateTime.now();
    final dtValue = map['dateTime'];
    
    if (dtValue is Timestamp) {
      appointmentDateTime = dtValue.toDate();
    }
    
    // إذا كان الوقت هو منتصف الليل تماماً (00:00)، أو الحقل غير موجود كـ Timestamp
    // نحاول القراءة من حقول 'date' و 'time' المنفصلة (التي يستخدمها تطبيق المريض)
    if (dtValue == null || (appointmentDateTime.hour == 0 && appointmentDateTime.minute == 0)) {
      final dateVal = map['date']; // e.g. "Mon, 18" or "2024-03-18"
      final timeVal = map['time']; // e.g. "10:30 AM"
      
      final dateStr = dateVal is String ? dateVal : dateVal?.toString();
      final timeStr = timeVal is String ? timeVal : timeVal?.toString();
      
      if (dateStr != null && timeStr != null) {
        try {
          // تحليل الوقت (timeStr) مثل "10:30 AM"
          final parts = timeStr.trim().split(' ');
          if (parts.length >= 2) {
            final hm = parts[0].split(':');
            int hour = int.tryParse(hm[0]) ?? 0;
            int minute = hm.length > 1 ? (int.tryParse(hm[1]) ?? 0) : 0;
            final isPM = parts[1].toUpperCase() == 'PM';
            
            if (isPM && hour != 12) hour += 12;
            if (!isPM && hour == 12) hour = 0;
            
            // نستخدم التاريخ من الـ Timestamp الأصلي (لو موجود) أو التاريخ الحالي
            // ولكن نحدث الساعة والدقيقة
            appointmentDateTime = DateTime(
              appointmentDateTime.year,
              appointmentDateTime.month,
              appointmentDateTime.day,
              hour,
              minute,
            );
          }
        } catch (e) {
          // Ignore parsing errors for fallback
        }
      }
    }

    return Appointment(
      id: id,
      doctorId: map['doctorId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      dateTime: appointmentDateTime,
      duration: map['duration'] is int ? map['duration'] : 20,
      status: map['status']?.toString() ?? 'pending',
      type: map['type']?.toString() ?? 'new',
      notes: map['notes']?.toString(),
      cancelReason: map['cancelReason']?.toString(),
      createdAt: (map['createdAt'] is Timestamp) ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp) ? (map['updatedAt'] as Timestamp).toDate() : null,
      patientReport: map['patientReport']?.toString() ?? map['report']?.toString(),
      prescriptions: (map['prescriptions'] as List<dynamic>?)
              ?.map((e) => AppointmentMedicine.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      doctorNotes: map['doctorNotes']?.toString(),
      medicationReminderTime:
          (map['medicationReminderTime'] is Timestamp) ? (map['medicationReminderTime'] as Timestamp).toDate() : null,
      patientName: map['patientName']?.toString(),
      patientPhotoUrl: map['patientPhotoUrl']?.toString(),
      doctorName: map['doctorName']?.toString(),
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
      'patientReport': patientReport,
      'prescriptions': prescriptions.map((e) => e.toMap()).toList(),
      'doctorNotes': doctorNotes,
      'medicationReminderTime': medicationReminderTime != null
          ? Timestamp.fromDate(medicationReminderTime!)
          : null,
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
    String? patientReport,
    List<AppointmentMedicine>? prescriptions,
    String? doctorNotes,
    DateTime? medicationReminderTime,
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
      patientReport: patientReport ?? this.patientReport,
      prescriptions: prescriptions ?? this.prescriptions,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      medicationReminderTime:
          medicationReminderTime ?? this.medicationReminderTime,
      patientName: patientName ?? this.patientName,
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      doctorName: doctorName ?? this.doctorName,
    );
  }
}
