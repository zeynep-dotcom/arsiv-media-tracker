import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_type.dart';

/// Tümü / Filmler / Kitaplar / Oyunlar seçim çipleri.
class TypeFilterBar extends StatelessWidget {
  const TypeFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// null = Tümü
  final ContentType? selected;
  final ValueChanged<ContentType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <ContentType?>[null, ...ContentType.values];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final option = options[i];
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text(option?.plural ?? 'Tümü'),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onChanged(option),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.white,
            ),
            selectedColor: Colors.white,
            backgroundColor: AppColors.background,
            side: BorderSide(
              color: isSelected ? Colors.white : AppColors.divider,
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
