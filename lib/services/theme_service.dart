import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'isDarkMode';
  static const String _highContrastKey = 'isHighContrast';
  bool _isDark = false;
  bool get isDark => _isDark;
  bool _isHighContrast = false;
  bool get isHighContrast => _isHighContrast;

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    _isHighContrast = prefs.getBool(_highContrastKey) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    await toggleDarkMode();
  }

  Future<void> toggleDarkMode() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDark);
  }

  Future<void> toggleHighContrast() async {
    _isHighContrast = !_isHighContrast;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, _isHighContrast);
  }
}
