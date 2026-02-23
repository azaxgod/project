import 'dart:math' as math;

import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart'
    as model;
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/driver_marker.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/map_controls_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/vehicle_3d_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  final String? createMode; // 'area', 'polygon', 'camera'
  final Function(String)? onAreaTap;
  final Function(String)? onPolygonTap;
  final Function(String)? onVehicleTap;
  final Function(double lat, double lon)? onMapTap;
  final bool isEditingGeometry;
  final Function(int index)? onPointTap;
  final bool showAreas;
  final bool showPolygons;
  final bool showCameras;
  final bool showVehicles;
  final VoidCallback? onToggleAreas;
  final VoidCallback? onTogglePolygons;
  final VoidCallback? onToggleCameras;
  final VoidCallback? onToggleVehicles;
  final VoidCallback? onRefresh;

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
  });

  @override
  State<MonitoringMapWidget> createState() => _MonitoringMapWidgetState();
}

enum _MapLabelSize { dot, compact, regular }

class _MonitoringMapWidgetState extends State<MonitoringMapWidget> {
  static const LatLng _defaultCenter = LatLng(54.8667, 69.1500);
  static const List<Color> _areaPalette = [
    Color(0xFF0D9488),
    Color(0xFF0284C7),
    Color(0xFF16A34A),
    Color(0xFF0EA5E9),
    Color(0xFF4F46E5),
    Color(0xFF0891B2),
  ];
  static const List<Color> _polygonPalette = [
    Color.fromARGB(255, 237, 129, 7),
  ];

