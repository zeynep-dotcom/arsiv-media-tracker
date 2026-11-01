import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';

/// Her veri kaynağının (TMDB, Google Books, RAWG) uyduğu ortak arayüz.
/// Keşfet, Ara ve Detay ekranları yalnızca bu metotları bilir.
///
/// Sayfalama: [page] 1'den başlar. Keşfet satırı sona kaydırılınca
/// `page: 2`, `page: 3`... ister; servis o sayfanın sonuçlarını döndürür,
/// sonuç kalmadıysa boş liste döner.
abstract class ContentService {
  /// Keşfet ekranındaki satır için öne çıkan içerikler.
  Future<List<ContentItem>> getPopular({int page = 1});

  /// Başlığa göre arama.
  Future<List<ContentItem>> search(String query, {int page = 1});

  /// Türe göre arama ("korku" → TMDB 27, subject:horror, tags=horror).
  Future<List<ContentItem>> getByGenre(Genre genre, {int page = 1});

  /// Detay ekranı açılınca çağrılır: listeden gelen [item]'ı tam açıklama,
  /// [ContentItem.creator] ve [ContentItem.length] gibi detaylarla
  /// zenginleştirip döndürür (`item.copyWith(...)`). Servis detayı
  /// getiremezse hata fırlatır; ekran mevcut kart bilgisini göstermeye
  /// devam eder.
  Future<ContentItem> getDetails(ContentItem item);
}

/// Servis bir hata verdiğinde fırlatılır; ekran kullanıcıya anlaşılır bir
/// mesaj gösterir.
class ContentServiceException implements Exception {
  const ContentServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
