import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String medicineName;
  final String? dosage;
  final DateTime expiryDate;
  final int quantity;
  final String location;
  final String userId; // Standardized from donorId
  final String donorName;
  final String? donorPhotoUrl;
  final String imageUrl; // Standardized from medicineImageUrl
  final String status; // 'available', 'pending', 'donated'
  final DateTime createdAt;
  final String userType; // 'patient' / 'doctor'
  final List<String> verifiedBy; // List of doctorIds who recommended this
  final bool isRecommended; // For compatibility
  final String? phone;

  Donation({
    required this.id,
    required this.medicineName,
    this.dosage,
    required this.expiryDate,
    required this.quantity,
    required this.location,
    required this.userId,
    required this.donorName,
    this.donorPhotoUrl,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.userType,
    required this.verifiedBy,
    this.isRecommended = false,
    this.phone,
  });

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      medicineName: data['medicineName'] ?? '',
      dosage: data['dosage'],
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      quantity: int.tryParse(data['quantity']?.toString() ?? '0') ?? 0,
      location: data['location'] ?? '',
      userId: data['userId'] ?? data['donorId'] ?? '',
      donorName: data['donorName'] ?? '',
      donorPhotoUrl: data['donorPhotoUrl'],
      imageUrl: data['imageUrl'] ?? data['medicineImageUrl'] ?? '',
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userType: data['userType'] ?? 'patient',
      verifiedBy: List<String>.from(data['verifiedBy'] ?? []),
      isRecommended: data['isRecommended'] ?? false,
      phone: data['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'quantity': quantity,
      'location': location,
      'userId': userId,
      'donorName': donorName,
      'donorPhotoUrl': donorPhotoUrl,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'userType': userType,
      'verifiedBy': verifiedBy,
      'isRecommended': isRecommended,
      'phone': phone,
    };
  }
}
