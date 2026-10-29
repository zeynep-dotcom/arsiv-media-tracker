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

  /// users/{uid}/library/{itemId} belgesi ve yerel kayıt için düz harita.
  /// Tarihler milisaniye olarak tutulur (Firestore'a bağımlı olmasın diye).
  Map<String, dynamic> toMap() => {
        'item': item.toMap(),
        'status': status.name,
        'progress': progress,
        'favorite': favorite,
        'userRating': userRating,
        'addedAt': addedAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
      };

  factory LibraryEntry.fromMap(Map<String, dynamic> map) {
    DateTime? date(Object? ms) =>
        ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null;

    return LibraryEntry(
      item: ContentItem.fromMap(Map<String, dynamic>.from(map['item'] as Map)),
      status: LibraryStatus.values.asNameMap()[map['status']] ??
          LibraryStatus.planned,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      favorite: map['favorite'] as bool? ?? false,
      userRating: (map['userRating'] as num?)?.toInt(),
      addedAt: date(map['addedAt']),
      completedAt: date(map['completedAt']),
    );
  }
}
