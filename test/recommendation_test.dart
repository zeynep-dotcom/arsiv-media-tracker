import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/services/app_services.dart';
import 'package:arsiv_app/services/content_service.dart';
import 'package:arsiv_app/services/recommendation_service.dart';
import 'package:arsiv_app/services/user_preferences.dart';

ContentItem item(
  String id,
  List<String> genres, {
  double rating = 7,
  ContentType type = ContentType.film,
}) => ContentItem(
  id: id,
  type: type,
  title: id,
  year: 2025,
  rating: rating,
  genres: genres,
  description: '',
  meta: '',
  artColors: const [Colors.black, Colors.black],
);

/// Her türe göre istekte [byGenre]'deki listeyi döndüren sahte servis.
class GenreService implements ContentService {
  GenreService(this.byGenre, {this.fails = false});
  final Map<String, List<ContentItem>> byGenre;
  final bool fails;
  final requested = <String>[];

  @override
  Future<List<ContentItem>> getByGenre(Genre genre, {int page = 1}) async {
    requested.add(genre.label);
    if (fails) throw const ContentServiceException('kota');
    return byGenre[genre.label] ?? const [];
  }

  @override
  Future<List<ContentItem>> getPopular({int page = 1}) async => const [];

  @override
  Future<List<ContentItem>> search(String query, {int page = 1}) async =>
      const [];

  @override
  Future<ContentItem> getDetails(ContentItem item) async => item;
}

