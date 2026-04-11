
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../config/colors.dart';
import '../../providers/locale_provider.dart';
import 'privacy_policy_screen.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';

/// شاشة الإعدادات
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEnglish = localeProvider.locale.languageCode == 'en';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.headerGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Row(
                    children: [
                      Text(
                        l10n.settingsTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.settings_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === التفضيلات ===
                  _buildSectionHeader(l10n.preferencesSection),
                  SizedBox(height: 8),
                  _buildCard([
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.primary,
                      title: l10n.languageTitle,
                      subtitle: l10n.languageSubtitle,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: !isEnglish
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ),
                          SizedBox(width: 4),
                          Switch(
                            value: isEnglish,
                            onChanged: (v) {
                              if (v) {
                                localeProvider.setLocale(const Locale('en'));
                              } else {
                                localeProvider.setLocale(const Locale('ar'));
                              }
                            },
                            activeThumbColor: AppColors.primary,
                            thumbColor: WidgetStateProperty.all(Colors.white),
                            trackColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.surfaceVariant,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'EN',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isEnglish
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      iconColor: AppColors.warning,
                      title: l10n.notificationsTitle,
                      subtitle: _notificationsEnabled
                          ? l10n.notificationsEnabled
                          : l10n.notificationsDisabled,
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                  ]),

                  SizedBox(height: 20),

                  // === الدعم والمساعدة ===
                  _buildSectionHeader(l10n.supportSection),
                  SizedBox(height: 8),
                  _buildCard([
                    _SettingsTile(
                      icon: Icons.phone_rounded,
                      iconColor: AppColors.success,
                      title: l10n.supportPhoneTitle,
                      subtitle: '01112221121',
                      onTap: () => _callNumber('01112221121'),
                      trailing: Icon(
                        Icons.call_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.headset_mic_rounded,
                      iconColor: Color(0xFF8B5CF6),
                      title: l10n.supportCustomerTitle,
                      subtitle: '19938',
                      onTap: () => _callNumber('19938'),
                      trailing: Icon(
                        Icons.call_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: AppColors.info,
                      title: l10n.supportWhatsappTitle,
                      subtitle: l10n.supportWhatsappSubtitle,
                      onTap: () => _openWhatsApp('01112221121'),
                      trailing: Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                    ),
                  ]),

                  SizedBox(height: 20),

                  // === معلومات التطبيق ===
                  _buildSectionHeader(l10n.aboutSection),
                  SizedBox(height: 8),
                  _buildCard([
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.info,
                      title: l10n.appVersionTitle,
                      subtitle: '1.0.0',
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.primary,
                      title: l10n.privacyPolicyTitle,
                      subtitle: l10n.privacyPolicySubtitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ),
                  ]),

                  SizedBox(height: 20),

                  // === حسابي ===
                  _buildSectionHeader('إدارة الحساب'),
                  SizedBox(height: 8),
                  _buildCard([
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: AppColors.error,
                      title: 'حذف الحساب نهائياً',
                      subtitle: 'سيتم مسح جميع بياناتك وسجلاتك للأبد',
                      onTap: () => _confirmDeleteAccount(context),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ),
                  ]),

                  SizedBox(height: 100), // bottom nav padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('تأكيد حذف الحساب', style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه، وسيتم مسح جميع بيانات مرضاك وسجلاتك من النظام بالكامل تماشياً مع سياسات الخصوصية.',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              _showReauthDialog(context); // 항상 كلمه السر اوالاً لضمان حداثة الجلسة (ALWAYS ask for password first)
            },
            child: Text('الموافقة والحذف', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount(BuildContext context, {String? password}) async {
    // إظهار شاشة تحميل للانتظار
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // إذا كان هناك كلمة مرور، نقوم بإعادة المصادقة أولاً
      if (password != null) {
        await authService.reauthenticate(password);
      }

      await authService.deleteAccount();
      
      // التخلص من شاشة الانتظار
      if (context.mounted) Navigator.pop(context);

      // الذهاب لشاشة تسجيل الدخول
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      
      final errorMsg = e.toString();
      if (errorMsg.contains('REQUIRES_REAUTH')) {
        // إذا طلب النظام إعادة المصادقة، نظهر نافذة كلمة المرور
        if (context.mounted) _showReauthDialog(context);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg.replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showReauthDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الهوية', style: TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لحذف الحساب، يرجى إدخال كلمة المرور الحالية لتأكيد هويتك.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              final pwd = passwordController.text.trim();
              if (pwd.isEmpty) return;
              Navigator.pop(ctx);
              _performDeleteAccount(context, password: pwd);
            },
            child: const Text('تأكيد وحذف', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final uri = Uri.parse('https://wa.me/2$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
      ),
      trailing: trailing,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 70),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}
