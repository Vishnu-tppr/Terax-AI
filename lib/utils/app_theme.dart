import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4CAF50); // Green
  static const Color accentColor = Color(0xFF8BC34A); // Light Green
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Grey
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textColor = Color(0xFF212121); // Dark Grey
  static const Color lightTextColor = Color(0xFF757575); // Medium Grey
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color warningColor = Color(0xFFFFC107); // Amber
  static const Color infoColor = Color(0xFF2196F3); // Blue
  static const Color successColor = Color(0xFF4CAF50); // Green

  // Additional colors based on diagnostics
  static const Color neutral800 = Color(0xFF212121);
  static const Color neutral700 = Color(0xFF424242);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA); // Added neutral50
  static const Color safeStateGreen = Color(0xFF4CAF50);
  static const Color statusBlue = Color(0xFF2196F3);
  static const Color primaryEmergency = Color(0xFFF44336);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryRed = Color(0xFFF44336);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color lightTextSecondary = Color(0xFF9E9E9E);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    hintColor: accentColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: textColor, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(
          color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(
          color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(
          color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textColor, fontSize: 18),
      titleLarge: TextStyle(color: textColor, fontSize: 16),
      bodyLarge: TextStyle(color: textColor, fontSize: 14),
      bodyMedium: TextStyle(color: lightTextColor, fontSize: 12),
      labelLarge: TextStyle(color: Colors.white, fontSize: 14),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.withAlpha(51),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: lightTextColor),
      hintStyle: TextStyle(color: lightTextColor.withAlpha(178)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: accentColor,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
    ),
    dividerColor: Colors.grey,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    hintColor: accentColor,
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark Grey
    cardColor: const Color(0xFF1E1E1E), // Darker Grey
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(
          color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontSize: 18),
      titleLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyLarge: TextStyle(color: Colors.white70, fontSize: 14),
      bodyMedium: TextStyle(color: Colors.white54, fontSize: 12),
      labelLarge: TextStyle(color: Colors.white, fontSize: 14),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.withAlpha(51),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white54.withAlpha(178)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: accentColor,
      contentTextStyle: const TextStyle(color: Colors.black),
      actionTextColor: primaryColor,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.black,
    ),
    iconTheme: const IconThemeData(
      color: accentColor,
    ),
    dividerColor: Colors.grey,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentColor,
    ),
  );
}