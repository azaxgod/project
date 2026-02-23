import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:flutter/material.dart';

/// Красивая 3D модель машины в стиле 2GIS/Яндекс Такси
class Vehicle3DMarker extends StatefulWidget {
  final VehicleMonitoring vehicle;
  final bool isSelected;
  final VoidCallback? onTap;

  const Vehicle3DMarker({
    super.key,
    required this.vehicle,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<Vehicle3DMarker> createState() => _Vehicle3DMarkerState();
}

class _Vehicle3DMarkerState extends State<Vehicle3DMarker>
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
    final speed = widget.vehicle.lastGps.speedKmh;
    final heading = widget.vehicle.lastGps.headingDeg;
    final color = _getVehicleColor(widget.vehicle.status);
    final isMoving = widget.vehicle.status == VehicleStatus.inTrip && speed > 5;
    final isOffline = widget.vehicle.status == VehicleStatus.offline;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedRotation(
        turns: heading / 360,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: AnimatedScale(
          scale: widget.isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Пульсирующий ореол для движущихся машин
              if (isMoving)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 80 * _pulseAnimation.value,
                      height: 80 * _pulseAnimation.value,
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
              _build3DVehicle(color, speed, isOffline),
              // Скорость в км/ч (только для движущихся машин)
              if (!isOffline)
                Positioned(
                  bottom: -8,
                  child: _buildSpeedBadge(speed),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DVehicle(Color color, double speed, bool isOffline) {
    return Container(
      width: widget.isSelected ? 56 : 48,
      height: widget.isSelected ? 56 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // Основная тень
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: widget.isSelected ? 20 : 15,
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
              // Иконка машины с градиентом
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
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: widget.isSelected ? 32 : 28,
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
              // Индикатор движения (пульсирующая точка) - только для активных машин
              if (widget.vehicle.status == VehicleStatus.inTrip && !isOffline)
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

  Widget _buildSpeedBadge(double speed) {
    final speedColor = _getSpeedColor(speed);
    final speedInt = speed.toInt();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: speedColor.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: speedColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: speedColor,
              boxShadow: [
                BoxShadow(
                  color: speedColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$speedInt',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: speedColor,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            ' км/ч',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getVehicleColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.inTrip:
        return const Color(0xFF34C759); // iOS Green
      case VehicleStatus.idle:
        return const Color(0xFFFF9500); // iOS Orange
      case VehicleStatus.offline:
        return Colors.grey.shade600;
    }
  }

  Color _getSpeedColor(double speed) {
    if (speed < 10) {
      return Colors.grey.shade600;
    } else if (speed < 30) {
      return const Color(0xFFFF9500); // Orange
    } else if (speed < 60) {
      return const Color(0xFF007AFF); // Blue
    } else {
      return const Color(0xFFFF3B30); // Red
    }
  }
}

