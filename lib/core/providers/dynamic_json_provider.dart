import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as hp;
import 'package:html/dom.dart' as dom;
import '../models/anime_model.dart';
import '../models/character_model.dart';
import '../models/extension_model.dart';
import '../services/webview_scraper.dart';
import 'anime_provider.dart';

class DynamicJsonProvider implements BaseAnimeProvider {
  final Extension extension;
  final Dio _dio = Dio();

  DynamicJsonProvider(this.extension);

  @override
  String get id => extension.id;

  @override
  String get name => extension.name;

  @override
  String get baseUrl => extension.source.baseUrl;

  @override
  Future<HomeData> loadHome() async {
    final homeConfig = extension.source.endpoints['home'] ??
        extension.source.endpoints['latest'];
    if (homeConfig == null) {
      return HomeData(
          latestEpisodes: [], broadcast: [], premiere: [], latestNews: []);
    }

    final url = _buildUrl(homeConfig['path'], {});
    debugPrint('DynamicJsonProvider: Loading home from $url');
    final response = await _dio.get(url,
        options: Options(headers: extension.source.headers));

    final List<Anime> animes;
    if (homeConfig['type'] == 'json') {
      animes = _parseJsonList(response.data, homeConfig['selectors']);
    } else {
      animes =
          _parseHtmlList(response.data.toString(), homeConfig['selectors']);
    }
    debugPrint('DynamicJsonProvider: Loaded ${animes.length} animes for home');

    return HomeData(
      latestEpisodes: animes
          .map((a) => AnimeWithEpisode(
                anime: a,
                episode: Episode(
                  eId: '',
                  animeId: a.animeId,
                  episodeNumber: '?',
                  okLink: '',
                  maLink: '',
                  frLink: '',
                  gdLink: '',
                  svLink: '',
                  released: '',
                ),
              ))
          .toList(),
      broadcast: animes,
      premiere: [],
      latestNews: [],
    );
  }

  @override
  Future<List<Anime>> searchAnime(String query, {int page = 0}) async {
    final searchConfig = extension.source.endpoints['search'];
    if (searchConfig == null) return [];

    final url = _buildUrl(
        searchConfig['path'], {'query': query, 'page': page.toString()});
    debugPrint('DynamicJsonProvider: Searching anime at $url');
    final response = await _dio.get(url,
        options: Options(headers: extension.source.headers));

    if (searchConfig['type'] == 'json') {
      return _parseJsonList(response.data, searchConfig['selectors']);
    } else {
      return _parseHtmlList(
          response.data.toString(), searchConfig['selectors']);
    }
  }

  @override
  Future<AnimeDetails> getAnimeDetails(String animeId) async {
    final config = extension.source.endpoints['details'];
    if (config == null) {
      throw Exception('Detailed info not supported by this extension');
    }

    final url = _buildUrl(config['path'], {'id': animeId});
    debugPrint('DynamicJsonProvider: Getting details from $url');
    final response = await _dio.get(url,
        options: Options(headers: extension.source.headers));

    if (config['type'] == 'json') {
      return _parseJsonDetails(response.data, config['selectors']);
    } else {
      final details =
          _parseHtmlDetails(response.data.toString(), config['selectors']);
      debugPrint(
          'DynamicJsonProvider: Extracted synopsis: ${details.synopsis.substring(0, details.synopsis.length > 50 ? 50 : details.synopsis.length)}...');
      return details;
    }
  }

