import 'dart:math' as math;

import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/services/app_services.dart';

/// Öneri motoru (Ahmet): her aday içeriğe 0-1 arası bir puan verir.
///
///   puan = 0,7 × tür uyumu + 0,3 × API puanı / 10
///
/// Tür uyumu, kullanıcının tür profilinden gelir:
/// - "Hangi türleri seversin?" ekranında seçilen her tür: 2
/// - Kütüphanedeki her içeriğin türleri: 1, favoriyse +1, kullanıcı puanı
///   verdiyse +(puan - 5) / 5; "Yarım kaldı" olanlar sayılmaz.
/// Profil en yüksek türe göre 0-1'e ölçeklenir; bir adayın tür uyumu,
/// türleri arasında profilde en yüksek olanın değeridir.
///
/// Kütüphanesi boş yeni kullanıcıda profil yalnızca seçtiği türlerden
/// oluşur; hiç tercih yoksa öneriler API puanına göre sıralanır.
/// Kütüphanede zaten olan içerik önerilmez.
class RecommendationService {
  RecommendationService._();

  static const double genreWeight = 0.7;
  static const double ratingWeight = 0.3;

  /// Türe göre ek aday çekilirken kullanılan en fazla tür sayısı.
  static const int candidateGenres = 3;

  /// "Bu haftanın önerisi" en iyi kaç öneri arasında haftalık döner.
  static const int weeklyPool = 3;

  /// Bir tür adını GenreMap etiketine çevirir ("Science Fiction" →
  /// "Bilim kurgu", "Humor" → "Komedi"). Tabloda yoksa null.
  static String? canonical(String raw) {
    final match = GenreMap.match(raw);
    if (match != null) return match.label;
    final q = GenreMap.normalize(raw);
    for (final genre in GenreMap.all) {
      if (GenreMap.normalize(genre.booksSubject) == q ||
          GenreMap.normalize(genre.rawgValue) == q) {
        return genre.label;
      }
    }
    return null;
  }

  static Set<String> _genresOf(ContentItem item) =>
      item.genres.map(canonical).nonNulls.toSet();

  /// Kütüphanedeki bir içeriğin profile katkısı (0-3).
  static double entryWeight(LibraryEntry entry) {
    if (entry.status == LibraryStatus.dropped) return 0;
    var weight = 1.0;
    if (entry.favorite) weight += 1;
    final rating = entry.userRating;
    if (rating != null) weight += (rating - 5) / 5;
    return weight.clamp(0.0, 3.0).toDouble();
  }

  /// Tür etiketi → 0-1 ağırlık. Hiç sinyal yoksa boş harita.
  static Map<String, double> genreProfile({
    Iterable<LibraryEntry> library = const [],
    Iterable<String> favoriteGenres = const [],
  }) {
    final raw = <String, double>{};
    void add(String genre, double weight) =>
        raw[genre] = (raw[genre] ?? 0) + weight;

    for (final genre in favoriteGenres.map(canonical).nonNulls.toSet()) {
      add(genre, 2);
    }
    for (final entry in library) {
      final weight = entryWeight(entry);
      if (weight <= 0) continue;
      for (final genre in _genresOf(entry.item)) {
        add(genre, weight);
      }
    }

    final top = raw.values.fold(0.0, math.max);
    if (top <= 0) return {};
    return {
      for (final e in raw.entries)
        if (e.value > 0) e.key: e.value / top,
    };
  }

  /// Profilde en ağır [count] tür, ağırdan hafife.
  static List<String> topGenres(Map<String, double> profile, {int count = 3}) {
    final sorted = profile.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in sorted.take(count)) e.key];
  }

  /// 0-1 arası tür uyumu.
  static double genreMatch(ContentItem item, Map<String, double> profile) =>
      _genresOf(item).map((g) => profile[g] ?? 0).fold(0.0, math.max);

  /// 0-1 arası öneri puanı: %70 tür uyumu, %30 API puanı.
  static double score(ContentItem item, Map<String, double> profile) =>
      genreWeight * genreMatch(item, profile) +
      ratingWeight * (item.rating.clamp(0.0, 10.0) / 10);

  /// Adayları puana göre sıralar; tekrarları ve [exclude] içindeki
  /// kimlikleri (kütüphanedekiler) atar. Eşitlikte API puanı, sonra ad.
  static List<ContentItem> rank(
    Iterable<ContentItem> candidates, {
    required Map<String, double> profile,
    Set<String> exclude = const {},
  }) {
    final unique = <String, ContentItem>{};
    for (final item in candidates) {
      if (!exclude.contains(item.id)) unique.putIfAbsent(item.id, () => item);
    }
    final scores = {
      for (final item in unique.values) item.id: score(item, profile),
    };
    return unique.values.toList()..sort((a, b) {
      final byScore = scores[b.id]!.compareTo(scores[a.id]!);
      if (byScore != 0) return byScore;
      final byRating = b.rating.compareTo(a.rating);
      return byRating != 0 ? byRating : a.title.compareTo(b.title);
    });
  }

  /// Sıralı listeden haftanın önerisi: en iyi [weeklyPool] öneri haftadan
  /// haftaya sırayla gösterilir, hafta içinde aynı kalır.
  static ContentItem? weeklyPick(List<ContentItem> ranked, {DateTime? now}) {
    if (ranked.isEmpty) return null;
    final week =
        (now ?? DateTime.now()).millisecondsSinceEpoch ~/
        const Duration(days: 7).inMilliseconds;
    return ranked[week % math.min(weeklyPool, ranked.length)];
  }

  /// [genres] türlerinde film, kitap ve oyun adayları. Bir servis hata
  /// verirse o kısım atlanır. Gelen içeriğin türleri arasında aranan tür
  /// yoksa eklenir (Google Books kategorileri tür adını içermeyebilir).
  static Future<List<ContentItem>> genreCandidates(
    Iterable<String> genres,
  ) async {
    final requests = <Future<List<ContentItem>>>[];
    for (final label in genres) {
      final genre = GenreMap.match(label);
      if (genre == null) continue;
      for (final type in ContentType.values) {
        requests.add(
          AppServices.forType(type)
              .getByGenre(genre)
              .then((items) => [for (final item in items) _tag(item, genre)])
              .catchError((Object _) => <ContentItem>[]),
        );
      }
    }
    final lists = await Future.wait(requests);
    return [for (final list in lists) ...list];
  }

  static ContentItem _tag(ContentItem item, Genre genre) =>
      _genresOf(item).contains(genre.label)
      ? item
      : item.copyWith(genres: [...item.genres, genre.label]);

  /// Keşfet'teki "Bu haftanın önerisi": [popular] satırlarının içerikleri ile
  /// profildeki ilk türlerin içerikleri birlikte sıralanır. Öneri yoksa null.
  static Future<ContentItem?> loadWeeklyPick({
    required Iterable<ContentItem> popular,
    required List<LibraryEntry> library,
    required List<String> favoriteGenres,
    DateTime? now,
  }) async {
    final profile = genreProfile(
      library: library,
      favoriteGenres: favoriteGenres,
    );
    final byGenre = await genreCandidates(
      topGenres(profile, count: candidateGenres),
    );
    final ranked = rank(
      [...popular, ...byGenre],
      profile: profile,
      exclude: {for (final e in library) e.item.id},
    );
    return weeklyPick(ranked, now: now);
  }
}
