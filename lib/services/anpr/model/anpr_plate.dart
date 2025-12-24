import 'package:equatable/equatable.dart';

/// Модель номера транспортного средства
class AnprPlate extends Equatable {
  final int id;
  final String number; // Исходный номер
  final String normalized; // Нормализованный номер
  final DateTime? lastEventTime;

  const AnprPlate({
    required this.id,
    required this.number,
    required this.normalized,
    this.lastEventTime,
  });

  factory AnprPlate.fromJson(Map<String, dynamic> json) {
    return AnprPlate(
      id: json['id'] as int,
      number: json['number'] as String,
      normalized: json['normalized'] as String,
      lastEventTime: json['last_event_time'] != null
          ? DateTime.parse(json['last_event_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'normalized': normalized,
      if (lastEventTime != null)
        'last_event_time': lastEventTime!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, number, normalized, lastEventTime];
}

/// Ответ на поиск номеров
class AnprPlatesResponse extends Equatable {
  final List<AnprPlate> data;

  const AnprPlatesResponse({required this.data});

  factory AnprPlatesResponse.fromJson(Map<String, dynamic> json) {
    return AnprPlatesResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => AnprPlate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [data];
}


