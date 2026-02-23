import 'package:akimat_project/modules/dashboard/src/model/trips/trip.dart';
import 'package:equatable/equatable.dart';

enum AppealStatus {
  submitted, // SUBMITTED - подано
  underReview, // UNDER_REVIEW - на рассмотрении
  needInfo, // NEED_INFO - требуется информация
  approved, // APPROVED - одобрено
  rejected, // REJECTED - отклонено
  closed, // CLOSED - закрыто
}

enum AppealReason {
  cameraError, // Ошибка камеры/распознавания
  transit, // Ехал транзитом через участок
  otherAssignment, // Был назначен другой участок/задание
  other, // Другая причина
}

class Appeal extends Equatable {
  final String id;
  final String tripId; // FK → trip.id
  final String? driverId; // FK → driver.id (кто подал)
  final TripStatus violationType; // Тип нарушения из trip.status
  final AppealReason reason; // Основание обжалования
  final String comment; // Комментарий (обязательно)
  final AppealStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appeal({
    required this.id,
    required this.tripId,
    this.driverId,
    required this.violationType,
    required this.reason,
    required this.comment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Appeal copyWith({
    String? id,
    String? tripId,
    Object? driverId = _keepDriver,
    TripStatus? violationType,
    AppealReason? reason,
    String? comment,
    AppealStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appeal(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      driverId: driverId == _keepDriver ? this.driverId : driverId as String?,
      violationType: violationType ?? this.violationType,
      reason: reason ?? this.reason,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _keepDriver = Object();

  @override
  List<Object?> get props => [
        id,
        tripId,
        driverId,
        violationType,
        reason,
        comment,
        status,
        createdAt,
        updatedAt,
      ];
}

