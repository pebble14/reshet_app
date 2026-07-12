import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModePreference {
  static const String _preferenceKey = 'theme_mode';

  static Future<ThemeMode> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return fromStorageValue(preferences.getString(_preferenceKey));
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static Future<bool> save(ThemeMode themeMode) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.setString(_preferenceKey, toStorageValue(themeMode));
    } catch (_) {
      return false;
    }
  }

  static ThemeMode fromStorageValue(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String toStorageValue(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
  }
}
