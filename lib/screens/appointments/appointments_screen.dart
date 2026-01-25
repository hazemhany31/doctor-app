import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/appointment_card.dart';

/// شاشة إدارة المواعيد
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  late TabController _tabController;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final doctor = await _firestoreService.getDoctorByUserId(user.uid);
    if (doctor != null) {
      setState(() => _doctorId = doctor.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المواعيد'),
        backgroundColor: AppColors.primaryBlue,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'الكل'),
            Tab(text: 'المعلقة'),
            Tab(text: 'المؤكدة'),
            Tab(text: 'المكتملة'),
            Tab(text: 'الملغاة'),
          ],
        ),
      ),
      body: _doctorId == null
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(null),
                _buildAppointmentsList(AppConstants.appointmentPending),
                _buildAppointmentsList(AppConstants.appointmentConfirmed),
                _buildAppointmentsList(AppConstants.appointmentCompleted),
                _buildAppointmentsList(AppConstants.appointmentCancelled),
              ],
            ),
    );
  }

  Widget _buildAppointmentsList(String? status) {
    return StreamBuilder<List<Appointment>>(
      stream: _firestoreService.getDoctorAppointments(
        _doctorId!,
        status: status,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text(
                  'لا توجد مواعيد',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return AppointmentCard(
              appointment: appointments[index],
              showActions:
                  appointments[index].status == AppConstants.appointmentPending,
              onAccept: () => _handleAcceptAppointment(appointments[index]),
              onReject: () => _handleRejectAppointment(appointments[index]),
              onTap: () {
                // TODO: Navigate to appointment details
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleAcceptAppointment(Appointment appointment) async {
    try {
      await _firestoreService.updateAppointmentStatus(
        appointment.id,
        AppConstants.appointmentConfirmed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم قبول الموعد'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleRejectAppointment(Appointment appointment) async {
    try {
      await _firestoreService.updateAppointmentStatus(
        appointment.id,
        AppConstants.appointmentCancelled,
        cancelReason: 'تم الرفض من قبل الدكتور',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض الموعد'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
