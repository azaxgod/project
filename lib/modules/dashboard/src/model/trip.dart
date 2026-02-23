import 'package:flutter/material.dart';

class TripModel {
  final String date;
  final String time;
  final String contractor;
  final String plate;
  final String area;
  final String polygon;
  final double volume;
  final String status;

  TripModel({
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
