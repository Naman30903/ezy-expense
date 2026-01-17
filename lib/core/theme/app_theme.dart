import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base Colors
  static const Color primary = Color(0xFF6C63FF); // Modern Purple
  static const Color secondary = Color(0xFF03DAC6); // Teal Accent
  static const Color background = Color(0xFF121212); // Deep Dark Background
  static const Color surface = Color(0xFF1E1E1E); // Card Surface
  static const Color surfaceVariant = Color(0xFF2D2D2D); // Lighter Surface
  static const Color onBackground = Colors.white;
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFFAAAAAA);

  // Functional Colors
  static const Color success = Color(0xFF00E676); // Green
  static const Color error = Color(0xFFCF6679); // Red Pink
  static const Color warning = Color(0xFFFFA726); // Orange
  static const Color info = Color(0xFF29B6F6); // Light Blue

  // Category Colors
  static const Color food = Color(0xFFFF7043); // Deep Orange
  static const Color transport = Color(0xFF42A5F5); // Blue
  static const Color shopping = Color(0xFFAB47BC); // Purple
  static const Color entertainment = Color(0xFFEF5350); // Red
  static const Color health = Color(0xFF26A69A); // Teal
  static const Color bills = Color(0xFF7E57C2); // Deep Purple
  static const Color education = Color(0xFF5C6BC0); // Indigo
  static const Color other = Color(0xFF8D6E63); // Brown

  // Graph/Analytics Palette
  static const List<Color> graphPalette = [
    Color(0xFF6C63FF), // Primary
    Color(0xFF03DAC6), // Secondary
    Color(0xFFFF7043),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFF26A69A),
  ];

  // UI Elements
  static const Color divider = Color(0xFF383838);
  static const Color outline = Color(0xFF484848);
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      error: AppColors.error,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
    ),

    // Card Theme
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8),
    ),

    // Text Theme
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.onBackground,
      displayColor: AppColors.onBackground,
    ).copyWith(
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.onBackground,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        color: AppColors.onBackground,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        color: AppColors.onSurfaceVariant,
      ),
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.onBackground),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        fontFamily: 'Outfit', // Ensure font consistency
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    
    // Input Decoration (TextFields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
    ),
  );
}
