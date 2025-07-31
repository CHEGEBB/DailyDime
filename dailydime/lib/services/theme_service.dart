// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  // Light theme colors
  static const Color _lightPrimary = Color(0xFF26D07C); // Emerald
  static const Color _lightSecondary = Color(0xFF0AB3B8); // Teal
  static const Color _lightAccent = Color(0xFF68EFC6); // Light emerald
  static const Color _lightBackground = Color(0xFFF8F9FA); // Light gray
  static const Color _lightSurface = Colors.white;
  static const Color _lightCard = Colors.white;
  
  // Dark theme colors - Deep blue/purple palette that complements emerald
  static const Color _darkPrimary = Color(0xFF26D07C); // Keep emerald for consistency
  static const Color _darkSecondary = Color(0xFF4F46E5); // Indigo
  static const Color _darkAccent = Color(0xFF68EFC6); // Light emerald accent
  static const Color _darkBackground = Color(0xFF0F172A); // Very dark blue
  static const Color _darkSurface = Color(0xFF1E293B); // Dark blue-gray
  static const Color _darkCard = Color(0xFF1F2937); // Darker blue-gray
  
  ThemeService() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
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
  
  // Theme data getters
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: _createMaterialColor(_lightPrimary),
    primaryColor: _lightPrimary,
    scaffoldBackgroundColor: _lightBackground,
    cardColor: _lightCard,
    dividerColor: Colors.grey[200],
    
    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      secondary: _lightSecondary,
      tertiary: _lightAccent,
      surface: _lightSurface,
      background: _lightBackground,
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1F2937),
      onBackground: Color(0xFF1F2937),
      onError: Colors.white,
    ),
    
    // App bar theme
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
    
    // Card theme
    cardTheme: CardThemeData(
      color: _lightCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _lightPrimary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimary,
        side: const BorderSide(color: _lightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    // Input decoration theme
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
        borderSide: const BorderSide(color: _lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _lightPrimary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Color(0xFF374151)),
      bodyMedium: TextStyle(color: Color(0xFF374151)),
      bodySmall: TextStyle(color: Color(0xFF6B7280)),
      labelLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Color(0xFF6B7280)),
      labelSmall: TextStyle(color: Color(0xFF9CA3AF)),
    ),
  );
  
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: _createMaterialColor(_darkPrimary),
    primaryColor: _darkPrimary,
    scaffoldBackgroundColor: _darkBackground,
    cardColor: _darkCard,
    dividerColor: Colors.grey[700],
    
    // Color scheme
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      secondary: _darkSecondary,
      tertiary: _darkAccent,
      surface: _darkSurface,
      background: _darkBackground,
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    
    // App bar theme
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
    
    // Card theme
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _darkPrimary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        side: const BorderSide(color: _darkPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    // Input decoration theme
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
        borderSide: const BorderSide(color: _darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _darkPrimary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
      bodyMedium: TextStyle(color: Color(0xFFE5E7EB)),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Color(0xFF9CA3AF)),
      labelSmall: TextStyle(color: Color(0xFF6B7280)),
    ),
  );
  
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
  
  // FIXED: All color getters with proper cardColor
  Color get primaryColor => _isDarkMode ? _darkPrimary : _lightPrimary;
  Color get secondaryColor => _isDarkMode ? _darkSecondary : _lightSecondary;
  Color get accentColor => _isDarkMode ? _darkAccent : _lightAccent;
  Color get backgroundColor => _isDarkMode ? _darkBackground : _lightBackground;
  Color get scaffoldColor => _isDarkMode ? _darkBackground : _lightBackground;
  Color get surfaceColor => _isDarkMode ? _darkSurface : _lightSurface;
  Color get cardColor => _isDarkMode ? _darkCard : _lightCard; // THIS WAS MISSING!
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