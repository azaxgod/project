// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../model/kpi_card.dart';
// import '../model/trip.dart';
// import '../model/ticket.dart';
// import '../model/polygon.dart';
// import '../service/akimat_service.dart';

// final akimatHomeControllerProvider = StateNotifierProvider<AkimatHomeController, AkimatHomeState>((ref) {
//   return AkimatHomeController(ref.read);
// });

// class AkimatHomeController extends StateNotifier<AkimatHomeState> {
//   final Reader read;

//   AkimatHomeController(this.read) : super(AkimatHomeState.initial()) {
//     fetchData();
//   }

//   Future<void> fetchData() async {
//     final service = read(akimatServiceProvider);
    
//     final kpi = await service.getKpiData();
//     final trips = await service.getLastTrips();
//     final polygons = await service.getPolygons();

//     state = state.copyWith(
//       kpiCards: kpi,
//       lastTrips: trips,
//       polygons: polygons,
//     );
//   }
// }

// class AkimatHomeState {
//   final List<KpiCardModel> kpiCards;
//   final List<TripModel> lastTrips;
//   final List<PolygonModel> polygons;

//   AkimatHomeState({
//     required this.kpiCards,
//     required this.lastTrips,
//     required this.polygons,
//   });

//   factory AkimatHomeState.initial() => AkimatHomeState(
//         kpiCards: [],
//         lastTrips: [],
//         polygons: [],
//       );

//   AkimatHomeState copyWith({
//     List<KpiCardModel>? kpiCards,
//     List<TripModel>? lastTrips,
//     List<PolygonModel>? polygons,
//   }) {
//     return AkimatHomeState(
//       kpiCards: kpiCards ?? this.kpiCards,
//       lastTrips: lastTrips ?? this.lastTrips,
//       polygons: polygons ?? this.polygons,
//     );
//   }
// }


/// MOCK DANNI 
/// 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../model/kpi_card.dart';
// import '../model/trip.dart';
// import '../model/polygon.dart';

final akimatHomeControllerProvider =
    StateNotifierProvider<AkimatHomeController, AkimatHomeState>((ref) {
  return AkimatHomeController();
});

class AkimatHomeController extends StateNotifier<AkimatHomeState> {
  AkimatHomeController() : super(AkimatHomeState.initial()) {
    _loadMockData();
  }

  void _loadMockData() {
    // ------------------ KPI ------------------
    final kpi = [
      KpiCardModel(
        title: 'Активные участки',
        value: '12',
        clickable: false,
      ),
      KpiCardModel(
        title: 'Активные тикеты',
        value: '8',
        clickable: false,
      ),
      KpiCardModel(
        title: 'Рейсы за сегодня',
        value: '25',
        clickable: false,
      ),
      KpiCardModel(
        title: 'Нарушения за сегодня',
        value: '3',
        clickable: true, // кликабельная карточка
      ),
    ];

    // ------------------ Последние рейсы ------------------
    // final trips = [
    //   TripModel(
    //     time: '08:00',
    //     contractor: 'Подрядчик А',
    //     plate: 'KZ1234AB',
    //     area: 'Участок 1',
    //     polygon: 'Полигон 1',
    //     volume: 5.2,
    //     status: 'CONFIRMED',
    //   ),
    //   TripModel(
    //     time: '09:15',
    //     contractor: 'Подрядчик B',
    //     plate: 'KZ5678CD',
    //     area: 'Участок 2',
    //     polygon: 'Полигон 2',
    //     volume: 3.7,
    //     status: 'ROUTE_VIOLATION',
    //   ),
    //   TripModel(
    //     time: '10:30',
    //     contractor: 'Подрядчик C',
    //     plate: 'KZ9012EF',
    //     area: 'Участок 3',
    //     polygon: 'Полигон 3',
    //     volume: 4.1,
    //     status: 'MISMATCH_PLATE',
    //   ),
    // ];

    // ------------------ Полигоны ------------------
    // final polygons = [
    //   PolygonModel(
    //     name: 'Полигон 1',
    //     contractor: 'Подрядчик А',
    //     status: 'ACTIVE',
    //     color: Colors.green,
    //   ),
    //   PolygonModel(
    //     name: 'Полигон 2',
    //     contractor: 'Подрядчик B',
    //     status: 'WARNING',
    //     color: Colors.orange,
    //   ),
    //   PolygonModel(
    //     name: 'Полигон 3',
    //     contractor: 'Подрядчик C',
    //     status: 'VIOLATION',
    //     color: Colors.red,
    //   ),
    // ];


    // state = state.copyWith(
    //   kpiCards: kpi,
    //   lastTrips: trips,
    //   polygons: polygons,
    // );
  }
}

class AkimatHomeState {
  final List<KpiCardModel> kpiCards;
  final List<TripModel> lastTrips;
  final List<PolygonModel> polygons;

  AkimatHomeState({
    required this.kpiCards,
    required this.lastTrips,
    required this.polygons,
  });

  factory AkimatHomeState.initial() => AkimatHomeState(
        kpiCards: [],
        lastTrips: [],
        polygons: [],
      );

  AkimatHomeState copyWith({
    List<KpiCardModel>? kpiCards,
    List<TripModel>? lastTrips,
    List<PolygonModel>? polygons,
  }) {
    return AkimatHomeState(
      kpiCards: kpiCards ?? this.kpiCards,
      lastTrips: lastTrips ?? this.lastTrips,
      polygons: polygons ?? this.polygons,
    );
  }
}




// ---------------- KPI Card ----------------
class KpiCardModel {
  final String title;
  final String value;
  final bool clickable;

  KpiCardModel({
    required this.title,
    required this.value,
    this.clickable = false,
  });
}

// ---------------- Trip ----------------
class TripModel {
  final String time;
  final String contractor;
  final String plate;
  final String area;
  final String polygon;
  final double volume;
  final String status;

  TripModel({
    required this.time,
    required this.contractor,
    required this.plate,
    required this.area,
    required this.polygon,
    required this.volume,
    required this.status,
  });
}

// ---------------- Polygon ----------------
class PolygonModel {
  final String name;
  final String contractor;
  final String status;
  final Color color;

  PolygonModel({
    required this.name,
    required this.contractor,
    required this.status,
    required this.color,
  });
}
