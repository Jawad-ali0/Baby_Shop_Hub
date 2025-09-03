import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'isDarkMode';
  static const String _highContrastKey = 'isHighContrast';
  static const String _systemThemeKey = 'useSystemTheme';

  bool _isDark = false;
  bool get isDark => _isDark;
  bool _isHighContrast = false;
  bool get isHighContrast => _isHighContrast;
  bool _useSystemTheme = true;
  bool get useSystemTheme => _useSystemTheme;

  // Get effective theme mode
  bool get effectiveIsDark {
    if (_useSystemTheme) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _isDark;
  }

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    _isHighContrast = prefs.getBool(_highContrastKey) ?? false;
    _useSystemTheme = prefs.getBool(_systemThemeKey) ?? true;
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

  Future<void> toggleSystemTheme() async {
    _useSystemTheme = !_useSystemTheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemThemeKey, _useSystemTheme);
  }

  Future<void> setThemeMode(bool isDark) async {
    _isDark = isDark;
    _useSystemTheme = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDark);
    await prefs.setBool(_systemThemeKey, false);
  }
}
