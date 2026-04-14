
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/colors.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../services/online_status_service.dart';
import '../services/emergency_service.dart';
import '../l10n/app_localizations.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard/dashboard_screen.dart';
import 'appointments/appointments_screen.dart';
import 'chat/chat_list_screen.dart';
import 'patients/patients_list_screen.dart';
import 'profile/profile_screen.dart';
import '../services/app_notification_service.dart';
import '../services/push_notification_service.dart';
import '../models/appointment.dart';

/// الشاشة الرئيسية مع Floating Pill Navigation
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  static MainLayoutState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainLayoutState>();
  }

  void setIndex(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  final EmergencyService _emergencyService = EmergencyService();
  StreamSubscription? _emergencySub;
  StreamSubscription<List<Appointment>>? _newApptSub;
  bool _isShowingEmergencyDialog = false;

  String? _doctorId;
  int _pendingAlertCount = 0; // tracks incoming emergency alerts

  // Tracks appointment IDs seen on first snapshot to avoid notifying old ones
  final Set<String> _seenAppointmentIds = {};
  bool _apptFirstLoad = true;

  // Tracks emergency alert IDs already notified to avoid duplicate notifications
  final Set<String> _seenEmergencyIds = {};
  bool _emergencyFirstLoad = true;

  final OnlineStatusService _onlineStatusService = OnlineStatusService();
  final _dashboardKey = GlobalKey<DashboardScreenState>();

  late final List<Widget> _screens;

  // Nav items definition (labels handled in build)
  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey),
      const AppointmentsScreen(),
      const ChatListScreen(),
      const PatientsListScreen(),
      const ProfileScreen(),
    ];
    _loadDoctorId();
  }

  bool _doctorNotFound = false;

  Future<void> _loadDoctorId({int retryCount = 0}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doctor = await _firestoreService.getDoctorByUserId(user.uid);
      if (doctor != null && mounted) {
        setState(() {
          _doctorId = doctor.id;
          _doctorNotFound = false;
        });
        _initializeOnlineStatus(doctor.id);
        _listenToEmergencies(doctor.id);
        AppNotificationService().startListening([user.uid, doctor.id]);
        _listenForNewAppointments([doctor.id, user.uid]);

        // طلب إذن الإشعارات بشكل احترافي مع شرح (Compliance)
        if (mounted) {
          PushNotificationService().requestPermission(context);
        }
      } else if (mounted) {
        // Retry up to 3 times with increasing delay (connectivity might be initializing)
        if (retryCount < 3) {
          final delay = Duration(seconds: (retryCount + 1) * 2);
          debugPrint('⏳ Doctor not found, retrying in ${delay.inSeconds}s (attempt ${retryCount + 1}/3)...');
          await Future.delayed(delay);
          if (mounted) _loadDoctorId(retryCount: retryCount + 1);
        } else {
          debugPrint('❌ Doctor document not found after 3 retries for userId: ${user.uid}');
          if (mounted) setState(() => _doctorNotFound = true);
        }
      }
    } catch (e) {
      if (mounted && retryCount < 3) {
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        if (mounted) _loadDoctorId(retryCount: retryCount + 1);
      }
    }
  }

  Future<void> _initializeOnlineStatus(String doctorId) async {
    try {
      await _onlineStatusService.initialize(doctorId);
      // Wait for the first frame so the dashboard widget is fully mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dashboardKey.currentState?.setOnlineStatusService(_onlineStatusService);
        }
      });
    } catch (e) {
      // ignore
    }
  }

  OnlineStatusService get onlineStatusService => _onlineStatusService;

  void _listenToEmergencies(String doctorId) {
    _emergencySub?.cancel();
    _seenEmergencyIds.clear();
    _emergencyFirstLoad = true;

    _emergencySub = _emergencyService.watchEmergencyAlerts(
      [doctorId, FirebaseAuth.instance.currentUser!.uid],
    ).listen(
      (alerts) {
        if (!mounted) return;
        setState(() => _pendingAlertCount = alerts.length);

        if (_emergencyFirstLoad) {
          // Seed existing alert IDs so we don't re-notify on app start
          for (final doc in alerts) {
            _seenEmergencyIds.add(doc.id);
          }
          _emergencyFirstLoad = false;
          debugPrint('Emergency watcher: seeded ${_seenEmergencyIds.length} existing alerts');
          // Still show bottom sheet for active alerts on app open
          if (alerts.isNotEmpty && !_isShowingEmergencyDialog) {
            _showEmergencyBottomSheet(alerts.first);
          }
          return;
        }

        // Fire notification for brand-new alerts
        for (final alertDoc in alerts) {
          if (!_seenEmergencyIds.contains(alertDoc.id)) {
            _seenEmergencyIds.add(alertDoc.id);
            final data = alertDoc.data() as Map<String, dynamic>;
            final patientName = (data['patientName'] as String?)?.trim().isNotEmpty == true
                ? data['patientName'] as String
                : 'مريض';
            final description = data['description'] as String?;
            final createdAt = (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now();

            PushNotificationService().showEmergencyNotification(
              alertId: alertDoc.id,
              patientName: patientName,
              description: description,
              time: createdAt,
            );
          }
        }

        // Also show in-app bottom sheet
        if (alerts.isNotEmpty && !_isShowingEmergencyDialog) {
          _showEmergencyBottomSheet(alerts.first);
        }
      },
      onError: (e) => debugPrint('⚠️ Emergency stream error: $e'),
    );
  }

  void _showEmergencyBottomSheet(DocumentSnapshot alertDoc) {
    if (!mounted) return;
    _isShowingEmergencyDialog = true;

    final l10n = AppLocalizations.of(context)!;
    final alertData = alertDoc.data() as Map<String, dynamic>;
    final patientName = alertData['patientName'] ?? 'مريض';
    final desc = (alertData['description'] as String?)?.isNotEmpty == true
        ? alertData['description'] as String
        : null;
    final alertId = alertDoc.id;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _EmergencyBottomSheet(
          patientName: patientName,
          description: desc,
          l10n: l10n,
          onAccept: () async {
            Navigator.pop(ctx);
            _isShowingEmergencyDialog = false;
            await _emergencyService.acknowledgeAlert(alertId);
          },
          onReject: () async {
            Navigator.pop(ctx);
            _isShowingEmergencyDialog = false;
            await _emergencyService.rejectAlert(alertId);
          },
        );
      },
    ).whenComplete(() {
      _isShowingEmergencyDialog = false;
    });
  }

  @override
  void dispose() {
    _emergencySub?.cancel();
    _newApptSub?.cancel();
    _onlineStatusService.dispose();
    super.dispose();
  }

  // New-appointment watcher: fires a local notification when a patient books
  void _listenForNewAppointments(List<String> doctorIds) {
    _newApptSub?.cancel();
    _seenAppointmentIds.clear();
    _apptFirstLoad = true;

    _newApptSub = _firestoreService
        .getDoctorAppointments(doctorIds)
        .listen((appointments) {
      if (_apptFirstLoad) {
        for (final a in appointments) {
          _seenAppointmentIds.add(a.id);
        }
        _apptFirstLoad = false;
        debugPrint('New-appt watcher: seeded ${_seenAppointmentIds.length} existing appointments');
        return;
      }

      for (final appt in appointments) {
        if (_seenAppointmentIds.contains(appt.id)) continue;
        _seenAppointmentIds.add(appt.id);

        // Only notify for freshly-booked (pending) appointments
        if (appt.status != 'pending' && appt.status != 'confirmed') continue;

        // Read language preference (async, fire-and-forget flow)
        SharedPreferences.getInstance().then((prefs) {
          final lang = prefs.getString('language_code') ?? 'ar';
          final isAr = lang == 'ar';

          final patientName = (appt.patientName?.trim().isNotEmpty == true)
              ? appt.patientName!
              : (isAr ? 'مريض' : 'Patient');

          final dateLabel = _formatAppointmentDate(appt.dateTime, lang);
          final timeLabel = _formatAppointmentTime(appt.dateTime, lang);

          final title = isAr ? 'حجز موعد جديد' : 'New Appointment Booked';
          final body = isAr
              ? '$patientName حجز موعداً $dateLabel الساعة $timeLabel'
              : '$patientName booked an appointment on $dateLabel at $timeLabel';

          debugPrint('New appointment notification [$lang]: $body (id=${appt.id})');

          PushNotificationService().show(
            title,
            body,
            payload: '{"appointmentId":"${appt.id}","type":"new_appointment"}',
          );
        });
      }
    }, onError: (e) => debugPrint('New-appt watcher error: $e'));
  }

  /// Day + date label (bilingual)
  String _formatAppointmentDate(DateTime dt, String lang) {
    final isAr = lang == 'ar';
    if (isAr) {
      const arabicDays = [
        'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
      ];
      const arabicMonths = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      final day = arabicDays[dt.weekday - 1];
      final month = arabicMonths[dt.month - 1];
      return 'يوم $day ${dt.day} $month';
    } else {
      const englishDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const englishMonths = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = englishDays[dt.weekday - 1];
      final month = englishMonths[dt.month - 1];
      return '$day, ${dt.day} $month';
    }
  }

  /// Time label (bilingual): "10:30 ص" / "10:30 AM"
  String _formatAppointmentTime(DateTime dt, String lang) {
    final isAr = lang == 'ar';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = isAr ? (dt.hour < 12 ? 'ص' : 'م') : (dt.hour < 12 ? 'AM' : 'PM');
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    if (_doctorNotFound) {
      return Scaffold(
        backgroundColor: AppColors.of(context).scaffoldBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text(
                  'تعذّر تحميل بيانات الدكتور',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'تأكد من اتصالك بالإنترنت وأن ملفك الشخصي موجود في Firestore',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _doctorNotFound = false);
                    _loadDoctorId();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    final l10n = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final navLabels = [
      l10n.navHome,
      l10n.navAppointments,
      l10n.navMessages,
      l10n.navPatients,
      l10n.navProfile,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: c.navBarBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: c.floatingShadow,
        border: Border.all(color: c.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final label = navLabels[index];
          final isActive = _currentIndex == index;

          // Chat badge special case
          Widget iconWidget = Icon(
            isActive ? item.activeIcon : item.icon,
            size: 22,
            color: isActive ? Colors.white : AppColors.textHint,
          );

          // Emergency badge on home tab (index 0)
          if (index == 0 && _pendingAlertCount > 0) {
            iconWidget = Badge(
              label: Text(
                '$_pendingAlertCount',
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 22,
                color: isActive ? Colors.white : AppColors.textHint,
              ),
            );
          }

          if (index == 1) {
            iconWidget = StreamBuilder<int>(
              stream: _doctorId != null &&
                      FirebaseAuth.instance.currentUser != null
                  ? _firestoreService.getPendingAppointmentsCount(
                      [_doctorId!, FirebaseAuth.instance.currentUser!.uid],
                    )
                  : Stream.value(0),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  label: count > 0
                      ? Text('$count', style: const TextStyle(fontSize: 10))
                      : null,
                  isLabelVisible: count > 0,
                  backgroundColor: AppColors.warning,
                  textColor: Colors.white,
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 22,
                    color: isActive ? Colors.white : AppColors.textHint,
                  ),
                );
              },
            );
          }

          if (index == 2) {
            final currentUser = FirebaseAuth.instance.currentUser;
            iconWidget = StreamBuilder<int>(
              stream: _doctorId != null && currentUser != null
                  ? _chatService.getTotalUnreadCount(
                      currentUser.uid,
                      _doctorId!,
                    )
                  : Stream.value(0),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  label: count > 0
                      ? Text('$count', style: const TextStyle(fontSize: 10))
                      : null,
                  isLabelVisible: count > 0,
                  backgroundColor: AppColors.accent,
                  textColor: Colors.white,
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 22,
                    color: isActive ? Colors.white : AppColors.textHint,
                  ),
                );
              },
            );
          }

          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.tealGradient : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.icon, required this.activeIcon});
}


// ─── Emergency Full-Screen Bottom Sheet ────────────────────────────────────

class _EmergencyBottomSheet extends StatefulWidget {
  final String patientName;
  final String? description;
  final AppLocalizations l10n;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const _EmergencyBottomSheet({
    required this.patientName,
    required this.description,
    required this.l10n,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_EmergencyBottomSheet> createState() => _EmergencyBottomSheetState();
}

class _EmergencyBottomSheetState extends State<_EmergencyBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Pulsing red emergency icon
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            l10n.emergencyDialogTitle,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB71C1C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Patient name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  l10n.emergencyDialogPatient(widget.patientName),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.description!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action buttons
          if (_loading)
            const CircularProgressIndicator(color: Color(0xFFE53935))
          else
            Row(
              children: [
                // Reject
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setState(() => _loading = true);
                      await widget.onReject();
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: Text(
                      l10n.emergencyDialogReject,
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Accept
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _loading = true);
                      await widget.onAccept();
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: Text(
                      l10n.emergencyDialogAccept,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
