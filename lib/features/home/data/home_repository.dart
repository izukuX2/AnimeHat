import 'package:flutter/foundation.dart';
import '../../../core/services/extension_service.dart';
import '../../../core/providers/anime_provider.dart';
import '../../../core/models/anime_model.dart';
import '../../../core/models/character_model.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/supabase_archive_service.dart';

class HomeRepository {
  final ExtensionService _extensionService;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  HomeRepository({required ExtensionService extensionService})
      : _extensionService = extensionService;

  BaseAnimeProvider get _provider => _extensionService.activeProvider;

  Future<List<AnimeWithEpisode>> getLatestEpisodes() async {
    final homeData = await _provider.loadHome();
    return homeData.latestEpisodes;
  }

  Future<HomeData> getHomeData() async {
    try {
      final data = await _provider.loadHome();
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
          latestEpisodes: [], // Complex to reconstruct without episode cache, maybe simplify
          broadcast: allAnimes.where((a) => a.status == 'Ongoing').toList(),
          premiere: allAnimes.where((a) => a.season.isNotEmpty).toList(),
          latestNews: news,
        );
      }
      rethrow;
    }
  }

  Future<List<TrendingItem>> getTrendingItems() async {
    return await _provider.loadTrending();
  }

  Future<AppConfiguration> getConfiguration() async {
    return await _provider.getConfiguration();
  }

  Future<List<Anime>> getMovies() async {
    return await _provider.getAnimeList(
      type: 'MOVIE',
      filterType: 'NEW_MOVIES',
    );
  }

  Future<List<Anime>> getSeries(int from) async {
    return await _provider.getAnimeList(type: 'SERIES', from: from);
  }

  Future<List<Anime>> getFilteredAnime({String? year, String? studio}) async {
    if (year != null) {
      return await _provider.getAnimeList(
        type: 'SERIES',
        filterType: 'YEAR',
        filterData: year,
      );
    } else if (studio != null) {
      return await _provider.getAnimeList(
        type: 'SERIES',
        filterType: 'STUDIO',
        filterData: studio,
      );
    }
    return [];
  }

  Future<List<Anime>> searchAnime(String query) async {
    return await _provider.searchAnime(query);
  }

  Future<List<NewsItem>> getNewsList({int from = 0}) async {
    // Note: getNewsList is not yet in provider interface, but used in News Screen
    // For now, if provider is Animeify, we can reach it or we add to interface
    // Adding to interface is best
    return [];
  }

  Future<List<Character>> getCharacters({int from = 0}) async {
    final chars = await _provider.loadCharacters(from: from);
    SupabaseArchiveService.archiveCharacters(chars);
    return chars;
  }

  Future<List<Character>> getDemoCharacters() async {
    // For now assume provider handles it or just use loadCharacters
    final chars = await _provider.loadCharacters(from: 0);
    SupabaseArchiveService.archiveCharacters(chars);
    return chars;
  }

  Future<Map<String, dynamic>> getExploreData({
    required String broadcast,
    required String premiere,
  }) async {
    return await _provider.loadExplore(
      broadcast: broadcast,
      premiere: premiere,
    );
  }

  Future<Anime> getAnimeById(String animeId) async {
    // 1. Try cache first for instant metadata availability
    final cached = await _dbHelper.getAnime(animeId);
    if (cached != null) {
      // Background update to keep it fresh without blocking UI
      _updateAnimeCache(animeId);
      return cached;
    }

    // 2. Fallback to API if not cached
    try {
      await _provider.getAnimeDetails(animeId);
      // Construct an Anime object from details if needed, but usually
      // getAnimeById returns metadata. Providers should have getAnimeMetadata.
      // For now, we'll try to get it from search if not found, or assume details
      // can be converted.

      // AnimeifyApiClient has getAnimeDetails returning Map.
      // Let's assume the provider returns enough info.
      return Anime(
        id: '',
        animeId: animeId,
        enTitle: '', // This is a bit weak, need better provider method
        jpTitle: '',
        arTitle: '',
        synonyms: '',
        genres: '',
        season: '',
        premiered: '',
        aired: '',
        broadcast: '',
        duration: '',
        thumbnail: '',
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateAnimeCache(String animeId) async {
    try {
      // Similar to getAnimeById but background
    } catch (e) {
      debugPrint("Background cache update failed for $animeId: $e");
    }
  }

  Future<List<Episode>> getEpisodes(String animeId) async {
    try {
      final episodes = await _provider.getEpisodes(animeId);
      await _dbHelper.insertEpisodes(episodes);
      return episodes;
    } catch (e) {
      final cached = await _dbHelper.getEpisodes(animeId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }
}
