import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart' as model;
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/vehicle_3d_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final Function(String)? onAreaTap;
  final Function(String)? onPolygonTap;
  final Function(String)? onVehicleTap;
  final Function(double lat, double lon)? onMapTap;
  final bool isEditingGeometry; // Режим редактирования
  final Function(int index)? onPointTap; // Обработчик клика на точку (для удаления)

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
    this.onAreaTap,
    this.onPolygonTap,
    this.onVehicleTap,
    this.onMapTap,
    this.isEditingGeometry = false,
    this.onPointTap,
  });

  @override
  State<MonitoringMapWidget> createState() => _MonitoringMapWidgetState();
}

class _MonitoringMapWidgetState extends State<MonitoringMapWidget> {
  late final MapController _mapController;

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

    return MouseRegion(
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
               // Участки уборки
               if (widget.areas.isNotEmpty)
                 PolygonLayer(
                   polygons: widget.areas.map((area) {
                     final isSelected = area.id == widget.selectedAreaId;
              return Polygon(
                points: area.geometry
                    .map((coord) => LatLng(coord[1], coord[0]))
                    .toList(),
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.4)
                    : Colors.blue.withValues(alpha: 0.2),
                borderColor: isSelected ? Colors.blue : Colors.blue.shade700,
                borderStrokeWidth: isSelected ? 3 : 2,
              );
            }).toList(),
          ),
               // Полигоны вывоза
               if (widget.polygons.isNotEmpty)
                 PolygonLayer(
                   polygons: widget.polygons.map((polygon) {
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
               // Техника с красивыми 3D маркерами в стиле 2GIS/Яндекс Такси
               if (widget.vehicles.isNotEmpty)
                 MarkerLayer(
                   markers: widget.vehicles
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
               // Рисуемая геометрия
               if (widget.drawingGeometry != null && widget.drawingGeometry!.isNotEmpty)
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
                     return Marker(
                       point: LatLng(coord[1], coord[0]),
                       width: widget.isEditingGeometry ? 30 : 20,
                       height: widget.isEditingGeometry ? 30 : 20,
                       child: GestureDetector(
                         onTap: widget.isEditingGeometry && widget.onPointTap != null
                             ? () => widget.onPointTap!(index)
                             : null,
                         child: Container(
                           decoration: BoxDecoration(
                             color: widget.isEditingGeometry ? Colors.red : Colors.green,
                             shape: BoxShape.circle,
                             border: Border.all(
                               color: Colors.white,
                               width: widget.isEditingGeometry ? 3 : 2,
                             ),
                             boxShadow: widget.isEditingGeometry
                                 ? [
                                     BoxShadow(
                                       color: Colors.red.withValues(alpha: 0.5),
                                       blurRadius: 8,
                                       spreadRadius: 2,
                                     ),
                                   ]
                                 : null,
                           ),
                           child: Center(
                             child: widget.isEditingGeometry
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
    );
  }

}

