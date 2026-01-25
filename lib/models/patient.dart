import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات المريض
class Patient {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final DateTime? dateOfBirth;
  final String? gender; // 'male' or 'female'
  final String? bloodType;
  final String? address;
  final List<String> chronicDiseases;
  final List<String> allergies;
  final List<String> previousSurgeries;
  final List<String> currentMedications;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.address,
    this.chronicDiseases = const [],
    this.allergies = const [],
    this.previousSurgeries = const [],
    this.currentMedications = const [],
    required this.createdAt,
  });

  /// حساب العمر
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// إنشاء Patient من Firestore DocumentSnapshot
  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Patient.fromMap(doc.id, data);
  }

  /// إنشاء Patient من Map
  factory Patient.fromMap(String id, Map<String, dynamic> map) {
    return Patient(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: map['gender'],
      bloodType: map['bloodType'],
      address: map['address'],
      chronicDiseases: List<String>.from(map['chronicDiseases'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      previousSurgeries: List<String>.from(map['previousSurgeries'] ?? []),
      currentMedications: List<String>.from(map['currentMedications'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل Patient إلى Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'gender': gender,
      'bloodType': bloodType,
      'address': address,
      'chronicDiseases': chronicDiseases,
      'allergies': allergies,
      'previousSurgeries': previousSurgeries,
      'currentMedications': currentMedications,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Patient copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? address,
    List<String>? chronicDiseases,
    List<String>? allergies,
    List<String>? previousSurgeries,
    List<String>? currentMedications,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      allergies: allergies ?? this.allergies,
      previousSurgeries: previousSurgeries ?? this.previousSurgeries,
      currentMedications: currentMedications ?? this.currentMedications,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
