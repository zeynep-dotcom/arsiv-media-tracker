import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/widgets/content_card.dart';
import 'package:arsiv_app/widgets/poster_art.dart';

/// 03 · Kütüphanem: İzlenecek, Okunan, Oynanan, Favoriler sekmeleri.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LibraryStore.instance;
    return DefaultTabController(
      length: 4,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Kütüphanem',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.red,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'İzlenecek'),
                Tab(text: 'Okunan'),
                Tab(text: 'Oynanan'),
                Tab(text: 'Favoriler'),
              ],
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) => TabBarView(
                  children: [
                    _EntryList(entries: store.watchList()),
                    _EntryList(entries: store.readList()),
                    _EntryList(entries: store.playList()),
                    _EntryList(entries: store.favorites()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries});

  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Bu liste boş.\nKeşfet ekranından içerik ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _EntryTile(entry: entries[i]),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final LibraryEntry entry;

  String get _subtitle {
    final item = entry.item;
    final pct = (entry.progress * 100).round();
    final verb = switch (item.type) {
      ContentType.film => 'izlendi',
      ContentType.book => 'okundu',
      ContentType.game => 'oynandı',
    };
    final detail = switch (entry.status) {
      LibraryStatus.planned => switch (item.type) {
          ContentType.film => 'İzlenecek',
          ContentType.book => 'Okunacak',
          ContentType.game => 'İstek listesi',
        },
      LibraryStatus.inProgress => '%$pct $verb',
      LibraryStatus.done => 'Tamamlandı',
      LibraryStatus.dropped => 'Yarım kaldı',
    };
    return '${item.type.label} · $detail';
  }

  @override
  Widget build(BuildContext context) {
    final done = entry.status == LibraryStatus.done;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openDetail(context, entry.item),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 70,
                child: PosterArt(item: entry.item, borderRadius: 8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.item.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (entry.favorite)
                          const Icon(Icons.favorite,
                              size: 16, color: AppColors.red),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.progress,
                        minHeight: 4,
                        backgroundColor: AppColors.divider,
                        color: done ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
