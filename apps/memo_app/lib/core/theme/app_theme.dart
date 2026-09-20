import 'package:flutter/material.dart';
import 'package:memo/core/theme/app_colors.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.terracotta,
    onPrimary: Colors.white,
    secondary: AppColors.teal,
    onSecondary: Colors.white,
    tertiary: AppColors.gold,
    onTertiary: AppColors.charcoal,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: AppColors.sand,
    onSurface: AppColors.charcoal,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.sand,
    fontFamily: 'Manrope',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.sand,
      foregroundColor: AppColors.charcoal,
      elevation: 0,
      centerTitle: false,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
