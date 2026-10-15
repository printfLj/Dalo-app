import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/auth/auth_gate.dart';

class DaloApp extends StatelessWidget {
  const DaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daló',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AuthGate(),
    );
  }

  ThemeData _buildTheme() {
    // Sketch-inspired black-and-white system
    const black = Color(0xFF111111);
    const white = Color(0xFFFFFFFF);
    const gray = Color(0xFF888888);
    const lightGray = Color(0xFFF4F4F4);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: black,
        onPrimary: white,
        secondary: gray,
        onSecondary: white,
        surface: white,
        onSurface: black,
        outline: black,
        surfaceContainerHighest: lightGray,
      ),
      scaffoldBackgroundColor: white,
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.caveat(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: black,
        ),
        iconTheme: const IconThemeData(color: black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: black, width: 1.5),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: black, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: black, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: black.withOpacity(0.35), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: gray, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: gray, fontSize: 14),
      ),
      cardTheme: CardTheme(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: black,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        side: const BorderSide(color: Color(0xFFCCCCCC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.caveat(fontSize: 48, fontWeight: FontWeight.w700, color: black),
        displayMedium: GoogleFonts.caveat(fontSize: 36, fontWeight: FontWeight.w700, color: black),
        displaySmall: GoogleFonts.caveat(fontSize: 28, fontWeight: FontWeight.w700, color: black),
        headlineLarge: GoogleFonts.caveat(fontSize: 26, fontWeight: FontWeight.w700, color: black),
        headlineMedium: GoogleFonts.caveat(fontSize: 22, fontWeight: FontWeight.w600, color: black),
        headlineSmall: GoogleFonts.caveat(fontSize: 20, fontWeight: FontWeight.w600, color: black),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: black),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: black),
        titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: black),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: black),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: black),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: gray),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: black),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: gray),
        labelSmall: GoogleFonts.inter(fontSize: 11, color: gray),
      ),
    );
  }
}
