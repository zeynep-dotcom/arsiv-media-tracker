import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/widgets/content_card.dart';

/// Başlık + yatay kaydırmalı kart satırı.
class ContentRow extends StatelessWidget {
  const ContentRow({super.key, required this.title, required this.items});

  final String title;
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ContentCard(item: items[i]),
          ),
        ),
      ],
    );
  }
}

/// API'den yüklenen satır. Yüklenirken iskelet kartlar, hata olursa
/// örnek veri ve kısa bir uyarı gösterir. [loadPage] verilirse satır sonuna
/// kaydırıldığında sıradaki sayfa (2, 3, ...) çekilip listeye eklenir.
class AsyncContentRow extends StatelessWidget {
  const AsyncContentRow({
    super.key,
    required this.title,
    required this.future,
    required this.fallback,
    this.loadPage,
  });

  final String title;
  final Future<List<ContentItem>> future;
  final List<ContentItem> fallback;

  /// Örn. `(page) => AppServices.films.getPopular(page: page)`.
  final Future<List<ContentItem>> Function(int page)? loadPage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContentItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _SkeletonRow(title: title);
        }
        final data = snapshot.data;
        if (snapshot.hasError) {
          debugPrint('[$title] hata: ${snapshot.error}');
        }
        if (snapshot.hasError || data == null || data.isEmpty) {
          final reason = snapshot.hasError
              ? '${snapshot.error}'
              : 'Sonuç gelmedi.';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContentRow(title: title, items: fallback),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  '$reason Örnek veri gösteriliyor.',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        }
        final loadPage = this.loadPage;
        if (loadPage == null) return ContentRow(title: title, items: data);
        return PagedContentRow(
          // Yenilemede yeni liste gelince satır baştan kurulsun.
          key: ObjectKey(data),
          title: title,
          firstPage: data,
          loadPage: loadPage,
        );
      },
    );
  }
}

/// Sonsuz kaydırmalı satır: 1. sayfa hazır gelir; kullanıcı satırın
/// sonuna yaklaşınca [loadPage] ile sıradaki sayfa çekilip eklenir.
/// Boş sayfa gelince ya da hata olunca daha fazla istemez.
class PagedContentRow extends StatefulWidget {
  const PagedContentRow({
    super.key,
    required this.title,
    required this.firstPage,
    required this.loadPage,
  });

  final String title;
  final List<ContentItem> firstPage;
  final Future<List<ContentItem>> Function(int page) loadPage;

  @override
  State<PagedContentRow> createState() => _PagedContentRowState();
}

class _PagedContentRowState extends State<PagedContentRow> {
  late final List<ContentItem> _items = [...widget.firstPage];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  /// Satır sonuna bu kadar piksel kala sıradaki sayfa istenir.
  static const _threshold = 300.0;

  bool _onScroll(ScrollNotification n) {
    // Bildirim yerleşim sırasında gelebilir; setState'i ondan sonraya bırak.
    if (n is ScrollUpdateNotification && n.metrics.extentAfter < _threshold) {
      Future.microtask(_loadMore);
    }
    return false;
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final next = await widget.loadPage(_page + 1);
      // Aynı içerik iki sayfada gelirse tekrar eklenmesin.
      final known = {for (final item in _items) item.id};
      final fresh = next.where((item) => !known.contains(item.id)).toList();
      if (!mounted) return;
      setState(() {
        _page++;
        _items.addAll(fresh);
        _hasMore = fresh.isNotEmpty;
      });
    } catch (e) {
      debugPrint('[${widget.title}] ${_page + 1}. sayfa alınamadı · $e');
      if (mounted) setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 200,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _items.length + (_loading ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => i < _items.length
                  ? ContentCard(item: _items[i])
                  : const SizedBox(
                      width: 60,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => Container(
              width: 104,
              margin: const EdgeInsets.only(bottom: 44),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
