import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';

/// خدمة Firestore للتعامل مع البيانات
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Doctor ====================

  /// الحصول على معلومات الدكتور
  Future<Doctor?> getDoctor(String doctorId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();

      if (!doc.exists) return null;
      return Doctor.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على معلومات الدكتور بواسطة userId
  Future<Doctor?> getDoctorByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Doctor.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
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

  /// الحصول على مواعيد الدكتور
  Stream<List<Appointment>> getDoctorAppointments(
    String doctorId, {
    String? status,
  }) {
    Query query = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('dateTime', descending: false);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().asyncMap((snapshot) async {
      final appointments = <Appointment>[];

      for (var doc in snapshot.docs) {
        var appointment = Appointment.fromFirestore(doc);

        // الحصول على معلومات المريض
        final patient = await getPatient(appointment.patientId);
        if (patient != null) {
          appointment = appointment.copyWith(
            patientName: patient.name,
            patientPhotoUrl: patient.photoUrl,
          );
        }

        appointments.add(appointment);
      }

      return appointments;
    });
  }

  /// الحصول على مواعيد اليوم
  Stream<List<Appointment>> getTodayAppointments(String doctorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime')
        .snapshots()
        .asyncMap((snapshot) async {
          final appointments = <Appointment>[];

          for (var doc in snapshot.docs) {
            var appointment = Appointment.fromFirestore(doc);

            // الحصول على معلومات المريض
            final patient = await getPatient(appointment.patientId);
            if (patient != null) {
              appointment = appointment.copyWith(
                patientName: patient.name,
                patientPhotoUrl: patient.photoUrl,
              );
            }

            appointments.add(appointment);
          }

          return appointments;
        });
  }

  /// تحديث حالة الموعد
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status, {
    String? cancelReason,
  }) async {
    final data = {'status': status, 'updatedAt': FieldValue.serverTimestamp()};

    if (cancelReason != null) {
      data['cancelReason'] = cancelReason;
    }

    await _firestore
        .collection(AppConstants.appointmentsCollection)
        .doc(appointmentId)
        .update(data);
  }

  /// الحصول على مواعيد المريض
  Stream<List<Appointment>> getPatientAppointments(String patientId) {
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final appointments = <Appointment>[];

          for (var doc in snapshot.docs) {
            var appointment = Appointment.fromFirestore(doc);

            // الحصول على معلومات الدكتور
            final doctor = await getDoctor(appointment.doctorId);
            if (doctor != null) {
              appointment = appointment.copyWith(doctorName: doctor.name);
            }

            appointments.add(appointment);
          }

          return appointments;
        });
  }

  // ==================== Patients ====================

  /// الحصول على معلومات المريض
  Future<Patient?> getPatient(String patientId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.patientsCollection)
          .doc(patientId)
          .get();

      if (!doc.exists) return null;
      return Patient.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على قائمة مرضى الدكتور
  Stream<List<Patient>> getDoctorPatients(String doctorId) {
    // الحصول على المرضى من خلال المواعيد
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .asyncMap((snapshot) async {
          final patientIds = <String>{};

          // تجميع IDs المرضى الفريدة
          for (var doc in snapshot.docs) {
            final appointment = Appointment.fromFirestore(doc);
            patientIds.add(appointment.patientId);
          }

          // الحصول على معلومات المرضى
          final patients = <Patient>[];
          for (var patientId in patientIds) {
            final patient = await getPatient(patientId);
            if (patient != null) {
              patients.add(patient);
            }
          }

          return patients;
        });
  }

  // ==================== Medical Records ====================

  /// الحصول على السجلات الطبية للمريض
  Stream<List<MedicalRecord>> getPatientMedicalRecords(String patientId) {
    return _firestore
        .collection(AppConstants.medicalRecordsCollection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final records = <MedicalRecord>[];

          for (var doc in snapshot.docs) {
            var record = MedicalRecord.fromFirestore(doc);

            // الحصول على معلومات الدكتور
            final doctor = await getDoctor(record.doctorId);
            if (doctor != null) {
              record = record.copyWith(doctorName: doctor.name);
            }

            records.add(record);
          }

          return records;
        });
  }

  /// إضافة سجل طبي جديد
  Future<String> addMedicalRecord(MedicalRecord record) async {
    final docRef = await _firestore
        .collection(AppConstants.medicalRecordsCollection)
        .add(record.toMap());
    return docRef.id;
  }

  // ==================== Statistics ====================

  /// الحصول على إحصائيات Dashboard
  Future<Map<String, int>> getDashboardStats(String doctorId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // عدد المرضى اليوم
      final todayAppointmentsSnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final todayPatientsCount = todayAppointmentsSnapshot.docs.length;

      // المواعيد المعلقة
      final pendingAppointmentsSnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: AppConstants.appointmentPending)
          .get();

      final pendingCount = pendingAppointmentsSnapshot.docs.length;

      // المواعيد القادمة
      final upcomingAppointmentsSnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('dateTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .where(
            'status',
            whereIn: [
              AppConstants.appointmentConfirmed,
              AppConstants.appointmentPending,
            ],
          )
          .get();

      final upcomingCount = upcomingAppointmentsSnapshot.docs.length;

      // إجمالي المرضى (من المواعيد)
      final allAppointmentsSnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final patientIds = <String>{};
      for (var doc in allAppointmentsSnapshot.docs) {
        final appointment = Appointment.fromFirestore(doc);
        patientIds.add(appointment.patientId);
      }

      return {
        'todayPatients': todayPatientsCount,
        'pendingAppointments': pendingCount,
        'upcomingAppointments': upcomingCount,
        'totalPatients': patientIds.length,
      };
    } catch (e) {
      return {
        'todayPatients': 0,
        'pendingAppointments': 0,
        'upcomingAppointments': 0,
        'totalPatients': 0,
      };
    }
  }
}
