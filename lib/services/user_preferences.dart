import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:arsiv_app/core/config/genre_map.dart';

/// Kullanıcının tür tercihleri: users/{uid} belgesindeki [field] alanı.
/// Oturum açılınca (AuthGate [start] çağırır) belgeyi dinler; öneri motoru
/// ve "Hangi türleri seversin?" ekranı buradan okur ve yazar.
class UserPreferences extends ChangeNotifier {
  UserPreferences._();

  static final UserPreferences instance = UserPreferences._();

  /// Firestore'daki alan adı; değerler GenreMap etiketleridir ("Dram").
  static const field = 'favoriteGenres';

  /// "Hangi türleri seversin?" ekranında en az seçilmesi gereken tür.
  static const minGenres = 3;

  DocumentReference<Map<String, dynamic>>? _doc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  List<String> _favoriteGenres = const [];

  /// Seçilen türler, GenreMap sırasıyla. Seçim yoksa boş liste.
  List<String> get favoriteGenres => _favoriteGenres;

  /// [doc] belgesini (users/{uid}) dinlemeye başlar. Aynı belge için tekrar
  /// çağrılırsa bir şey yapmaz.
  void start(DocumentReference<Map<String, dynamic>> doc) {
    final current = _doc;
    if (current != null &&
        current.path == doc.path &&
        identical(current.firestore, doc.firestore)) {
      return;
    }
    stop();
    _doc = doc;
    _subscription = doc.snapshots().listen(
      (snapshot) => _set(snapshot.data()?[field]),
      onError: (Object e) =>
          debugPrint('[Tercihler] ${doc.path} okunamadı · $e'),
    );
  }

  /// Dinlemeyi bırakır ve tercihleri boşaltır (çıkış yapılınca).
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _doc = null;
    _set(null);
  }

  /// Seçilen türleri kaydeder. Belgedeki diğer alanlar (plan, ad) korunur:
  /// güvenlik kuralı plan alanını kontrol ettiği için set(merge: true)
  /// kullanılır. Kayıt başarısız olursa hata fırlatır.
  Future<void> saveFavoriteGenres(List<String> genres) async {
    final clean = cleanGenres(genres);
    _set(clean);
    await _doc?.set({field: clean}, SetOptions(merge: true));
  }

  void _set(Object? raw) {
    final next = raw is List
        ? cleanGenres(raw.whereType<String>())
        : const <String>[];
    if (listEquals(next, _favoriteGenres)) return;
    _favoriteGenres = next;
    notifyListeners();
  }

  /// GenreMap'te olmayan ya da tekrarlanan değerleri atar, GenreMap
  /// sırasına dizer.
  static List<String> cleanGenres(Iterable<String> genres) {
    final wanted = genres.toSet();
    return [
      for (final genre in GenreMap.all)
        if (wanted.contains(genre.label)) genre.label,
    ];
  }
}
