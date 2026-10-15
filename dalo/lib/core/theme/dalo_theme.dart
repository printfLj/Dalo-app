import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class DaloPalette {
  static const ink = Color(0xFF171717);
  static const canvas = Color(0xFFF7F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF77736E);
  static const outline = Color(0xFFE8E5DF);
  static const accent = Color(0xFFE86B4A);
  static const accentSoft = Color(0xFFFFE9E1);
  static const success = Color(0xFF267A55);
  static const successSoft = Color(0xFFE5F3EB);
}

abstract final class DaloTheme {
  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme();
    const colors = ColorScheme.light(
      primary: DaloPalette.ink,
      onPrimary: Colors.white,
      secondary: DaloPalette.accent,
      onSecondary: Colors.white,
      surface: DaloPalette.surface,
      onSurface: DaloPalette.ink,
      error: Color(0xFFB42318),
      outline: DaloPalette.outline,
      surfaceContainerHighest: Color(0xFFF0EEEA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: DaloPalette.canvas,
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 38,
          height: 1.08,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: DaloPalette.ink,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 32,
          height: 1.12,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
          color: DaloPalette.ink,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 26,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
          color: DaloPalette.ink,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: DaloPalette.ink,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DaloPalette.ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DaloPalette.ink,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.45,
          color: DaloPalette.ink,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          color: DaloPalette.ink,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          height: 1.4,
          color: DaloPalette.muted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DaloPalette.ink,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DaloPalette.muted,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: DaloPalette.muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DaloPalette.canvas,
        foregroundColor: DaloPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: DaloPalette.ink,
        ),
        iconTheme: const IconThemeData(color: DaloPalette.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DaloPalette.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DaloPalette.ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: DaloPalette.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DaloPalette.accent,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DaloPalette.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: DaloPalette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: DaloPalette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: DaloPalette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFB42318)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: DaloPalette.muted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: DaloPalette.muted, fontSize: 14),
      ),
      cardTheme: CardTheme(
        color: DaloPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: DaloPalette.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: DaloPalette.outline,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DaloPalette.surface,
        elevation: 0,
        indicatorColor: DaloPalette.accentSoft,
        labelTextStyle:
            WidgetStateProperty.resolveWith((states) => GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                )),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DaloPalette.ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
