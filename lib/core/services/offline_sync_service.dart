import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/anime_model.dart';
import '../../features/home/data/home_repository.dart';

class OfflineSyncService {
  final HomeRepository _repository;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  OfflineSyncService(this._repository);

  Stream<double> syncAll() async* {
    yield 0.0;

    try {
      // 1. Fetch Home Data
      final homeData = await _repository.getHomeData();
      yield 0.1;

      // 2. Cache News
      await _dbHelper.insertNews(homeData.latestNews);
      yield 0.2;

      // 3. Cache Home Animes
      List<Anime> homeAnimes = [];
      homeAnimes.addAll(homeData.broadcast);
      homeAnimes.addAll(homeData.premiere);
      homeAnimes.addAll(homeData.latestEpisodes.map((e) => e.anime).toList());
      await _dbHelper.insertAnimes(homeAnimes);
      yield 0.4;

      // 4. Fetch and Cache Trending
      final trending = await _repository.getTrendingItems();
      // We could insert trending metadata if we want, but for now just the animes
      await _dbHelper.insertAnimes(
        trending.where((t) => t.anime != null).map((t) => t.anime!).toList(),
      );
      yield 0.5;

      // 5. Deep Sync: Fetch more episodes for home animes (optional but requested "store all")
      // To avoid overwhelming the API, we might want to limit this or do it in chunks.
      int total = homeAnimes.length;
      int processed = 0;

      for (var anime in homeAnimes) {
        try {
          final episodes = await _repository.getEpisodes(anime.id);
          await _dbHelper.insertEpisodes(episodes);
        } catch (e) {
          debugPrint('Failed to cache episodes for ${anime.enTitle}: $e');
        }
        processed++;
        yield 0.5 + (0.5 * (processed / total));
      }

      yield 1.0;
    } catch (e) {
      debugPrint('Sync failed: $e');
      yield -1.0; // Error state
    }
  }
}
