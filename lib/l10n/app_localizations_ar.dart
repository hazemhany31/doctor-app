// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get preferencesSection => 'التفضيلات';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageSubtitle => 'العربية';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEnabled => 'مفعّلة';

  @override
  String get notificationsDisabled => 'معطّلة';

  @override
  String get supportSection => 'الدعم والمساعدة';

  @override
  String get supportPhoneTitle => 'خط الدعم الفني';

  @override
  String get supportCustomerTitle => 'خط خدمة العملاء';

  @override
  String get supportWhatsappTitle => 'تواصل معنا عبر واتساب';

  @override
  String get supportWhatsappSubtitle => 'للاستفسارات والشكاوى';

  @override
  String get aboutSection => 'عن التطبيق';

  @override
  String get appVersionTitle => 'إصدار التطبيق';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get privacyPolicySubtitle => 'اقرأ سياستنا';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navAppointments => 'المواعيد';

  @override
  String get navMessages => 'الرسائل';

  @override
  String get navPatients => 'المرضى';

  @override
  String get navProfile => 'ملفي';

  @override
  String get emergencyDialogTitle => 'طلب طوارئ!';

  @override
  String emergencyDialogPatient(String name) {
    return 'المريض: $name';
  }

  @override
  String emergencyDialogDetails(String desc) {
    return 'التفاصيل: $desc';
  }

  @override
  String get emergencyDialogReject => 'رفض';

  @override
  String get emergencyDialogAccept => 'قبول';

  @override
  String get dashGreetingM => 'صباح الخير';

  @override
  String get dashGreetingE => 'مساء الخير';

  @override
  String get dashGreetingN => 'مساء النور';

  @override
  String dashGreetingMsg(String greeting) {
    return '$greeting 👋';
  }

  @override
  String dashDrName(String name) {
    return 'د. $name';
  }

  @override
  String get dashOnline => 'متاح الآن';

  @override
  String get dashOffline => 'غير متاح';

  @override
  String get dashScheduleBtn => 'إدارة المواعيد';

  @override
  String get dashStatsPatients => 'مرضى اليوم';

  @override
  String get dashStatsPending => 'معلقة';

  @override
  String get dashStatsUpcoming => 'قادمة';

  @override
  String get dashStatsTotal => 'إجمالي';

  @override
  String get dashOverview => 'نظرة عامة';

  @override
  String get dashTodayAppointments => 'مواعيد اليوم';

  @override
  String get dashTodayAndNewAppointments => 'المواعيد الجديدة واليوم';

  @override
  String get dashViewAll => 'عرض الكل';

  @override
  String get dashNoConnectionTitle => 'لا يوجد اتصال';

  @override
  String get dashNoConnectionSub => 'تحقق من الإنترنت وحاول مجدداً';

  @override
  String get dashRetryBtn => 'إعادة المحاولة';

  @override
  String get dashNoAppointmentsTitle => 'لا توجد مواعيد حالياً';

  @override
  String get dashNoAppointmentsSub =>
      'لا توجد مواعيد اليوم أو طلبات جديدة بانتظارك';

  @override
  String get dashErrorTitle => 'حدث خطأ في تحميل البيانات';

  @override
  String get dashErrorNoDoctor =>
      'لم يتم العثور على معلومات الدكتور\nيرجى التواصل مع المسؤول لإضافة بياناتك';

  @override
  String get dashErrorSetupProfile => 'إعداد الملف الشخصي';

  @override
  String get dashAcceptSuccess => 'تم قبول الموعد';

  @override
  String get dashRejectSuccess => 'تم رفض الموعد';

  @override
  String get dashRejectReason => 'تم الرفض من قبل الدكتور';

  @override
  String get dashErrorGeneral => 'حدث خطأ';

  @override
  String get apptTitle => 'المواعيد';

  @override
  String get apptSubtitle => 'إدارة جميع مواعيدك';

  @override
  String get apptTabAll => 'الكل';

  @override
  String get apptTabPending => 'المعلقة';

  @override
  String get apptTabConfirmed => 'المؤكدة';

  @override
  String get apptTabCompleted => 'المكتملة';

  @override
  String get apptTabCancelled => 'الملغاة';

  @override
  String get apptNoAppointments => 'لا توجد مواعيد';

  @override
  String get apptAcceptSuccess => 'تم قبول الموعد';

  @override
  String get apptRejectSuccess => 'تم رفض الموعد';

  @override
  String get apptRejectReason => 'تم الرفض من قبل الدكتور';

  @override
  String get apptError => 'حدث خطأ';

  @override
  String get ptsTitle => 'المرضى';

  @override
  String get ptsSearchHint => 'ابحث عن مريض...';

  @override
  String get ptsNoPatients => 'لا يوجد مرضى';

  @override
  String get ptsNoResults => 'لا توجد نتائج';

  @override
  String get profTitle => 'الملف الشخصي';

  @override
  String get profLogout => 'تسجيل الخروج';

  @override
  String get profLogoutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get profCancel => 'إلغاء';

  @override
  String get profErrorLabel => 'حدث خطأ في تحميل البيانات';

  @override
  String get profClinicInfo => 'معلومات العيادة';

  @override
  String get profClinicName => 'اسم العيادة';

  @override
  String get profClinicUnspecified => 'غير محدد';

  @override
  String get profAddress => 'العنوان';

  @override
  String get profPhone => 'هاتف العيادة';

  @override
  String get profFees => 'سعر الكشف';

  @override
  String get profFeesCurrency => 'جنيه';

  @override
  String get profWorkingHours => 'ساعات العمل';

  @override
  String get profPersonalInfo => 'معلومات شخصية';

  @override
  String get profEmail => 'البريد الإلكتروني';

  @override
  String get profPersonalPhone => 'رقم الهاتف الشخصي';

  @override
  String get profExperience => 'سنوات الخبرة';

  @override
  String profExperienceYears(String years) {
    return '$years سنة';
  }

  @override
  String get profBio => 'نبذة عن الدكتور';

  @override
  String get profEditProfile => 'تعديل الملف الشخصي';

  @override
  String get profDiagnostic => 'معلومات التشخيص';

  @override
  String get profDiagnosticSub => 'لتحديد مشاكل البيانات';

  @override
  String get profHelpSupport => 'المساعدة والدعم';

  @override
  String get chatTitle => 'الرسائل';

  @override
  String get chatSubtitle => 'راسل مرضاك مباشرة';

  @override
  String get chatErrorTitle => 'خطأ في تحميل البيانات';

  @override
  String get chatErrorNoDoctor => 'لم يتم العثور على معلومات الدكتور';

  @override
  String get chatErrorPrefix => 'حدث خطأ: ';

  @override
  String get chatNoChatsTitle => 'لا توجد محادثات بعد';

  @override
  String get chatNoChatsSub => 'عندما يتواصل المرضى معك،\nستظهر المحادثات هنا';

  @override
  String get chatDateYesterday => 'أمس';

  @override
  String get chatNoMessages => 'لا توجد رسائل';

  @override
  String get apptCardStatusPending => 'معلق';

  @override
  String get apptCardStatusConfirmed => 'مؤكد';

  @override
  String get apptCardStatusCompleted => 'مكتمل';

  @override
  String get apptCardStatusCancelled => 'ملغي';

  @override
  String get apptCardTypeNew => 'كشف جديد';

  @override
  String get apptCardTypeFollowup => 'متابعة';

  @override
  String get apptCardPatientFallback => 'مريض';

  @override
  String get apptCardStatusLabel => 'الحالة: ';

  @override
  String get apptCardBtnReject => 'رفض';

  @override
  String get apptCardBtnAccept => 'قبول';

  @override
  String get chatDetailSendError => 'فشل إرسال الرسالة: ';

  @override
  String get chatDetailStartPlaceholder => 'ابدأ المحادثة مع المريض';

  @override
  String get chatDetailInputHint => 'اكتب رسالة...';

  @override
  String get chatDetailToday => 'اليوم';

  @override
  String get chatDetailYesterday => 'أمس';

  @override
  String ptDetailAgeYears(String age) {
    return '$age سنة';
  }

  @override
  String get ptDetailGenderMale => 'ذكر';

  @override
  String get ptDetailGenderFemale => 'أنثى';

  @override
  String get ptDetailTabInfo => 'معلومات';

  @override
  String get ptDetailTabAppointments => 'مواعيد';

  @override
  String get ptDetailTabRecords => 'سجلات طبية';

  @override
  String get ptInfoContactTitle => 'معلومات الاتصال';

  @override
  String get ptInfoPhone => 'رقم الهاتف';

  @override
  String get ptInfoEmail => 'البريد الإلكتروني';

  @override
  String get ptInfoAddress => 'العنوان';

  @override
  String get ptInfoMedicalHistory => 'السجل الطبي';

  @override
  String get ptInfoChronic => 'الأمراض المزمنة';

  @override
  String get ptInfoAllergies => 'الحساسية';

  @override
  String get ptInfoSurgeries => 'العمليات السابقة';

  @override
  String get ptInfoMedications => 'الأدوية الحالية';

  @override
  String get ptApptErrorLoad => 'حدث خطأ في تحميل المواعيد';

  @override
  String get ptApptUpcomingTitle => 'المواعيد القادمة';

  @override
  String get ptApptPastTitle => 'المواعيد السابقة';

  @override
  String get ptApptDoctorPrefix => 'د. ';

  @override
  String get ptApptBtnConfirm => 'تأكيد';

  @override
  String get ptApptBtnCancel => 'إلغاء';

  @override
  String get ptApptUpdateStatusSuccess => 'تم تحديث حالة الموعد';

  @override
  String get ptApptUpdateStatusError => 'حدث خطأ في تحديث الحالة';

  @override
  String get ptApptCancelTitle => 'إلغاء الموعد';

  @override
  String get ptApptCancelReasonHint => 'سبب الإلغاء (اختياري)';

  @override
  String get ptApptCancelBtnBack => 'تراجع';

  @override
  String get ptApptCancelBtnConfirm => 'إلغاء الموعد';

  @override
  String get ptApptCancelSuccess => 'تم إلغاء الموعد';

  @override
  String get ptApptEmpty => 'لا توجد مواعيد';

  @override
  String get ptRecordsErrorLoad => 'حدث خطأ في تحميل السجلات الطبية';

  @override
  String get ptRecordsEmpty => 'لا توجد سجلات طبية';

  @override
  String get ptRecordsSymptoms => 'الأعراض';

  @override
  String get ptRecordsPrescriptions => 'الوصفات الطبية';

  @override
  String get ptRecordsNotes => 'ملاحظات';

  @override
  String get ptRecordsAttachments => 'المرفقات';

  @override
  String get ptRecordsAttachmentItem => 'مرفق';

  @override
  String get ptRecordsDosage => 'الجرعة';

  @override
  String get ptRecordsFrequency => 'عدد المرات';

  @override
  String get ptRecordsDuration => 'المدة';

  @override
  String get ptRecordsInstructions => 'تعليمات';

  @override
  String get ptRecordsOpenAttachmentMsg => 'فتح المرفق: ';

  @override
  String get apptDetailTitle => 'تفاصيل الموعد';

  @override
  String get apptDetailPatientReport => 'تقرير المريض';

  @override
  String get apptDetailNoReport => 'المريض لم يكتب تقريراً';

  @override
  String get apptDetailPrescriptions => 'الوصفة الطبية';

  @override
  String get apptDetailAddMedicine => 'إضافة دواء';

  @override
  String get apptDetailMedicineName => 'اسم الدواء';

  @override
  String get apptDetailDosage => 'الجرعة (مثال: 500mg)';

  @override
  String get apptDetailFrequency => 'عدد المرات (مثال: 3 مرات يومياً)';

  @override
  String get apptDetailDuration => 'المدة (مثال: 7 أيام)';

  @override
  String get apptDetailReminderTitle => 'تنبيه الدواء';

  @override
  String get apptDetailReminderSubtitle => 'اضبط وقت تذكير المريض بالدواء';

  @override
  String apptDetailReminderSet(String datetime) {
    return 'التنبيه: $datetime';
  }

  @override
  String get apptDetailReminderBtn => 'ضبط التنبيه';

  @override
  String get apptDetailSaveBtn => 'حفظ وإتمام';

  @override
  String get apptDetailSaveSuccess => 'تم حفظ الوصفة بنجاح';

  @override
  String get apptDetailSaveError => 'فشل في حفظ الوصفة';

  @override
  String get apptDetailPatientName => 'المريض';

  @override
  String get apptDetailDate => 'التاريخ';

  @override
  String get apptDetailType => 'النوع';

  @override
  String get apptDetailStatus => 'الحالة';

  @override
  String get apptDetailNotes => 'ملاحظات الدكتور';

  @override
  String get apptDetailNotesHint => 'أضف ملاحظاتك (اختياري)';

  @override
  String get settingsDarkTitle => 'الوضع الداكن';

  @override
  String get settingsLightTitle => 'الوضع الفاتح';

  @override
  String get settingsDarkSub => 'اضغط للتبديل للوضع الفاتح';

  @override
  String get settingsLightSub => 'اضغط للتبديل للوضع الداكن';

  @override
  String get settingsAccountSection => 'إدارة الحساب';

  @override
  String get settingsDeleteAccountTitle => 'حذف الحساب نهائياً';

  @override
  String get settingsDeleteAccountSub => 'سيتم مسح جميع بياناتك وسجلاتك للأبد';

  @override
  String get deleteDialogTitle => 'تأكيد حذف الحساب';

  @override
  String get deleteDialogMessage =>
      'هل أنت متأكد أنك تريد حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه، وسيتم مسح جميع بيانات مرضاك وسجلاتك من النظام بالكامل تماشياً مع سياسات الخصوصية.';

  @override
  String get deleteDialogConfirm => 'الموافقة والحذف';

  @override
  String get reauthDialogTitle => 'تأكيد الهوية';

  @override
  String get reauthDialogMessage =>
      'لحذف الحساب، يرجى إدخال كلمة المرور الحالية لتأكيد هويتك.';

  @override
  String get passwordLabel => 'كلمة المرور';
}
