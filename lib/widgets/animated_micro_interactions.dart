import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/colors.dart';
import '../config/animations.dart';
class AnimatedSuccessIcon extends StatelessWidget {
  final double size;
  final Color color;

  const AnimatedSuccessIcon({
    super.key,
    this.size = 100,
    this.color = AppColors.confirmedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_rounded,
        size: size * 0.6,
        color: color,
      ),
    )
        .animate(onInit: (_) => HapticFeedback.mediumImpact())
        .scale(
            curve: AppAnimations.bounce,
            duration: 600.ms,
            begin: const Offset(0, 0),
            end: const Offset(1, 1))
        .fadeIn(duration: AppAnimations.entrance);
  }
}

/// لافتة (Badge) تنبض لجذب الانتباه (مثلا للإشعارات الجديدة)
class PulsingBadge extends StatelessWidget {
  final Widget child;

  const PulsingBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.1, 1.1),
      curve: Curves.easeInOut,
      duration: 800.ms,
    );
  }
}

/// حالة تحميل مخصصة بشكل دائري يدور مع ظل
class PremiumLoadingSpinner extends StatelessWidget {
  const PremiumLoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).shimmer(
        duration: 1500.ms,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
