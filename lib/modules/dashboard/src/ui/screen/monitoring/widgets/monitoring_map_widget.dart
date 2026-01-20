import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart' as model;
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/driver_marker.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/map_controls_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/vehicle_3d_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class MonitoringMapWidget extends StatefulWidget {
  final List<CleaningArea> areas;
  final List<model.Polygon> polygons;
  final List<Camera> cameras;
  final List<VehicleMonitoring> vehicles;
  final String? selectedAreaId;
  final String? selectedPolygonId;
  final String? selectedVehicleId;
  final VehicleTrack? selectedVehicleTrack;
  final List<List<double>>? drawingGeometry;
  final String? createMode; // Режим создания: 'area', 'polygon', 'camera'
  final Function(String)? onAreaTap;
  final Function(String)? onPolygonTap;
  final Function(String)? onVehicleTap;
  final Function(double lat, double lon)? onMapTap;
  final bool isEditingGeometry; // Режим редактирования
  final Function(int index)? onPointTap; // Обработчик клика на точку (для удаления)
  final bool showAreas;
  final bool showPolygons;
  final bool showCameras;
  final bool showVehicles;
  final VoidCallback? onToggleAreas;
  final VoidCallback? onTogglePolygons;
  final VoidCallback? onToggleCameras;
  final VoidCallback? onToggleVehicles;
  final VoidCallback? onRefresh;
  // Добавляем список подрядчиков для определения цвета участков
  final List<Organization> contractors;

  const MonitoringMapWidget({
    super.key,
    required this.areas,
    required this.polygons,
    required this.cameras,
    required this.vehicles,
    this.selectedAreaId,
    this.selectedPolygonId,
    this.selectedVehicleId,
    this.selectedVehicleTrack,
    this.drawingGeometry,
    this.createMode,
    this.onAreaTap,
    this.onPolygonTap,
    this.onVehicleTap,
    this.onMapTap,
    this.isEditingGeometry = false,
    this.onPointTap,
    this.showAreas = true,
    this.showPolygons = true,
    this.showCameras = true,
    this.showVehicles = true,
    this.onToggleAreas,
    this.onTogglePolygons,
    this.onToggleCameras,
    this.onToggleVehicles,
    this.onRefresh,
    this.contractors = const [],
  });

  @override
  State<MonitoringMapWidget> createState() => _MonitoringMapWidgetState();
}

class _MonitoringMapWidgetState extends State<MonitoringMapWidget> {
  late final MapController _mapController;

