import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import 'package:arsiv_app/core/auth_gate.dart';
import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/services/auth_service.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/sample_data.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late AuthService service;

  // AuthGate kütüphaneyi tek örnek LibraryStore üzerinden başlatır.
  tearDown(LibraryStore.instance.stop);

  void createService({bool signedIn = false}) {
    auth = MockFirebaseAuth(
      signedIn: signedIn,
      mockUser: MockUser(
        uid: 'akif-uid',
        email: 'akif@ornek.com',
        displayName: 'Akif',
      ),
    );
    firestore = FakeFirebaseFirestore();
    service = AuthService(auth: auth, firestore: firestore);
  }

  /// Ana ekran yerine, Hesabım'ı açan basit bir sayfa.
  Future<void> pumpGate(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: AuthGate(
        service: service,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openProfile(context, service: service),
              child: const Text('ANA EKRAN'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder button(String label) => find.widgetWithText(FilledButton, label);

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('oturum yoksa giriş ekranı açılır', (tester) async {
    createService();
    await pumpGate(tester);

    expect(button('Giriş yap'), findsOneWidget);
    expect(find.text('ANA EKRAN'), findsNothing);
  });

  testWidgets('oturum varsa ana ekran açılır', (tester) async {
    createService(signedIn: true);
    await pumpGate(tester);

    expect(find.text('ANA EKRAN'), findsOneWidget);
  });

  testWidgets('giriş yapınca ana ekrana geçer', (tester) async {
    createService();
    await pumpGate(tester);

    await tester.enterText(field('E-posta'), 'akif@ornek.com');
    await tester.enterText(field('Şifre'), 'sifre123');
    await tapVisible(tester, button('Giriş yap'));

    expect(find.text('ANA EKRAN'), findsOneWidget);
  });

  testWidgets('boş alanla giriş uyarı verir', (tester) async {
    createService();
    await pumpGate(tester);

    await tapVisible(tester, button('Giriş yap'));

    expect(find.text('E-posta ve şifreni gir.'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('yanlış şifrede Türkçe hata görünür', (tester) async {
    createService();
    whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
        .on(auth)
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await pumpGate(tester);

    await tester.enterText(field('E-posta'), 'akif@ornek.com');
    await tester.enterText(field('Şifre'), 'yanlis');
    await tapVisible(tester, button('Giriş yap'));

    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
    expect(find.text('ANA EKRAN'), findsNothing);
  });

  testWidgets('kayıt olunca ana ekrana geçer ve belge yazılır',
      (tester) async {
    createService();
    await pumpGate(tester);

    await tapVisible(tester, find.text('Hesabın yok mu? Kayıt ol'));
    await tester.enterText(field('Ad'), 'Akif');
    await tester.enterText(field('E-posta'), 'yeni@ornek.com');
    await tester.enterText(field('Şifre'), 'sifre123');
    await tester.enterText(field('Şifre tekrar'), 'sifre123');
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, button('Kayıt ol'));

    expect(find.text('ANA EKRAN'), findsOneWidget);
    final uid = auth.currentUser!.uid;
    final doc = await firestore.doc('users/$uid').get();
    expect(doc.data()?['name'], 'Akif');
    expect(doc.data()?['plan'], 'free');
  });

  testWidgets('şifreler farklıysa kayıt yapılmaz', (tester) async {
    createService();
    await pumpGate(tester);

    await tapVisible(tester, find.text('Hesabın yok mu? Kayıt ol'));
    await tester.enterText(field('Ad'), 'Akif');
    await tester.enterText(field('E-posta'), 'yeni@ornek.com');
    await tester.enterText(field('Şifre'), 'sifre123');
    await tester.enterText(field('Şifre tekrar'), 'sifre456');
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, button('Kayıt ol'));

    expect(find.text('Şifreler aynı değil.'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('şifremi unuttum bağlantı gönderir', (tester) async {
    createService();
    await pumpGate(tester);

    await tapVisible(tester, find.text('Şifremi unuttum'));
    await tester.enterText(field('E-posta'), 'akif@ornek.com');
    await tapVisible(tester, button('Bağlantı gönder'));

    expect(find.text('E-postanı kontrol et'), findsOneWidget);
  });

  testWidgets('Hesabım ekranından çıkış yapınca giriş ekranına döner',
      (tester) async {
    createService(signedIn: true);
    await firestore.doc('users/akif-uid').set({'plan': 'free'});
    await pumpGate(tester);

    await tapVisible(tester, find.text('ANA EKRAN'));
    expect(find.text('Hesabım'), findsOneWidget);
    expect(find.text('akif@ornek.com'), findsOneWidget);
    expect(find.text('Ücretsiz'), findsOneWidget);

    await tapVisible(tester, find.text('Çıkış yap'));

    expect(auth.currentUser, isNull);
    expect(find.text('Hesabım'), findsNothing);
    expect(button('Giriş yap'), findsOneWidget);
  });

  testWidgets('giriş yapınca kütüphane kullanıcının koleksiyonuna yazılır',
      (tester) async {
    createService();
    await pumpGate(tester);

    await tester.enterText(field('E-posta'), 'akif@ornek.com');
    await tester.enterText(field('Şifre'), 'sifre123');
    await tapVisible(tester, button('Giriş yap'));

    final film = SampleData.films.first;
    final library = LibraryStore.instance;
    await tester.runAsync(() async {
      library.add(film);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    final doc = await tester.runAsync(
        () => firestore.doc('users/akif-uid/library/${film.id}').get());
    expect(doc?.exists, isTrue);

    await service.logout();
    await tester.pumpAndSettle();
    expect(library.entries, isEmpty);
    expect(button('Giriş yap'), findsOneWidget);
  });
}
