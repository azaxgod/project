import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:flutter/material.dart';

class VehicleCard extends StatefulWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.driver,
    required this.onTap,
    this.onEdit,
    this.onAssignDriver,
  });

  final Vehicle vehicle;
  final Driver? driver;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssignDriver;

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverName = (widget.driver?.id.isNotEmpty ?? false)
        ? widget.driver!.fullName
        : 'Не назначен';

    final hasDriver = widget.driver?.id.isNotEmpty ?? false;
    final statusColor = widget.vehicle.isActive
        ? AppColors.success
        : AppColors.error;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          AppColors.cardBackground,
                          statusColor.withOpacity(0.02),
                        ]
                      : [
                          AppColors.cardBackground,
                          AppColors.cardBackground,
                        ],
                ),
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                border: Border.all(
                  color: _isHovered
                      ? statusColor.withOpacity(0.3)
                      : AppColors.divider,
                  width: _isHovered ? 1.5 : 0.5,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: statusColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: AppSize.shadowBlur,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: AppSize.shadowBlurLarge,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(AppSize.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.large),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Фото техники или иконка
                        _buildVehicleImage(hasDriver),
                        const SizedBox(width: AppPadding.large),
                        // Информация о технике
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок с госномером
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.vehicle.plateNumber,
                                          style: AppTextStyles.title2.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            fontSize: 20,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_shipping,
                                              size: 16,
                                              color: AppColors.primary.withOpacity(0.7),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${widget.vehicle.brand} ${widget.vehicle.model}',
                                              style: AppTextStyles.body.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Статус badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: widget.vehicle.isActive
                                            ? [
                                                AppColors.success.withOpacity(0.15),
                                                AppColors.success.withOpacity(0.1),
                                              ]
                                            : [
                                                AppColors.error.withOpacity(0.15),
                                                AppColors.error.withOpacity(0.1),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.vehicle.isActive
                                              ? 'Активна'
                                              : 'Неактивна',
                                          style: AppTextStyles.caption.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Детали в красивых карточках
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildModernInfoCard(
                                    icon: Icons.palette_outlined,
                                    label: 'Цвет',
                                    value: widget.vehicle.color,
                                    color: Colors.purple,
                                  ),
                                  _buildModernInfoCard(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Год',
                                    value: widget.vehicle.year.toString(),
                                    color: Colors.blue,
                                  ),
                                  _buildModernInfoCard(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Объём',
                                    value:
                                        '${widget.vehicle.bodyVolumeM3.toStringAsFixed(1)} м³',
                                    color: Colors.orange,
                                  ),
                                  _buildModernInfoCard(
                                    icon: hasDriver
                                        ? Icons.person_outline
                                        : Icons.person_off_outlined,
                                    label: 'Водитель',
                                    value: driverName,
                                    color: hasDriver ? Colors.green : Colors.grey,
                                    isHighlighted: !hasDriver,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Действия
                              Row(
                                children: [
                                  if (widget.onEdit != null)
                                    _buildActionButton(
                                      icon: Icons.edit_outlined,
                                      label: 'Редактировать',
                                      onPressed: widget.onEdit!,
                                      color: AppColors.primary,
                                    ),
                                  if (widget.onAssignDriver != null) ...[
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      icon: hasDriver
                                          ? Icons.swap_horiz_outlined
                                          : Icons.person_add_outlined,
                                      label: hasDriver
                                          ? 'Сменить водителя'
                                          : 'Назначить водителя',
                                      onPressed: widget.onAssignDriver!,
                                      color: hasDriver
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ],
                                ],
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
          );
        },
      ),
    );
  }

  Widget _buildVehicleImage(bool hasDriver) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        child: widget.vehicle.photoUrl != null &&
                widget.vehicle.photoUrl!.isNotEmpty &&
                widget.vehicle.photoUrl != 'netu' &&
                widget.vehicle.photoUrl!.startsWith('http')
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.vehicle.photoUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildVehicleIcon();
                    },
                  ),
                  if (hasDriver)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              )
            : _buildVehicleIcon(),
      ),
    );
  }

  Widget _buildVehicleIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
      ),
      child: Center(
        child: Icon(
          Icons.local_shipping_rounded,
          size: 56,
          color: AppColors.primary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: isHighlighted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
