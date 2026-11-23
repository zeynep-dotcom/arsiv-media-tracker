import 'package:flutter/material.dart';

/// Firestore bir kaydı reddedince (ör. güvenlik kuralı) gösterilen ortak
/// uyarı. Kütüphane ve koleksiyonlar hatayı buraya bildirir; uygulama hangi
/// ekranda olursa olsun altta tek bir SnackBar çıkar. Ekranların ayrıca bir
/// şey yapması gerekmez.
abstract final class SaveErrors {
  static const message = 'Kaydedilemedi. Tekrar dene.';

  /// MaterialApp.scaffoldMessengerKey olarak verilir (app.dart).
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// [where]: günlükte hangi kaydın düştüğünü göstermek için kısa etiket.
  static void report(String where, Object error) {
    debugPrint('[$where] kaydedilemedi · $error');
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(message)));
  }
}
