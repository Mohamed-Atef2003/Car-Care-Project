import 'package:flutter/material.dart';

class AppColors {
  // Light gray background
  static const Color background = Color(0xFFECECEC);
  
  // Pure white
  static const Color white = Color(0xFFFFFFFF);
  
  // Medium gray for secondary text
  static const Color gray = Color(0xFFA3A3A3);
  
  // Dark gray/black for primary text
  static const Color textPrimary = Color(0xFF1C1C1C);
  
  // Red for primary actions and errors
  static const Color primary = Color(0xFFD32F2F);
  
  // Light red for secondary actions and backgrounds
  static const Color secondary = Color(0xFFEEB2B2);

  // Additional getters for common use cases
  static MaterialColor primarySwatch = MaterialColor(
    primary.value,
    <int, Color>{
      50: primary.withOpacity(0.1),
      100: primary.withOpacity(0.2),
      200: primary.withOpacity(0.3),
      300: primary.withOpacity(0.4),
      400: primary.withOpacity(0.5),
      500: primary.withOpacity(0.6),
      600: primary.withOpacity(0.7),
      700: primary.withOpacity(0.8),
      800: primary.withOpacity(0.9),
      900: primary,
    },
  );
}
