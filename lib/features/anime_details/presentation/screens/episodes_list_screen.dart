import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../auth/data/auth_repository.dart';

class EpisodesListScreen extends StatefulWidget {
  final Anime anime;
  final List<Episode> episodes;

  const EpisodesListScreen({
    super.key,
    required this.anime,
    required this.episodes,
  });

  @override
  State<EpisodesListScreen> createState() => _EpisodesListScreenState();
}

class _EpisodesListScreenState extends State<EpisodesListScreen> {
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _auth = AuthRepository();
  static const int _pageSize = 50;
  int _currentPage = 0;
  late List<List<Episode>> _paginatedEpisodes;
  late List<Episode> _sortedEpisodes;

  @override
  void initState() {
    super.initState();
    // Sort episodes numerically
    _sortedEpisodes = List<Episode>.from(widget.episodes)
      ..sort((a, b) {
        final numA = double.tryParse(a.episodeNumber) ?? 0;
        final numB = double.tryParse(b.episodeNumber) ?? 0;
        return numA.compareTo(numB);
      });
    // Paginate episodes
    _paginatedEpisodes = [];
    for (var i = 0; i < _sortedEpisodes.length; i += _pageSize) {
      final end = (i + _pageSize < _sortedEpisodes.length)
          ? i + _pageSize
          : _sortedEpisodes.length;
      _paginatedEpisodes.add(_sortedEpisodes.sublist(i, end));
    }
  }

  String _getRangeLabel(int pageIndex) {
    final start = pageIndex * _pageSize + 1;
    final end = (pageIndex + 1) * _pageSize;
    final actualEnd =
        end > widget.episodes.length ? widget.episodes.length : end;
    return '$start - $actualEnd';
  }

  Future<void> _playEpisode(Episode ep) async {
    final user = _auth.currentUser;
    int startAtMs = 0;

    if (user != null) {
      final appUser = await _userRepository.getUser(user.uid);
      if (appUser != null) {
        final historyItem = appUser.history.any(
          (e) =>
              e.animeId == widget.anime.animeId &&
              e.episodeNumber == ep.episodeNumber,
        )
            ? appUser.history.firstWhere(
                (e) =>
                    e.animeId == widget.anime.animeId &&
                    e.episodeNumber == ep.episodeNumber,
              )
            : null;

        if (historyItem != null && historyItem.positionInMs > 5000) {
          if (mounted) {
            final resume = await showDialog<bool>(
              context: context,
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return AlertDialog(
                  title: Text(l10n.resumePlaying),
                  content: Text(
                    l10n.resumePrompt(
                      Duration(
                        milliseconds: historyItem.positionInMs,
                      ).toString().split('.').first,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.startOver),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.resume),
                    ),
                  ],
                );
              },
            );
            if (resume == true) {
              startAtMs = historyItem.positionInMs;
            }
          }
        }
      }
    }

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/episode-player',
        arguments: {
          'anime': widget.anime,
          'episode': ep,
          'startAtMs': startAtMs,
          'episodes': widget.episodes,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentEpisodes = _paginatedEpisodes.isNotEmpty
        ? _paginatedEpisodes[_currentPage]
        : <Episode>[];

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.anime.enTitle} - ${l10n.episodes}'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Range selector for long series
          if (_paginatedEpisodes.length > 1)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _paginatedEpisodes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _currentPage;
                  return GestureDetector(
                    onTap: () => setState(() => _currentPage = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary)
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getRangeLabel(index),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Episodes list
          Expanded(
            child: currentEpisodes.isEmpty
                ? Center(child: Text(l10n.noEpisodesFound))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: currentEpisodes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ep = currentEpisodes[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withOpacity(isDark ? 0.2 : 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            "${l10n.episodePrefix}${ep.episodeNumber}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => _playEpisode(ep),
                              icon: const Icon(
                                LucideIcons.play,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          onTap: () => _playEpisode(ep),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
