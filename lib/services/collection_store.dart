import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/models/user_collection.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/save_errors.dart';

/// Kullanıcının koleksiyonları (Kütüphanem › Koleksiyonlar).
///
/// LibraryStore ile aynı kalıp: oturum açılınca (AuthGate [start] çağırır)
/// users/{uid}/collections dinlenir; her değişiklik önce bellekte yapılır,
/// sonra Firestore'a yazılır. Oturum yokken yalnızca bellekte tutar.
/// Firestore bir yazmayı reddederse "Kaydedilemedi. Tekrar dene." çıkar.
///
/// Kurallar:
/// - Koleksiyona eklenen içerik kütüphanede yoksa "İzlenecek" olarak
///   kütüphaneye de eklenir.
/// - Kütüphaneden silinen içerik bütün koleksiyonlardan çıkar.
/// - Silinen koleksiyonun içerikleri kütüphanede kalır.
/// - Geçersiz girişler sessizce düzeltilir: ad kırpılır / "Adsız koleksiyon"
///   olur; dolu (200 içerik) koleksiyona ekleme yapılmaz.
class CollectionStore extends ChangeNotifier {
  CollectionStore._(this._library);

  static final CollectionStore instance =
      CollectionStore._(LibraryStore.instance);

  final LibraryStore _library;
  final Map<String, UserCollection> _collections = {};
  int _nextId = 0;

  String? _uid;
  CollectionReference<Map<String, dynamic>>? _collection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// [uid] kullanıcısının koleksiyonlarını [collection]'dan yükler ve
  /// dinler. İlk liste geldiğinde tamamlanır. Aynı kullanıcı için tekrar
  /// çağrılırsa bir şey yapmaz.
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
        _collections
          ..clear()
          ..addEntries(snapshot.docs.map(_fromDoc).nonNulls);
        notifyListeners();
        if (!firstLoad.isCompleted) firstLoad.complete();
      },
      onError: (Object e) {
        debugPrint('[Koleksiyon] users/$uid/collections okunamadı · $e');
        if (!firstLoad.isCompleted) firstLoad.complete();
      },
    );
    return firstLoad.future;
  }

  /// Dinlemeyi bırakır ve bellekteki koleksiyonları boşaltır (çıkışta).
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _collection = null;
    _uid = null;
    _collections.clear();
    notifyListeners();
  }

  /// Bozuk bir belge tüm listeyi düşürmesin diye atlanır.
  static MapEntry<String, UserCollection>? _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      return MapEntry(doc.id, UserCollection.fromMap(doc.id, doc.data()));
    } catch (e) {
      debugPrint('[Koleksiyon] ${doc.id} okunamadı · $e');
      return null;
    }
  }

  /// En yeni oluşturulan başta.
  List<UserCollection> get collections =>
      _collections.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  UserCollection? byId(String id) => _collections[id];

  /// [itemId]'yi içeren koleksiyonlar ("Koleksiyona ekle" panelindeki
  /// işaretler için).
  List<UserCollection> containing(String itemId) =>
      collections.where((c) => c.contains(itemId)).toList();

  /// Koleksiyondaki içerikler, eklenme sırasıyla (kartlardaki afişler ve
  /// koleksiyon ekranı için). Kütüphanede bulunmayanlar atlanır.
  List<LibraryEntry> itemsOf(UserCollection collection) => [
        for (final itemId in collection.itemIds)
          ?_library.entryById(itemId),
      ];

  /// Yeni, boş koleksiyon oluşturur ve döndürür.
  UserCollection create(String name) {
    final collection = UserCollection(id: _newId(), name: name);
    _collections[collection.id] = collection;
    _write(collection.id, (doc) => doc.set(collection.toMap()));
    notifyListeners();
    return collection;
  }

  void rename(String id, String name) {
    final collection = _collections[id];
    if (collection == null) return;
    collection
      ..name = UserCollection.cleanName(name)
      ..updatedAt = DateTime.now();
    _write(id, (doc) => doc.update({
          'name': collection.name,
          'updatedAt': _ms(collection.updatedAt),
        }));
    notifyListeners();
  }

  /// Koleksiyonu siler; içerikleri kütüphanede kalır.
  void delete(String id) {
    if (_collections.remove(id) == null) return;
    _write(id, (doc) => doc.delete());
    notifyListeners();
  }

  /// [item]'ı koleksiyona ekler; kütüphanede yoksa oraya da ekler.
  /// Koleksiyon yoksa ya da doluysa bir şey yapmaz ve false döner.
  bool addItem(String id, ContentItem item) {
    final collection = _collections[id];
    if (collection == null) return false;
    if (collection.contains(item.id)) return true;
    if (collection.isFull) return false;

    if (!_library.contains(item)) _library.add(item);
    collection
      ..itemIds.add(item.id)
      ..updatedAt = DateTime.now();
    _write(id, (doc) => doc.update({
          'itemIds': FieldValue.arrayUnion([item.id]),
          'updatedAt': _ms(collection.updatedAt),
        }));
    notifyListeners();
    return true;
  }

  /// İçeriği yalnızca bu koleksiyondan çıkarır (kütüphanede kalır).
  void removeItem(String id, String itemId) {
    final collection = _collections[id];
    if (collection == null || !collection.itemIds.remove(itemId)) return;
    collection.updatedAt = DateTime.now();
    _write(id, (doc) => doc.update(_removal(itemId, collection.updatedAt)));
    notifyListeners();
  }

  /// İçeriği bütün koleksiyonlardan çıkarır (kütüphaneden silinince
  /// LibraryStore çağırır). Firestore'a tek seferde (batch) yazılır.
  void removeEverywhere(String itemId) {
    final now = DateTime.now();
    final changed = [
      for (final c in _collections.values)
        if (c.itemIds.remove(itemId)) c..updatedAt = now,
    ];
    if (changed.isEmpty) return;

    final ref = _collection;
    if (ref != null) {
      final batch = ref.firestore.batch();
      for (final c in changed) {
        batch.update(ref.doc(c.id), _removal(itemId, now));
      }
      batch.commit().catchError(
          (Object e) => SaveErrors.report('Koleksiyon $itemId', e));
    }
    notifyListeners();
  }

  /// Testler için bütün koleksiyonları siler.
  @visibleForTesting
  void clear() {
    _collections.clear();
    notifyListeners();
  }

  /// Oturum varsa users/{uid}/collections/{id} belgesine yazar; reddedilirse
  /// ortak uyarıyı gösterir. Oturum yoksa yalnızca bellekte kalır.
  void _write(
    String id,
    Future<void> Function(DocumentReference<Map<String, dynamic>> doc) op,
  ) {
    final ref = _collection;
    if (ref == null) return;
    op(ref.doc(id)).catchError(
        (Object e) => SaveErrors.report('Koleksiyon $id', e));
  }

  static Map<String, Object> _removal(String itemId, DateTime at) => {
        'itemIds': FieldValue.arrayRemove([itemId]),
        'updatedAt': _ms(at),
      };

  static int _ms(DateTime date) => date.millisecondsSinceEpoch;

  /// Oturum varken Firestore'un ürettiği kimlik, yoksa yerel kimlik.
  String _newId() =>
      _collection?.doc().id ??
      'c${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';
}
