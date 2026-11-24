import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/models/user_collection.dart';
import 'package:arsiv_app/services/collection_store.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/save_errors.dart';
import 'package:arsiv_app/services/sample_data.dart';

void main() {
  group('UserCollection', () {
    test('toMap / fromMap tüm alanları korur', () {
      final collection = UserCollection(
        id: 'c1',
        name: 'Yaz listesi',
        itemIds: ['tmdb_1', 'gb_2'],
        createdAt: DateTime(2026, 11, 20, 10),
        updatedAt: DateTime(2026, 11, 21, 18, 30),
      );

      final copy = UserCollection.fromMap('c1', collection.toMap());

      expect(copy.id, 'c1');
      expect(copy.name, 'Yaz listesi');
      expect(copy.itemIds, ['tmdb_1', 'gb_2']);
      expect(copy.createdAt, collection.createdAt);
      expect(copy.updatedAt, collection.updatedAt);
      expect(collection.toMap().containsKey('id'), isFalse);
    });

    test('eksik ya da bozuk alanlar varsayılana döner', () {
      final copy = UserCollection.fromMap('c2', {'itemIds': 'yanlis'});
      expect(copy.name, UserCollection.defaultName);
      expect(copy.itemIds, isEmpty);
    });

    test('ad sessizce düzeltilir', () {
      expect(UserCollection.cleanName('  Favoriler  '), 'Favoriler');
      expect(UserCollection.cleanName('   '), UserCollection.defaultName);
      final long = UserCollection.cleanName('ç' * 50);
      expect(long.runes.length, UserCollection.maxNameLength);
    });
  });

  group('CollectionStore (bellek içi)', () {
    final store = CollectionStore.instance;
    final library = LibraryStore.instance;
    final film = SampleData.films.first;
    final book = SampleData.books.first;

    setUp(() {
      library.stop();
      store.clear();
    });

    test('oluşturur, adlandırır ve siler', () {
      final c = store.create('Hafta sonu');
      expect(store.collections.map((c) => c.name), ['Hafta sonu']);

      store.rename(c.id, '  Yaz tatili ');
      expect(store.byId(c.id)?.name, 'Yaz tatili');

      store.delete(c.id);
      expect(store.collections, isEmpty);
      expect(store.byId(c.id), isNull);
    });

    test('en yeni koleksiyon başta gelir', () async {
      store.create('Birinci');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      store.create('İkinci');
      expect(store.collections.map((c) => c.name), ['İkinci', 'Birinci']);
    });

    test('eklenen içerik kütüphanede yoksa İzlenecek olarak eklenir', () {
      final c = store.create('Filmler');

      expect(store.addItem(c.id, film), isTrue);

      expect(c.itemIds, [film.id]);
      expect(library.entryFor(film)?.status, LibraryStatus.planned);
      expect(store.itemsOf(c).map((e) => e.item.id), [film.id]);
    });

    test('kütüphanedeki durum korunur, aynı içerik iki kez eklenmez', () {
      library.setStatus(film, LibraryStatus.done);
      final c = store.create('Bitenler');

      store.addItem(c.id, film);
      store.addItem(c.id, film);

      expect(c.itemIds, [film.id]);
      expect(library.entryFor(film)?.status, LibraryStatus.done);
    });

    test('içerik çıkarılınca kütüphanede kalır', () {
      final c = store.create('Liste');
      store.addItem(c.id, film);

      store.removeItem(c.id, film.id);

      expect(c.itemIds, isEmpty);
      expect(library.contains(film), isTrue);
    });

    test('koleksiyon silinince içerikleri kütüphanede kalır', () {
      final c = store.create('Liste');
      store.addItem(c.id, film);
      store.addItem(c.id, book);

      store.delete(c.id);

      expect(library.contains(film), isTrue);
      expect(library.contains(book), isTrue);
    });

    test('kütüphaneden silinen içerik bütün koleksiyonlardan çıkar', () {
      final a = store.create('A');
      final b = store.create('B');
      store.addItem(a.id, film);
      store.addItem(b.id, film);
      store.addItem(b.id, book);

      library.remove(film);

      expect(a.itemIds, isEmpty);
      expect(b.itemIds, [book.id]);
      expect(store.containing(film.id), isEmpty);
      expect(store.containing(book.id).map((c) => c.id), [b.id]);
    });

    test('200 içeriğe ulaşınca yeni ekleme yapılmaz', () {
      final c = store.create('Dolu');
      for (var i = 0; i < UserCollection.maxItems; i++) {
        expect(store.addItem(c.id, _item('x$i')), isTrue);
      }

      expect(store.addItem(c.id, _item('fazla')), isFalse);
      expect(c.itemIds.length, UserCollection.maxItems);
      expect(library.entryById('fazla'), isNull);
    });

    test('olmayan koleksiyona işlem bir şey yapmaz', () {
      expect(store.addItem('yok', film), isFalse);
      store.rename('yok', 'Ad');
      store.removeItem('yok', film.id);
      store.delete('yok');
      expect(store.collections, isEmpty);
      expect(library.contains(film), isFalse);
    });

    test('her değişiklikte dinleyiciler haberdar edilir', () {
      var calls = 0;
      void listener() => calls++;
      store.addListener(listener);
      addTearDown(() => store.removeListener(listener));

      final c = store.create('Liste');
      store.rename(c.id, 'Yeni ad');
      store.addItem(c.id, film);
      store.removeItem(c.id, film.id);
      store.delete(c.id);

      expect(calls, 5);
    });
  });

  group('CollectionStore Firestore eşitlemesi', () {
    final store = CollectionStore.instance;
    final library = LibraryStore.instance;
    final film = SampleData.films.first;
    final book = SampleData.books.first;

    late FakeFirebaseFirestore firestore;

    setUp(() {
      library.stop();
      store.stop();
      firestore = FakeFirebaseFirestore();
    });
    tearDown(() {
      store.stop();
      library.stop();
    });

    Future<void> startFor(String uid) =>
        store.start(uid, firestore.collection('users/$uid/collections'));

    /// Firestore'a yazma arka planda biter; kısa bir bekleme yeterli.
    Future<Map<String, dynamic>?> docData(String path) async {
      await Future<void>.delayed(Duration.zero);
      return (await firestore.doc(path).get()).data();
    }

    test('oluşturulan koleksiyon users/{uid}/collections/{id} belgesine '
        'yazılır', () async {
      await startFor('u1');
      final c = store.create('Yaz listesi');

      final data = await docData('users/u1/collections/${c.id}');
      expect(data?['name'], 'Yaz listesi');
      expect(data?['itemIds'], isEmpty);
      expect(data?['createdAt'], isA<int>());
    });

    test('ekleme, çıkarma ve yeniden adlandırma yazılır', () async {
      await startFor('u1');
      final c = store.create('Liste');
      store.addItem(c.id, film);
      store.addItem(c.id, book);
      store.removeItem(c.id, film.id);
      store.rename(c.id, 'Kitaplar');

      final data = await docData('users/u1/collections/${c.id}');
      expect(data?['itemIds'], [book.id]);
      expect(data?['name'], 'Kitaplar');
    });

    test('silinen koleksiyonun belgesi silinir', () async {
      await startFor('u1');
      final c = store.create('Geçici');
      await docData('users/u1/collections/${c.id}');

      store.delete(c.id);
      expect(await docData('users/u1/collections/${c.id}'), isNull);
    });

    test('kütüphaneden silinen içerik bütün koleksiyon belgelerinden çıkar',
        () async {
      await startFor('u1');
      final a = store.create('A');
      final b = store.create('B');
      store.addItem(a.id, film);
      store.addItem(b.id, film);
      store.addItem(b.id, book);
      await docData('users/u1/collections/${b.id}');

      library.remove(film);

      expect((await docData('users/u1/collections/${a.id}'))?['itemIds'],
          isEmpty);
      expect((await docData('users/u1/collections/${b.id}'))?['itemIds'],
          [book.id]);
    });

    test('oturum açılınca kayıtlı koleksiyonlar yüklenir, bozuk belge '
        'atlanır', () async {
      await firestore.doc('users/u1/collections/c1').set(UserCollection(
            id: 'c1',
            name: 'Kayıtlı',
            itemIds: [book.id],
          ).toMap());
      await firestore.doc('users/u1/collections/bozuk').set({'name': 42});

      await startFor('u1');

      expect(store.collections.map((c) => c.id), ['c1']);
      expect(store.byId('c1')?.itemIds, [book.id]);
    });

    test('çıkışta boşalır, başka kullanıcı kendi koleksiyonlarını görür',
        () async {
      await startFor('u1');
      store.create('Birinin listesi');
      await docData('users/u1/collections/x');

      store.stop();
      expect(store.collections, isEmpty);

      await startFor('u2');
      expect(store.collections, isEmpty);
    });
  });

  testWidgets('Firestore yazmayı reddederse "Kaydedilemedi" uyarısı çıkar',
      (tester) async {
    const denyAll = '''
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}''';
    final auth = MockFirebaseAuth(signedIn: true);
    final firestore = FakeFirebaseFirestore(
      securityRules: denyAll,
      authObject: auth.authForFakeFirestore,
    );
    final store = CollectionStore.instance;
    addTearDown(store.stop);

    await tester.pumpWidget(MaterialApp(
      scaffoldMessengerKey: SaveErrors.messengerKey,
      home: const Scaffold(),
    ));

    await tester.runAsync(() async {
      await store.start('u1', firestore.collection('users/u1/collections'));
      store.create('Reddedilecek');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.text(SaveErrors.message), findsOneWidget);
  });
}

ContentItem _item(String id) => ContentItem(
      id: id,
      type: ContentType.film,
      title: id,
      year: 2026,
      rating: 0,
      genres: const [],
      description: '',
      meta: '',
      artColors: const [],
    );
