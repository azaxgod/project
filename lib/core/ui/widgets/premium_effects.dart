import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_size.dart';
import '../app_padding.dart';

/// Премиум визуальные эффекты для красивого дизайна
class PremiumEffects {
  /// Мягкая тень с цветным свечением
  static List<BoxShadow> softGlowShadow({
    Color? color,
    double blur = AppSize.shadowBlur,
    double spread = 0,
  }) {
    return [
      BoxShadow(
        color: (color ?? AppColors.primaryGlow).withOpacity(0.2),
        blurRadius: blur * 1.5,
        spreadRadius: spread,
        offset: const Offset(0, AppSize.shadowOffsetY),
      ),
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: blur,
        spreadRadius: spread,
        offset: const Offset(0, AppSize.shadowOffsetY),
      ),
    ];
  }

  /// Многослойная тень для глубины
  static List<BoxShadow> layeredShadow({
    double elevation = 1,
  }) {
    return [
      // Основная тень
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: AppSize.shadowBlur * elevation,
        offset: Offset(0, AppSize.shadowOffsetY * elevation),
      ),
      // Мягкая тень для объема
      BoxShadow(
        color: AppColors.shadowColorLight,
        blurRadius: AppSize.shadowBlur * elevation * 0.5,
        offset: Offset(0, AppSize.shadowOffsetY * elevation * 0.5),
      ),
    ];
  }

  /// Градиентная рамка
  static BoxDecoration gradientBorder({
    required Gradient gradient,
    double width = 2,
    double radius = AppSize.cardRadius,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        width: width,
        color: Colors.transparent,
      ),
      gradient: gradient,
    );
  }

  /// Эффект стекла (glassmorphism)
  static BoxDecoration glassEffect({
    double opacity = 0.8,
    double blur = 10,
    double radius = AppSize.cardRadius,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: AppColors.glassBackground.withOpacity(opacity),
      border: Border.all(
        color: AppColors.glassBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: blur,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Блестящий эффект (shimmer)
  static LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [
      Colors.white.withOpacity(0.0),
      Colors.white.withOpacity(0.3),
      Colors.white.withOpacity(0.0),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  /// Неоновое свечение
  static List<BoxShadow> neonGlow({
    required Color color,
    double intensity = 1.0,
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(0.4 * intensity),
        blurRadius: 20 * intensity,
        spreadRadius: 2 * intensity,
      ),
      BoxShadow(
        color: color.withOpacity(0.2 * intensity),
        blurRadius: 40 * intensity,
        spreadRadius: 4 * intensity,
      ),
    ];
  }
}

/// Премиум контейнер с эффектами
class PremiumContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool showGlow;
  final Color? glowColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const PremiumContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.showGlow = false,
    this.glowColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppSize.cardRadius),
        color: backgroundColor,
        gradient: gradient,
        boxShadow: showGlow
            ? PremiumEffects.softGlowShadow(
                color: glowColor,
                blur: (elevation ?? 1) * AppSize.shadowBlur,
              )
            : PremiumEffects.layeredShadow(
                elevation: elevation ?? 1,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSize.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSize.cardRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppPadding.card),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Градиентный текст
class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? style;

  const GradientText({
    super.key,
    required this.text,
    required this.gradient,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Анимированный градиентный фон
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.colors,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors.map((color) {
                final opacity = 0.05 + (_controller.value * 0.05);
                return color.withOpacity(opacity);
              }).toList(),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}


