import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'state/settings_provider.dart';
import 'ui/main_screen.dart';

class SmagApp extends StatelessWidget {
  const SmagApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'SMAG',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(settings.theme),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainScreen(),
    );
  }

  ThemeData _buildTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.oledDark:
        return _oledDarkTheme();
      case AppTheme.light:
        return _lightTheme();
    }
  }

  // ──────────────── Light Theme ──────────────────

  ThemeData _lightTheme() {
    const sage = Color(0xFF6B8F71);
    const warmWhite = Color(0xFFF5F2ED);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: sage,
      brightness: Brightness.light,
      surface: warmWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: warmWhite,
      textTheme: _textTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: warmWhite,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: sage,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: warmWhite,
        selectedItemColor: sage,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ──────────────── OLED Dark Theme ──────────────

  ThemeData _oledDarkTheme() {
    const sage = Color(0xFF6B8F71);
    const pureBlack = Color(0xFF000000);
    const surface = Color(0xFF0A0A0A);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: sage,
      brightness: Brightness.dark,
      surface: pureBlack,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(surface: pureBlack),
      scaffoldBackgroundColor: pureBlack,
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: pureBlack,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: surface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: sage,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: surface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: pureBlack,
        selectedItemColor: sage,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ──────────────── Typography ───────────────────

  TextTheme _textTheme(Brightness brightness) {
    final color =
        brightness == Brightness.light ? Colors.black87 : Colors.white;

    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(color: color),
      displayMedium: GoogleFonts.playfairDisplay(color: color),
      displaySmall: GoogleFonts.playfairDisplay(color: color),
      headlineLarge: GoogleFonts.playfairDisplay(color: color),
      headlineMedium: GoogleFonts.playfairDisplay(color: color),
      headlineSmall: GoogleFonts.playfairDisplay(color: color),
      titleLarge: GoogleFonts.playfairDisplay(color: color),
      titleMedium: GoogleFonts.inter(color: color),
      titleSmall: GoogleFonts.inter(color: color),
      bodyLarge: GoogleFonts.inter(color: color),
      bodyMedium: GoogleFonts.inter(color: color),
      bodySmall: GoogleFonts.inter(color: color),
      labelLarge: GoogleFonts.inter(color: color),
      labelMedium: GoogleFonts.inter(color: color),
      labelSmall: GoogleFonts.inter(color: color),
    );
  }
}
