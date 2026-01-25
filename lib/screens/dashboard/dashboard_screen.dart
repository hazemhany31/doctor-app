import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/doctor.dart';
import '../../models/appointment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/appointment_card.dart';

/// لوحة التحكم الرئيسية
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Doctor? _doctor;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // الحصول على معلومات الدكتور
      final doctor = await _firestoreService.getDoctorByUserId(user.uid);
      if (doctor == null) return;

      // الحصول على الإحصائيات
      final stats = await _firestoreService.getDashboardStats(doctor.id);

      setState(() {
        _doctor = doctor;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_doctor == null) {
      return Scaffold(body: Center(child: Text('حدث خطأ في تحميل البيانات')));
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // صورة الدكتور
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: _doctor!.photoUrl != null
                                ? NetworkImage(_doctor!.photoUrl!)
                                : null,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            child: _doctor!.photoUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          SizedBox(width: 16),
                          // معلومات الدكتور
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'د. ${_doctor!.name}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _doctor!.specialization,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // أيقونة الإشعارات
                          IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // TODO: Navigate to notifications
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // المحتوى
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  // الإحصائيات
                  _buildStatsSection(),
                  SizedBox(height: 24),
                  // مواعيد اليوم
                  _buildTodayAppointmentsSection(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'نظرة عامة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          padding: EdgeInsets.symmetric(horizontal: 8),
          children: [
            StatCard(
              title: 'مرضى اليوم',
              value: '${_stats['todayPatients'] ?? 0}',
              icon: Icons.people,
              color: AppColors.primaryBlue,
            ),
            StatCard(
              title: 'مواعيد معلقة',
              value: '${_stats['pendingAppointments'] ?? 0}',
              icon: Icons.pending_actions,
              color: AppColors.warning,
            ),
            StatCard(
              title: 'مواعيد قادمة',
              value: '${_stats['upcomingAppointments'] ?? 0}',
              icon: Icons.event,
              color: AppColors.success,
            ),
            StatCard(
              title: 'إجمالي المرضى',
              value: '${_stats['totalPatients'] ?? 0}',
              icon: Icons.group,
              color: AppColors.secondaryTeal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مواعيد اليوم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all appointments
                },
                child: Text('عرض الكل'),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        StreamBuilder<List<Appointment>>(
          stream: _firestoreService.getTodayAppointments(_doctor!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد مواعيد اليوم',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final appointments = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: appointments.length > 5 ? 5 : appointments.length,
              itemBuilder: (context, index) {
                return AppointmentCard(
                  appointment: appointments[index],
                  showActions: appointments[index].status == 'pending',
                  onAccept: () => _handleAcceptAppointment(appointments[index]),
                  onReject: () => _handleRejectAppointment(appointments[index]),
                  onTap: () {
                    // TODO: Navigate to appointment details
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleAcceptAppointment(Appointment appointment) async {
    try {
      await _firestoreService.updateAppointmentStatus(
        appointment.id,
        'confirmed',
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
        'cancelled',
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
