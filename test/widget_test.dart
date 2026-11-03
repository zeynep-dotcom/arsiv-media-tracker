import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:arsiv_app/app.dart';
import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/services/app_services.dart';
import 'package:arsiv_app/services/auth_service.dart';
import 'package:arsiv_app/services/content_service.dart';
import 'package:arsiv_app/services/google_books_service.dart';
import 'package:arsiv_app/services/http_json.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/rawg_service.dart';
import 'package:arsiv_app/services/sample_data.dart';
import 'package:arsiv_app/services/tmdb_service.dart';

/// Testlerde internete çıkmamak için sahte servis.
class FakeService implements ContentService {
  FakeService(this.items);
  final List<ContentItem> items;

  @override
  Future<List<ContentItem>> getPopular({int page = 1}) async =>
      page == 1 ? items : const [];

  @override
  Future<List<ContentItem>> search(String query, {int page = 1}) async =>
      page > 1
          ? const []
          : items
              .where(
                  (b) => b.title.toLowerCase().contains(query.toLowerCase()))
              .toList();

  @override
  Future<List<ContentItem>> getByGenre(Genre genre, {int page = 1}) async =>
      page == 1 ? items : const [];

  @override
  Future<ContentItem> getDetails(ContentItem item) async => item;
}

/// Testleri telefon boyutunda çalıştır (varsayılan 800x600 çok küçük).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

