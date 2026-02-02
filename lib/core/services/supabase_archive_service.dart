import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/anime_model.dart';

class SupabaseArchiveService {
  static final _supabase = Supabase.instance.client;

  /// Fire-and-forget method to archive anime details
  static Future<void> archiveAnime(Anime anime) async {
    try {
      // Use upsert to insert or update if already exists
      await _supabase.from('animes').upsert({
        'id': anime.animeId, // Explicitly using animeId as primary reference
        'title': anime.enTitle,
        'poster': anime.thumbnail,
        'synopsis': anime
            .genres, // Using genres since synopsis is not in basic Anime model
        'rating': anime.rating,
        'status': anime.status,
        'year': anime.premiered,
        'metadata': anime
            .toMap(), // Store full raw JSON/Map for future proofing
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'id'); // Ensure 'id' is the conflict constraint
      debugPrint('[Supabase] Archived Anime: ${anime.enTitle}');
    } catch (e) {
      debugPrint('[Supabase] Failed to archive anime ${anime.animeId}: $e');
    }
  }

  /// Archive a list of episodes
  static Future<void> archiveEpisodes(
    String animeId,
    List<Episode> episodes,
  ) async {
    if (episodes.isEmpty) return;

    try {
      final List<Map<String, dynamic>> records = episodes.map((e) {
        return {
          'id': '${animeId}_${e.episodeNumber}', // Composite ID
          'anime_id': animeId,
          'episode_number': e.episodeNumber,
          'title': 'Episode ${e.episodeNumber}',
          'thumbnail':
              '', // Can be populated if we have episode thumbnails later
          'last_updated': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _supabase.from('episodes').upsert(records, onConflict: 'id');
      debugPrint(
        '[Supabase] Archived ${episodes.length} episodes for $animeId',
      );
    } catch (e) {
      debugPrint('[Supabase] Failed to archive episodes for $animeId: $e');
    }
  }

  /// Archive servers for a specific episode
  static Future<void> archiveServers(
    String animeId,
    String episodeNumber,
    List<StreamingServer> servers,
  ) async {
    if (servers.isEmpty) return;

    final episodeId = '${animeId}_$episodeNumber';

    try {
      // For servers, we might want to just insert them.
      // Upserting is tricky without a unique ID for the server link itself.
      // Strategy: Delete existing for this episode and re-insert to keep it fresh.

      // 1. Delete old servers for this episode (Optional, but cleaner)
      // Note: This requires a policy or setup that allows deletion.
      // For now, let's just insert and rely on generated ID.
      // Or better, check if we can make a unique hash.

      // Simpler approach: Just insert. Repeated inserts might duplicate data over time.
      // Let's use a composite key if possible or just log them.
      // Ideally, we want unique servers.
      // Let's assume (episode_id, server_name) is unique-ish? checking server_url is better.

      final List<Map<String, dynamic>> records = servers.map((s) {
        return {
          'episode_id': episodeId,
          'server_name': s.name,
          'server_url': s.url,
          'quality': s.quality,
          'last_updated': DateTime.now().toIso8601String(),
        };
      }).toList();

      // We won't use upsert for servers right now unless we have a unique constraint.
      // If the user ran the SQL I provided, 'id' is auto-gen.
      // Let's just insert. Duplicate archival might happen but better than missing data.
      await _supabase.from('servers').insert(records);

      debugPrint(
        '[Supabase] Archived ${servers.length} servers for $episodeId',
      );
    } catch (e) {
      debugPrint('[Supabase] Failed to archive servers for $episodeId: $e');
    }
  }
}
