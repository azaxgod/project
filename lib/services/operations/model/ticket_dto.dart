import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_dto.g.dart';

@JsonSerializable()
class TicketDto {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'cleaning_area_id')
  final String cleaningAreaId;

  @JsonKey(name: 'contractor_id')
  final String contractorId;

  @JsonKey(name: 'contract_id')
  final String contractId;

  @JsonKey(name: 'planned_start_at')
  final DateTime plannedStartAt;

  @JsonKey(name: 'planned_end_at')
  final DateTime plannedEndAt;

  @JsonKey(name: 'fact_start_at')
  final DateTime? factStartAt;

  @JsonKey(name: 'fact_end_at')
  final DateTime? factEndAt;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'trips_count')
  final int? tripsCount;

  @JsonKey(name: 'volume_shipped_m3')
  final double? volumeShippedM3;

  @JsonKey(name: 'has_violations')
  final bool hasViolations;

  @JsonKey(name: 'created_by_org_id')
  final String? createdByOrgId;

  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  TicketDto({
    required this.id,
    required this.cleaningAreaId,
    required this.contractorId,
    required this.contractId,
    required this.plannedStartAt,
    required this.plannedEndAt,
    this.factStartAt,
    this.factEndAt,
    this.description,
    required this.status,
    this.tripsCount,
    this.volumeShippedM3,
    this.hasViolations = false,
    this.createdByOrgId,
    this.isActive = true, // По умолчанию true, если не указано
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketDto.fromJson(Map<String, dynamic> json) => _$TicketDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketDtoToJson(this);

  Ticket toDomain() {
    return Ticket(
      id: id,
      cleaningAreaId: cleaningAreaId,
      contractorId: contractorId,
      contractId: contractId,
      plannedStartAt: plannedStartAt,
      plannedEndAt: plannedEndAt,
      factStartAt: factStartAt,
      factEndAt: factEndAt,
      description: description,
      status: _mapStatus(status),
      tripsCount: tripsCount,
      volumeShipped: volumeShippedM3,
      hasViolations: hasViolations,
      createdByOrgId: createdByOrgId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static TicketStatus _mapStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return TicketStatus.planned;
      case 'IN_PROGRESS':
        return TicketStatus.inProgress;
      case 'COMPLETED':
        return TicketStatus.completed;
      case 'CLOSED':
        return TicketStatus.closed;
      case 'CANCELLED':
        return TicketStatus.cancelled;
      default:
        return TicketStatus.planned;
    }
  }

  static String statusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.planned:
        return 'PLANNED';
      case TicketStatus.inProgress:
        return 'IN_PROGRESS';
      case TicketStatus.completed:
        return 'COMPLETED';
      case TicketStatus.closed:
        return 'CLOSED';
      case TicketStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

