import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/models/progress_format.dart';
import 'package:arsiv_app/screens/library/library_screen.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/sample_data.dart';

/// Hafta 4 · Ece: birimli ilerleme, kaydırarak silme + "Geri al",
/// uzun basınca durum menüsü.
void main() {
  final store = LibraryStore.instance;
  // Uzunluk servislerden gelir; testte elle veriyoruz.
  final film = SampleData.films.first.copyWith(length: 134);
  final book = SampleData.books.first.copyWith(length: 340);
  final game = SampleData.games.first.copyWith(length: 18);
  final noLength = SampleData.games.last; // uzunluk bilinmiyor

  setUp(store.stop);
  tearDown(store.stop);

  group('ProgressFormat', () {
    test('türe göre birimle gösterir', () {
      expect(ProgressFormat.label(book, 0.4), '136 / 340 sayfa');
      expect(ProgressFormat.label(game, 0.5), '9 / 18 saat');
      expect(ProgressFormat.label(film, 1), '134 / 134 dk');
    });

    test('uzunluk bilinmiyorsa yüzde gösterir, "0 / 0" olmaz', () {
      expect(noLength.length, isNull);
      expect(ProgressFormat.label(noLength, 0.4), '%40');
      final zero = book.copyWith(length: 0);
      expect(ProgressFormat.label(zero, 0), '%0');
    });

    test('elle girilen sayı 0-1 aralığına çevrilir', () {
      expect(ProgressFormat.fromInput(book, 170), 0.5);
      expect(ProgressFormat.fromInput(book, 999), 1);
      expect(ProgressFormat.fromInput(noLength, 25), 0.25);
      expect(ProgressFormat.maxInput(book), 340);
      expect(ProgressFormat.maxInput(noLength), 100);
    });
  });

  group('LibraryStore', () {
    test('restore durum, puan, ilerleme ve tarihi geri getirir', () {
      store.add(book);
      store.setProgress(book, 0.4);
      store.rate(book, 9);
      store.toggleFavorite(book);
      final snapshot = store.entryFor(book)!.copy();

      store.remove(book);
      expect(store.contains(book), isFalse);

      store.restore(snapshot);
      final entry = store.entryFor(book)!;
      expect(entry.status, LibraryStatus.inProgress);
      expect(entry.progress, 0.4);
      expect(entry.userRating, 9);
      expect(entry.favorite, isTrue);
      expect(entry.addedAt, snapshot.addedAt);
    });

    test('updateItem detaydan gelen uzunluğu kayda işler', () {
      final listItem = noLength;
      store.add(listItem);
      store.setProgress(listItem, 0.5);

      final ContentItem detailed = listItem.copyWith(length: 60);
      store.updateItem(detailed);

      final entry = store.entryFor(listItem)!;
      expect(entry.item.length, 60);
      expect(entry.progress, 0.5);
      expect(ProgressFormat.label(entry.item, entry.progress), '30 / 60 saat');
    });

    test('updateItem kütüphanede olmayan içeriği eklemez', () {
      store.updateItem(book);
      expect(store.contains(book), isFalse);
    });
  });

  group('Kütüphanem', () {
    Future<void> openBooks(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: LibraryScreen()),
      ));
      await tester.tap(find.text('Kitaplar'));
      await tester.pumpAndSettle();
    }

    testWidgets('sekmeler türü anlatır', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: LibraryScreen()),
      ));
      for (final tab in ['Filmler', 'Kitaplar', 'Oyunlar', 'Favoriler']) {
        expect(find.text(tab), findsOneWidget);
      }
    });

    testWidgets('satırda ilerleme birimle görünür', (tester) async {
      store.add(book);
      store.setProgress(book, 0.4);
      await openBooks(tester);
      expect(find.text('Kitap · 136 / 340 sayfa'), findsOneWidget);
    });

    testWidgets('sola kaydırınca silinir, "Geri al" geri getirir',
        (tester) async {
      store.add(book);
      store.setProgress(book, 0.4);
      store.rate(book, 9);
      await openBooks(tester);

      await tester.drag(find.text(book.title), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(store.contains(book), isFalse);
      expect(find.text('Geri al'), findsOneWidget);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      final entry = store.entryFor(book)!;
      expect(entry.progress, 0.4);
      expect(entry.userRating, 9);
      expect(entry.status, LibraryStatus.inProgress);
      expect(find.text(book.title), findsOneWidget);
    });

    testWidgets('uzun basınca durum menüsü açılır', (tester) async {
      store.add(book);
      await openBooks(tester);

      await tester.longPress(find.text(book.title));
      await tester.pumpAndSettle();
      expect(find.text('Okunuyor'), findsOneWidget);

      await tester.tap(find.text('Tamamlandı').last);
      await tester.pumpAndSettle();
      expect(store.entryFor(book)!.status, LibraryStatus.done);
      expect(store.entryFor(book)!.progress, 1);
    });
  });
}
