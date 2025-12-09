import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:flutter/material.dart';

/// Профессиональный бейдж с анимациями и градиентами
class ProfessionalBadge extends StatefulWidget {
  const ProfessionalBadge({
    super.key,
    required this.text,
    this.type = BadgeType.primary,
    this.size = BadgeSize.medium,
    this.icon,
    this.animate = true,
  });

  final String text;
  final BadgeType type;
  final BadgeSize size;
  final IconData? icon;
  final bool animate;

  @override
  State<ProfessionalBadge> createState() => _ProfessionalBadgeState();
}

enum BadgeType {
  primary,
  success,
  error,
  warning,
  info,
  secondary,
}

enum BadgeSize {
  small,
  medium,
  large,
}

class _ProfessionalBadgeState extends State<ProfessionalBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case BadgeType.success:
        return AppColors.success;
      case BadgeType.error:
        return AppColors.error;
      case BadgeType.warning:
        return AppColors.warning;
      case BadgeType.info:
        return AppColors.primary;
      case BadgeType.secondary:
        return AppColors.secondary;
      case BadgeType.primary:
      default:
        return AppColors.primary;
    }
  }

  Color get _lightColor {
    switch (widget.type) {
      case BadgeType.success:
        return AppColors.successLight;
      case BadgeType.error:
        return AppColors.errorLight;
      case BadgeType.warning:
        return AppColors.warningLight;
      case BadgeType.info:
        return AppColors.primaryLight;
      case BadgeType.secondary:
        return AppColors.secondaryLight;
      case BadgeType.primary:
      default:
        return AppColors.primaryLight;
    }
  }

  double get _padding {
    switch (widget.size) {
      case BadgeSize.small:
        return AppPadding.xs;
      case BadgeSize.large:
        return AppPadding.small;
      case BadgeSize.medium:
      default:
        return 6;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.large:
        return 14;
      case BadgeSize.medium:
      default:
        return 12;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.large:
        return 16;
      case BadgeSize.medium:
      default:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _padding,
                vertical: _padding * 0.7,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _backgroundColor,
                    _lightColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _backgroundColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: _iconSize,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    widget.text,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Статусный индикатор для активных/неактивных элементов
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.isActive,
    this.size = 8,
    this.showPulse = true,
  });

  final bool isActive;
  final double size;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    if (!showPulse || !isActive) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? AppColors.success : AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.6 * (1 - value)),
                blurRadius: size * 2 * value,
                spreadRadius: size * value,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // Restart animation
      },
    );
  }
}

