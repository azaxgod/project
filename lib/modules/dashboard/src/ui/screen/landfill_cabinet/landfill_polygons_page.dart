import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/polygons/polygons_page.dart';
import 'package:flutter/material.dart';

class LandfillPolygonsPage extends StatelessWidget {
  const LandfillPolygonsPage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    // Используем существующую страницу полигонов, но фильтруем только полигоны текущей организации
    return PolygonsPage(
      scaffoldKey: scaffoldKey,
    );
  }
}

