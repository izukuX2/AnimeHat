import 'package:anime_hat/core/models/anime_model.dart';
import 'package:anime_hat/core/models/character_model.dart' show Character;

/// Server quality levels
enum ServerQuality {
  unknown,
  sd, // 480p or less
  hd, // 720p
  fhd, // 1080p
  uhd; // 4K

  String get displayName {
    switch (this) {
      case ServerQuality.uhd:
        return '4K';
      case ServerQuality.fhd:
        return 'FHD';
      case ServerQuality.hd:
        return 'HD';
      case ServerQuality.sd:
        return 'SD';
      default:
        return '';
    }
  }

  /// Detect quality from text (server name, etc.)
  static ServerQuality fromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('4k') ||
        lower.contains('uhd') ||
        lower.contains('2160')) {
      return ServerQuality.uhd;
    }
    if (lower.contains('fhd') ||
        lower.contains('1080') ||
        lower.contains('full hd')) {
      return ServerQuality.fhd;
    }
    if (lower.contains('hd') || lower.contains('720')) {
      return ServerQuality.hd;
    }
    if (lower.contains('sd') ||
        lower.contains('480') ||
        lower.contains('360')) {
      return ServerQuality.sd;
    }
    return ServerQuality.unknown;
  }
}

/// Enhanced server model with quality detection
class EnhancedServer {
  final String id;
  final String name;
  final String url;
  final ServerQuality quality;
  final String? embedUrl;
  final Map<String, String>? headers;

  EnhancedServer({
    required this.id,
    required this.name,
    required this.url,
    this.quality = ServerQuality.unknown,
    this.embedUrl,
    this.headers,
  });

  /// Create from raw name with auto quality detection
  factory EnhancedServer.fromRaw({
    required String rawName,
    required String url,
    String? embedUrl,
    Map<String, String>? headers,
  }) {
    final quality = ServerQuality.fromText(rawName);
    final cleanName = _cleanServerName(rawName);

    return EnhancedServer(
      id: url.hashCode.toString(),
      name: cleanName,
      url: url,
      quality: quality,
      embedUrl: embedUrl,
      headers: headers,
    );
  }

  /// Clean server name by removing quality suffixes
  static String _cleanServerName(String raw) {
    return raw
        .replaceAll(
            RegExp(r'\s*-\s*(SD|HD|FHD|4K|UHD|1080p?|720p?|480p?)\s*',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Convert to legacy StreamingServer format
  StreamingServer toStreamingServer() {
    return StreamingServer(
      name: quality != ServerQuality.unknown
          ? '$name (${quality.displayName})'
          : name,
      url: url,
    );
  }
}

/// Abstract base class for all anime providers.
/// Providers are self-contained scrapers for specific anime websites.
abstract class BaseProvider {
  /// Unique provider identifier
  String get id;

  /// Human-readable provider name
  String get name;

  /// Provider base URL
  String get baseUrl;

  /// Provider icon URL
  String get iconUrl;

  /// Provider language code (e.g., 'ar', 'en', 'ja')
  String get language;

  /// Provider version
  String get version;

  /// Whether this provider is enabled
  bool get isEnabled => true;

  /// Whether this provider requires WebView for JS rendering
  bool get requiresWebView => false;

  /// Get home page content (latest episodes, trending, etc.)
  Future<HomeData> getHome();

  /// Search for anime
  Future<List<Anime>> search(String query);

  /// Get anime details (synopsis, genres, etc.)
  Future<AnimeDetails> getDetails(String animeId);

  /// Get episode list for an anime
  Future<List<Episode>> getEpisodes(String animeId);

  /// Get available servers for an episode
  Future<List<EnhancedServer>> getServers(Episode episode);

  /// Extract video URL from a server (optional, for direct playback)
  Future<String?> extractVideoUrl(EnhancedServer server) async => null;

  /// Get anime list by type (latest, movies, seasonal, etc.)
  Future<List<Anime>> getAnimeList({
    required String type,
    String filterType = '',
    String filterData = '',
    int from = 0,
  });

  /// Get characters for an anime (optional)
  Future<List<Character>> getCharacters(String animeId) async => [];

  /// Get recommended anime (optional)
  Future<List<Anime>> getRecommendations(String animeId) async => [];
}
