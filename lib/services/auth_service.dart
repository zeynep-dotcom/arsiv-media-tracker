import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Giriş/kayıt sırasında ekranda gösterilecek Türkçe hata.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;

  /// Firebase hata kodu (ör. "weak-password"); testler ve kayıt için.
  final String? code;

  @override
  String toString() => message;
}

/// Firebase Authentication ve kullanıcı belgesi (users/{uid}) işlemleri.
/// Ekranlar Firebase'i doğrudan değil, bu sınıfı kullanır.
/// Testlerde [auth] ve [firestore] sahteleriyle değiştirilebilir.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Uygulamanın kullandığı tek örnek; ilk erişimde oluşturulur.
  static AuthService instance = AuthService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Oturum açılınca kullanıcı, kapanınca null gelir (AuthGate dinler).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Hesap açar, adı profile yazar ve users/{uid} belgesini oluşturur.
  /// Belge yazılamazsa yarım kalmasın diye hesap geri silinir.
  Future<User> register(String name, String email, String password) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(e);
    }

    final user = credential.user!;
    try {
      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'plan': 'free',
      });
    } catch (e) {
      debugPrint('[Auth] users/${user.uid} yazılamadı · $e');
      await user.delete();
      final code = e is FirebaseException ? e.code : 'unknown';
      throw AuthException(messageFor(code), code: code);
    }
    return user;
  }

  Future<User> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Kullanıcının kütüphane koleksiyonu: users/{uid}/library.
  CollectionReference<Map<String, dynamic>> libraryOf(String uid) =>
      _firestore.collection('users').doc(uid).collection('library');

  /// users/{uid} belgesindeki üyelik planı ("free" ya da "premium").
  Future<String> fetchPlan() async {
    final user = _auth.currentUser;
    if (user == null) return 'free';
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['plan'] as String? ?? 'free';
  }

  AuthException _toAuthException(FirebaseException e) =>
      AuthException(messageFor(e.code), code: e.code);

  /// Firebase hata kodlarının Türkçe karşılıkları (Ahmet'in tablosu).
  static String messageFor(String code) => switch (code) {
        'invalid-credential' || 'wrong-password' => 'E-posta veya şifre hatalı.',
        'user-not-found' => 'Bu e-postayla kayıtlı bir hesap bulunamadı.',
        'email-already-in-use' => 'Bu e-postayla zaten bir hesap var.',
        'weak-password' => 'Şifre en az 6 karakter olmalı.',
        'invalid-email' => 'Geçerli bir e-posta adresi gir.',
        'missing-email' => 'E-posta adresi boş olamaz.',
        'missing-password' => 'Şifre boş olamaz.',
        'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
        'too-many-requests' =>
          'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
        'network-request-failed' => 'İnternet bağlantısı yok.',
        'permission-denied' => 'Hesap bilgileri kaydedilemedi.',
        _ => 'Bir hata oluştu. Lütfen tekrar dene.',
      };
}
