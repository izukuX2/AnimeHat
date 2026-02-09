import 'package:flutter/foundation.dart';
import '../../../core/models/anime_model.dart';
import '../../../core/repositories/anime_firestore_repository.dart';
import '../../../../core/services/supabase_archive_service.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/extension_service.dart';
import '../../../../core/providers/anime_provider.dart';

class AnimeRepository {
  final ExtensionService extensionService;
  final AnimeFirestoreRepository _firestore = AnimeFirestoreRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  AnimeRepository({required this.extensionService});

  BaseAnimeProvider get _provider => extensionService.activeProvider;

  Future<AnimeDetails> getAnimeDetails(
    String animeId, {
    String? malId,
    Anime? animeMetadata,
  }) async {
    // Check cache first
    final cached = await _firestore.getCachedAnime(animeId);
    if (cached != null && cached['details'] != null) {
      debugPrint('DEBUG: Using cached anime details for $animeId');
      return AnimeDetails.fromJson(cached['details']);
    }

    var details = await _provider.getAnimeDetails(animeId);

    // malId logic remains here as it's a "enhancement" layer, not core provider work
    // However, we still need a way to reach Jikan. For now, we'll keep it simple
    // if provider is Animeify (which has malId logic inside its API client usually,
    // but here we used the interface)

    // Save to cache if metadata is provided
    if (animeMetadata != null) {
      await _firestore.saveAnime(animeMetadata, details);
      await _dbHelper.insertAnime(animeMetadata);
    }

    return details;
  }

  Future<void> cacheMetadata(Anime anime) async {
    await _dbHelper.insertAnime(anime);
  }

  Future<List<Episode>> getEpisodes(String animeId) async {
    // Check cache first
    final cached = await _firestore.getCachedEpisodes(animeId);
    if (cached != null) {
      debugPrint('DEBUG: Using cached episodes for $animeId');
      return _sortEpisodes(cached);
    }

    final episodes = await _provider.getEpisodes(animeId);

    // Sort episodes numerically
    final sortedEpisodes = _sortEpisodes(episodes);

    // Save to cache
    await _firestore.saveEpisodes(animeId, sortedEpisodes);

    // Archive to Supabase
    SupabaseArchiveService.archiveEpisodes(animeId, sortedEpisodes);

    return sortedEpisodes;
  }

  /// Sort episodes numerically
  List<Episode> _sortEpisodes(List<Episode> episodes) {
    return List<Episode>.from(episodes)
      ..sort((a, b) {
        final numA = double.tryParse(a.episodeNumber) ?? 0;
        final numB = double.tryParse(b.episodeNumber) ?? 0;
        return numA.compareTo(numB);
      });
  }

  Future<List<StreamingServer>> getServers(
    String animeId,
    String episodeNumber,
  ) async {
    if (animeId.isEmpty || episodeNumber.isEmpty) return [];

    // Check cache first
    final cached = await _firestore.getCachedServers(animeId, episodeNumber);
    if (cached != null) {
      debugPrint('DEBUG: Using cached servers for $animeId Ep $episodeNumber');
      return cached;
    }

    try {
      final servers = await _provider.getServers(animeId, episodeNumber);

      // Save to cache
      await _firestore.saveServers(animeId, episodeNumber, servers);

      // Archive to Supabase
      SupabaseArchiveService.archiveServers(animeId, episodeNumber, servers);

      return servers;
    } catch (e) {
      debugPrint('DEBUG: Error fetching servers: $e');
      return [];
    }
  }

  // Helper to trigger save if we have the results
  Future<void> cacheServers(
    String animeId,
    String episodeNumber,
    List<StreamingServer> servers,
  ) async {
    await _firestore.saveServers(animeId, episodeNumber, servers);
  }
}
