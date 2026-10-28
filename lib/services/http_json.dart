import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:arsiv_app/services/content_service.dart';

/// Üç servisin ortak HTTP yardımcısı: zaman aşımı, hata mesajları ve
/// kısa süreli önbellek. Aynı istek 5 dakika içinde tekrar gönderilmez;
/// bu, API kotalarını korur.
class JsonFetcher {
  JsonFetcher({
    required this.source,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.cacheFor = const Duration(minutes: 5),
    this.retries = 2,
    this.retryDelay = const Duration(milliseconds: 600),
  }) : _client = client ?? http.Client();

  /// Hata mesajlarında görünen kaynak adı (ör. "TMDB").
  final String source;
  final Duration timeout;
  final Duration cacheFor;
  final int retries;
  final Duration retryDelay;
  final http.Client _client;

  static bool _isTemporary(int code) =>
      code == 500 || code == 502 || code == 503 || code == 504;

  final Map<String, _CacheEntry> _cache = {};

  Future<dynamic> get(Uri uri, {Map<String, String>? headers}) async {
    final key = uri.toString();
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.expires)) {
      return cached.body;
    }

    // Sunucu geçici hata verirse (500, 502, 503, 504) kısa aralıklarla
    // 2 kez daha dener. Google Books zaman zaman 503 döndürüyor.
    late http.Response response;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } on TimeoutException {
        throw ContentServiceException('$source yanıt vermedi.');
      } catch (e) {
        debugPrint('[$source] bağlantı hatası · ${uri.path} · $e');
        throw const ContentServiceException('İnternet bağlantısı yok.');
      }
      if (!_isTemporary(response.statusCode) || attempt == retries) break;
      debugPrint('[$source] HTTP ${response.statusCode}, tekrar deneniyor '
          '(${attempt + 1}/$retries)');
      await Future<void>.delayed(retryDelay * (attempt + 1));
    }

    if (response.statusCode != 200) {
      final snippet = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      debugPrint('[$source] HTTP ${response.statusCode} · ${uri.path} · $snippet');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 401:
      case 403:
        throw ContentServiceException(
            '$source anahtarı geçersiz ya da eksik (env.json).');
      case 429:
        throw ContentServiceException('$source istek sınırı aşıldı.');
      case 500:
      case 502:
      case 503:
      case 504:
        throw ContentServiceException(
            '$source geçici olarak yanıt vermiyor (${response.statusCode}).');
      default:
        throw ContentServiceException(
            '$source hatası (${response.statusCode}).');
    }

    final dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ContentServiceException('$source beklenmeyen yanıt verdi.');
    }
    _cache[key] = _CacheEntry(body, DateTime.now().add(cacheFor));
    return body;
  }
}

class _CacheEntry {
  _CacheEntry(this.body, this.expires);
  final dynamic body;
  final DateTime expires;
}

/// "2024-05-17" gibi bir tarihten yılı alır; yoksa 0.
int parseYear(String? date) {
  if (date == null || date.length < 4) return 0;
  return int.tryParse(date.substring(0, 4)) ?? 0;
}
