import 'package:flutter/foundation.dart';

import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';

/// Kullanıcının kütüphanesini bellekte tutar ve boş başlar.
/// Akif'in Firestore servisi hazır olunca kayıtlar users/{uid}/library
/// koleksiyonuna yazılacak; ekranlar bu sınıfı kullanmaya devam eder.
class LibraryStore extends ChangeNotifier {
  LibraryStore._();

  static final LibraryStore instance = LibraryStore._();

  final Map<String, LibraryEntry> _entries = {};

  List<LibraryEntry> get entries => _entries.values.toList();

  LibraryEntry? entryFor(ContentItem item) => _entries[item.id];

  bool contains(ContentItem item) => _entries.containsKey(item.id);

  LibraryEntry _ensure(ContentItem item) =>
      _entries.putIfAbsent(item.id, () => LibraryEntry(item: item));

  void add(ContentItem item) {
    _ensure(item);
    notifyListeners();
  }

  void remove(ContentItem item) {
    _entries.remove(item.id);
    notifyListeners();
  }

  void toggleFavorite(ContentItem item) {
    final entry = _ensure(item);
    entry.favorite = !entry.favorite;
    notifyListeners();
  }

  void rate(ContentItem item, int rating) {
    _ensure(item).userRating = rating;
    notifyListeners();
  }

  /// Durumu değiştirir; "Bitti" seçilince ilerleme %100 olur ve tamamlanma
  /// tarihi kaydedilir.
  void setStatus(ContentItem item, LibraryStatus status) {
    final entry = _ensure(item);
    entry.status = status;
    switch (status) {
      case LibraryStatus.planned:
        entry.progress = 0;
        entry.completedAt = null;
      case LibraryStatus.inProgress:
        if (entry.progress == 0 || entry.progress == 1) entry.progress = 0.3;
        entry.completedAt = null;
      case LibraryStatus.done:
        entry.progress = 1;
        entry.completedAt = DateTime.now();
      case LibraryStatus.dropped:
        entry.completedAt = null;
    }
    notifyListeners();
  }

  /// Testler için kütüphaneyi boşaltır.
  @visibleForTesting
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Kütüphanem sekmeleri: İzlenecek, Okunan, Oynanan, Favoriler.
  List<LibraryEntry> watchList() =>
      entries.where((e) => e.item.type == ContentType.film).toList();

  List<LibraryEntry> readList() =>
      entries.where((e) => e.item.type == ContentType.book).toList();

  List<LibraryEntry> playList() =>
      entries.where((e) => e.item.type == ContentType.game).toList();

  List<LibraryEntry> favorites() => entries.where((e) => e.favorite).toList();
}
