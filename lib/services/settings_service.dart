import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();

  SharedPreferences? _prefs;

  // Defaults
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  String get currency => '€';
  String get distanceUnit => 'km';
  String get volumeUnit => 'L';
  String get pricePerVolumeUnit => '€/L';
  String get themeLabel => switch (_themeMode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Hell',
        ThemeMode.dark => 'Dunkel',
      };

  /// Format a cost value with currency symbol
  String formatCost(double cost) {
    final formatted = cost.toStringAsFixed(2).replaceAll('.', ',');
    return '$formatted €';
  }

  /// Format a distance value with unit
  String formatDistance(int km) {
    return '${_formatInt(km)} km';
  }

  String _formatInt(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[_prefs!.getInt('themeMode') ?? 0];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs!.setInt('themeMode', mode.index);
    notifyListeners();
  }
}
