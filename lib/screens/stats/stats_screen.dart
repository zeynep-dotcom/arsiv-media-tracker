import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/widgets/section_card.dart';

/// 04 · İstatistik: kullanıcının kütüphanesinden hesaplanır.
/// Firestore bağlanınca aynı hesaplar kalıcı kayıtlar üzerinden yapılacak.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const _monthNames = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  static const _genreColors = [
    AppColors.red,
    AppColors.book,
    AppColors.game,
    AppColors.orange,
    AppColors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final store = LibraryStore.instance;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final entries = store.entries;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'İstatistiklerim',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              Text(
                entries.isEmpty
                    ? 'Kütüphanen boş'
                    : '${DateTime.now().year} · kütüphanendeki ${entries.length} içerik',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final type in ContentType.values) ...[
                    if (type != ContentType.film) const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        value:
                            entries.where((e) => e.item.type == type).length,
                        done: entries
                            .where((e) =>
                                e.item.type == type &&
                                e.status == LibraryStatus.done)
                            .length,
                        label: type.label,
                        color: AppColors.forType(type),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const SectionCard(
                  title: 'Henüz veri yok',
                  child: Text(
                    'Keşfet ya da Ara ekranından bir içeriğin detayına gir ve '
                    '"Kütüphaneme Ekle" de. Durumunu "Bitti" yaptığında '
                    'aylık grafik ve favori türler burada oluşur.',
                    style:
                        TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                )
              else ...[
                SectionCard(
                  title: 'Aylık tamamlanan',
                  child: _monthlyChart(entries),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Favori türler',
                  child: _genreChart(entries),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Son 6 ayda tamamlanan içerik sayısı.
  Widget _monthlyChart(List<LibraryEntry> entries) {
    final now = DateTime.now();
    final months = List.generate(
        6, (i) => DateTime(now.year, now.month - 5 + i));
    final values = [
      for (final m in months)
        entries
            .where((e) =>
                e.completedAt != null &&
                e.completedAt!.year == m.year &&
                e.completedAt!.month == m.month)
            .length,
    ];
    if (values.every((v) => v == 0)) {
      return const Text(
        'Henüz tamamlanan içerik yok. Detay ekranında durumu "Bitti" yap.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      );
    }
    return SizedBox(
      height: 170,
      child: _BarChart(
        labels: [for (final m in months) _monthNames[m.month - 1]],
        values: values,
      ),
    );
  }

  /// Kütüphanedeki içeriklerin türlerine göre dağılımı (ilk 4 + Diğer).
  Widget _genreChart(List<LibraryEntry> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      for (final g in e.item.genres) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return const Text('Tür bilgisi yok.',
          style: TextStyle(color: AppColors.textSecondary));
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (s, e) => s + e.value);
    final top = sorted.take(4).toList();
    final rest = sorted.skip(4).fold<int>(0, (s, e) => s + e.value);

    final genres = <_Genre>[
      for (var i = 0; i < top.length; i++)
        _Genre(top[i].key, top[i].value, _genreColors[i]),
      if (rest > 0) _Genre('Diğer', rest, _genreColors[4]),
    ];

    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(painter: _DonutPainter(genres)),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (final g in genres)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: g.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(g.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                        '%${(g.count * 100 / total).round()}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Genre {
  const _Genre(this.name, this.count, this.color);
  final String name;
  final int count;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.done,
    required this.label,
    required this.color,
  });

  final int value;
  final int done;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w900, color: color),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            '$done bitti',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.labels, required this.values});

  final List<String> labels;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, values.reduce(math.max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${values[i]}',
                    style: TextStyle(
                      fontSize: 10,
                      color: i == values.length - 1
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: math.max(0.02, values[i] / maxValue),
                      child: Container(
                        decoration: BoxDecoration(
                          color: i == values.length - 1
                              ? AppColors.red
                              : AppColors.redDark,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.genres);

  final List<_Genre> genres;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.18;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    final total = genres.fold<int>(0, (sum, g) => sum + g.count);
    if (total == 0) return;
    final gap = genres.length > 1 ? 0.03 : 0.0;
    var start = -math.pi / 2;
    for (final g in genres) {
      final sweep = 2 * math.pi * g.count / total;
      canvas.drawArc(
        rect,
        start + gap,
        sweep - 2 * gap,
        false,
        Paint()
          ..color = g.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
