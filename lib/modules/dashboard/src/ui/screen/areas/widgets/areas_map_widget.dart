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
  void didUpdateWidget(AreasMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset drawing points when drawing mode is turned off
    if (oldWidget.isDrawingMode && !widget.isDrawingMode) {
      _drawingPoints.clear();
    }
    // Reset drawing points when drawing mode is turned on (start fresh)
    if (!oldWidget.isDrawingMode && widget.isDrawingMode) {
      _drawingPoints.clear();
    }
  }

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
                    // Check if polygon should be closed (clicked on first point)
                    if (_drawingPoints.length >= 3) {
                      final firstPoint = _drawingPoints.first;
                      final distance = Distance();
                      final dist = distance.as(
                        LengthUnit.Meter,
                        firstPoint,
                        point,
                      );
                      // Increased threshold to 100 meters for easier closing
                      if (dist < 100) {
                        // Close polygon if clicked near first point (don't add duplicate point)
                        _closePolygon();
                        return;
                      }
                    }
                    // Add new point
                    _drawingPoints.add(point);
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
        if (widget.existingPolygons != null && widget.existingPolygons!.isNotEmpty)
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
        // Drawing polygon (only show if we have at least 3 points)
        if (widget.isDrawingMode && _drawingPoints.length >= 3)
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
        // Drawing line between points (show progress even with less than 3 points)
        if (widget.isDrawingMode && _drawingPoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _drawingPoints,
                strokeWidth: 2,
                color: Colors.green.withValues(alpha: 0.6),
                borderStrokeWidth: 1,
                borderColor: Colors.green.shade700,
              ),
            ],
          ),
        // Drawing points
        if (widget.isDrawingMode && _drawingPoints.isNotEmpty)
          MarkerLayer(
            markers: _drawingPoints.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              final isFirst = index == 0;
              return Marker(
                point: point,
                width: isFirst && _drawingPoints.length >= 3 ? 16 : 12,
                height: isFirst && _drawingPoints.length >= 3 ? 16 : 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: isFirst && _drawingPoints.length >= 3 
                        ? Colors.orange 
                        : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: isFirst && _drawingPoints.length >= 3
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        // Selected polygon
        if (widget.polygonGeometry != null && 
            widget.polygonGeometry!.isNotEmpty && 
            !widget.isDrawingMode)
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

