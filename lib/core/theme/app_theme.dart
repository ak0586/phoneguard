import 'package:flutter/material.dart';

/// Premium dark red/black theme for the Lost Phone Finder app
class AppTheme {
  AppTheme._();

  // ─── Color Palette ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE53935); // Deep red
  static const Color primaryDark = Color(0xFFB71C1C); // Darker red
  static const Color primaryLight = Color(0xFFFF6F60); // Lighter red
  static const Color background = Color(0xFF0A0A0F); // Almost black
  static const Color surface = Color(0xFF13131A); // Dark card surface
  static const Color surfaceVariant = Color(0xFF1C1C26); // Slightly lighter
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFE8E8F0);
  static const Color onSurface = Color(0xFFCCCCDD);
  static const Color accent = Color(0xFFFF5252); // Bright red accent
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color divider = Color(0xFF2A2A38);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF13131A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C26), Color(0xFF13131A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── ThemeData ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: primary,
      primaryContainer: primaryDark,
      secondary: accent,
      surface: surface,
      onPrimary: onPrimary,
      onSecondary: onPrimary,
      onSurface: onSurface,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: onBackground),
        titleTextStyle: TextStyle(
          color: onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.4);
          }
          return Colors.grey.shade800;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: onSurface,
        iconColor: onSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: onBackground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle: const TextStyle(color: onSurface),
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      iconTheme: const IconThemeData(color: onSurface),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
          color: onBackground,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(color: onSurface, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: Colors.grey),
        labelLarge: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: onSurface),
        labelSmall: TextStyle(color: Colors.grey),
      ),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primary,
      primaryContainer: Color(0xFFE53935),
      secondary: accent,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF13131A),
      error: error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FE), // Premium light blue tint
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FE),
        foregroundColor: Color(0xFF13131A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF13131A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blueGrey.shade50, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: Colors.blueGrey.shade50, thickness: 1),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: Color(0xFF13131A),
        iconColor: Color(0xFF13131A),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return Colors.grey.shade300;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF13131A),
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF13131A),
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF13131A),
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: Color(0xFF2D2D3A)),
        bodyMedium: TextStyle(color: Color(0xFF4A4A58)),
        bodySmall: TextStyle(color: Color(0xFF757585)),
      ),
    );
  }
}
