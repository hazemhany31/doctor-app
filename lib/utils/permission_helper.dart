import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/colors.dart';

/// مساعد الأذونات - للتعامل مع طلبات الصلاحيات بشكل احترافي ومتوافق مع المتاجر
class PermissionHelper {
  /// طلب صلاحية الكاميرا مع شرح مسبق
  static Future<bool> requestCameraPermission(BuildContext context) async {
    return _requestWithRationale(
      context: context,
      permission: Permission.camera,
      title: 'الوصول للكاميرا',
      description: 'نحتاج للوصول للكاميرا لتتمكن من التقاط صور التقارير الطبية والتحاليل لمشاركتها مع المريض.',
      icon: Icons.camera_alt_rounded,
    );
  }

  /// طلب صلاحية الإشعارات مع شرح مسبق
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    return _requestWithRationale(
      context: context,
      permission: Permission.notification,
      title: 'تفعيل التنبيهات',
      description: 'نحتاج لتفعيل التنبيهات لنقوم بإخطارك بالمواعيد الجديدة، الرسائل من المرضى، وتحديثات الحالات.',
      icon: Icons.notifications_active_rounded,
    );
  }

  /// طلب صلاحية معرض الصور
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    return _requestWithRationale(
      context: context,
      permission: Permission.photos,
      title: 'الوصول للمعرض',
      description: 'نحتاج للوصول لمعرض الصور لتتمكن من اختيار وإرفاق المستندات والتقارير الطبية المخزنة على جهازك.',
      icon: Icons.photo_library_rounded,
    );
  }

  /// منطق الطلب مع إظهار شرح (Rationale)
  static Future<bool> _requestWithRationale({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String description,
    required IconData icon,
  }) async {
    final status = await permission.status;

    // إذا ممنوعة بشكل دائم، نوجه للإعدادات مباشرة
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, title);
      }
      return false;
    }

    // إذا ممنوحة مسبقاً (حتى لو من إعدادات الجهاز مباشرة)، نحفظ الـ flag ونرجع true
    if (status.isGranted) {
      if (permission == Permission.notification) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pref_notification_granted', true);
      }
      return true;
    }

    // للإشعارات فقط: لو المستخدم وافق قبل كده، نحاول نطلب مباشرة بدون dialog
    if (permission == Permission.notification) {
      final prefs = await SharedPreferences.getInstance();
      final hasGrantedBefore = prefs.getBool('pref_notification_granted') ?? false;
      if (hasGrantedBefore) {
        // المستخدم وافق قبل كده — نطلب الإذن من النظام مباشرة
        final result = await permission.request();
        return result.isGranted;
      }
    }

    // إظهار شرح قبل طلب الصلاحية (Compliance Best Practice)
    if (!context.mounted) return false;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18)),
          ],
        ),
        content: Text(
          description,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ليس الآن', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    // لو المستخدم ضغط "ليس الآن" — لا نحفظ شيء، نسأله المرة الجاية
    if (proceed != true) return false;

    // المستخدم ضغط "موافق" — نطلب الإذن الفعلي من نظام التشغيل
    final result = await permission.request();

    if (result.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, title);
      }
      return false;
    }

    // نحفظ أن المستخدم وافق (فقط لو النظام قبل)
    if (result.isGranted && permission == Permission.notification) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_notification_granted', true);
    }

    return result.isGranted;
  }

  static void _showSettingsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تفعيل $title', style: const TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'تلقينا رفضاً دائماً للوصول. يرجى تفعيل الصلاحية من إعدادات النظام لتتمكن من استخدام هذه الميزة.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            child: const Text('فتح الإعدادات', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
