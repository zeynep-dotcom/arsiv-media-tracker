import 'package:flutter/material.dart';

import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/services/app_services.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/widgets/content_row.dart';
import 'package:arsiv_app/widgets/poster_art.dart';
import 'package:arsiv_app/widgets/type_badge.dart';

/// 02 · Detay: büyük afiş, bilgiler, kütüphaneye ekleme, benzer içerikler.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final store = LibraryStore.instance;
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final entry = store.entryFor(item);
          final inLibrary = entry != null;
          final favorite = entry?.favorite ?? false;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: height * 0.46,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PosterArt(
                          item: item, borderRadius: 0, preferBackdrop: true),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.background],
                            stops: [0.55, 1],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: IconButton.filled(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.chevron_left),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        TypeBadge(type: item.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.detailInfo,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (item.hasRating) Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '★ ${item.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.hasRating ? item.ratingSource : 'Henüz puan yok',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                        if (entry?.userRating != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Senin puanın: ${entry!.userRating}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          inLibrary ? store.remove(item) : store.add(item);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              content: Text(inLibrary
                                  ? '${item.title} kütüphaneden çıkarıldı'
                                  : '${item.title} kütüphanene eklendi'),
                            ));
                        },
                        icon: Icon(inLibrary ? Icons.check : Icons.add),
                        label: Text(
                            inLibrary ? 'Kütüphanende' : 'Kütüphaneme Ekle'),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              inLibrary ? AppColors.cardHigh : AppColors.red,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _OutlineAction(
                            icon: favorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: 'Favori',
                            active: favorite,
                            onTap: () => store.toggleFavorite(item),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OutlineAction(
                            icon: Icons.star_border,
                            label: 'Puanla',
                            onTap: () => _showRating(context, store),
                          ),
                        ),
                      ],
                    ),
                    if (entry != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Durum',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<LibraryStatus>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                                value: LibraryStatus.planned,
                                label: Text('Planlandı')),
                            ButtonSegment(
                                value: LibraryStatus.inProgress,
                                label: Text('Devam')),
                            ButtonSegment(
                                value: LibraryStatus.done,
                                label: Text('Bitti')),
                            ButtonSegment(
                                value: LibraryStatus.dropped,
                                label: Text('Yarım')),
                          ],
                          selected: {entry.status},
                          onSelectionChanged: (set) =>
                              store.setStatus(item, set.first),
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppColors.red,
                            selectedForegroundColor: Colors.white,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.divider),
                            textStyle: const TextStyle(fontSize: 12),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      item.description,
                      style: const TextStyle(height: 1.5, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _SimilarRow(item: item)),
            ],
          );
        },
      ),
    );
  }

  void _showRating(BuildContext context, LibraryStore store) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.title} için puanın',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 1; i <= 10; i++)
                    ActionChip(
                      label: Text('$i'),
                      onPressed: () {
                        store.rate(item, i);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: active ? AppColors.red : Colors.white),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.divider),
        minimumSize: const Size.fromHeight(44),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}


/// Benzer içerikler: aynı türdeki popüler içerikler, ilgili API'den.
class _SimilarRow extends StatefulWidget {
  const _SimilarRow({required this.item});

  final ContentItem item;

  @override
  State<_SimilarRow> createState() => _SimilarRowState();
}

class _SimilarRowState extends State<_SimilarRow> {
  Future<List<ContentItem>>? _future;

  @override
  void initState() {
    super.initState();
    Genre? genre;
    for (final g in widget.item.genres) {
      genre = GenreMap.match(g);
      if (genre != null) break;
    }
    final found = genre;
    if (found != null) {
      _future = AppServices.forType(widget.item.type)
          .getByGenre(found)
          .then((list) =>
              list.where((e) => e.id != widget.item.id).take(10).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox(height: 32);
    return FutureBuilder<List<ContentItem>>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.isEmpty) return const SizedBox(height: 32);
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: ContentRow(title: 'Benzer içerikler', items: data),
        );
      },
    );
  }
}
