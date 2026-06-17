import 'package:flutter/material.dart';

/// Light and dark [ThemeData] for AmbientNav. The palette echoes the ambient
/// LED-strip aesthetic (deep night background, amber accent).
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFFFFB300); // amber accent

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E0F14),
      );
}
