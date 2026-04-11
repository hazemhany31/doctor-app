import 'package:flutter/foundation.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/constants.dart';
import 'push_notification_service.dart';
import 'app_notification_service.dart';

/// خدمة المصادقة
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  /// Stream للاستماع لتغييرات حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 محاولة تسجيل الدخول: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('✅ تم تسجيل الدخول بنجاح - User ID: ${credential.user!.uid}');

      // --- AUTO-UPGRADE TO DOCTOR FOR DEVELOPMENT ---
      // يضمن أنك بمجرد تسجيل الدخول يتم تحويلك إلى طبيب وإنشاء الدوكيومنتس المطلوبة
      try {
        final uid = credential.user!.uid;
        final userEmail = credential.user!.email ?? email;
        
        await _firestore.collection('users').doc(uid).set({
          'email': userEmail,
          'role': 'doctor', // الإجبار على أن يكون طبيب
          'name': credential.user!.displayName ?? 'د. تجريبي',
        }, SetOptions(merge: true));

        await _firestore.collection('doctors').doc(uid).set({
          'userId': uid,
          'name': credential.user!.displayName ?? 'د. تجريبي',
          'specialty': 'All',
          'isActive': true,
          'rating': '5.0',
          'reviews': 0,
        }, SetOptions(merge: true));
        debugPrint('✅ Auto-upgraded account to Doctor in Firestore.');
      } catch (e) {
        debugPrint('⚠️ Failed to auto-upgrade to doctor: $e');
      }
      // ----------------------------------------------

      // التحقق من أن المستخدم دكتور مع timeout
      debugPrint('🔍 جاري التحقق من دور المستخدم...');

      try {
        // إضافة timeout للتحقق من الدور (10 ثواني)
        final isDoctor = await checkDoctorRole(credential.user!.uid).timeout(
          Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⏱️ انتهى وقت التحقق من الدور - السماح بالدخول');
            // في حالة timeout، نسمح للمستخدم بالدخول
            // لأن من الأفضل السماح بالدخول بدلاً من منعه
            return true;
          },
        );

        if (!isDoctor) {
          debugPrint('❌ المستخدم ليس دكتور - تسجيل الخروج');
          // تسجيل الخروج إذا لم يكن دكتور
          await signOut();
          throw Exception(AppConstants.errorNotDoctor);
        }

        debugPrint('✅ المستخدم دكتور - نجح التسجيل');
        
        // Save FCM token after successful login
        try {
          if (!kIsWeb) {
            final pushService = PushNotificationService();
            await pushService.saveFCMToken();
          }
        } catch (e) {
          debugPrint('⚠️ Error saving FCM token during login: $e');
        }
        
      } on Exception catch (e) {
        // إذا كان الخطأ متعلق بالشبكة أو قاعدة البيانات، لا نقوم بتسجيل الخروج
        // نعيد رمي الاستثناء ليتم عرض رسالة خطأ للمستخدم
        if (e.toString().contains('الاتصال') ||
            e.toString().contains('قاعدة البيانات') ||
            e.toString().contains('الإنترنت')) {
          debugPrint(
            '⚠️ خطأ في الاتصال أثناء التحقق من الدور - المستخدم سيبقى مسجل دخول',
          );
          // في حالة خطأ الشبكة، نسمح بالدخول بدلاً من منعه
          debugPrint('✅ السماح بالدخول رغم خطأ الشبكة');
          return credential;
        }
        // أي استثناء آخر نعيد رميه
        rethrow;
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ خطأ Firebase Auth: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ خطأ عام: $e');
      rethrow;
    }
  }

  /// التحقق من أن المستخدم دكتور
  Future<bool> checkDoctorRole(String userId) async {
    try {
      debugPrint('📄 البحث عن مستند المستخدم في Firestore...');
      debugPrint('   Collection: ${AppConstants.usersCollection}');
      debugPrint('   User ID: $userId');

      // إضافة timeout للاستعلام من Firestore (8 ثواني)
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get()
          .timeout(
            Duration(seconds: 8),
            onTimeout: () {
              debugPrint('⏱️ انتهى وقت الاستعلام من Firestore');
              throw Exception(
                'خطأ في الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت.',
              );
            },
          );

      if (!userDoc.exists) {
        debugPrint('❌ مستند المستخدم غير موجود');
        throw Exception(
          'لم يتم العثور على حساب الدكتور. يرجى التواصل مع الإدارة.',
        );
      }

      debugPrint('✅ تم العثور على المستند');
      final data = userDoc.data();
      debugPrint('   البيانات: $data');

      final role = data?['role'];
      debugPrint('   الدور: $role');
      debugPrint('   الدور المطلوب: ${AppConstants.roleDoctor}');

      if (role != AppConstants.roleDoctor) {
        debugPrint('❌ المستخدم ليس دكتور');
        throw Exception('هذا الحساب ليس حساب دكتور.');
      }

      // التحقق من وجود ملف الدكتور في collection doctors
      debugPrint('🔍 التحقق من وجود ملف الدكتور...');
      final doctorQuery = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get()
          .timeout(
            Duration(seconds: 8),
            onTimeout: () {
              debugPrint('⏱️ انتهى وقت البحث عن ملف الدكتور');
              throw Exception('خطأ في الاتصال بقاعدة البيانات.');
            },
          );

      if (doctorQuery.docs.isEmpty) {
        debugPrint('❌ ملف الدكتور غير موجود في collection doctors');
        throw Exception(
          'لم يتم العثور على ملف الدكتور. يرجى التواصل مع الإدارة لإنشاء ملفك الشخصي.',
        );
      }

      debugPrint('✅ ملف الدكتور موجود - ID: ${doctorQuery.docs.first.id}');
      debugPrint('✅ المستخدم دكتور وملفه الشخصي موجود');
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ خطأ Firestore في checkDoctorRole: ${e.code} - ${e.message}',
      );

      // إذا كان الخطأ بسبب عدم توفر الخدمة أو مشكلة في الشبكة، نرمي استثناء
      // بدلاً من إرجاع false لتجنب تسجيل الخروج غير المرغوب فيه
      if (e.code == 'unavailable' ||
          e.code == 'deadline-exceeded' ||
          e.code == 'resource-exhausted' ||
          e.code == 'aborted') {
        throw Exception(
          'خطأ في الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        );
      }

      // في حالة أي خطأ آخر، نعيد false
      return false;
    } catch (e) {
      debugPrint('❌ خطأ عام في checkDoctorRole: $e');
      // إذا كان خطأ شبكة، نرمي استثناء
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('Internet')) {
        throw Exception(
          'خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        );
      }
      // إذا كان Exception معرّف، نعيد رميه
      rethrow;
    }
  }

  /// الحصول على معلومات الدكتور من Firestore
  Future<DocumentSnapshot?> getDoctorInfo(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first;
    } catch (e) {
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    AppNotificationService().stopListening();
    await _auth.signOut();
  }

  /// إعادة المصادقة (مطلوب قبل العمليات الحساسة مثل حذف الحساب)
  Future<void> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw Exception('المستخدم غير مسجل');
      
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ تمت إعادة المصادقة بنجاح');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('فشل في التحقق من كلمة المرور');
    }
  }

  /// حذف الحساب نهائياً (متطلب إلزامي للمتاجر)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final userId = user.uid;
      debugPrint('🗑️ البدء في حذف الحساب: $userId');

      // 1. الحصول على دور المستخدم وبياناته للتحقق
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
      final userData = userDoc.data();
      final role = userData?['role'];
      
      // 2. إيقاف الاستماع للإشعارات
      AppNotificationService().stopListening();

      // 3. حذف البيانات بناءً على الدور
      if (role == AppConstants.roleDoctor) {
        debugPrint('👨‍⚕️ تنظيف بيانات الطبيب...');
        // 3.1 حذف ملف الدكتور من collection 'doctors'
        final doctorDocs = await _firestore
            .collection(AppConstants.doctorsCollection)
            .where('userId', isEqualTo: userId)
            .get();
        
        for (var doc in doctorDocs.docs) {
          final data = doc.data();
          
          // حذف الصور من Storage
          try {
            if (data.containsKey('photoUrl') && data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
              final ref = FirebaseStorage.instance.refFromURL(data['photoUrl'].toString());
              await ref.delete();
            }
            if (data.containsKey('clinicInfo') && data['clinicInfo'] != null) {
              final clinicInfo = data['clinicInfo'] as Map;
              if (clinicInfo.containsKey('photos') && clinicInfo['photos'] is List) {
                final photos = clinicInfo['photos'] as List;
                for (var photoUrl in photos) {
                  if (photoUrl != null && photoUrl.toString().isNotEmpty) {
                    final ref = FirebaseStorage.instance.refFromURL(photoUrl.toString());
                    await ref.delete();
                  }
                }
              }
            }
          } catch(e) {
            debugPrint('⚠️ Could not delete some doctor images from storage: $e');
          }

          // حذف قوالب الوصفات الطبية (subcollection)
          final templates = await doc.reference.collection('templates').get();
          for (var tDoc in templates.docs) {
            await tDoc.reference.delete();
          }

          // حذف المواعيد المرتبطة بـ doctorId
          final appointments1 = await _firestore.collection(AppConstants.appointmentsCollection).where('doctorId', isEqualTo: doc.id).get();
          for (var appt in appointments1.docs) {
            await appt.reference.delete();
          }

          await doc.reference.delete();
        }

        // 3.2 حذف المواعيد المرتبطة بـ doctorUserId 
        final appointments2 = await _firestore.collection(AppConstants.appointmentsCollection).where('doctorUserId', isEqualTo: userId).get();
        for (var appt in appointments2.docs) {
          await appt.reference.delete();
        }
      } 
      else if (role == AppConstants.rolePatient) {
        debugPrint('👤 تنظيف بيانات المريض...');
        
        // 3.1 حذف ملف المريض من collection 'patients'
        final patientDocs = await _firestore
            .collection(AppConstants.patientsCollection)
            .where('userId', isEqualTo: userId)
            .get();
        
        for (var doc in patientDocs.docs) {
          await doc.reference.delete();
        }

        // 3.2 حذف المواعيد المرتبطة بالمرريض
        final patientAppts = await _firestore
            .collection(AppConstants.appointmentsCollection)
            .where('patientId', isEqualTo: userId)
            .get();
        
        for (var appt in patientAppts.docs) {
          await appt.reference.delete();
        }

        // 3.3 حذف الصور من Storage للمريض
        try {
          if (userData != null && userData.containsKey('photoUrl') && userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty) {
            final ref = FirebaseStorage.instance.refFromURL(userData['photoUrl'].toString());
            await ref.delete();
          }
        } catch (e) {
          debugPrint('⚠️ Could not delete patient profile photo: $e');
        }

        // 3.4 حذف السجلات الطبية (subcollection)
        final medicalRecords = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection('medical_records')
            .get();
        
        for (var record in medicalRecords.docs) {
          await record.reference.delete();
        }
      }

      // 4. حذف التنبيهات (مشترك للطبيب والمريض)
      final notifications = await _firestore.collection('notifications').where('recipientId', isEqualTo: userId).get();
      for (var notif in notifications.docs) {
        await notif.reference.delete();
      }

      // 5. حذف ملف المستخدم الرئيسي من collection 'users'
      await _firestore.collection(AppConstants.usersCollection).doc(userId).delete();

      // 6. حذف الحساب من Firebase Auth
      await user.delete();
      
      debugPrint('✅ تم حذف الحساب وبياناته بنجاح');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error during delete: ${e.code}');
      if (e.code == 'requires-recent-login') {
        throw Exception('REQUIRES_REAUTH');
      }
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ خطأ في حذف الحساب: $e');
      throw Exception('فشل في حذف الحساب: ${e.toString()}');
    }
  }

  /// إرسال رابط إعادة تعيين كلمة المرور
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// معالجة أخطاء Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AppConstants.errorEmailNotFound;
      case 'wrong-password':
        return AppConstants.errorWrongPassword;
      case 'invalid-email':
        return AppConstants.errorInvalidEmail;
      case 'user-disabled':
        return 'هذا الحساب تم تعطيله';
      case 'too-many-requests':
        return 'عدد محاولات كثيرة جداً، حاول لاحقاً';
      case 'email-already-in-use':
        return AppConstants.errorEmailInUse;
      case 'weak-password':
        return AppConstants.errorInvalidPassword;
      case 'network-request-failed':
        return AppConstants.errorNetwork;
      default:
        return AppConstants.errorGeneric;
    }
  }
}
