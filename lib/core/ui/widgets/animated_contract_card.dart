import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';

/// Анимированная карточка контракта для мобильных устройств
class AnimatedContractCard extends StatefulWidget {
  const AnimatedContractCard({
    super.key,
    required this.contract,
    required this.contractorName,
    required this.onTap,
    this.index = 0,
  });

  final Contract contract;
  final String contractorName;
  final VoidCallback onTap;
  final int index;

  @override
  State<AnimatedContractCard> createState() => _AnimatedContractCardState();
}

class _AnimatedContractCardState extends State<AnimatedContractCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ContractStatus _getContractStatus(Contract contract) {
    final now = DateTime.now();
    if (!contract.isActive) return ContractStatus.archived;
    if (now.isBefore(contract.startAt)) return ContractStatus.planned;
    if (now.isAfter(contract.endAt)) return ContractStatus.expired;
    return ContractStatus.active;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final status = _getContractStatus(widget.contract);
    final volumeProgress = widget.contract.usage != null &&
            widget.contract.minimalVolumeM3 > 0
        ? (widget.contract.usage!.totalVolumeM3 /
                widget.contract.minimalVolumeM3 *
                100.0)
            .clamp(0.0, 100.0)
        : 0.0;
    final budgetProgress = widget.contract.budgetTotal > 0
        ? (widget.contract.usage?.totalCost ?? 0.0) /
                widget.contract.budgetTotal *
                100.0
        : 0.0;
    final budgetExceeded =
        (widget.contract.usage?.totalCost ?? 0.0) >
            widget.contract.budgetTotal;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: AppPadding.normal),
              transform: Matrix4.identity()
                ..scale(_isPressed ? 0.98 : 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with gradient
                      Container(
                        padding: const EdgeInsets.all(AppPadding.large),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(status).withOpacity(0.1),
                              _getStatusColor(status).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.contract.name,
                                    style: AppTextStyles.title2.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.xs),
                                  Text(
                                    widget.contractorName,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(status: status),
                          ],
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(AppPadding.large),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Период',
                              value:
                                  '${dateFormat.format(widget.contract.startAt)} - ${dateFormat.format(widget.contract.endAt)}',
                            ),
                            const SizedBox(height: AppPadding.small),
                            _InfoRow(
                              icon: Icons.attach_money,
                              label: 'Цена за м³',
                              value:
                                  '${widget.contract.pricePerM3.toStringAsFixed(2)} ₸',
                            ),
                            const SizedBox(height: AppPadding.normal),
                            // Volume progress
                            _AnimatedProgressSection(
                              label: 'Освоение объёма',
                              progress: volumeProgress,
                              value:
                                  '${widget.contract.usage?.totalVolumeM3.toStringAsFixed(1) ?? '0'} / ${widget.contract.minimalVolumeM3.toStringAsFixed(1)} м³',
                              color: Colors.blue,
                            ),
                            const SizedBox(height: AppPadding.normal),
                            // Budget progress
                            _AnimatedProgressSection(
                              label: 'Освоение бюджета',
                              progress: budgetProgress,
                              value:
                                  '${(widget.contract.usage?.totalCost ?? 0.0).toStringAsFixed(0)} / ${widget.contract.budgetTotal.toStringAsFixed(0)} ₸',
                              color: budgetExceeded ? Colors.red : Colors.green,
                            ),
                            const SizedBox(height: AppPadding.normal),
                            // Budget exceeded indicator
                            Container(
                              padding: const EdgeInsets.all(AppPadding.small),
                              decoration: BoxDecoration(
                                color: budgetExceeded
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: budgetExceeded
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    budgetExceeded
                                        ? Icons.warning
                                        : Icons.check_circle,
                                    size: 20,
                                    color: budgetExceeded
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: AppPadding.small),
                                  Expanded(
                                    child: Text(
                                      'Превышение бюджета: ${budgetExceeded ? 'Да' : 'Нет'}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: budgetExceeded
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppPadding.normal),
                            // Action button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: widget.onTap,
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Открыть'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppPadding.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.planned:
        return Colors.blue;
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.expired:
        return Colors.orange;
      case ContractStatus.archived:
        return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ContractStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ContractStatus.planned:
        color = Colors.blue;
        label = 'Запланирован';
        icon = Icons.schedule;
        break;
      case ContractStatus.active:
        color = Colors.green;
        label = 'Активен';
        icon = Icons.check_circle;
        break;
      case ContractStatus.expired:
        color = Colors.orange;
        label = 'Истёк';
        icon = Icons.access_time;
        break;
      case ContractStatus.archived:
        color = Colors.grey;
        label = 'Архив';
        icon = Icons.archive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppPadding.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedProgressSection extends StatefulWidget {
  const _AnimatedProgressSection({
    required this.label,
    required this.progress,
    required this.value,
    required this.color,
  });

  final String label;
  final double progress;
  final String value;
  final Color color;

  @override
  State<_AnimatedProgressSection> createState() =>
      _AnimatedProgressSectionState();
}

class _AnimatedProgressSectionState
    extends State<_AnimatedProgressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _controller.reset();
      _progressAnimation = Tween<double>(
        begin: 0.0,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${_progressAnimation.value.toStringAsFixed(1)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppPadding.xs),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progressAnimation.value / 100,
                minHeight: 10,
                backgroundColor: AppColors.secondaryBackground,
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            );
          },
        ),
        const SizedBox(height: AppPadding.xs),
        Text(
          widget.value,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

