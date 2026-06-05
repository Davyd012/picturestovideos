import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF2EF2FF),
      onPrimary: Color(0xFF001F24),
      primaryContainer: Color(0xFF147DFF),
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondary: Color(0xFFBDA7FF),
      onSecondary: Color(0xFF241A49),
      secondaryContainer: Color(0xFF3D2D73),
      onSecondaryContainer: Color(0xFFE9DDFF),
      surface: Color(0xFF050722),
      onSurface: Color(0xFFF2F4FF),
      surfaceContainerHighest: Color(0xFF171A3F),
      onSurfaceVariant: Color(0xFFC5C7D8),
      outline: Color(0xFF8F92A8),
      outlineVariant: Color(0xFF42465F),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
      ),
    );
  }
}
