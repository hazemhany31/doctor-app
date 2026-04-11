
import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات الدكتور
class Doctor {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String specialization;
  final int yearsOfExperience;
  final List<String> certificates;
  final String? bio;
  final ClinicInfo clinicInfo;
  final Map<String, DaySchedule> schedule;
  final double rating;
  final int reviewsCount;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  Doctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.specialization,
    required this.yearsOfExperience,
    this.certificates = const [],
    this.bio,
    required this.clinicInfo,
    this.schedule = const {},
    this.rating = 0.0,
    this.reviewsCount = 0,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
  });

  /// إنشاء Doctor من Firestore DocumentSnapshot
  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Doctor.fromMap(doc.id, data);
  }

  /// إنشاء Doctor من Map
  factory Doctor.fromMap(String id, Map<String, dynamic> map) {
    return Doctor(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      specialization: map['specialization'] ?? '',
      yearsOfExperience: (map['yearsOfExperience'] ?? 0) is int
          ? map['yearsOfExperience']
          : int.tryParse(map['yearsOfExperience'].toString()) ?? 0,
      certificates: List<String>.from(map['certificates'] ?? []),
      bio: map['bio'],
      clinicInfo: ClinicInfo.fromMap(map['clinicInfo'] ?? {}),
      schedule:
          (map['schedule'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, DaySchedule.fromMap(value)),
          ) ??
          {},
      rating: (map['rating'] ?? 0.0) is double
          ? (map['rating'] ?? 0.0)
          : double.tryParse(map['rating'].toString()) ?? 0.0,
      reviewsCount: (map['reviewsCount'] ?? 0) is int
          ? map['reviewsCount']
          : int.tryParse(map['reviewsCount'].toString()) ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  /// تحويل Doctor إلى Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      'certificates': certificates,
      'bio': bio,
      'clinicInfo': clinicInfo.toMap(),
      'schedule': schedule.map((key, value) => MapEntry(key, value.toMap())),
      'rating': rating,
      'reviewsCount': reviewsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  Doctor copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? specialization,
    int? yearsOfExperience,
    List<String>? certificates,
    String? bio,
    ClinicInfo? clinicInfo,
    Map<String, DaySchedule>? schedule,
    double? rating,
    int? reviewsCount,
    DateTime? createdAt,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return Doctor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      specialization: specialization ?? this.specialization,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certificates: certificates ?? this.certificates,
      bio: bio ?? this.bio,
      clinicInfo: clinicInfo ?? this.clinicInfo,
      schedule: schedule ?? this.schedule,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// معلومات العيادة
class ClinicInfo {
  final String name;
  final String address;
  final String? phone;
  final String? workingHours;
  final double? latitude;
  final double? longitude;
  final double fees;
  final List<String> photos;

  ClinicInfo({
    required this.name,
    required this.address,
    this.phone,
    this.workingHours,
    this.latitude,
    this.longitude,
    required this.fees,
    this.photos = const [],
  });

  factory ClinicInfo.fromMap(Map<String, dynamic> map) {
    return ClinicInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'],
      workingHours: map['workingHours'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      fees: (map['fees'] ?? 0.0).toDouble(),
      photos: List<String>.from(map['photos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'workingHours': workingHours,
      'latitude': latitude,
      'longitude': longitude,
      'fees': fees,
      'photos': photos,
    };
  }
}

/// جدول يوم العمل
class DaySchedule {
  final bool isAvailable;
  final String? startTime; // Format: "09:00"
  final String? endTime; // Format: "17:00"
  final int? slotDuration; // في الدقائق
  final int? breakDuration; // استراحة بين المواعيد في الدقائق

  DaySchedule({
    required this.isAvailable,
    this.startTime,
    this.endTime,
    this.slotDuration,
    this.breakDuration,
  });

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      isAvailable: map['isAvailable'] ?? false,
      startTime: map['startTime'],
      endTime: map['endTime'],
      slotDuration: map['slotDuration'],
      breakDuration: map['breakDuration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isAvailable': isAvailable,
      'startTime': startTime,
      'endTime': endTime,
      'slotDuration': slotDuration,
      'breakDuration': breakDuration,
    };
  }
}
