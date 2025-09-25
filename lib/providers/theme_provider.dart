// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Default aman agar tidak terjadi LateInitializationError
  ThemeMode _currentTheme = ThemeMode.light;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeMode get currentTheme => _currentTheme;
  bool get isDark => _currentTheme == ThemeMode.dark;

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIsDark = prefs.getBool('is_dark_theme') ?? false;
    _setTheme(savedIsDark ? ThemeMode.dark : ThemeMode.light, notify: true);
  }

  Future<void> toggleTheme(bool isDark) async {
    _setTheme(isDark ? ThemeMode.dark : ThemeMode.light, notify: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', isDark);
  }

  void _setTheme(ThemeMode mode, {bool notify = false}) {
    if (_currentTheme == mode) return;
    _currentTheme = mode;
    if (notify) notifyListeners();
  }
}
