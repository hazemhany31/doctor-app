import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';
import '../models/dashboard_data.dart';
import '../models/prescription_template.dart';

/// خدمة Firestore للتعامل مع البيانات
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // -- Caches for performance --
  final Map<String, Patient> _patientCache = {};
  final Map<String, Doctor> _doctorCache = {};

  // ==================== Doctor ====================

  /// الحصول على معلومات الدكتور
  Future<Doctor?> getDoctor(String doctorId) async {
    if (_doctorCache.containsKey(doctorId)) return _doctorCache[doctorId];
    try {
      final doc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) return null;
      final doctor = Doctor.fromFirestore(doc);
      _doctorCache[doctorId] = doctor;
      return doctor;
    } catch (e) {
      debugPrint('⚠️ Error fetching doctor ($doctorId): $e');
      return null;
    }
  }

  /// الحصول على معلومات الدكتور بواسطة userId
  Future<Doctor?> getDoctorByUserId(String userId) async {
    try {
      debugPrint('📡 Fetching doctor data (Resilient)...');

      // 1. Try Cache first
      try {
        final cacheSnapshot = await _firestore
            .collection(AppConstants.doctorsCollection)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get(const GetOptions(source: Source.cache));

        if (cacheSnapshot.docs.isNotEmpty) {
          debugPrint('✅ Found in CACHE (offline)');
          return Doctor.fromFirestore(cacheSnapshot.docs.first);
        }
      } catch (e) {
        debugPrint('ℹ️ Cache empty or error: $e');
      }

      // 2. Try Default (Server with local fallback if server unreachable)
      final snapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 7), onTimeout: () {
            debugPrint('⚠️ Server fetch timed out, returning null or falling back');
            throw Exception('Doctor profile fetch timeout');
          });

      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ Found on SERVER/Default');
        return Doctor.fromFirestore(snapshot.docs.first);
      }

      debugPrint('❌ No doctor found with userId: $userId');
      return null;
    } catch (e) {
      debugPrint('❌ Error in getDoctorByUserId: $e');
      
      // Final attempt: one more look at cache just in case
      try {
        final lastChance = await _firestore
            .collection(AppConstants.doctorsCollection)
            .where('userId', isEqualTo: userId)
            .get(const GetOptions(source: Source.cache));
        if (lastChance.docs.isNotEmpty) {
          return Doctor.fromFirestore(lastChance.docs.first);
        }
      } catch (_) {}
      
      return null;
    }
  }

  /// إنشاء ملف شخصي جديد للدكتور
  Future<String> createDoctorProfile({
    required String userId,
    required String name,
    required String specialization,
    required String email,
    String? phoneNumber,
    int? yearsOfExperience,
    String? about,
    String? photoUrl,
    Map<String, dynamic>? clinicInfo,
    String? facebook,
    String? instagram,
    String? linkedin,
    String? twitter,
  }) async {
    try {
      debugPrint('📝 إنشاء ملف شخصي جديد للدكتور...');
      debugPrint('   userId: $userId');
      debugPrint('   name: $name');
      debugPrint('   specialization: $specialization');

      final data = {
        'userId': userId,
        'name': name,
        'specialization': specialization,
        'email': email,
        'phone': phoneNumber ?? '',
        'yearsOfExperience': yearsOfExperience ?? 0,
        'bio': about ?? '',
        'photoUrl': photoUrl,
        'isAvailable': true,
        'rating': 0.0,
        'reviewsCount': 0,
        'certificates': [],
        'createdAt': FieldValue.serverTimestamp(),
        'facebook': facebook,
        'instagram': instagram,
        'linkedin': linkedin,
        'twitter': twitter,
      };

      // إضافة معلومات العيادة إذا كانت موجودة
      if (clinicInfo != null) {
        data['clinicInfo'] = clinicInfo;
      } else {
        // قيم افتراضية لمعلومات العيادة
        data['clinicInfo'] = {
          'name': '',
          'address': '',
          'fees': 0.0,
          'photos': [],
        };
      }

      final docRef = await _firestore
          .collection(AppConstants.doctorsCollection)
          .add(data);

      debugPrint('✅ تم إنشاء الملف الشخصي بنجاح - Doctor ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الملف الشخصي: $e');
      rethrow;
    }
  }

  /// تحديث الملف الشخصي للدكتور (تحديث جزئي)
  Future<void> updateDoctorProfile({
    required String doctorId,
    String? name,
    String? specialization,
    String? phone,
    String? photoUrl,
    int? yearsOfExperience,
    String? bio,
    Map<String, dynamic>? clinicInfo,
    String? facebook,
    String? instagram,
    String? linkedin,
    String? twitter,
  }) async {
    try {
      debugPrint('📝 تحديث الملف الشخصي للدكتور...');

      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (specialization != null) data['specialization'] = specialization;
      if (phone != null) data['phone'] = phone;
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (yearsOfExperience != null) {
        data['yearsOfExperience'] = yearsOfExperience;
      }
      if (bio != null) data['bio'] = bio;
      if (clinicInfo != null) data['clinicInfo'] = clinicInfo;
      if (facebook != null) data['facebook'] = facebook;
      if (instagram != null) data['instagram'] = instagram;
      if (linkedin != null) data['linkedin'] = linkedin;
      if (twitter != null) data['twitter'] = twitter;

      if (data.isNotEmpty) {
        await _firestore
            .collection(AppConstants.doctorsCollection)
            .doc(doctorId)
            .update(data);

        debugPrint('✅ تم تحديث الملف الشخصي بنجاح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الملف الشخصي: $e');
      rethrow;
    }
  }

  /// تحديث معلومات الدكتور
  Future<void> updateDoctor(String doctorId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.doctorsCollection)
        .doc(doctorId)
        .update(data);
  }

  // ==================== Appointments ====================

  /// الحصول على مواعيد الدكتور مع دعم الفلاتر المتقدمة
  /// يستعلم على doctorId وdoctorUserId معاً لضمان إيجاد كل المواعيد
  Stream<List<Appointment>> getDoctorAppointments(
    List<String> doctorIds, {
    String? status,
    bool? upcomingOnly,
  }) {
    debugPrint('🔍 getDoctorAppointments: doctorIds=$doctorIds, status=$status, upcomingOnly=$upcomingOnly');

    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value([]);

    // Run TWO parallel streams: one by 'doctorId', one by 'doctorUserId'
    final byDoctorId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', whereIn: uniqueIds)
        .snapshots();

    final byDoctorUserId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorUserId', whereIn: uniqueIds)
        .snapshots();

    return _mergeDualStream(byDoctorId, byDoctorUserId).asyncMap((allDocs) =>
        _processDoctorAppointments(allDocs, status: status, upcomingOnly: upcomingOnly));
  }

  /// Merges two Firestore snapshot streams, deduplicating docs by ID.
  /// Uses a single-subscription controller to ensure initial snapshots are not lost.
  Stream<List<DocumentSnapshot>> _mergeDualStream(
    Stream<QuerySnapshot> s1,
    Stream<QuerySnapshot> s2,
  ) {
    StreamSubscription<QuerySnapshot>? sub1;
    StreamSubscription<QuerySnapshot>? sub2;
    final Map<String, DocumentSnapshot> cache1 = {};
    final Map<String, DocumentSnapshot> cache2 = {};

    late final StreamController<List<DocumentSnapshot>> controller;

    void emit() {
      if (controller.isClosed) return;
      final merged = <String, DocumentSnapshot>{};
      merged.addAll(cache1);
      merged.addAll(cache2);
      controller.add(merged.values.toList());
    }

    controller = StreamController<List<DocumentSnapshot>>.broadcast(
      onListen: () {
        sub1 = s1.listen((snap) {
          cache1.clear();
          for (var doc in snap.docs) { cache1[doc.id] = doc; }
          emit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        sub2 = s2.listen((snap) {
          cache2.clear();
          for (var doc in snap.docs) { cache2[doc.id] = doc; }
          emit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  /// Internal helper to process and filter appointment docs
  Future<List<Appointment>> _processDoctorAppointments(
    List<DocumentSnapshot> docs, {
    String? status,
    bool? upcomingOnly,
  }) async {
      final now = DateTime.now();
      
      // 1. Initial parsing with safety — skip soft-deleted docs
      List<Appointment> appointments = [];
      for (var doc in docs) {
        try {
          // Skip docs marked as soft-deleted by doctor
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            if (data['deletedByDoctor'] == true) continue;
            if (data['status'] == 'deleted') continue;
          }
          appointments.add(Appointment.fromFirestore(doc));
        } catch (e) {
          debugPrint('❌ Skipping corrupt appointment document (${doc.id}): $e');
        }
      }

      // 2. Filter by status (if provided)
      if (status != null) {
        if (status == 'upcoming_pseudo') {
          appointments = appointments.where((a) =>
            a.dateTime.isAfter(now) &&
            a.status == AppConstants.appointmentConfirmed
          ).toList();
        } else {
          appointments = appointments.where((a) => a.status == status).toList();
        }
      } else {
        // If status is NULL (All tab), exclude cancelled appointments as requested
        appointments = appointments.where((a) => a.status != AppConstants.appointmentCancelled).toList();
      }

      // 3. Filter by "Upcoming Only" flag if set
      if (upcomingOnly == true) {
        appointments = appointments.where((a) => a.dateTime.isAfter(now)).toList();
      }

      // 4. Enrich with patient details (Parallel & Cached)
      await Future.wait(appointments.map((appointment) async {
        final patient = await getPatient(appointment.patientId);
        
        if (patient != null) {
          bool isGeneric(String? name) {
            if (name == null || name.trim().isEmpty) return true;
            final low = name.trim().toLowerCase();
            return low == 'patient' || low == 'مريض';
          }

          String? resolvedName;
          if (!isGeneric(appointment.patientName)) {
            resolvedName = appointment.patientName;
          } else if (!isGeneric(patient.name)) {
            resolvedName = patient.name;
          }

          final idx = appointments.indexOf(appointment);
          if (idx != -1) {
            appointments[idx] = appointment.copyWith(
              patientName: resolvedName,
              patientPhotoUrl: (appointment.patientPhotoUrl != null && 
                                appointment.patientPhotoUrl!.isNotEmpty)
                  ? appointment.patientPhotoUrl
                  : patient.photoUrl,
            );
          }
        }
      }));

      // 5. Final sort (Ascending by date)
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      debugPrint('✅ Returned ${appointments.length} appointments after filtering');
      return appointments;
  }

  /// الحصول على مواعيد اليوم
  Stream<List<Appointment>> getTodayAppointments(List<String> doctorIds) {
    // Ensure unique IDs
    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value([]);

    final byDoctorId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', whereIn: uniqueIds)
        .snapshots();

    final byDoctorUserId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorUserId', whereIn: uniqueIds)
        .snapshots();

    return _mergeDualStream(byDoctorId, byDoctorUserId).asyncMap((allDocs) async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final appointments = <Appointment>[];
      for (var doc in allDocs) {
        try {
          final appt = Appointment.fromFirestore(doc);
          if (appt.dateTime.isAfter(startOfDay) &&
              appt.dateTime.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
              appt.status != AppConstants.appointmentCancelled) {
            appointments.add(appt);
          }
        } catch (e) {
          debugPrint('❌ Skipping corrupt today appointment (${doc.id}): $e');
        }
      }

      // Parallel fetch patient details
      await Future.wait(appointments.map((appointment) async {
        final patient = await getPatient(appointment.patientId);

        // Name resolution logic (same as above)
        bool isNameGeneric(String? n) {
          if (n == null || n.trim().isEmpty) return true;
          final low = n.trim().toLowerCase();
          return low == 'patient' || low == 'مريض';
        }

        if (patient != null) {
          String? resolvedName;
          if (!isNameGeneric(appointment.patientName)) {
            resolvedName = appointment.patientName;
          } else if (!isNameGeneric(patient.name)) {
            resolvedName = patient.name;
          }

          final index = appointments.indexOf(appointment);
          appointments[index] = appointment.copyWith(
            patientName: resolvedName,
            patientPhotoUrl: (appointment.patientPhotoUrl != null &&
                    appointment.patientPhotoUrl!.isNotEmpty)
                ? appointment.patientPhotoUrl
                : patient.photoUrl,
          );
        }
      }));

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    });
  }

  /// حذف الموعد نهائياً — مع fallback لـ soft-delete لو الـ rules لا تسمح
  Future<void> deleteAppointment(String appointmentId) async {
    final docRef = _firestore
        .collection(AppConstants.appointmentsCollection)
        .doc(appointmentId);
    try {
      // Try hard delete first (requires updated Firestore rules)
      await docRef.delete();
      debugPrint('✅ Appointment hard-deleted: $appointmentId');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Fallback: soft-delete — mark as deleted so the doctor doesn't see it
        debugPrint('⚠️ No delete permission — falling back to soft-delete');
        try {
          await docRef.update({
            'deletedByDoctor': true,
            'status': 'deleted',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Appointment soft-deleted: $appointmentId');
        } catch (updateError) {
          debugPrint('❌ Soft-delete also failed: $updateError');
          rethrow;
        }
      } else {
        debugPrint('❌ Error deleting appointment: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error deleting appointment: $e');
      rethrow;
    }
  }

  /// تحديث حالة الموعد مع تنبيه المريض
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status, {
    String? cancelReason,
  }) async {
    try {
      final docRef = _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId);
      
      final docSnap = await docRef.get();
      if (!docSnap.exists) return;
      
      final apptData = docSnap.data()!;
      final patientId = apptData['patientId']?.toString() ?? '';
      final doctorName = apptData['doctorName']?.toString() ?? 'الطبيب';

      // استخرج تاريخ ووقت الموعد لعرضه في الإشعار
      DateTime? apptDateTime;
      final dtValue = apptData['dateTime'];
      if (dtValue is Timestamp) {
        apptDateTime = dtValue.toDate();
      }

      // جلب لغة المريض من Firestore (ar أو en)
      final bool isArabicPatient = await _getPatientLanguage(patientId);

      final String apptDateStr = apptDateTime != null
          ? _formatApptDate(apptDateTime, arabic: isArabicPatient)
          : '';

      final updateData = {'status': status, 'updatedAt': FieldValue.serverTimestamp()};

      if (cancelReason != null) {
        updateData['cancelReason'] = cancelReason;
      }

      await docRef.update(updateData);

      // إرسال تنبيه للمريض بلغته
      if (patientId.isNotEmpty) {
        String title = '';
        String body = '';
        String type = '';

        if (status == AppConstants.appointmentCancelled) {
          if (isArabicPatient) {
            title = 'تم إلغاء الموعد';
            body = 'نعتذر، تم إلغاء موعدك مع د. $doctorName';
            if (apptDateStr.isNotEmpty) body += ' ($apptDateStr)';
            if (cancelReason != null) body += ' — السبب: $cancelReason';
          } else {
            title = 'Appointment Cancelled';
            body = 'Sorry, your appointment with Dr. $doctorName has been cancelled';
            if (apptDateStr.isNotEmpty) body += ' ($apptDateStr)';
            if (cancelReason != null) body += ' — Reason: $cancelReason';
          }
          type = 'appointment_cancelled';
        } else if (status == AppConstants.appointmentAccepted) {
          if (isArabicPatient) {
            title = '✅ تم قبول موعدك!';
            body = 'د. $doctorName وافق على موعدك';
            if (apptDateStr.isNotEmpty) body += '\n📅 $apptDateStr';
          } else {
            title = '✅ Appointment Accepted!';
            body = 'Dr. $doctorName has accepted your appointment';
            if (apptDateStr.isNotEmpty) body += '\n📅 $apptDateStr';
          }
          type = 'appointment_accepted';
        } else if (status == AppConstants.appointmentConfirmed) {
          if (isArabicPatient) {
            title = 'تأكيد الموعد';
            body = 'تم تأكيد موعدك مع د. $doctorName';
            if (apptDateStr.isNotEmpty) body += '\n📅 $apptDateStr';
          } else {
            title = 'Appointment Confirmed';
            body = 'Your appointment with Dr. $doctorName has been confirmed';
            if (apptDateStr.isNotEmpty) body += '\n📅 $apptDateStr';
          }
          type = 'appointment_confirmed';
        }

        if (type.isNotEmpty) {
          await _triggerPatientNotification(
            patientId: patientId,
            title: title,
            body: body,
            type: type,
            appointmentId: appointmentId,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating appointment status: $e');
      rethrow;
    }
  }

  /// جلب لغة المريض من Firestore — إذا لم تُحدَّد يُفترض العربية
  Future<bool> _getPatientLanguage(String patientId) async {
    if (patientId.isEmpty) return true;
    try {
      final doc = await _firestore.collection('users').doc(patientId).get();
      if (doc.exists) {
        final lang = doc.data()?['language']?.toString() ?? 'ar';
        return lang == 'ar';
      }
    } catch (_) {}
    return true; // default: Arabic
  }

  /// تنسيق تاريخ ووقت الموعد للعرض في الإشعار
  String _formatApptDate(DateTime dt, {bool arabic = true}) {
    if (arabic) {
      const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
                      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'ص' : 'م';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$dayName ${dt.day} $monthName — $displayHour:$minute $period';
    } else {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$dayName ${dt.day} $monthName — $displayHour:$minute $period';
    }
  }

  /// إلغاء جميع المواعيد القادمة في يوم محدد من الأسبوع
  Future<void> cancelAppointmentsOnDay({
    required String doctorId,
    required String doctorUserId,
    required int targetWeekday,
    required String reason,
  }) async {
    try {
      final now = DateTime.now();
      
      // 1. جلب المواعيد القادمة (pending/confirmed)
      // نبحث بـ doctorId و doctorUserId لضمان الشمولية
      final List<QuerySnapshot> snapshots = await Future.wait([
        _firestore
            .collection(AppConstants.appointmentsCollection)
            .where('doctorId', isEqualTo: doctorId)
            .where('status', whereIn: [AppConstants.appointmentPending, AppConstants.appointmentConfirmed])
            .get(),
        _firestore
            .collection(AppConstants.appointmentsCollection)
            .where('doctorUserId', isEqualTo: doctorUserId)
            .where('status', whereIn: [AppConstants.appointmentPending, AppConstants.appointmentConfirmed])
            .get(),
      ]);

      // دمج وإزالة التكرار
      final Map<String, Appointment> toCancel = {};
      for (var snap in snapshots) {
        for (var doc in snap.docs) {
          try {
            final appt = Appointment.fromFirestore(doc);
            // فلترة المواعيد التي تقع في نفس اليوم من الأسبوع وتكون في المستقبل
            if (appt.dateTime.isAfter(now) && appt.dateTime.weekday == targetWeekday) {
              toCancel[appt.id] = appt;
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing appointment during bulk cancel: $e');
          }
        }
      }

      debugPrint('📅 Found ${toCancel.length} appointments to cancel for weekday $targetWeekday');

      // 2. تحديث الحالات وإرسال التنبيهات
      for (var appt in toCancel.values) {
        await updateAppointmentStatus(
          appt.id, 
          AppConstants.appointmentCancelled, 
          cancelReason: reason
        );
      }
    } catch (e) {
      debugPrint('❌ Error in cancelAppointmentsOnDay: $e');
      rethrow;
    }
  }

  /// إرسال إشعار للمريض عبر Firestore
  Future<void> _triggerPatientNotification({
    required String patientId,
    required String title,
    required String body,
    required String type,
    required String appointmentId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': patientId,
        'title': title,
        'body': body,
        'type': type,
        'appointmentId': appointmentId,
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🔔 Notification triggered for patient: $patientId');
    } catch (e) {
      debugPrint('⚠️ Failed to trigger notification for patient: $e');
    }
  }

  /// حفظ الوصفة الطبية وتنبيه الدواء من الدكتور
  Future<void> updateAppointmentDetails(
    String appointmentId, {
    List<Map<String, dynamic>>? prescriptions,
    DateTime? medicationReminderTime,
    String? doctorNotes,
    String? status,
    String? doctorId, // مطلوب لحساب الـ income عند الإكمال
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (prescriptions != null) {
      data['prescriptions'] = prescriptions;
    }
    if (medicationReminderTime != null) {
      data['medicationReminderTime'] =
          Timestamp.fromDate(medicationReminderTime);
    }
    if (doctorNotes != null) {
      data['doctorNotes'] = doctorNotes;
    }
    if (status != null) {
      data['status'] = status;
    }

    // ✅ لما الموعد يتمّ: نكتب الـ fees في الـ appointment مباشرةً
    if (status == AppConstants.appointmentCompleted && doctorId != null) {
      try {
        // جرب بالـ doc ID أول، لو فشل جرب بالـ userId
        Doctor? doc = await getDoctor(doctorId);
        if (doc == null || doc.clinicInfo.fees == 0.0) {
          doc = await getDoctorByUserId(doctorId);
        }
        final double completedFees = doc?.clinicInfo.fees ?? 0.0;
        data['completedFees'] = completedFees;
        data['completedAt'] = FieldValue.serverTimestamp();
        debugPrint('💰 Writing completedFees=$completedFees to appointment $appointmentId');
      } catch (e) {
        debugPrint('⚠️ Could not resolve doctor fees for income: $e');
      }
    }

    final docRef = _firestore.collection(AppConstants.appointmentsCollection).doc(appointmentId);
    await docRef.update(data);

    // Trigger notification for the patient
    try {
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final apptData = docSnap.data()!;
        final patientId = apptData['patientId']?.toString() ?? '';
        final doctorName = apptData['doctorName']?.toString() ?? 'الطبيب';

        if (patientId.isNotEmpty) {
          final bool isArabicPatient = await _getPatientLanguage(patientId);
          String title = '';
          String body = '';
          String type = 'prescription_updated';

          if (isArabicPatient) {
            title = 'تحديث في خطة العلاج';
            body = 'قام د. $doctorName بتحديث تفاصيل موعدك';
            if (prescriptions != null && prescriptions.isNotEmpty) {
              body = 'قام د. $doctorName بإضافة وصفة طبية جديدة لموعدك';
            }
          } else {
            title = 'Treatment Plan Update';
            body = 'Dr. $doctorName has updated your appointment details';
            if (prescriptions != null && prescriptions.isNotEmpty) {
              body = 'Dr. $doctorName has added a new prescription to your appointment';
            }
          }
          
          if (status == AppConstants.appointmentCompleted) {
            if (isArabicPatient) {
              title = 'اكتمل الموعد';
              body = 'تم الانتهاء من موعدك مع د. $doctorName. الوصفة الطبية متاحة الآن.';
            } else {
              title = 'Appointment Completed';
              body = 'Your appointment with Dr. $doctorName has been completed. The prescription is now available.';
            }
            type = 'appointment_completed';
          }

          await _triggerPatientNotification(
            patientId: patientId,
            title: title,
            body: body,
            type: type,
            appointmentId: appointmentId,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to trigger prescription notification: $e');
    }
  }

  /// الحصول على مواعيد المريض
  Stream<List<Appointment>> getPatientAppointments(String patientId) {
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .asyncMap((snapshot) async {
          final appointments = <Appointment>[];

          for (var doc in snapshot.docs) {
            var appointment = Appointment.fromFirestore(doc);

            // الحصول على معلومات الدكتور
            final doctor = await getDoctor(appointment.doctorId);
            if (doctor != null) {
              appointment = appointment.copyWith(
                doctorName: doctor.name,
                patientName: appointment.patientName,
              );
            }

            appointments.add(appointment);
          }

          // Sort in Dart to avoid needing a composite Firestore index
          appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          return appointments;
        });
  }

  // ==================== Patients ====================

  /// الحصول على معلومات المريض
  Future<Patient?> getPatient(String patientId) async {
    // Guard: empty ID causes Firestore "path must be non-empty" crash
    if (patientId.trim().isEmpty) return null;

    if (_patientCache.containsKey(patientId)) return _patientCache[patientId];

    bool hasName(DocumentSnapshot d) {
      if (!d.exists) return false;
      final data = d.data() as Map<String, dynamic>?;
      if (data == null) return false;
      final n = (data['name'] ?? data['displayName'] ?? data['fullName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return n.isNotEmpty && n != 'patient' && n != 'مريض';
    }

    try {
      DocumentSnapshot? doc;

      // 1. Try patients collection (may not exist or may be permission-denied)
      try {
        final patientsDoc = await _firestore
            .collection(AppConstants.patientsCollection)
            .doc(patientId)
            .get();
        if (hasName(patientsDoc)) doc = patientsDoc;
      } catch (_) {
        // Silently fall through to users collection
      }

      // 2. Fallback: users collection
      if (doc == null || !hasName(doc)) {
        try {
          final userDoc = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(patientId)
              .get();
          if (userDoc.exists) doc = userDoc;
        } catch (e) {
          debugPrint('❌ Error in getPatient ($patientId): $e');
        }
      }

      if (doc == null || !doc.exists) return null;

      final patient = Patient.fromFirestore(doc);
      _patientCache[patientId] = patient;
      return patient;
    } catch (e) {
      debugPrint('❌ Error in getPatient ($patientId): $e');
      return null;
    }
  }

  /// الحصول على قائمة مرضى الدكتور
  Stream<List<Patient>> getDoctorPatients(List<String> doctorIds) {
    // Ensure unique IDs
    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value([]);

    // الحصول على المرضى من خلال المواعيد
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', whereIn: uniqueIds)
        .snapshots()
        .asyncMap((snapshot) async {
          final Map<String, Patient> patientMap = {};

          // تجميع المرضى من المواعيد
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final patientId = data['patientId'] as String? ?? '';
              if (patientId.isEmpty) continue;

              // إذا لم نقم بمعالجة هذا المريض بعد
              if (!patientMap.containsKey(patientId)) {
                // محاولة الحصول على الملف الشخصي الكامل
                final patient = await getPatient(patientId);
                
                if (patient != null && patient.name.isNotEmpty) {
                  patientMap[patientId] = patient;
                } else {
                  // Fallback: إنشاء ملف مريض "مصطنع" من بيانات الموعد
                  // لضمان ظهوره في القائمة حتى لو لم يكتمل ملفه الشخصي
                  patientMap[patientId] = Patient(
                    id: patientId,
                    userId: patientId,
                    name: data['patientName'] ?? (patient?.name ?? 'Patient'),
                    email: patient?.email ?? '',
                    phone: data['patientPhone'] ?? (patient?.phone ?? ''),
                    photoUrl: data['patientPhotoUrl'] ?? patient?.photoUrl,
                    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  );
                }
              }
            } catch (e) {
              debugPrint('❌ Error parsing appointment for patient list: $e');
            }
          }

          final patientList = patientMap.values.toList();
          debugPrint('👥 getDoctorPatients: found ${patientList.length} unique patients');
          return patientList;
        });
  }

  // ==================== Medical Records ====================

  /// الحصول على السجلات الطبية للمريض المرفوعة من nbig_app
  Stream<List<MedicalRecord>> getPatientMedicalRecords(String patientId) {
    return _firestore
        .collection('users')
        .doc(patientId)
        .collection('medical_records')
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map((doc) => MedicalRecord.fromFirestore(doc))
          .toList();
      // Sort in Dart to avoid needing a Firestore index on string date field
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    });
  }

  /// إضافة سجل طبي جديد (نفس مسار المريض)
  Future<String> addMedicalRecord(String patientId, MedicalRecord record) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(patientId)
          .collection('medical_records')
          .add(record.toMap())
          .timeout(const Duration(seconds: 15));
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding medical record: $e');
      rethrow;
    }
  }

  // ==================== Schedule ====================

  /// تحديث جدول مواعيد الدكتور
  Future<void> updateDoctorSchedule(
    String doctorId,
    Map<String, DaySchedule> schedule,
  ) async {
    try {
      final scheduleMap = schedule.map(
        (key, value) => MapEntry(key, value.toMap()),
      );

      debugPrint('📅 Saving schedule for doctorId: $doctorId');

      // محاولة التحديث بواسطة document ID مباشرة أولاً
      final docRef = _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId);

      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 10));

      if (docSnapshot.exists) {
        await docRef.update({'schedule': scheduleMap}).timeout(const Duration(seconds: 10));
        debugPrint('✅ Schedule updated via document ID');
      } else {
        // البحث بواسطة userId
        final doctorDocs = await _firestore
            .collection(AppConstants.doctorsCollection)
            .where('userId', isEqualTo: doctorId)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));

        if (doctorDocs.docs.isNotEmpty) {
          await doctorDocs.docs.first.reference.update({
            'schedule': scheduleMap,
          });
          debugPrint('✅ Schedule updated via userId query');
        } else {
          throw Exception('Doctor document not found for ID: $doctorId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating schedule: $e');
      rethrow;
    }
  }

  // ==================== Statistics ====================

  /// الحصول على إحصائيات Dashboard
  Future<Map<String, int>> getDashboardStats(List<String> doctorIds) async {
    try {
      debugPrint('📊 getDashboardStats called with doctorIds: $doctorIds');
      
      final uniqueIds = doctorIds.toSet().toList();
      if (uniqueIds.isEmpty) {
        return {
          'todayPatients': 0,
          'pendingAppointments': 0,
          'upcomingAppointments': 0,
          'totalPatients': 0,
        };
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Query by BOTH doctorId and doctorUserId to catch all appointments
      final byDoctorId = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', whereIn: uniqueIds)
          .get();
      final byDoctorUserId = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorUserId', whereIn: uniqueIds)
          .get();

      // Deduplicate by document ID
      final Map<String, dynamic> seen = {};
      for (var doc in [...byDoctorId.docs, ...byDoctorUserId.docs]) {
        seen[doc.id] = doc;
      }
      final allDocs = seen.values.toList();

      // Fake a QuerySnapshot-like iterable from allDocs
      final allAppointmentsSnapshot = allDocs;

      int todayPatientsCount = 0;
      int pendingCount = 0;
      int upcomingCount = 0;
      final patientIds = <String>{};

      for (var doc in allAppointmentsSnapshot) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final patientId = data['patientId'] ?? '';
        if (patientId.isNotEmpty) patientIds.add(patientId);

        DateTime? apptDate;
        if (data['dateTime'] != null) {
          apptDate = (data['dateTime'] as Timestamp).toDate();
        }

        if (apptDate != null &&
            apptDate.isAfter(startOfDay) &&
            apptDate.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
            status != AppConstants.appointmentCancelled) {
          todayPatientsCount++;
        }
        if (status == AppConstants.appointmentPending) {
          pendingCount++;
        }
        if (apptDate != null &&
            apptDate.isAfter(now) &&
            status == AppConstants.appointmentConfirmed) {
          upcomingCount++;
        }
      }

      return {
        'todayPatients': todayPatientsCount,
        'pendingAppointments': pendingCount,
        'upcomingAppointments': upcomingCount,
        'totalPatients': patientIds.length,
      };
    } catch (e) {
      debugPrint('❌ Error in getDashboardStats: $e');
      return {
        'todayPatients': 0,
        'pendingAppointments': 0,
        'upcomingAppointments': 0,
        'totalPatients': 0,
      };
    }
  }

  /// Real-time stream of pending appointment count for the nav badge
  /// Queries by both doctorId and doctorUserId to catch all appointments
  Stream<int> getPendingAppointmentsCount(List<String> doctorIds) {
    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value(0);

    final byDoctorId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', whereIn: uniqueIds)
        .where('status', isEqualTo: AppConstants.appointmentPending)
        .snapshots();

    final byDoctorUserId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorUserId', whereIn: uniqueIds)
        .where('status', isEqualTo: AppConstants.appointmentPending)
        .snapshots();

    return _mergeDualStream(byDoctorId, byDoctorUserId).map((allDocs) {
      return allDocs.map((d) => d.id).toSet().length;
    });
  }

  /// الحصول على إحصائيات Dashboard والمواعيد في Stream واحد لتحسين الأداء
  Stream<DashboardData> getDashboardUnifiedStream(List<String> doctorIds) {
    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value(DashboardData.empty());

    final byDoctorId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', whereIn: uniqueIds)
        .snapshots();

    final byDoctorUserId = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorUserId', whereIn: uniqueIds)
        .snapshots();

    return _mergeDualStream(byDoctorId, byDoctorUserId).asyncMap((allDocs) async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      int todayPatientsCount = 0;
      int pendingCount = 0;
      int upcomingCount = 0;
      double dailyIncomeCount = 0.0;
      final patientIds = <String>{};
      final todayAppts = <Appointment>[];

      for (var doc in allDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          
          final status = data['status'] ?? '';
          final patientId = data['patientId'] ?? '';
          if (patientId.isNotEmpty) patientIds.add(patientId);

          DateTime? apptDate;
          if (data['dateTime'] != null) {
            apptDate = (data['dateTime'] as Timestamp).toDate();
          }

          if (apptDate != null) {
            // Stats logic: Only count true "today" patients (non-cancelled)
            final bool isToday = apptDate.isAfter(startOfDay) &&
                                apptDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
            
            if (isToday) {
              if (status != AppConstants.appointmentCancelled) {
                todayPatientsCount++;
              }
              // ✅ نقرا الـ fees من الـ appointment مباشرةً (اتسجّلت وقت الإكمال)
              if (status == AppConstants.appointmentCompleted) {
                final double apptFees = (data['completedFees'] ?? 0.0).toDouble();
                dailyIncomeCount += apptFees;
                debugPrint('💰 Added fees=$apptFees from appointment ${doc.id} | total=$dailyIncomeCount');
              }
            }

            // Dashboard list logic: Include if today OR pending, ALWAYS exclude if cancelled
            if (status != AppConstants.appointmentCancelled && 
                (isToday || status == AppConstants.appointmentPending)) {
              todayAppts.add(Appointment.fromFirestore(doc));
            }

            if (status == AppConstants.appointmentPending) {
              pendingCount++;
            }
            if (apptDate.isAfter(now) &&
                status == AppConstants.appointmentConfirmed) {
              upcomingCount++;
            }
          }
        } catch (e) {
          debugPrint('❌ Error parsing doc ${doc.id} in dashboard stream: $e');
        }
      }

      // Deduplicate by ID
      final Map<String, Appointment> uniqueMap = {};
      for (var a in todayAppts) {
        uniqueMap[a.id] = a;
      }
      final List<Appointment> uniqueAppts = uniqueMap.values.toList();

      // Parallel fetch patient details for the display list
      await Future.wait(uniqueAppts.map((appointment) async {
        final patient = await getPatient(appointment.patientId);
        if (patient != null) {
          final index = uniqueAppts.indexOf(appointment);
          uniqueAppts[index] = appointment.copyWith(
            patientName: (appointment.patientName == null || appointment.patientName!.toLowerCase() == 'patient') 
                ? patient.name 
                : appointment.patientName,
            patientPhotoUrl: (appointment.patientPhotoUrl != null && appointment.patientPhotoUrl!.isNotEmpty)
                ? appointment.patientPhotoUrl
                : patient.photoUrl,
          );
        }
      }));

      // Sort: Pending first, then by date (soonest/newest first)
      uniqueAppts.sort((a, b) {
        if (a.status == AppConstants.appointmentPending && b.status != AppConstants.appointmentPending) return -1;
        if (a.status != AppConstants.appointmentPending && b.status == AppConstants.appointmentPending) return 1;
        return a.dateTime.compareTo(b.dateTime);
      });

      // Limit to 5 for the dashboard
      final displayAppts = uniqueAppts.take(5).toList();

      return DashboardData(
        todayPatients: todayPatientsCount,
        pendingAppointments: pendingCount,
        upcomingAppointments: upcomingCount,
        totalPatients: patientIds.length,
        dailyIncome: dailyIncomeCount,
        todayAppointments: displayAppts,
      );
    });
  }

  // ==================== Notifications ====================

  /// Stream للتبيهات الخاصة بالدكتور
  Stream<QuerySnapshot> getNotificationsStream(String recipientId) {
    // لا نستخدم orderBy لتجنب الحاجة لـ composite index
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .where('status', isEqualTo: 'unread')
        .snapshots();
  }

  /// تحديث حالة التنبيه إلى مقروء
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'status': 'read'});
  }

  // ==================== Prescription Templates ====================

  /// الحصول على قائمة قوالب الوصفات الطبية الخاصة بالطبيب
  Stream<List<PrescriptionTemplate>> getPrescriptionTemplates(String doctorId) {
    return _firestore
        .collection(AppConstants.doctorsCollection)
        .doc(doctorId)
        .collection('templates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrescriptionTemplate.fromFirestore(doc))
            .toList());
  }

  /// إضافة قالب جديد
  Future<void> addPrescriptionTemplate(String doctorId, PrescriptionTemplate template) async {
    final data = template.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(AppConstants.doctorsCollection)
        .doc(doctorId)
        .collection('templates')
        .add(data);
  }

  /// تحديث قالب موجود
  Future<void> updatePrescriptionTemplate(String doctorId, PrescriptionTemplate template) async {
    final data = template.toMap();
    data.remove('createdAt');
    await _firestore
        .collection(AppConstants.doctorsCollection)
        .doc(doctorId)
        .collection('templates')
        .doc(template.id)
        .update(data);
  }

  /// حذف قالب
  Future<void> deletePrescriptionTemplate(String doctorId, String templateId) async {
    await _firestore
        .collection(AppConstants.doctorsCollection)
        .doc(doctorId)
        .collection('templates')
        .doc(templateId)
        .delete();
  }
}
