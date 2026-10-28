import 'package:flutter/material.dart';

import 'package:arsiv_app/models/content_item.dart';

/// Afiş/kapak görseli. API'den gerçek görsel ([ContentItem.imageUrl]) gelene
/// kadar tasarımdaki gibi gradyan + güneş + dağ silüeti çizer.
class PosterArt extends StatelessWidget {
  const PosterArt({
    super.key,
    required this.item,
    this.borderRadius = 10,
    this.showSun = true,
    this.preferBackdrop = false,
  });

  final ContentItem item;
  final double borderRadius;
  final bool showSun;

  /// Geniş alanlarda (öne çıkan kart, Detay üstü) yatay görseli tercih et.
  final bool preferBackdrop;

  @override
  Widget build(BuildContext context) {
    final url = preferBackdrop
        ? (item.backdropUrl ?? item.imageUrl)
        : item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _painted(),
              errorBuilder: (_, _, _) => _painted(),
            )
          : _painted(),
    );
  }

  Widget _painted() => CustomPaint(
        painter: _PosterPainter(item.artColors, showSun),
        child: const SizedBox.expand(),
      );
}

class _PosterPainter extends CustomPainter {
  _PosterPainter(this.colors, this.showSun);

  final List<Color> colors;
  final bool showSun;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    if (showSun) {
      canvas.drawCircle(
        Offset(size.width * 0.68, size.height * 0.32),
        size.shortestSide * 0.32,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
    }

    final far = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.3, size.height * 0.55)
      ..lineTo(size.width * 0.55, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.64)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(far, Paint()..color = Colors.black.withValues(alpha: 0.22));

    final near = Path()
      ..moveTo(0, size.height * 0.84)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.82)
      ..lineTo(size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(near, Paint()..color = Colors.black.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant _PosterPainter old) =>
      old.colors != colors || old.showSun != showSun;
}
