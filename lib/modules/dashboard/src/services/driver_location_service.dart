import 'dart:async';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Сервис для отслеживания и отправки GPS-локации водителя
class DriverLocationService {
  final OperationsRepository _repository;
  Position? _lastPosition;
  DateTime? _lastSentAt;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;
  Timer? _periodicTimer;

  DriverLocationService({
    required OperationsRepository repository,
  }) : _repository = repository;

  /// Начать отслеживание GPS-локации
  /// Отправляет локацию каждые 10 секунд или при изменении позиции > 10 метров
  Future<void> startTracking() async {
    if (_isTracking) {
      debugPrint('DriverLocationService: Already tracking');
      return;
    }

    _isTracking = true;
    debugPrint('DriverLocationService: Starting GPS tracking');

    // Проверяем разрешения
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('DriverLocationService: Location services are disabled');
      _isTracking = false;
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('DriverLocationService: Location permissions are denied');
        _isTracking = false;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('DriverLocationService: Location permissions are permanently denied');
      _isTracking = false;
      return;
    }

    // Настраиваем параметры отслеживания
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Отправляем только если переместились > 10 метров
    );

    // Слушаем изменения позиции
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
      (Position position) {
        _handlePositionUpdate(position);
      },
      onError: (error) {
        debugPrint('DriverLocationService: Error getting position: $error');
      },
    );

    // Также отправляем локацию периодически (каждые 10 секунд)
    // даже если позиция не изменилась
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        if (!_isTracking) {
          timer.cancel();
          return;
        }
        if (_lastPosition != null) {
          _sendLocation(_lastPosition!);
        }
      },
    );
  }

  /// Остановить отслеживание
  void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel();
    _positionStream = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    debugPrint('DriverLocationService: Stopped GPS tracking');
  }

  /// Обработка обновления позиции
  Future<void> _handlePositionUpdate(Position position) async {
    if (!_isTracking) return;

    _lastPosition = position;

    // Отправляем только если прошло достаточно времени или позиция значительно изменилась
    final now = DateTime.now();
    final shouldSend = _lastSentAt == null ||
        now.difference(_lastSentAt!) >= const Duration(seconds: 10) ||
        _hasSignificantChange(position);

    if (shouldSend) {
      await _sendLocation(position);
    }
  }

  /// Проверяет, изменилась ли позиция значительно (> 10 метров)
  bool _hasSignificantChange(Position newPosition) {
    if (_lastPosition == null) return true;

    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance > 10; // 10 метров
  }

  /// Отправка локации на сервер
  Future<void> _sendLocation(Position position) async {
    try {
      await _repository.sendDriverLocation(
        lat: position.latitude,
        lon: position.longitude,
        accuracy: position.accuracy,
      );

      _lastSentAt = DateTime.now();
      debugPrint(
        'DriverLocationService: Location sent: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('DriverLocationService: Error sending location: $e');
    }
  }


  /// Отправить текущую локацию вручную
  Future<void> sendCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _sendLocation(position);
    } catch (e) {
      debugPrint('DriverLocationService: Error getting/sending current location: $e');
    }
  }
}

