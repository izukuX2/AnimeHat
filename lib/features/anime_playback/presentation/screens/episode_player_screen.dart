import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/link_resolver.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/repositories/anime_firestore_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../anime_details/data/anime_repository.dart';
import 'video_player_screen.dart';

class EpisodePlayerScreen extends StatefulWidget {
  final Anime anime;
  final Episode episode;
  final int startAtMs;
  final List<Episode> episodes;

  // Helper to parse quality from server name or URL
  static String? _extractResolution(String input) {
    final regex = RegExp(
      r'(360|480|720|1080|1440|4k|2k)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(input);
    if (match != null) {
      String quality = match.group(0)!.toUpperCase();
      if (!quality.contains('P') && !quality.contains('K')) {
        quality += 'p';
      }
      return quality;
    }
    return null;
  }

  static String parseQuality(StreamingServer server) {
    final name = server.name;
    final url = server.url;

    String? fromName = _extractResolution(name);
    if (fromName != null) return fromName;

    String? fromUrl = _extractResolution(url);
    if (fromUrl != null) return fromUrl;

    if (name.toLowerCase().contains('fullhd') ||
        name.toLowerCase().contains('fhd'))
      return '1080p';
    if (name.toLowerCase().contains('hd')) return '720p';
    if (name.toLowerCase().contains('sd')) return '480p';

    // Fallback: If name text is short (likely a quality like "360p"), use it.
    // Otherwise if it's "mp4upload" etc, return "High Speed".
    if (name.length < 6) return name;
    return "Auto (${name})"; // Keeping as is or could use l10n.auto but this is static
  }

  const EpisodePlayerScreen({
    super.key,
    required this.anime,
    required this.episode,
    this.startAtMs = 0,
    required this.episodes,
  });

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  late final AnimeRepository _repository;
  final UserRepository _userRepository = UserRepository();
  final AnimeFirestoreRepository _animeFirestore = AnimeFirestoreRepository();
  final AuthRepository _authRepository = AuthRepository();
  late Future<List<StreamingServer>> _serversFuture;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _repository = AnimeRepository(apiClient: AnimeifyApiClient());
    _serversFuture = _repository.getServers(
      widget.anime.animeId,
      widget.episode.episodeNumber,
    );
  }

  // Auto-resolve removed in favor of manual selection

  Future<void> _launchInternalPlayer(
    String urlString,
    String serverName,
    List<StreamingServer> availableServers,
  ) async {
    setState(() => _isResolving = true);

    try {
      final resolvedUrl = await LinkResolver.resolve(urlString);

      if (mounted) {
        // Save to History first
        _saveToHistory();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: resolvedUrl,
              title:
                  '${widget.anime.enTitle} - Ep ${widget.episode.episodeNumber}',
              anime: widget.anime,
              episode: widget.episode,
              startAtMs: widget.startAtMs,
              episodes: widget.episodes,
              servers: availableServers, // Passing all servers now
              currentServerName: serverName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Link resolution failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.failedToResolveLink)));
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  void _saveToHistory() {
    final user = _authRepository.currentUser;
    if (user != null && widget.anime.animeId.isNotEmpty) {
      _animeFirestore.saveAnime(widget.anime);
      _userRepository.addToHistory(
        user.uid,
        WatchHistoryItem(
          animeId: widget.anime.animeId,
          episodeNumber: widget.episode.episodeNumber,
          watchedAt: DateTime.now(),
          title: widget.anime.enTitle,
          imageUrl: widget.anime.thumbnail,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.anime.enTitle} - ${l10n.epShort} ${widget.episode.episodeNumber}',
        ),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<StreamingServer>>(
            future: _serversFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildErrorState(
                  snapshot.error?.toString(),
                  isDark,
                  l10n,
                );
              }

              final servers = snapshot.data!;
              // Show ALL servers, but parse quality smartly
              final availableServers = servers;

              if (availableServers.isEmpty) {
                return _buildErrorState(l10n.noServersAvailable, isDark, l10n);
              }

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.selectQuality,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: availableServers.map((server) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              backgroundColor: isDark
                                  ? AppColors.darkCardBg
                                  : Colors.white,
                              foregroundColor: isDark
                                  ? Colors.white
                                  : Colors.black,
                              side: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => _launchInternalPlayer(
                              server.url,
                              server.name,
                              availableServers,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  EpisodePlayerScreen.parseQuality(server),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (server.quality.isNotEmpty)
                                  Text(
                                    server.quality,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isResolving) _buildResolvingOverlay(l10n),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error, bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 64,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            Text(
              error ?? l10n.mediaUnavailable,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _serversFuture = _repository.getServers(
                  widget.anime.animeId,
                  widget.episode.episodeNumber,
                );
              }),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvingOverlay(AppLocalizations l10n) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.blueAccent),
                const SizedBox(height: 24),
                Text(
                  l10n.startingPlayer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.resolvingLink,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
