import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arsiv_app/core/auth_gate.dart';
import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/screens/onboarding/genre_preference_screen.dart';
import 'package:arsiv_app/services/auth_service.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/services/user_preferences.dart';

void main() {
  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Finder devam() => find.widgetWithText(FilledButton, 'Devam');
  bool enabled(WidgetTester tester) =>
      tester.widget<FilledButton>(devam()).onPressed != null;

  group('GenrePreferenceScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      required Future<void> Function(List<String>) onSave,
      VoidCallback? onSkip,
    }) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: GenrePreferenceScreen(onSave: onSave, onSkip: onSkip ?? () {}),
        ),
      );
    }

    testWidgets('9 tür görünür, 3 seçilmeden Devam kapalıdır', (tester) async {
      List<String>? saved;
      await pump(tester, onSave: (g) async => saved = g);

      expect(find.text('Hangi türleri seversin?'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(9));
      expect(enabled(tester), isFalse);

      await tester.tap(find.text('Gerilim'));
      await tester.tap(find.text('Korku'));
      await tester.pump();
      expect(find.text('2 / 3 seçildi'), findsOneWidget);
      expect(enabled(tester), isFalse);

      await tester.tap(find.text('Dram'));
      await tester.pump();
      expect(find.text('3 tür seçildi'), findsOneWidget);
      expect(enabled(tester), isTrue);

      await tester.tap(devam());
      await tester.pump();
      expect(saved, ['Korku', 'Dram', 'Gerilim']);
    });

    testWidgets('seçim kaldırılınca Devam yeniden kapanır', (tester) async {
      await pump(tester, onSave: (_) async {});
      for (final g in ['Korku', 'Dram', 'Gizem']) {
        await tester.tap(find.text(g));
      }
      await tester.pump();
      expect(enabled(tester), isTrue);

      await tester.tap(find.text('Gizem'));
      await tester.pump();
      expect(enabled(tester), isFalse);
    });

    testWidgets('Atla seçim yapmadan geçer', (tester) async {
      var skipped = false;
      await pump(tester, onSave: (_) async {}, onSkip: () => skipped = true);

      await tester.tap(find.text('Atla'));
      expect(skipped, isTrue);
    });

    testWidgets('kayıt başarısız olursa hata görünür', (tester) async {
      await pump(tester, onSave: (_) async => throw Exception('reddedildi'));
      for (final g in ['Korku', 'Dram', 'Gizem']) {
        await tester.tap(find.text(g));
      }
      await tester.pump();
      await tester.tap(devam());
      await tester.pumpAndSettle();

      expect(find.text('Kaydedilemedi. Tekrar dene.'), findsOneWidget);
    });
  });

  group('kayıttan sonra tür tercihi', () {
    late MockFirebaseAuth auth;
    late FakeFirebaseFirestore firestore;
    late AuthService service;

    tearDown(() {
      LibraryStore.instance.stop();
      UserPreferences.instance.stop();
    });

    Future<void> register(WidgetTester tester) async {
      usePhoneScreen(tester);
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'ahmet-uid'));
      firestore = FakeFirebaseFirestore();
      service = AuthService(auth: auth, firestore: firestore);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: AuthGate(
            service: service,
            home: const Scaffold(body: Text('ANA EKRAN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Finder field(String label) => find.widgetWithText(TextField, label);
      await tap(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.enterText(field('Ad'), 'Ahmet');
      await tester.enterText(field('E-posta'), 'ahmet@ornek.com');
      await tester.enterText(field('Şifre'), 'sifre123');
      await tester.enterText(field('Şifre tekrar'), 'sifre123');
      await tap(find.byType(Checkbox));
      await tap(find.widgetWithText(FilledButton, 'Kayıt ol'));
    }

    testWidgets('seçilen türler users/{uid} belgesine yazılır', (tester) async {
      await register(tester);
      expect(find.text('Hangi türleri seversin?'), findsOneWidget);
      expect(find.text('ANA EKRAN'), findsNothing);

      for (final g in ['Bilim kurgu', 'Fantastik', 'Macera']) {
        await tester.tap(find.text(g));
      }
      await tester.pump();
      await tester.tap(devam());
      await tester.pumpAndSettle();

      expect(find.text('ANA EKRAN'), findsOneWidget);
      final uid = auth.currentUser!.uid;
      final doc = await firestore.doc('users/$uid').get();
      expect(doc.data()?['favoriteGenres'], [
        'Bilim kurgu',
        'Fantastik',
        'Macera',
      ]);
      expect(doc.data()?['plan'], 'free');
      expect(UserPreferences.instance.favoriteGenres, [
        'Bilim kurgu',
        'Fantastik',
        'Macera',
      ]);
    });

    testWidgets('Atla ana ekrana geçer, tercih yazılmaz', (tester) async {
      await register(tester);

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      expect(find.text('ANA EKRAN'), findsOneWidget);
      final doc = await firestore.doc('users/${auth.currentUser!.uid}').get();
      expect(doc.data()?.containsKey('favoriteGenres'), isFalse);
    });
  });
}
