// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'business_profile_provider.dart';

class ThemeProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  BusinessProfileProvider? _profileProvider;

  // Default aman agar tidak terjadi LateInitializationError
  ThemeMode _currentTheme = ThemeMode.light;

  ThemeProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null && _profileProvider != null) {
        _loadThemeFromProfile();
      } else {
        _setTheme(ThemeMode.light, notify: true);
      }
    });
  }

  void setProfileProvider(BusinessProfileProvider provider) {
    _profileProvider = provider;
    _loadThemeFromProfile();
    // Listen to profile changes
    provider.addListener(_loadThemeFromProfile);
  }

  ThemeMode get currentTheme => _currentTheme;
  bool get isDark => _currentTheme == ThemeMode.dark;

  Future<void> _loadThemeFromProfile() async {
    if (_profileProvider == null) {
      _setTheme(ThemeMode.light, notify: true);
      return;
    }

    final isDark = _profileProvider!.isDarkTheme;
    _setTheme(isDark ? ThemeMode.dark : ThemeMode.light, notify: true);
  }

  Future<void> toggleTheme(bool isDark) async {
    _setTheme(isDark ? ThemeMode.dark : ThemeMode.light, notify: true);

    // Save to Firestore via BusinessProfileProvider
    if (_profileProvider != null && _auth.currentUser != null) {
      try {
        await _profileProvider!.updateTheme(isDark);
      } catch (e) {
        debugPrint('Error saving theme: $e');
        // Revert on error
        _setTheme(isDark ? ThemeMode.light : ThemeMode.dark, notify: true);
      }
    }
  }

  void _setTheme(ThemeMode mode, {bool notify = false}) {
    if (_currentTheme == mode) return;
    _currentTheme = mode;
    if (notify) notifyListeners();
  }
}
