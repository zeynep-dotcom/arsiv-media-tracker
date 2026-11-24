import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/screens/detail/detail_screen.dart';
import 'package:arsiv_app/services/app_services.dart';
import 'package:arsiv_app/services/google_books_service.dart';

/// Barkoddan kitap bulan fonksiyon. Testlerde sahtesi verilebilir.
typedef IsbnLookup = Future<ContentItem?> Function(String code);

Future<ContentItem?> _defaultLookup(String code) {
  final books = AppServices.books;
  final service = books is GoogleBooksService ? books : GoogleBooksService();
  return service.findByIsbn(code);
}

/// Barkodla kitap (Abdulkadir): kitabın arkasındaki ISBN barkodu
/// okutulur, Google Books'ta bulunan kitabın Detay ekranı açılır.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, this.lookup = _defaultLookup});

  final IsbnLookup lookup;

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  // Kitap barkodları EAN-13'tür; diğer biçimleri okumaya gerek yok.
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13],
  );

  bool _busy = false;
  String? _message;
  String? _notFoundCode; // aynı bulunamayan barkodu tekrar tekrar sorma

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null || code == _notFoundCode) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    String message;
    try {
      final item = await widget.lookup(code);
      if (!mounted) return;
      if (item != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
        );
        return;
      }
      _notFoundCode = code;
      message = 'Bu barkodla kitap bulunamadı';
    } catch (e) {
      message = '$e Tekrar okut.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Barkodla kitap bul'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScanError(error: error),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (_busy) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      _busy
                          ? 'Kitap aranıyor…'
                          : _message ??
                                'Kitabın arkasındaki ISBN barkodunu '
                                    'çerçeveye getir.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kamera açılamazsa (ör. izin reddedildi) çökmek yerine ne yapılacağını
/// anlatır.
class _ScanError extends StatelessWidget {
  const _ScanError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            denied ? Icons.no_photography : Icons.error_outline,
            size: 48,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          Text(
            denied
                ? 'Barkod okutmak için kamera izni gerekiyor.\n'
                      'Telefonda Ayarlar › Uygulamalar › ARŞİV › İzinler '
                      'bölümünden kamera iznini açıp tekrar dene.'
                : 'Kamera açılamadı. Ekranı kapatıp tekrar dene.',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Geri dön'),
          ),
        ],
      ),
    );
  }
}
