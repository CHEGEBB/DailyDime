// lib/services/settings_storage.dart
import 'package:hive_flutter/hive_flutter.dart';

class SettingsStorage {
  static final SettingsStorage _instance = SettingsStorage._internal();
  factory SettingsStorage() => _instance;
  
  SettingsStorage._internal();
  
  static const String _settingsBoxName = 'settings';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _biometricsKey = 'biometrics_enabled';
  
  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_settingsBoxName);
  }
  
  // Get Hive box
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(_settingsBoxName);
  
  // Notifications settings
  Future<void> setNotificationsEnabled(bool value) async {
    await _settingsBox.put(_notificationsKey, value);
  }
  
  Future<bool> getNotificationsEnabled() async {
    return _settingsBox.get(_notificationsKey, defaultValue: true);
  }
  
  // Dark mode settings
  Future<void> setDarkModeEnabled(bool value) async {
    await _settingsBox.put(_darkModeKey, value);
  }
  
  Future<bool> getDarkModeEnabled() async {
    return _settingsBox.get(_darkModeKey, defaultValue: false);
  }
  
  // Biometrics settings
  Future<void> setBiometricsEnabled(bool value) async {
    await _settingsBox.put(_biometricsKey, value);
  }
  
  Future<bool> getBiometricsEnabled() async {
    return _settingsBox.get(_biometricsKey, defaultValue: false);
  }
  
  // Clear all settings (for logout)
  Future<void> clearSettings() async {
    await _settingsBox.clear();
  }
}