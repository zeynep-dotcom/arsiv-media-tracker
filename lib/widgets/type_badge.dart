import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_type.dart';

/// Film / Kitap / Oyun rozetini türün rengiyle gösterir.
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final ContentType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.forType(type),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}
