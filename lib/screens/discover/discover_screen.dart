import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/services/app_services.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/sample_data.dart';
import 'package:arsiv_app/widgets/content_card.dart';
import 'package:arsiv_app/widgets/content_row.dart';
import 'package:arsiv_app/widgets/poster_art.dart';
import 'package:arsiv_app/widgets/type_filter_bar.dart';

/// 01 · Keşfet: haftanın önerisi + film, kitap, oyun satırları.
/// Her satır kendi API'sinden yüklenir; hata olursa örnek veri gösterilir.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  ContentType? _filter;
  late Future<List<ContentItem>> _films;
  late Future<List<ContentItem>> _books;
  late Future<List<ContentItem>> _games;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _films = AppServices.films.getPopular();
    _books = AppServices.books.getPopular();
    _games = AppServices.games.getPopular();
  }

  Future<void> _refresh() async {
    setState(_load);
    // Hatalar satırların içinde gösteriliyor; burada yalnızca bitmesini bekle.
    await Future.wait([
      _films.catchError((_) => <ContentItem>[]),
      _books.catchError((_) => <ContentItem>[]),
      _games.catchError((_) => <ContentItem>[]),
    ]);
  }

  bool _show(ContentType type) => _filter == null || _filter == type;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.red,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _Header(),
            const SizedBox(height: 12),
            TypeFilterBar(
              selected: _filter,
              onChanged: (t) => setState(() => _filter = t),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<ContentItem>>(
                future: _films,
                builder: (context, snapshot) {
                  final films = snapshot.data;
                  final item = (films != null && films.isNotEmpty)
                      ? films.first
                      : SampleData.featured;
                  return _FeaturedCard(item: item);
                },
              ),
            ),
            if (_show(ContentType.film))
              AsyncContentRow(
                title: 'Popüler Filmler',
                future: _films,
                fallback: SampleData.films,
              ),
            if (_show(ContentType.book))
              AsyncContentRow(
                title: 'Çok Okunan Kitaplar',
                future: _books,
                fallback: SampleData.books,
              ),
            if (_show(ContentType.game))
              AsyncContentRow(
                title: 'Trend Oyunlar',
                future: _games,
                fallback: SampleData.games,
              ),
            const _Attribution(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text(
            'ARŞİV',
            style: TextStyle(
              color: AppColors.red,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          Spacer(),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.cardHigh,
            child: Text(
              'A',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final store = LibraryStore.instance;
    return AspectRatio(
      aspectRatio: 4 / 3.4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PosterArt(item: item, borderRadius: 0, preferBackdrop: true),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BU HAFTANIN ÖNERİSİ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    [
                      item.type.label,
                      if (item.genres.isNotEmpty) item.genres.join(', '),
                      if (item.hasRating) '★ ${item.rating.toStringAsFixed(1)}',
                    ].join(' · '),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // Dar ekranda düğmeler sığmazsa alt satıra geçer.
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => openDetail(context, item),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Detay'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: store,
                        builder: (context, _) {
                          final added = store.contains(item);
                          return FilledButton.icon(
                            onPressed: () => added
                                ? store.remove(item)
                                : store.add(item),
                            icon: Icon(added ? Icons.check : Icons.add,
                                size: 18),
                            label: Text(added ? 'Listemde' : 'Listeme'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.22),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TMDB ve RAWG kullanım koşulları gereği kaynak gösterimi.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Text(
        'Film verileri TMDB, kitap verileri Google Books, oyun verileri '
        'RAWG (rawg.io) kaynaklıdır. Bu ürün TMDB API\'sini kullanır ancak '
        'TMDB tarafından onaylanmamıştır.',
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}
