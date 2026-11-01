import 'package:flutter/material.dart';

import 'package:arsiv_app/models/content_type.dart';

/// Üç API'den (TMDB, Google Books, RAWG) gelen veri bu ortak modele dönüşür.
/// Şimdilik örnek veriyle dolduruluyor; servisler hazır olunca aynı alanlar
/// API'den gelecek.
class ContentItem {
  const ContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.year,
    required this.rating,
    required this.genres,
    required this.description,
    required this.meta,
    required this.artColors,
    this.imageUrl,
    this.backdropUrl,
    this.creator,
    this.length,
  });

  final String id;
  final ContentType type;
  final String title;
  final int year;
  final double rating; // 0-10
  final List<String> genres;
  final String description;

  /// Türe özel kısa bilgi: süre, sayfa sayısı ya da platform.
  final String meta;

  /// Afiş/kapak adresi. API bağlanana kadar boş; yerine [artColors] ile
  /// çizilen görsel gösterilir.
  final String? imageUrl;

  /// Yatay geniş görsel (TMDB backdrop, RAWG arka plan). Öne çıkan kart ve
  /// Detay ekranının üstünde kullanılır; yoksa [imageUrl] gösterilir.
  final String? backdropUrl;
  final List<Color> artColors;

  /// Detay alanları: listelerde gelmez, Detay ekranı açılınca
  /// [ContentService.getDetails] ile doldurulur.
  /// Filmde yönetmen, kitapta yazar, oyunda geliştirici.
  final String? creator;

  /// Filmde süre (dakika), kitapta sayfa sayısı, oyunda ortalama oynama
  /// süresi (saat).
  final int? length;

  bool get hasRating => rating > 0;

  /// Kartlarda başlığın altındaki kısa bilgi: "2025 · ★ 8.4".
  String get shortInfo => [
        if (year > 0) '$year',
        if (hasRating) '★ ${rating.toStringAsFixed(1)}',
      ].join(' · ');

  /// Detay ekranındaki bilgi satırı: yıl · türler · süre/sayfa.
  String get detailInfo => [
        if (year > 0) '$year',
        if (genres.isNotEmpty) genres.join(', '),
        if (meta.isNotEmpty) meta,
      ].join(' · ');

  /// Detay ekranında [creator] satırının başlığı.
  String get creatorLabel => switch (type) {
        ContentType.film => 'Yönetmen',
        ContentType.book => 'Yazar',
        ContentType.game => 'Geliştirici',
      };

  /// [length] birimiyle: "148 dk", "412 sayfa", "25 saat". Yoksa null.
  String? get lengthLabel {
    final value = length;
    if (value == null || value <= 0) return null;
    return switch (type) {
      ContentType.film => '$value dk',
      ContentType.book => '$value sayfa',
      ContentType.game => '$value saat',
    };
  }

  /// Verilen alanları değiştirip yeni bir kopya döndürür. Servisler
  /// getDetails içinde listeden gelen öğeyi bununla zenginleştirir:
  /// `item.copyWith(creator: 'Christopher Nolan', length: 148)`.
  ContentItem copyWith({
    String? id,
    ContentType? type,
    String? title,
    int? year,
    double? rating,
    List<String>? genres,
    String? description,
    String? meta,
    List<Color>? artColors,
    String? imageUrl,
    String? backdropUrl,
    String? creator,
    int? length,
  }) =>
      ContentItem(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        year: year ?? this.year,
        rating: rating ?? this.rating,
        genres: genres ?? this.genres,
        description: description ?? this.description,
        meta: meta ?? this.meta,
        artColors: artColors ?? this.artColors,
        imageUrl: imageUrl ?? this.imageUrl,
        backdropUrl: backdropUrl ?? this.backdropUrl,
        creator: creator ?? this.creator,
        length: length ?? this.length,
      );

  String get ratingSource => switch (type) {
        ContentType.film => 'TMDB puanı',
        ContentType.book => 'Google Books puanı',
        ContentType.game => 'RAWG puanı',
      };

  /// Firestore ve yerel kayıt için düz harita (renkler ARGB sayısı olarak).
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'year': year,
        'rating': rating,
        'genres': genres,
        'description': description,
        'meta': meta,
        'imageUrl': imageUrl,
        'backdropUrl': backdropUrl,
        'creator': creator,
        'length': length,
        'artColors': [for (final c in artColors) c.toARGB32()],
      };

  factory ContentItem.fromMap(Map<String, dynamic> map) => ContentItem(
        id: map['id'] as String,
        type: ContentType.values.byName(map['type'] as String),
        title: map['title'] as String? ?? '',
        year: (map['year'] as num?)?.toInt() ?? 0,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        genres: List<String>.from(map['genres'] as List? ?? const []),
        description: map['description'] as String? ?? '',
        meta: map['meta'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        backdropUrl: map['backdropUrl'] as String?,
        creator: map['creator'] as String?,
        length: (map['length'] as num?)?.toInt(),
        artColors: [
          for (final c in map['artColors'] as List? ?? const [])
            Color((c as num).toInt()),
        ],
      );
}
