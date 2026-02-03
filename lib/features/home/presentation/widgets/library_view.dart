import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/home_repository.dart';
import '../widgets/anime_card.dart';

class LibraryView extends StatefulWidget {
  final HomeRepository repository;

  const LibraryView({super.key, required this.repository});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _searchQuery = "";
  String _sortBy = 'addedAt'; // 'addedAt', 'title'

  void _setSearchQuery(String query) {
    setState(() => _searchQuery = query.toLowerCase());
  }

  void _setSortBy(String? sort) {
    if (sort != null) setState(() => _sortBy = sort);
  }

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
          key: ValueKey(allCategories.length),
          child: Column(
            children: [
              _buildHeader(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: _setSearchQuery,
              decoration: InputDecoration(
                hintText: "Search library...",
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox(),
            icon: const Icon(LucideIcons.listFilter, size: 20),
            items: const [
              DropdownMenuItem(value: 'addedAt', child: Text("Date")),
              DropdownMenuItem(value: 'title', child: Text("Name")),
            ],
            onChanged: _setSortBy,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    String category,
    List<LibraryEntry> library,
  ) {
    var items = library.where((e) => e.category == category).toList();

    // Sorting logic (Note: requires anime title which we fetch later in FutureBuilder)
    // For sorting by title, we might need to pre-fetch or handle it differently.
    // Let's sort by addedAt for now.
    if (_sortBy == 'addedAt') {
      items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }

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
        return FutureBuilder<Anime>(
          future: widget.repository.getAnimeById(entry.animeId),
          builder: (context, animeSnapshot) {
            if (!animeSnapshot.hasData) {
              return _buildLoadingCard();
            }
            final anime = animeSnapshot.data!;

            // Search Filtering
            if (_searchQuery.isNotEmpty &&
                !anime.enTitle.toLowerCase().contains(_searchQuery)) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: [
                AnimeCard(
                  title: anime.enTitle,
                  imageUrl: anime.thumbnail,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/anime-details',
                    arguments: anime,
                  ),
                ),
                // Quick Update Button for 'Watching'
                if (category == 'Watching')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildQuickUpdateIcon(anime),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickUpdateIcon(Anime anime) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        onPressed: () => _updateProgress(anime),
      ),
    );
  }

  void _updateProgress(Anime anime) {
    // In a real app, this would increment the 'watchedEpisodes' field in the LibraryEntry
    // Since our LibraryEntry doesn't have it yet, this is a placeholder for the logic.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Updated progress for ${anime.enTitle} (Stub)")),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
