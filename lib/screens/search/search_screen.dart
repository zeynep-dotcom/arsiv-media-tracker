import 'dart:async';

import 'package:flutter/material.dart';

import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/services/app_services.dart';
import 'package:arsiv_app/services/sample_data.dart';
import 'package:arsiv_app/widgets/content_card.dart';
import 'package:arsiv_app/widgets/type_filter_bar.dart';

/// Ara: kelime bir türse (ör. "korku") üç API'de tür araması, değilse
/// başlık araması yapılır. İstekler aynı anda gönderilir (Future.wait);
/// bir kaynak hata verirse diğerlerinin sonuçları yine gösterilir.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  ContentType? _filter;

  Timer? _debounce;
  int _requestId = 0;
  bool _loading = false;
  Genre? _genre;

  /// Türe göre API sonuçları; null = o tür için henüz API sonucu yok.
  final Map<ContentType, List<ContentItem>> _apiResults = {};
  final Map<ContentType, String> _errors = {};

  @override
  void initState() {
    super.initState();
    // Açılışta API'lerden popüler içerikleri getir (ilk çizimden sonra).
    _loading = true;
    Future.microtask(() => _run(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<ContentType> get _wantedTypes =>
      _filter == null ? ContentType.values : [_filter!];

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _schedule();
  }

  void _onFilterChanged(ContentType? type) {
    setState(() => _filter = type);
    _schedule();
  }

  void _searchGenre(Genre genre) {
    _controller.text = genre.label;
    _onQueryChanged(genre.label);
  }

  /// Yazmayı bırakınca 500 ms sonra API'lere sorar; her harfte istek atmaz.
  void _schedule() {
    _debounce?.cancel();
    final q = _query.trim();
    if (q.isEmpty) {
      _run(''); // Arama silinince popülerlere dön (önbellekten gelir).
      return;
    }
    if (q.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 500), () => _run(q));
  }

  Future<void> _run(String q) async {
    final id = ++_requestId;
    final genre = q.isEmpty ? null : GenreMap.match(q);
    final types = _wantedTypes;
    setState(() {
      _loading = true;
      _genre = genre;
    });

    Future<(ContentType, List<ContentItem>?, String?)> fetchOne(
        ContentType type) async {
      final service = AppServices.forType(type);
      try {
        final items = q.isEmpty
            ? await service.getPopular()
            : genre != null
                ? await service.getByGenre(genre)
                : await service.search(q);
        return (type, items, null);
      } catch (e) {
        return (type, null, '$e');
      }
    }

    final outcomes = await Future.wait(types.map(fetchOne));

    if (!mounted || id != _requestId) return;
    setState(() {
      _apiResults.clear();
      _errors.clear();
      for (final (type, items, error) in outcomes) {
        if (items != null) _apiResults[type] = items;
        if (error != null) _errors[type] = error;
      }
      _loading = false;
    });
  }

  bool _matchesLocal(ContentItem item, String q) {
    if (q.isEmpty) return true;
    final n = GenreMap.normalize(q);
    final genre = _genre;
    if (genre != null) {
      return item.genres.any((g) => GenreMap.normalize(g) ==
          GenreMap.normalize(genre.label));
    }
    return GenreMap.normalize(item.title).contains(n) ||
        item.genres.any((g) => GenreMap.normalize(g).contains(n));
  }

  /// API sonucu gelen türler için API verisi; yalnızca o API hata verirse
  /// örnek veri. Aramada puana göre sıralanır.
  List<ContentItem> get _results {
    final q = _query.trim();
    final list = <ContentItem>[];
    for (final type in _wantedTypes) {
      final api = _apiResults[type];
      if (api != null) {
        list.addAll(api);
      } else if (_errors.containsKey(type)) {
        list.addAll(SampleData.byType(type).where((i) => _matchesLocal(i, q)));
      }
    }
    if (q.isNotEmpty) list.sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Ara',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Film, kitap, oyun ya da tür ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      ),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TypeFilterBar(selected: _filter, onChanged: _onFilterChanged),
          if (_query.trim().isEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'Türe göre ara',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: GenreMap.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final g = GenreMap.all[i];
                  return ActionChip(
                    label: Text(g.label),
                    onPressed: () => _searchGenre(g),
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.divider),
                    shape: const StadiumBorder(),
                  );
                },
              ),
            ),
          ],
          if (_query.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                'Popüler film, kitap ve oyunlar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          if (_genre != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                'Tür araması: ${_genre!.label} · film, kitap ve oyun birlikte',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.red,
                backgroundColor: AppColors.card,
              ),
            ),
          for (final entry in _errors.entries)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                '${entry.key.plural}: ${entry.value} Örnek veri gösteriliyor.',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      _loading ? 'Yükleniyor…' : 'Sonuç bulunamadı',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.52,
                    ),
                    itemCount: results.length,
                    itemBuilder: (_, i) =>
                        ContentCard(item: results[i], width: double.infinity),
                  ),
          ),
        ],
      ),
    );
  }
}
