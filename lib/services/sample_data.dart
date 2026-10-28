import 'package:flutter/material.dart';

import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';

/// API'ler bağlanana kadar ekranları dolduran örnek veri.
/// Hafta 2'de Ali Kağan (TMDB), Abdulkadir (Google Books) ve Enes (RAWG)
/// servisleri hazır olunca bu liste yerine API sonuçları kullanılacak.
class SampleData {
  SampleData._();

  static const List<ContentItem> films = [
    ContentItem(
      id: 'f1',
      type: ContentType.film,
      title: 'Kızıl Ufuk',
      year: 2025,
      rating: 8.1,
      genres: ['Dram', 'Macera'],
      meta: '2 sa 14 dk',
      description:
          'Çölün ortasında kaybolan bir keşif ekibi, gün batımında ortaya çıkan '
          'gizemli bir sinyalin peşine düşer.',
      artColors: [Color(0xFFE5484D), Color(0xFF6E1219)],
    ),
    ContentItem(
      id: 'f2',
      type: ContentType.film,
      title: 'Mavi Saat',
      year: 2025,
      rating: 8.4,
      genres: ['Bilim kurgu'],
      meta: '2 sa 08 dk',
      description:
          'Zamanın durduğu bir şehirde, genç bir saat ustası kayıp dakikaların '
          'izini sürer.',
      artColors: [Color(0xFF3B82F6), Color(0xFF0B1A3A)],
    ),
    ContentItem(
      id: 'f3',
      type: ContentType.film,
      title: 'Sessiz Liman',
      year: 2024,
      rating: 7.6,
      genres: ['Gerilim'],
      meta: '1 sa 52 dk',
      description:
          'Fırtınalı bir gecede limana sığınan yabancı, kasabanın unutmak '
          'istediği bir sırrı açığa çıkarır.',
      artColors: [Color(0xFF34D399), Color(0xFF0F3B33)],
    ),
    ContentItem(
      id: 'f4',
      type: ContentType.film,
      title: 'Ay Işığı',
      year: 2023,
      rating: 8.1,
      genres: ['Bilim kurgu', 'Dram'],
      meta: '2 sa 21 dk',
      description:
          'Ay üssünde tek başına kalan bir mühendis, Dünya ile bağlantısını '
          'yeniden kurmaya çalışır.',
      artColors: [Color(0xFF8B7CF6), Color(0xFF241A5C)],
    ),
    ContentItem(
      id: 'f5',
      type: ContentType.film,
      title: 'Gece Treni',
      year: 2022,
      rating: 7.2,
      genres: ['Gizem'],
      meta: '1 sa 47 dk',
      description:
          'Son seferdeki yolcular, bir sonraki istasyonun haritada olmadığını '
          'fark eder.',
      artColors: [Color(0xFF64748B), Color(0xFF1E2430)],
    ),
  ];

  static const List<ContentItem> books = [
    ContentItem(
      id: 'b1',
      type: ContentType.book,
      title: 'Son Sayfa',
      year: 2021,
      rating: 8.0,
      genres: ['Fantastik'],
      meta: '340 sayfa',
      description:
          'Bir kütüphaneci, her gece kendiliğinden yazılan bir kitabın son '
          'sayfasına ulaşmaya çalışır.',
      artColors: [Color(0xFF5FA8D3), Color(0xFF173B52)],
    ),
    ContentItem(
      id: 'b2',
      type: ContentType.book,
      title: 'Altın Pusula',
      year: 2019,
      rating: 8.7,
      genres: ['Fantastik', 'Macera'],
      meta: '412 sayfa',
      description:
          'Kuzeyin buzlu topraklarına uzanan bir yolculukta, gerçeği gösteren '
          'bir pusula iki dünyanın kaderini belirler.',
      artColors: [Color(0xFFF4B23E), Color(0xFF5A3A0A)],
    ),
    ContentItem(
      id: 'b3',
      type: ContentType.book,
      title: 'Gölge Protokolü',
      year: 2022,
      rating: 7.4,
      genres: ['Gerilim'],
      meta: '298 sayfa',
      description:
          'Emekli bir ajan, adını hiç duymadığı bir operasyonun baş şüphelisi '
          'olduğunu öğrenir.',
      artColors: [Color(0xFF7C8494), Color(0xFF22262E)],
    ),
    ContentItem(
      id: 'b4',
      type: ContentType.book,
      title: 'Rüzgârın Kızı',
      year: 2020,
      rating: 7.9,
      genres: ['Tarihî', 'Dram'],
      meta: '376 sayfa',
      description:
          'Ege kıyısındaki bir köyde büyüyen genç kız, ailesinin yüz yıllık '
          'hikâyesini yeniden yazar.',
      artColors: [Color(0xFF9BC53D), Color(0xFF2E4110)],
    ),
  ];

  static const List<ContentItem> games = [
    ContentItem(
      id: 'g1',
      type: ContentType.game,
      title: 'Neon Labirent',
      year: 2024,
      rating: 8.3,
      genres: ['Bulmaca', 'Macera'],
      meta: 'PC · PlayStation',
      description:
          'Sürekli değişen neon bir labirentte, her bölüm yeni bir kuralla '
          'başlar.',
      artColors: [Color(0xFFC04CFD), Color(0xFF3A1052)],
    ),
    ContentItem(
      id: 'g2',
      type: ContentType.game,
      title: 'Demir Vadi',
      year: 2023,
      rating: 7.8,
      genres: ['Strateji'],
      meta: 'PC',
      description:
          'Terk edilmiş bir maden vadisinde kendi kasabanı kur ve kışa hazırlan.',
      artColors: [Color(0xFF84CC16), Color(0xFF26380A)],
    ),
    ContentItem(
      id: 'g3',
      type: ContentType.game,
      title: 'Yedinci Kat',
      year: 2025,
      rating: 8.0,
      genres: ['Korku'],
      meta: 'PlayStation · Xbox',
      description:
          'Asansörün durmadığı yedinci katta neler olduğunu yalnızca sen '
          'öğrenebilirsin.',
      artColors: [Color(0xFFEC4899), Color(0xFF4A0F2C)],
    ),
    ContentItem(
      id: 'g4',
      type: ContentType.game,
      title: 'Kayıp Yıldız',
      year: 2022,
      rating: 8.6,
      genres: ['Bilim kurgu', 'Macera'],
      meta: 'PC · Switch',
      description:
          'Küçük bir uzay gemisiyle galaksinin kenarındaki kayıp yıldızı ara.',
      artColors: [Color(0xFF22D3EE), Color(0xFF0B3440)],
    ),
  ];

  static List<ContentItem> get all => [...films, ...books, ...games];

  static ContentItem get featured => films.first;

  static List<ContentItem> byType(ContentType type) => switch (type) {
        ContentType.film => films,
        ContentType.book => books,
        ContentType.game => games,
      };

  static List<ContentItem> similarTo(ContentItem item) => all
      .where((e) =>
          e.id != item.id && e.genres.any((g) => item.genres.contains(g)))
      .toList();
}
