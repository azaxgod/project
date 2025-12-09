import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:flutter/material.dart';

/// Улучшенная анимированная кнопка с эффектами
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.icon,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
    this.useBlackText = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;
  final double? width;
  final bool useBlackText;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Более плавная fade анимация
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutCubic,
      ),
    );
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.useBlackText) {
      return Colors.white; // Белый фон для черного текста
    }
    if (widget.isDestructive) {
      return widget.isOutlined 
          ? AppColors.error.withOpacity(0.1) 
          : AppColors.error;
    }
    return widget.isOutlined 
        ? AppColors.primary.withOpacity(0.1) 
        : AppColors.primary;
  }

  Color get _textColor {
    if (widget.useBlackText) {
      return AppColors.textPrimary;
    }
    if (widget.isOutlined) {
      return widget.isDestructive 
          ? AppColors.error 
          : AppColors.primary;
    }
    return Colors.white;
  }

  Color get _borderColor {
    if (widget.isOutlined) {
      return widget.isDestructive 
          ? AppColors.error 
          : AppColors.primary;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward(); // Плавное появление вместо repeat
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
        _hoverController.reverse(); // Плавное исчезновение
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          if (!widget.isLoading) {
            widget.onPressed();
          }
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: AppSize.buttonHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSize.buttonRadius),
                  boxShadow: _isHovered && !widget.isOutlined
                      ? [
                          BoxShadow(
                            color: (widget.isDestructive
                                    ? AppColors.error
                                    : AppColors.primary)
                                .withOpacity(0.5 * _glowAnimation.value),
                            blurRadius: 16 * _glowAnimation.value,
                            offset: Offset(0, 4 + 2 * _glowAnimation.value),
                            spreadRadius: 2 * _glowAnimation.value,
                          ),
                        ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSize.buttonRadius),
                  child: Stack(
                    children: [
                      // Gradient background
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          gradient: _isHovered
                              ? (!widget.isOutlined
                                  ? LinearGradient(
                                      colors: widget.isDestructive
                                          ? [
                                              AppColors.error,
                                              AppColors.errorLight,
                                            ]
                                          : [
                                              AppColors.primary,
                                              AppColors.primaryLight,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: widget.isDestructive
                                          ? [
                                              AppColors.error.withOpacity(0.2),
                                              AppColors.errorLight.withOpacity(0.15),
                                            ]
                                          : [
                                              AppColors.primary.withOpacity(0.2),
                                              AppColors.primaryLight.withOpacity(0.15),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ))
                              : null,
                          color: _isHovered
                              ? null
                              : _backgroundColor,
                          borderRadius: BorderRadius.circular(AppSize.buttonRadius),
                          border: Border.all(
                            color: _isHovered
                                ? (_borderColor == Colors.transparent
                                    ? AppColors.primaryLight.withOpacity(
                                        0.6 * _glowAnimation.value,
                                      )
                                    : _borderColor.withOpacity(
                                        0.8 + 0.2 * _glowAnimation.value,
                                      ))
                                : _borderColor,
                            width: _isHovered
                                ? (2 + 0.5 * _glowAnimation.value)
                                : (widget.isOutlined ? 2 : 1.5),
                          ),
                          boxShadow: widget.isOutlined && _isHovered
                              ? [
                                  BoxShadow(
                                    color: (widget.isDestructive
                                            ? AppColors.error
                                            : AppColors.primary)
                                        .withOpacity(0.2 * _glowAnimation.value),
                                    blurRadius: 8 * _glowAnimation.value,
                                    offset: const Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      // Shimmer effect (только для кнопок без черного текста)
                      if (_isHovered && !widget.isOutlined && !widget.useBlackText)
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(
                              _shimmerAnimation.value * 50,
                              0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Content
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isLoading ? null : widget.onPressed,
                          borderRadius: BorderRadius.circular(AppSize.buttonRadius),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.normal,
                              vertical: AppPadding.small,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.isLoading) ...[
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _textColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppPadding.small),
                                ] else if (widget.icon != null) ...[
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    transform: Matrix4.identity()
                                      ..scale(_isHovered ? 1.1 : 1.0),
                                    child: Icon(
                                      widget.icon,
                                      size: AppSize.iconSizeSmall,
                                      color: _textColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppPadding.small),
                                ],
                                Text(
                                  widget.label,
                                  style: AppTextStyles.button.copyWith(
                                    color: _textColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

