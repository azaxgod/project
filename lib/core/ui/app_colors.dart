import 'package:flutter/material.dart';

class AppColors {
  // Premium color palette - harmonious and elegant
  // Primary colors - refined blue tones
  static const primary = Color(0xFF1E40AF); // Rich, professional blue
  static const primaryLight = Color(0xFF3B82F6); // Bright, friendly blue
  static const primaryLighter = Color(0xFF60A5FA); // Very light blue
  static const primaryDark = Color(0xFF1E3A8A); // Deep, authoritative blue
  static const primaryDarker = Color(0xFF1E293B); // Almost navy
  static const primaryHover = Color(0xFF2563EB); // Interactive blue
  
  // Secondary colors - elegant purple tones
  static const secondary = Color(0xFF6D28D9); // Rich purple
  static const secondaryLight = Color(0xFF8B5CF6); // Bright purple
  static const secondaryLighter = Color(0xFFA78BFA); // Light purple
  static const secondaryDark = Color(0xFF5B21B6); // Deep purple
  static const secondaryDarker = Color(0xFF4C1D95); // Very deep purple
  
  // Background colors - premium, sophisticated
  static const background = Color(0xFFFAFBFC); // Warm, soft white
  static const backgroundSecondary = Color(0xFFF5F7FA); // Subtle gray
  static const backgroundTertiary = Color(0xFFF1F5F9); // Slightly darker
  static const surface = Colors.white;
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFFEFEFE); // Almost white with warmth
  
  // Beautiful gradient backgrounds - more sophisticated
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAFBFC),
      Color(0xFFF5F7FA),
      Color(0xFFF1F5F9),
      Color(0xFFE8ECF1),
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
  );
  
  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAFBFC),
      Color(0xFFF8F9FA),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Premium accent gradients
  static const premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E40AF),
      Color(0xFF3B82F6),
      Color(0xFF60A5FA),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Text colors - refined for perfect readability
  static const textPrimary = Color(0xFF0A0E27); // Deep, rich black with blue tint
  static const textSecondary = Color(0xFF475569); // Balanced gray
  static const textTertiary = Color(0xFF94A3B8); // Soft gray
  static const textQuaternary = Color(0xFFCBD5E1); // Very light gray
  static const textDisabled = Color(0xFFE2E8F0); // Disabled state
  static const textInverse = Colors.white; // For dark backgrounds
  
  // System colors - more vibrant and modern
  static const error = Color(0xFFEF4444); // Modern red
  static const errorLight = Color(0xFFF87171); // Light red
  static const errorDark = Color(0xFFDC2626); // Dark red
  static const success = Color(0xFF10B981); // Modern green
  static const successLight = Color(0xFF34D399); // Light green
  static const successDark = Color(0xFF059669); // Dark green
  static const warning = Color(0xFFF59E0B); // Modern orange
  static const warningLight = Color(0xFFFBBF24); // Light orange
  static const warningDark = Color(0xFFD97706); // Dark orange
  static const info = Color(0xFF3B82F6); // Info blue
  static const infoLight = Color(0xFF60A5FA); // Light info
  
  // Separator and borders - softer, more subtle
  static const separator = Color(0xFFE2E8F0); // Soft gray
  static const divider = Color(0xFFE2E8F0); // Same as separator for consistency
  static const border = Color(0xFFD1D5DB); // Slightly darker for better definition
  static const borderLight = Color(0xFFE5E7EB); // Light border
  static const borderSubtle = Color(0xFFF3F4F6); // Very subtle border
  
  // Card and surface colors - modern and clean
  static const cardBackground = Colors.white;
  static const cardBackgroundHover = Color(0xFFFAFBFC); // Hover state
  static const secondaryBackground = Color(0xFFF8FAFC);
  static const tertiaryBackground = Color(0xFFF1F5F9);
  static const quaternaryBackground = Color(0xFFE2E8F0);
  
  // Beautiful gradient colors - premium and harmonious
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryLight, primaryLighter],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  static const primaryGradientVertical = LinearGradient(
    colors: [primary, primaryLight, primaryLighter],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );
  
  static final primaryGradientSubtle = LinearGradient(
    colors: [
      const Color(0xFF1E40AF).withOpacity(0.15),
      const Color(0xFF3B82F6).withOpacity(0.08),
      Colors.transparent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight, secondaryLighter],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  static const accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const warningGradient = LinearGradient(
    colors: [warning, warningLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  // Alias for text colors
  static const text = textPrimary;
  
  // Glow effects - refined and elegant
  static Color primaryGlow = primary.withOpacity(0.25);
  static Color primaryGlowLight = primaryLight.withOpacity(0.15);
  static Color successGlow = success.withOpacity(0.25);
  static Color errorGlow = error.withOpacity(0.25);
  static Color warningGlow = warning.withOpacity(0.25);
  static Color secondaryGlow = secondary.withOpacity(0.2);
  static Color accentGlow = accent.withOpacity(0.2);
  
  // Glassmorphism support - improved
  static Color glassBackground = Colors.white.withOpacity(0.8);
  static Color glassBackgroundDark = Colors.black.withOpacity(0.4);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  
  // Gradient overlays for depth - more subtle
  static LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.15),
      Colors.transparent,
    ],
  );
  
  // Shadow colors for premium depth and elevation
  static Color shadowColor = const Color(0xFF0A0E27).withOpacity(0.06);
  static Color shadowColorLight = const Color(0xFF0A0E27).withOpacity(0.03);
  static Color shadowColorMedium = const Color(0xFF0A0E27).withOpacity(0.08);
  static Color shadowColorDark = const Color(0xFF0A0E27).withOpacity(0.12);
  static Color shadowColorXDark = const Color(0xFF0A0E27).withOpacity(0.16);
  
  // Colored shadows for special effects
  static Color shadowPrimary = primary.withOpacity(0.15);
  static Color shadowSecondary = secondary.withOpacity(0.15);
  static Color shadowSuccess = success.withOpacity(0.15);
  
  // Accent colors for special elements
  static const accent = Color(0xFF06B6D4); // Cyan accent
  static const accentLight = Color(0xFF67E8F9);
  static const accentDark = Color(0xFF0891B2);
}
