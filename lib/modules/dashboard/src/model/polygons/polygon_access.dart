import 'package:equatable/equatable.dart';

class PolygonAccess extends Equatable {
  final String id;
  final String polygonId;
  final String contractorId;
  final String source; // "TICKETS", "MANUAL", etc.
  final bool isActive;
  final DateTime createdAt;

  const PolygonAccess({
    required this.id,
    required this.polygonId,
    required this.contractorId,
    required this.source,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, polygonId, contractorId, source, isActive, createdAt];
}


