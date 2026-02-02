import 'package:flutter/material.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../data/anime_repository.dart';

class AnimeDetailsScreen extends StatefulWidget {
  final Anime anime;

  const AnimeDetailsScreen({super.key, required this.anime});

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  late final AnimeRepository _repository;
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _auth = AuthRepository();
  late Future<AnimeDetails> _detailsFuture;
  late Future<List<Episode>> _episodesFuture;
  bool _isFavorite = false;
  bool _isInLibrary = false;
  int? _userRating;

  @override
  void initState() {
    super.initState();
    _repository = AnimeRepository(apiClient: AnimeifyApiClient());
    _detailsFuture = _repository.getAnimeDetails(
      widget.anime.animeId,
      malId: widget.anime.malId,
      animeMetadata: widget.anime,
    );
    _episodesFuture = _repository.getEpisodes(widget.anime.animeId);
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final appUser = await _userRepository.getUser(user.uid);
      if (appUser != null && mounted) {
        setState(() {
          _isFavorite = appUser.favorites.contains(widget.anime.animeId);
          _isInLibrary = appUser.library.any(
            (e) => e.animeId == widget.anime.animeId,
          );
          _userRating = appUser.ratings[widget.anime.animeId];
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add to favorites")),
      );
      return;
    }

    setState(() => _isFavorite = !_isFavorite);
    await _userRepository.toggleFavorite(user.uid, widget.anime.animeId);
  }

  Future<void> _toggleLibrary() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add to library")),
      );
      return;
    }

    if (_isInLibrary) {
      await _userRepository.updateLibraryCategory(
        user.uid,
        widget.anime.animeId,
        'Remove',
      );
    } else {
      _showLibraryCategoryPicker(user.uid);
    }
    _checkInitialStatus();
  }

  void _showLibraryCategoryPicker(String uid) async {
    final user = await _userRepository.getUser(uid);
    if (user == null) return;

    final defaultCategories = [
      'Watching',
      'Completed',
      'Plan to Watch',
      'Dropped',
    ];
    final customCategories = user.customLibraryCategories;
    final allCategories = [...defaultCategories, ...customCategories];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...allCategories.map(
                      (cat) => ListTile(
                        title: Text(cat),
                        onTap: () async {
                          await _userRepository.updateLibraryCategory(
                            uid,
                            widget.anime.animeId,
                            cat,
                          );
                          if (context.mounted) Navigator.pop(context);
                          _checkInitialStatus();
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text("Create New Category"),
                      onTap: () async {
                        Navigator.pop(context);
                        _showCreateCategoryDialog(uid);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateCategoryDialog(String uid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Category"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Category Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final category = controller.text.trim();
                if (category.isNotEmpty) {
                  await _userRepository.addCustomCategory(uid, category);
                  // Optionally modify the library entry right away or just add category
                  if (context.mounted) {
                    Navigator.pop(context);
                    // Re-open picker to let user select it
                    _showLibraryCategoryPicker(uid);
                  }
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog() {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login to rate")));
      return;
    }

    double tempRating = (_userRating ?? 5).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Rate this Anime"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${tempRating.toInt()} Stars",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempRating,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: Colors.amber,
                    onChanged: (value) {
                      setDialogState(() => tempRating = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    final rating = tempRating.toInt();
                    await _userRepository.updateRating(
                      user.uid,
                      widget.anime.animeId,
                      rating,
                    );
                    if (mounted) {
                      setState(() => _userRating = rating);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Rate"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(isDark),
                  const SizedBox(height: 16),
                  _buildEnrichedStats(isDark),
                  const SizedBox(height: 24),
                  _buildWatchButton(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Information"),
                  const SizedBox(height: 12),
                  _buildDetailedInfo(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Plot"),
                  const SizedBox(height: 12),
                  _buildPlot(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchButton(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final episodes = await _episodesFuture;
              if (mounted) {
                Navigator.pushNamed(
                  context,
                  '/episodes',
                  arguments: {'anime': widget.anime, 'episodes': episodes},
                );
              }
            },
            icon: const Icon(Icons.play_circle_fill, size: 28),
            label: const Text(
              "VIEW EPISODES",
              style: TextStyle(fontSize: 18, letterSpacing: 1.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkPrimary
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 2,
                ),
              ),
              elevation: 8,
              shadowColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              _isFavorite ? "Favorited" : "Favorite",
              _isFavorite ? Colors.red : (isDark ? Colors.white : Colors.black),
              _toggleFavorite,
              isDark,
            ),
            _buildActionButton(
              _isInLibrary
                  ? Icons.library_add_check
                  : Icons.library_add_outlined,
              _isInLibrary ? "In Library" : "Library",
              _isInLibrary
                  ? AppColors.primary
                  : (isDark ? Colors.white : Colors.black),
              _toggleLibrary,
              isDark,
            ),
            _buildActionButton(
              Icons.star_outline,
              _userRating != null ? "Rated: $_userRating" : "Rate",
              Colors.amber,
              _showRatingDialog,
              isDark,
            ),
            _buildActionButton(
              Icons.comment_rounded,
              "Comments",
              Colors.pinkAccent,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityScreen(
                      animeId: widget.anime.animeId,
                      animeTitle: widget.anime.enTitle,
                    ),
                  ),
                );
              },
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(
          isDark ? 0.3 : 0.05,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.info_outline,
            "Status",
            widget.anime.status,
            isDark,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            Icons.category_outlined,
            "Type",
            widget.anime.type,
            isDark,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            Icons.timer_outlined,
            "Duration",
            "${widget.anime.duration} min",
            isDark,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            "Released",
            widget.anime.premiered,
            isDark,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            Icons.layers_outlined,
            "Episodes",
            widget.anime.episodes,
            isDark,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            Icons.wb_sunny_outlined,
            "Season",
            (widget.anime.season == '0' || widget.anime.season.isEmpty)
                ? widget.anime.premiered
                : "Season ${widget.anime.season}",
            isDark,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            Icons.business_outlined,
            "Studio",
            widget.anime.creators,
            isDark,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            Icons.accessibility_new_outlined,
            "Rating",
            widget.anime.rating,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkSecondary : AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            (value.isEmpty || value == '0') ? "Unknown" : value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      color: (isDark ? AppColors.darkBorder : AppColors.border).withOpacity(
        0.5,
      ),
      thickness: 1,
    );
  }

  Widget _buildEnrichedStats(bool isDark) {
    return FutureBuilder<AnimeDetails>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final details = snapshot.data!;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatChip(
              "Popularity",
              "#${details.popularity}",
              Icons.trending_up,
              Colors.orange,
              isDark,
            ),
            _buildStatChip(
              "Members",
              details.members,
              Icons.people_outline,
              Colors.green,
              isDark,
            ),
            _buildStatChip(
              "Favorites",
              details.favorites,
              Icons.favorite_border,
              Colors.red,
              isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.5,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    final imagePath = widget.anime.thumbnail;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withOpacity(0.9),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16),
        background: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.4,
                      child: AppNetworkImage(
                        path: imagePath,
                        category: 'thumbnails',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withOpacity(0.1),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Hero(
                    tag: 'anime-${widget.anime.animeId}',
                    child: Container(
                      height: 180,
                      width: 125,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AppNetworkImage(
                          path: imagePath,
                          category: 'thumbnails',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(
          isDark ? 0.3 : 0.05,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.anime.enTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge(
                widget.anime.score,
                Icons.star_rounded,
                isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildBadge(
                widget.anime.status,
                Icons.info_outline_rounded,
                Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.anime.genres,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPlot(bool isDark) {
    return FutureBuilder<AnimeDetails>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text("Error loading plot: ${snapshot.error}");
        }
        final plot = snapshot.data?.plot ?? "No plot available";

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(
              isDark ? 0.3 : 0.05,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            plot,
            style: TextStyle(
              fontSize: 15,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.8),
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        );
      },
    );
  }
}
