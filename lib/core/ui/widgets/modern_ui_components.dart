import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_textstyle.dart';
import '../app_size.dart';
import '../app_padding.dart';
import 'premium_effects.dart';
import 'modern_text_widgets.dart';

/// Современная кнопка с градиентом и эффектами
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final IconData? icon;
  final bool isLoading;
  final EdgeInsets? padding;
  final double? borderRadius;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.icon,
    this.isLoading = false,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.primaryGradient;
    final effectiveColor = backgroundColor ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSize.buttonRadius,
        ),
        gradient: backgroundColor == null ? effectiveGradient : null,
        color: backgroundColor,
        boxShadow: PremiumEffects.softGlowShadow(
          color: effectiveColor,
          blur: AppSize.shadowBlurMedium,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSize.buttonRadius,
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppSize.buttonRadius,
          ),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppPadding.buttonHorizontal,
                  vertical: AppPadding.buttonVertical,
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppPadding.small),
                ],
                if (!isLoading || icon == null)
                  Text(
                    text,
                    style: AppTextStyles.button,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Современное поле ввода
class ModernInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const ModernInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppPadding.xs),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.buttonRadius),
            color: AppColors.surface,
            border: Border.all(
              color: AppColors.border,
              width: 1.5,
            ),
            boxShadow: PremiumEffects.layeredShadow(elevation: 0.5),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            keyboardType: keyboardType,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
              suffixIcon: suffixIcon != null
                  ? InkWell(
                      onTap: onSuffixTap,
                      child: Icon(
                        suffixIcon,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppPadding.inputHorizontal,
                vertical: AppPadding.inputVertical,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Современная карточка статистики
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveGradient = gradient ?? AppColors.primaryGradient;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        gradient: effectiveGradient,
        boxShadow: PremiumEffects.softGlowShadow(
          color: effectiveColor,
          blur: AppSize.shadowBlurMedium,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppPadding.small),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppPadding.normal),
                ],
                Text(
                  value,
                  style: AppTextStyles.title1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  title,
                  style: AppTextStyles.footnote.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Современный список элементов
class ModernListItem extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const ModernListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppPadding.normal,
        vertical: AppPadding.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSize.mediumRadius),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: PremiumEffects.layeredShadow(elevation: 0.3),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSize.mediumRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.mediumRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.normal),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: AppTextStyles.body,
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppPadding.xs),
                        DefaultTextStyle(
                          style: AppTextStyles.footnote,
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppPadding.normal),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Современный разделитель секций
class ModernSectionDivider extends StatelessWidget {
  final String? title;
  final Widget? action;

  const ModernSectionDivider({
    super.key,
    this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.normal,
        vertical: AppPadding.medium,
      ),
      child: Row(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.title3,
            ),
            const Expanded(
              child: Divider(
                indent: AppPadding.normal,
                color: AppColors.divider,
                thickness: 1,
              ),
            ),
          ] else
            const Expanded(
              child: Divider(
                color: AppColors.divider,
                thickness: 1,
              ),
            ),
          if (action != null) ...[
            const SizedBox(width: AppPadding.normal),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Современный чип/тег
class ModernChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onDeleted;
  final bool selected;

  const ModernChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onDeleted,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = selected
        ? (backgroundColor ?? AppColors.primary)
        : (backgroundColor ?? AppColors.secondaryBackground);
    final effectiveTextColor = selected
        ? (textColor ?? Colors.white)
        : (textColor ?? AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.normal,
        vertical: AppPadding.xs,
      ),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(AppSize.pillRadius),
        border: selected
            ? null
            : Border.all(
                color: AppColors.border,
                width: 1,
              ),
        boxShadow: selected
            ? PremiumEffects.softGlowShadow(
                color: backgroundColor ?? AppColors.primary,
                blur: AppSize.shadowBlurSmall,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: effectiveTextColor,
            ),
            const SizedBox(width: AppPadding.xs),
          ],
          Text(
            label,
            style: AppTextStyles.footnote.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AppPadding.xs),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                Icons.close,
                size: 16,
                color: effectiveTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

