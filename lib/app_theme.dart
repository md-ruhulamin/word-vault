// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep navy + electric teal palette
  static const Color bg = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color card = Color(0xFF1C2333);
  static const Color accent = Color(0xFF00E5C3);
  static const Color accentSoft = Color(0xFF00B49A);
  static const Color gold = Color(0xFFFFD166);
  static const Color rose = Color(0xFFFF6B6B);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color border = Color(0xFF30363D);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: gold,
          surface: surface,
          error: rose,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        cardTheme: CardThemeData(
          color: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
          elevation: 0,
        ),
      );
}
