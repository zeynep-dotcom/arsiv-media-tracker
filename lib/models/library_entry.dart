import 'package:arsiv_app/models/content_item.dart';

/// Kullanıcının kütüphanesindeki durum (Ahmet'in liste türleri).
enum LibraryStatus {
  planned('İzlenecek'),
  inProgress('Devam ediyor'),
  done('Tamamlandı'),
  dropped('Yarım kaldı');

  const LibraryStatus(this.label);
  final String label;
}

/// Kütüphaneye eklenmiş bir içerik.
class LibraryEntry {
  LibraryEntry({
    required this.item,
    this.status = LibraryStatus.planned,
    this.progress = 0,
    this.favorite = false,
    this.userRating,
    DateTime? addedAt,
    this.completedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final ContentItem item;
  LibraryStatus status;
  double progress; // 0-1
  bool favorite;
  int? userRating; // 1-10

  /// Kütüphaneye eklenme ve tamamlanma zamanı (İstatistik bunları kullanır).
  final DateTime addedAt;
  DateTime? completedAt;
}