  @override
  Future<List<Episode>> getEpisodes(String animeId) async {
    final config = extension.source.endpoints['episodes'];
    if (config == null) return [];

    final url = _buildUrl(config['path'], {'id': animeId});
    final waitForJs = config['wait_for_js'] == true;

    // If page requires JavaScript rendering, use WebViewScraper
    if (waitForJs) {
      try {
        debugPrint('DynamicJsonProvider: Using WebViewScraper for $url');
        final waitSelector = config['selectors']['root'] as String?;
        final html = await WebViewScraper.instance.fetchWithJavaScript(
          url: url,
          waitForSelector: waitSelector,
          waitDuration: const Duration(seconds: 4),
        );

        if (html.isEmpty) {
          debugPrint(
              'DynamicJsonProvider: WebViewScraper returned empty content');
          return [];
        }

        final eps = _parseHtmlEpisodes(html, config['selectors']);
        debugPrint(
            'DynamicJsonProvider: WebViewScraper parsed ${eps.length} episodes');
        return eps;
      } catch (e) {
        debugPrint('DynamicJsonProvider: WebViewScraper failed: $e');
        // Fall back to regular scraping
      }
    }

    // Check if we need to handle AJAX
    if (config['ajax'] != null) {
      final ajaxConfig = config['ajax'] as Map<String, dynamic>;

      // Step 1: Fetch the main page to get the internal ID
      final pageResponse = await _dio.get(url,
          options: Options(headers: extension.source.headers));
      final doc = hp.parse(pageResponse.data.toString());

      final internalIdSelectors = [
        ajaxConfig['internalIdSelector'] ?? 'input#anime_id',
        'input#anime_id',
        'input[name="anime_id"]',
        'input#post_id',
        'input[name="post_id"]',
        '#post_id',
      ];
      final internalIdAttr = ajaxConfig['internalIdAttr'] ?? 'value';
      String? internalId;

      for (final selector in internalIdSelectors) {
        internalId = doc.querySelector(selector)?.attributes[internalIdAttr];
        if (internalId != null && internalId.isNotEmpty) {
          debugPrint(
              'DynamicJsonProvider: Found internal ID $internalId using $selector');
          break;
        }
      }

      // Regex fallback if selectors fail
      if (internalId == null) {
        final html = pageResponse.data.toString();
        final match =
            RegExp(r'["' ']?anime_id["' ']?\s*[:=]\s*["' ']?(\d+)["' ']?')
                    .firstMatch(html) ??
                RegExp(r'["' ']?post_id["' ']?\s*[:=]\s*["' ']?(\d+)["' ']?')
                    .firstMatch(html);
        if (match != null) {
          internalId = match.group(1);
          debugPrint(
              'DynamicJsonProvider: Found internal ID $internalId using regex');
        }
      }

      if (internalId == null) {
        debugPrint(
            'DynamicJsonProvider: AJAX ID not found, falling back to direct HTML parsing');
        // Fallback: Try direct HTML parsing from the already fetched page
        return _parseHtmlEpisodes(
            pageResponse.data.toString(), config['selectors']);
      }

      // Step 2: Perform the AJAX request
      final ajaxUrl = _buildUrl(ajaxConfig['path'], {});
      final body = <String, dynamic>{};
      if (ajaxConfig['body'] != null) {
        (ajaxConfig['body'] as Map<String, dynamic>).forEach((key, value) {
          body[key] = value.toString().replaceAll('{internal_id}', internalId!);
        });
      }

      final response = await _dio.post(
        ajaxUrl,
        data: FormData.fromMap(body),
        options: Options(
          headers: {
            ...extension.source.headers,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return _parseHtmlEpisodes(response.data.toString(), config['selectors']);
    }

    debugPrint('DynamicJsonProvider: Getting episodes from $url');
    final response = await _dio.get(url,
        options: Options(headers: extension.source.headers));

    if (config['type'] == 'json') {
      final eps = _parseJsonEpisodes(response.data, config['selectors']);
      debugPrint('DynamicJsonProvider: Parsed ${eps.length} JSON episodes');
      return eps;
    } else {
      final eps =
          _parseHtmlEpisodes(response.data.toString(), config['selectors']);
      final rootSelector = (config['selectors']['root'] ?? 'div.episode');
      debugPrint(
          'DynamicJsonProvider: Parsed ${eps.length} HTML episodes using selector: $rootSelector');
      return eps;
    }
  }

  @override
  Future<List<StreamingServer>> getServers(
      String animeId, String episodeNumber) async {
    final config = extension.source.endpoints['servers'];
    if (config == null) return [];

    final url = _buildUrl(config['path'], {'id': animeId, 'ep': episodeNumber});
    final response = await _dio.get(url,
        options: Options(headers: extension.source.headers));

    if (config['type'] == 'json') {
      return _parseJsonServers(response.data, config['selectors']);
    } else {
      return _parseHtmlServers(response.data.toString(), config['selectors']);
    }
  }

  @override
  Future<List<Anime>> getAnimeList({
    required String type,
    String filterType = '',
    String filterData = '',
    int from = 0,
  }) async {
    final config = extension.source.endpoints[type];
    if (config == null) return [];

    // Map 'type' to path parameters if needed, or just use as is
    final url = _buildUrl(config['path'], {'from': from.toString()});
    final response = await _dio.get(url,
        options: Options(headers: extension.source.headers));

    if (config['type'] == 'json') {
      return _parseJsonList(response.data, config['selectors']);
    } else {
      return _parseHtmlList(response.data.toString(), config['selectors']);
    }
  }

  String _buildUrl(String path, Map<String, String> params) {
    var finalPath = path;
    params.forEach((key, value) {
      finalPath = finalPath.replaceAll('{$key}', value);
    });
    // If path is already a full URL, return as-is
    if (finalPath.startsWith('http')) return finalPath;

    // Ensure proper path separator between baseUrl and path
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = finalPath.startsWith('/') ? finalPath : '/$finalPath';
    return '$cleanBaseUrl$cleanPath';
  }

  List<Anime> _parseHtmlList(String html, Map<String, dynamic> selectors) {
    final doc = hp.parse(html);
    final containerSelector =
        (selectors['root'] ?? selectors['container'] ?? 'div.item') as String;
    final List<dom.Element> items = doc.querySelectorAll(containerSelector);
    debugPrint(
        'DynamicJsonProvider: Found ${items.length} items with selector $containerSelector');

    return items
        .map((el) {
          final animeId = _getValue(el, selectors['id']) ?? '';
          if (animeId.isEmpty) {
            debugPrint(
                'DynamicJsonProvider: Failed to extract animeId for an item');
          }
          return Anime(
            id: '',
            animeId: animeId,
            enTitle: _getValue(el, selectors['title']) ?? '',
            jpTitle: '',
            arTitle: '',
            synonyms: '',
            genres: _getValue(el, selectors['genres']) ?? '',
            season: '',
            premiered: '',
            aired: '',
            broadcast: '',
            duration: '',
            thumbnail: _getValue(el, selectors['image']) ?? '',
            trailer: '',
            ytTrailer: '',
            creators: '',
            status: _getValue(el, selectors['status']) ?? '',
            episodes: '',
            score: '',
            rank: '',
            popularity: '',
            rating: '',
            type: '',
            views: '',
            malId: '',
          );
        })
        .where((a) => a.animeId.isNotEmpty)
        .toList();
  }

  String? _getValue(dynamic element, dynamic selectorSpec) {
    if (selectorSpec == null) return null;

    if (selectorSpec is String) {
      if (element is dom.Element) {
        if (selectorSpec.contains(':contains(')) {
          return _getTextByContains(element, selectorSpec);
        }
        return element.querySelector(selectorSpec)?.text.trim();
      } else if (element is Map) {
        return _getJsonPathValue(element, selectorSpec);
      }
      return null;
    }

    if (selectorSpec is Map) {
      final selector = selectorSpec['selector'] as String?;
      final attribute = selectorSpec['attr'] as String?;
      final fallbackAttr = selectorSpec['fallback_attr'] as String?;
      final regex = selectorSpec['regex'] as String?;
      final index = selectorSpec['index'] as int?;
      final isList = selectorSpec['type'] == 'list';

      if (isList && element is dom.Element && selector != null) {
        if (selector.contains(':contains(')) {
          return _getTextsByContains(element, selector)?.join(', ');
        }
        final elements = element.querySelectorAll(selector);
        return elements.map((e) => e.text.trim()).join(', ');
      }

      String? value;
      if (element is dom.Element) {
        if (selector != null && selector != 'self') {
          if (selector.contains(':contains(')) {
            value = _getTextByContains(element, selector);
          } else if (index != null) {
            final elements = element.querySelectorAll(selector);
            if (index < elements.length) {
              final target = elements[index];
              value = _getAttributeOrText(target, attribute, fallbackAttr);
            }
          } else {
            final target = element.querySelector(selector);
            if (target != null) {
              value = _getAttributeOrText(target, attribute, fallbackAttr);
              debugPrint('DynamicJsonProvider: _getValue($selector) -> $value');
            } else {
              debugPrint(
                  'DynamicJsonProvider: _getValue($selector) -> NOT FOUND');
            }
          }
        } else {
          value = _getAttributeOrText(element, attribute, fallbackAttr);
          debugPrint('DynamicJsonProvider: _getValue(self) -> $value');
        }
      } else if (element is Map) {
        value = _getJsonPathValue(element, selector ?? '');
      } else if (element is String) {
        value = element;
      }

      if (value == null) return null;

      // Transformations
      if (selectorSpec['transform'] == 'base64') {
        try {
          var cleanValue = value.trim();
          if (cleanValue.contains("'")) {
            final match = RegExp(r"'([^']*)'").firstMatch(cleanValue);
            if (match != null) cleanValue = match.group(1)!;
          } else if (cleanValue.contains('"')) {
            final match = RegExp(r'"([^"]*)"').firstMatch(cleanValue);
            if (match != null) cleanValue = match.group(1)!;
          }
          value = utf8.decode(base64.decode(cleanValue));
        } catch (e) {
          debugPrint('Base64 decode failed: $e');
        }
      }

      if (value == null) return null;

      if (selectorSpec['replace'] != null &&
          selectorSpec['replace_with'] != null) {
        value = value.replaceAll(
            selectorSpec['replace'], selectorSpec['replace_with']);
      }

      if (selectorSpec['regex_replace'] != null &&
          selectorSpec['replace_with'] != null) {
        value = value.replaceAll(RegExp(selectorSpec['regex_replace']),
            selectorSpec['replace_with']);
      }

      if (selectorSpec['substring'] != null) {
        final parts = (selectorSpec['substring'] as String).split(',');
        if (parts.length == 2) {
          final start = int.tryParse(parts[0]) ?? 0;
          final end = int.tryParse(parts[1]);
          if (end != null && end <= value.length) {
            value = value.substring(start, end);
          } else if (start <= value.length) {
            value = value.substring(start);
          }
        }
      }

      if (regex != null) {
        final reg = RegExp(regex);
        final match = reg.firstMatch(value);
        if (match != null) {
          value = match.group(1) ?? match.group(0);
        } else {
          debugPrint(
              'DynamicJsonProvider: Regex match failed for $value with $regex');
        }
      }
      return value;
    }

    return null;
  }

  /// Strips common Arabic labels from extracted metadata values
  String _stripLabel(String text) {
    final patterns = [
      RegExp(r'^[^:]+:\s*'), // "Label: Value" -> "Value"
      RegExp(
          r'^(النوع|الحالة|حالة الأنمي|التصنيف|بداية العرض|الموسم|المصدر|الاستوديو|المدة):\s*',
          unicode: true),
    ];
    String result = text.trim();
    for (final p in patterns) {
      result = result.replaceFirst(p, '');
    }
    return result.trim();
  }

  String? _getJsonPathValue(Map data, String path) {
    if (path.isEmpty || path == 'self') return data.toString();
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current?.toString();
  }

  String? _getAttributeOrText(dom.Element el, String? attr, String? fallback) {
    if (attr != null) {
      final val = el.attributes[attr];
      if (val != null && val.isNotEmpty) return val;
      if (fallback != null) return el.attributes[fallback];
    }
    return el.text.trim();
  }

  String? _getTextByContains(dom.Element root, String selector) {
    // Improved implementation of :contains selector for csslib/html
    // Selector format: ".parent:has(child:contains(\"Text\")) subchild"
    final match =
        RegExp(r"(.+):has\((.+):contains\((.+)\)\)(.*)").firstMatch(selector);
    if (match != null) {
      final parentSelector = match.group(1)!.trim();
      final childSearchSelector = match.group(2)!.trim();
      final searchText =
          match.group(3)!.replaceAll('"', '').replaceAll("'", '').trim();
      final subChildSelector = match.group(4)!.trim();

      final parents = root.querySelectorAll(parentSelector);
      for (final p in parents) {
        final children = p.querySelectorAll(childSearchSelector);
        for (final c in children) {
          if (c.text.contains(searchText)) {
            if (subChildSelector.isNotEmpty) {
              final sub = p.querySelector(subChildSelector);
              return sub?.text.trim();
            }
            return p.text.trim();
          }
        }
      }
    }
    return null;
  }

  List<String>? _getTextsByContains(dom.Element root, String selector) {
    // Improved implementation of :contains selector for lists
    final match =
        RegExp(r"(.+):has\((.+):contains\((.+)\)\)(.*)").firstMatch(selector);
    if (match != null) {
      final parentSelector = match.group(1)!.trim();
      final childSearchSelector = match.group(2)!.trim();
      final searchText =
          match.group(3)!.replaceAll('"', '').replaceAll("'", '').trim();
      final subChildSelector = match.group(4)!.trim();

      final parents = root.querySelectorAll(parentSelector);
      final List<String> results = [];
      for (final p in parents) {
        final children = p.querySelectorAll(childSearchSelector);
        for (final c in children) {
          if (c.text.contains(searchText)) {
            if (subChildSelector.isNotEmpty) {
              final subs = p.querySelectorAll(subChildSelector);
              results.addAll(subs.map((s) => s.text.trim()));
            } else {
              results.add(p.text.trim());
            }
            // Once we found the matching parent, we move to next parent
            break;
          }
        }
      }
      return results.isNotEmpty ? results : null;
    }
    return null;
  }

  AnimeDetails _parseHtmlDetails(String html, Map<String, dynamic> selectors) {
    final doc = hp.parse(html);
    final synopsis = _getValue(doc.body, selectors['synopsis']) ?? '';

    // Extract and strip labels from metadata
    final rawStatus = _getValue(doc.body, selectors['status']) ?? '';
    final rawType = _getValue(doc.body, selectors['type']) ?? '';
    final rawDate = _getValue(doc.body, selectors['release_date']) ?? '';
    final genres = _getValue(doc.body, selectors['genres']) ?? '';

    final status = _stripLabel(rawStatus);
    final type = _stripLabel(rawType);
    final releaseDate = _stripLabel(rawDate);

    debugPrint(
        'DynamicJsonProvider: Extracted Details - Status: $status, Type: $type, Date: $releaseDate, Genres: $genres');
    debugPrint(
        'DynamicJsonProvider: Extracted synopsis: ${synopsis.substring(0, synopsis.length > 50 ? 50 : synopsis.length)}...');

    return AnimeDetails(
      plot: synopsis,
      synopsis: synopsis,
      background: '',
      popularity: '',
      members: '',
      favorites: '',
      statistics: AnimeStatistics(userRate: '0', views: '0', rates: {}),
      relatedAnime: [],
    );
  }

  List<Episode> _parseHtmlEpisodes(
      String html, Map<String, dynamic> selectors) {
    final doc = hp.parse(html);
    final containerSelector = (selectors['root'] ??
        selectors['container'] ??
        'div.episode') as String;
    final List<dom.Element> items = doc.querySelectorAll(containerSelector);
    debugPrint(
        'DynamicJsonProvider: Found ${items.length} episodes with selector $containerSelector');

    return items
        .map((el) {
          final urlSelector =
              selectors['url'] ?? selectors['episode_url_base64'];
          final url = _getValue(el, urlSelector);
          final title = _getValue(el, selectors['title']) ?? '';
          final number = _getValue(el, selectors['number']) ?? title;

          return Episode(
            eId: url ?? '',
            animeId: '', // Usually filled by the caller or not needed here
            episodeNumber: number,
            okLink: '',
            maLink: '',
            frLink: '',
            gdLink: '',
            svLink: '',
            released: '',
          );
        })
        .where((e) => e.eId.isNotEmpty)
        .toList();
  }

  List<StreamingServer> _parseHtmlServers(
      String html, Map<String, dynamic> selectors) {
    final doc = hp.parse(html);
    final containerSelector = selectors['container'] ?? 'li';
    final List<dom.Element> items = doc.querySelectorAll(containerSelector);

    return items
        .map((el) {
          final name = _getValue(el, selectors['name']) ?? 'Server';
          final url = _getValue(el, selectors['url']);

          if (url == null) return null;

          return StreamingServer(
            name: name,
            url: url,
            quality: 'HD',
          );
        })
        .whereType<StreamingServer>()
        .toList();
  }

  List<Anime> _parseJsonList(dynamic data, Map<String, dynamic> selectors) {
    final root = selectors['root'] as String?;
    final itemsSource = root != null ? _getJsonRawValue(data, root) : data;

    if (itemsSource is! List) return [];

    return itemsSource
        .map((item) {
          if (item is! Map) return null;
          return Anime(
            id: '',
            animeId: _getValue(item, selectors['id']) ?? '',
            enTitle: _getValue(item, selectors['title']) ?? '',
            jpTitle: '',
            arTitle: '',
            synonyms: '',
            genres: '',
            season: '',
            premiered: '',
            aired: '',
            broadcast: '',
            duration: '',
            thumbnail: _getValue(item, selectors['image']) ?? '',
            trailer: '',
            ytTrailer: '',
            creators: '',
            status: '',
            episodes: '',
            score: '',
            rank: '',
            popularity: '',
            rating: '',
            type: '',
            views: '',
            malId: '',
          );
        })
        .whereType<Anime>()
        .where((a) => a.animeId.isNotEmpty)
        .toList();
  }

  AnimeDetails _parseJsonDetails(dynamic data, Map<String, dynamic> selectors) {
    if (data is! Map) {
      return AnimeDetails(
        plot: '',
        synopsis: '',
        background: '',
        popularity: '',
        members: '',
        favorites: '',
        statistics: AnimeStatistics(userRate: '0', views: '0', rates: {}),
        relatedAnime: [],
      );
    }

    final synopsis = _getValue(data, selectors['synopsis']) ?? '';
    return AnimeDetails(
      plot: synopsis,
      synopsis: synopsis,
      background: '',
      popularity: '',
      members: '',
      favorites: '',
      statistics: AnimeStatistics(userRate: '0', views: '0', rates: {}),
      relatedAnime: [],
    );
  }

  List<Episode> _parseJsonEpisodes(
      dynamic data, Map<String, dynamic> selectors) {
    final root = selectors['root'] as String?;
    final itemsSource = root != null ? _getJsonRawValue(data, root) : data;

    if (itemsSource is! List) return [];

    return itemsSource
        .map((item) {
          if (item is! Map) return null;
          final url = _getValue(item, selectors['url']);
          final title = _getValue(item, selectors['title']) ?? '';
          final number = _getValue(item, selectors['number']) ?? title;

          return Episode(
            eId: url ?? '',
            animeId: '',
            episodeNumber: number,
            okLink: '',
            maLink: '',
            frLink: '',
            gdLink: '',
            svLink: '',
            released: '',
          );
        })
        .whereType<Episode>()
        .where((e) => e.eId.isNotEmpty)
        .toList();
  }

  List<StreamingServer> _parseJsonServers(
      dynamic data, Map<String, dynamic> selectors) {
    final root = selectors['root'] as String?;
    final itemsSource = root != null ? _getJsonRawValue(data, root) : data;

    if (itemsSource is! List) return [];

    return itemsSource
        .map((item) {
          if (item is! Map) return null;
          final name = _getValue(item, selectors['name']) ?? 'Server';
          final url = _getValue(item, selectors['url']);

          if (url == null) return null;

          return StreamingServer(
            name: name,
            url: url,
            quality: 'HD',
          );
        })
        .whereType<StreamingServer>()
        .toList();
  }

  dynamic _getJsonRawValue(dynamic data, String path) {
    if (path.isEmpty || path == 'self') return data;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  @override
  Future<List<TrendingItem>> loadTrending() async => [];

  @override
  Future<AppConfiguration> getConfiguration() async => AppConfiguration(
        currentSeason: '',
        studios: [],
        years: [],
        appDownloadUrl: '',
      );

  @override
  Future<List<Character>> loadCharacters({int from = 0}) async => [];

  @override
  Future<Map<String, dynamic>> loadExplore({
    required String broadcast,
    required String premiere,
  }) async =>
      {};
}
