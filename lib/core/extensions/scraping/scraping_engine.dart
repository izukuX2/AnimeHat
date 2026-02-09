import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:anime_hat/core/services/webview_scraper.dart';
import 'transformers.dart';
import 'package:anime_hat/core/extensions/base_provider.dart'
    show ServerQuality;

/// Unified scraping engine with multiple strategies
class ScrapingEngine {
  final Dio _dio;
  final Map<String, String> _defaultHeaders;

  ScrapingEngine({
    Dio? dio,
    Map<String, String>? defaultHeaders,
  })  : _dio = dio ?? Dio(),
        _defaultHeaders = defaultHeaders ??
            {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
            };

  /// Fetch and parse HTML page
  Future<Document> fetchPage(
    String url, {
    bool useWebView = false,
    Map<String, String>? headers,
    String? waitForSelector,
  }) async {
    String html;

    if (useWebView) {
      debugPrint('ScrapingEngine: Using WebView for $url');
      html = await WebViewScraper.instance.fetchWithJavaScript(
        url: url,
        waitForSelector: waitForSelector,
        waitDuration: const Duration(seconds: 4),
      );
    } else {
      debugPrint('ScrapingEngine: Using HTTP for $url');
      final response = await _dio.get(
        url,
        options: Options(headers: {..._defaultHeaders, ...?headers}),
      );
      html = response.data.toString();
    }

    return parser.parse(html);
  }

  /// Post request and parse HTML response
  Future<Document> postPage(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final response = await _dio.post(
      url,
      data: data != null ? FormData.fromMap(data) : null,
      options: Options(headers: {..._defaultHeaders, ...?headers}),
    );
    return parser.parse(response.data.toString());
  }

  /// Select all matching elements
  List<Element> selectAll(Document doc, String selector) {
    try {
      return doc.querySelectorAll(selector);
    } catch (e) {
      debugPrint('ScrapingEngine: Invalid selector "$selector": $e');
      return [];
    }
  }

  /// Select first matching element
  Element? selectOne(Document doc, String selector) {
    try {
      return doc.querySelector(selector);
    } catch (e) {
      debugPrint('ScrapingEngine: Invalid selector "$selector": $e');
      return null;
    }
  }

  /// Extract text from element
  String getText(Element el) => el.text.trim();

  /// Extract attribute from element
  String? getAttr(Element el, String attr) => el.attributes[attr];

  /// Extract value with optional transformer
  String? extractValue(
    Element el, {
    String? attr,
    ValueTransformer? transformer,
  }) {
    String? value;

    if (attr != null) {
      value = el.attributes[attr];
    } else {
      value = el.text.trim();
    }

    if (value != null && transformer != null) {
      value = transformer.transform(value);
    }

    return value;
  }

  /// Extract all text values from matching elements
  List<String> extractAllText(Document doc, String selector) {
    return selectAll(doc, selector)
        .map((el) => el.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Detect server quality from text
  ServerQuality detectQuality(String text) => ServerQuality.fromText(text);

  /// Parse episode number from text
  int? parseEpisodeNumber(String text) {
    // Try Arabic pattern first
    final arabicMatch = RegExp(r'الحلقة\s*(\d+)').firstMatch(text);
    if (arabicMatch != null) {
      return int.tryParse(arabicMatch.group(1)!);
    }

    // Try English patterns
    final englishMatch =
        RegExp(r'(?:ep(?:isode)?|الحلقة)\s*(\d+)', caseSensitive: false)
            .firstMatch(text);
    if (englishMatch != null) {
      return int.tryParse(englishMatch.group(1)!);
    }

    // Try just number
    final numberMatch = RegExp(r'(\d+)').firstMatch(text);
    if (numberMatch != null) {
      return int.tryParse(numberMatch.group(1)!);
    }

    return null;
  }

  /// Build full URL from relative path
  String buildUrl(String baseUrl, String path) {
    if (path.startsWith('http')) return path;

    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }
}
