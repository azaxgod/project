import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/services/driver_location_service.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/tickets/tickets_page.dart';
import 'package:akimat_project/services/operations/module.dart';
import 'package:akimat_project/services/tickets/module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverLocationServiceProvider = Provider<DriverLocationService>((ref) {
  final operationsRepo = OperationsRepositoryImpl(
    services: ref.watch(operationsServicesProvider),
    ticketsServices: ref.watch(ticketsServicesProvider),
    userRole: null, // Не используется для отправки локации
  );
  return DriverLocationService(repository: operationsRepo);
});

class DriverHome extends ConsumerStatefulWidget {
  const DriverHome({super.key});

  @override
  ConsumerState<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends ConsumerState<DriverHome> {
  bool _isLocationTracking = false;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    // Начинаем отслеживание GPS-локации при входе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationTracking();
    });
  }

  @override
  void dispose() {
    // Останавливаем отслеживание при выходе
    final service = ref.read(driverLocationServiceProvider);
    service.stopTracking();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      final service = ref.read(driverLocationServiceProvider);
      await service.startTracking();
      setState(() {
        _isLocationTracking = true;
        _locationStatus = 'Отслеживание активно';
      });
    } catch (e) {
      setState(() {
        _isLocationTracking = false;
        _locationStatus = 'Ошибка: $e';
      });
    }
  }

  Future<void> _sendCurrentLocation() async {
    try {
      final service = ref.read(driverLocationServiceProvider);
      await service.sendCurrentLocation();
      setState(() {
        _locationStatus = 'Локация отправлена';
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Ошибка отправки: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель Водителя'),
        actions: [
          // Индикатор статуса GPS-отслеживания
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  _isLocationTracking ? Icons.location_on : Icons.location_off,
                  color: _isLocationTracking ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 4),
                if (_locationStatus != null)
                  Text(
                    _locationStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isLocationTracking ? Colors.green : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Карточка с информацией о водителе и статусе GPS
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Водитель: ${user?.phone ?? "Неизвестно"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isLocationTracking ? Icons.gps_fixed : Icons.gps_off,
                      color: _isLocationTracking ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLocationTracking
                            ? 'GPS-отслеживание активно. Ваша локация отправляется автоматически.'
                            : 'GPS-отслеживание неактивно. Нажмите кнопку для отправки локации.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (!_isLocationTracking) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _sendCurrentLocation,
                    icon: const Icon(Icons.send),
                    label: const Text('Отправить текущую локацию'),
                  ),
                ],
              ],
            ),
          ),
          // Список тикетов водителя
          Expanded(
            child: TicketsPage(
              scaffoldKey: GlobalKey<ScaffoldState>(),
            ),
          ),
        ],
      ),
    );
  }
}
