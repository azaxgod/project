import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Apple typography - clean, readable, system font
  // Large Title (iOS style)
  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.37,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Title 1
  static const title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.36,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Title 2
  static const title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.35,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Title 3
  static const title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Headline
  static const headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Body
  static const body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.41,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Callout
  static const callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.32,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Subheadline
  static const subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.24,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Footnote
  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.08,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Caption
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // Button text
  static const button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: Colors.white,
    height: 1.3,
  );

  // Legacy support
  static const title = title2;
  static const subtitle = callout;
  
  // Professional enhancements
  static TextStyle withGradient(TextStyle base, List<Color> colors) {
    return base.copyWith(
      foreground: Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
          const Rect.fromLTWH(0, 0, 200, 70),
        ),
    );
  }
  
  // Enhanced button text
  static const buttonBold = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
    color: Colors.white,
    height: 1.3,
  );
}
