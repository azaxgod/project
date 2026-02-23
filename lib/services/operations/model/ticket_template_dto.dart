import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/services/operations/model/cleaning_area_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_template_dto.g.dart';

@JsonSerializable()
class TicketTemplateDto {
  @JsonKey(name: 'cleaning_area')
  final CleaningAreaDto cleaningArea;
  @JsonKey(name: 'available_contractors')
  final List<Map<String, dynamic>> availableContractors;

  TicketTemplateDto({
    required this.cleaningArea,
    required this.availableContractors,
  });

  factory TicketTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$TicketTemplateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketTemplateDtoToJson(this);

  CleaningArea get area => cleaningArea.toDomain();
}

