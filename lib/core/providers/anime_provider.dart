import '../models/anime_model.dart';
import '../models/character_model.dart';

abstract class BaseAnimeProvider {
  String get name;
  String get id;
  String get baseUrl;

  /// Load home data (latest episodes, trending, etc.)
  Future<HomeData> loadHome();

  /// Load trending anime items
  Future<List<TrendingItem>> loadTrending();

  /// Get application configuration (ads, updates, etc.)
  Future<AppConfiguration> getConfiguration();

  /// Search for anime by query
  Future<List<Anime>> searchAnime(String query, {int page = 0});

  /// Get details for a specific anime
  Future<AnimeDetails> getAnimeDetails(String animeId);

  /// Get list of episodes for a specific anime
  Future<List<Episode>> getEpisodes(String animeId);

  /// Get streaming servers for a specific episode
  Future<List<StreamingServer>> getServers(
      String animeId, String episodeNumber);

  /// Get characters list
  Future<List<Character>> loadCharacters({int from = 0});

  /// Get explore data (categorized)
  Future<Map<String, dynamic>> loadExplore({
    required String broadcast,
    required String premiere,
  });

  /// Get a list of anime by type/category
  Future<List<Anime>> getAnimeList({
    required String type,
    String filterType = '',
    String filterData = '',
    int from = 0,
  });
}
