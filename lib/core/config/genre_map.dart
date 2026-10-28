/// Türkçe tür adlarını her API'nin anladığı değere çeviren tablo (Ahmet).
///
/// TMDB türleri sayı kimliğiyle, Google Books konularla (subject), RAWG ise
/// tür (genres) ya da etiketle (tags) arar. RAWG değerleri Enes'in deneme
/// istekleriyle doğrulanmalı.
class Genre {
  const Genre({
    required this.label,
    required this.aliases,
    required this.tmdbId,
    required this.booksSubject,
    required this.rawgParam,
    required this.rawgValue,
  });

  final String label;
  final List<String> aliases;
  final int tmdbId;
  final String booksSubject;

  /// RAWG'de 'genres' ya da 'tags'.
  final String rawgParam;
  final String rawgValue;
}

class GenreMap {
  GenreMap._();

  static const List<Genre> all = [
    Genre(
      label: 'Korku',
      aliases: ['korku', 'horror'],
      tmdbId: 27,
      booksSubject: 'horror',
      rawgParam: 'tags',
      rawgValue: 'horror',
    ),
    Genre(
      label: 'Bilim kurgu',
      aliases: ['bilim kurgu', 'bilimkurgu', 'bilim-kurgu', 'sci-fi', 'science fiction'],
      tmdbId: 878,
      booksSubject: 'science fiction',
      rawgParam: 'tags',
      rawgValue: 'sci-fi',
    ),
    Genre(
      label: 'Fantastik',
      aliases: ['fantastik', 'fantasy'],
      tmdbId: 14,
      booksSubject: 'fantasy',
      rawgParam: 'tags',
      rawgValue: 'fantasy',
    ),
    Genre(
      label: 'Macera',
      aliases: ['macera', 'adventure'],
      tmdbId: 12,
      booksSubject: 'adventure',
      rawgParam: 'genres',
      rawgValue: 'adventure',
    ),
    Genre(
      label: 'Aksiyon',
      aliases: ['aksiyon', 'action'],
      tmdbId: 28,
      booksSubject: 'action',
      rawgParam: 'genres',
      rawgValue: 'action',
    ),
    Genre(
      label: 'Komedi',
      aliases: ['komedi', 'comedy', 'mizah'],
      tmdbId: 35,
      booksSubject: 'humor',
      rawgParam: 'tags',
      rawgValue: 'funny',
    ),
    Genre(
      label: 'Gizem',
      aliases: ['gizem', 'mystery', 'polisiye'],
      tmdbId: 9648,
      booksSubject: 'mystery',
      rawgParam: 'tags',
      rawgValue: 'mystery',
    ),
  ];

  /// Aranan kelime bir türle eşleşiyorsa o türü döndürür, yoksa null.
  static Genre? match(String query) {
    final q = normalize(query);
    if (q.isEmpty) return null;
    for (final genre in all) {
      if (genre.aliases.any((a) => normalize(a) == q)) return genre;
    }
    return null;
  }

  /// Türkçe büyük/küçük harf farkını giderir (İ → i, I → ı).
  static String normalize(String text) => text
      .trim()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}
