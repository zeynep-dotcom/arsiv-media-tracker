import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/sample_data.dart';

void main() {
  final store = LibraryStore.instance;
  final film = SampleData.films.first;
  final book = SampleData.books.first;

  late FakeFirebaseFirestore firestore;

  setUp(() {
    store.stop();
    firestore = FakeFirebaseFirestore();
  });
  tearDown(store.stop);

  Future<void> startFor(String uid) =>
      store.start(uid, firestore.collection('users/$uid/library'));

  /// Firestore'a yazma arka planda biter; kısa bir bekleme yeterli.
  Future<Map<String, dynamic>?> docData(String path) async {
    await Future<void>.delayed(Duration.zero);
    return (await firestore.doc(path).get()).data();
  }

  group('LibraryEntry.toMap / fromMap', () {
    test('tüm alanlar korunur', () {
      const item = ContentItem(
        id: 'rawg_42',
        type: ContentType.game,
        title: 'Örnek Oyun',
        year: 2024,
        rating: 8.5,
        genres: ['Aksiyon', 'RPG'],
        description: 'Açıklama',
        meta: 'PC, PS5',
        imageUrl: 'https://ornek.com/kapak.jpg',
        artColors: [Color(0xFF112233), Color(0x80AABBCC)],
      );
      final entry = LibraryEntry(
        item: item,
        status: LibraryStatus.done,
        progress: 1,
        favorite: true,
        userRating: 9,
        addedAt: DateTime(2026, 10, 1, 12),
        completedAt: DateTime(2026, 10, 20, 18, 30),
      );

      final copy = LibraryEntry.fromMap(entry.toMap());

      expect(copy.item.id, 'rawg_42');
      expect(copy.item.type, ContentType.game);
      expect(copy.item.title, 'Örnek Oyun');
      expect(copy.item.genres, ['Aksiyon', 'RPG']);
      expect(copy.item.imageUrl, 'https://ornek.com/kapak.jpg');
      expect(copy.item.backdropUrl, isNull);
      expect(copy.item.artColors, item.artColors);
      expect(copy.status, LibraryStatus.done);
      expect(copy.progress, 1);
      expect(copy.favorite, isTrue);
      expect(copy.userRating, 9);
      expect(copy.addedAt, entry.addedAt);
      expect(copy.completedAt, entry.completedAt);
    });

    test('eksik alanlar varsayılana döner', () {
      final copy = LibraryEntry.fromMap({
        'item': {'id': 'gb_1', 'type': 'book'},
      });
      expect(copy.item.title, '');
      expect(copy.status, LibraryStatus.planned);
      expect(copy.progress, 0);
      expect(copy.userRating, isNull);
      expect(copy.completedAt, isNull);
    });
  });

  group('LibraryStore Firestore eşitlemesi', () {
    test('eklenen içerik users/{uid}/library/{itemId} belgesine yazılır',
        () async {
      await startFor('u1');
      store.add(film);

      final data = await docData('users/u1/library/${film.id}');
      expect(data?['item']['title'], film.title);
      expect(data?['status'], 'planned');
    });

    test('durum, puan ve favori güncellemeleri yazılır', () async {
      await startFor('u1');
      store.setStatus(film, LibraryStatus.done);
      store.rate(film, 8);
      store.toggleFavorite(film);

      final data = await docData('users/u1/library/${film.id}');
      expect(data?['status'], 'done');
      expect(data?['progress'], 1);
      expect(data?['completedAt'], isA<int>());
      expect(data?['userRating'], 8);
      expect(data?['favorite'], isTrue);
    });

    test('kaldırılan içerik silinir', () async {
      await startFor('u1');
      store.add(film);
      await docData('users/u1/library/${film.id}');

      store.remove(film);
      expect(await docData('users/u1/library/${film.id}'), isNull);
    });

    test('oturum açılınca kayıtlı kütüphane yüklenir', () async {
      await firestore
          .doc('users/u1/library/${book.id}')
          .set(LibraryEntry(item: book, favorite: true).toMap());

      await startFor('u1');

      expect(store.contains(book), isTrue);
      expect(store.entryFor(book)?.favorite, isTrue);
    });

    test('bozuk belge atlanır, diğerleri yüklenir', () async {
      await firestore.doc('users/u1/library/bozuk').set({'item': 'yanlis'});
      await firestore
          .doc('users/u1/library/${book.id}')
          .set(LibraryEntry(item: book).toMap());

      await startFor('u1');

      expect(store.entries.map((e) => e.item.id), [book.id]);
    });

    test('çıkışta liste boşalır, başka kullanıcı kendi listesini görür',
        () async {
      await startFor('u1');
      store.add(film);
      await docData('users/u1/library/${film.id}');

      store.stop();
      expect(store.entries, isEmpty);

      await startFor('u2');
      expect(store.entries, isEmpty);

      store.add(book);
      await docData('users/u2/library/${book.id}');
      expect(
        (await firestore.collection('users/u1/library').get()).docs.length,
        1,
      );
    });

    test('oturum yokken yalnızca bellekte tutar', () async {
      store.add(film);
      expect(store.contains(film), isTrue);
      expect(
        (await firestore.collectionGroup('library').get()).docs,
        isEmpty,
      );
    });
  });
}
