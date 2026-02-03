import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/anime_model.dart';
import '../../core/models/character_model.dart';
import '../../core/repositories/admin_repository.dart';

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
      AdminRepository().logSystemEvent(
        message: 'Archived Anime: ${anime.enTitle}',
        type: 'success',
      );
    } catch (e) {
      debugPrint('[Supabase] Failed to archive anime ${anime.animeId}: $e');
      AdminRepository().logSystemEvent(
        message: 'Failed to archive anime ${anime.animeId}: $e',
        type: 'error',
      );
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
      AdminRepository().logSystemEvent(
        message: 'Archived ${episodes.length} episodes for $animeId',
        type: 'success',
      );
    } catch (e) {
      debugPrint('[Supabase] Failed to archive episodes for $animeId: $e');
      AdminRepository().logSystemEvent(
        message: 'Failed to archive episodes for $animeId: $e',
        type: 'error',
      );
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
      // Clean up existing servers for this episode to prevent duplicates
      await _supabase.from('servers').delete().eq('episode_id', episodeId);

      final List<Map<String, dynamic>> records = servers.map((s) {
        return {
          'episode_id': episodeId,
          'server_name': s.name,
          'server_url': s.url,
          'quality': s.quality,
          'last_updated': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _supabase.from('servers').insert(records);

      debugPrint(
        '[Supabase] Archived ${servers.length} servers for $episodeId',
      );
    } catch (e) {
      debugPrint('[Supabase] Failed to archive servers for $episodeId: $e');
    }
  }

  /// Archive characters
  static Future<void> archiveCharacters(List<Character> characters) async {
    if (characters.isEmpty) return;

    try {
      final List<Map<String, dynamic>> records = characters.map((c) {
        return {
          'id': c.id, // Using the API ID as primary key
          'char_id': c.charId,
          'name_en': c.nameEn,
          'name_ar': c.nameAr,
          'name_jp': c.nameJp,
          'aka': c.aka,
          'gender': c.gender,
          'age': c.age,
          'height': c.height,
          'weight': c.weight,
          'blood_type': c.bloodType,
          'relation_id': c.relationId,
          'photo': c.photo,
          'cover': c.cover,
          'views': c.views,
          'likes': c.likersCount,
          'last_updated': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _supabase.from('characters').upsert(records, onConflict: 'id');
      debugPrint('[Supabase] Archived ${characters.length} characters');
      AdminRepository().logSystemEvent(
        message: 'Archived ${characters.length} characters',
        type: 'success',
      );
    } catch (e) {
      debugPrint('[Supabase] Failed to archive characters: $e');
      AdminRepository().logSystemEvent(
        message: 'Failed to archive characters: $e',
        type: 'error',
      );
    }
  }

  /// Check if a table exists (Quick check via RPC or simple query)
  static Future<bool> checkTableExists(String tableName) async {
    try {
      await _supabase.from(tableName).select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