http.Response jsonResponse(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

void main() {
  setUp(() {
    AppServices.films = FakeService(SampleData.films);
    AppServices.books = FakeService(SampleData.books);
    AppServices.games = FakeService(SampleData.games);
    LibraryStore.instance.stop();
    // Uygulama AuthGate'ten açılır; testler giriş yapmış kullanıcıyla başlar.
    AuthService.instance = AuthService(
      auth: MockFirebaseAuth(signedIn: true),
      firestore: FakeFirebaseFirestore(),
    );
  });

  testWidgets('Alt menü dört ekran arasında geçiş yapar',
      (WidgetTester tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const ArsivApp());
    await tester.pumpAndSettle();

    expect(find.text('ARŞİV'), findsOneWidget);
    expect(find.text('Popüler Filmler'), findsOneWidget);

    await tester.tap(find.text('Kütüphanem').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Bu liste boş'), findsWidgets);

    await tester.tap(find.text('İstatistik'));
    await tester.pumpAndSettle();
    expect(find.text('İstatistiklerim'), findsOneWidget);
    expect(find.text('Kütüphanen boş'), findsOneWidget);

    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();
    expect(find.text('Film, kitap, oyun ya da tür ara'), findsOneWidget);
  });

  testWidgets('Detay ekranından kütüphaneye eklenir',
      (WidgetTester tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const ArsivApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Detay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detay'));
    await tester.pumpAndSettle();
    expect(find.text('Kütüphaneme Ekle'), findsOneWidget);

    await tester.ensureVisible(find.text('Kütüphaneme Ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kütüphaneme Ekle'));
    await tester.pump();
    expect(find.text('Kütüphanende'), findsOneWidget);
  });

  test('Bitti seçilince istatistik verisi oluşur', () {
    final store = LibraryStore.instance;
    final film = SampleData.films.first;
    store.add(film);
    expect(store.entryFor(film)!.status, LibraryStatus.planned);

    store.setStatus(film, LibraryStatus.done);
    final entry = store.entryFor(film)!;
    expect(entry.progress, 1);
    expect(entry.completedAt, isNotNull);

    store.setStatus(film, LibraryStatus.planned);
    expect(store.entryFor(film)!.completedAt, isNull);
  });

  group('GenreMap', () {
    test('Türkçe tür adlarını tanır', () {
      expect(GenreMap.match('korku')?.tmdbId, 27);
      expect(GenreMap.match('  KORKU ')?.booksSubject, 'horror');
      expect(GenreMap.match('Bilim kurgu')?.tmdbId, 878);
      expect(GenreMap.match('Dram')?.tmdbId, 18);
      expect(GenreMap.match('gerilim')?.booksSubject, 'thriller');
      expect(GenreMap.all.length, 9);
      expect(GenreMap.match('Harry Potter'), isNull);
    });
  });

  group('GoogleBooksService', () {
    test('volumeInfo alanlarını ContentItem modeline çevirir', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'intitle:dune');
        return jsonResponse({
          'items': [
            {
              'id': 'abc',
              'volumeInfo': {
                'title': 'Dune',
                'authors': ['Frank Herbert'],
                'publishedDate': '1965-08-01',
                'pageCount': 412,
                'averageRating': 4.5,
                'categories': ['Fiction'],
                'description': '<p>Çöl gezegeni</p>',
                'imageLinks': {
                  'thumbnail':
                      'http://books.google.com/x?id=abc&zoom=1&edge=curl',
                },
              },
            },
            {'id': 'no-title', 'volumeInfo': <String, dynamic>{}},
          ],
        });
      });

      final books =
          await GoogleBooksService(client: client, apiKey: '').search('dune');

      expect(books, hasLength(1));
      final book = books.single;
      expect(book.title, 'Dune');
      expect(book.type, ContentType.book);
      expect(book.year, 1965);
      expect(book.rating, 9.0);
      expect(book.meta, 'Frank Herbert · 412 sayfa');
      expect(book.description, 'Çöl gezegeni');
      expect(book.imageUrl, 'https://books.google.com/x?id=abc&zoom=1');
    });

    test('tür araması önce subject, boşsa yedek sorgularla yapılır', () async {
      final queries = <String?>[];
      final client = MockClient((request) async {
        queries.add(request.url.queryParameters['q']);
        return jsonResponse({'items': []});
      });
      final result = await GoogleBooksService(client: client, apiKey: '')
          .getByGenre(GenreMap.match('korku')!);
      expect(result, isEmpty);
      expect(queries, ['subject:horror', 'horror', 'Korku']);
    });

    test('503 gelirse tekrar dener ve sonucu döndürür', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        if (calls == 1) return http.Response('', 503);
        return jsonResponse({
          'items': [
            {
              'id': 'x',
              'volumeInfo': {'title': 'Roman'},
            },
          ],
        });
      });
      final books =
          await GoogleBooksService(client: client, apiKey: '').getPopular();
      expect(calls, 2);
      expect(books.single.title, 'Roman');
    });

    test('429 yanıtında anlaşılır hata verir', () async {
      final client = MockClient((_) async => http.Response('', 429));
      expect(
        GoogleBooksService(client: client, apiKey: '').getPopular(),
        throwsA(isA<ContentServiceException>()),
      );
    });

    test('getDetails /volumes/{id} ile yazar, sayfa ve açıklamayı ekler',
        () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/books/v1/volumes/abc');
        return jsonResponse({
          'id': 'abc',
          'volumeInfo': {
            'title': 'Dune',
            'authors': ['Frank Herbert', 'Brian Herbert'],
            'pageCount': 896,
            'averageRating': 4.0,
            'description': '<p>Tam <b>açıklama</b></p>',
            'categories': ['Fiction / Science Fiction / General'],
            'imageLinks': {
              'thumbnail': 'http://books.google.com/t.jpg',
              'large': 'http://books.google.com/l.jpg&edge=curl',
            },
          },
        });
      });
      const listItem = ContentItem(
        id: 'gb_abc',
        type: ContentType.book,
        title: 'Dune',
        year: 1965,
        rating: 0,
        genres: ['Kitap'],
        description: 'Kısa',
        meta: '',
        artColors: [],
      );

      final detail = await GoogleBooksService(client: client, apiKey: '')
          .getDetails(listItem);

      expect(detail.creator, 'Frank Herbert, Brian Herbert');
      expect(detail.length, 896);
      expect(detail.lengthLabel, '896 sayfa');
      expect(detail.description, 'Tam açıklama');
      expect(detail.rating, 8.0);
      expect(detail.genres, ['Science Fiction']);
      expect(detail.imageUrl, 'https://books.google.com/l.jpg');
      expect(detail.title, 'Dune'); // değişmeyen alanlar korunur
    });

    test('getDetails başka kaynağın öğesinde istek atmaz', () async {
      final client = MockClient((_) async => fail('istek atılmamalı'));
      final film = SampleData.films.first;
      final result = await GoogleBooksService(client: client, apiKey: '')
          .getDetails(film);
      expect(result, same(film));
    });

    test('sayfalama startIndex parametresiyle yapılır', () async {
      final starts = <String?>[];
      final client = MockClient((request) async {
        starts.add(request.url.queryParameters['startIndex']);
        return jsonResponse({'items': []});
      });
      final service = GoogleBooksService(client: client, apiKey: '');
      await service.search('dune');
      await service.search('dune', page: 3);
      expect(starts, ['0', '40']);
    });

    test('popülerin 2. sayfası 1. sayfada sonuç veren sorguyla istenir',
        () async {
      final requests = <String>[];
      final client = MockClient((request) async {
        final q = request.url.queryParameters['q']!;
        final start = request.url.queryParameters['startIndex']!;
        requests.add('$q@$start');
        if (q == 'roman') return jsonResponse({'items': []});
        return jsonResponse({
          'items': [
            {
              'id': 'n$start',
              'volumeInfo': {'title': 'Novel $start'},
            },
          ],
        });
      });
      final service = GoogleBooksService(client: client, apiKey: '');
      final page1 = await service.getPopular();
      final page2 = await service.getPopular(page: 2);
      expect(page1.single.title, 'Novel 0');
      expect(page2.single.title, 'Novel 20');
      expect(requests, ['roman@0', 'novel@0', 'novel@20']);
    });
  });

  group('JsonFetcher', () {
    test('süresi dolan önbellek 429 gelince yedek olarak kullanılır', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return calls == 1
            ? jsonResponse({'ok': true})
            : http.Response('', 429);
      });
      final fetcher = JsonFetcher(
        source: 'Test',
        client: client,
        cacheFor: Duration.zero,
        retries: 0,
      );
      final uri = Uri.https('example.com', '/x');
      expect(await fetcher.get(uri), {'ok': true});
      expect(await fetcher.get(uri), {'ok': true}); // 429, önbellekten
      expect(calls, 2);
    });

    test('önbellek yoksa 503 hata olarak iletilir', () async {
      final client = MockClient((_) async => http.Response('', 503));
      final fetcher = JsonFetcher(
        source: 'Test',
        client: client,
        retries: 0,
      );
      expect(
        fetcher.get(Uri.https('example.com', '/y')),
        throwsA(isA<ContentServiceException>()),
      );
    });
  });

  group('TmdbService', () {
    test('sonuçları ContentItem modeline çevirir', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['with_genres'], '27');
        expect(request.headers['Authorization'], 'Bearer eyJ.test.token');
        return jsonResponse({
          'results': [
            {
              'id': 42,
              'title': 'Korku Evi',
              'original_title': 'House of Fear',
              'release_date': '2024-10-31',
              'vote_average': 7.3,
              'genre_ids': [27, 53],
              'overview': 'Bir ev, bir sır.',
              'poster_path': '/p.jpg',
              'backdrop_path': '/b.jpg',
            },
          ],
        });
      });

      final films = await TmdbService(client: client, token: 'eyJ.test.token')
          .getByGenre(GenreMap.match('korku')!);

      final film = films.single;
      expect(film.type, ContentType.film);
      expect(film.year, 2024);
      expect(film.rating, 7.3);
      expect(film.genres, ['Korku', 'Gerilim']);
      expect(film.meta, 'House of Fear');
      expect(film.imageUrl, 'https://image.tmdb.org/t/p/w500/p.jpg');
      expect(film.backdropUrl, 'https://image.tmdb.org/t/p/w780/b.jpg');
    });

    test('kısa API Key api_key parametresiyle gönderilir', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['api_key'],
            '0123456789abcdef0123456789abcdef');
        expect(request.headers.containsKey('Authorization'), isFalse);
        return jsonResponse({'results': []});
      });
      await TmdbService(
              client: client, token: '0123456789abcdef0123456789abcdef')
          .getPopular();
    });

    test('anahtar yoksa istek atmadan hata verir', () async {
      final client = MockClient((_) async => fail('istek atılmamalı'));
      expect(
        TmdbService(client: client, token: '').getPopular(),
        throwsA(isA<ContentServiceException>()),
      );
    });
  });

  group('RawgService', () {
    test('sonuçları ContentItem modeline çevirir', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['tags'], 'horror');
        expect(request.url.queryParameters['key'], 'k');
        return jsonResponse({
          'results': [
            {
              'id': 7,
              'name': 'Karanlık Koridor',
              'released': '2023-02-14',
              'rating': 4.2,
              'background_image': 'https://media.rawg.io/x.jpg',
              'genres': [
                {'name': 'Action', 'slug': 'action'},
              ],
              'parent_platforms': [
                {
                  'platform': {'name': 'PC'},
                },
                {
                  'platform': {'name': 'PlayStation'},
                },
              ],
            },
          ],
        });
      });

      final games = await RawgService(client: client, apiKey: 'k')
          .getByGenre(GenreMap.match('korku')!);

      final game = games.single;
      expect(game.type, ContentType.game);
      expect(game.year, 2023);
      expect(game.rating, closeTo(8.4, 0.001));
      expect(game.genres, ['Aksiyon']);
      expect(game.meta, 'PC · PlayStation');
      expect(game.imageUrl, 'https://media.rawg.io/x.jpg');
    });

    test('getPopular sayfa numarasını page parametresiyle gönderir', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['page'], '3');
        return jsonResponse({'results': []});
      });
      final games =
          await RawgService(client: client, apiKey: 'k').getPopular(page: 3);
      expect(games, isEmpty);
    });

    test('son sayfadan sonrası (404) boş liste döner', () async {
      final client = MockClient(
          (_) async => http.Response('{"detail":"Invalid page."}', 404));
      final games =
          await RawgService(client: client, apiKey: 'k').getPopular(page: 50);
      expect(games, isEmpty);
    });

    test('getDetails description_raw, playtime ve geliştiriciyi ekler',
        () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/games/7');
        expect(request.url.queryParameters['key'], 'k');
        return jsonResponse({
          'id': 7,
          'name': 'Karanlık Koridor',
          'description_raw': 'Terk edilmiş bir hastanede geçen korku oyunu.'
              '\n\n\n\nKaranlıkta hayatta kal.\n\nEspañol\nUn juego de terror.',
          'playtime': 12,
          'developers': [
            {'name': 'Gece Stüdyo'},
            {'name': 'Ayna Games'},
            {'name': 'Üçüncü Ekip'},
          ],
        });
      });

      final base = ContentItem(
        id: 'rawg_7',
        type: ContentType.game,
        title: 'Karanlık Koridor',
        year: 2023,
        rating: 8.4,
        genres: const ['Aksiyon'],
        description: 'Aksiyon türünde bir oyun.',
        meta: 'PC',
        artColors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
      );

      final detail =
          await RawgService(client: client, apiKey: 'k').getDetails(base);

      expect(detail.description,
          'Terk edilmiş bir hastanede geçen korku oyunu.\n\nKaranlıkta hayatta kal.');
      expect(detail.length, 12);
      expect(detail.lengthLabel, '12 saat');
      expect(detail.creator, 'Gece Stüdyo, Ayna Games');
      // Listeden gelen alanlar korunur.
      expect(detail.title, 'Karanlık Koridor');
      expect(detail.year, 2023);
      expect(detail.meta, 'PC');
    });

    test('getDetails boş alanlarda eski bilgiyi korur', () async {
      final client = MockClient((_) async => jsonResponse({
            'id': 7,
            'description_raw': '',
            'playtime': 0,
            'developers': [],
          }));
      final base = ContentItem(
        id: 'rawg_7',
        type: ContentType.game,
        title: 'X',
        year: 0,
        rating: 0,
        genres: const ['Oyun'],
        description: 'Liste açıklaması',
        meta: '',
        artColors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
      );
      final detail =
          await RawgService(client: client, apiKey: 'k').getDetails(base);
      expect(detail.description, 'Liste açıklaması');
      expect(detail.length, isNull);
      expect(detail.creator, isNull);
    });

    test('getDetails örnek veride istek göndermeden öğeyi döndürür',
        () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return jsonResponse({});
      });
      final sample = SampleData.games.first;
      final detail =
          await RawgService(client: client, apiKey: 'k').getDetails(sample);
      expect(requests, 0);
      expect(detail, same(sample));
    });

    test('örnek oyunların açıklaması tek satırdan uzundur', () {
      for (final game in SampleData.games) {
        expect(game.description, contains('\n\n'), reason: game.title);
        expect(game.creator, isNotNull, reason: game.title);
        expect(game.lengthLabel, isNotNull, reason: game.title);
      }
    });

    test('ilk sayfadaki 404 hatası yutulmaz', () async {
      final client =
          MockClient((_) async => http.Response('{"detail":"x"}', 404));
      expect(
        RawgService(client: client, apiKey: 'k').getPopular(),
        throwsA(isA<ContentServiceException>()
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