  /// Получает цвет подрядчика по ID
  Color _getContractorColor(String? contractorId) {
    if (contractorId == null) return Colors.blue.shade700;

    try {
      widget.contractors.firstWhere((c) => c.id == contractorId);
    } catch (_) {
      return Colors.blue.shade700;
    }
    
    // Генерируем цвет на основе ID подрядчика
    final hash = contractorId.hashCode;
    final hue = (hash.abs() % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Определяем курсор в зависимости от режима рисования
    final isDrawing = widget.drawingGeometry != null && widget.drawingGeometry!.isNotEmpty;
    final cursor = isDrawing ? SystemMouseCursors.precise : SystemMouseCursors.basic;
    final center = const LatLng(54.8667, 69.1500); // Петропавловск

    // Подсчитываем количество объектов
    final vehicleCount = widget.vehicles.where((v) => !v.vehicleId.startsWith('driver_')).length;
    final driverCount = widget.vehicles.where((v) => v.vehicleId.startsWith('driver_')).length;

    return Stack(
      children: [
        MouseRegion(
          cursor: cursor,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
            initialCenter: center,
            initialZoom: 12.0,
            onTap: widget.onMapTap != null
                ? (tapPosition, point) {
                    widget.onMapTap!(point.latitude, point.longitude);
                  }
                : null,
            interactionOptions: InteractionOptions(
              flags: widget.onMapTap != null
                  ? InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.all,
            ),
          ),
          children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.akimat.project',
        ),
               // Участки уборки (отображаем линиями, фильтруем участки с пустой геометрией)
               if (widget.areas.isNotEmpty)
                 PolylineLayer(
                   polylines: widget.areas
                       .where((area) => area.geometry.isNotEmpty && area.geometry.length >= 2)
                       .map((area) {
                         final isSelected = area.id == widget.selectedAreaId;
                         // Получаем цвет подрядчика
                         final contractorColor = _getContractorColor(area.defaultContractorId);
                         
                         // Преобразуем геометрию в точки LatLng
                         final points = area.geometry
                             .map((coord) => LatLng(coord[1], coord[0]))
                             .toList();
                         // Замыкаем полилинию (добавляем первую точку в конец для замкнутого контура)
                         if (points.isNotEmpty && points.first != points.last) {
                           points.add(points.first);
                         }
                         return Polyline(
                           points: points,
                           strokeWidth: isSelected ? 3.0 : 2.0,
                           color: isSelected ? contractorColor : contractorColor.withOpacity(0.8),
                         );
                       }).toList(),
                 ),
               // Полигоны вывоза (фильтруем полигоны с пустой геометрией)
               if (widget.polygons.isNotEmpty)
                 PolygonLayer(
                   polygons: widget.polygons
                       .where((polygon) => polygon.geometry.isNotEmpty && polygon.geometry.length >= 3)
                       .map((polygon) {
                         final isSelected = polygon.id == widget.selectedPolygonId;
                         return Polygon(
                           points: polygon.geometry
                               .map((coord) => LatLng(coord[1], coord[0]))
                               .toList(),
                           color: isSelected
                               ? Colors.orange.withValues(alpha: 0.4)
                               : Colors.orange.withValues(alpha: 0.2),
                           borderColor: isSelected ? Colors.orange : Colors.orange.shade700,
                           borderStrokeWidth: isSelected ? 3 : 2,
                         );
                       }).toList(),
                 ),
               // Камеры
               if (widget.cameras.isNotEmpty)
                 MarkerLayer(
                   markers: widget.cameras.map((camera) {
              if (camera.location == null) return null;
              return Marker(
                point: LatLng(camera.location![1], camera.location![0]),
                width: 30,
                height: 30,
                child: Icon(
                  Icons.videocam,
                  color: camera.isActive ? Colors.purple : Colors.grey,
                  size: 30,
                ),
              );
            }).whereType<Marker>().toList(),
          ),
               // Разделяем транспортные средства и водителей
               if (widget.vehicles.isNotEmpty) ...[
                 // Транспортные средства (не водители)
                 MarkerLayer(
                   markers: widget.vehicles
                       .where((vehicle) => !vehicle.vehicleId.startsWith('driver_'))
                       .map((vehicle) {
                         final isSelected = vehicle.vehicleId == widget.selectedVehicleId;
                         return Marker(
                           point: LatLng(vehicle.lastGps.lat, vehicle.lastGps.lon),
                           width: isSelected ? 90 : 80,
                           height: isSelected ? 90 : 80,
                           alignment: Alignment.center,
                           child: Vehicle3DMarker(
                             vehicle: vehicle,
                             isSelected: isSelected,
                             onTap: () => widget.onVehicleTap?.call(vehicle.vehicleId),
                           ),
                         );
                       }).toList(),
                 ),
                 // Водители с отдельной иконкой
                 MarkerLayer(
                   markers: widget.vehicles
                       .where((vehicle) => vehicle.vehicleId.startsWith('driver_'))
                       .map((vehicle) {
                         final isSelected = vehicle.vehicleId == widget.selectedVehicleId;
                         return Marker(
                           point: LatLng(vehicle.lastGps.lat, vehicle.lastGps.lon),
                           width: isSelected ? 70 : 60,
                           height: isSelected ? 70 : 60,
                           alignment: Alignment.center,
                           child: DriverMarker(
                             driver: vehicle,
                             isSelected: isSelected,
                             onTap: () => widget.onVehicleTap?.call(vehicle.vehicleId),
                           ),
                         );
                       }).toList(),
                 ),
               ],
               // Трек выбранной техники
               if (widget.selectedVehicleTrack != null && widget.selectedVehicleTrack!.points.isNotEmpty)
                 PolylineLayer(
                   polylines: [
                     Polyline(
                       points: widget.selectedVehicleTrack!.points
                    .map((p) => LatLng(p.lat, p.lon))
                    .toList(),
                strokeWidth: 3,
                color: Colors.red,
              ),
            ],
          ),
               // Рисуемая геометрия (только для участков и полигонов, не для камер)
               // Для камеры отображаем только маркер точки (см. ниже)
               if (widget.drawingGeometry != null && 
                   widget.drawingGeometry!.isNotEmpty &&
                   widget.createMode != 'camera' &&
                   widget.drawingGeometry!.length >= 3)
                 PolygonLayer(
                   polygons: [
                     Polygon(
                       points: widget.drawingGeometry!
                           .map((coord) => LatLng(coord[1], coord[0]))
                           .toList(),
                       color: Colors.green.withValues(alpha: 0.3),
                       borderColor: Colors.green,
                       borderStrokeWidth: 3,
                     ),
                   ],
                 ),
               // Маркеры точек рисования
               if (widget.drawingGeometry != null && widget.drawingGeometry!.isNotEmpty)
                 MarkerLayer(
                   markers: widget.drawingGeometry!.asMap().entries.map((entry) {
                     final index = entry.key;
                     final coord = entry.value;
                     final isCamera = widget.createMode == 'camera';
                     return Marker(
                       point: LatLng(coord[1], coord[0]),
                       width: isCamera ? 40 : (widget.isEditingGeometry ? 30 : 20),
                       height: isCamera ? 40 : (widget.isEditingGeometry ? 30 : 20),
                       child: GestureDetector(
                         onTap: widget.isEditingGeometry && widget.onPointTap != null
                             ? () => widget.onPointTap!(index)
                             : null,
                         child: Container(
                           decoration: BoxDecoration(
                             color: isCamera 
                                 ? Colors.blue 
                                 : (widget.isEditingGeometry ? Colors.red : Colors.green),
                             shape: BoxShape.circle,
                             border: Border.all(
                               color: Colors.white,
                               width: widget.isEditingGeometry ? 3 : 2,
                             ),
                             boxShadow: widget.isEditingGeometry || isCamera
                                 ? [
                                     BoxShadow(
                                       color: (isCamera ? Colors.blue : Colors.red).withValues(alpha: 0.5),
                                       blurRadius: 8,
                                       spreadRadius: 2,
                                     ),
                                   ]
                                 : null,
                           ),
                           child: Center(
                             child: isCamera
                                 ? const Icon(
                                     Icons.videocam,
                                     color: Colors.white,
                                     size: 24,
                                   )
                                 : widget.isEditingGeometry
                                     ? const Icon(
                                         Icons.close,
                                         color: Colors.white,
                                         size: 16,
                                       )
                                     : Text(
                                         '${index + 1}',
                                         style: const TextStyle(
                                           color: Colors.white,
                                           fontSize: 10,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                           ),
                         ),
                       ),
                     );
                   }).toList(),
                 ),
      ],
          ),
        ),
        // Плавающие виджеты управления картой
        MapControlsWidget(
          mapController: _mapController,
          showAreas: widget.showAreas,
          showPolygons: widget.showPolygons,
          showCameras: widget.showCameras,
          showVehicles: widget.showVehicles,
          onToggleAreas: widget.onToggleAreas,
          onTogglePolygons: widget.onTogglePolygons,
          onToggleCameras: widget.onToggleCameras,
          onToggleVehicles: widget.onToggleVehicles,
          onRefresh: widget.onRefresh,
          vehicleCount: vehicleCount,
          driverCount: driverCount,
          areaCount: widget.areas.length,
          polygonCount: widget.polygons.length,
        ),
      ],
    );
  }

}

