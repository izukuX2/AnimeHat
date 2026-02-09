import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dio/dio.dart';

/// A scraper for pages that require JavaScript rendering.
/// Uses headless WebView with proper fallback to regular HTTP.
class WebViewScraper {
  static WebViewScraper? _instance;
  HeadlessInAppWebView? _headlessWebView;
  Completer<String>? _pageContentCompleter;
  final Dio _dio = Dio();

  WebViewScraper._();

  static WebViewScraper get instance {
    _instance ??= WebViewScraper._();
    return _instance!;
  }

  /// Fetch a page with JavaScript rendering.
  /// Falls back to regular HTTP if WebView fails.
  Future<String> fetchWithJavaScript({
    required String url,
    String? waitForSelector,
    Duration waitDuration = const Duration(seconds: 3),
  }) async {
    // Try headless WebView first
    try {
      final result = await _fetchWithHeadlessWebView(
        url: url,
        waitForSelector: waitForSelector,
        waitDuration: waitDuration,
      );
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('WebViewScraper: Headless WebView failed: $e');
    }

    // Fallback to regular HTTP (won't have JS-rendered content)
    debugPrint('WebViewScraper: Falling back to regular HTTP request');
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
            'Referer': 'https://witanime.you/',
          },
        ),
      );
      return response.data.toString();
    } catch (e) {
      debugPrint('WebViewScraper: HTTP fallback also failed: $e');
      return '';
    }
  }

  Future<String> _fetchWithHeadlessWebView({
    required String url,
    String? waitForSelector,
    Duration waitDuration = const Duration(seconds: 3),
  }) async {
    _pageContentCompleter = Completer<String>();

    debugPrint('WebViewScraper: Loading $url...');

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
        },
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        domStorageEnabled: true,
        useOnLoadResource: false,
        cacheEnabled: true,
        clearCache: false,
        allowContentAccess: true,
        allowFileAccess: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useShouldOverrideUrlLoading: false,
        mediaPlaybackRequiresUserGesture: true,
        transparentBackground: true,
        disableDefaultErrorPage: true,
        supportMultipleWindows: false,
        useWideViewPort: false,
        loadWithOverviewMode: false,
        javaScriptCanOpenWindowsAutomatically: false,
      ),
      onWebViewCreated: (controller) {
        debugPrint('WebViewScraper: WebView created');
      },
      onLoadStart: (controller, url) {
        debugPrint('WebViewScraper: Load started: $url');
      },
      onLoadStop: (controller, url) async {
        debugPrint(
            'WebViewScraper: Load stopped, waiting for dynamic content...');

        // Wait for dynamic content to load
        if (waitForSelector != null) {
          // Wait for specific element with retries
          for (int i = 0; i < 10; i++) {
            try {
              final result = await controller.evaluateJavascript(
                source: 'document.querySelector("$waitForSelector") !== null',
              );
              if (result == true) {
                debugPrint('WebViewScraper: Selector found: $waitForSelector');
                break;
              }
            } catch (e) {
              debugPrint('WebViewScraper: JS evaluation error: $e');
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          // Just wait for a fixed duration
          await Future.delayed(waitDuration);
        }

        // Extract the page content
        try {
          final html = await controller.evaluateJavascript(
            source: 'document.documentElement.outerHTML',
          );

          debugPrint(
              'WebViewScraper: Content extracted, length: ${html?.toString().length ?? 0}');

          if (!_pageContentCompleter!.isCompleted) {
            _pageContentCompleter!.complete(html as String? ?? '');
          }
        } catch (e) {
          debugPrint('WebViewScraper: Failed to extract content: $e');
          if (!_pageContentCompleter!.isCompleted) {
            _pageContentCompleter!.complete('');
          }
        }
      },
      onReceivedError: (controller, request, error) {
        debugPrint('WebViewScraper: Error: ${error.description}');
        if (!_pageContentCompleter!.isCompleted) {
          _pageContentCompleter!.completeError(Exception(error.description));
        }
      },
      onReceivedHttpError: (controller, request, response) {
        debugPrint('WebViewScraper: HTTP Error: ${response.statusCode}');
      },
    );

    await _headlessWebView!.run();

    try {
      final content = await _pageContentCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('WebViewScraper: Timeout waiting for page');
          return '';
        },
      );
      return content;
    } finally {
      await _headlessWebView?.dispose();
      _headlessWebView = null;
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _headlessWebView?.dispose();
    _headlessWebView = null;
  }
}
