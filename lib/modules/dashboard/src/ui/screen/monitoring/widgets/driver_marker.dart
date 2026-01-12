import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:flutter/material.dart';

/// Маркер для отображения локации водителя на карте
class DriverMarker extends StatefulWidget {
  final VehicleMonitoring driver;
  final bool isSelected;
  final VoidCallback? onTap;

  const DriverMarker({
    super.key,
    required this.driver,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<DriverMarker> createState() => _DriverMarkerState();
}

class _DriverMarkerState extends State<DriverMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDriverColor(widget.driver.status);
    final isOffline = widget.driver.status == VehicleStatus.offline;
    final isActive = widget.driver.status == VehicleStatus.inTrip;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Пульсирующий ореол для активных водителей
            if (isActive)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 70 * _pulseAnimation.value,
                    height: 70 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.3 * _pulseAnimation.value),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            // Основной контейнер с 3D эффектом
            _build3DDriver(color, isOffline),
          ],
        ),
      ),
    );
  }

  Widget _build3DDriver(Color color, bool isOffline) {
    return Container(
      width: widget.isSelected ? 52 : 44,
      height: widget.isSelected ? 52 : 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // Основная тень
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: widget.isSelected ? 18 : 15,
            spreadRadius: widget.isSelected ? 4 : 3,
          ),
          // Глубокая тень для 3D эффекта
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          // Внутренняя тень для объема
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.6),
                color.withValues(alpha: 0.4),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Блик для 3D эффекта
              Positioned(
                top: 8,
                left: 12,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Иконка человека/пешехода
              Opacity(
                opacity: isOffline ? 0.5 : 1.0,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.7),
                    ],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: widget.isSelected ? 28 : 24,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // Индикатор активности (пульсирующая точка) - только для активных водителей
              if (widget.driver.status == VehicleStatus.inTrip && !isOffline)
                Positioned(
                  top: 4,
                  right: 4,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 10 * _pulseAnimation.value,
                        height: 10 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.8 * _pulseAnimation.value),
                              blurRadius: 8 * _pulseAnimation.value,
                              spreadRadius: 2 * _pulseAnimation.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              // Индикатор OFFLINE (серый крестик)
              if (isOffline)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade700,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDriverColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.inTrip:
        return const Color(0xFF007AFF); // iOS Blue для активных водителей
      case VehicleStatus.idle:
        return const Color(0xFFFF9500); // iOS Orange
      case VehicleStatus.offline:
        return Colors.grey.shade600;
    }
  }
}


