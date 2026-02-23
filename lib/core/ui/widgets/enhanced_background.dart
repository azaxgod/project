import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'decorative_elements.dart';

/// Улучшенный фон с декоративными элементами
class EnhancedBackground extends StatelessWidget {
  final Widget child;
  final bool showDecorativeCircles;
  final bool showPattern;
  final Color? backgroundColor;

  const EnhancedBackground({
    super.key,
    required this.child,
    this.showDecorativeCircles = true,
    this.showPattern = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.background,
      child: Stack(
        children: [
          if (showDecorativeCircles) ...[
            // Большой декоративный круг справа вверху
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.primary.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Средний декоративный круг слева внизу
            Positioned(
              bottom: -200,
              left: -200,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Маленький декоративный круг в центре
            Positioned(
              top: 200,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.info.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (showPattern)
            Positioned.fill(
              child: DecorativeElements.dotPattern(
                color: AppColors.textTertiary.withOpacity(0.2),
                spacing: 30,
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Фон с градиентом и декоративными элементами
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final List<Widget>? additionalDecorations;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.additionalDecorations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.backgroundGradient,
      ),
      child: Stack(
        children: [
          if (additionalDecorations != null) ...additionalDecorations!,
          child,
        ],
      ),
    );
  }
}

/// Декоративный разделитель с волной
class WaveDivider extends StatelessWidget {
  final Color? color;
  final double height;
  final bool flip;

  const WaveDivider({
    super.key,
    this.color,
    this.height = 60,
    this.flip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipY: flip,
      child: DecorativeElements.waveDecoration(
        color: color ?? AppColors.primary.withOpacity(0.1),
        height: height,
      ),
    );
  }
}


