import 'dart:async';
import 'dart:io';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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

  
  Future<void> startTracking() async {
    if (_isTracking) {
      debugPrint('DriverLocationService: Already tracking');
      return;
    }

    _isTracking = true;
    debugPrint('DriverLocationService: Starting GPS tracking');


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


    if (permission == LocationPermission.whileInUse) {
      debugPrint('DriverLocationService: Requesting background location permission');
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        debugPrint('DriverLocationService: Background location permission not granted, but continuing with foreground tracking');
      } else {
        debugPrint('DriverLocationService: Background location permission granted');
      }
    }


    // Настраиваем параметры отслеживания с поддержкой фонового режима
    // Используем платформо-специфичные настройки
    final LocationSettings locationSettings;
    
    if (Platform.isAndroid) {
      // Настройки для Android - фоновое отслеживание
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Отправляем только если переместились > 10 метров
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Отслеживание местоположения',
          notificationText: 'Приложение отслеживает ваше местоположение в фоновом режиме',
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      // Настройки для iOS - фоновое отслеживание
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Отправляем только если переместились > 10 метров
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      // Настройки по умолчанию для других платформ
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }


    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
      (Position position) {
        _handlePositionUpdate(position);
      },
      onError: (error) {
        debugPrint('DriverLocationService: Error getting position: $error');
      },
    );

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


  void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel();
    _positionStream = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    debugPrint('DriverLocationService: Stopped GPS tracking');
  }


  Future<void> _handlePositionUpdate(Position position) async {
    if (!_isTracking) return;

    _lastPosition = position;


    final now = DateTime.now();
    final shouldSend = _lastSentAt == null ||
        now.difference(_lastSentAt!) >= const Duration(seconds: 10) ||
        _hasSignificantChange(position);

    if (shouldSend) {
      await _sendLocation(position);
    }
  }


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

