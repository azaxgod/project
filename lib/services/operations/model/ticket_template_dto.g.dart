// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_template_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketTemplateDto _$TicketTemplateDtoFromJson(Map<String, dynamic> json) =>
    TicketTemplateDto(
      cleaningArea: CleaningAreaDto.fromJson(
          json['cleaning_area'] as Map<String, dynamic>),
      availableContractors: (json['available_contractors'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$TicketTemplateDtoToJson(TicketTemplateDto instance) =>
    <String, dynamic>{
      'cleaning_area': instance.cleaningArea,
      'available_contractors': instance.availableContractors,
    };