  late final MapController _mapController;
  late final LayerHitNotifier<String> _areaHitNotifier;
  late final LayerHitNotifier<String> _polygonHitNotifier;
  String? _lastAreaFillHitId;
  DateTime? _lastAreaFillHitAt;
  String? _lastPolygonFillHitId;
  DateTime? _lastPolygonFillHitAt;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _areaHitNotifier = ValueNotifier<LayerHitResult<String>?>(null);
    _polygonHitNotifier = ValueNotifier<LayerHitResult<String>?>(null);
    _areaHitNotifier.addListener(_onAreaFillHit);
    _polygonHitNotifier.addListener(_onPolygonFillHit);
  }

  @override
  void dispose() {
    _areaHitNotifier.removeListener(_onAreaFillHit);
    _polygonHitNotifier.removeListener(_onPolygonFillHit);
    _areaHitNotifier.dispose();
    _polygonHitNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MonitoringMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedVehicleId != oldWidget.selectedVehicleId &&
        widget.selectedVehicleId != null) {
      final vehicle = _findVehicleById(widget.selectedVehicleId!);
      if (vehicle != null) {
        _focusVehicle(vehicle);
      }
      return;
    }

    if (widget.selectedPolygonId != oldWidget.selectedPolygonId &&
        widget.selectedPolygonId != null) {
      final polygon = _findPolygonById(widget.selectedPolygonId!);
      if (polygon != null) {
        _focusGeometry(polygon.geometry);
      }
      return;
    }

    if (widget.selectedAreaId != oldWidget.selectedAreaId &&
        widget.selectedAreaId != null) {
      final area = _findAreaById(widget.selectedAreaId!);
      if (area != null) {
        _focusGeometry(area.geometry);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDrawing =
        widget.drawingGeometry != null && widget.drawingGeometry!.isNotEmpty;
    final cursor =
        isDrawing ? SystemMouseCursors.precise : SystemMouseCursors.basic;

    final vehicleCount =
        widget.vehicles.where((v) => !v.vehicleId.startsWith('driver_')).length;
    final driverCount =
        widget.vehicles.where((v) => v.vehicleId.startsWith('driver_')).length;

    final visibleAreas = widget.areas
        .where((area) => _hasValidGeometry(area.geometry, minPoints: 3))
        .toList();
    final visiblePolygons = widget.polygons
        .where((polygon) => _hasValidGeometry(polygon.geometry, minPoints: 3))
        .toList();

    return Stack(
      children: [
        MouseRegion(
          cursor: cursor,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
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
              if (visibleAreas.isNotEmpty)
                PolylineLayer(
                  polylines: visibleAreas.map((area) {
                    final isSelected = area.id == widget.selectedAreaId;
                    final borderColor = _areaBorderColor(area, isSelected);
                    return Polyline(
                      points: _geometryToPoints(area.geometry, closeRing: true),
                      strokeWidth: isSelected ? 8.0 : 6.0,
                      color: borderColor.withValues(
                          alpha: isSelected ? 0.28 : 0.16),
                    );
                  }).toList(),
                ),
              if (visibleAreas.isNotEmpty)
                PolygonLayer<String>(
                  hitNotifier:
                      widget.onMapTap == null ? _areaHitNotifier : null,
                  polygons: visibleAreas.map((area) {
                    final isSelected = area.id == widget.selectedAreaId;
                    return Polygon<String>(
                      points: _geometryToPoints(area.geometry),
                      color: _areaFillColor(area, isSelected),
                      borderColor: _areaBorderColor(area, isSelected),
                      borderStrokeWidth: isSelected ? 3.6 : 2.4,
                      hitValue: area.id,
                    );
                  }).toList(),
                ),
              if (visiblePolygons.isNotEmpty)
                PolylineLayer(
                  polylines: visiblePolygons.map((polygon) {
                    final isSelected = polygon.id == widget.selectedPolygonId;
                    final borderColor =
                        _polygonBorderColor(polygon, isSelected);
                    return Polyline(
                      points:
                          _geometryToPoints(polygon.geometry, closeRing: true),
                      strokeWidth: isSelected ? 8.5 : 6.5,
                      color: borderColor.withValues(
                          alpha: isSelected ? 0.3 : 0.17),
                    );
                  }).toList(),
                ),
              if (visiblePolygons.isNotEmpty)
                PolygonLayer<String>(
                  hitNotifier:
                      widget.onMapTap == null ? _polygonHitNotifier : null,
                  polygons: visiblePolygons.map((polygon) {
                    final isSelected = polygon.id == widget.selectedPolygonId;
                    return Polygon<String>(
                      points: _geometryToPoints(polygon.geometry),
                      color: _polygonFillColor(polygon, isSelected),
                      borderColor: _polygonBorderColor(polygon, isSelected),
                      borderStrokeWidth: isSelected ? 3.4 : 2.2,
                      hitValue: polygon.id,
                    );
                  }).toList(),
                ),
              if (visibleAreas.isNotEmpty)
                MarkerLayer(
                  markers: visibleAreas.map((area) {
                    final points = _geometryToPoints(area.geometry);
                    final isSelected = area.id == widget.selectedAreaId;
                    final accentColor = _areaBorderColor(area, isSelected);
                    final labelSize = isSelected
                        ? _expandedLabelSize(
                            _labelSizeForGeometry(area.geometry),
                          )
                        : _MapLabelSize.dot;
                    return Marker(
                      point: _calculateCentroid(points),
                      width: _labelWidth(labelSize, isSelected),
                      height: _labelHeight(labelSize),
                      alignment: Alignment.center,
                      child: _buildMapLabel(
                        icon: Icons.route_rounded,
                        accentColor: accentColor,
                        title: area.name,
                        subtitle: 'Участок',
                        isSelected: isSelected,
                        labelSize: labelSize,
                        onTap: () => _handleAreaTap(area),
                      ),
                    );
                  }).toList(),
                ),
              if (visiblePolygons.isNotEmpty)
                MarkerLayer(
                  markers: visiblePolygons.map((polygon) {
                    final points = _geometryToPoints(polygon.geometry);
                    final isSelected = polygon.id == widget.selectedPolygonId;
                    final accentColor =
                        _polygonBorderColor(polygon, isSelected);
                    final labelSize = isSelected
                        ? _expandedLabelSize(
                            _labelSizeForGeometry(polygon.geometry),
                          )
                        : _MapLabelSize.dot;
                    return Marker(
                      point: _calculateCentroid(points),
                      width: _labelWidth(labelSize, isSelected),
                      height: _labelHeight(labelSize),
                      alignment: Alignment.center,
                      child: _buildMapLabel(
                        icon: Icons.landscape_rounded,
                        accentColor: accentColor,
                        title: polygon.name,
                        subtitle: 'Полигон',
                        isSelected: isSelected,
                        labelSize: labelSize,
                        onTap: () => _handlePolygonTap(polygon),
                      ),
                    );
                  }).toList(),
                ),
              if (widget.cameras.isNotEmpty)
                MarkerLayer(
                  markers: widget.cameras
                      .map((camera) {
                        if (camera.location == null ||
                            camera.location!.length < 2) {
                          return null;
                        }
                        return Marker(
                          point:
                              LatLng(camera.location![1], camera.location![0]),
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.videocam,
                            color:
                                camera.isActive ? Colors.purple : Colors.grey,
                            size: 30,
                          ),
                        );
                      })
                      .whereType<Marker>()
                      .toList(),
                ),
              if (widget.vehicles.isNotEmpty) ...[
                MarkerLayer(
                  markers: widget.vehicles
                      .where(
                          (vehicle) => !vehicle.vehicleId.startsWith('driver_'))
                      .map((vehicle) {
                    final isSelected =
                        vehicle.vehicleId == widget.selectedVehicleId;
                    return Marker(
                      point: LatLng(vehicle.lastGps.lat, vehicle.lastGps.lon),
                      width: isSelected ? 90 : 80,
                      height: isSelected ? 90 : 80,
                      alignment: Alignment.center,
                      child: Vehicle3DMarker(
                        vehicle: vehicle,
                        isSelected: isSelected,
                        onTap: () => _handleVehicleTap(vehicle),
                      ),
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: widget.vehicles
                      .where(
                          (vehicle) => vehicle.vehicleId.startsWith('driver_'))
                      .map((vehicle) {
                    final isSelected =
                        vehicle.vehicleId == widget.selectedVehicleId;
                    return Marker(
                      point: LatLng(vehicle.lastGps.lat, vehicle.lastGps.lon),
                      width: isSelected ? 70 : 60,
                      height: isSelected ? 70 : 60,
                      alignment: Alignment.center,
                      child: DriverMarker(
                        driver: vehicle,
                        isSelected: isSelected,
                        onTap: () => _handleVehicleTap(vehicle),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (widget.selectedVehicleTrack != null &&
                  widget.selectedVehicleTrack!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.selectedVehicleTrack!.points
                          .map((p) => LatLng(p.lat, p.lon))
                          .toList(),
                      strokeWidth: 7.5,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                    Polyline(
                      points: widget.selectedVehicleTrack!.points
                          .map((p) => LatLng(p.lat, p.lon))
                          .toList(),
                      strokeWidth: 3.4,
                      color: Colors.red.shade600,
                    ),
                  ],
                ),
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
                      color: AppColors.success.withValues(alpha: 0.25),
                      borderColor: AppColors.success,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              if (widget.drawingGeometry != null &&
                  widget.drawingGeometry!.isNotEmpty)
                MarkerLayer(
                  markers: widget.drawingGeometry!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final coord = entry.value;
                    final isCamera = widget.createMode == 'camera';
                    return Marker(
                      point: LatLng(coord[1], coord[0]),
                      width:
                          isCamera ? 40 : (widget.isEditingGeometry ? 30 : 20),
                      height:
                          isCamera ? 40 : (widget.isEditingGeometry ? 30 : 20),
                      child: GestureDetector(
                        onTap: widget.isEditingGeometry &&
                                widget.onPointTap != null
                            ? () => widget.onPointTap!(index)
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCamera
                                ? Colors.blue
                                : (widget.isEditingGeometry
                                    ? Colors.red
                                    : Colors.green),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: widget.isEditingGeometry ? 3 : 2,
                            ),
                            boxShadow: widget.isEditingGeometry || isCamera
                                ? [
                                    BoxShadow(
                                      color:
                                          (isCamera ? Colors.blue : Colors.red)
                                              .withValues(alpha: 0.5),
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

  Widget _buildMapLabel({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required _MapLabelSize labelSize,
    required VoidCallback onTap,
  }) {
    final textColor = AppColors.textPrimary;
    final isDot = labelSize == _MapLabelSize.dot;
    final isCompact = labelSize == _MapLabelSize.compact;

    if (isDot) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isSelected ? 16 : 12,
                height: isSelected ? 16 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      accentColor.withValues(alpha: isSelected ? 0.96 : 0.88),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.96),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: isSelected ? 0.45 : 0.3,
                      ),
                      blurRadius: isSelected ? 10 : 7,
                      spreadRadius: isSelected ? 1.0 : 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isSelected ? 0.98 : 0.9),
                  accentColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: isSelected ? 0.72 : 0.38),
                width: isSelected ? 1.7 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isSelected ? 0.14 : 0.09),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.34),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 11,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: isCompact ? 10.8 : 11.6,
                        ),
                      ),
                      if (!isCompact)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                            fontSize: 8.9,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: accentColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasValidGeometry(List<List<double>> geometry,
      {required int minPoints}) {
    if (geometry.length < minPoints) {
      return false;
    }

    for (final coord in geometry) {
      if (coord.length < 2) {
        return false;
      }

      final lon = coord[0];
      final lat = coord[1];
      if (!lon.isFinite || !lat.isFinite || lon.abs() > 180 || lat.abs() > 90) {
        return false;
      }
    }

    return true;
  }

  List<LatLng> _geometryToPoints(
    List<List<double>> geometry, {
    bool closeRing = false,
  }) {
    final points = geometry
        .where((coord) => coord.length >= 2)
        .map((coord) => LatLng(coord[1], coord[0]))
        .toList();

    if (closeRing && points.length > 2 && points.first != points.last) {
      points.add(points.first);
    }
    return points;
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) {
      return _defaultCenter;
    }

    double signedArea = 0;
    double centroidX = 0;
    double centroidY = 0;

    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final a =
          current.longitude * next.latitude - next.longitude * current.latitude;
      signedArea += a;
      centroidX += (current.longitude + next.longitude) * a;
      centroidY += (current.latitude + next.latitude) * a;
    }

    if (signedArea.abs() < 1e-7) {
      final avgLat =
          points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final avgLon = points.map((p) => p.longitude).reduce((a, b) => a + b) /
          points.length;
      return LatLng(avgLat, avgLon);
    }

    signedArea *= 0.5;
    final factor = 1 / (6 * signedArea);
    centroidX *= factor;
    centroidY *= factor;

    return LatLng(centroidY, centroidX);
  }

  Color _areaBorderColor(CleaningArea area, bool isSelected) {
    final isActiveArea =
        area.isActive && area.status == CleaningAreaStatus.active;

    if (!isActiveArea) {
      return isSelected ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    }

    final baseColor = _colorFromId(area.id, _areaPalette);
    return isSelected
        ? _shadeColor(baseColor, saturationShift: 0.06, lightnessShift: -0.12)
        : baseColor;
  }

  Color _areaFillColor(CleaningArea area, bool isSelected) {
    final isActiveArea =
        area.isActive && area.status == CleaningAreaStatus.active;

    if (!isActiveArea) {
      return const Color(0xFF94A3B8)
          .withValues(alpha: isSelected ? 0.18 : 0.09);
    }

    final baseColor = _colorFromId(area.id, _areaPalette);
    return baseColor.withValues(alpha: isSelected ? 0.25 : 0.14);
  }

  Color _polygonBorderColor(model.Polygon polygon, bool isSelected) {
    if (!polygon.isActive) {
      return isSelected ? const Color(0xFF78716C) : const Color(0xFFA8A29E);
    }

    final baseColor = _colorFromId(polygon.id, _polygonPalette);
    return isSelected
        ? _shadeColor(baseColor, saturationShift: 0.06, lightnessShift: -0.11)
        : baseColor;
  }

  Color _polygonFillColor(model.Polygon polygon, bool isSelected) {
    if (!polygon.isActive) {
      return const Color(0xFFA8A29E).withValues(alpha: isSelected ? 0.2 : 0.11);
    }

    final baseColor = _colorFromId(polygon.id, _polygonPalette);
    return baseColor.withValues(alpha: isSelected ? 0.3 : 0.18);
  }

  Color _colorFromId(String id, List<Color> palette) {
    if (palette.isEmpty) {
      return const Color(0xFF64748B);
    }
    return palette[_stableHash(id) % palette.length];
  }

  int _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  Color _shadeColor(
    Color color, {
    required double saturationShift,
    required double lightnessShift,
  }) {
    final hsl = HSLColor.fromColor(color);
    final adjustedSaturation =
        (hsl.saturation + saturationShift).clamp(0.0, 1.0).toDouble();
    final adjustedLightness =
        (hsl.lightness + lightnessShift).clamp(0.0, 1.0).toDouble();

    return hsl
        .withSaturation(adjustedSaturation)
        .withLightness(adjustedLightness)
        .toColor();
  }

  void _onAreaFillHit() {
    final hit = _areaHitNotifier.value;
    if (hit == null || hit.hitValues.isEmpty || widget.onMapTap != null) {
      return;
    }

    final areaId = hit.hitValues.first;
    if (_isDuplicateAreaFillHit(areaId)) {
      return;
    }

    final area = _findAreaById(areaId);
    if (area != null) {
      _handleAreaTap(area);
    }
  }

  void _onPolygonFillHit() {
    final hit = _polygonHitNotifier.value;
    if (hit == null || hit.hitValues.isEmpty || widget.onMapTap != null) {
      return;
    }

    final polygonId = hit.hitValues.first;
    if (_isDuplicatePolygonFillHit(polygonId)) {
      return;
    }

    final polygon = _findPolygonById(polygonId);
    if (polygon != null) {
      _handlePolygonTap(polygon);
    }
  }

  bool _isDuplicateAreaFillHit(String areaId) {
    final now = DateTime.now();
    final isDuplicate = _lastAreaFillHitId == areaId &&
        _lastAreaFillHitAt != null &&
        now.difference(_lastAreaFillHitAt!) < const Duration(milliseconds: 250);

    _lastAreaFillHitId = areaId;
    _lastAreaFillHitAt = now;
    return isDuplicate;
  }

  bool _isDuplicatePolygonFillHit(String polygonId) {
    final now = DateTime.now();
    final isDuplicate = _lastPolygonFillHitId == polygonId &&
        _lastPolygonFillHitAt != null &&
        now.difference(_lastPolygonFillHitAt!) <
            const Duration(milliseconds: 250);

    _lastPolygonFillHitId = polygonId;
    _lastPolygonFillHitAt = now;
    return isDuplicate;
  }

  void _handleAreaTap(CleaningArea area) {
    _focusGeometry(area.geometry);
    widget.onAreaTap?.call(area.id);
  }

  void _handlePolygonTap(model.Polygon polygon) {
    _focusGeometry(polygon.geometry);
    widget.onPolygonTap?.call(polygon.id);
  }

  void _handleVehicleTap(VehicleMonitoring vehicle) {
    _focusVehicle(vehicle);
    widget.onVehicleTap?.call(vehicle.vehicleId);
  }

  CleaningArea? _findAreaById(String id) {
    for (final area in widget.areas) {
      if (area.id == id) {
        return area;
      }
    }
    return null;
  }

  model.Polygon? _findPolygonById(String id) {
    for (final polygon in widget.polygons) {
      if (polygon.id == id) {
        return polygon;
      }
    }
    return null;
  }

  VehicleMonitoring? _findVehicleById(String id) {
    for (final vehicle in widget.vehicles) {
      if (vehicle.vehicleId == id) {
        return vehicle;
      }
    }
    return null;
  }

  void _focusVehicle(VehicleMonitoring vehicle) {
    _moveCamera(
      LatLng(vehicle.lastGps.lat, vehicle.lastGps.lon),
      16.0,
    );
  }

  void _focusGeometry(List<List<double>> geometry) {
    if (!_hasValidGeometry(geometry, minPoints: 3)) {
      return;
    }

    final points = _geometryToPoints(geometry);
    if (points.isEmpty) {
      return;
    }

    final center = _calculateCentroid(points);
    final targetZoom = _zoomForGeometry(geometry);
    _moveCamera(center, targetZoom);
  }

  void _moveCamera(LatLng center, double zoom) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      try {
        _mapController.move(center, zoom.clamp(3.0, 18.0).toDouble());
      } catch (_) {
        // ignore if map is not attached yet
      }
    });
  }

  double _zoomForGeometry(List<List<double>> geometry) {
    if (geometry.isEmpty) {
      return 15.0;
    }

    double minLon = double.infinity;
    double maxLon = -double.infinity;
    double minLat = double.infinity;
    double maxLat = -double.infinity;

    for (final coord in geometry) {
      if (coord.length < 2) {
        continue;
      }
      final lon = coord[0];
      final lat = coord[1];
      minLon = math.min(minLon, lon);
      maxLon = math.max(maxLon, lon);
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
    }

    if (!minLon.isFinite ||
        !maxLon.isFinite ||
        !minLat.isFinite ||
        !maxLat.isFinite) {
      return 15.0;
    }

    final span = math.max(maxLon - minLon, maxLat - minLat);
    if (span <= 0.0) {
      return 15.5;
    }

    final zoom = math.log(360 / (span * 2.2)) / math.ln2;
    return zoom.clamp(11.0, 17.0).toDouble();
  }

  _MapLabelSize _labelSizeForGeometry(List<List<double>> geometry) {
    if (geometry.length < 3) {
      return _MapLabelSize.compact;
    }

    double minLon = double.infinity;
    double maxLon = -double.infinity;
    double minLat = double.infinity;
    double maxLat = -double.infinity;

    for (final coord in geometry) {
      if (coord.length < 2) {
        continue;
      }
      final lon = coord[0];
      final lat = coord[1];
      minLon = math.min(minLon, lon);
      maxLon = math.max(maxLon, lon);
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
    }

    if (!minLon.isFinite ||
        !maxLon.isFinite ||
        !minLat.isFinite ||
        !maxLat.isFinite) {
      return _MapLabelSize.compact;
    }

    final maxSpan = math.max(maxLon - minLon, maxLat - minLat);

    if (maxSpan < 0.00075) {
      return _MapLabelSize.dot;
    }
    if (maxSpan < 0.0022) {
      return _MapLabelSize.compact;
    }
    return _MapLabelSize.regular;
  }

  _MapLabelSize _expandedLabelSize(_MapLabelSize baseSize) {
    if (baseSize == _MapLabelSize.dot) {
      return _MapLabelSize.compact;
    }
    return baseSize;
  }

  double _labelWidth(_MapLabelSize size, bool isSelected) {
    switch (size) {
      case _MapLabelSize.dot:
        return isSelected ? 24 : 20;
      case _MapLabelSize.compact:
        return isSelected ? 162 : 146;
      case _MapLabelSize.regular:
        return isSelected ? 212 : 188;
    }
  }

  double _labelHeight(_MapLabelSize size) {
    switch (size) {
      case _MapLabelSize.dot:
        return 20;
      case _MapLabelSize.compact:
        return 34;
      case _MapLabelSize.regular:
        return 44;
    }
  }
}
