import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';

/// İlerlemeyi birimle gösterir: kitapta sayfa, oyunda saat, filmde dakika
/// ("140 / 350 sayfa"). Uzunluk ([ContentItem.length]) bilinmiyorsa yüzde
/// kullanılır ("%40"); "0 / 0" hiç görünmez.
///
/// İlerleme kayıtta her zaman 0-1 arası tutulur; birimler yalnızca gösterim
/// ve elle giriş için hesaplanır, böylece Firestore'daki alan değişmez.
class ProgressFormat {
  ProgressFormat._();

  /// Türün ilerleme birimi.
  static String unit(ContentType type) => switch (type) {
        ContentType.film => 'dk',
        ContentType.book => 'sayfa',
        ContentType.game => 'saat',
      };

  /// Toplam birim (350 sayfa gibi). Uzunluk yoksa ya da 0 ise null.
  static int? total(ContentItem item) {
    final length = item.length;
    return length != null && length > 0 ? length : null;
  }

  static bool hasUnits(ContentItem item) => total(item) != null;

  /// 0-1 arası ilerlemenin birim karşılığı (0.4 × 350 = 140).
  static int current(ContentItem item, double progress) {
    final max = total(item);
    if (max == null) return percent(progress);
    return (progress.clamp(0.0, 1.0) * max).round();
  }

  static int percent(double progress) =>
      (progress.clamp(0.0, 1.0) * 100).round();

  /// "140 / 350 sayfa" ya da uzunluk bilinmiyorsa "%40".
  static String label(ContentItem item, double progress) {
    final max = total(item);
    if (max == null) return '%${percent(progress)}';
    return '${current(item, progress)} / $max ${unit(item.type)}';
  }

  /// Elle girilen sayıyı (sayfa/saat/dakika ya da yüzde) 0-1 arasına çevirir.
  static double fromInput(ContentItem item, int value) {
    final max = total(item) ?? 100;
    return (value / max).clamp(0.0, 1.0).toDouble();
  }

  /// Elle girişte izin verilen en büyük değer.
  static int maxInput(ContentItem item) => total(item) ?? 100;
}
