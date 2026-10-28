import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/services/content_service.dart';
import 'package:arsiv_app/services/google_books_service.dart';
import 'package:arsiv_app/services/rawg_service.dart';
import 'package:arsiv_app/services/tmdb_service.dart';

/// Uygulamanın kullandığı servisler tek yerde.
/// Testlerde bu alanlar sahte servislerle değiştirilebilir.
class AppServices {
  AppServices._();

  static ContentService films = TmdbService();
  static ContentService books = GoogleBooksService();
  static ContentService games = RawgService();

  static ContentService forType(ContentType type) => switch (type) {
        ContentType.film => films,
        ContentType.book => books,
        ContentType.game => games,
      };
}
