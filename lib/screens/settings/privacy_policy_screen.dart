import 'package:flutter/material.dart';
import '../../config/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'سياسة الخصوصية',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'مقدمة',
              content:
                  'نحن في NBIG Doctor نأخذ خصوصية أطبائنا ومرضاهم على محمل الجد. تشرح هذه السياسة كيفية جمع واستخدام وحماية البيانات الشخصية والطبية.',
            ),
            _buildSection(
              title: 'البيانات التي نجمعها',
              content:
                  '• بيانات الحساب: مثل الاسم، التخصص العلمي، البريد الإلكتروني، ورقم الهاتف.\n'
                  '• البيانات الطبية: المواعيد، السجلات الطبية، التحاليل والتقارير المرفقة للمرضى.',
            ),
            _buildSection(
              title: 'الأذونات المطلوبة (Permissions)',
              content:
                  '• الكاميرا والمعرض: تستخدم فقط عندما تقوم بإرفاق التقارير الطبية أو تعديل صورتك الشخصية.\n'
                  '• الإشعارات: لتلقي تنبيهات عند وجود مواعيد جديدة أو رسائل من المرضى.',
            ),
            _buildSection(
              title: 'حماية البيانات',
              content:
                  'يتم تشفير جميع المحادثات والسجلات الطبية وتخزينها بأمان على خوادم سحابية مشفرة. لا نشارك بيانات مرضاك مع أي طرف ثالث لأغراض إعلانية نهائياً.',
            ),
            _buildSection(
              title: 'الاحتفاظ بالبيانات وحذفها',
              content:
                  'نحتفظ ببياناتك طالما أن حسابك نشط. يمكنك طلب "حذف الحساب" نهائياً من إعدادات التطبيق وسيتم مسح كافة سجلاتك من النظام بالكامل.',
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'آخر تحديث: 2026',
                style: TextStyle(color: AppColors.textHint, fontFamily: 'Cairo'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
