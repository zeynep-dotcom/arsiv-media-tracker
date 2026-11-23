import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/services/app_services.dart';
import 'package:arsiv_app/services/tmdb_service.dart';

/// Film detay ekranındaki "Fragmanı izle" butonu ve "Türkiye'de nerede izlenir"
/// platform logoları bölümü (Ali Kağan).
///
/// Yalnızca [ContentType.film] için çalışır; fragman yoksa buton, Türkiye'de
/// izleme platformu yoksa platform bölümü hiç görünmez.
class FilmExtrasSection extends StatefulWidget {
  const FilmExtrasSection({
    super.key,
    required this.item,
    this.service,
    this.onLaunchUrl,
  });

  final ContentItem item;

  /// Testlerde özel [TmdbService] verilebilir; yoksa [AppServices.films]
  /// bir [TmdbService] ise o kullanılır.
  final TmdbService? service;

  /// Testlerde URL açma davranışını yakalamak için; yoksa [launchUrl].
  final Future<bool> Function(Uri url)? onLaunchUrl;

  @override
  State<FilmExtrasSection> createState() => _FilmExtrasSectionState();
}

class _FilmExtrasSectionState extends State<FilmExtrasSection> {
  List<WatchProvider> _providers = const [];
  Uri? _trailerUrl;

  TmdbService? get _tmdb {
    if (widget.service != null) return widget.service;
    final current = AppServices.films;
    return current is TmdbService ? current : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FilmExtrasSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.item.type != ContentType.film) return;
    final tmdb = _tmdb;
    if (tmdb == null) return;

    final results = await Future.wait<Object?>([
      tmdb
          .getWatchProviders(widget.item)
          .catchError((Object e) {
            debugPrint('[TMDB] platformlar alınamadı · $e');
            return const <WatchProvider>[];
          }),
      tmdb
          .getTrailerUrl(widget.item)
          .catchError((Object e) {
            debugPrint('[TMDB] fragman alınamadı · $e');
            return null;
          }),
    ]);

    if (!mounted) return;
    setState(() {
      _providers = results[0] as List<WatchProvider>;
      _trailerUrl = results[1] as Uri?;
    });
  }

  Future<void> _openTrailer(Uri url) async {
    try {
      final launcher = widget.onLaunchUrl;
      final ok = launcher != null
          ? await launcher(url)
          : await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fragman açılamadı.')),
        );
      }
    } catch (e) {
      debugPrint('[TMDB] fragman açılamadı · $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fragman açılamadı.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type != ContentType.film) {
      return const SizedBox.shrink();
    }
    if (_trailerUrl == null && _providers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_trailerUrl != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _openTrailer(_trailerUrl!),
                icon: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.red,
                ),
                label: const Text('Fragmanı izle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.card,
                  side: const BorderSide(color: AppColors.divider),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (_trailerUrl != null && _providers.isNotEmpty)
            const SizedBox(height: 16),
          if (_providers.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'Nerede izlenir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Kaynak: JustWatch',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final provider in _providers)
                  _ProviderTile(provider: provider),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider});

  final WatchProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.logoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                provider.logoUrl!,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.tv,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            const Icon(
              Icons.tv,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            provider.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
