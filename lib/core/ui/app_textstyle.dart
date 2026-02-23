import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Premium typography system with refined spacing and elegant proportions
  // Optimized for maximum readability and visual harmony
  
  // Display - for hero sections and large headings (most prominent)
  static const display = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
    height: 1.08,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'), // Ligatures for better typography
    ],
  );

  // Large Title - for main page titles
  static const largeTitle = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.12,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Title 1 - for section headers
  static const title1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
    height: 1.18,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Title 2 - for subsection headers
  static const title2 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
    height: 1.22,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Title 3 - for card titles
  static const title3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: AppColors.textPrimary,
    height: 1.28,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Headline - for emphasized text
  static const headline = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.08,
    color: AppColors.textPrimary,
    height: 1.38,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Body - main text content (optimized for reading)
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.03, // Slightly increased for modern look
    color: AppColors.textPrimary,
    height: 1.65, // Increased for better readability
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Body Large - for important body text
  static const bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.58,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Callout - for highlighted information
  static const callout = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01,
    color: AppColors.textPrimary,
    height: 1.48,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Subheadline - for secondary information
  static const subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.03,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Footnote - for small supporting text
  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.08,
    color: AppColors.textSecondary,
    height: 1.45,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
  );

  // Caption - for labels and metadata
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
    color: AppColors.textSecondary,
    height: 1.4,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
  );

  // Button text - for primary actions (refined)
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700, // Increased for more impact
    letterSpacing: 0.25, // Increased for modern look
    color: Colors.white,
    height: 1.2,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
  );

  // Button Large - for prominent actions
  static const buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    color: Colors.white,
    height: 1.18,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
  );

  // Button Small - for secondary actions
  static const buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: Colors.white,
    height: 1.18,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
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
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: Colors.white,
    height: 1.18,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
  );

  // Label styles for forms
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.08,
    color: AppColors.textPrimary,
    height: 1.45,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
  );

  // Overline - for very small labels
  static const overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
    height: 1.35,
    fontFeatures: [
      FontFeature.enable('kern'),
    ],
  );

  // Hero text - for special emphasis
  static const hero = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
    height: 1.05,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Quote text - for citations and quotes
  static const quote = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.05,
    color: AppColors.textPrimary,
    height: 1.6,
    fontStyle: FontStyle.italic,
    fontFeatures: [
      FontFeature.enable('kern'),
      FontFeature.enable('liga'),
    ],
  );

  // Code text - for technical content
  static const code = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFeatures: [
      FontFeature.tabularFigures(), // Monospaced numbers
    ],
  );
}
