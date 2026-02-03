import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../data/anime_repository.dart';
import '../../../../core/theme/accent_colors.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/services/share_service.dart';
import 'dart:ui';

class AnimeDetailsScreen extends StatefulWidget {
  final Anime anime;

  const AnimeDetailsScreen({super.key, required this.anime});

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimeRepository _repository;
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _auth = AuthRepository();
  late Future<AnimeDetails> _detailsFuture;
  late Future<List<Episode>> _episodesFuture;
  late AccentPreset _accent;
  bool _isFavorite = false;
  bool _isInLibrary = false;
  int? _userRating;
  late AnimationController _pulseController;

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
    _accent = AccentColors.getByGenre(widget.anime.genres);
    _checkInitialStatus();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginToFavorite)));
      return;
    }

    setState(() => _isFavorite = !_isFavorite);
    await _userRepository.toggleFavorite(user.uid, widget.anime.animeId);
  }

  Future<void> _toggleLibrary() async {
    final user = _auth.currentUser;
    if (user == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginToLibrary)));
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
    final l10n = AppLocalizations.of(context)!;

    final defaultCategories = [
      l10n.watching,
      l10n.completed,
      'Plan to Watch', // Need to add this to ARB if wanted, but keeping for now or I can add it
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
              Text(
                l10n.selectCategory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                      leading: const Icon(LucideIcons.plus),
                      title: Text(l10n.createNewCategory),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.newCategory),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.categoryName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final category = controller.text.trim();
                if (category.isNotEmpty) {
                  await _userRepository.addCustomCategory(uid, category);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showLibraryCategoryPicker(uid);
                  }
                }
              },
              child: Text(l10n.create),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog() {
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginToRate)));
      return;
    }

    double tempRating = (_userRating ?? 5).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.rateThisAnime),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${tempRating.toInt()} ${l10n.stars}",
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
                  child: Text(l10n.cancel),
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
                  child: Text(l10n.rate),
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: ThemeManager.instance.buildTheme(
        isDark ? AppThemeType.modern : AppThemeType.classic,
        locale: Localizations.localeOf(context),
        accentOverride: _accent,
      ),
      child: Builder(
        builder: (context) {
          final themedIsDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                _buildAppBar(themedIsDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainInfo(themedIsDark),
                        const SizedBox(height: 16),
                        _buildEnrichedStats(themedIsDark, l10n),
                        const SizedBox(height: 24),
                        _buildWatchButton(themedIsDark, l10n),
                        const SizedBox(height: 24),
                        _buildSectionTitle(l10n.information),
                        const SizedBox(height: 12),
                        _buildDetailedInfo(themedIsDark, l10n),
                        const SizedBox(height: 24),
                        _buildSectionTitle(l10n.plot),
                        const SizedBox(height: 12),
                        _buildPlot(themedIsDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchButton(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
          ),
          child: SizedBox(
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
              icon: const Icon(LucideIcons.playCircle, size: 28),
              label: Text(
                l10n.viewEpisodes,
                style: const TextStyle(fontSize: 18, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              _isFavorite ? LucideIcons.heart : LucideIcons.heart,
              _isFavorite ? l10n.favorited : l10n.favorite,
              _isFavorite ? Colors.red : (isDark ? Colors.white : Colors.black),
              _toggleFavorite,
              isDark,
            ),
            _buildActionButton(
              _isInLibrary ? LucideIcons.checkSquare : LucideIcons.plusSquare,
              _isInLibrary ? l10n.inLibrary : l10n.library,
              _isInLibrary
                  ? AppColors.primary
                  : (isDark ? Colors.white : Colors.black),
              _toggleLibrary,
              isDark,
            ),
            _buildActionButton(
              LucideIcons.star,
              _userRating != null ? "Rated: $_userRating" : l10n.rate,
              Colors.amber,
              _showRatingDialog,
              isDark,
            ),
            _buildActionButton(
              LucideIcons.messageSquare,
              l10n.comments,
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

  Widget _buildDetailedInfo(bool isDark, AppLocalizations l10n) {
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
            LucideIcons.info,
            l10n.status,
            widget.anime.status,
            isDark,
            l10n,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            LucideIcons.tag,
            l10n.type,
            widget.anime.type,
            isDark,
            l10n,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            LucideIcons.clock,
            l10n.duration,
            "${widget.anime.duration} min",
            isDark,
            l10n,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            LucideIcons.calendar,
            l10n.released,
            widget.anime.premiered,
            isDark,
            l10n,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            LucideIcons.layers,
            l10n.episodes,
            widget.anime.episodes,
            isDark,
            l10n,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            LucideIcons.sun,
            l10n.season,
            (widget.anime.season == '0' || widget.anime.season.isEmpty)
                ? widget.anime.premiered
                : "${l10n.season} ${widget.anime.season}",
            isDark,
            l10n,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            LucideIcons.building,
            l10n.studio,
            widget.anime.creators,
            isDark,
            l10n,
          ),
          _buildDivider(isDark),
          _buildInfoRow(
            LucideIcons.userCheck,
            l10n.rating,
            widget.anime.rating,
            isDark,
            l10n,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
    AppLocalizations l10n,
  ) {
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
            (value.isEmpty || value == '0') ? l10n.unknown : value,
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

  Widget _buildEnrichedStats(bool isDark, AppLocalizations l10n) {
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
              l10n.popularity,
              "#${details.popularity}",
              LucideIcons.trendingUp,
              Colors.orange,
              isDark,
            ),
            _buildStatChip(
              l10n.members,
              details.members,
              LucideIcons.users,
              Colors.green,
              isDark,
            ),
            _buildStatChip(
              l10n.favorites,
              details.favorites,
              LucideIcons.heart,
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
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.chevronLeft,
            color: Colors.white,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: ShareButton(
            onShare: () => ShareService().shareAnime(
              animeId: widget.anime.animeId,
              title: widget.anime.enTitle,
              imageUrl: widget.anime.thumbnail,
              synopsis: widget.anime.synonyms,
            ),
            onCopyLink: () => ShareService().copyLink(
              context: context,
              url: 'https://animehat.app/anime/${widget.anime.animeId}',
            ),
            iconColor: Colors.white,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Blur/Tint
            Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  path: imagePath,
                  category: 'thumbnails',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                // Glassy Overlay
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withOpacity(0.4),
                    ),
                  ),
                ),
                // Gradient for visibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
            // Floating Poster
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Hero(
                  tag: 'anime_poster_${widget.anime.animeId}',
                  child: Container(
                    height: 180,
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                LucideIcons.star,
                isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildBadge(widget.anime.status, LucideIcons.info, Colors.grey),
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
