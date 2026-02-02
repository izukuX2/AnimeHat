import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime_model.dart';
import '../models/character_model.dart';
import '../config/env.dart';

class AnimeifyApiClient {
  static const String domain = 'animeify.net';
  static const String apiPath = '/animeify/apis_v4';
  static const String baseUrl = 'https://$domain$apiPath';

  final String token = Env.animeifyToken;
  final String userId = '0';

  final Map<String, String> _headers = {
    'User-Agent': 'okhttp/4.9.0',
    'Accept': '*/*',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Connection': 'keep-alive',
  };

  dynamic _safeDecode(http.Response response, String endpoint) {
    try {
      final body = response.body.trim();
      if (body.isEmpty) {
        throw Exception(
          'Empty response from $endpoint (Status: ${response.statusCode})',
        );
      }

      if (body.startsWith('<')) {
        print('DEBUG: HTML Error detected from $endpoint:');
        print('DEBUG: Body snippet: ${body.take(200)}');
        throw Exception(
          'Server returned HTML instead of JSON from $endpoint. '
          'This often happens due to PHP errors or 404s. '
          'Status: ${response.statusCode}',
        );
      }

      return json.decode(body);
    } on FormatException catch (e) {
      print('DEBUG: JSON Decode Error from $endpoint: $e');
      throw Exception('Failed to decode JSON from $endpoint: $e');
    } catch (e) {
      print('DEBUG: Error in _safeDecode for $endpoint: $e');
      rethrow;
    }
  }

