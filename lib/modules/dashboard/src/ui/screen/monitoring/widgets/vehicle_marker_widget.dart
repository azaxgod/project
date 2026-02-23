import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Красивый виджет маркера машины с 3D эффектом и отображением скорости
class VehicleMarkerWidget extends StatelessWidget {
  final VehicleMonitoring vehicle;
  final bool isSelected;
  final VoidCallback? onTap;

  const VehicleMarkerWidget({
    super.key,
    required this.vehicle,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final speed = vehicle.lastGps.speedKmh;
    final heading = vehicle.lastGps.headingDeg;
    final color = _getVehicleColor(vehicle.status);
    
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: heading * math.pi / 180,
        child: Container(
          width: isSelected ? 70 : 60,
          height: isSelected ? 70 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: isSelected ? 15 : 10,
                spreadRadius: isSelected ? 3 : 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3D эффект - градиентный фон
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                      color.withValues(alpha: 0.4),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              // Иконка машины
              Transform.scale(
                scale: isSelected ? 1.2 : 1.0,
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: isSelected ? 35 : 30,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Скорость в км/ч
              Positioned(
                bottom: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed,
                        size: 12,
                        color: _getSpeedColor(speed),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${speed.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getSpeedColor(speed),
                        ),
                      ),
                      Text(
                        ' км/ч',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Индикатор статуса (пульсирующий)
              if (vehicle.status == VehicleStatus.inTrip)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getVehicleColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.inTrip:
        return Colors.green;
      case VehicleStatus.idle:
        return Colors.orange;
      case VehicleStatus.offline:
        return Colors.grey;
    }
  }

  Color _getSpeedColor(double speed) {
    if (speed < 10) {
      return Colors.grey;
    } else if (speed < 30) {
      return Colors.orange;
    } else if (speed < 60) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }
}

