import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/services/operations/model/camera_dto.dart';
import 'package:akimat_project/services/operations/model/polygon_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'camera_polygon_dto.g.dart';

@JsonSerializable()
class CameraPolygonDto {
  final CameraDto camera;
  final PolygonDto polygon;

  CameraPolygonDto({
    required this.camera,
    required this.polygon,
  });

  factory CameraPolygonDto.fromJson(Map<String, dynamic> json) =>
      _$CameraPolygonDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CameraPolygonDtoToJson(this);

  Camera get cameraDomain => camera.toDomain();
  Polygon get polygonDomain => polygon.toDomain();
}

