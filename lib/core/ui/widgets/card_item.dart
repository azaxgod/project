import 'package:akimat_project/core/ui/widgets/animated_card.dart';
import 'package:flutter/material.dart';


class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool elevated;
  final bool animateOnBuild;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevated = true,
    this.animateOnBuild = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: padding,
      backgroundColor: backgroundColor,
      elevated: elevated,
      animateOnBuild: animateOnBuild,
      child: child,
    );
  }
}
