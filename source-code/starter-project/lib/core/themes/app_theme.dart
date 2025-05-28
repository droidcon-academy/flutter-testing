import 'package:flutter/material.dart';

class ThemeColors {
  static const Color primary = Color(0xFFFF5722);
  static const Color secondary = Color(0xFFFFB74D);
  
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Colors.red;
  static const Color favorite = Colors.red;
  static const Color bookmark = Colors.orange;
  
  static const Color titleText = Colors.black87;
  static const Color bodyText = Colors.black54;
  
  static const Color activeNav = primary;
  static const Color inactiveNav = Colors.grey;
  
  static const Color darkCardBackground = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF404040);
  static const Color darkTitleText = Colors.white;
  static const Color darkBodyText = Colors.white70;
}

class AppTheme {
  static final _borderRadius = BorderRadius.circular(12.0);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ThemeColors.primary,
      secondary: ThemeColors.secondary,
      error: ThemeColors.error,
      surface: ThemeColors.cardBackground,
    ),
    
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      color: ThemeColors.cardBackground,
    ),
    
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: ThemeColors.activeNav,
      unselectedItemColor: ThemeColors.inactiveNav,
      type: BottomNavigationBarType.fixed,
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ThemeColors.titleText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ThemeColors.titleText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: ThemeColors.bodyText,
      ),
    ),
    
    dividerTheme: const DividerThemeData(
      color: ThemeColors.divider,
      thickness: 1,
    ),
    
    iconTheme: const IconThemeData(
      color: ThemeColors.primary,
      size: 24,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: ThemeColors.primary,
      secondary: ThemeColors.secondary,
      error: ThemeColors.error,
      surface: ThemeColors.darkCardBackground,
    ),
    
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      color: ThemeColors.darkCardBackground,
    ),
    
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: ThemeColors.activeNav,
      unselectedItemColor: ThemeColors.inactiveNav,
      type: BottomNavigationBarType.fixed,
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ThemeColors.darkTitleText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ThemeColors.darkTitleText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: ThemeColors.darkBodyText,
      ),
    ),
    
    dividerTheme: const DividerThemeData(
      color: ThemeColors.darkDivider,
      thickness: 1,
    ),
    
    iconTheme: const IconThemeData(
      color: ThemeColors.primary,
      size: 24,
    ),
  );
}