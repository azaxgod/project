import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandfillJournalState {
  final AsyncValue<LandfillJournalData> data;
  final String? polygonFilter;
  final String? contractorFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? statusFilter;

  const LandfillJournalState({
    required this.data,
    this.polygonFilter,
    this.contractorFilter,
    this.dateFrom,
    this.dateTo,
    this.statusFilter,
  });

  factory LandfillJournalState.initial() {
    return const LandfillJournalState(
      data: AsyncLoading(),
    );
  }

  LandfillJournalState copyWith({
    AsyncValue<LandfillJournalData>? data,
    String? polygonFilter,
    String? contractorFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? statusFilter,
  }) {
    return LandfillJournalState(
      data: data ?? this.data,
      polygonFilter: polygonFilter ?? this.polygonFilter,
      contractorFilter: contractorFilter ?? this.contractorFilter,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class LandfillJournalData {
  final List<ReceptionTrip> trips;
  final double totalVolumeM3;
  final int totalTrips;

  const LandfillJournalData({
    required this.trips,
    required this.totalVolumeM3,
    required this.totalTrips,
  });
}

class ReceptionTrip {
  final String tripId;
  final DateTime entryAt;
  final DateTime? exitAt;
  final String polygonId;
  final String polygonName;
  final String vehiclePlateNumber;
  final String detectedPlateNumber;
  final String contractorId;
  final String contractorName;
  final double detectedVolumeEntry;
  final double detectedVolumeExit;
  final double netVolumeM3;
  final String status;
  final String? violationReason;

  const ReceptionTrip({
    required this.tripId,
    required this.entryAt,
    this.exitAt,
    required this.polygonId,
    required this.polygonName,
    required this.vehiclePlateNumber,
    required this.detectedPlateNumber,
    required this.contractorId,
    required this.contractorName,
    required this.detectedVolumeEntry,
    required this.detectedVolumeExit,
    required this.netVolumeM3,
    required this.status,
    this.violationReason,
  });

  factory ReceptionTrip.fromJson(Map<String, dynamic> json) {
    return ReceptionTrip(
      tripId: json['trip_id'] as String,
      entryAt: DateTime.parse(json['entry_at'] as String),
      exitAt: json['exit_at'] != null
          ? DateTime.parse(json['exit_at'] as String)
          : null,
      polygonId: json['polygon_id'] as String,
      polygonName: json['polygon_name'] as String,
      vehiclePlateNumber: json['vehicle_plate_number'] as String,
      detectedPlateNumber: json['detected_plate_number'] as String,
      contractorId: json['contractor_id'] as String,
      contractorName: json['contractor_name'] as String,
      detectedVolumeEntry: (json['detected_volume_entry'] as num).toDouble(),
      detectedVolumeExit: (json['detected_volume_exit'] as num).toDouble(),
      netVolumeM3: (json['net_volume_m3'] as num).toDouble(),
      status: json['status'] as String,
      violationReason: json['violation_reason'] as String?,
    );
  }
}

final landfillJournalControllerProvider =
    StateNotifierProvider<LandfillJournalController, LandfillJournalState>((ref) {
  final repository = ref.watch(operationsRepositoryProvider);
  return LandfillJournalController(repository: repository);
});

class LandfillJournalController extends StateNotifier<LandfillJournalState> {
  LandfillJournalController({
    required OperationsRepository repository,
  })  : _repository = repository,
        super(LandfillJournalState.initial()) {
    _loadData();
  }

  final OperationsRepository _repository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        final result = await _repository.getLandfillReceptionJournal(
          polygonId: state.polygonFilter,
          contractorId: state.contractorFilter,
          dateFrom: state.dateFrom,
          dateTo: state.dateTo,
          status: state.statusFilter,
        );

        final tripsData = result['data'] as Map<String, dynamic>;
        final tripsList = tripsData['trips'] as List<dynamic>? ?? [];
        final trips = tripsList
            .map((json) => ReceptionTrip.fromJson(json as Map<String, dynamic>))
            .toList();

        return LandfillJournalData(
          trips: trips,
          totalVolumeM3: (tripsData['total_volume_m3'] as num?)?.toDouble() ?? 0.0,
          totalTrips: (tripsData['total_trips'] as int?) ?? 0,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  void setPolygonFilter(String? polygonId) {
    state = state.copyWith(polygonFilter: polygonId);
    _loadData();
  }

  void setContractorFilter(String? contractorId) {
    state = state.copyWith(contractorFilter: contractorId);
    _loadData();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
    _loadData();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    _loadData();
  }
}

