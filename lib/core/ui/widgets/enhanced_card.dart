import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_size.dart';
import '../app_padding.dart';
import 'decorative_elements.dart';
import 'premium_effects.dart';

/// Улучшенная карточка с декоративными элементами и эффектами
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final bool showPattern;
  final bool showGlow;
  final VoidCallback? onTap;
  final double? elevation;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.showPattern = false,
    this.showGlow = false,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        color: backgroundColor ?? AppColors.cardBackground,
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: showGlow
            ? PremiumEffects.softGlowShadow(
                color: AppColors.primary,
                blur: (elevation ?? 1) * AppSize.shadowBlurMedium,
              )
            : PremiumEffects.layeredShadow(
                elevation: elevation ?? 1,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppPadding.card),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              gradient: showPattern
                  ? AppColors.surfaceGradient
                  : null,
            ),
            child: showPattern
                ? DecorativeElements.cardPattern(child: child)
                : child,
          ),
        ),
      ),
    );
  }
}

/// Карточка с градиентом
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        gradient: gradient ?? AppColors.primaryGradient,
        boxShadow: PremiumEffects.softGlowShadow(
          color: AppColors.primary,
          blur: AppSize.shadowBlurLarge,
          spread: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppPadding.card),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Карточка с иконкой и декоративным элементом
class ThemedCard extends StatelessWidget {
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final String? title;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final DecorativeIconType? decorativeIcon;

  const ThemedCard({
    super.key,
    required this.child,
    this.icon,
    this.iconColor,
    this.title,
    this.padding,
    this.margin,
    this.decorativeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard(
      padding: EdgeInsets.zero,
      margin: margin,
      showPattern: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || icon != null || decorativeIcon != null)
            Container(
              padding: const EdgeInsets.all(AppPadding.card),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSize.cardRadius),
                  topRight: Radius.circular(AppSize.cardRadius),
                ),
              ),
              child: Row(
                children: [
                  if (decorativeIcon != null)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: _buildDecorativeIcon(decorativeIcon!),
                    )
                  else if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(AppPadding.small),
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor ?? AppColors.primary,
                        size: AppSize.iconSize,
                      ),
                    ),
                  if (title != null) ...[
                    const SizedBox(width: AppPadding.normal),
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppPadding.card),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcon(DecorativeIconType type) {
    switch (type) {
      case DecorativeIconType.truck:
        return DecorativeElements.truckIcon(size: 32);
      case DecorativeIconType.polygon:
        return DecorativeElements.polygonIcon(size: 32);
      case DecorativeIconType.map:
        return DecorativeElements.mapIcon(size: 32);
    }
  }
}

enum DecorativeIconType {
  truck,
  polygon,
  map,
}
