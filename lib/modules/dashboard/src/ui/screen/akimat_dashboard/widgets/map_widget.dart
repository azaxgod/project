import 'package:flutter/material.dart';

class PolygonData {
  final String name;
  final String contractor;
  final String status;
  final Color color;

  PolygonData({
    required this.name,
    required this.contractor,
    required this.status,
    required this.color,
  });
}

class MapWidget extends StatelessWidget {
  final List<PolygonData> polygons;

  const MapWidget({super.key, required this.polygons});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: polygons.map((polygon) {
          // Для простоты показываем прямоугольники вместо настоящей карты
          return Positioned(
            left: (polygons.indexOf(polygon) * 60).toDouble(),
            top: 20,
            child: Tooltip(
              message:
                  '${polygon.name}\nПодрядчик: ${polygon.contractor}\nСтатус: ${polygon.status}',
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: polygon.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
