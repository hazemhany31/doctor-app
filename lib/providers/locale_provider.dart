
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.system;

  static const String _prefKeyLang  = 'language_code';
  static const String _prefKeyTheme = 'theme_mode';

  Locale    get locale    => _locale;
  ThemeMode get themeMode => _themeMode;

  /// true when the effective appearance is dark (manual or system)
  bool get isDarkMode =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  LocaleProvider() {
    _loadPrefs();
  }

  // ─── Load ────────────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final lang = prefs.getString(_prefKeyLang);
    if (lang != null) _locale = Locale(lang);

    final themeStr = prefs.getString(_prefKeyTheme);
    _themeMode = switch (themeStr) {
      'light'  => ThemeMode.light,
      'dark'   => ThemeMode.dark,
      _        => ThemeMode.system,
    };

    notifyListeners();
  }

  // ─── Setters ─────────────────────────────────────────────────────────────
  Future<void> setLocale(Locale locale) async {
    if (!['en', 'ar'].contains(locale.languageCode)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLang, locale.languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.dark   => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefKeyTheme, str);
    notifyListeners();
  }

  Future<void> clearLocale() async {
    _locale = const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyLang);
    notifyListeners();
  }
}
