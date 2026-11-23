import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import 'package:arsiv_app/services/auth_service.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late AuthService service;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    service = AuthService(auth: auth, firestore: firestore);
  });

  Matcher authError(String code) => isA<AuthException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.message, 'message', AuthService.messageFor(code));

  group('AuthService.register', () {
    test('hesap açar ve users/{uid} belgesini oluşturur', () async {
      final user =
          await service.register(' Akif ', 'akif@ornek.com ', 'sifre123');

      expect(service.currentUser?.uid, user.uid);
      expect(user.displayName, 'Akif');

      final doc = await firestore.doc('users/${user.uid}').get();
      expect(doc.data()?['name'], 'Akif');
      expect(doc.data()?['email'], 'akif@ornek.com');
      expect(doc.data()?['plan'], 'free');
      expect(doc.data()?['createdAt'], isA<Timestamp>());
    });

    test('aynı e-postayla ikinci kayıt Türkçe hata verir', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        () => service.register('Akif', 'akif@ornek.com', 'sifre123'),
        throwsA(authError('email-already-in-use')),
      );
    });

    test('zayıf şifre Türkçe hata verir', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'weak-password'));

      expect(
        () => service.register('Akif', 'akif@ornek.com', '123'),
        throwsA(authError('weak-password')),
      );
    });
  });

  group('AuthService.login / logout', () {
    test('giriş yapınca authStateChanges kullanıcıyı verir', () async {
      expectLater(
        service.authStateChanges,
        emitsInOrder([isNull, isA<User>()]),
      );
      final user = await service.login('akif@ornek.com', 'sifre123');
      expect(service.currentUser?.uid, user.uid);
    });

    test('yanlış şifre Türkçe hata verir', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      expect(
        () => service.login('akif@ornek.com', 'yanlis'),
        throwsA(authError('invalid-credential')),
      );
    });

    test('çıkış yapınca oturum kapanır', () async {
      await service.login('akif@ornek.com', 'sifre123');
      await service.logout();
      expect(service.currentUser, isNull);
    });
  });

  group('AuthService.sendPasswordReset', () {
    test('geçerli e-postada hata vermez', () async {
      await expectLater(
        service.sendPasswordReset('akif@ornek.com'),
        completes,
      );
    });

    test('geçersiz e-posta Türkçe hata verir', () async {
      whenCalling(Invocation.method(#sendPasswordResetEmail, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));

      expect(
        () => service.sendPasswordReset('akif'),
        throwsA(authError('invalid-email')),
      );
    });
  });

  group('AuthService.messageFor', () {
    test('plandaki hata kodlarının hepsi Türkçe', () {
      const fallback = 'Bir hata oluştu. Lütfen tekrar dene.';
      for (final code in [
        'invalid-credential',
        'email-already-in-use',
        'weak-password',
        'user-not-found',
        'too-many-requests',
        'network-request-failed',
      ]) {
        expect(AuthService.messageFor(code), isNot(fallback), reason: code);
      }
      expect(AuthService.messageFor('bilinmeyen-kod'), fallback);
    });
  });

  test('users/{uid} yazılamazsa kayıt Türkçe hatayla biter', () async {
    // Her yazmayı reddeden kural: kayıt yarım kalmamalı.
    const denyAll = '''
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}''';
    service = AuthService(
      auth: auth,
      firestore: FakeFirebaseFirestore(
        securityRules: denyAll,
        authObject: auth.authForFakeFirestore,
      ),
    );

    await expectLater(
      service.register('Akif', 'akif@ornek.com', 'sifre123'),
      throwsA(authError('unknown')),
    );
    // Hesabın geri silindiği (user.delete) burada ölçülemiyor:
    // MockUser.delete hiçbir şey yapmıyor.
  });
}
