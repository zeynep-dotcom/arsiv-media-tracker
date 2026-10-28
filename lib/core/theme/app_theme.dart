import 'package:flutter/material.dart';

import 'package:arsiv_app/models/content_type.dart';

/// Hafta 1 sunumundaki renk paleti (Emir'in tasarımı).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0B0F); // Zemin
  static const Color card = Color(0xFF1C1C24); // Kart
  static const Color cardHigh = Color(0xFF26262F);
  static const Color red = Color(0xFFE50914); // Vurgu (film)
  static const Color redDark = Color(0xFF5A1418);
  static const Color book = Color(0xFF5FA8D3); // Kitap
  static const Color game = Color(0xFFC04CFD); // Oyun
  static const Color gold = Color(0xFFF5C518); // Puan rozeti
  static const Color green = Color(0xFF3DDC84); // Tamamlandı
  static const Color orange = Color(0xFFF4B23E);
  static const Color teal = Color(0xFF3CC8A8);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9A9AA6);
  static const Color divider = Color(0xFF2E2E38);

  static Color forType(ContentType type) => switch (type) {
        ContentType.film => red,
        ContentType.book => book,
        ContentType.game => game,
      };
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.red,
        brightness: Brightness.dark,
        primary: AppColors.red,
        surface: AppColors.background,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      dividerColor: AppColors.divider,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardHigh,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
