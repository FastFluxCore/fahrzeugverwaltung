import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();

  SharedPreferences? _prefs;

  // Defaults
  ThemeMode _themeMode = ThemeMode.system;
  String _unit = 'km';
  String _currency = '€';

  ThemeMode get themeMode => _themeMode;
  String get unit => _unit;
  String get currency => _currency;
  bool get isKm => _unit == 'km';
  bool get isEuro => _currency == '€';

  String get unitLabel => isKm ? 'Metrisch (km)' : 'Imperial (mi)';
  String get currencyLabel => isEuro ? 'Euro (€)' : 'Dollar (\$)';
  String get distanceUnit => isKm ? 'km' : 'mi';
  String get volumeUnit => isKm ? 'L' : 'gal';
  String get consumptionUnit => isKm ? 'L/100km' : 'mpg';
  String get pricePerVolumeUnit => '$currency/${isKm ? 'L' : 'gal'}';
  String get themeLabel => switch (_themeMode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Hell',
        ThemeMode.dark => 'Dunkel',
      };

  /// Convert stored km to display distance
  double displayDistance(int km) =>
      isKm ? km.toDouble() : km * 0.621371;

  /// Convert display distance to km for storage
  int storageDistance(double display) =>
      isKm ? display.round() : (display / 0.621371).round();

  /// Convert stored liters to display volume
  double displayVolume(double liters) =>
      isKm ? liters : liters * 0.264172;

  /// Convert display volume to liters for storage
  double storageVolume(double display) =>
      isKm ? display : display / 0.264172;

  /// Format a cost value with currency symbol
  String formatCost(double cost) {
    final formatted = cost.toStringAsFixed(2).replaceAll('.', ',');
    return '$formatted $currency';
  }

  /// Format a distance value with unit
  String formatDistance(int km) {
    final value = displayDistance(km);
    return '${_formatInt(value.round())} $distanceUnit';
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
    _unit = _prefs!.getString('unit') ?? 'km';
    _currency = _prefs!.getString('currency') ?? '€';
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs!.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    _unit = unit;
    await _prefs!.setString('unit', unit);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    await _prefs!.setString('currency', currency);
    notifyListeners();
  }
}
