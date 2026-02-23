import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:flutter/material.dart';

/// Профессиональный чип с анимациями
class ProfessionalChip extends StatefulWidget {
  const ProfessionalChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.avatar,
    this.selected = false,
    this.color,
  });

  final String label;
  final VoidCallback? onDeleted;
  final Widget? avatar;
  final bool selected;
  final Color? color;

  @override
  State<ProfessionalChip> createState() => _ProfessionalChipState();
}

class _ProfessionalChipState extends State<ProfessionalChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (widget.selected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ProfessionalChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: widget.selected
                  ? LinearGradient(
                      colors: [
                        (widget.color ?? AppColors.primary)
                            .withOpacity(0.2),
                        (widget.color ?? AppColors.primary)
                            .withOpacity(0.1),
                      ],
                    )
                  : null,
              color: widget.selected
                  ? null
                  : AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.selected
                    ? (widget.color ?? AppColors.primary)
                    : AppColors.divider,
                width: widget.selected ? 1.5 : 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: (widget.color ?? AppColors.primary)
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.avatar != null) ...[
                  widget.avatar!,
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.caption.copyWith(
                    color: widget.selected
                        ? (widget.color ?? AppColors.primary)
                        : AppColors.textPrimary,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (widget.onDeleted != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onDeleted,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}



