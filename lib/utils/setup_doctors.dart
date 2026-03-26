import 'package:flutter/foundation.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script لإضافة الدكاترة في Firebase
///
/// الاستخدام:
/// 1. افتح التطبيق
/// 2. شغل الـ function ده من main أو من شاشة معينة
/// 3. هيضيف كل الدكاترة في Authentication و Firestore

class DoctorSetupScript {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // بيانات الدكاترة
  final List<Map<String, dynamic>> doctors = [
    {
      'name': 'Dr. Magdy Mohammad Fakhr Hussein',
      'email': 'dr.magdy@nbig.com',
      'password': 'Magdy@2024',
      'specialty': 'Biotechnology & Genetic Engineering',
      'yearsOfExperience': 15,
      'rating': 4.8,
      'reviewsCount': 120,
      'bio':
          'PhD in Biotechnology, University of Sadat City. Expert in Genetic Engineering and Biotechnology Research.',
      'education': [
        'PhD in Biotechnology - University of Sadat City',
        'Master of Science (M.Sc.) in Genetic Engineering',
        'Faculty of Science, Department (Chemistry & Physics), Cairo University',
      ],
      'certifications': [
        'Diploma in PCR or Polymerase Chain Reaction technique',
        'Diploma in Quality Management (ISO 9001, ISO 14001)',
      ],
    },
    {
      'name': 'Dr. Shahd Al-Hamdani',
      'email': 'dr.shahd@nbig.com',
      'password': 'Shahd@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 11,
      'rating': 4.9,
      'reviewsCount': 250,
      'bio': 'خبرة أكثر من 11 سنة في جميع معالجات الأسنان',
      'education': ['Doctor of Dental Surgery (DDS)'],
      'certifications': [
        'الزمالة الإيطالية لتطبيقات الليزر في طب الأسنان',
        'معتمدة من جمعية طب الأسنان الأمريكية لحشوات العصب (ADA)',
        'معتمدة من جمعية طب الأسنان الأمريكية لزراعة الأسنان (ADA)',
      ],
    },
    {
      'name': 'Dr. Ahmed Jameel',
      'email': 'dr.ahmed@nbig.com',
      'password': 'Ahmed@2024',
      'specialty': 'Dentistry & Dental Surgery',
      'yearsOfExperience': 13,
      'rating': 4.7,
      'reviewsCount': 180,
      'bio': 'طبيب وجراح أسنان. خبرة واسعة في معالجات الأسنان وزراعة الأسنان.',
      'education': [
        'دراسات عليا في طب أسنان الأطفال',
        'دراسات عليا في زراعة الأسنان',
      ],
      'certifications': [
        'خبرة في مراكز شايني وايت (سنتين)',
        'خبرة في مراكز د. هيثم (4 سنوات)',
        'عيادة خاصة منذ 7 سنوات',
      ],
    },
    {
      'name': 'Dr. Youssef Taher Mohammad',
      'email': 'dr.youssef@nbig.com',
      'password': 'Youssef@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.6,
      'reviewsCount': 85,
      'bio': 'طبيب أسنان متخصص في العلاجات التحفظية والتجميلية',
      'education': ['Doctor of Dental Surgery (DDS)'],
      'certifications': [],
    },
    {
      'name': 'Dr. Ahmed Khaled',
      'email': 'dr.ahmedkhaled@nbig.com',
      'password': 'AhmedK@2024',
      'specialty': 'Orthodontics',
      'yearsOfExperience': 10,
      'rating': 4.9,
      'reviewsCount': 200,
      'bio': 'استشاري تقويم الأسنان. عضو سابق في هيئة التدريس بجامعة القاهرة.',
      'education': ['ماجستير تقويم الأسنان - جامعة القاهرة'],
      'certifications': [
        'الزمالة البريطانية في تقويم الأسنان',
        'عضو سابق في هيئة التدريس بطب الأسنان - جامعة القاهرة',
      ],
    },
    {
      'name': 'Dr. Adham Ezz El-Din',
      'email': 'dr.adham@nbig.com',
      'password': 'Adham@2024',
      'specialty': 'Neurosurgery',
      'yearsOfExperience': 12,
      'rating': 5.0,
      'reviewsCount': 150,
      'bio':
          'استشاري ومدرس جراحة المخ والأعصاب والعمود الفقري بكلية الطب جامعة القاهرة',
      'education': [
        'دكتوراه جراحة المخ والأعصاب - جامعة القاهرة',
        'مدرس بمستشفيات القصر العيني ومستشفى أبو الريش للأطفال',
      ],
      'certifications': [
        'استشاري جراحة المخ والأعصاب',
        'متخصص في جراحة العمود الفقري وأورام المخ',
      ],
      'clinics': ['المهندسين', 'الدقي', '6 أكتوبر'],
    },
  ];

  /// تشغيل السكريبت لإضافة كل الدكاترة
  Future<void> setupAllDoctors() async {
    debugPrint('🚀 بدء إضافة الدكاترة...\n');

    for (var doctorData in doctors) {
      try {
        await _createDoctorAccount(doctorData);
        debugPrint('✅ تم إضافة: ${doctorData['name']}\n');
      } catch (e) {
        debugPrint('❌ فشل إضافة ${doctorData['name']}: $e\n');
      }
    }

    debugPrint('🎉 انتهى إضافة الدكاترة!');
  }

  /// إضافة دكتور واحد
  Future<void> _createDoctorAccount(Map<String, dynamic> doctorData) async {
    // 1. إنشاء حساب في Authentication
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: doctorData['email'],
      password: doctorData['password'],
    );

    final userId = userCredential.user!.uid;
    debugPrint('  📧 تم إنشاء حساب: ${doctorData['email']}');
    debugPrint('  🆔 User ID: $userId');

    // 2. إضافة document في collection users (للـ role)
    await _firestore.collection('users').doc(userId).set({
      'email': doctorData['email'],
      'role': 'doctor',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('  👤 تم إضافة user document');

    // 3. إضافة document في collection doctors
    await _firestore.collection('doctors').add({
      'userId': userId,
      'name': doctorData['name'],
      'email': doctorData['email'],
      'specialty': doctorData['specialty'],
      'yearsOfExperience': doctorData['yearsOfExperience'],
      'rating': doctorData['rating'],
      'reviewsCount': doctorData['reviewsCount'],
      'bio': doctorData['bio'],
      'education': doctorData['education'],
      'certifications': doctorData['certifications'],
      'clinics': doctorData['clinics'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('  🩺 تم إضافة doctor document');
  }

  /// طباعة بيانات تسجيل الدخول
  void printCredentials() {
    debugPrint('\n📋 بيانات تسجيل الدخول للدكاترة:\n');
    debugPrint('=' * 60);
    for (var doctor in doctors) {
      debugPrint('الاسم: ${doctor['name']}');
      debugPrint('Email: ${doctor['email']}');
      debugPrint('Password: ${doctor['password']}');
      debugPrint('-' * 60);
    }
  }
}

/// مثال على الاستخدام:
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   final script = DoctorSetupScript();
///   await script.setupAllDoctors();
///   script.printCredentials();
/// }
