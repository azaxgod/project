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
    this.polygons, // Список всех полигонов подрядчика
    this.isInArea = false,
    this.isInPolygon = false,
    this.isVehicleInWork = false, // Машина в работе (зеленый цвет на карте)
  });

  final LatLng currentLocation; // Текущая позиция водителя
  final CleaningArea? cleaningArea; // Участок уборки
  final model.Polygon? polygon; // Полигон вывоза (для обратной совместимости)
  final List<model.Polygon>? polygons; // Список всех полигонов подрядчика
  final bool isInArea; // Находится ли водитель в зоне участка
  final bool isInPolygon; // Находится ли водитель в зоне полигона
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
        // Обновляем центр карты при изменении позиции
        onMapReady: () {
          // Карта готова
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.akimat.project',
        ),
        // Участок уборки (отображаем линиями, как у подрядчика)
        if (cleaningArea != null && cleaningArea!.geometry.isNotEmpty && cleaningArea!.geometry.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: () {
                  // Преобразуем геометрию в точки LatLng
                  final points = cleaningArea!.geometry
                      .map((coord) => LatLng(coord[1], coord[0]))
                      .toList();
                  // Замыкаем полилинию (добавляем первую точку в конец для замкнутого контура)
                  if (points.isNotEmpty && points.first != points.last) {
                    points.add(points.first);
                  }
                  return points;
                }(),
                strokeWidth: 2.0,
                color: Colors.blue.shade700,
              ),
            ],
          ),
        // Полигоны вывоза (привязанные к подрядчику)
        // Отображаем все полигоны подрядчика, если передан список, иначе используем один полигон
        if ((polygons != null && polygons!.isNotEmpty) || (polygon != null && polygon!.geometry.isNotEmpty))
          PolygonLayer(
            polygons: () {
              // Если передан список полигонов, используем его
              if (polygons != null && polygons!.isNotEmpty) {
                return polygons!
                    .where((p) => p.geometry.isNotEmpty && p.geometry.length >= 3)
                    .map((p) => Polygon(
                          points: p.geometry
                              .map((coord) => LatLng(coord[1], coord[0]))
                              .toList(),
                          color: Colors.orange.withOpacity(0.3),
                          borderColor: Colors.orange,
                          borderStrokeWidth: 2,
                        ))
                    .toList();
              }
              // Иначе используем один полигон (для обратной совместимости)
              if (polygon != null && polygon!.geometry.isNotEmpty) {
                return [
                  Polygon(
                    points: polygon!.geometry
                        .map((coord) => LatLng(coord[1], coord[0]))
                        .toList(),
                    color: Colors.orange.withOpacity(0.3),
                    borderColor: Colors.orange,
                    borderStrokeWidth: 2,
                  ),
                ];
              }
              return <Polygon>[];
            }(),
          ),
        // Маркер текущей позиции водителя
        // Зелёный цвет = машина в работе (статус IN_PROGRESS после нажатия "Начать рейс")
        // Синий цвет = машина не в работе (статус NOT_STARTED или COMPLETED)
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
                  boxShadow: [
                    BoxShadow(
                      color: (isVehicleInWork ? Colors.green : Colors.blue).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isVehicleInWork ? Icons.local_shipping : Icons.person_pin_circle,
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
        // Логика маршрутов в зависимости от позиции водителя:
        // 1. Если водитель на участке → маршрут до полигона
        // 2. Если водитель на полигоне → маршрут до участка
        // 3. Если вне границ → маршрут до участка
        
        // Сценарий 1: Водитель на участке → маршрут до полигона
        if (cleaningArea != null && polygon != null && isInArea && !isInPolygon)
          PolylineLayer(
            polylines: [
              // Основной маршрут от текущей позиции до полигона (зеленый, толще)
              Polyline(
                points: [
                  currentLocation,
                  LatLng(
                    _calculatePolygonCenter(polygon!.geometry)[1],
                    _calculatePolygonCenter(polygon!.geometry)[0],
                  ),
                ],
                strokeWidth: 5,
                color: Colors.green,
              ),
              // Альтернативные маршруты (серые, тоньше) - 4 варианта
              ...List.generate(4, (index) {
                final offsetLat = (index + 1) * 0.008;
                final offsetLon = (index % 2 == 0 ? 1 : -1) * (index + 1) * 0.008;
                final polygonCenter = _calculatePolygonCenter(polygon!.geometry);
                return Polyline(
                  points: [
                    currentLocation,
                    LatLng(
                      polygonCenter[1] + offsetLat,
                      polygonCenter[0] + offsetLon,
                    ),
                  ],
                  strokeWidth: 2,
                  color: Colors.grey.withOpacity(0.4),
                );
              }),
            ],
          ),

        if (cleaningArea != null && isInPolygon)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  currentLocation,
                  LatLng(
                    _calculatePolygonCenter(cleaningArea!.geometry)[1],
                    _calculatePolygonCenter(cleaningArea!.geometry)[0],
                  ),
                ],
                strokeWidth: 5,
                color: Colors.green,
              ),
              // Альтернативные маршруты (серые, тоньше) - 4 варианта
              ...List.generate(4, (index) {
                final offsetLat = (index + 1) * 0.008;
                final offsetLon = (index % 2 == 0 ? 1 : -1) * (index + 1) * 0.008;
                final areaCenter = _calculatePolygonCenter(cleaningArea!.geometry);
                return Polyline(
                  points: [
                    currentLocation,
                    LatLng(
                      areaCenter[1] + offsetLat,
                      areaCenter[0] + offsetLon,
                    ),
                  ],
                  strokeWidth: 2,
                  color: Colors.grey.withOpacity(0.4),
                );
              }),
            ],
          ),
  
        if (cleaningArea != null && !isInArea && !isInPolygon)
          PolylineLayer(
            polylines: [

              Polyline(
                points: [
                  currentLocation,
                  LatLng(
                    _calculatePolygonCenter(cleaningArea!.geometry)[1],
                    _calculatePolygonCenter(cleaningArea!.geometry)[0],
                  ),
                ],
                strokeWidth: 5,
                color: Colors.green,
              ),

              ...List.generate(4, (index) {
                final offsetLat = (index + 1) * 0.008;
                final offsetLon = (index % 2 == 0 ? 1 : -1) * (index + 1) * 0.008;
                final areaCenter = _calculatePolygonCenter(cleaningArea!.geometry);
                return Polyline(
                  points: [
                    currentLocation,
                    LatLng(
                      areaCenter[1] + offsetLat,
                      areaCenter[0] + offsetLon,
                    ),
                  ],
                  strokeWidth: 2,
                  color: Colors.grey.withOpacity(0.4),
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

