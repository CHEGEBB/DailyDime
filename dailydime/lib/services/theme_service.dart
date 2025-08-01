// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  static const String _primaryColorKey = 'primary_color';
  static const String _secondaryColorKey = 'secondary_color';
  static const String _accentColorKey = 'accent_color';
  static const String _textSizeKey = 'text_size';
  
  bool _isDarkMode = false;
  double _textScale = 1.0;
  
  // Custom colors
  Color _customPrimaryColor = const Color(0xFF26D07C);
  Color _customSecondaryColor = const Color(0xFF0AB3B8);
  Color _customAccentColor = const Color(0xFF68EFC6);
  
  // Default theme colors
  static const Color _defaultLightPrimary = Color(0xFF26D07C);
  static const Color _defaultLightSecondary = Color(0xFF0AB3B8);
  static const Color _defaultLightAccent = Color(0xFF68EFC6);
  static const Color _defaultDarkPrimary = Color(0xFF26D07C);
  static const Color _defaultDarkSecondary = Color(0xFF4F46E5);
  static const Color _defaultDarkAccent = Color(0xFF68EFC6);
  
  // Base theme colors
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _lightSurface = Colors.white;
  static const Color _lightCard = Colors.white;
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkCard = Color(0xFF1F2937);
  
  bool get isDarkMode => _isDarkMode;
  double get textScale => _textScale;
  
  ThemeService() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _textScale = prefs.getDouble(_textSizeKey) ?? 1.0;
    
    // Load custom colors
    final primaryColorValue = prefs.getInt(_primaryColorKey);
    final secondaryColorValue = prefs.getInt(_secondaryColorKey);
    final accentColorValue = prefs.getInt(_accentColorKey);
    
    if (primaryColorValue != null) {
      _customPrimaryColor = Color(primaryColorValue);
    }
    if (secondaryColorValue != null) {
      _customSecondaryColor = Color(secondaryColorValue);
    }
    if (accentColorValue != null) {
      _customAccentColor = Color(accentColorValue);
    }
    
    _updateSystemUI();
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    _updateSystemUI();
    notifyListeners();
  }
  
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
      _updateSystemUI();
      notifyListeners();
    }
  }
  
  Future<void> updateTextScale(double scale) async {
    _textScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, scale);
    notifyListeners();
  }
  
  Future<void> updatePrimaryColor(Color color) async {
    _customPrimaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.value);
    notifyListeners();
  }
  
  Future<void> updateSecondaryColor(Color color) async {
    _customSecondaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_secondaryColorKey, color.value);
    notifyListeners();
  }
  
  Future<void> updateAccentColor(Color color) async {
    _customAccentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);
    notifyListeners();
  }
  
  Future<void> updateAllColors({
    required Color primary,
    required Color secondary,
    required Color accent,
  }) async {
    _customPrimaryColor = primary;
    _customSecondaryColor = secondary;
    _customAccentColor = accent;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, primary.value);
    await prefs.setInt(_secondaryColorKey, secondary.value);
    await prefs.setInt(_accentColorKey, accent.value);
    
    notifyListeners();
  }
  
  Future<void> resetToDefaultColors() async {
    _customPrimaryColor = _isDarkMode ? _defaultDarkPrimary : _defaultLightPrimary;
    _customSecondaryColor = _isDarkMode ? _defaultDarkSecondary : _defaultLightSecondary;
    _customAccentColor = _isDarkMode ? _defaultDarkAccent : _defaultLightAccent;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_primaryColorKey);
    await prefs.remove(_secondaryColorKey);
    await prefs.remove(_accentColorKey);
    
    notifyListeners();
  }
  
  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _isDarkMode ? _darkBackground : _lightBackground,
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }
  
  // Helper method to create MaterialColor from Color
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(color.value, swatch);
  }
  
  // Theme data getters
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: _createMaterialColor(_customPrimaryColor),
    primaryColor: _customPrimaryColor,
    scaffoldBackgroundColor: _lightBackground,
    cardColor: _lightCard,
    dividerColor: Colors.grey[200],
    
    colorScheme: ColorScheme.light(
      primary: _customPrimaryColor,
      secondary: _customSecondaryColor,
      tertiary: _customAccentColor,
      surface: _lightSurface,
      background: _lightBackground,
      error: const Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1F2937),
      onBackground: const Color(0xFF1F2937),
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1F2937),
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: Color(0xFF1F2937),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _lightCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _customPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _customPrimaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _customPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _customPrimaryColor,
        side: BorderSide(color: _customPrimaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _customPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _customPrimaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    textTheme: TextTheme(
      displayLarge: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 32 * _textScale),
      displayMedium: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 28 * _textScale),
      displaySmall: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 24 * _textScale),
      headlineLarge: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 22 * _textScale),
      headlineMedium: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 20 * _textScale),
      headlineSmall: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.w600, fontSize: 18 * _textScale),
      titleLarge: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.w600, fontSize: 16 * _textScale),
      titleMedium: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.w500, fontSize: 14 * _textScale),
      titleSmall: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.w500, fontSize: 12 * _textScale),
      bodyLarge: TextStyle(color: const Color(0xFF374151), fontSize: 16 * _textScale),
      bodyMedium: TextStyle(color: const Color(0xFF374151), fontSize: 14 * _textScale),
      bodySmall: TextStyle(color: const Color(0xFF6B7280), fontSize: 12 * _textScale),
      labelLarge: TextStyle(color: const Color(0xFF1F2937), fontWeight: FontWeight.w500, fontSize: 14 * _textScale),
      labelMedium: TextStyle(color: const Color(0xFF6B7280), fontSize: 12 * _textScale),
      labelSmall: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 10 * _textScale),
    ),
  );
  
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: _createMaterialColor(_customPrimaryColor),
    primaryColor: _customPrimaryColor,
    scaffoldBackgroundColor: _darkBackground,
    cardColor: _darkCard,
    dividerColor: Colors.grey[700],
    
    colorScheme: ColorScheme.dark(
      primary: _customPrimaryColor,
      secondary: _customSecondaryColor,
      tertiary: _customAccentColor,
      surface: _darkSurface,
      background: _darkBackground,
      error: const Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _customPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _customPrimaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _customPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _customPrimaryColor,
        side: BorderSide(color: _customPrimaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D3748),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _customPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _customPrimaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32 * _textScale),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28 * _textScale),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24 * _textScale),
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22 * _textScale),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20 * _textScale),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18 * _textScale),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16 * _textScale),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14 * _textScale),
      titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12 * _textScale),
      bodyLarge: TextStyle(color: const Color(0xFFE5E7EB), fontSize: 16 * _textScale),
      bodyMedium: TextStyle(color: const Color(0xFFE5E7EB), fontSize: 14 * _textScale),
      bodySmall: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 12 * _textScale),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14 * _textScale),
      labelMedium: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 12 * _textScale),
      labelSmall: TextStyle(color: const Color(0xFF6B7280), fontSize: 10 * _textScale),
    ),
  );
  
  // Color getters
  Color get primaryColor => _customPrimaryColor;
  Color get secondaryColor => _customSecondaryColor;
  Color get accentColor => _customAccentColor;
  Color get backgroundColor => _isDarkMode ? _darkBackground : _lightBackground;
  Color get scaffoldColor => _isDarkMode ? _darkBackground : _lightBackground;
  Color get surfaceColor => _isDarkMode ? _darkSurface : _lightSurface;
  Color get cardColor => _isDarkMode ? _darkCard : _lightCard;
  Color get textColor => _isDarkMode ? Colors.white : const Color(0xFF1F2937);
  Color get subtextColor => _isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF6B7280);
  Color get errorColor => _isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
  
  // Status colors that work in both themes
  Color get successColor => const Color(0xFF10B981);
  Color get warningColor => const Color(0xFFF59E0B);
  Color get infoColor => const Color(0xFF3B82F6);
  
  // Gradient getters
  LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );
  
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: _isDarkMode 
        ? [_darkBackground, const Color(0xFF1E293B)]
        : [_lightBackground, Colors.grey[50]!],
  );
}