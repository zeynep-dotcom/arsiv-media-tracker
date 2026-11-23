import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_type.dart';
import 'package:arsiv_app/models/library_entry.dart';
import 'package:arsiv_app/models/progress_format.dart';
import 'package:arsiv_app/services/library_store.dart';
import 'package:arsiv_app/widgets/content_card.dart';
import 'package:arsiv_app/widgets/poster_art.dart';

/// Duruma türe uygun ad verir: filmde "İzleniyor", kitapta "Okunuyor"...
String statusLabelFor(LibraryStatus status, ContentType type) =>
    switch (status) {
      LibraryStatus.planned => switch (type) {
          ContentType.film => 'İzlenecek',
          ContentType.book => 'Okunacak',
          ContentType.game => 'İstek listesi',
        },
      LibraryStatus.inProgress => switch (type) {
          ContentType.film => 'İzleniyor',
          ContentType.book => 'Okunuyor',
          ContentType.game => 'Oynanıyor',
        },
      LibraryStatus.done => 'Tamamlandı',
      LibraryStatus.dropped => 'Yarım kaldı',
    };

/// Kütüphanem'deki bir satır (Ece · Hafta 4).
/// - Dokununca Detay açılır.
/// - Sola kaydırınca içerik silinir; "Geri al" durumu, puanı ve ilerlemeyi
///   geri getirir.
/// - Uzun basınca durum menüsü açılır.
class LibraryEntryTile extends StatelessWidget {
  const LibraryEntryTile({super.key, required this.entry});

  final LibraryEntry entry;

  String get _subtitle {
    final item = entry.item;
    final status = statusLabelFor(entry.status, item.type);
    final progress = ProgressFormat.label(item, entry.progress);
    final detail = switch (entry.status) {
      LibraryStatus.inProgress => progress,
      LibraryStatus.dropped when entry.progress > 0 => '$status · $progress',
      _ => status,
    };
    return '${item.type.label} · $detail';
  }

  void _remove(BuildContext context) {
    final store = LibraryStore.instance;
    // Satır ağaçtan çıkmadan önce kopyayı ve messenger'ı al.
    final snapshot = entry.copy();
    final messenger = ScaffoldMessenger.of(context);
    store.remove(entry.item);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${snapshot.item.title} kütüphaneden çıkarıldı'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Geri al',
          textColor: AppColors.gold,
          onPressed: () => store.restore(snapshot),
        ),
      ));
  }

  Future<void> _showStatusMenu(BuildContext context) async {
    final type = entry.item.type;
    final chosen = await showModalBottomSheet<LibraryStatus>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                entry.item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final status in LibraryStatus.values)
              ListTile(
                title: Text(statusLabelFor(status, type)),
                trailing: status == entry.status
                    ? const Icon(Icons.check, color: AppColors.red)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(status),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != entry.status) {
      LibraryStore.instance.setStatus(entry.item, chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = entry.status == LibraryStatus.done;
    return Dismissible(
      key: ValueKey('library-${entry.item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.redDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sil', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline),
          ],
        ),
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => openDetail(context, entry.item),
          onLongPress: () => _showStatusMenu(context),
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
      ),
    );
  }
}
