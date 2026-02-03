import '../../../core/api/animeify_api_client.dart';
import '../../../core/models/anime_model.dart';
import '../../../core/repositories/anime_firestore_repository.dart';
import '../../../../core/services/supabase_archive_service.dart';
import '../../../../core/database/database_helper.dart';

class AnimeRepository {
  final AnimeifyApiClient apiClient;
  final AnimeFirestoreRepository _firestore = AnimeFirestoreRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  AnimeRepository({required this.apiClient});

  Future<AnimeDetails> getAnimeDetails(
    String animeId, {
    String? malId,
    Anime? animeMetadata,
  }) async {
    // Check cache first
    final cached = await _firestore.getCachedAnime(animeId);
    if (cached != null && cached['details'] != null) {
      print('DEBUG: Using cached anime details for $animeId');
      return AnimeDetails.fromJson(cached['details']);
    }

    final jsonify = await apiClient.getAnimeDetails(animeId);
    var details = AnimeDetails.fromJson(jsonify);

    if (malId != null && malId.isNotEmpty && malId != '0') {
      try {
        final jikanJson = await apiClient.getJikanDetails(malId);
        final jikanDetails = AnimeDetails.fromJson(jikanJson);

        // Merge Jikan data into details
        details = details.copyWith(
          synopsis: jikanDetails.synopsis,
          background: jikanDetails.background,
          popularity: jikanDetails.popularity,
          members: jikanDetails.members,
          favorites: jikanDetails.favorites,
          // Use Jikan synopsis if plot is empty or very short
          plot: details.plot.length < 20 ? jikanDetails.synopsis : details.plot,
        );
      } catch (e) {
        print('DEBUG: Jikan merge error: $e');
        // Continue with Animeify details only
      }
    }

    // Save to cache if metadata is provided
    if (animeMetadata != null) {
      await _firestore.saveAnime(animeMetadata, details);
      await _dbHelper.insertAnime(
        animeMetadata,
      ); // Cache locally for LibraryView
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
      print('DEBUG: Using cached episodes for $animeId');
      return _sortEpisodes(cached);
    }

    final List<dynamic> jsonList = await apiClient.getEpisodes(animeId);
    final episodes = jsonList.map((e) => Episode.fromJson(e)).toList();

    // Sort episodes numerically
    final sortedEpisodes = _sortEpisodes(episodes);

    // Save to cache
    await _firestore.saveEpisodes(animeId, sortedEpisodes);

    // Archive to Supabase
    SupabaseArchiveService.archiveEpisodes(animeId, sortedEpisodes);

    return sortedEpisodes;
  }

  /// Sort episodes numerically (handles "1", "1.5", "10", "100", "1000" correctly)
  List<Episode> _sortEpisodes(List<Episode> episodes) {
    return List<Episode>.from(episodes)..sort((a, b) {
      // Parse episode numbers as doubles to handle decimals like "1.5"
      final numA = double.tryParse(a.episodeNumber) ?? 0;
      final numB = double.tryParse(b.episodeNumber) ?? 0;
      return numA.compareTo(numB);
    });
  }

  Future<List<StreamingServer>> getServers(
    String animeId,
    String episodeNumber,
  ) async {
    if (animeId.isEmpty || episodeNumber.isEmpty) {
      print(
        'DEBUG: Skipping getServers for $animeId Ep $episodeNumber (Empty ID or Ep)',
      );
      return [];
    }

    // Check cache first
    final cached = await _firestore.getCachedServers(animeId, episodeNumber);
    if (cached != null) {
      print('DEBUG: Using cached servers for $animeId Ep $episodeNumber');
      return cached;
    }

    try {
      final response = await apiClient.loadServers(
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
        // Check standard HD quality
        _addServerIfValid(
          servers,
          currentEpisode,
          baseKey,
          name,
          'HD',
          animeId,
          episodeNumber,
        );

        // Check Low quality (SD)
        final lowKey = baseKey.replaceAll('Link', 'LowQ');
        _addServerIfValid(
          servers,
          currentEpisode,
          lowKey,
          name,
          'SD',
          animeId,
          episodeNumber,
        );

        // Check Full HD quality (FHD)
        final fhdKey = baseKey.replaceAll('Link', 'FhdQ');
        _addServerIfValid(
          servers,
          currentEpisode,
          fhdKey,
          name,
          'FHD',
          animeId,
          episodeNumber,
        );
      });

      // Save to cache
      await _firestore.saveServers(animeId, episodeNumber, servers);

      // Archive to Supabase
      SupabaseArchiveService.archiveServers(animeId, episodeNumber, servers);

      return servers;
    } catch (e) {
      print('DEBUG: Error fetching servers for $animeId Ep $episodeNumber: $e');
      return []; // Return empty list on failure
    }
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
    if (value != null && value.isNotEmpty) {
      // Basic placeholder check - though '1' might be valid for some internal servers
      // we only skip if it's literally just '0' or empty after trimming.
      if (value == '0') return;

      String url = value;

      // If it's not a full URL, attempt to construct it based on the server type
      if (!url.startsWith('http')) {
        if (key.contains('OK')) {
          url = 'https://ok.ru/videoembed/$value';
        } else if (key.contains('FR')) {
          url = 'https://www.mediafire.com/file/$value';
        } else if (key.contains('MA')) {
          url = 'https://mycloud.click/v/$value'; // Common MyCloud pattern
        } else if (key.contains('SV') ||
            key.contains('LB') ||
            key.contains('FD') ||
            key.contains('FH')) {
          // Internal servers often need animeId and episode if the value is a flag like '1'
          final serverType = key.substring(0, 2);
          url =
              'https://animeify.net/animeify/player/player.php?v=$value&t=$serverType&id=$animeId&ep=$episode';
        }
      }

      servers.add(StreamingServer(name: name, url: url, quality: quality));
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
