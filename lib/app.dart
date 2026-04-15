import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smag/l10n/app_localizations.dart';

import 'ui/recipe_home_screen.dart';

class SmagApp extends StatelessWidget {
  const SmagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMAG',
      debugShowCheckedModeBanner: false,
      // i18n
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Theme — Scandinavian minimalism
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6B8F71), // sage
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F2ED),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF5F2ED),
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: const Color(0xFF2D3436),
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3436),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6B8F71),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
          ),
        ),
      ),
      home: const RecipeHomeScreen(),
    );
  }
}
