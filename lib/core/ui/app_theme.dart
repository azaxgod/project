import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_textstyle.dart';
import 'app_size.dart';
import 'app_padding.dart';

class AppTheme {
  // Light theme - modern, clean, professional
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceElevated,
        background: AppColors.background,
        error: AppColors.error,
        errorContainer: AppColors.errorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.background,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.title2.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSize.iconSize,
        ),
        centerTitle: false,
      ),
      
      // Card theme - premium styling
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          side: BorderSide(
            color: AppColors.borderLight,
            width: 1.5,
          ),
        ),
        color: AppColors.cardBackground,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: AppColors.shadowColor,
      ),
      
      // Elevated button theme - premium styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.buttonHorizontal,
            vertical: AppPadding.buttonVertical,
          ),
          minimumSize: const Size(0, AppSize.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.buttonRadius),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          disabledBackgroundColor: AppColors.textDisabled,
          disabledForegroundColor: AppColors.textTertiary,
          shadowColor: AppColors.shadowPrimary,
        ),
      ),
      
      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.buttonHorizontal,
            vertical: AppPadding.buttonVertical,
          ),
          minimumSize: const Size(0, AppSize.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.buttonRadius),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.buttonHorizontal,
            vertical: AppPadding.buttonVertical,
          ),
          minimumSize: const Size(0, AppSize.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.buttonRadius),
          ),
          side: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.normal,
            vertical: AppPadding.small,
          ),
          minimumSize: const Size(0, AppSize.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.buttonRadius),
          ),
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppPadding.inputHorizontal,
          vertical: AppPadding.inputVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
          borderSide: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
          borderSide: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      
      // Text theme - premium typography
      textTheme: TextTheme(
        displayLarge: AppTextStyles.hero,
        displayMedium: AppTextStyles.display,
        displaySmall: AppTextStyles.largeTitle,
        headlineLarge: AppTextStyles.title1,
        headlineMedium: AppTextStyles.title2,
        headlineSmall: AppTextStyles.title3,
        titleLarge: AppTextStyles.headline,
        titleMedium: AppTextStyles.bodyLarge,
        titleSmall: AppTextStyles.body,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.subheadline,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.callout,
        labelSmall: AppTextStyles.footnote,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSize.iconSize,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondaryBackground,
        deleteIconColor: AppColors.textSecondary,
        disabledColor: AppColors.textDisabled,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.small,
          vertical: AppPadding.xs,
        ),
        labelStyle: AppTextStyles.footnote,
        secondaryLabelStyle: AppTextStyles.footnote.copyWith(
          color: Colors.white,
        ),
        brightness: Brightness.light,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.pillRadius),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.largeRadius),
        ),
        backgroundColor: AppColors.surface,
        titleTextStyle: AppTextStyles.title2,
        contentTextStyle: AppTextStyles.body,
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSize.largeRadius),
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
        ),
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
        ),
        textStyle: AppTextStyles.footnote.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.small,
          vertical: AppPadding.xs,
        ),
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.secondaryBackground,
        circularTrackColor: AppColors.secondaryBackground,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.secondaryBackground;
        }),
      ),
      
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
        ),
      ),
      
      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
      ),
      
      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppPadding.normal,
          vertical: AppPadding.small,
        ),
        iconColor: AppColors.textPrimary,
        textColor: AppColors.textPrimary,
        minVerticalPadding: AppPadding.small,
      ),
    );
  }
  
  // Dark theme (optional, for future use)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // Dark theme colors would go here
      scaffoldBackgroundColor: const Color(0xFF0F172A),
    );
  }
}


