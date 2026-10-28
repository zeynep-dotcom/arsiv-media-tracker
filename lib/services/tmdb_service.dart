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
  Future<List<ContentItem>> getPopular() => _fetch('/3/movie/popular', {});

  @override
  Future<List<ContentItem>> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return Future.value(const []);
    return _fetch('/3/search/movie', {'query': q});
  }

  @override
  Future<List<ContentItem>> getByGenre(Genre genre) => _fetch(
        '/3/discover/movie',
        {'with_genres': '${genre.tmdbId}', 'sort_by': 'popularity.desc'},
      );

  Future<List<ContentItem>> _fetch(
      String path, Map<String, String> params) async {
    if (_token.isEmpty) {
      throw const ContentServiceException('TMDB anahtarı yok (env.json).');
    }
    final uri = Uri.https('api.themoviedb.org', path, {
      ...params,
      'language': 'tr-TR',
      'include_adult': 'false',
      'page': '1',
      if (_isShortKey) 'api_key': _token,
    });
    final body = await _http.get(uri, headers: {
      if (!_isShortKey) 'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });
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
