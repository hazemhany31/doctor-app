import 'package:flutter/foundation.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

/// إضافة بيانات تجريبية للدكتور الحالي
Future<void> seedDoctorData() async {
  try {
    final authService = AuthService();
    final firestore = FirebaseFirestore.instance;

    // الحصول على المستخدم الحالي
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      debugPrint('❌ لا يوجد مستخدم مسجل دخول');
      return;
    }

    debugPrint('🔵 المستخدم الحالي: ${currentUser.email}');
    debugPrint('🔵 userId: ${currentUser.uid}');

    // التحقق من وجود دكتور بالفعل
    final existingDoctors = await firestore
        .collection('doctors')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    if (existingDoctors.docs.isNotEmpty) {
      debugPrint('✅ يوجد بالفعل بيانات دكتور لهذا المستخدم');
      debugPrint('   Doctor ID: ${existingDoctors.docs.first.id}');
      return;
    }

    // إنشاء بيانات دكتور تجريبية
    final doctorData = {
      'userId': currentUser.uid,
      'name': 'د. ${currentUser.displayName ?? "أحمد محمد"}',
      'email': currentUser.email ?? 'doctor@example.com',
      'phone': '01234567890',
      'photoUrl': currentUser.photoURL,
      'specialization': 'طبيب عام',
      'yearsOfExperience': 5,
      'certificates': ['بكالوريوس الطب والجراحة', 'دبلوم الباطنة'],
      'bio': 'طبيب متخصص في الطب العام مع خبرة 5 سنوات',
      'clinicInfo': {
        'name': 'عيادة النور الطبية',
        'address': 'القاهرة، مصر',
        'latitude': 30.0444,
        'longitude': 31.2357,
        'fees': 200.0,
        'photos': [],
      },
      'schedule': {
        'saturday': {
          'isAvailable': true,
          'startTime': '09:00',
          'endTime': '17:00',
          'slotDuration': 30,
        },
        'sunday': {
          'isAvailable': true,
          'startTime': '09:00',
          'endTime': '17:00',
          'slotDuration': 30,
        },
        'monday': {
          'isAvailable': true,
          'startTime': '09:00',
          'endTime': '17:00',
          'slotDuration': 30,
        },
        'tuesday': {
          'isAvailable': true,
          'startTime': '09:00',
          'endTime': '17:00',
          'slotDuration': 30,
        },
        'wednesday': {
          'isAvailable': true,
          'startTime': '09:00',
          'endTime': '17:00',
          'slotDuration': 30,
        },
        'thursday': {
          'isAvailable': true,
          'startTime': '09:00',
          'endTime': '14:00',
          'slotDuration': 30,
        },
        'friday': {
          'isAvailable': false,
          'startTime': null,
          'endTime': null,
          'slotDuration': null,
        },
      },
      'rating': 4.5,
      'reviewsCount': 25,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // إضافة البيانات إلى Firestore
    final docRef = await firestore.collection('doctors').add(doctorData);

    debugPrint('✅ تم إضافة بيانات الدكتور بنجاح!');
    debugPrint('   Doctor ID: ${docRef.id}');
    debugPrint('   Email: ${doctorData['email']}');
    debugPrint('   Name: ${doctorData['name']}');
  } catch (e) {
    debugPrint('❌ خطأ في إضافة البيانات: $e');
  }
}
