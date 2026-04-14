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
    // Added from patient data image
    {
      'name': 'Dr. Yahya El-Adawy Shousha',
      'email': 'dr.yahya@nbig.com',
      'password': 'Yahya@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب أسنان متخصص',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Mohamed Sabry',
      'email': 'dr.mohamed.sabry@nbig.com',
      'password': 'Mohamed@2024',
      'specialty': 'Ophthalmology',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'أخصائي طب وجراحة العيون',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Maher Hassan Aglan',
      'email': 'dr.maher@nbig.com',
      'password': 'Maher@2024',
      'specialty': 'Surgery',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'استشاري الجراحة العامة',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Mohamed Sayed Taha Sawi',
      'email': 'dr.mohamed.sawi@nbig.com',
      'password': 'Mohamed@2024',
      'specialty': 'General Practice',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب عام',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Hazem Abdelrahman',
      'email': 'dr.hazem@nbig.com',
      'password': 'Hazem@2024',
      'specialty': 'General Practice',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب عام',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Heba Farid Ali',
      'email': 'dr.heba@nbig.com',
      'password': 'Heba@2024',
      'specialty': 'Investment',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'استثمار عيادات',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Ashraf Mohamed Thabet',
      'email': 'dr.ashraf@nbig.com',
      'password': 'Ashraf@2024',
      'specialty': 'General Practice',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب عام',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Shawky Abdelrahman',
      'email': 'dr.shawky@nbig.com',
      'password': 'Shawky@2024',
      'specialty': 'General Practice',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب بشري',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Samira Shaaban',
      'email': 'dr.samira@nbig.com',
      'password': 'Samira@2024',
      'specialty': 'Dentistry & General',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'العيادات اللي مفتوحين على بعض أسنان / بشري',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Hoda Ali El-Sayed',
      'email': 'dr.hoda@nbig.com',
      'password': 'Hoda@2024',
      'specialty': 'Orthopedics & Pediatrics',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طب بشري عظام - اطفال',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Sameh Abdel Tawab',
      'email': 'dr.sameh@nbig.com',
      'password': 'Sameh@2024',
      'specialty': 'Ophthalmology',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طب وجراحة عيون',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Mohamed Ali Saleh',
      'email': 'dr.mohamed.saleh@nbig.com',
      'password': 'Mohamed@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Taher Mohamed Hassan Eissa',
      'email': 'dr.taher@nbig.com',
      'password': 'Taher@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Mohamed Nada Abdel Naby',
      'email': 'dr.mohamed.nada@nbig.com',
      'password': 'Mohamed@2024',
      'specialty': 'General Practice',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب عام',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Atef',
      'email': 'dr.atef@nbig.com',
      'password': 'Atef@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Ali Salah',
      'email': 'dr.ali.salah@nbig.com',
      'password': 'Ali@2024',
      'specialty': 'General Medicine',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب بشري عام',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Mohamed Mostafa',
      'email': 'dr.mohamed.mostafa@nbig.com',
      'password': 'Mohamed@2024',
      'specialty': 'Obstetrics & Gynecology',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'أخصائي نساء وتوليد',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Ahmed Shawkat Mohamed',
      'email': 'dr.ahmed.shawkat@nbig.com',
      'password': 'Ahmed@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Ahmed Abdel Raouf',
      'email': 'dr.ahmed.raouf@nbig.com',
      'password': 'Ahmed@2024',
      'specialty': 'Investment',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'استثمار',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Nadia El-Meligy',
      'email': 'dr.nadia@nbig.com',
      'password': 'Nadia@2024',
      'specialty': 'Dermatology & Cosmetology',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'أخصائية جلدية وتجميل',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Suhaila Ahmed Mahmoud',
      'email': 'dr.suhaila@nbig.com',
      'password': 'Suhaila@2024',
      'specialty': 'General Practice',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيبة عامة',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Shahd Sarmad',
      'email': 'dr.shahd.sarmad@nbig.com',
      'password': 'Shahd@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيبة أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Ahmed Mohamed Thabet',
      'email': 'dr.ahmed.thabet@nbig.com',
      'password': 'Ahmed@2024',
      'specialty': 'Dermatology & Cosmetology',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'استثمار - تجميل',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Mowafi Mohamed Dahab',
      'email': 'dr.mowafi@nbig.com',
      'password': 'Mowafi@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Alaa Abdelhamid Sabry',
      'email': 'dr.alaa@nbig.com',
      'password': 'Alaa@2024',
      'specialty': 'General Medicine',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب بشري عام',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Afaf Ahmed',
      'email': 'dr.afaf@nbig.com',
      'password': 'Afaf@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيبة أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Ghada Abdelmoneim',
      'email': 'dr.ghada@nbig.com',
      'password': 'Ghada@2024',
      'specialty': 'Dermatology & Cosmetology',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'أخصائية جلدية وتجميل',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Mohamed Atef Abdelaziz',
      'email': 'dr.mohamed.atef@nbig.com',
      'password': 'Mohamed@2024',
      'specialty': 'Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيب أسنان',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Waleed Abdelmoneim',
      'email': 'dr.waleed@nbig.com',
      'password': 'Waleed@2024',
      'specialty': 'Dentistry & General',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'اسنان - بشري',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Sahar Abdelhalim',
      'email': 'dr.sahar@nbig.com',
      'password': 'Sahar@2024',
      'specialty': 'Pediatric Dentistry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'اسنان - اطفال',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Asmaa Mohamed Maher',
      'email': 'dr.asmaa@nbig.com',
      'password': 'Asmaa@2024',
      'specialty': 'General Practice',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيبة عامة',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Reda Abdel-Aal',
      'email': 'dr.reda@nbig.com',
      'password': 'Reda@2024',
      'specialty': 'ENT',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'اخصائي انف واذن',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Essam Abu El-Makarim',
      'email': 'dr.essam@nbig.com',
      'password': 'Essam@2024',
      'specialty': 'Physical Therapy',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'أخصائي علاج طبيعي',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Khaled',
      'email': 'dr.khaled@nbig.com',
      'password': 'Khaled@2024',
      'specialty': 'Investment',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'استثمار',
      'education': [],
      'certifications': [],
    },
    {
      'name': 'Dr. Alia',
      'email': 'dr.alia@nbig.com',
      'password': 'Alia@2024',
      'specialty': 'Psychiatry',
      'yearsOfExperience': 5,
      'rating': 4.5,
      'reviewsCount': 50,
      'bio': 'طبيبة نفسية',
      'education': [],
      'certifications': [],
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
    await _firestore.collection('doctors').doc(userId).set({
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
