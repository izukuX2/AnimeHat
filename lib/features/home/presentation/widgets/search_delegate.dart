import 'package:flutter/material.dart';
import '../../../../core/models/anime_model.dart';
import '../../data/home_repository.dart';
import 'anime_card.dart';

class AnimeSearchDelegate extends SearchDelegate {
  final HomeRepository repository;

  AnimeSearchDelegate(this.repository);

  @override
  String get searchFieldLabel => 'Search Anime...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters'));
    }

    return FutureBuilder<List<Anime>>(
      future: repository.searchAnime(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final anime = results[index];
            return AnimeCard(
              title: anime.enTitle,
              imageUrl:
                  'https://animeify.net/animeify/files/thumbnails/${anime.thumbnail}',
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
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Icon(Icons.search, size: 64, color: Colors.grey),
    );
  }
}
