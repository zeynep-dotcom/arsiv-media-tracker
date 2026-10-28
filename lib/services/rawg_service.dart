import 'package:http/http.dart' as http;

import 'package:arsiv_app/core/config/env.dart';
import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/services/content_service.dart';
import 'package:arsiv_app/services/google_books_service.dart';
import 'package:arsiv_app/services/http_json.dart';

/// RAWG oyun servisi (Enes).
///
/// API anahtarı env.json içindeki RAWG_KEY alanından gelir. RAWG koşulu
/// gereği uygulamada kaynak gösterimi yapılır (Keşfet ekranının altı).
class RawgService implements ContentService {
  RawgService({http.Client? client, String? apiKey})
      : _http = JsonFetcher(source: 'RAWG', client: client),
        _apiKey = apiKey ?? Env.rawgKey;

  final JsonFetcher _http;
  final String _apiKey;

  static const Map<String, String> _genreNames = {
    'action': 'Aksiyon', 'adventure': 'Macera', 'role-playing-games-rpg': 'RPG',
    'strategy': 'Strateji', 'shooter': 'Nişancı', 'puzzle': 'Bulmaca',
    'racing': 'Yarış', 'sports': 'Spor', 'simulation': 'Simülasyon',
    'indie': 'Bağımsız', 'platformer': 'Platform', 'fighting': 'Dövüş',
    'casual': 'Gündelik', 'arcade': 'Arcade', 'family': 'Aile',
  };

  @override
  Future<List<ContentItem>> getPopular() => _fetch({'ordering': '-added'});

  @override
  Future<List<ContentItem>> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return Future.value(const []);
    return _fetch({'search': q, 'search_precise': 'true'});
  }

  @override
  Future<List<ContentItem>> getByGenre(Genre genre) =>
      _fetch({genre.rawgParam: genre.rawgValue, 'ordering': '-added'});

  Future<List<ContentItem>> _fetch(Map<String, String> params) async {
    if (_apiKey.isEmpty) {
      throw const ContentServiceException('RAWG anahtarı yok (env.json).');
    }
    final uri = Uri.https('api.rawg.io', '/api/games', {
      ...params,
      'key': _apiKey,
      'page_size': '20',
    });
    final body = await _http.get(uri);
    final results = (body is Map ? body['results'] : null) as List<dynamic>?;
    if (results == null) return const [];
    return results.map(_toContentItem).whereType<ContentItem>().toList();
  }

  static ContentItem? _toContentItem(dynamic raw) {
    if (raw is! Map) return null;
    final name = (raw['name'] as String?)?.trim();
    final id = raw['id'];
    if (name == null || name.isEmpty || id == null) return null;

    final genres = <String>[];
    for (final g in (raw['genres'] as List?) ?? const []) {
      if (g is Map) {
        final slug = g['slug'] as String?;
        final label = _genreNames[slug] ?? g['name'] as String?;
        if (label != null) genres.add(label);
      }
    }

    final platforms = <String>[];
    for (final p in (raw['parent_platforms'] as List?) ??
        (raw['platforms'] as List?) ??
        const []) {
      final platform = p is Map ? p['platform'] : null;
      final pName = platform is Map ? platform['name'] as String? : null;
      if (pName != null) platforms.add(pName);
    }

    final image = raw['background_image'] as String?;
    final rating5 = (raw['rating'] as num?)?.toDouble() ?? 0;
    final shownGenres = genres.take(2).toList();

    return ContentItem(
      id: 'rawg_$id',
      type: ContentType.game,
      title: name,
      year: parseYear(raw['released'] as String?),
      rating: rating5 * 2, // 5'lik puanı 10'luğa çevir
      genres: shownGenres.isEmpty ? const ['Oyun'] : shownGenres,
      description: shownGenres.isEmpty
          ? 'RAWG oyun kaydı.'
          : '${shownGenres.join(' ve ')} türünde bir oyun. '
              'Ayrıntılı açıklama Hafta 3\'te detay isteğiyle eklenecek.',
      meta: platforms.take(3).join(' · '),
      imageUrl: image,
      backdropUrl: image,
      artColors: fallbackColors('rawg_$id'),
    );
  }
}
