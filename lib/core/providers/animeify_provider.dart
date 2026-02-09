import '../api/animeify_api_client.dart';
import '../models/anime_model.dart';
import '../models/character_model.dart';
import 'anime_provider.dart';

class AnimeifyProvider implements BaseAnimeProvider {
  final AnimeifyApiClient _apiClient;

  AnimeifyProvider(this._apiClient);

  @override
  String get name => 'Animeify';

  @override
  String get id => 'animeify_legacy';

  @override
  String get baseUrl => 'https://animeify.net';

  @override
  Future<HomeData> loadHome() async {
    return await _apiClient.loadHome();
  }

  @override
  Future<List<Anime>> searchAnime(String query, {int page = 0}) async {
    return await _apiClient.searchAnime(query);
  }

  @override
  Future<AnimeDetails> getAnimeDetails(String animeId) async {
    final json = await _apiClient.getAnimeDetails(animeId);
    return AnimeDetails.fromJson(json);
  }

  @override
  Future<List<Episode>> getEpisodes(String animeId) async {
    final List<dynamic> jsonList = await _apiClient.getEpisodes(animeId);
    return jsonList.map((e) => Episode.fromJson(e)).toList();
  }

  @override
  Future<List<StreamingServer>> getServers(
      String animeId, String episodeNumber) async {
    final response = await _apiClient.loadServers(
      animeId: animeId,
      episode: episodeNumber,
    );

    final currentEpisode =
        response['CurrentEpisode'] as Map<String, dynamic>? ?? {};
    final servers = <StreamingServer>[];

    final serverMap = {
      'OKLink': 'OK.ru',
      'MALink': 'MyCloud',
      'SVLink': 'Internal 1',
      'LBLink': 'Internal 2',
      'FHLink': 'Full HD',
      'GDLink': 'G-Drive',
      'FRLink': 'MediaFire',
      'SFLink': 'SuperFast',
      'FDLink': 'Internal 3',
    };

    serverMap.forEach((baseKey, name) {
      _addServerIfValid(
          servers, currentEpisode, baseKey, name, 'HD', animeId, episodeNumber);
      _addServerIfValid(
          servers,
          currentEpisode,
          baseKey.replaceAll('Link', 'LowQ'),
          name,
          'SD',
          animeId,
          episodeNumber);
      _addServerIfValid(
          servers,
          currentEpisode,
          baseKey.replaceAll('Link', 'FhdQ'),
          name,
          'FHD',
          animeId,
          episodeNumber);
    });

    return servers;
  }

  @override
  Future<List<Anime>> getAnimeList({
    required String type,
    String filterType = 'FilterData',
    String filterData = '',
    int from = 0,
  }) async {
    return await _apiClient.getAnimeList(
      type: type,
      from: from,
      filterData: filterData,
      filterType: filterType,
    );
  }

  @override
  Future<List<TrendingItem>> loadTrending() async {
    return await _apiClient.loadTrending();
  }

  @override
  Future<AppConfiguration> getConfiguration() async {
    return await _apiClient.getConfiguration();
  }

  @override
  Future<List<Character>> loadCharacters({int from = 0}) async {
    return await _apiClient.loadCharacters(from: from);
  }

  @override
  Future<Map<String, dynamic>> loadExplore({
    required String broadcast,
    required String premiere,
  }) async {
    return await _apiClient.loadExplore(
      broadcast: broadcast,
      premiere: premiere,
    );
  }

  void _addServerIfValid(
    List<StreamingServer> servers,
    Map<String, dynamic> data,
    String key,
    String name,
    String quality,
    String animeId,
    String episode,
  ) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value != '0') {
      String url = value;
      if (!url.startsWith('http')) {
        if (key.contains('OK')) {
          url = 'https://ok.ru/videoembed/$value';
        } else if (key.contains('FR')) {
          url = 'https://www.mediafire.com/file/$value';
        } else if (key.contains('MA')) {
          url = 'https://mycloud.click/v/$value';
        } else if (key.contains('SV') ||
            key.contains('LB') ||
            key.contains('FD') ||
            key.contains('FH')) {
          final serverType = key.substring(0, 2);
          url =
              'https://animeify.net/animeify/player/player.php?v=$value&t=$serverType&id=$animeId&ep=$episode';
        }
      }
      servers.add(StreamingServer(name: name, url: url, quality: quality));
    }
  }
}
