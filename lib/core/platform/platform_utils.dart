import 'package:akimat_project/core/platform/platform_config_mobile.dart';
import 'package:akimat_project/core/platform/platform_config_web.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

abstract class PlatformConfig {
  double get padding;                // для отступов
  bool get horizontalScroll;         // для горизонтального скролла
  double get topOffset;              // top offset для виджетов
  bool get showExtraWidget;          // показывать доп. виджет
  Axis get scrollDirection;          // направление скролла
  Color get backgroundColor;         // цвет фона

  static PlatformConfig instance = kIsWeb ? PlatformConfigWeb() : PlatformConfigMobile();
}

class PlatformConfigWeb implements PlatformConfig {
  @override
  double get padding => 24.0;

  @override
  bool get horizontalScroll => false;

  @override
  double get topOffset => 32.0;

  @override
  bool get showExtraWidget => true;

  @override
  Axis get scrollDirection => Axis.vertical;

  @override
  Color get backgroundColor => const Color(0xFFF5F7FA);
}

class PlatformConfigMobile implements PlatformConfig {
  @override
  double get padding => 12.0;

  @override
  bool get horizontalScroll => true;

  @override
  double get topOffset => 16.0;

  @override
  bool get showExtraWidget => false;

  @override
  Axis get scrollDirection => Axis.horizontal;

  @override
  Color get backgroundColor => const Color(0xFFF5F7FA);
}