void main() {
  group('RecommendationService', () {
    test('tür adlarını GenreMap etiketine çevirir', () {
      expect(RecommendationService.canonical('Dram'), 'Dram');
      expect(RecommendationService.canonical('Science Fiction'), 'Bilim kurgu');
      expect(RecommendationService.canonical('Humor'), 'Komedi');
      expect(RecommendationService.canonical('Animasyon'), isNull);
    });

    test('puan %70 tür uyumu, %30 API puanıdır', () {
      final profile = {'Dram': 1.0, 'Korku': 0.5};
      expect(
        RecommendationService.score(item('a', ['Dram'], rating: 8), profile),
        closeTo(0.7 + 0.24, 1e-9),
      );
      expect(
        RecommendationService.score(item('b', ['Korku'], rating: 6), profile),
        closeTo(0.35 + 0.18, 1e-9),
      );
      expect(
        RecommendationService.score(
          item('c', ['Western'], rating: 10),
          profile,
        ),
        closeTo(0.3, 1e-9),
      );
    });

    test('yeni kullanıcıda profil seçtiği türlerden oluşur', () {
      final profile = RecommendationService.genreProfile(
        favoriteGenres: ['Korku', 'Gerilim', 'Gizem'],
      );
      expect(profile, {'Korku': 1.0, 'Gerilim': 1.0, 'Gizem': 1.0});

      final ranked = RecommendationService.rank([
        item('yuksek-puan', ['Komedi'], rating: 9.5),
        item('korku', ['Korku'], rating: 6),
      ], profile: profile);
      expect(ranked.first.id, 'korku');
    });

    test(
      'kütüphane favori ve puanla profili etkiler, yarım kalan sayılmaz',
      () {
        final profile = RecommendationService.genreProfile(
          library: [
            LibraryEntry(
              item: item('1', ['Dram']),
              favorite: true,
              userRating: 10,
            ),
            LibraryEntry(item: item('2', ['Komedi']), userRating: 2),
            LibraryEntry(
              item: item('3', ['Korku']),
              status: LibraryStatus.dropped,
            ),
          ],
        );
        expect(profile['Dram'], 1.0);
        expect(profile['Komedi'], closeTo(0.4 / 3, 1e-9));
        expect(profile.containsKey('Korku'), isFalse);
      },
    );

    test('kütüphanedeki ve tekrar eden içerik önerilmez', () {
      final ranked = RecommendationService.rank(
        [
          item('a', ['Dram']),
          item('a', ['Dram']),
          item('b', ['Dram']),
        ],
        profile: {'Dram': 1.0},
        exclude: {'b'},
      );
      expect(ranked.map((i) => i.id), ['a']);
    });

    test('hiç tercih yoksa API puanına göre sıralar', () {
      final ranked = RecommendationService.rank([
        item('dusuk', ['Dram'], rating: 5),
        item('yuksek', ['Dram'], rating: 9),
      ], profile: const {});
      expect(ranked.first.id, 'yuksek');
    });

    test('haftanın önerisi hafta içinde aynı kalır, haftaya göre döner', () {
      final ranked = [
        item('1', []),
        item('2', []),
        item('3', []),
        item('4', []),
      ];
      final monday = DateTime.utc(2026, 11, 23);
      final week =
          monday.millisecondsSinceEpoch ~/
          const Duration(days: 7).inMilliseconds;

      final pick = RecommendationService.weeklyPick(ranked, now: monday);
      expect(pick, same(ranked[week % 3]));
      expect(
        RecommendationService.weeklyPick(
          ranked,
          now: monday.add(const Duration(hours: 1)),
        ),
        same(pick),
      );
      expect(
        RecommendationService.weeklyPick(
          ranked,
          now: monday.add(const Duration(days: 7)),
        ),
        same(ranked[(week + 1) % 3]),
      );
      expect(RecommendationService.weeklyPick(const []), isNull);
    });

    group('ağ ile', () {
      late ContentService films, books, games;
      setUp(() {
        films = AppServices.films;
        books = AppServices.books;
        games = AppServices.games;
      });
      tearDown(() {
        AppServices.films = films;
        AppServices.books = books;
        AppServices.games = games;
      });

      test('seçilen türlerden aday çeker, hata veren servisi atlar', () async {
        final kitap = item('kitap', ['Fiction'], type: ContentType.book);
        AppServices.films = GenreService({
          'Korku': [
            item('film', ['Korku']),
          ],
        });
        AppServices.books = GenreService({
          'Korku': [kitap],
        });
        AppServices.games = GenreService(const {}, fails: true);

        final result = await RecommendationService.genreCandidates(['Korku']);

        expect(result.map((i) => i.id), ['film', 'kitap']);
        // Google Books kategorisi tür adını içermese de aranan tür eklenir.
        expect(result.last.genres, ['Fiction', 'Korku']);
      });

      test('boş kütüphanede haftanın önerisi seçilen türden gelir', () async {
        final korku = GenreService({
          'Korku': [
            item('korku-film', ['Korku'], rating: 6),
          ],
        });
        AppServices.films = korku;
        AppServices.books = GenreService(const {});
        AppServices.games = GenreService(const {});

        // 0. hafta: haftalık havuzun ilk sırası, yani en yüksek puanlı aday.
        final pick = await RecommendationService.loadWeeklyPick(
          popular: [
            item('populer', ['Komedi'], rating: 9.8),
          ],
          library: const [],
          favoriteGenres: ['Korku'],
          now: DateTime.fromMillisecondsSinceEpoch(0),
        );

        expect(korku.requested, ['Korku']);
        expect(pick?.id, 'korku-film');
      });
    });
  });

  group('UserPreferences', () {
    late FakeFirebaseFirestore firestore;
    final prefs = UserPreferences.instance;

    setUp(() => firestore = FakeFirebaseFirestore());
    tearDown(prefs.stop);

    test('kaydederken plan ve adı korur, GenreMap sırasına dizer', () async {
      final doc = firestore.doc('users/ahmet-uid');
      await doc.set({'name': 'Ahmet', 'plan': 'free'});
      prefs.start(doc);

      await prefs.saveFavoriteGenres(['Gerilim', 'Korku', 'Uydurma', 'Korku']);

      final data = (await doc.get()).data()!;
      expect(data['favoriteGenres'], ['Korku', 'Gerilim']);
      expect(data['plan'], 'free');
      expect(data['name'], 'Ahmet');
      expect(prefs.favoriteGenres, ['Korku', 'Gerilim']);
    });

    test('belgedeki tercihleri okur, çıkışta boşaltır', () async {
      final doc = firestore.doc('users/ahmet-uid');
      await doc.set({
        'favoriteGenres': ['Dram', 'Bilinmeyen', 'Aksiyon'],
      });
      prefs.start(doc);
      await Future<void>.delayed(Duration.zero);

      expect(prefs.favoriteGenres, ['Aksiyon', 'Dram']);
      prefs.stop();
      expect(prefs.favoriteGenres, isEmpty);
    });
  });
}
