import 'package:equatable/equatable.dart';

enum TicketStatus {
  planned, // PLANNED - Тикет создан, нет фактов
  inProgress, // IN_PROGRESS - В работе
  completed, // COMPLETED - Завершен водителем
  closed, // CLOSED - Закрыт после проверки
  cancelled, // CANCELLED - Отменен
}

class Ticket extends Equatable {
  final String id;
  final String cleaningAreaId; // FK → cleaning_area.id
  final String contractorId; // FK → organization.id (type = CONTRACTOR)
  final String contractId; // FK → contract.id (обязательно)
  final DateTime plannedStartAt; // Плановый период начала
  final DateTime plannedEndAt; // Плановый период окончания
  final DateTime? factStartAt; // Фактическое начало работ
  final DateTime? factEndAt; // Фактическое окончание работ
  final String? description;
  final TicketStatus status;
  final int? tripsCount; // Количество рейсов (факт: COUNT trip)
  final double? volumeShipped; // Объем вывезен (м³) (факт: SUM trip.detected_volume_entry)
  final bool hasViolations; // Есть нарушения (EXISTS trip WHERE status <> 'OK')
  final String? createdByOrgId; // ID организации, создавшей тикет
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticket({
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
    this.volumeShipped,
    this.hasViolations = false,
    this.createdByOrgId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Ticket copyWith({
    String? id,
    String? cleaningAreaId,
    String? contractorId,
    String? contractId,
    DateTime? plannedStartAt,
    DateTime? plannedEndAt,
    Object? factStartAt = _keepFactStart,
    Object? factEndAt = _keepFactEnd,
    Object? description = _keepDescription,
    TicketStatus? status,
    Object? tripsCount = _keepTripsCount,
    Object? volumeShipped = _keepVolumeShipped,
    bool? hasViolations,
    Object? createdByOrgId = _keepCreatedByOrg,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      cleaningAreaId: cleaningAreaId ?? this.cleaningAreaId,
      contractorId: contractorId ?? this.contractorId,
      contractId: contractId ?? this.contractId,
      plannedStartAt: plannedStartAt ?? this.plannedStartAt,
      plannedEndAt: plannedEndAt ?? this.plannedEndAt,
      factStartAt: factStartAt == _keepFactStart ? this.factStartAt : factStartAt as DateTime?,
      factEndAt: factEndAt == _keepFactEnd ? this.factEndAt : factEndAt as DateTime?,
      description: description == _keepDescription ? this.description : description as String?,
      status: status ?? this.status,
      tripsCount: tripsCount == _keepTripsCount ? this.tripsCount : tripsCount as int?,
      volumeShipped: volumeShipped == _keepVolumeShipped ? this.volumeShipped : volumeShipped as double?,
      hasViolations: hasViolations ?? this.hasViolations,
      createdByOrgId: createdByOrgId == _keepCreatedByOrg ? this.createdByOrgId : createdByOrgId as String?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _keepDescription = Object();
  static const _keepTripsCount = Object();
  static const _keepVolumeShipped = Object();
  static const _keepFactStart = Object();
  static const _keepFactEnd = Object();
  static const _keepCreatedByOrg = Object();

  @override
  List<Object?> get props => [
        id,
        cleaningAreaId,
        contractorId,
        contractId,
        plannedStartAt,
        plannedEndAt,
        factStartAt,
        factEndAt,
        description,
        status,
        tripsCount,
        volumeShipped,
        hasViolations,
        createdByOrgId,
        isActive,
        createdAt,
        updatedAt,
      ];
}

