import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('pantrymatch_theme') ?? 'Light';

      _mode = switch (saved) {
        'Dark' => ThemeMode.dark,
        'System' => ThemeMode.system,
        _ => ThemeMode.light,
      };
    } catch (_) {
      _mode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();

    final value = switch (mode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pantrymatch_theme', value);
  }

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFBF6EC),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8813A),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF3B6D11),
          secondary: const Color(0xFFE8813A),
          surface: Colors.white,
          onSurface: const Color(0xFF3A3226),
          outline: const Color(0xFFE4D9C3),
        ),
    cardTheme: const CardThemeData(color: Colors.white, elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF151A16),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8813A),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFB8D99A),
          secondary: const Color(0xFFFFB77F),
          surface: const Color(0xFF202720),
          onSurface: const Color(0xFFF3F1E8),
          outline: const Color(0xFF3B483D),
        ),
    cardTheme: const CardThemeData(color: Color(0xFF202720), elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF202720),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
