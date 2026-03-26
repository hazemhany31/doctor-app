
import 'package:flutter/material.dart';
import '../config/colors.dart';

/// Widget لعرض مؤشر التقدم في الخطوات
class ProgressStepper extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> stepTitles;

  const ProgressStepper({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.stepTitles = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          // عرض رقم الخطوة
          Text(
            'الخطوة ${currentStep + 1} من $totalSteps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12),

          // عرض النقاط
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;

              return Row(
                children: [
                  // النقطة
                  _buildStepDot(
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    stepNumber: index + 1,
                  ),

                  // الخط الفاصل
                  if (index < totalSteps - 1)
                    Container(
                      width: 40,
                      height: 2,
                      color: isCompleted
                          ? AppColors.primaryBlue
                          : AppColors.primaryBlue.withValues(alpha: 0.2),
                    ),
                ],
              );
            }),
          ),

          // عنوان الخطوة الحالية
          if (stepTitles.isNotEmpty && currentStep < stepTitles.length) ...[
            SizedBox(height: 12),
            Text(
              stepTitles[currentStep],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepDot({
    required bool isCompleted,
    required bool isCurrent,
    required int stepNumber,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent
            ? AppColors.primaryBlue
            : AppColors.primaryBlue.withValues(alpha: 0.2),
        border: Border.all(
          color: isCurrent ? AppColors.primaryBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '$stepNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Colors.white : AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

/// Progress Indicator خطي بسيط
class LinearProgressStepper extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const LinearProgressStepper({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // النص
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الخطوة ${currentStep + 1} من $totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
