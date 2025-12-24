import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:flutter/material.dart';
// import '../../app_colors.dart';
// import '../../app_padding.dart';
// import '../../app_size.dart';
// import '../../app_textstyle.dart';
import 'decorative_elements.dart';
import 'enhanced_card.dart';

/// Красивое пустое состояние с декоративными элементами
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final DecorativeIconType? decorativeIcon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;

  const EmptyState({
    super.key,
    this.icon,
    this.decorativeIcon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Декоративный фон для иконки
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (iconColor ?? AppColors.primary).withOpacity(0.15),
                    (iconColor ?? AppColors.primary).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: decorativeIcon != null
                    ? SizedBox(
                        width: 80,
                        height: 80,
                        child: _buildDecorativeIcon(decorativeIcon!),
                      )
                    : Icon(
                        icon ?? Icons.inbox_outlined,
                        size: AppSize.iconSizeXXLarge,
                        color: iconColor ?? AppColors.textTertiary,
                      ),
              ),
            ),
            const SizedBox(height: AppPadding.xl),
            Text(
              title,
              style: AppTextStyles.title2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppPadding.small),
              Text(
                subtitle!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppPadding.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeIcon(DecorativeIconType type) {
    switch (type) {
      case DecorativeIconType.truck:
        return DecorativeElements.truckIcon(
          size: 80,
          color: AppColors.primary,
        );
      case DecorativeIconType.polygon:
        return DecorativeElements.polygonIcon(
          size: 80,
          color: AppColors.secondary,
        );
      case DecorativeIconType.map:
        return DecorativeElements.mapIcon(
          size: 80,
          color: AppColors.info,
        );
    }
  }
}

/// Декоративный разделитель секции
class SectionDivider extends StatelessWidget {
  final String? title;
  final Widget? trailing;

  const SectionDivider({
    super.key,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppPadding.large),
      child: Row(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.headline,
            ),
            const SizedBox(width: AppPadding.normal),
          ],
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.divider,
                    AppColors.divider.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppPadding.normal),
            trailing!,
          ],
        ],
      ),
    );
  }
}

