import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/home_repository.dart';
import '../widgets/anime_card.dart';

class LibraryView extends StatelessWidget {
  final HomeRepository repository;

  const LibraryView({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please login to see your library"));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Error loading library"));
        }

        final appUser = AppUser.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
        );
        final defaultCategories = [
          'Watching',
          'Completed',
          'Plan to Watch',
          'Dropped',
        ];
        final customCategories = appUser.customLibraryCategories;
        final allCategories = [...defaultCategories, ...customCategories];

        return DefaultTabController(
          length: allCategories.length,
          key: ValueKey(allCategories.length), // Recreate if count changes
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: allCategories.map((cat) => Tab(text: cat)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: allCategories
                      .map(
                        (cat) =>
                            _buildCategoryList(context, cat, appUser.library),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    String category,
    List<LibraryEntry> library,
  ) {
    final items = library.where((e) => e.category == category).toList();

    if (items.isEmpty) {
      return Center(child: Text("No anime in '$category' yet."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        // Fetch Anime details
        // Note: Ideally we should cache or batch this.
        return FutureBuilder<Anime>(
          future: repository.getAnimeById(entry.animeId),
          builder: (context, animeSnapshot) {
            if (!animeSnapshot.hasData) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final anime = animeSnapshot.data!;
            return AnimeCard(
              title: anime.enTitle,
              imageUrl: anime.thumbnail,
              onTap: () => Navigator.pushNamed(
                context,
                '/anime-details',
                arguments: anime,
              ),
            );
          },
        );
      },
    );
  }
}
