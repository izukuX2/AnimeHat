import 'package:flutter/material.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import 'anime_card.dart';

class EpisodesView extends StatelessWidget {
  final Future<List<AnimeWithEpisode>> episodesFuture;
  final VoidCallback onRefresh;

  const EpisodesView({
    super.key,
    required this.episodesFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<AnimeWithEpisode>>(
        future: episodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading episodes',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 48,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No episodes found',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimeCard(
                title: item.anime.enTitle,
                subtitle: 'EP ${item.episode.episodeNumber}',
                imageUrl: item.anime.thumbnail,
                isCompact: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/anime-details',
                    arguments: item.anime,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
