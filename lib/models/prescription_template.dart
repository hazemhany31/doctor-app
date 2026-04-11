import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment.dart';

/// نموذج قالب الوصفة الطبية المحفوظة
class PrescriptionTemplate {
  final String id;
  final String name;
  final List<AppointmentMedicine> medicines;
  final DateTime createdAt;

  PrescriptionTemplate({
    required this.id,
    required this.name,
    required this.medicines,
    required this.createdAt,
  });

  factory PrescriptionTemplate.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return PrescriptionTemplate(
      id: doc.id,
      name: map['name'] ?? '',
      medicines: (map['medicines'] as List<dynamic>?)
              ?.map((e) => AppointmentMedicine.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
