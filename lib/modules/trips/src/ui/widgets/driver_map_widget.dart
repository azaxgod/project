import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart' as model;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class DriverMapWidget extends StatelessWidget {
  const DriverMapWidget({
    super.key,
    required this.currentLocation,
    this.cleaningArea,
    this.polygon,
    this.isInArea = false,
    this.isVehicleInWork = false, // Машина в работе (зеленый цвет на карте)
  });

  final LatLng currentLocation; // Текущая позиция водителя
  final CleaningArea? cleaningArea; // Участок уборки
  final model.Polygon? polygon; // Полигон вывоза
  final bool isInArea; // Находится ли водитель в зоне участка
  final bool isVehicleInWork; // Машина в работе (зеленый цвет на карте)

  @override
  Widget build(BuildContext context) {
    // Определяем центр карты
    LatLng mapCenter = currentLocation;
    if (cleaningArea != null && cleaningArea!.geometry.isNotEmpty) {
      // Используем центр участка, если он есть
      final center = _calculatePolygonCenter(cleaningArea!.geometry);
      mapCenter = LatLng(center[1], center[0]);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: 13.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.akimat.project',
        ),
        // Участок уборки
        if (cleaningArea != null && cleaningArea!.geometry.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: cleaningArea!.geometry
                    .map((coord) => LatLng(coord[1], coord[0]))
                    .toList(),
                color: Colors.blue.withOpacity(0.3),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        // Полигон вывоза
        if (polygon != null && polygon!.geometry.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: polygon!.geometry
                    .map((coord) => LatLng(coord[1], coord[0]))
                    .toList(),
                color: Colors.orange.withOpacity(0.3),
                borderColor: Colors.orange,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        // Маркер текущей позиции водителя (зеленый, если машина в работе)
        MarkerLayer(
          markers: [
            Marker(
              point: currentLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: isVehicleInWork ? Colors.green : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        // Маркер центра участка (если водитель вне зоны)
        if (cleaningArea != null && !isInArea)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  _calculatePolygonCenter(cleaningArea!.geometry)[1],
                  _calculatePolygonCenter(cleaningArea!.geometry)[0],
                ),
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ],
          ),
        // Маркер полигона (если водитель в зоне участка)
        if (polygon != null && isInArea)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  _calculatePolygonCenter(polygon!.geometry)[1],
                  _calculatePolygonCenter(polygon!.geometry)[0],
                ),
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ],
          ),
        // Маршруты (упрощенная версия - прямые линии)
        // TODO: Интегрировать с API построения маршрутов (OSRM, OpenRouteService)
        if (cleaningArea != null && !isInArea)
          PolylineLayer(
            polylines: [
              // Основной маршрут до участка (зеленый)
              Polyline(
                points: [
                  currentLocation,
                  LatLng(
                    _calculatePolygonCenter(cleaningArea!.geometry)[1],
                    _calculatePolygonCenter(cleaningArea!.geometry)[0],
                  ),
                ],
                strokeWidth: 4,
                color: Colors.green,
              ),
              // Альтернативные маршруты (серые) - упрощенная версия
              // В реальности нужно использовать API построения маршрутов
              ...List.generate(4, (index) {
                final offset = (index + 1) * 0.01;
                return Polyline(
                  points: [
                    currentLocation,
                    LatLng(
                      _calculatePolygonCenter(cleaningArea!.geometry)[1] + offset,
                      _calculatePolygonCenter(cleaningArea!.geometry)[0] + offset,
                    ),
                  ],
                  strokeWidth: 2,
                  color: Colors.grey.withOpacity(0.5),
                );
              }),
            ],
          ),
        // Маршруты от участка до полигона (если водитель в зоне участка)
        if (cleaningArea != null && polygon != null && isInArea)
          PolylineLayer(
            polylines: [
              // Основной маршрут от участка до полигона (зеленый)
              Polyline(
                points: [
                  LatLng(
                    _calculatePolygonCenter(cleaningArea!.geometry)[1],
                    _calculatePolygonCenter(cleaningArea!.geometry)[0],
                  ),
                  LatLng(
                    _calculatePolygonCenter(polygon!.geometry)[1],
                    _calculatePolygonCenter(polygon!.geometry)[0],
                  ),
                ],
                strokeWidth: 4,
                color: Colors.green,
              ),
              // Альтернативные маршруты (серые)
              ...List.generate(4, (index) {
                final offset = (index + 1) * 0.01;
                return Polyline(
                  points: [
                    LatLng(
                      _calculatePolygonCenter(cleaningArea!.geometry)[1] + offset,
                      _calculatePolygonCenter(cleaningArea!.geometry)[0] + offset,
                    ),
                    LatLng(
                      _calculatePolygonCenter(polygon!.geometry)[1] + offset,
                      _calculatePolygonCenter(polygon!.geometry)[0] + offset,
                    ),
                  ],
                  strokeWidth: 2,
                  color: Colors.grey.withOpacity(0.5),
                );
              }),
            ],
          ),
      ],
    );
  }

  /// Вычисляет центр полигона (центроид)
  List<double> _calculatePolygonCenter(List<List<double>> geometry) {
    if (geometry.isEmpty) return [69.15, 54.87]; // Центр Петропавловска по умолчанию

    double sumLat = 0;
    double sumLon = 0;
    for (final coord in geometry) {
      sumLon += coord[0]; // longitude
      sumLat += coord[1]; // latitude
    }
    return [sumLon / geometry.length, sumLat / geometry.length];
  }
}

