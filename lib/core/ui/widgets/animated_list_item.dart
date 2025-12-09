import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:flutter/material.dart';

/// Анимированный элемент списка с эффектами при появлении
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.onTap,
    this.isSelected = false,
  });

  final Widget child;
  final int index;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : _isHovered
                            ? AppColors.secondaryBackground
                            : null,
                    border: Border(
                      left: BorderSide(
                        color: widget.isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

