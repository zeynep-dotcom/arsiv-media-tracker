import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:arsiv_app/services/google_books_service.dart';

http.Response _json(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

void main() {
  group('Barkodla kitap', () {
    test('normalizeIsbn ISBN-10/13 kabul eder, market barkodunu reddeder', () {
      expect(
        GoogleBooksService.normalizeIsbn('978-975-07-1938-7'),
        '9789750719387',
      );
      expect(GoogleBooksService.normalizeIsbn('0-306-40615-x'), '030640615X');
      expect(GoogleBooksService.normalizeIsbn('8690504000016'), isNull);
      expect(GoogleBooksService.normalizeIsbn('123'), isNull);
    });

    test('findByIsbn isbn: sorgusuyla kitabı bulur', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'isbn:9789750719387');
        return _json({
          'items': [
            {
              'id': 'abc',
              'volumeInfo': {
                'title': 'Tutunamayanlar',
                'imageLinks': {'thumbnail': 'http://books.google.com/k.jpg'},
              },
            },
          ],
        });
      });
      final book = await GoogleBooksService(
        client: client,
        apiKey: '',
      ).findByIsbn('9789750719387');
      expect(book?.title, 'Tutunamayanlar');
      expect(book?.imageUrl, 'https://books.google.com/k.jpg');
    });

    test(
      'Google Books kapak vermezse Open Library kapağı kullanılır',
      () async {
        final client = MockClient(
          (_) async => _json({
            'items': [
              {
                'id': 'abc',
                'volumeInfo': {'title': 'Kapaksız Kitap'},
              },
            ],
          }),
        );
        final book = await GoogleBooksService(
          client: client,
          apiKey: '',
        ).findByIsbn('9789750719387');
        expect(
          book?.imageUrl,
          'https://covers.openlibrary.org/b/isbn/9789750719387-L.jpg?default=false',
        );
      },
    );

    test('bulunamayan barkodda null döner', () async {
      final client = MockClient((_) async => _json({'totalItems': 0}));
      final book = await GoogleBooksService(
        client: client,
        apiKey: '',
      ).findByIsbn('9789750719387');
      expect(book, isNull);
    });

    test('ISBN olmayan barkodda istek atılmaz', () async {
      final client = MockClient((_) async => fail('istek atılmamalı'));
      final book = await GoogleBooksService(
        client: client,
        apiKey: '',
      ).findByIsbn('8690504000016');
      expect(book, isNull);
    });
  });
}
