
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/colors.dart';
import '../../models/doctor.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';
import '../diagnostic_screen.dart';
import '../setup/setup_doctor_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../../l10n/app_localizations.dart';

/// شاشة الملف الشخصي — Premium Redesign
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Doctor? _doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      final doctor = await _firestoreService.getDoctorByUserId(user.uid);
      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.profLogout, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
        content: Text(l10n.profLogoutConfirm, style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.profCancel, style: const TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.profLogout, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    if (_doctor == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Column(
          children: [
            _buildHeader(l10n, null),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text(l10n.profErrorLabel,
                        style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.profLogout, style: const TextStyle(fontFamily: 'Cairo')),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(l10n, _doctor)),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildInfoSection(l10n),
                _buildSettingsSection(context, l10n),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Premium Hero Header with gold avatar ring ───
  Widget _buildHeader(AppLocalizations l10n, Doctor? doctor) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.premiumHeaderGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            children: [
              // Top: title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.profTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  // Edit button
                  if (doctor != null)
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SetupDoctorProfileScreen(doctor: _doctor),
                          ),
                        );
                        if (result == true && mounted) _loadDoctorData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                            const SizedBox(width: 6),
                            Text(
                              l10n.profEditProfile,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // Avatar with gold ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Gold ring
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                      boxShadow: AppColors.goldShadow,
                    ),
                  ),
                  // White spacer ring
                  Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: doctor?.photoUrl != null
                        ? NetworkImage(doctor!.photoUrl!)
                        : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: doctor?.photoUrl == null
                        ? const Icon(Icons.person_rounded, size: 48, color: AppColors.primary)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (doctor != null) ...[
                Text(
                  l10n.dashDrName(doctor.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    doctor.specialization,
                    style: const TextStyle(
                      color: AppColors.accentGoldLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Info Section ───
  Widget _buildInfoSection(AppLocalizations l10n) {
    final doctor = _doctor!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildPremiumCard(
            title: l10n.profClinicInfo,
            icon: Icons.local_hospital_rounded,
            children: [
              _buildInfoRow(Icons.local_hospital_rounded, l10n.profClinicName,
                  doctor.clinicInfo.name.isNotEmpty ? doctor.clinicInfo.name : l10n.profClinicUnspecified),
              _buildInfoRow(Icons.location_on_rounded, l10n.profAddress,
                  doctor.clinicInfo.address.isNotEmpty ? doctor.clinicInfo.address : l10n.profClinicUnspecified),
              if (doctor.clinicInfo.phone != null && doctor.clinicInfo.phone!.isNotEmpty)
                _buildInfoRow(Icons.phone_rounded, l10n.profPhone, doctor.clinicInfo.phone!),
              _buildInfoRow(Icons.payments_rounded, l10n.profFees,
                  doctor.clinicInfo.fees > 0
                      ? '${doctor.clinicInfo.fees.toStringAsFixed(0)} ${l10n.profFeesCurrency}'
                      : l10n.profClinicUnspecified),
              if (doctor.clinicInfo.workingHours != null && doctor.clinicInfo.workingHours!.isNotEmpty)
                _buildInfoRow(Icons.schedule_rounded, l10n.profWorkingHours, doctor.clinicInfo.workingHours!),
            ],
          ),
          const SizedBox(height: 14),
          _buildPremiumCard(
            title: l10n.profPersonalInfo,
            icon: Icons.person_rounded,
            children: [
              _buildInfoRow(Icons.email_rounded, l10n.profEmail, doctor.email),
              if (doctor.phone.isNotEmpty)
                _buildInfoRow(Icons.phone_rounded, l10n.profPersonalPhone, doctor.phone),
              if (doctor.yearsOfExperience > 0)
                _buildInfoRow(Icons.work_rounded, l10n.profExperience,
                    l10n.profExperienceYears(doctor.yearsOfExperience.toString())),
            ],
          ),
          if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildPremiumCard(
              title: l10n.profBio,
              icon: Icons.notes_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    doctor.bio!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.65,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Settings Section ───
  Widget _buildSettingsSection(BuildContext context, AppLocalizations l10n) {
    final items = [
      _SettingItem(
        icon: Icons.bug_report_rounded,
        color: AppColors.info,
        title: l10n.profDiagnostic,
        subtitle: l10n.profDiagnosticSub,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticScreen())),
      ),
      _SettingItem(
        icon: Icons.notifications_active_rounded,
        color: AppColors.primary,
        title: Localizations.localeOf(context).languageCode == 'ar' ? 'اختبار التنبيهات' : 'Test Notifications',
        subtitle: Localizations.localeOf(context).languageCode == 'ar' ? 'اضغط لإرسال تنبيه تجريبي لهاتفك' : 'Tap to send a test alert',
        onTap: () async {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'جاري إرسال التنبيه...' : 'Sending test notification...'),
              duration: const Duration(seconds: 2),
            ),
          );

          try {
            // Direct local notification — instant, no server needed
            await PushNotificationService().show(
              isAr ? 'اختبار التنبيهات ✅' : 'Notification Test ✅',
              isAr
                  ? 'نظام التنبيهات يعمل بنجاح على جهازك!'
                  : 'Notifications are working correctly!',
            );
          } catch (e) {
            debugPrint('❌ Test notification error: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
      _SettingItem(
        icon: Icons.settings_rounded,
        color: AppColors.textSecondary,
        title: l10n.settingsTitle,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      _SettingItem(
        icon: Icons.help_outline_rounded,
        color: AppColors.warning,
        title: l10n.profHelpSupport,
        onTap: () {},
      ),
      _SettingItem(
        icon: Icons.logout_rounded,
        color: AppColors.error,
        title: l10n.profLogout,
        isDestructive: true,
        onTap: () => _handleLogout(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: item.isDestructive ? AppColors.error : AppColors.textPrimary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Text(
                                    item.subtitle!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!item.isDestructive)
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 70, color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.glassTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.glassTeal,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper model ──────────────────────────────────────────────────────────

class _SettingItem {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });
}
