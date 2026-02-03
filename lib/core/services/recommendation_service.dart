import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime_model.dart';

/// Service for generating personalized anime recommendations
class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  /// Genre weights based on user preferences and watch history
  final Map<String, double> _genreWeights = {};

  /// Recently watched anime IDs
  final Set<String> _watchedAnimeIds = {};

  /// User's favorite genres from onboarding
  List<String> _favoriteGenres = [];

  /// Initialize the service with user data
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load favorite genres from onboarding
    _favoriteGenres = prefs.getStringList('favorite_genres') ?? [];

    // Initialize weights from favorite genres
    for (final genre in _favoriteGenres) {
      _genreWeights[genre] =
          2.0; // Higher weight for explicitly selected genres
    }

    // Load watch history
    await _loadWatchHistory();
  }

  /// Load watch history and update genre weights
  Future<void> _loadWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('continue_watching');
      if (historyJson == null) return;

      final List<dynamic> history = jsonDecode(historyJson);

      for (final item in history) {
        _watchedAnimeIds.add(item['animeId'].toString());

        // If the item has genre info, boost those genres
        final genres = item['genres'] as List<dynamic>?;
        if (genres != null) {
          for (final genre in genres) {
            final genreName = genre.toString();
            _genreWeights[genreName] = (_genreWeights[genreName] ?? 0) + 0.5;
          }
        }
      }
    } catch (e) {
      // Silently fail if history can't be loaded
    }
  }

  /// Record that user watched an anime
  void recordWatch(String animeId, List<String> genres) {
    _watchedAnimeIds.add(animeId);

    for (final genre in genres) {
      _genreWeights[genre] = (_genreWeights[genre] ?? 0) + 0.3;
    }
  }

  /// Record that user completed an anime (higher weight)
  void recordCompletion(String animeId, List<String> genres) {
    _watchedAnimeIds.add(animeId);

    for (final genre in genres) {
      _genreWeights[genre] = (_genreWeights[genre] ?? 0) + 1.0;
    }
  }

  /// Record that user skipped/dropped an anime (negative weight)
  void recordDrop(String animeId, List<String> genres) {
    for (final genre in genres) {
      _genreWeights[genre] = (_genreWeights[genre] ?? 0) - 0.5;
    }
  }

  /// Calculate recommendation score for an anime
  double calculateScore(Map<String, dynamic> anime) {
    double score = 0.0;

    // Skip if already watched
    final animeId = anime['id']?.toString() ?? anime['mal_id']?.toString();
    if (animeId != null && _watchedAnimeIds.contains(animeId)) {
      return -1.0; // Negative score means don't recommend
    }

    // Genre matching
    final genres = anime['genres'] as List<dynamic>?;
    if (genres != null) {
      for (final genre in genres) {
        final genreName = genre is Map
            ? genre['name']?.toString()
            : genre.toString();
        if (genreName != null) {
          score += _genreWeights[genreName] ?? 0;
        }
      }
    }

    // Boost for high popularity
    final popularity = anime['popularity'] as num?;
    if (popularity != null) {
      // Lower popularity number = more popular
      score += (10000 - popularity.clamp(0, 10000)) / 5000;
    }

    // Boost for high score
    final animeScore = anime['score'] as num?;
    if (animeScore != null) {
      score += (animeScore - 5) / 2; // Boost for scores above 5
    }

    // Boost for currently airing (fresh content)
    final status = anime['status']?.toString();
    if (status == 'Currently Airing' || status == 'Airing') {
      score += 1.0;
    }

    return score;
  }

  /// Calculate score for an Anime model
  double calculateAnimeScore(Anime anime) {
    double score = 0.0;

    // Skip if already watched
    if (_watchedAnimeIds.contains(anime.animeId)) {
      return -1.0;
    }

    // Genre matching
    final genres = anime.genres.split(',').map((g) => g.trim()).toList();
    for (final genre in genres) {
      score += _genreWeights[genre] ?? 0;
    }

    // Boost for high score
    final animeScore = double.tryParse(anime.score);
    if (animeScore != null) {
      score += (animeScore - 5) / 2;
    }

    // Boost for high popularity
    final popularity = int.tryParse(anime.popularity);
    if (popularity != null) {
      score += (10000 - popularity.clamp(0, 10000)) / 5000;
    }

    // Airing boost
    if (anime.status.contains('Currently') || anime.status.contains('Airing')) {
      score += 1.0;
    }

    return score;
  }

  /// Filter and sort anime list by recommendation score
  List<Map<String, dynamic>> getRecommendations(
    List<Map<String, dynamic>> animeList, {
    int limit = 20,
  }) {
    // Calculate scores
    final scoredList = animeList
        .map((anime) {
          return {'anime': anime, 'recommendationScore': calculateScore(anime)};
        })
        .where((item) => item['recommendationScore'] as double >= 0)
        .toList();

    // Sort by score (descending)
    scoredList.sort((a, b) {
      return (b['recommendationScore'] as double).compareTo(
        a['recommendationScore'] as double,
      );
    });

    // Return top recommendations
    return scoredList
        .take(limit)
        .map((item) => item['anime'] as Map<String, dynamic>)
        .toList();
  }

  /// Filter and sort Anime models by recommendation score
  List<Anime> getAnimeRecommendations(List<Anime> animeList, {int limit = 20}) {
    final scoredList = animeList
        .map((anime) => {'anime': anime, 'score': calculateAnimeScore(anime)})
        .where((item) => (item['score'] as double) >= 0)
        .toList();

    scoredList.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    return scoredList
        .map((item) => item['anime'] as Anime)
        .take(limit)
        .toList();
  }

  /// Get "Because you watched X" recommendations
  Future<List<BecauseYouWatched>> getBecauseYouWatchedRecommendations(
    List<Map<String, dynamic>> allAnime,
  ) async {
    final results = <BecauseYouWatched>[];

    // Get recent watch history
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('continue_watching');
    if (historyJson == null) return results;

    final List<dynamic> history = jsonDecode(historyJson);
    if (history.isEmpty) return results;

    // Take up to 3 recent unique anime
    final recentAnime = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (final item in history) {
      final animeId = item['animeId']?.toString();
      if (animeId != null && !seenIds.contains(animeId)) {
        recentAnime.add(item);
        seenIds.add(animeId);
        if (recentAnime.length >= 3) break;
      }
    }

    // For each recent anime, find similar ones
    for (final watched in recentAnime) {
      final watchedGenres =
          (watched['genres'] as List<dynamic>?)
              ?.map((g) => g.toString())
              .toList() ??
          [];

      if (watchedGenres.isEmpty) continue;

      // Find anime with matching genres
      final similar = allAnime
          .where((anime) {
            final animeId =
                anime['id']?.toString() ?? anime['mal_id']?.toString();
            if (animeId == watched['animeId']?.toString()) return false;
            if (_watchedAnimeIds.contains(animeId)) return false;

            final genres = anime['genres'] as List<dynamic>?;
            if (genres == null) return false;

            final animeGenres = genres
                .map((g) => g is Map ? g['name']?.toString() : g.toString())
                .whereType<String>()
                .toList();

            // Count matching genres
            final matches = watchedGenres
                .where((g) => animeGenres.contains(g))
                .length;
            return matches >= 2; // At least 2 matching genres
          })
          .take(5)
          .toList();

      if (similar.isNotEmpty) {
        results.add(
          BecauseYouWatched(
            watchedAnimeName: watched['animeName']?.toString() ?? 'Unknown',
            recommendations: similar,
          ),
        );
      }
    }

    return results;
  }

  /// Get user's top genres
  List<String> getTopGenres({int limit = 5}) {
    final sortedGenres = _genreWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedGenres.take(limit).map((e) => e.key).toList();
  }

  /// Check if recommendations are available
  bool hasEnoughData() {
    return _favoriteGenres.isNotEmpty || _genreWeights.isNotEmpty;
  }

  /// Clear all data (for logout)
  void clear() {
    _genreWeights.clear();
    _watchedAnimeIds.clear();
    _favoriteGenres.clear();
  }
}

/// Model for "Because you watched X" recommendations
class BecauseYouWatched {
  final String watchedAnimeName;
  final List<Map<String, dynamic>> recommendations;

  BecauseYouWatched({
    required this.watchedAnimeName,
    required this.recommendations,
  });
}
