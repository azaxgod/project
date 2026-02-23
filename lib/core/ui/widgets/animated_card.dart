import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:flutter/material.dart';

/// Анимированная карточка с эффектами hover, появления и нажатия
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevated = true,
    this.onTap,
    this.animateOnBuild = true,
    this.delay = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool elevated;
  final VoidCallback? onTap;
  final bool animateOnBuild;
  final int delay; // Задержка анимации в миллисекундах

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800 + widget.delay),
    );

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.9, curve: Cubic(0.25, 0.46, 0.45, 0.94)),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.9, curve: Cubic(0.68, -0.55, 0.265, 1.55)),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.animateOnBuild) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: MouseRegion(
                onEnter: (_) {
                  if (widget.onTap != null) {
                    setState(() => _isHovered = true);
                    _hoverController.forward();
                  }
                },
                onExit: (_) {
                  setState(() {
                    _isHovered = false;
                    _isPressed = false;
                  });
                  _hoverController.reverse();
                },
                child: GestureDetector(
                  onTapDown: widget.onTap != null
                      ? (_) => setState(() => _isPressed = true)
                      : null,
                  onTapUp: widget.onTap != null
                      ? (_) {
                          setState(() => _isPressed = false);
                          widget.onTap?.call();
                        }
                      : null,
                  onTapCancel: widget.onTap != null
                      ? () => setState(() => _isPressed = false)
                      : null,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: widget.padding ?? const EdgeInsets.all(AppPadding.card),
                        decoration: BoxDecoration(
                          gradient: _isHovered
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (widget.backgroundColor ?? AppColors.cardBackground),
                                    (widget.backgroundColor ?? AppColors.cardBackground)
                                        .withOpacity(0.95),
                                  ],
                                )
                              : null,
                          color: _isHovered
                              ? null
                              : (widget.backgroundColor ?? AppColors.cardBackground),
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                          border: Border.all(
                            color: _isHovered
                                ? AppColors.primary.withOpacity(0.4 * _glowAnimation.value)
                                : AppColors.divider.withOpacity(0.6),
                            width: _isHovered ? (1.5 + _glowAnimation.value * 0.5) : 0.5,
                          ),
                          boxShadow: widget.elevated
                              ? [
                                  if (_isHovered)
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.2 * _glowAnimation.value,
                                      ),
                                      blurRadius: 20 * _glowAnimation.value,
                                      offset: Offset(0, 4 + 4 * _glowAnimation.value),
                                      spreadRadius: 3 * _glowAnimation.value,
                                    ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      _isHovered ? 0.06 : 0.04,
                                    ),
                                    blurRadius: _isHovered
                                        ? 12 + 4 * _glowAnimation.value
                                        : AppSize.shadowBlur,
                                    offset: Offset(
                                      0,
                                      _isPressed
                                          ? 2
                                          : (_isHovered
                                              ? 4 + 2 * _glowAnimation.value
                                              : 2),
                                    ),
                                    spreadRadius: _isHovered ? 1 * _glowAnimation.value : 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: AppSize.shadowBlurLarge,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        transform: Matrix4.identity()
                          ..scale(
                            _isPressed
                                ? 0.98
                                : (_isHovered
                                    ? 1.01 + 0.01 * _glowAnimation.value
                                    : 1.0),
                          )
                          ..translate(0.0, _isPressed ? 1.0 : 0.0),
                        child: widget.child,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

