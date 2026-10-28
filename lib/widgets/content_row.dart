import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/widgets/content_card.dart';

/// Başlık + yatay kaydırmalı kart satırı.
class ContentRow extends StatelessWidget {
  const ContentRow({super.key, required this.title, required this.items});

  final String title;
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ContentCard(item: items[i]),
          ),
        ),
      ],
    );
  }
}

/// API'den yüklenen satır. Yüklenirken iskelet kartlar, hata olursa
/// örnek veri ve kısa bir uyarı gösterir.
class AsyncContentRow extends StatelessWidget {
  const AsyncContentRow({
    super.key,
    required this.title,
    required this.future,
    required this.fallback,
  });

  final String title;
  final Future<List<ContentItem>> future;
  final List<ContentItem> fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContentItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _SkeletonRow(title: title);
        }
        final data = snapshot.data;
        if (snapshot.hasError) {
          debugPrint('[$title] hata: ${snapshot.error}');
        }
        if (snapshot.hasError || data == null || data.isEmpty) {
          final reason = snapshot.hasError
              ? '${snapshot.error}'
              : 'Sonuç gelmedi.';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContentRow(title: title, items: fallback),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  '$reason Örnek veri gösteriliyor.',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        }
        return ContentRow(title: title, items: data);
      },
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => Container(
              width: 104,
              margin: const EdgeInsets.only(bottom: 44),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
