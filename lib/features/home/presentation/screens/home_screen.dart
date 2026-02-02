import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../data/home_repository.dart';
import '../widgets/anime_card.dart';
import '../widgets/movies_view.dart';
import '../widgets/episodes_view.dart';
import '../widgets/search_view.dart';
import '../widgets/news_card.dart';
import '../widgets/series_view.dart';
import '../widgets/characters_view.dart';
import '../widgets/library_view.dart';
import '../widgets/community_view.dart';
import '../widgets/history_view.dart';
import '../../../auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/repositories/sync_repository.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final HomeRepository _repository;
  final UserRepository _userRepository = UserRepository();
  late Future<HomeData> _homeDataFuture;
  late Future<List<TrendingItem>> _trendingItemsFuture;
  late Future<List<Anime>> _moviesFuture;
  late Future<AppConfiguration> _configFuture;
  final _authRepository = AuthRepository();
  final _syncRepository = SyncRepository();
  int _currentIndex = 0;
  bool _showSyncProgress = true;
  bool _isDevMode = false;
  Stream<AppUser?>? _userStream;

  // Category definitions
  final List<_CategoryItem> _categories = [
    _CategoryItem(Icons.explore_rounded, 'Explore', 0, const Color(0xFF007AFF)),
    _CategoryItem(
      Icons.play_circle_filled_rounded,
      'Episodes',
      1,
      const Color(0xFFFF9500),
    ),
    _CategoryItem(Icons.tv_rounded, 'Series', 2, const Color(0xFF34C759)),
    _CategoryItem(Icons.movie_rounded, 'Movies', 3, const Color(0xFFAF52DE)),
    _CategoryItem(Icons.search_rounded, 'Search', 4, const Color(0xFFFF3B30)),
    _CategoryItem(
      Icons.people_rounded,
      'Characters',
      5,
      const Color(0xFF5856D6),
    ),
    _CategoryItem(
      Icons.bookmark_rounded,
      'Library',
      6,
      const Color(0xFFFF2D55),
    ),
    _CategoryItem(Icons.forum_rounded, 'Community', 7, const Color(0xFF007AFF)),
    _CategoryItem(Icons.history_rounded, 'History', 8, const Color(0xFFFF9500)),
  ];

  @override
  void initState() {
    super.initState();
    _repository = HomeRepository(apiClient: AnimeifyApiClient());
    _refreshData();
    _ensureUserExists();
    _initUserStream();
    _loadDevMode();
  }

  Future<void> _loadDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDevMode = prefs.getBool('dev_mode_enabled') ?? false;
    });
  }

  void _initUserStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userStream = _userRepository.getUserStream(uid);
    }
  }

  Future<void> _ensureUserExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userRepository.syncUser(
        user.uid,
        user.email ?? '',
        user.displayName,
        user.photoURL,
      );
    }
  }

  void _refreshData() {
    setState(() {
      _homeDataFuture = _repository.getHomeData();
      _trendingItemsFuture = _repository.getTrendingItems();
      _moviesFuture = _repository.getMovies();
      _configFuture = _repository.getConfiguration();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
        appBar: _buildAppBar(isDark, l10n),
        drawer: _buildDrawer(context, isDark, l10n),
        body: Column(
          children: [
            _buildSyncProgressBar(isDark),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeView(isDark, l10n),
                  FutureBuilder<HomeData>(
                    future: _homeDataFuture,
                    builder: (context, snapshot) {
                      return EpisodesView(
                        episodesFuture: Future.value(
                          snapshot.data?.latestEpisodes ?? [],
                        ),
                        onRefresh: _refreshData,
                      );
                    },
                  ),
                  SeriesView(repository: _repository, onRefresh: _refreshData),
                  MoviesView(
                    moviesFuture: _moviesFuture,
                    onRefresh: _refreshData,
                  ),
                  SearchView(
                    repository: _repository,
                    configFuture: _configFuture,
                  ),
                  CharactersView(
                    repository: _repository,
                    onRefresh: _refreshData,
                  ),
                  LibraryView(repository: _repository),
                  const CommunityView(),
                  HistoryView(),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, AppLocalizations l10n) {
    String title = '';
    if (_currentIndex > 0 && _currentIndex < _categories.length) {
      title = _categories[_currentIndex].label;
    }

    return AppBar(
      backgroundColor: isDark ? Colors.black : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: _currentIndex == 0
          ? Row(
              children: [
                Image.asset(
                  'assets/images/logo_no_bg.png',
                  height: 32,
                  color: isDark ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  'AnimeHat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildHomeView(bool isDark, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Quick Categories
          SliverToBoxAdapter(child: _buildQuickCategories(isDark)),

          // Trending Carousel
          SliverToBoxAdapter(
            child: FutureBuilder<List<TrendingItem>>(
              future: _trendingItemsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(height: 20);
                }
                return _buildTrendingCarousel(snapshot.data!, isDark);
              },
            ),
          ),

          // Content sections
          FutureBuilder<HomeData>(
            future: _homeDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return SliverFillRemaining(child: _buildOfflineView(isDark));
              }

              final homeData = snapshot.data!;
              return SliverList(
                delegate: SliverChildListDelegate([
                  // Continue Watching
                  _buildContinueWatching(isDark),

                  // Latest Episodes Grid
                  if (homeData.latestEpisodes.isNotEmpty)
                    _buildAnimeGridSection(
                      title: '🔥 Latest Episodes',
                      items: homeData.latestEpisodes.take(6).toList(),
                      isDark: isDark,
                      onSeeAll: () => setState(() => _currentIndex = 1),
                      itemBuilder: (item) => AnimeCard(
                        title: item.anime.enTitle,
                        subtitle: item.anime.jpTitle,
                        imageUrl: item.anime.thumbnail,
                        episodeBadge: 'EP ${item.episode.episodeNumber}',
                        rating: double.tryParse(item.anime.rating),
                        isCompact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/anime-details',
                          arguments: item.anime,
                        ),
                      ),
                    ),

                  // Broadcast Schedule
                  if (homeData.broadcast.isNotEmpty)
                    _buildAnimeGridSection(
                      title: '📅 Broadcast Schedule',
                      items: homeData.broadcast.take(6).toList(),
                      isDark: isDark,
                      itemBuilder: (item) => AnimeCard(
                        title: item.enTitle,
                        imageUrl: item.thumbnail,
                        isCompact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/anime-details',
                          arguments: item,
                        ),
                      ),
                    ),

                  // Latest News
                  if (homeData.latestNews.isNotEmpty)
                    _buildNewsSection(homeData.latestNews, isDark),

                  // Current Season
                  if (homeData.premiere.isNotEmpty)
                    _buildAnimeGridSection(
                      title: '🌸 Current Season',
                      items: homeData.premiere.take(6).toList(),
                      isDark: isDark,
                      itemBuilder: (item) => AnimeCard(
                        title: item.enTitle,
                        imageUrl: item.thumbnail,
                        isCompact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/anime-details',
                          arguments: item,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategories(bool isDark) {
    // Check for modern theme specifically
    final isModern = Theme.of(context).primaryColor == const Color(0xFF00D1FF);

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _currentIndex == index;

          if (isModern) {
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = index),
              child: Container(
                width: 85,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? category.color
                        : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1)),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected
                          ? category.color
                          : (isDark ? Colors.white54 : Colors.black54),
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? category.color
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            child: Container(
              width: 72,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color
                          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? category.color.withOpacity(0.4)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      category.icon,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : category.color),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? category.color
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingCarousel(List<TrendingItem> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            '✨ Trending Now',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.92),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  if (item.anime != null) {
                    Navigator.pushNamed(
                      context,
                      '/anime-details',
                      arguments: item.anime,
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          path: item.photo,
                          category: 'sliders',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.type == 'EPISODE' &&
                                  item.episode != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'EP ${item.episode!.episodeNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeGridSection<T>({
    required String title,
    required List<T> items,
    required bool isDark,
    required Widget Function(T) itemBuilder,
    VoidCallback? onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection(List<NewsItem> news, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            '📰 Latest News',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: news.length > 5 ? 5 : news.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 280,
                child: NewsCard(news: news[index], onTap: () {}),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueWatching(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<AppUser?>(
      future: _userRepository.getUser(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.history.isEmpty) {
          return const SizedBox.shrink();
        }

        final history = snapshot.data!.history
          ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
        final displayHistory = history.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Continue Watching',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayHistory.length,
                itemBuilder: (context, index) {
                  final item = displayHistory[index];
                  final progress = item.totalDurationInMs > 0
                      ? item.positionInMs / item.totalDurationInMs
                      : 0.0;

                  return GestureDetector(
                    onTap: () async {
                      final anime = await _repository.getAnimeById(
                        item.animeId,
                      );
                      final episodes = await _repository.getEpisodes(
                        item.animeId,
                      );
                      final episode = episodes.firstWhere(
                        (e) => e.episodeNumber == item.episodeNumber,
                        orElse: () => episodes.first,
                      );
                      if (context.mounted) {
                        Navigator.pushNamed(
                          context,
                          '/episode-player',
                          arguments: {
                            'anime': anime,
                            'episode': episode,
                            'episodes': episodes,
                          },
                        );
                      }
                    },
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(
                              path: item.imageUrl,
                              category: 'thumbnails',
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.9),
                                  ],
                                ),
                              ),
                            ),
                            // Play button overlay
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      0,
                                      10,
                                      6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Episode ${item.episodeNumber}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppColors.primary,
                                    ),
                                    minHeight: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final shape = Theme.of(context).cardTheme.shape as RoundedRectangleBorder?;
    final borderRadius = shape?.borderRadius ?? BorderRadius.circular(12);
    final isMinimal = borderRadius == BorderRadius.zero;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: isMinimal ? const RoundedRectangleBorder() : null,
      child: SafeArea(
        child: Column(
          children: [
            // User header
            _buildDrawerHeader(context, isDark, isMinimal),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                children: [
                  _buildDrawerSectionTitle(isDark, 'MY ACCOUNT'),
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    color: AppColors.primary,
                    isSelected: false,
                    isDark: isDark,
                    borderRadius: borderRadius,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    color: Colors.orange,
                    isSelected: _currentIndex == 8,
                    isDark: isDark,
                    borderRadius: borderRadius,
                    onTap: () {
                      setState(() => _currentIndex = 8);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 20),
                  _buildDrawerSectionTitle(isDark, 'EXPLORE'),
                  for (int i = 0; i <= 5; i++)
                    _buildDrawerItem(
                      icon: _categories[i].icon,
                      label: _categories[i].label,
                      color: _categories[i].color,
                      isSelected: _currentIndex == i,
                      isDark: isDark,
                      borderRadius: borderRadius,
                      onTap: () {
                        setState(() => _currentIndex = i);
                        Navigator.pop(context);
                      },
                    ),

                  const SizedBox(height: 20),
                  _buildDrawerSectionTitle(isDark, 'MY LIBRARY'),
                  _buildDrawerItem(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Library',
                    color: Colors.pink,
                    isSelected: _currentIndex == 6,
                    isDark: isDark,
                    borderRadius: borderRadius,
                    onTap: () {
                      setState(() => _currentIndex = 6);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.forum_outlined,
                    label: 'Community',
                    color: Colors.blue,
                    isSelected: _currentIndex == 7,
                    isDark: isDark,
                    borderRadius: borderRadius,
                    onTap: () {
                      setState(() => _currentIndex = 7);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 20),
                  _buildDrawerSectionTitle(isDark, 'SETTINGS'),
                  if (_isDevMode)
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin Dashboard',
                      color: Colors.red,
                      isSelected: false,
                      isDark: isDark,
                      borderRadius: borderRadius,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin');
                      },
                    ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'App Settings',
                    color: Colors.grey,
                    isSelected: false,
                    isDark: isDark,
                    borderRadius: borderRadius,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: Colors.redAccent,
                    isSelected: false,
                    isDark: isDark,
                    borderRadius: borderRadius,
                    onTap: () async {
                      await _authRepository.logout();
                      if (mounted)
                        Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, bool isDark, bool isMinimal) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<AppUser?>(
        stream: _userStream,
        builder: (context, snapshot) {
          final appUser = snapshot.data;
          final photoUrl =
              appUser?.photoUrl ?? FirebaseAuth.instance.currentUser?.photoURL;
          final displayName =
              appUser?.displayName ??
              FirebaseAuth.instance.currentUser?.displayName ??
              "Guest";

          return Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: isMinimal ? BoxShape.rectangle : BoxShape.circle,
                  image: photoUrl != null && photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null || photoUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 36)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign In/Create Account',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerSectionTitle(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required BorderRadiusGeometry borderRadius,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius as BorderRadius?,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white70 : Colors.black54),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? color
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncProgressBar(bool isDark) {
    return StreamBuilder<SyncProgress>(
      stream: _syncRepository.syncProgress,
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data!.isComplete ||
            !_showSyncProgress) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.primary.withOpacity(0.1),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Syncing: ${progress.currentCategory}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _showSyncProgress = false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'You are offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection or try again later',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final int index;
  final Color color;

  const _CategoryItem(this.icon, this.label, this.index, this.color);
}