  Future<T> _wrapNetworkCall<T>(
    Future<T> Function() call,
    String endpoint,
  ) async {
    try {
      return await call();
    } on http.ClientException catch (e) {
      print('DEBUG: Network Client Error ($endpoint): $e');
      throw Exception('Network error: Please check your internet connection.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        print('DEBUG: Connectivity Error ($endpoint): $e');
        throw Exception('No internet connection. Please try again later.');
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getLatestEpisodesRaw() async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(
        domain,
        '$apiPath/episodes/load_latest_episodes.php',
      );
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'From': '0',
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _safeDecode(response, 'load_latest_episodes.php');
      } else {
        throw Exception(
          'Failed to load latest episodes: ${response.statusCode}',
        );
      }
    }, 'getLatestEpisodesRaw');
  }

  Future<List<dynamic>> getLatestAnime() async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/anime/load_latest_anime.php');
      final body = {
        'UserId': userId,
        'From': '0',
        'Language': 'AR',
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _safeDecode(response, 'load_latest_anime.php');
      } else {
        throw Exception('Failed to load latest anime: ${response.statusCode}');
      }
    }, 'getLatestAnime');
  }

  Future<List<Anime>> getMovies() async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/anime/load_anime_list_v2.php');
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'FilterType': 'NEW_MOVIES',
        'Type': 'MOVIE',
        'From': '0',
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(
          response,
          'load_anime_list_v2.php (Movies)',
        );
        if (decoded is List) {
          return decoded.map((json) => Anime.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    }, 'getMovies');
  }

  Future<List<Anime>> searchAnime(String query) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/anime/load_anime_list_v2.php');
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'FilterType': 'SEARCH',
        'FilterData': query,
        'Type': 'SERIES',
        'From': '0',
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(
          response,
          'load_anime_list_v2.php (Search)',
        );
        if (decoded is List) {
          return decoded.map((json) => Anime.fromJson(json)).toList();
        } else if (decoded is Map && decoded.containsKey('Anime')) {
          return [Anime.fromJson(decoded['Anime'])];
        }
        return [];
      } else {
        throw Exception('Failed to search anime: ${response.statusCode}');
      }
    }, 'searchAnime');
  }

  Future<Map<String, dynamic>> getAnimeDetails(String animeId) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/anime/load_anime_details.php');
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'AnimeId': animeId,
        'AnimeRelationId': '',
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _safeDecode(response, 'load_anime_details.php');
      } else {
        throw Exception('Failed to load anime details: ${response.statusCode}');
      }
    }, 'getAnimeDetails');
  }

  Future<List<dynamic>> getEpisodes(String animeId) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/episodes/load_episodes.php');
      final body = {'AnimeID': animeId, 'UserId': userId, 'Token': token};

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _safeDecode(response, 'load_episodes.php');
      } else {
        throw Exception('Failed to load episodes: ${response.statusCode}');
      }
    }, 'getEpisodes');
  }

  Future<Map<String, dynamic>> loadServers({
    required String animeId,
    required String episode,
    String animeType = 'SERIES',
  }) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/anime/load_servers.php');
      final body = {
        'UserId': userId,
        'AnimeId': animeId,
        'Episode': episode,
        'AnimeType': animeType,
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _safeDecode(response, 'load_servers.php');
      } else {
        throw Exception('Failed to load servers: ${response.statusCode}');
      }
    }, 'loadServers');
  }

  Future<AppConfiguration> getConfiguration() async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/configuration.php');
      final body = {'user_id': userId, 'notification_id': '0', 'Token': token};

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'configuration.php');
        return AppConfiguration.fromJson(decoded);
      } else {
        throw Exception('Failed to load configuration: ${response.statusCode}');
      }
    }, 'getConfiguration');
  }

  Future<List<TrendingItem>> loadTrending() async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/home/load_trending.php');
      final body = {'UserId': userId, 'Language': 'AR', 'Token': token};

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'load_trending.php');
        if (decoded is List) {
          return decoded.map((e) => TrendingItem.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load trending: ${response.statusCode}');
      }
    }, 'loadTrending');
  }

  Future<HomeData> loadHome() async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/home/load_home.php');
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'Broadcast': 'FRIDAY',
        'Premiered': 'Winter 2026',
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'load_home.php');
        return HomeData.fromJson(decoded);
      } else {
        throw Exception('Failed to load home data: ${response.statusCode}');
      }
    }, 'loadHome');
  }

  Future<List<NewsItem>> loadNewsList({int from = 0}) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/news/load_news.php');
      final body = {'Language': 'AR', 'From': from.toString(), 'Token': token};

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'load_news.php');
        if (decoded is List) {
          return decoded.map((json) => NewsItem.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    }, 'loadNewsList');
  }

  Future<List<Character>> loadCharacters({int from = 0}) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/characters/characters_list.php');
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'From': from.toString(),
        'Sortby': '',
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'characters_list.php');
        if (decoded is List) {
          return decoded.map((json) => Character.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load characters: ${response.statusCode}');
      }
    }, 'loadCharacters');
  }

  Future<List<Character>> loadDemoCharacters() async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/characters/demo_characters.php');
      final body = {'UserId': userId, 'Token': token};

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'demo_characters.php');
        if (decoded is List) {
          return decoded.map((json) => Character.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception(
          'Failed to load demo characters: ${response.statusCode}',
        );
      }
    }, 'loadDemoCharacters');
  }

  Future<Map<String, dynamic>> loadExplore({
    required String broadcast,
    required String premiere,
  }) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/explore/loade_explore.php');
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'Broadcast': broadcast,
        'Premiere': premiere,
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _safeDecode(response, 'loade_explore.php');
      } else {
        throw Exception('Failed to load explore data: ${response.statusCode}');
      }
    }, 'loadExplore');
  }

  Future<List<Anime>> getAnimeList({
    required String type,
    String filterType = 'FilterData',
    String filterData = '',
    int from = 0,
  }) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https(domain, '$apiPath/anime/load_anime_list_v2.php');
      final body = {
        'UserId': userId,
        'Language': 'AR',
        'FilterType': filterType,
        'FilterData': filterData,
        'Type': type,
        'From': from.toString(),
        'Token': token,
      };

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'load_anime_list_v2.php');
        if (decoded is List) {
          return decoded.map((e) => Anime.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load anime list: ${response.statusCode}');
      }
    }, 'getAnimeList');
  }

  Future<Map<String, dynamic>> getJikanDetails(String malId) async {
    return _wrapNetworkCall(() async {
      final url = Uri.https('api.jikan.moe', '/v4/anime/$malId');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response, 'Jikan API ($malId)');
        return decoded['data'] ?? {};
      } else {
        throw Exception('Failed to load Jikan details: ${response.statusCode}');
      }
    }, 'getJikanDetails');
  }
}

extension StringExtension on String {
  String take(int n) => length > n ? substring(0, n) : this;
}
