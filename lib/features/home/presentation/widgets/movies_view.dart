import 'package:flutter/material.dart';
import '../../../../core/models/anime_model.dart';
import '../widgets/anime_card.dart';

class MoviesView extends StatelessWidget {
  final Future<List<Anime>> moviesFuture;
  final VoidCallback onRefresh;

  const MoviesView({
    super.key,
    required this.moviesFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<Anime>>(
        future: moviesFuture,
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
                    'Error loading movies',
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
                    Icons.movie_outlined,
                    size: 48,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No movies found',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          final movies = snapshot.data!;

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
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final anime = movies[index];
              return AnimeCard(
                title: anime.enTitle,
                imageUrl: anime.thumbnail,
                isCompact: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/anime-details',
                    arguments: anime,
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
