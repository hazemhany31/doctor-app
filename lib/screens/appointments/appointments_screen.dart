
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/appointment_card.dart';
import '../../l10n/app_localizations.dart';
import 'appointment_detail_screen.dart';

/// شاشة إدارة المواعيد — Premium Redesign
class AppointmentsScreen extends StatefulWidget {
  final int initialIndex;
  const AppointmentsScreen({super.key, this.initialIndex = 0});

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
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final doctor = await _firestoreService.getDoctorByUserId(user.uid);
    if (doctor != null && mounted) {
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
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final tabs = [
      l10n.apptTabAll,
      l10n.apptTabPending,
      l10n.apptTabConfirmed,
      l10n.apptTabCompleted,
      l10n.apptTabCancelled,
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          // ─── Premium Hero Header ───
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.premiumHeaderGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + title row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.apptTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                l10n.apptSubtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Calendar icon decoration
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Pill Tab Bar ───
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tabs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            final isActive = _tabController.index == index;
                            return GestureDetector(
                              onTap: () => _tabController.animateTo(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isActive ? AppColors.tealGradient : null,
                                  color: isActive ? null : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.transparent
                                        : Colors.white.withValues(alpha: 0.15),
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  tabs[index],
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                                    fontSize: 13,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ─── Tab Body ───
          Expanded(
            child: _doctorId == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(null),
                      _buildList(AppConstants.appointmentPending),
                      _buildList('upcoming_pseudo'),
                      _buildList(AppConstants.appointmentCompleted),
                      _buildList(AppConstants.appointmentCancelled),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String? status) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Appointment>>(
      stream: _firestoreService.getDoctorAppointments(
        [_doctorId!, _authService.currentUser!.uid],
        status: status,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Error in Appointments list: ${snapshot.error}');
          return _buildEmpty(l10n); // Or a specific error widget
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmpty(l10n);
        }

        final appointments = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return AppointmentCard(
              appointment: appointments[index],
              showActions: appointments[index].status == AppConstants.appointmentPending,
              onAccept: () => _handleAccept(appointments[index]),
              onReject: () => _handleReject(appointments[index]),
              onTap: (appointments[index].status == AppConstants.appointmentPending ||
                      appointments[index].status == AppConstants.appointmentCancelled)
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailScreen(
                            appointment: appointments[index],
                          ),
                        ),
                      );
                    },
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 38,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.apptNoAppointments,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(Appointment appt) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _firestoreService.updateAppointmentStatus(
          appt.id, AppConstants.appointmentConfirmed);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailScreen(
              appointment: appt.copyWith(status: AppConstants.appointmentConfirmed),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.apptError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _handleReject(Appointment appt) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _firestoreService.updateAppointmentStatus(
          appt.id, AppConstants.appointmentCancelled,
          cancelReason: l10n.apptRejectReason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.apptRejectSuccess),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.apptError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}
