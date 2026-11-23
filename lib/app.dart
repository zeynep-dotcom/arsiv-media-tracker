import 'package:flutter/material.dart';

import 'package:arsiv_app/core/auth_gate.dart';
import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/services/save_errors.dart';

class ArsivApp extends StatelessWidget {
  const ArsivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARŞİV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // "Kaydedilemedi" uyarısı her ekranda bu anahtarla gösterilir.
      scaffoldMessengerKey: SaveErrors.messengerKey,
      home: const AuthGate(),
    );
  }
}
