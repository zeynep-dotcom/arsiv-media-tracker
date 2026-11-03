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
  Future<List<ContentItem>> getPopular({int page = 1}) =>
      _fetch({'ordering': '-added'}, page: page);

  @override
  Future<List<ContentItem>> search(String query, {int page = 1}) {
    final q = query.trim();
    if (q.isEmpty) return Future.value(const []);
    return _fetch({'search': q, 'search_precise': 'true'}, page: page);
  }

  @override
  Future<List<ContentItem>> getByGenre(Genre genre, {int page = 1}) => _fetch(
        {genre.rawgParam: genre.rawgValue, 'ordering': '-added'},
        page: page,
      );

  /// Detay ekranı açılınca /api/games/{id} ile oyunun tam bilgisini çeker:
  /// açıklama (description_raw), ortalama oynama süresi (playtime, saat)
  /// ve geliştirici(ler). Gelmeyen alanlar listedeki değerini korur.
  /// RAWG'dan gelmeyen öğeler (örnek veri) istek gönderilmeden aynen döner;
  /// onların açıklaması zaten sample_data.dart içinde tam yazılıdır.
  @override
  Future<ContentItem> getDetails(ContentItem item) async {
    if (!item.id.startsWith('rawg_')) return item;
    _requireKey();
    final id = item.id.substring(5);
    final uri = Uri.https('api.rawg.io', '/api/games/$id', {'key': _apiKey});
    final body = await _http.get(uri);
    if (body is! Map) {
      throw const ContentServiceException('RAWG beklenmeyen yanıt verdi.');
    }

    final developers = <String>[];
    for (final d in (body['developers'] as List?) ?? const []) {
      final name = d is Map ? (d['name'] as String?)?.trim() : null;
      if (name != null && name.isNotEmpty) developers.add(name);
    }
    final playtime = (body['playtime'] as num?)?.toInt() ?? 0;

    return item.copyWith(
      description: cleanDescription(body['description_raw'] as String?),
      creator: developers.isEmpty ? null : developers.take(2).join(', '),
      length: playtime > 0 ? playtime : null,
    );
  }

  /// RAWG açıklamasını sadeleştirir: sondaki İspanyolca çeviriyi atar,
  /// fazla boş satırları toplar. Açıklama yoksa null döner.
  static String? cleanDescription(String? raw) {
    if (raw == null) return null;
    var text = raw.replaceAll('\r\n', '\n');
    final spanish = RegExp(r'\n\s*Español\s*\n').firstMatch(text);
    if (spanish != null) text = text.substring(0, spanish.start);
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return text.isEmpty ? null : text;
  }

  void _requireKey() {
    if (_apiKey.isEmpty) {
      throw const ContentServiceException('RAWG anahtarı yok (env.json).');
    }
  }

  Future<List<ContentItem>> _fetch(
    Map<String, String> params, {
    required int page,
  }) async {
    if (page < 1) return const [];
    _requireKey();
    final uri = Uri.https('api.rawg.io', '/api/games', {
      ...params,
      'key': _apiKey,
      'page_size': '20',
      'page': '$page',
    });
    final dynamic body;
    try {
      body = await _http.get(uri);
    } on ContentServiceException catch (e) {
      // RAWG son sayfadan sonrası için 404 ("Invalid page") döndürür;
      // bu bir hata değil, sonuçların bittiği anlamına gelir.
      if (page > 1 && e.statusCode == 404) return const [];
      rethrow;
    }
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
          : '${shownGenres.join(' ve ')} türünde bir oyun.',
      meta: platforms.take(3).join(' · '),
      imageUrl: image,
      backdropUrl: image,
      artColors: fallbackColors('rawg_$id'),
    );
  }
}
