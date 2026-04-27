import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/donation.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'donations';

  // Get all active donations
  Stream<List<Donation>> getDonations() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => Donation.fromFirestore(doc)).toList();
      // Sort client-side to avoid index requirement
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Upload donation image to storage
  Future<String> uploadDonationImage(File imageFile) async {
    try {
      final String fileName =
          'donation_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('donations/$fileName');
      final Uint8List fileBytes = await imageFile.readAsBytes();
      final uploadTask = storageRef.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Create new donation
  Future<void> createDonation({
    required String medicineName,
    required String? dosage,
    required int quantity,
    required DateTime expiryDate,
    required String location,
    required String imageUrl,
    required String donorName,
    String? donorPhotoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final donation = Donation(
      id: '', // Will be set by Firestore
      medicineName: medicineName,
      dosage: dosage,
      expiryDate: expiryDate,
      quantity: quantity,
      location: location,
      userId: user.uid,
      donorName: donorName,
      donorPhotoUrl: donorPhotoUrl,
      imageUrl: imageUrl,
      status: 'available',
      createdAt: DateTime.now(),
      userType: 'doctor',
      verifiedBy: [user.uid], // Automatically verified by the donor doctor
      isRecommended: true,
    );

    await _firestore.collection(_collection).add(donation.toMap());
  }

  // Doctor recommends/verifies a medicine
  Future<void> recommendMedicine(String donationId, String doctorId) async {
    try {
      await _firestore.collection(_collection).doc(donationId).update({
        'verifiedBy': FieldValue.arrayUnion([doctorId]),
        'isRecommended': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Doctor removes recommendation
  Future<void> unrecommendMedicine(String donationId, String doctorId) async {
    try {
      // Note: We only set isRecommended to false if NO doctors verify it anymore.
      // For simplicity, we just remove the current doctor from list.
      final doc = await _firestore.collection(_collection).doc(donationId).get();
      final currentVerified = List<String>.from(doc.data()?['verifiedBy'] ?? []);
      currentVerified.remove(doctorId);
      
      await _firestore.collection(_collection).doc(donationId).update({
        'verifiedBy': FieldValue.arrayRemove([doctorId]),
        'isRecommended': currentVerified.isNotEmpty,
      });
    } catch (e) {
      rethrow;
    }
  }
  // Delete donation
  Future<void> deleteDonation(String donationId) async {
    try {
      await _firestore.collection(_collection).doc(donationId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
