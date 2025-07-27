// lib/utils/settings_storage.dart
import 'package:hive_flutter/hive_flutter.dart';

class SettingsStorage {
  static final SettingsStorage _instance = SettingsStorage._internal();
  factory SettingsStorage() => _instance;
  SettingsStorage._internal();

  static const String _boxName = 'settings';
  static const String _darkModeKey = 'darkMode';
  static const String _notificationsKey = 'notifications';
  static const String _biometricsKey = 'biometrics';
  static const String _themeColorKey = 'themeColor';
  static const String _syncFrequencyKey = 'syncFrequency';
  static const String _currencyKey = 'currency';
  static const String _budgetAlertThresholdKey = 'budgetAlertThreshold';
  
  Box<dynamic>? _box;
  
  Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }
  
  // Dark mode settings
  bool getDarkMode() {
    return _box?.get(_darkModeKey, defaultValue: false) ?? false;
  }
  
  Future<void> setDarkMode(bool value) async {
    await _box?.put(_darkModeKey, value);
  }
  
  // Notifications settings
  bool getNotifications() {
    return _box?.get(_notificationsKey, defaultValue: true) ?? true;
  }
  
  Future<void> setNotifications(bool value) async {
    await _box?.put(_notificationsKey, value);
  }
  
  // Biometrics settings
  bool getBiometrics() {
    return _box?.get(_biometricsKey, defaultValue: false) ?? false;
  }
  
  Future<void> setBiometrics(bool value) async {
    await _box?.put(_biometricsKey, value);
  }
  
  // Theme color settings
  int getThemeColor() {
    return _box?.get(_themeColorKey, defaultValue: 0xFF26D07C) ?? 0xFF26D07C;
  }
  
  Future<void> setThemeColor(int value) async {
    await _box?.put(_themeColorKey, value);
  }
  
  // Sync frequency settings (in minutes)
  int getSyncFrequency() {
    return _box?.get(_syncFrequencyKey, defaultValue: 30) ?? 30;
  }
  
  Future<void> setSyncFrequency(int minutes) async {
    await _box?.put(_syncFrequencyKey, minutes);
  }
  
  // Currency settings
  String getCurrency() {
    return _box?.get(_currencyKey, defaultValue: 'USD') ?? 'USD';
  }
  
  Future<void> setCurrency(String currencyCode) async {
    await _box?.put(_currencyKey, currencyCode);
  }
  
  // Budget alert threshold (percentage)
  int getBudgetAlertThreshold() {
    return _box?.get(_budgetAlertThresholdKey, defaultValue: 80) ?? 80;
  }
  
  Future<void> setBudgetAlertThreshold(int percentage) async {
    await _box?.put(_budgetAlertThresholdKey, percentage);
  }
  
  // Clear all settings
  Future<void> clearAll() async {
    await _box?.clear();
  }
}