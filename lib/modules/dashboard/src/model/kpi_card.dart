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
