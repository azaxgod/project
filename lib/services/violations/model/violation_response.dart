import 'package:flutter/foundation.dart';
import 'package:akimat_project/services/violations/model/appeal.dart';
import 'package:akimat_project/services/violations/model/violation.dart';

class ViolationRecord {
  final Violation violation;
  final String? tripStatus;
  final DateTime? tripEntryAt;
  final String? tripViolationReason;
  final ContractorInfo? contractor;
  final TicketInfo? ticket;
  final DriverInfo? driver;
  final VehicleInfo? vehicle;
  final String? polygonName;
  final bool hasActiveAppeal;

  ViolationRecord({
    required this.violation,
    this.tripStatus,
    this.tripEntryAt,
    this.tripViolationReason,
    this.contractor,
    this.ticket,
    this.driver,
    this.vehicle,
    this.polygonName,
    this.hasActiveAppeal = false,
  });

  factory ViolationRecord.fromJson(Map<String, dynamic> json) {
    return ViolationRecord(
      violation: Violation.fromJson(json['violation'] as Map<String, dynamic>),
      tripStatus: json['trip_status'] as String?,
      tripEntryAt: json['trip_entry_at'] != null
          ? DateTime.parse(json['trip_entry_at'] as String)
          : null,
      tripViolationReason: json['trip_violation_reason'] as String?,
      contractor: json['contractor'] != null
          ? ContractorInfo.fromJson(json['contractor'] as Map<String, dynamic>)
          : null,
      ticket: json['ticket'] != null
          ? TicketInfo.fromJson(json['ticket'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? DriverInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] != null
          ? VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      polygonName: json['polygon_name'] as String?,
      hasActiveAppeal: json['has_active_appeal'] as bool? ?? false,
    );
  }
}

class ContractorInfo {
  final String id;
  final String name;

  ContractorInfo({required this.id, required this.name});

  factory ContractorInfo.fromJson(Map<String, dynamic> json) {
    return ContractorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class TicketInfo {
  final String id;
  final String status;

  TicketInfo({required this.id, required this.status});

  factory TicketInfo.fromJson(Map<String, dynamic> json) {
    return TicketInfo(
      id: json['id'] as String,
      status: json['status'] as String,
    );
  }
}

class DriverInfo {
  final String id;
  final String fullName;
  final String? phone;

  DriverInfo({required this.id, required this.fullName, this.phone});

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class VehicleInfo {
  final String id;
  final String plateNumber;

  VehicleInfo({required this.id, required this.plateNumber});

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      id: json['id'] as String,
      plateNumber: json['plate_number'] as String,
    );
  }
}

class ViolationsListResponse {
  final List<ViolationRecord> items;

  ViolationsListResponse({required this.items});

  factory ViolationsListResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('ViolationsListResponse - Parsing JSON: $json');
    
    // Handle different response formats
    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic> && data.containsKey('items')) {
        // Format: { "data": { "items": [...] } }
        return ViolationsListResponse(
          items: (data['items'] as List<dynamic>)
              .map((e) => ViolationRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else if (data is List) {
        // Format: { "data": [...] }
        return ViolationsListResponse(
          items: (data as List<dynamic>)
              .map((e) => ViolationRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    } else if (json.containsKey('items')) {
      // Format: { "items": [...] }
      return ViolationsListResponse(
        items: (json['items'] as List<dynamic>)
            .map((e) => ViolationRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else if (json is List) {
      // Format: [...] (direct array)
      return ViolationsListResponse(
        items: (json as List<dynamic>)
            .map((e) => ViolationRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    
    // Default empty response
    debugPrint('ViolationsListResponse - Unknown format, returning empty list');
    return ViolationsListResponse(items: []);
  }
}

class ViolationDetailResponse {
  final ViolationRecord violation;
  final List<AppealRecord> appeals;

  ViolationDetailResponse({
    required this.violation,
    required this.appeals,
  });

  factory ViolationDetailResponse.fromJson(Map<String, dynamic> json) {
    return ViolationDetailResponse(
      violation: ViolationRecord.fromJson(
        json['violation'] as Map<String, dynamic>,
      ),
      appeals: (json['appeals'] as List<dynamic>?)
              ?.map((e) => AppealRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AppealRecord {
  final Appeal appeal;
  final Violation? violation;
  final DriverInfo? driver;
  final List<AppealAttachment> attachments;
  final List<AppealComment> comments;

  AppealRecord({
    required this.appeal,
    this.violation,
    this.driver,
    required this.attachments,
    required this.comments,
  });

  factory AppealRecord.fromJson(Map<String, dynamic> json) {
    return AppealRecord(
      appeal: Appeal.fromJson(json['appeal'] as Map<String, dynamic>),
      violation: json['violation'] != null
          ? Violation.fromJson(json['violation'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? DriverInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  AppealAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => AppealComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AppealsListResponse {
  final List<AppealRecord> items;

  AppealsListResponse({required this.items});

  factory AppealsListResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('AppealsListResponse - Parsing JSON: $json');
    
    // Handle different response formats
    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic> && data.containsKey('items')) {
        // Format: { "data": { "items": [...] } }
        return AppealsListResponse(
          items: (data['items'] as List<dynamic>)
              .map((e) => AppealRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else if (data is List) {
        // Format: { "data": [...] }
        return AppealsListResponse(
          items: (data as List<dynamic>)
              .map((e) => AppealRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    } else if (json.containsKey('items')) {
      // Format: { "items": [...] }
      return AppealsListResponse(
        items: (json['items'] as List<dynamic>)
            .map((e) => AppealRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else if (json is List) {
      // Format: [...] (direct array)
      return AppealsListResponse(
        items: (json as List<dynamic>)
            .map((e) => AppealRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    
    // Default empty response
    debugPrint('AppealsListResponse - Unknown format, returning empty list');
    return AppealsListResponse(items: []);
  }
}

class AppealDetailResponse {
  final AppealRecord appeal;

  AppealDetailResponse({required this.appeal});

  factory AppealDetailResponse.fromJson(Map<String, dynamic> json) {
    return AppealDetailResponse(
      appeal: AppealRecord.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}








