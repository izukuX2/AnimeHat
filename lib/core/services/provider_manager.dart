import 'package:flutter/foundation.dart';
import '../extensions/base_provider.dart';
import '../extensions/models/server_model.dart';
import '../extensions/providers/python_api_provider.dart';
import '../extensions/providers/witanime_provider.dart';
import '../models/anime_model.dart';
import '../models/character_model.dart';

/// Singleton service for managing anime providers
class ProviderManager {
  static ProviderManager? _instance;

  final Map<String, BaseProvider> _providers = {};
  String _activeProviderId = 'witanime_python';

  ProviderManager._();

  static ProviderManager get instance {
    _instance ??= ProviderManager._();
    return _instance!;
  }

  /// Initialize and register all built-in providers
  Future<void> initialize() async {
    debugPrint('ProviderManager: Initializing...');

    // Register built-in providers
    registerProvider(WitAnimeProvider());
    registerProvider(PythonApiProvider());

    // TODO: Add more providers here
    // registerProvider(AniWaveProvider());
    // registerProvider(GogoAnimeProvider());

    debugPrint('ProviderManager: Registered ${_providers.length} providers');
  }

  /// Register a provider
  void registerProvider(BaseProvider provider) {
    _providers[provider.id] = provider;
    debugPrint('ProviderManager: Registered ${provider.name} (${provider.id})');
  }

  /// Unregister a provider
  void unregisterProvider(String providerId) {
    _providers.remove(providerId);
  }

  /// Get a specific provider by ID
  BaseProvider? getProvider(String id) => _providers[id];

  /// Get all registered providers
  List<BaseProvider> get allProviders => _providers.values.toList();

  /// Get enabled providers only
  List<BaseProvider> get enabledProviders =>
      _providers.values.where((p) => p.isEnabled).toList();

  /// Get/set active provider ID
  String get activeProviderId => _activeProviderId;
  set activeProviderId(String id) {
    if (_providers.containsKey(id)) {
      _activeProviderId = id;
      debugPrint('ProviderManager: Active provider set to $id');
    }
  }

  /// Get active provider
  BaseProvider? get activeProvider => _providers[_activeProviderId];

  // Convenience methods that delegate to active provider

  Future<HomeData> getHome() async {
    final provider = activeProvider;
    if (provider == null) {
      debugPrint('ProviderManager: No active provider');
      return HomeData(
        latestEpisodes: [],
        broadcast: [],
        premiere: [],
        latestNews: [],
      );
    }
    return provider.getHome();
  }

  Future<List<Anime>> search(String query) async {
    final provider = activeProvider;
    if (provider == null) return [];
    return provider.search(query);
  }

  Future<AnimeDetails> getDetails(String animeId) async {
    final provider = activeProvider;
    if (provider == null) {
      return AnimeDetails(
        plot: '',
        synopsis: '',
        background: '',
        popularity: '',
        members: '',
        favorites: '',
        statistics: AnimeStatistics(userRate: '0', views: '0', rates: {}),
        relatedAnime: [],
      );
    }
    return provider.getDetails(animeId);
  }

  Future<List<Episode>> getEpisodes(String animeId) async {
    final provider = activeProvider;
    if (provider == null) return [];
    return provider.getEpisodes(animeId);
  }

  Future<List<EnhancedServer>> getServers(Episode episode) async {
    final provider = activeProvider;
    if (provider == null) return [];
    return provider.getServers(episode);
  }

  /// Convert enhanced servers to legacy streaming servers
  Future<List<StreamingServer>> getStreamingServers(Episode episode) async {
    final servers = await getServers(episode);
    return servers.map((s) => s.toStreamingServer()).toList();
  }

  Future<List<Anime>> getAnimeList({
    required String type,
    String filterType = '',
    String filterData = '',
    int from = 0,
  }) async {
    final provider = activeProvider;
    if (provider == null) return [];
    return provider.getAnimeList(
      type: type,
      filterType: filterType,
      filterData: filterData,
      from: from,
    );
  }

  Future<List<Character>> getCharacters(String animeId) async {
    final provider = activeProvider;
    if (provider == null) return [];
    return provider.getCharacters(animeId);
  }
}
