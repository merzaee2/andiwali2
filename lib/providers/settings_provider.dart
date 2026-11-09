import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _isInitialized = false;
  bool _isAppLockEnabled = false;


  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;
  bool get isAppLockEnabled => _isAppLockEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeString = prefs.getString('theme_mode');
    if (themeString == 'light') _themeMode = ThemeMode.light;
    if (themeString == 'dark') _themeMode = ThemeMode.dark;

    final langCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(langCode);

    _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> changeLanguage(String langCode) async {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
  }

  Future<void> toggleAppLock(bool enabled) async {
    _isAppLockEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', enabled);
  }

  void forceLock() {
    if (_isAppLockEnabled) {
      notifyListeners();
    }
  }

}