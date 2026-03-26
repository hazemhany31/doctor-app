import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج السجل الطبي المطابق لما يرفعه المريض في تطبيق nbig_app
class MedicalRecord {
  final String id;
  final String name;
  final String url;
  final String type;
  final DateTime date;

  MedicalRecord({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.date,
  });

  /// إنشاء MedicalRecord من Firestore DocumentSnapshot
  factory MedicalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecord.fromMap(doc.id, data);
  }

  /// إنشاء MedicalRecord من Map
  factory MedicalRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return MedicalRecord(
      id: id,
      name: map['name'] ?? 'ملف طبي',
      url: map['url'] ?? '',
      type: map['type'] ?? 'unknown',
      date: parsedDate,
    );
  }

  /// تحويل MedicalRecord إلى Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type,
      // nbig app stores as ISO string: DateTime.now().toIso8601String()
      'date': date.toIso8601String(),
    };
  }

  MedicalRecord copyWith({
    String? id,
    String? name,
    String? url,
    String? type,
    DateTime? date,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }
}
