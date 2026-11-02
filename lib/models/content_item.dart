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
        artColors: [
          for (final c in map['artColors'] as List? ?? const [])
            Color((c as num).toInt()),
        ],
      );
}
