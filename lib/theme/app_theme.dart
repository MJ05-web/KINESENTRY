import 'package:flutter/material.dart';

class AppThemeColors {
  const AppThemeColors._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? const Color(0xFF061120) : const Color(0xFFF4F7FB);

  static Color panel(BuildContext context) =>
      isDark(context) ? const Color(0xCC12213A) : const Color(0xD9FFFFFF);

  static Color panelAlt(BuildContext context) =>
      isDark(context) ? const Color(0xCC0A1730) : const Color(0xE8EEF5FF);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0x33D7E3FF) : const Color(0xCCD9E2EF);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF8FBFF) : const Color(0xFF0F172A);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFAFBED8) : const Color(0xFF526072);

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? const Color(0xFF7F92B2) : const Color(0xFF7B8798);

  static Color accent(BuildContext context) =>
      isDark(context) ? const Color(0xFF6AD4FF) : const Color(0xFF1E78FF);

  static Color accentSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF76F2C2) : const Color(0xFF10B981);

  static Color glow(BuildContext context) =>
      isDark(context) ? const Color(0xFF7C5CFF) : const Color(0xFF8AB4FF);

  static Color success(BuildContext context) => const Color(0xFF22C55E);
  static Color warning(BuildContext context) => const Color(0xFFF59E0B);
  static Color danger(BuildContext context) => const Color(0xFFEF4444);
}

class AppThemes {
  const AppThemes._();

  static ThemeData dark() {
    const seed = Color(0xFF2563EB);
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF061120),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF111827),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF111C31),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xCC08111D),
        selectedItemColor: Color(0xFF5AA0FF),
        unselectedItemColor: Color(0xFF7F92B2),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
      ),
      cardColor: const Color(0xCC12213A),
      dividerColor: const Color(0x33D7E3FF),
      elevatedButtonTheme: _buttonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      inputDecorationTheme: _inputTheme(
        fillColor: const Color(0xB30C1528),
        textColor: Colors.white,
        borderColor: const Color(0x335AA0FF),
        labelColor: const Color(0xFFAFBED8),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData light() {
    const seed = Color(0xFF2563EB);
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF111827),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xD9FFFFFF),
        selectedItemColor: Color(0xFF2563EB),
        unselectedItemColor: Color(0xFF7B8798),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
      ),
      cardColor: const Color(0xD9FFFFFF),
      dividerColor: const Color(0xCCD9E2EF),
      elevatedButtonTheme: _buttonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      inputDecorationTheme: _inputTheme(
        fillColor: const Color(0xF8FFFFFF),
        textColor: const Color(0xFF0F172A),
        borderColor: const Color(0xFFD2DEEC),
        labelColor: const Color(0xFF526072),
      ),
      useMaterial3: true,
    );
  }

  static ElevatedButtonThemeData _buttonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0x667B8798)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fillColor,
    required Color textColor,
    required Color borderColor,
    required Color labelColor,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: borderColor),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: labelColor),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: textColor.withValues(alpha: .72), width: 1.4),
      ),
      border: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }
}
