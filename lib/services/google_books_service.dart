import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:arsiv_app/core/config/env.dart';
import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/services/content_service.dart';
import 'package:arsiv_app/services/http_json.dart';

/// Google Books API servisi (Abdulkadir).
///
/// Anahtar isteğe bağlıdır: anahtarsız da çalışır ama günlük istek sınırı
/// düşüktür. Anahtar env.json içindeki GOOGLE_BOOKS_KEY alanından gelir.
class GoogleBooksService implements ContentService {
  GoogleBooksService({http.Client? client, String? apiKey})
    : _http = JsonFetcher(source: 'Google Books', client: client),
      _apiKey = apiKey ?? Env.googleBooksKey;

  final JsonFetcher _http;
  final String _apiKey;

  /// Google Books'ta "popüler" uç noktası yok. Keşfet için sırayla bu
  /// sorguları deneriz; bazı bölgelerde konu sorgusu boş dönebiliyor.
  static const popularQueries = ['roman', 'novel', 'subject:fiction'];

  @override
  Future<List<ContentItem>> getPopular() => _firstNonEmpty(popularQueries);

  /// Sorguları sırayla dener; bir sorgu hata verirse ya da boş dönerse
  /// sıradakine geçer. Hepsi hata verirse son hatayı iletir.
  Future<List<ContentItem>> _firstNonEmpty(List<String> queries) async {
    ContentServiceException? lastError;
    for (final q in queries) {
      try {
        final items = await _fetch({'q': q});
        if (items.isNotEmpty) return items;
      } on ContentServiceException catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError;
    return const [];
  }

  @override
  Future<List<ContentItem>> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return Future.value(const []);
    return _fetch({'q': 'intitle:$q'});
  }

  /// Konu sorgusu bazı bölgelerde boş dönüyor; sırayla konu, İngilizce tür
  /// adı ve Türkçe tür adıyla dener.
  @override
  Future<List<ContentItem>> getByGenre(Genre genre) {
    final queries = [
      'subject:${genre.booksSubject}',
      genre.booksSubject,
      genre.label,
    ];
    return _firstNonEmpty(queries);
  }

  Future<List<ContentItem>> _fetch(Map<String, String> params) async {
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
      ...params,
      'printType': 'books',
      'maxResults': '20',
      // Konum belirlenemeyen ağlarda (ör. mobil veri) boş sonuç gelmesin.
      'country': 'TR',
      if (_apiKey.isNotEmpty) 'key': _apiKey,
    });
    final body = await _http.get(uri);
    final items = (body is Map ? body['items'] : null) as List<dynamic>?;
    if (items == null || items.isEmpty) {
      final total = body is Map ? body['totalItems'] : null;
      debugPrint(
        '[Google Books] boş yanıt · q=${params['q']} · totalItems=$total',
      );
      return const [];
    }

    final seen = <String>{};
    final result = <ContentItem>[];
    for (final raw in items) {
      final item = _toContentItem(raw);
      // Aynı kitabın farklı baskıları tekrar gelmesin.
      if (item != null && seen.add(item.title.toLowerCase())) {
        result.add(item);
      }
    }
    return result;
  }

  /// volumeInfo alanlarını ortak modele çevirir. Başlığı olmayan kayıt atlanır.
  static ContentItem? _toContentItem(dynamic raw) {
    if (raw is! Map) return null;
    final info = raw['volumeInfo'];
    if (info is! Map) return null;

    final title = (info['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return null;

    final id = raw['id'] as String? ?? title;
    final authors =
        (info['authors'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    final pageCount = info['pageCount'] as int?;
    final rating5 = (info['averageRating'] as num?)?.toDouble();
    final categories =
        (info['categories'] as List?)?.whereType<String>().toList() ??
        const <String>[];

    final metaParts = [
      if (authors.isNotEmpty) authors.take(2).join(', '),
      if (pageCount != null && pageCount > 0) '$pageCount sayfa',
    ];

    return ContentItem(
      id: 'gb_$id',
      type: ContentType.book,
      title: title,
      year: parseYear(info['publishedDate'] as String?),
      rating: rating5 == null ? 0 : rating5 * 2, // 5'lik puanı 10'luğa çevir
      genres: categories.isEmpty
          ? const ['Kitap']
          : categories.take(2).toList(),
      description: _cleanDescription(info['description'] as String?),
      meta: metaParts.isEmpty ? 'Yazar bilgisi yok' : metaParts.join(' · '),
      imageUrl: _coverUrl(info['imageLinks']),
      artColors: fallbackColors(id),
    );
  }

  static String? _coverUrl(dynamic links) {
    if (links is! Map) return null;
    final url = (links['thumbnail'] ?? links['smallThumbnail']) as String?;
    if (url == null) return null;
    // Android http adreslerini engeller; kapakları https ile iste.
    return url.replaceFirst('http://', 'https://').replaceAll('&edge=curl', '');
  }

  static String _cleanDescription(String? text) {
    if (text == null || text.trim().isEmpty) return 'Açıklama bulunmuyor.';
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

/// Görsel gelmezse kimliğe göre sabit bir renk çifti seçilir.
List<Color> fallbackColors(String id) {
  const palettes = [
    [Color(0xFF5FA8D3), Color(0xFF173B52)],
    [Color(0xFFF4B23E), Color(0xFF5A3A0A)],
    [Color(0xFF9BC53D), Color(0xFF2E4110)],
    [Color(0xFF7C8494), Color(0xFF22262E)],
    [Color(0xFFE5484D), Color(0xFF6E1219)],
    [Color(0xFFC04CFD), Color(0xFF3A1052)],
  ];
  return palettes[id.hashCode.abs() % palettes.length];
}
