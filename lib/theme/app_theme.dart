import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build() {
    // Force LIGHT to match design previews exactly
    final base = ThemeData(
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF0E63F6),
      useMaterial3: true,
    );

    const radius = 16.0;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Colors.black12),
    );

    return base.copyWith(
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFF7F7F9), // stable neutral card bg
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: base.colorScheme.primary, width: 1.6),
        ),
        labelStyle: const TextStyle(color: Colors.black87),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
    );
  }
}
