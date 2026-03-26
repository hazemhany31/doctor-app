
/// ثوابت التطبيق
class AppConstants {
  // App Info
  static const String appName = 'تطبيق الدكتور';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String doctorsCollection = 'doctors';
  static const String patientsCollection = 'patients';
  static const String appointmentsCollection = 'appointments';
  static const String medicalRecordsCollection = 'medicalRecords';
  static const String messagesCollection = 'messages';

  // User Roles
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';

  // Appointment Status
  static const String appointmentPending = 'pending';
  static const String appointmentConfirmed = 'confirmed';
  static const String appointmentCompleted = 'completed';
  static const String appointmentCancelled = 'cancelled';

  // Appointment Types
  static const String appointmentTypeNew = 'new';
  static const String appointmentTypeFollowup = 'followup';

  // Days of Week
  static const List<String> daysOfWeek = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  // Time Durations (in minutes)
  static const int defaultAppointmentDuration = 20;
  static const List<int> appointmentDurations = [15, 20, 30, 45, 60];

  // Pagination
  static const int defaultPageSize = 20;

  // Storage Folders
  static const String doctorPhotosFolder = 'doctor_photos';
  static const String patientPhotosFolder = 'patient_photos';
  static const String medicalRecordsFolder = 'medical_records';
  static const String prescriptionsFolder = 'prescriptions';

  // Regex Patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^(010|011|012|015)[0-9]{8}$';

  // Error Messages
  static const String errorGeneric = 'حدث خطأ ما، يرجى المحاولة مرة أخرى';
  static const String errorNetwork = 'تحقق من اتصالك بالإنترنت';
  static const String errorInvalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String errorInvalidPassword =
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  static const String errorEmailNotFound = 'البريد الإلكتروني غير مسجل';
  static const String errorWrongPassword = 'كلمة المرور غير صحيحة';
  static const String errorEmailInUse = 'البريد الإلكتروني مستخدم بالفعل';
  static const String errorNotDoctor = 'هذا الحساب ليس حساب دكتور';

  // Success Messages
  static const String successLogin = 'تم تسجيل الدخول بنجاح';
  static const String successLogout = 'تم تسجيل الخروج بنجاح';
  static const String successUpdated = 'تم التحديث بنجاح';
  static const String successAdded = 'تم الإضافة بنجاح';
  static const String successDeleted = 'تم الحذف بنجاح';
}
