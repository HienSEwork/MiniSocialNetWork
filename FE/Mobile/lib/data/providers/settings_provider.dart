import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _restore();
  }

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('vi');
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    _themeMode = saved == 'dark'
        ? ThemeMode.dark
        : saved == 'light'
        ? ThemeMode.light
        : ThemeMode.system;
    _locale = prefs.getString('language_code') == 'en'
        ? const Locale('en')
        : const Locale('vi');
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'vi' && languageCode != 'en') return;
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', dark ? 'dark' : 'light');
  }
}
