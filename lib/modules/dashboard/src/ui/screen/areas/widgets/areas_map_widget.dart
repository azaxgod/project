import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class AreasMapWidget extends StatefulWidget {
  final List<List<double>>? polygonGeometry;
  final List<List<List<double>>>? existingPolygons;
  final bool isDrawingMode;
  final Function(List<List<double>>)? onPolygonComplete;
  final Function(LatLng)? onMapTap;
  final LatLng? center;
  final double? zoom;

  const AreasMapWidget({
    super.key,
    this.polygonGeometry,
    this.existingPolygons,
    this.isDrawingMode = false,
    this.onPolygonComplete,
    this.onMapTap,
    this.center,
    this.zoom,
  });

  @override
  State<AreasMapWidget> createState() => _AreasMapWidgetState();
}

class _AreasMapWidgetState extends State<AreasMapWidget> {
  final MapController _mapController = MapController();
  List<LatLng> _drawingPoints = [];

  @override
  Widget build(BuildContext context) {
    final center = widget.center ?? const LatLng(54.8667, 69.1500); // Петропавловск
    final zoom = widget.zoom ?? 12.0;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: widget.isDrawingMode
            ? (tapPosition, point) {
                if (widget.isDrawingMode) {
                  setState(() {
                    _drawingPoints.add(point);
                    // Check if polygon is closed (clicked on first point)
                    if (_drawingPoints.length >= 3) {
                      final firstPoint = _drawingPoints.first;
                      final distance = Distance();
                      final dist = distance.as(
                        LengthUnit.Meter,
                        firstPoint,
                        point,
                      );
                      if (dist < 50) {
                        // Close polygon if clicked near first point
                        _closePolygon();
                      }
                    }
                  });
                }
                widget.onMapTap?.call(point);
              }
            : (tapPosition, point) => widget.onMapTap?.call(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.akimat.project',
        ),
        // Existing polygons
        if (widget.existingPolygons != null)
          PolygonLayer(
            polygons: widget.existingPolygons!.map((polygon) {
              return Polygon(
                points: polygon.map((coord) => LatLng(coord[1], coord[0])).toList(),
                color: Colors.blue.withValues(alpha: 0.3),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              );
            }).toList(),
          ),
        // Drawing polygon
        if (widget.isDrawingMode && _drawingPoints.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _drawingPoints,
                color: Colors.green.withValues(alpha: 0.3),
                borderColor: Colors.green,
                borderStrokeWidth: 3,
              ),
            ],
          ),
        // Drawing points
        if (widget.isDrawingMode && _drawingPoints.isNotEmpty)
          MarkerLayer(
            markers: _drawingPoints.map((point) {
              return Marker(
                point: point,
                width: 12,
                height: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            }).toList(),
          ),
        // Selected polygon
        if (widget.polygonGeometry != null && !widget.isDrawingMode)
          PolygonLayer(
            polygons: [
              Polygon(
                points: widget.polygonGeometry!
                    .map((coord) => LatLng(coord[1], coord[0]))
                    .toList(),
                color: Colors.orange.withValues(alpha: 0.3),
                borderColor: Colors.orange,
                borderStrokeWidth: 3,
              ),
            ],
          ),
      ],
    );
  }

  void _closePolygon() {
    if (_drawingPoints.length >= 3) {
      final geometry = _drawingPoints
          .map((point) => [point.longitude, point.latitude])
          .toList();
      widget.onPolygonComplete?.call(geometry);
      setState(() {
        _drawingPoints.clear();
      });
    }
  }

  void resetDrawing() {
    setState(() {
      _drawingPoints.clear();
    });
  }
}

