import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/screens/detail/detail_screen.dart';
import 'package:arsiv_app/widgets/poster_art.dart';
import 'package:arsiv_app/widgets/type_badge.dart';

/// Detay ekranını açar. Her kart ve liste satırı bunu kullanır.
void openDetail(BuildContext context, ContentItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DetailScreen(item: item)),
  );
}

/// Afiş + başlıktan oluşan küçük kart (Keşfet satırları, benzer içerikler).
class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.item, this.width = 104});

  final ContentItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => openDetail(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                children: [
                  Positioned.fill(child: PosterArt(item: item)),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: TypeBadge(type: item.type),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              item.shortInfo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
