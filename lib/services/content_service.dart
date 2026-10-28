import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';

/// Her veri kaynağının (TMDB, Google Books, RAWG) uyduğu ortak arayüz.
/// Keşfet ve Ara ekranları yalnızca bu metotları bilir.
abstract class ContentService {
  /// Keşfet ekranındaki satır için öne çıkan içerikler.
  Future<List<ContentItem>> getPopular();

  /// Başlığa göre arama.
  Future<List<ContentItem>> search(String query);

  /// Türe göre arama ("korku" → TMDB 27, subject:horror, tags=horror).
  Future<List<ContentItem>> getByGenre(Genre genre);
}

/// Servis bir hata verdiğinde fırlatılır; ekran kullanıcıya anlaşılır bir
/// mesaj gösterir.
class ContentServiceException implements Exception {
  const ContentServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
