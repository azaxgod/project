import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_textstyle.dart';
import '../app_size.dart';
import '../app_padding.dart';
import 'premium_effects.dart';

/// Современный текстовый виджет с градиентом
class ModernGradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ModernGradientText({
    super.key,
    required this.text,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: (style ?? AppTextStyles.title2).copyWith(
          color: Colors.white,
        ),
        textAlign: textAlign,
      ),
    );
  }
}

/// Текст с мягкой тенью для глубины
class TextWithShadow extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;
  final TextAlign? textAlign;

  const TextWithShadow({
    super.key,
    required this.text,
    required this.style,
    this.shadowColor = const Color(0x0F0A0E27), // Default shadow color with opacity (0x0F = ~6% opacity)
    this.shadowOffset = const Offset(0, 2),
    this.shadowBlur = 4,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style.copyWith(
        shadows: [
          Shadow(
            color: shadowColor,
            offset: shadowOffset,
            blurRadius: shadowBlur,
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

/// Элегантный заголовок с подчеркиванием
class ElegantHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color underlineColor;
  final double underlineHeight;
  final EdgeInsets? padding;

  const ElegantHeading({
    super.key,
    required this.text,
    this.style,
    this.underlineColor = AppColors.primary,
    this.underlineHeight = 3,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.only(bottom: AppPadding.small),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: underlineColor,
            width: underlineHeight,
          ),
        ),
      ),
      child: Text(
        text,
        style: style ?? AppTextStyles.title2,
      ),
    );
  }
}

/// Текст с иконкой
class TextWithIcon extends StatelessWidget {
  final String text;
  final IconData icon;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double? iconSize;
  final double spacing;
  final MainAxisAlignment alignment;

  const TextWithIcon({
    super.key,
    required this.text,
    required this.icon,
    this.textStyle,
    this.iconColor,
    this.iconSize,
    this.spacing = 8,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: iconSize ?? 20,
        ),
        SizedBox(width: spacing),
        Text(
          text,
          style: textStyle ?? AppTextStyles.body,
        ),
      ],
    );
  }
}

/// Бейдж/метка с современным дизайном
class ModernBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final double? borderRadius;

  const ModernBadge({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.textStyle,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppPadding.normal,
            vertical: AppPadding.xs,
          ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSize.pillRadius,
        ),
        boxShadow: PremiumEffects.layeredShadow(elevation: 0.5),
      ),
      child: Text(
        text,
        style: (textStyle ?? AppTextStyles.footnote).copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Статистический блок с большим числом
class StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;

  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveGradient = gradient ?? AppColors.primaryGradient;

    return Container(
      padding: const EdgeInsets.all(AppPadding.card),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        gradient: effectiveGradient,
        boxShadow: PremiumEffects.softGlowShadow(
          color: effectiveColor,
          blur: AppSize.shadowBlurMedium,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: AppPadding.small),
          ],
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.9)],
            ).createShader(bounds),
            child: Text(
              value,
              style: AppTextStyles.title1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppPadding.xs),
          Text(
            label,
            style: AppTextStyles.footnote.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Современный список с разделителями
class ModernList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final Color? dividerColor;

  const ModernList({
    super.key,
    required this.children,
    this.padding,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (context, index) => Divider(
        color: dividerColor ?? AppColors.divider,
        height: 1,
        thickness: 1,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Текст с анимацией появления
class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  const AnimatedText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOut,
  });

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: Text(
          widget.text,
          style: widget.style,
        ),
      ),
    );
  }
}

/// Текст с градиентным подчеркиванием
class TextWithGradientUnderline extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final double underlineHeight;

  const TextWithGradientUnderline({
    super.key,
    required this.text,
    this.style,
    required this.gradient,
    this.underlineHeight = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: style ?? AppTextStyles.title2,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: underlineHeight,
            decoration: BoxDecoration(
              gradient: gradient,
            ),
          ),
        ),
      ],
    );
  }
}
