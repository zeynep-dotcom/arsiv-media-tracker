/// Uygulamadaki üç içerik türü.
enum ContentType {
  film('Film', 'Filmler'),
  book('Kitap', 'Kitaplar'),
  game('Oyun', 'Oyunlar');

  const ContentType(this.label, this.plural);
  final String label;
  final String plural;
}
