/// API anahtarları. Derleme sırasında env.json dosyasından gelir:
///   flutter run --dart-define-from-file=env.json
/// env.json Git'e eklenmez; örnek için env.example.json dosyasına bak.
class Env {
  Env._();

  static const tmdbToken = String.fromEnvironment('TMDB_TOKEN');
  static const googleBooksKey = String.fromEnvironment('GOOGLE_BOOKS_KEY');
  static const rawgKey = String.fromEnvironment('RAWG_KEY');
}
