import 'package:flutter/material.dart';

class TripData {
  final String date;
  final String time;
  final String contractor;
  final String plate;
  final String area;
  final String polygon;
  final double volume;
  final String status;

  TripData({
    required this.date,
    required this.time,
    required this.contractor,
    required this.plate,
    required this.area,
    required this.polygon,
    required this.volume,
    required this.status,
  });
}

class TripTableWidget extends StatelessWidget {
  final List<TripData> trips;

  const TripTableWidget({super.key, required this.trips});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Дата')),
          DataColumn(label: Text('Время')),
          DataColumn(label: Text('Подрядчик')),
          DataColumn(label: Text('Госномер')),
          DataColumn(label: Text('Полигон')),
          DataColumn(label: Text('Объем (м³)')),
        ],
        rows: trips
            .map(
              (trip) => DataRow(
                cells: [
                  DataCell(Text(trip.date)),
                  DataCell(Text(trip.time)),
                  DataCell(Text(trip.contractor)),
                  DataCell(Text(trip.plate)),
                  DataCell(Text(trip.polygon)),
                  DataCell(Text(trip.volume.toStringAsFixed(2))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
