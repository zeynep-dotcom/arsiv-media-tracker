import 'package:flutter/material.dart';

import 'package:arsiv_app/core/auth_gate.dart';
import 'package:arsiv_app/core/theme/app_theme.dart';

class ArsivApp extends StatelessWidget {
  const ArsivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARŞİV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AuthGate(),
    );
  }
}
