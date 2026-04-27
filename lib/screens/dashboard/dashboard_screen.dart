import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/doctor.dart';
import '../../models/appointment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/appointment_card.dart';
import '../../services/online_status_service.dart';
import '../setup/setup_doctor_profile_screen.dart';
import '../schedule/schedule_management_screen.dart';
import '../appointments/appointments_screen.dart';
import '../appointments/appointment_detail_screen.dart';
import '../../config/constants.dart';
import '../patients/patients_list_screen.dart';
import '../../models/dashboard_data.dart';
import '../../l10n/app_localizations.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// لوحة التحكم الرئيسية
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Doctor? _doctor;
  List<String> _doctorIds = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Online status
  OnlineStatusService? _onlineStatusService;
  bool _isOnline = false;

  // Real-time notifications
  StreamSubscription? _notificationSubscription;

  /// IDs of appointments deleted locally — filtered out instantly from the stream
  /// to prevent them reappearing before Firestore confirms the deletion.
  final Set<String> _deletedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not signed in';
        });
        return;
      }

      final doctor = await _firestoreService.getDoctorByUserId(user.uid);
      if (doctor == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Doctor information not found';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _doctorIds = [doctor.id, user.uid];
        _isLoading = false;
        _errorMessage = null;
      });

      // استخدام user.uid لأن nbig_app يرسل الـ notification على doctorUserId = Firebase Auth UID
      _setupNotificationListener(user.uid);
    } catch (e) {
      debugPrint('❌ Error in _loadData: $e');
      if (_doctor != null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      String errorMsg = l10n.dashErrorTitle;
      if (e.toString().contains('unavailable') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMsg = l10n.dashNoConnectionSub;
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  void _setupNotificationListener(String doctorId) {
    _notificationSubscription?.cancel();
    _notificationSubscription = _firestoreService
        .getNotificationsStream(doctorId)
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              _showInAppNotification(
                change.doc.id,
                data['title'] ?? 'New Appointment',
                data['body'] ?? 'A patient has booked a new appointment',
              );
            }
          }
        }
      },
      onError: (e) => debugPrint('⚠️ Notifications stream error: $e'),
    );
  }

  void _showInAppNotification(String id, String title, String body) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            _firestoreService.markNotificationAsRead(id);
            _loadData();
          },
        ),
      ),
    );
  }

  void setOnlineStatusService(OnlineStatusService service) {
    _onlineStatusService = service;
    if (mounted) {
      setState(() {
        _isOnline = service.isOnline;
      });
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_onlineStatusService == null) return;
    final newStatus = !_isOnline;
    setState(() => _isOnline = newStatus);
    await _onlineStatusService!.setOnlineStatus(newStatus);
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.dashGreetingM;
    if (hour < 17) return l10n.dashGreetingE;
    return l10n.dashGreetingN;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.of(context).scaffoldBg,
        body: Column(
          children: [
            _buildLoadingHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(child: ShimmerStatCard()),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerStatCard()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: ShimmerStatCard()),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerStatCard()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const ShimmerListItem(),
                    const ShimmerListItem(),
                    const ShimmerListItem(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    if (_errorMessage != null) {
      final isMissingDoctorData = _errorMessage!.contains(
        l10n.dashErrorNoDoctor.split('\n').first,
      );
      return Scaffold(
        backgroundColor: AppColors.of(context).scaffoldBg,
        body: Column(
          children: [
            _buildLoadingHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: (isMissingDoctorData
                                  ? AppColors.primary
                                  : AppColors.error)
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMissingDoctorData
                              ? Icons.person_add_outlined
                              : Icons.cloud_off_outlined,
                          size: 40,
                          color: isMissingDoctorData
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isMissingDoctorData
                            ? l10n.dashErrorNoDoctor
                            : _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SetupDoctorProfileScreen(),
                            ),
                          );
                          if (result == true && mounted) _loadData();
                        },
                        icon: Icon(
                          isMissingDoctorData ? Icons.person_add : Icons.refresh,
                          size: 18,
                        ),
                        label: Text(
                          isMissingDoctorData
                              ? l10n.dashErrorSetupProfile
                              : l10n.dashRetryBtn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_doctor == null) {
      return Scaffold(
        backgroundColor: AppColors.of(context).scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader(context)),
            SliverToBoxAdapter(
              child: StreamBuilder<DashboardData>(
                stream: _firestoreService.getDashboardUnifiedStream(_doctorIds),
                initialData: DashboardData.empty(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('⚠️ Dashboard Stream Error: ${snapshot.error}');
                  }
                  final data = snapshot.data ?? DashboardData.empty();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(data),
                      const SizedBox(height: 24),
                      _buildTodayAppointmentsSection(data.todayAppointments),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(gradient: AppColors.headerGradient),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting(context)} 👋',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textOnDark.withValues(alpha: 0.7),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.dashDrName(_doctor!.name),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _doctor!.specialization,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.accentLight,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                    Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage: (_doctor!.photoUrl != null && _doctor!.photoUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(_doctor!.photoUrl!)
                            : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: (_doctor!.photoUrl == null || _doctor!.photoUrl!.isEmpty)
                            ? Icon(
                                Icons.person_rounded,
                                size: 34,
                                color: Colors.white.withValues(alpha: 0.8),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? AppColors.success
                                : AppColors.textHint,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.headerDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _onlineStatusService != null
                          ? _toggleOnlineStatus
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? AppColors.success.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isOnline
                                ? AppColors.success.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? AppColors.success
                                    : AppColors.textHint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isOnline ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isOnline
                                    ? AppColors.success
                                    : Colors.white.withValues(alpha: 0.6),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScheduleManagementScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Manage Schedule',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Overview'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s Patients',
                  '${data.todayPatients}',
                  Icons.people_rounded,
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.1),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen(initialIndex: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Daily Income',
                  '\$${data.dailyIncome.toStringAsFixed(0)}',
                  Icons.monetization_on_rounded,
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.1),
                  null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '${data.pendingAppointments}',
                  Icons.hourglass_top_rounded,
                  AppColors.warning,
                  AppColors.warning.withValues(alpha: 0.1),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen(initialIndex: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Upcoming',
                  '${data.upcomingAppointments}',
                  Icons.event_rounded,
                  AppColors.info,
                  AppColors.info.withValues(alpha: 0.1),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen(initialIndex: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Patients',
                  '${data.totalPatients}',
                  Icons.group_rounded,
                  const Color(0xFF8B5CF6),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientsListScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: const SizedBox()), // Empty slot for balance
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, Color bg, VoidCallback? onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: c.cardShadow,
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: c.textSecondary,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildTodayAppointmentsSection(List<Appointment> appointments) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            l10n.dashTodayAndNewAppointments,
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppointmentsScreen(initialIndex: 0),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.dashViewAll,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (appointments.isEmpty)
            _buildEmptyState(
              icon: Icons.event_available_rounded,
              title: l10n.dashNoAppointmentsTitle,
              subtitle: l10n.dashNoAppointmentsSub,
            )
          else
            Column(
              children: appointments
                  .where((a) => !_deletedIds.contains(a.id))
                  .take(5)
                  .map((appt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: AppointmentCard(
                    appointment: appt,
                    showActions: appt.status == AppConstants.appointmentPending ||
                                appt.status == AppConstants.appointmentConfirmed,
                    onAccept: () => _handleAcceptAppointment(appt),
                    onReject: () => _handleRejectAppointment(appt),
                    onDelete: () => _handleDelete(appt),
                    onTap: (appt.status == AppConstants.appointmentPending ||
                            appt.status == AppConstants.appointmentCancelled)
                        ? null
                        : () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailScreen(
                                  appointment: appt,
                                ),
                              ),
                            );
                          },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  Future<void> _handleAcceptAppointment(Appointment appointment) async {
    try {
      await _firestoreService.updateAppointmentStatus(
        appointment.id,
        'confirmed',
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => AppointmentDetailScreen(
              appointment: appointment.copyWith(status: 'confirmed'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectAppointment(Appointment appointment) async {
    try {
      await _firestoreService.updateAppointmentStatus(
        appointment.id,
        'cancelled',
        cancelReason: 'Rejected by doctor',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Immediately hides the card by adding to local set, then deletes from Firestore.
  /// If Firestore fails, removes from local set so the card reappears.
  Future<void> _handleDelete(Appointment appt) async {
    final l10n = AppLocalizations.of(context)!;
    if (mounted) setState(() => _deletedIds.add(appt.id));
    
    try {
      await _firestoreService.deleteAppointment(appt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'ar'
              ? 'تم حذف الموعد'
              : 'Appointment deleted'),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {
      // Revert: let the card reappear if deletion failed
      if (mounted) setState(() => _deletedIds.remove(appt.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.apptError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}
