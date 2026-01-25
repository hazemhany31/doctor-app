import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // التحقق من أن المستخدم دكتور
      final isDoctor = await checkDoctorRole(credential.user!.uid);
      if (!isDoctor) {
        // تسجيل الخروج إذا لم يكن دكتور
        await signOut();
        throw Exception(AppConstants.errorNotDoctor);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// التحقق من أن المستخدم دكتور
  Future<bool> checkDoctorRole(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final role = userDoc.data()?['role'];
      return role == AppConstants.roleDoctor;
    } catch (e) {
      return false;
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
    await _auth.signOut();
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
