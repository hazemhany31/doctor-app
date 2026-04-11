import 'package:flutter/material.dart';

/// إعدادات الـ Animations الموحدة لكل أجزاء التطبيق
/// لضمان استقرار الأداء ونفس السرعة/النعومة في كل الشاشات.
class AppAnimations {
  // فترات التحريك القياسية (Durations)
  /// سرعة عالية للتفاعلات الدقيقة مثل الضغط على زر
  static const Duration fast = Duration(milliseconds: 150);
  
  /// سرعة متوسطة للتحميل وتغيير الحالات
  static const Duration medium = Duration(milliseconds: 300);
  
  /// سرعة أبطأ قليلاً لدخول الشاشات أو البطاقات الجديدة
  static const Duration entrance = Duration(milliseconds: 400);

  // منحنيات التحريك القياسية (Curves)
  /// انسيابي للظهور
  static const Curve easeOut = Curves.easeOutCubic;
  
  /// انسيابي للاختفاء
  static const Curve easeIn = Curves.easeInCubic;
  
  /// مريح وتفاعلي جدًا (مناسب للمسة الأزرار)
  static const Curve bounce = Curves.easeOutBack;
}
