import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider extends ChangeNotifier {
  bool _isLargeFont = false;

  bool get isLargeFont => _isLargeFont;

  double get fontSize => _isLargeFont ? 18.0 : 14.0;

  FontProvider() {
    _loadFontSize();
  }

  void toggleFont(bool value) async {
    _isLargeFont = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('font_besar', _isLargeFont);
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _isLargeFont = prefs.getBool('font_besar') ?? false;
    notifyListeners();
  }
}
