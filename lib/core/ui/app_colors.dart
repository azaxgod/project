import 'package:flutter/material.dart';

class AppColors {
  // Modern primary colors with gradients support
  static const primary = Color(0xFF007AFF); // iOS Blue
  static const primaryLight = Color(0xFF5AC8FA); // Light Blue
  static const primaryDark = Color(0xFF0051D5); // Dark Blue
  static const secondary = Color(0xFF5856D6); // iOS Purple
  static const secondaryLight = Color(0xFFAF52DE); // Light Purple
  static const background = Color(0xFFF5F7FA); // Modern light gray with blue tint
  static const surface = Colors.white;
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5F7FA),
      Color(0xFFE8ECF1),
      Color(0xFFF2F5F8),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Text colors (Apple style)
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFFC7C7CC);
  
  // System colors
  static const error = Color(0xFFFF3B30); // iOS Red
  static const errorLight = Color(0xFFFF6B6B); // Light Red
  static const success = Color(0xFF34C759); // iOS Green
  static const successLight = Color(0xFF4CD964); // Light Green
  static const warning = Color(0xFFFF9500); // iOS Orange
  static const warningLight = Color(0xFFFFB340); // Light Orange
  
  // Separator and borders
  static const separator = Color(0xFFC6C6C8);
  static const divider = Color(0xFFE5E5EA);
  
  // Card and surface colors
  static const cardBackground = Colors.white;
  static const secondaryBackground = Color(0xFFF2F2F7);
  static const tertiaryBackground = Color(0xFFE5E5EA);
  
  // Gradient colors
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Alias for text colors
  static const text = textPrimary;
  
  // Glow effects
  static Color primaryGlow = primary.withOpacity(0.3);
  static Color successGlow = success.withOpacity(0.3);
  static Color errorGlow = error.withOpacity(0.3);
  
  // Glassmorphism support
  static Color glassBackground = Colors.white.withOpacity(0.7);
  static Color glassBackgroundDark = Colors.black.withOpacity(0.3);
  
  // Gradient overlays for depth
  static LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.1),
      Colors.transparent,
    ],
  );
}
