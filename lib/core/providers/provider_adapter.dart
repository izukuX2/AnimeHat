import 'package:flutter/foundation.dart';
import 'package:anime_hat/core/extensions/base_provider.dart';
import 'package:anime_hat/core/models/anime_model.dart';
import 'package:anime_hat/core/models/character_model.dart';
import 'anime_provider.dart';

/// Adapter that wraps a new BaseProvider to work with the legacy BaseAnimeProvider interface.
/// This allows gradual migration from JSON-based to Dart-native providers.
class ProviderAdapter implements BaseAnimeProvider {
  final BaseProvider _provider;

  ProviderAdapter(this._provider);

  @override
  String get id => _provider.id;

  @override
  String get name => _provider.name;

  @override
  String get baseUrl => _provider.baseUrl;

  @override
  Future<HomeData> loadHome() async {
    debugPrint('ProviderAdapter: Loading home via ${_provider.name}');
    return _provider.getHome();
  }

  @override
  Future<List<TrendingItem>> loadTrending() async {
    // Convert anime list from home to trending items
    final home = await _provider.getHome();
    return home.broadcast
        .map((a) => TrendingItem(
              id: a.id,
              title: a.enTitle,
              photo: a.thumbnail,
              type: 'ANIME',
              anime: a,
            ))
        .toList();
  }

  @override
  Future<AppConfiguration> getConfiguration() async {
    // Return default config - provider doesn't handle this
    return AppConfiguration(
      currentSeason: '',
      studios: [],
      years: [],
      appDownloadUrl: '',
    );
  }

  @override
  Future<List<Anime>> searchAnime(String query, {int page = 0}) async {
    debugPrint('ProviderAdapter: Searching "$query" via ${_provider.name}');
    return _provider.search(query);
  }

  @override
  Future<AnimeDetails> getAnimeDetails(String animeId) async {
    debugPrint(
        'ProviderAdapter: Getting details for $animeId via ${_provider.name}');
    return _provider.getDetails(animeId);
  }

  @override
  Future<List<Episode>> getEpisodes(String animeId) async {
    debugPrint(
        'ProviderAdapter: Getting episodes for $animeId via ${_provider.name}');
    return _provider.getEpisodes(animeId);
  }

  @override
  Future<List<StreamingServer>> getServers(
      String animeId, String episodeNumber) async {
    debugPrint(
        'ProviderAdapter: Getting servers for $animeId ep $episodeNumber via ${_provider.name}');

    // Find the episode by number to get its real URL
    // We cannot construct the URL manually because it varies (movies, series, etc.)
    final episodes = await _provider.getEpisodes(animeId);

    Episode? episode;
    try {
      episode = episodes.firstWhere(
        (e) =>
            e.episodeNumber == episodeNumber || e.eId.contains(episodeNumber),
      );
    } catch (e) {
      debugPrint(
          'ProviderAdapter: Episode $episodeNumber not found for $animeId');
      return [];
    }

    final enhancedServers = await _provider.getServers(episode);

    // Convert to legacy format with quality in name
    return enhancedServers.map((s) => s.toStreamingServer()).toList();
  }

  @override
  Future<List<Character>> loadCharacters({int from = 0}) async {
    // Not supported by most providers
    return [];
  }

  @override
  Future<Map<String, dynamic>> loadExplore({
    required String broadcast,
    required String premiere,
  }) async {
    // Return basic explore data
    final home = await _provider.getHome();
    return {
      'latest': home.latestEpisodes,
      'broadcast': home.broadcast,
      'premiere': home.premiere,
    };
  }

  @override
  Future<List<Anime>> getAnimeList({
    required String type,
    String filterType = '',
    String filterData = '',
    int from = 0,
  }) async {
    debugPrint('ProviderAdapter: Getting $type list via ${_provider.name}');
    return _provider.getAnimeList(
      type: type,
      filterType: filterType,
      filterData: filterData,
      from: from,
    );
  }
}
