import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/animations.dart';

class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isSecondary;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.padding,
    this.borderRadius = 12.0,
    this.isSecondary = false,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
      reverseDuration: AppAnimations.fast,
    );

    // Creates a slight bounce down effect
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.easeIn,
        reverseCurve: AppAnimations.bounce, // Gives a slight bounce back
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBgColor = widget.isSecondary
        ? Colors.grey.shade200
        : theme.primaryColor;
    
    final disabledColor = Colors.grey.shade400;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? disabledColor
                : (widget.backgroundColor ?? defaultBgColor),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.onPressed == null || widget.isSecondary
                ? []
                : [
                    BoxShadow(
                      color: (widget.backgroundColor ?? defaultBgColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
