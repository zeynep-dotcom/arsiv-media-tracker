import 'package:http/http.dart' as http;

import 'package:arsiv_app/core/config/env.dart';
import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/services/content_service.dart';
import 'package:arsiv_app/services/google_books_service.dart';
import 'package:arsiv_app/services/http_json.dart';

/// TMDB film servisi (Ali Kağan).
///
/// TMDB anahtarı env.json içindeki TMDB_TOKEN alanından gelir. İki tür de
/// çalışır: uzun "API Read Access Token" (eyJ... ile başlar, Bearer başlığıyla
/// gönderilir) ya da 32 karakterlik kısa "API Key" (api_key parametresiyle).
/// Anahtar yoksa servis hata verir ve ekran örnek veriye döner.
class TmdbService implements ContentService {
  TmdbService({http.Client? client, String? token})
      : _http = JsonFetcher(source: 'TMDB', client: client),
        _token = token ?? Env.tmdbToken;

  final JsonFetcher _http;
  final String _token;

  /// Kısa v3 anahtarı mı? (32 karakter, nokta içermez)
  bool get _isShortKey => _token.length <= 40 && !_token.contains('.');

  static const _imageBase = 'https://image.tmdb.org/t/p';

  /// TMDB tür kimliklerinin Türkçe adları (kartlarda gösterilir).
  static const Map<int, String> genreNames = {
    28: 'Aksiyon', 12: 'Macera', 16: 'Animasyon', 35: 'Komedi', 80: 'Suç',
    99: 'Belgesel', 18: 'Dram', 10751: 'Aile', 14: 'Fantastik', 36: 'Tarih',
    27: 'Korku', 10402: 'Müzik', 9648: 'Gizem', 10749: 'Romantik',
    878: 'Bilim kurgu', 10770: 'TV filmi', 53: 'Gerilim', 10752: 'Savaş',
    37: 'Western',
  };

  @override
  Future<List<ContentItem>> getPopular({int page = 1}) =>
      _fetch('/3/movie/popular', {}, page: page);

  @override
  Future<List<ContentItem>> search(String query, {int page = 1}) {
    final q = query.trim();
    if (q.isEmpty) return Future.value(const []);
    return _fetch('/3/search/movie', {'query': q}, page: page);
  }

  @override
  Future<List<ContentItem>> getByGenre(Genre genre, {int page = 1}) => _fetch(
        '/3/discover/movie',
        {'with_genres': '${genre.tmdbId}', 'sort_by': 'popularity.desc'},
        page: page,
      );

  /// Detay ekranı açılınca /3/movie/{id}?append_to_response=credits&language=tr-TR
  /// isteğiyle yönetmen (creator), süre (length, dakika), türler ve tam
  /// açıklamayı getirir. TMDB'den gelmeyen öğeler (örnek veri) aynen döner.
  @override
  Future<ContentItem> getDetails(ContentItem item) async {
    if (!item.id.startsWith('tmdb_')) return item;
    if (_token.isEmpty) {
      throw const ContentServiceException('TMDB anahtarı yok (env.json).');
    }
    final movieId = item.id.substring(5);
    final uri = Uri.https('api.themoviedb.org', '/3/movie/$movieId', {
      'language': 'tr-TR',
      'append_to_response': 'credits',
      if (_isShortKey) 'api_key': _token,
    });
    final body = await _http.get(uri, headers: {
      if (!_isShortKey) 'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });
    if (body is! Map) {
      throw const ContentServiceException('TMDB beklenmeyen yanıt verdi.');
    }

    final runtime = (body['runtime'] as num?)?.toInt() ?? 0;
    final overview = (body['overview'] as String?)?.trim() ?? '';
    final rating = (body['vote_average'] as num?)?.toDouble();

    final genres = <String>[];
    for (final g in (body['genres'] as List?) ?? const []) {
      if (g is Map) {
        final id = (g['id'] as num?)?.toInt();
        final name = (id != null ? genreNames[id] : null) ??
            (g['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) genres.add(name);
      }
    }

    final directors = <String>[];
    final credits = body['credits'];
    final crew = credits is Map ? credits['crew'] : null;
    for (final c in (crew as List?) ?? const []) {
      if (c is Map && c['job'] == 'Director') {
        final name = (c['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty && !directors.contains(name)) {
          directors.add(name);
        }
      }
    }

    return item.copyWith(
      description: overview.isEmpty ? null : overview,
      creator: directors.isEmpty ? null : directors.take(2).join(', '),
      length: runtime > 0 ? runtime : null,
      genres: genres.isEmpty ? null : genres.take(2).toList(),
      rating: rating != null && rating > 0 ? rating : null,
    );
  }

  Future<List<ContentItem>> _fetch(
    String path,
    Map<String, String> params, {
    int page = 1,
  }) async {
    if (page < 1) return const [];
    if (_token.isEmpty) {
      throw const ContentServiceException('TMDB anahtarı yok (env.json).');
    }
    final uri = Uri.https('api.themoviedb.org', path, {
      ...params,
      'language': 'tr-TR',
      'include_adult': 'false',
      'page': '$page',
      if (_isShortKey) 'api_key': _token,
    });
    final dynamic body;
    try {
      body = await _http.get(uri, headers: {
        if (!_isShortKey) 'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      });
    } on ContentServiceException catch (e) {
      if (page > 1 && (e.statusCode == 400 || e.statusCode == 404)) {
        return const [];
      }
      rethrow;
    }
    final results = (body is Map ? body['results'] : null) as List<dynamic>?;
    if (results == null) return const [];
    return results.map(_toContentItem).whereType<ContentItem>().toList();
  }

  static ContentItem? _toContentItem(dynamic raw) {
    if (raw is! Map) return null;
    final title = (raw['title'] as String?)?.trim();
    final id = raw['id'];
    if (title == null || title.isEmpty || id == null) return null;

    final genreIds =
        (raw['genre_ids'] as List?)?.whereType<int>().toList() ?? const <int>[];
    final genres = genreIds
        .map((g) => genreNames[g])
        .whereType<String>()
        .take(2)
        .toList();
    final overview = (raw['overview'] as String?)?.trim() ?? '';
    final original = (raw['original_title'] as String?)?.trim() ?? '';
    final poster = raw['poster_path'] as String?;
    final backdrop = raw['backdrop_path'] as String?;

    return ContentItem(
      id: 'tmdb_$id',
      type: ContentType.film,
      title: title,
      year: parseYear(raw['release_date'] as String?),
      rating: (raw['vote_average'] as num?)?.toDouble() ?? 0,
      genres: genres.isEmpty ? const ['Film'] : genres,
      description:
          overview.isEmpty ? 'Türkçe açıklama bulunmuyor.' : overview,
      meta: original.isNotEmpty && original != title ? original : '',
      imageUrl: poster == null ? null : '$_imageBase/w500$poster',
      backdropUrl: backdrop == null ? null : '$_imageBase/w780$backdrop',
      artColors: fallbackColors('tmdb_$id'),
    );
  }
}
