
import 'package:flutter/material.dart';

/// Page transition animation محسّنة
class FadePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  FadePageRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(opacity: animation, child: builder(context));
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}

/// Slide transition من اليمين (RTL)
class SlidePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  SlidePageRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    const begin = Offset(1.0, 0.0); // من اليمين
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    var tween = Tween(begin: begin, end: end);

    return SlideTransition(
      position: tween.animate(curvedAnimation),
      child: builder(context),
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}

/// Scale transition مع fade
class ScalePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  ScalePageRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: FadeTransition(opacity: animation, child: builder(context)),
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}
