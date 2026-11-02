import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';

/// Kullanıcının kütüphanesi. Oturum açılınca (AuthGate [start] çağırır)
/// users/{uid}/library koleksiyonunu dinler; her değişiklik önce bellekte
/// yapılır, sonra Firestore'a yazılır. Oturum yokken yalnızca bellekte tutar.
class LibraryStore extends ChangeNotifier {
  LibraryStore._();

  static final LibraryStore instance = LibraryStore._();

  final Map<String, LibraryEntry> _entries = {};

  String? _uid;
  CollectionReference<Map<String, dynamic>>? _collection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// [uid] kullanıcısının kütüphanesini [collection]'dan yükler ve dinler.
  /// İlk liste geldiğinde tamamlanır. Aynı kullanıcı için tekrar çağrılırsa
  /// bir şey yapmaz.
  Future<void> start(
    String uid,
    CollectionReference<Map<String, dynamic>> collection,
  ) {
    if (_uid == uid) return Future.value();
    stop();
    _uid = uid;
    _collection = collection;

    final firstLoad = Completer<void>();
    _subscription = collection.snapshots().listen(
      (snapshot) {
        _entries
          ..clear()
          ..addEntries(snapshot.docs.map(_fromDoc).nonNulls);
        notifyListeners();
        if (!firstLoad.isCompleted) firstLoad.complete();
      },
      onError: (Object e) {
        debugPrint('[Kütüphane] users/$uid/library okunamadı · $e');
        if (!firstLoad.isCompleted) firstLoad.complete();
      },
    );
    return firstLoad.future;
  }

  /// Dinlemeyi bırakır ve bellekteki listeyi boşaltır (çıkış yapılınca).
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _collection = null;
    _uid = null;
    _entries.clear();
    notifyListeners();
  }

  /// Bozuk bir belge tüm listeyi düşürmesin diye atlanır.
  static MapEntry<String, LibraryEntry>? _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      return MapEntry(doc.id, LibraryEntry.fromMap(doc.data()));
    } catch (e) {
      debugPrint('[Kütüphane] ${doc.id} okunamadı · $e');
      return null;
    }
  }

  void _save(LibraryEntry entry) {
    _collection
        ?.doc(entry.item.id)
        .set(entry.toMap())
        .catchError((Object e) => debugPrint(
            '[Kütüphane] ${entry.item.id} kaydedilemedi · $e'));
  }

  void _delete(String itemId) {
    _collection?.doc(itemId).delete().catchError(
        (Object e) => debugPrint('[Kütüphane] $itemId silinemedi · $e'));
  }

  List<LibraryEntry> get entries => _entries.values.toList();

  LibraryEntry? entryFor(ContentItem item) => _entries[item.id];

  bool contains(ContentItem item) => _entries.containsKey(item.id);

  LibraryEntry _ensure(ContentItem item) =>
      _entries.putIfAbsent(item.id, () => LibraryEntry(item: item));

  void add(ContentItem item) {
    _save(_ensure(item));
    notifyListeners();
  }

  void remove(ContentItem item) {
    _entries.remove(item.id);
    _delete(item.id);
    notifyListeners();
  }

  void toggleFavorite(ContentItem item) {
    final entry = _ensure(item);
    entry.favorite = !entry.favorite;
    _save(entry);
    notifyListeners();
  }

  void rate(ContentItem item, int rating) {
    final entry = _ensure(item)..userRating = rating;
    _save(entry);
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
    _save(entry);
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
