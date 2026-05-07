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
            return primary.withOpacity(0.4);
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
        unselectedItemColor: Color(0xFFAAAAAB), // Brighter grey for unselected
        selectedLabelStyle: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        selectedIconTheme: IconThemeData(size: 28, color: primary),
        unselectedIconTheme: IconThemeData(size: 24, color: Color(0xFFAAAAAB)),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
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
    const Color lightBackground = Color(0xFFFBFBFF);
    const Color lightSurface = Colors.white;
    const Color lightOnSurface = Color(0xFF1A1A2E);
    const Color lightDivider = Color(0xFFEEEEF5);
    const Color lightHeading = Color(0xFF0F0F1A);

    const colorScheme = ColorScheme.light(
      primary: primary,
      primaryContainer: primaryDark,
      secondary: accent,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightOnSurface,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightHeading,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightHeading,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightDivider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F1F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF757585)),
        hintStyle: const TextStyle(color: Color(0xFF9E9EAE)),
        prefixIconColor: const Color(0xFF757585),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightHeading, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(color: lightHeading, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: lightHeading, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: lightHeading, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: Color(0xFF2D2D3A), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF4A4A58), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFF757585), fontSize: 12),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF4A4A58)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightHeading,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
