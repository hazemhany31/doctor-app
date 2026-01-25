import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج السجل الطبي
class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String? appointmentId;
  final String diagnosis;
  final List<String> symptoms;
  final List<Prescription> prescriptions;
  final List<String> attachments; // URLs للأشعة والتحاليل
  final String? notes;
  final DateTime createdAt;

  // بيانات إضافية للعرض
  final String? doctorName;
  final String? patientName;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.appointmentId,
    required this.diagnosis,
    this.symptoms = const [],
    this.prescriptions = const [],
    this.attachments = const [],
    this.notes,
    required this.createdAt,
    this.doctorName,
    this.patientName,
  });

  /// إنشاء MedicalRecord من Firestore DocumentSnapshot
  factory MedicalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecord.fromMap(doc.id, data);
  }

  /// إنشاء MedicalRecord من Map
  factory MedicalRecord.fromMap(String id, Map<String, dynamic> map) {
    return MedicalRecord(
      id: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      appointmentId: map['appointmentId'],
      diagnosis: map['diagnosis'] ?? '',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      prescriptions:
          (map['prescriptions'] as List<dynamic>?)
              ?.map((e) => Prescription.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      attachments: List<String>.from(map['attachments'] ?? []),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      doctorName: map['doctorName'],
      patientName: map['patientName'],
    );
  }

  /// تحويل MedicalRecord إلى Map
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'prescriptions': prescriptions.map((e) => e.toMap()).toList(),
      'attachments': attachments,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MedicalRecord copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? appointmentId,
    String? diagnosis,
    List<String>? symptoms,
    List<Prescription>? prescriptions,
    List<String>? attachments,
    String? notes,
    DateTime? createdAt,
    String? doctorName,
    String? patientName,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      appointmentId: appointmentId ?? this.appointmentId,
      diagnosis: diagnosis ?? this.diagnosis,
      symptoms: symptoms ?? this.symptoms,
      prescriptions: prescriptions ?? this.prescriptions,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
    );
  }
}

/// نموذج الوصفة الطبية
class Prescription {
  final String medication;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  Prescription({
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      medication: map['medication'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? '',
      instructions: map['instructions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medication': medication,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}
