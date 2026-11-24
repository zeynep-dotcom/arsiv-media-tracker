/// Kullanıcının oluşturduğu koleksiyon (ör. "Yaz tatili listesi").
///
/// Yalnızca içeriklerin kimliklerini ([itemIds]) tutar; içeriğin kendisi
/// kütüphanededir (LibraryStore). Bu yüzden koleksiyondaki her içerik
/// kütüphanede de bulunur.
class UserCollection {
  UserCollection({
    required this.id,
    required String name,
    List<String>? itemIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : name = cleanName(name),
        itemIds = [...?itemIds],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// Ad en fazla bu kadar karakter olabilir (firestore.rules ile aynı).
  static const maxNameLength = 40;

  /// Bir koleksiyonda en fazla bu kadar içerik olabilir.
  static const maxItems = 200;

  /// Ad boş bırakılırsa kullanılan ad.
  static const defaultName = 'Adsız koleksiyon';

  final String id;
  String name;
  final List<String> itemIds;
  final DateTime createdAt;
  DateTime updatedAt;

  bool get isFull => itemIds.length >= maxItems;

  bool contains(String itemId) => itemIds.contains(itemId);

  /// Adı sessizce düzeltir: boşluklar kırpılır, boşsa [defaultName],
  /// [maxNameLength] karakterden uzunsa kısaltılır.
  static String cleanName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return defaultName;
    final chars = name.runes.toList();
    if (chars.length <= maxNameLength) return name;
    return String.fromCharCodes(chars.take(maxNameLength)).trimRight();
  }

  /// users/{uid}/collections/{id} belgesi. Kimlik belgenin adıdır, haritada
  /// tutulmaz. Tarihler milisaniye (LibraryEntry ile aynı).
  Map<String, dynamic> toMap() => {
        'name': name,
        'itemIds': itemIds,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory UserCollection.fromMap(String id, Map<String, dynamic> map) {
    DateTime? date(Object? ms) =>
        ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null;

    final ids = map['itemIds'];
    return UserCollection(
      id: id,
      name: map['name'] as String? ?? '',
      itemIds: ids is List ? ids.whereType<String>().toList() : null,
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
    );
  }
}
