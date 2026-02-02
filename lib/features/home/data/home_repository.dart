import '../../../core/api/animeify_api_client.dart';
import '../../../core/models/anime_model.dart';
import '../../../core/models/character_model.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/supabase_archive_service.dart';

class HomeRepository {
  final AnimeifyApiClient apiClient;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  HomeRepository({required this.apiClient});

  Future<List<AnimeWithEpisode>> getLatestEpisodes() async {
    final List<dynamic> latestJson = await apiClient.getLatestEpisodesRaw();
    return latestJson.map((json) {
      if (json is Map<String, dynamic> && json.containsKey('Anime')) {
        return AnimeWithEpisode.fromJson(json);
      } else {
        return AnimeWithEpisode(
          anime: Anime.fromJson(json),
          episode: Episode.fromJson(json),
        );
      }
    }).toList();
  }

  Future<HomeData> getHomeData() async {
    try {
      final data = await apiClient.loadHome();
      // Update cache
      await _dbHelper.insertAnimes(data.broadcast);
      await _dbHelper.insertAnimes(data.premiere);
      await _dbHelper.insertAnimes(
        data.latestEpisodes.map((e) => e.anime).toList(),
      );
      await _dbHelper.insertNews(data.latestNews);
      return data;
    } catch (e) {
      // Fallback to cache
      final news = await _dbHelper.getNews();
      final allAnimes = await _dbHelper.getAllAnimes();
      if (news.isNotEmpty || allAnimes.isNotEmpty) {
        return HomeData(
          latestEpisodes:
              [], // Complex to reconstruct without episode cache, maybe simplify
          broadcast: allAnimes.where((a) => a.status == 'Ongoing').toList(),
          premiere: allAnimes.where((a) => a.season.isNotEmpty).toList(),
          latestNews: news,
        );
      }
      rethrow;
    }
  }

  Future<List<TrendingItem>> getTrendingItems() async {
    return await apiClient.loadTrending();
  }

  Future<AppConfiguration> getConfiguration() async {
    return await apiClient.getConfiguration();
  }

  Future<List<Anime>> getMovies() async {
    return await apiClient.getAnimeList(
      type: 'MOVIE',
      filterType: 'NEW_MOVIES',
    );
  }

  Future<List<Anime>> getSeries(int from) async {
    return await apiClient.getAnimeList(type: 'SERIES', from: from);
  }

  Future<List<Anime>> getFilteredAnime({String? year, String? studio}) async {
    if (year != null) {
      return await apiClient.getAnimeList(
        type: 'SERIES',
        filterType: 'YEAR',
        filterData: year,
      );
    } else if (studio != null) {
      return await apiClient.getAnimeList(
        type: 'SERIES',
        filterType: 'STUDIO',
        filterData: studio,
      );
    }
    return [];
  }

  Future<List<Anime>> searchAnime(String query) async {
    return await apiClient.searchAnime(query);
  }

  Future<List<NewsItem>> getNewsList({int from = 0}) async {
    return await apiClient.loadNewsList(from: from);
  }

  Future<List<Character>> getCharacters({int from = 0}) async {
    return await apiClient.loadCharacters(from: from);
  }

  Future<List<Character>> getDemoCharacters() async {
    return await apiClient.loadDemoCharacters();
  }

  Future<Map<String, dynamic>> getExploreData({
    required String broadcast,
    required String premiere,
  }) async {
    return await apiClient.loadExplore(
      broadcast: broadcast,
      premiere: premiere,
    );
  }

  Future<Anime> getAnimeById(String animeId) async {
    try {
      var json = await apiClient.getAnimeDetails(animeId);
      // Ensure the ID is present in the JSON so the model is valid
      if (json['AnimeId'] == null && json['animeId'] == null) {
        // Create a mutable copy if needed, but safeDecode usually returns a standard map
        json = Map<String, dynamic>.from(json);
        json['AnimeId'] = animeId;
      }
      final anime = Anime.fromJson(json);
      await _dbHelper.insertAnime(anime);

      // Archive to Supabase (Fire-and-forget)
      SupabaseArchiveService.archiveAnime(anime);

      return anime;
    } catch (e) {
      final cached = await _dbHelper.getAnime(animeId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Episode>> getEpisodes(String animeId) async {
    try {
      final List<dynamic> jsonList = await apiClient.getEpisodes(animeId);
      final episodes = jsonList.map((e) => Episode.fromJson(e)).toList();
      await _dbHelper.insertEpisodes(episodes);
      return episodes;
    } catch (e) {
      final cached = await _dbHelper.getEpisodes(animeId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }
}
