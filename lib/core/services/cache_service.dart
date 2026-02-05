import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime_model.dart';

/// Service for caching anime metadata and app state locally
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _trendingCacheKey = 'cached_trending_anime';
  static const String _lastSyncKey = 'last_cache_sync_time';

  /// Save trending anime to local storage
  Future<void> cacheTrending(List<Anime> animes) async {
    final prefs = await SharedPreferences.getInstance();
    final data = animes.map((a) => a.toMap()).toList();
    await prefs.setString(_trendingCacheKey, jsonEncode(data));
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    debugPrint("CACHE UPDATED: ${animes.length} trending items saved.");
  }

  /// Retrieve cached trending anime
  Future<List<Anime>> getCachedTrending() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_trendingCacheKey);
    if (dataStr == null) return [];

    try {
      final List<dynamic> data = jsonDecode(dataStr);
      return data.map((json) => Anime.fromJson(json)).toList();
    } catch (e) {
      debugPrint("CACHE ERROR: Failed to parse trending cache: $e");
      return [];
    }
  }

  /// Check if cache is stale (older than 6 hours)
  Future<bool> isCacheStale() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
    final diff = DateTime.now().millisecondsSinceEpoch - lastSync;
    return diff > (6 * 60 * 60 * 1000); // 6 hours
  }

  /// Cache a single anime details
  Future<void> cacheAnime(Anime anime) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'anime_cache_${anime.animeId}';
    await prefs.setString(key, jsonEncode(anime.toMap()));
  }

  /// Get cached single anime
  Future<Anime?> getCachedAnime(String animeId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'anime_cache_$animeId';
    final dataStr = prefs.getString(key);
    if (dataStr == null) return null;

    try {
      return Anime.fromJson(jsonDecode(dataStr));
    } catch (e) {
      return null;
    }
  }
}
