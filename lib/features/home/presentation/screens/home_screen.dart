import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../../../core/services/recommendation_service.dart';

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
  late Future<List<Anime>> _recommendationsFuture;
  late Future<List<BecauseYouWatched>> _becauseYouWatchedFuture;
  late Future<AppConfiguration> _configFuture;
  final _authRepository = AuthRepository();
  final _syncRepository = SyncRepository();
  final _adminRepository = AdminRepository();
  int _currentIndex = 0;
  bool _showSyncProgress = true;
  bool _isDevMode = false;
  Stream<AppUser?>? _userStream;

  // Category definitions
  List<_CategoryItem> _getCategories(AppLocalizations l10n) => [
    _CategoryItem(
      LucideIcons.compass,
      l10n.explore,
      0,
      const Color(0xFF007AFF),
    ),
    _CategoryItem(
      LucideIcons.playCircle,
      l10n.episodes,
      1,
      const Color(0xFFFF9500),
    ),
    _CategoryItem(LucideIcons.tv, l10n.series, 2, const Color(0xFF34C759)),
    _CategoryItem(LucideIcons.film, l10n.movies, 3, const Color(0xFFAF52DE)),
    _CategoryItem(LucideIcons.search, l10n.search, 4, const Color(0xFFFF3B30)),
    _CategoryItem(
      LucideIcons.users,
      l10n.characters,
      5,
      const Color(0xFF5856D6),
    ),
    _CategoryItem(
      LucideIcons.bookmark,
      l10n.library,
      6,
      const Color(0xFFFF2D55),
    ),
    _CategoryItem(
      LucideIcons.messageSquare,
      l10n.community,
      7,
      const Color(0xFF007AFF),
    ),
    _CategoryItem(
      LucideIcons.history,
      l10n.history,
      8,
      const Color(0xFFFF9500),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _repository = HomeRepository(apiClient: AnimeifyApiClient());
    _refreshData();
    _ensureUserExists();
    _initUserStream();
    _loadDevMode();
    RecommendationService().initialize();
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
      _fetchRecommendations();
    });
  }

  Future<void> _fetchRecommendations() async {
    final rs = RecommendationService();
    // We need all anime to filter from
    final homeData = await _homeDataFuture;
    final allAnime = <Anime>[
      ...homeData.broadcast,
      ...homeData.premiere,
      ...homeData.latestEpisodes.map((e) => e.anime),
    ];

    // Remove duplicates
    final seenIds = <String>{};
    final uniqueAnime = allAnime.where((a) => seenIds.add(a.animeId)).toList();

    _recommendationsFuture = Future.value(
      rs.getAnimeRecommendations(uniqueAnime),
    );

    // For "Because you watched", it needs Map<String, dynamic>
    final maps = uniqueAnime.map((a) => a.toMap()).toList();
    _becauseYouWatchedFuture = rs.getBecauseYouWatchedRecommendations(maps);
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
            _buildSyncProgressBar(isDark, l10n),
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
    final categories = _getCategories(l10n);
    if (_currentIndex > 0 && _currentIndex < categories.length) {
      title = categories[_currentIndex].label;
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
                  l10n.appTitle,
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
            LucideIcons.settings,
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
          // Admin Announcements
          SliverToBoxAdapter(child: _buildAdminAnnouncements(isDark)),

          // Quick Categories
          SliverToBoxAdapter(child: _buildQuickCategories(isDark, l10n)),

          // Admin Featured section
          SliverToBoxAdapter(child: _buildAdminFeatured(isDark)),

          // Trending Carousel
          SliverToBoxAdapter(
            child: FutureBuilder<List<TrendingItem>>(
              future: _trendingItemsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(height: 20);
                }
                return _buildTrendingCarousel(snapshot.data!, isDark, l10n);
              },
            ),
          ),

          // Content sections
          FutureBuilder<HomeData>(
            future: _homeDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(child: _buildShimmerLoading(isDark));
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return SliverFillRemaining(child: _buildOfflineView(isDark));
              }

              final homeData = snapshot.data!;
              return SliverList(
                delegate: SliverChildListDelegate([
                  // Continue Watching
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildContinueWatching(isDark, l10n),
                  ),

                  // Latest Episodes Grid
                  if (homeData.latestEpisodes.isNotEmpty)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: _buildAnimeGridSection(
                        title: '🔥 ${l10n.latestEpisodes}',
                        items: homeData.latestEpisodes.take(6).toList(),
                        isDark: isDark,
                        seeAllLabel: l10n.seeAll,
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
                    ),

                  // AI Recommendations
                  FutureBuilder<List<Anime>>(
                    future: _recommendationsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return FadeInWidget(
                        delay: const Duration(milliseconds: 300),
                        child: _buildAnimeGridSection(
                          title: '✨ Recommended For You',
                          items: snapshot.data!.take(6).toList(),
                          isDark: isDark,
                          itemBuilder: (item) => AnimeCard(
                            title: item.enTitle,
                            imageUrl: item.thumbnail,
                            isCompact: true,
                            rating: double.tryParse(item.score),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/anime-details',
                              arguments: item,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Because You Watched
                  FutureBuilder<List<BecauseYouWatched>>(
                    future: _becauseYouWatchedFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return FadeInWidget(
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          children: snapshot.data!.map((group) {
                            return _buildAnimeGridSection(
                              title:
                                  '💙 Because you watched ${group.watchedAnimeName}',
                              items: group.recommendations
                                  .take(3)
                                  .map((m) => Anime.fromJson(m))
                                  .toList(),
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
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  // Broadcast Schedule
                  if (homeData.broadcast.isNotEmpty)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 500),
                      child: _buildAnimeGridSection(
                        title: '📅 ${l10n.broadcastSchedule}',
                        items: homeData.broadcast.take(6).toList(),
                        isDark: isDark,
                        seeAllLabel: l10n.seeAll,
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
                    ),

                  // Latest News
                  if (homeData.latestNews.isNotEmpty)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 600),
                      child: _buildNewsSection(
                        homeData.latestNews,
                        isDark,
                        l10n,
                      ),
                    ),

                  // Current Season
                  if (homeData.premiere.isNotEmpty)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 700),
                      child: _buildAnimeGridSection(
                        title: '🌸 ${l10n.currentSeason}',
                        items: homeData.premiere.take(6).toList(),
                        isDark: isDark,
                        seeAllLabel: l10n.seeAll,
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

  Widget _buildQuickCategories(bool isDark, AppLocalizations l10n) {
    // Check for modern theme specifically
    final isModern = Theme.of(context).primaryColor == const Color(0xFF00D1FF);
    final categories = _getCategories(l10n);

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
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

  Widget _buildTrendingCarousel(
    List<TrendingItem> items,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            '✨ ${l10n.popularAnime}',
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
    String? seeAllLabel,
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
                    seeAllLabel ?? 'See All',
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

  Widget _buildNewsSection(
    List<NewsItem> news,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            '📰 ${l10n.latestNews}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 190,
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

  Widget _buildContinueWatching(bool isDark, AppLocalizations l10n) {
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
                    LucideIcons.playCircle,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.continueWatching,
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
                                  LucideIcons.play,
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
    final categories = _getCategories(l10n);

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: isMinimal ? const RoundedRectangleBorder() : null,
      child: SafeArea(
        child: Column(
          children: [
            // User header
            _buildDrawerHeader(context, isDark, isMinimal, l10n),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                children: [
                  _buildDrawerSectionTitle(isDark, l10n.myAccount),
                  _buildDrawerItem(
                    icon: LucideIcons.user,
                    label: l10n.username,
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
                    icon: LucideIcons.history,
                    label: l10n.history,
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
                  _buildDrawerSectionTitle(isDark, l10n.explore),
                  for (int i = 0; i <= 5; i++)
                    _buildDrawerItem(
                      icon: categories[i].icon,
                      label: categories[i].label,
                      color: categories[i].color,
                      isSelected: _currentIndex == i,
                      isDark: isDark,
                      borderRadius: borderRadius,
                      onTap: () {
                        setState(() => _currentIndex = i);
                        Navigator.pop(context);
                      },
                    ),

                  const SizedBox(height: 20),
                  _buildDrawerSectionTitle(isDark, l10n.myLibrary),
                  _buildDrawerItem(
                    icon: LucideIcons.bookmark,
                    label: l10n.library,
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
                    icon: LucideIcons.messageSquare,
                    label: l10n.community,
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
                  _buildDrawerSectionTitle(isDark, l10n.explore.toUpperCase()),
                  _buildDrawerItem(
                    icon: LucideIcons.calendar,
                    label: l10n.broadcastSchedule,
                    color: Colors.teal,
                    isSelected: false,
                    isDark: isDark,
                    borderRadius: borderRadius,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/schedule');
                    },
                  ),
                  if (_isDevMode)
                    _buildDrawerItem(
                      icon: LucideIcons.shieldCheck,
                      label: l10n.adminDashboard,
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
                    icon: LucideIcons.settings,
                    label: l10n.settings,
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
                    icon: LucideIcons.logOut,
                    label: l10n.logout,
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

  Widget _buildDrawerHeader(
    BuildContext context,
    bool isDark,
    bool isMinimal,
    AppLocalizations l10n,
  ) {
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
                    ? const Icon(
                        LucideIcons.user,
                        color: Colors.white,
                        size: 36,
                      )
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
                l10n.signInOrCreateAccount,
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

  Widget _buildSyncProgressBar(bool isDark, AppLocalizations l10n) {
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
                  '${l10n.syncUserProfile}: ${progress.currentCategory}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
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

  Widget _buildShimmerLoading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Continue Watching shimmer
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: ShimmerLoading(width: 180, height: 24, borderRadius: 8),
          ),
          const ShimmerCarousel(height: 180),

          const SizedBox(height: 32),

          // Latest Episodes shimmer
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: ShimmerLoading(width: 200, height: 24, borderRadius: 8),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return FadeInWidget(
                delay: Duration(milliseconds: index * 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ShimmerLoading(borderRadius: 12)),
                    const SizedBox(height: 8),
                    ShimmerLoading.text(width: double.infinity, height: 12),
                    const SizedBox(height: 4),
                    ShimmerLoading.text(width: 60, height: 10),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Broadcast Schedule shimmer
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: ShimmerLoading(width: 220, height: 24, borderRadius: 8),
          ),
          const ShimmerCarousel(height: 180, itemCount: 4),
        ],
      ),
    );
  }

  Widget _buildOfflineView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.wifiOff,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          const Text(
            'You are offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAnnouncements(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminRepository.getAnnouncements(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        final ann = snapshot.data!;
        return Column(
          children: ann.map((a) {
            Color bgColor = Colors.blue;
            IconData icon = LucideIcons.info;

            if (a['type'] == 'warning') {
              bgColor = Colors.orange;
              icon = LucideIcons.alertTriangle;
            } else if (a['type'] == 'success') {
              bgColor = Colors.green;
              icon = LucideIcons.checkCircle;
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bgColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: bgColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          a['content'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAdminFeatured(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminRepository.getFeaturedAnime(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        final featured = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '⭐ Admin\'s Choice',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: featured.length,
                itemBuilder: (context, index) {
                  final item = featured[index];
                  return GestureDetector(
                    onTap: () async {
                      final anime = await _repository.getAnimeById(
                        item['animeId'],
                      );
                      if (context.mounted) {
                        Navigator.pushNamed(
                          context,
                          '/anime-details',
                          arguments: anime,
                        );
                      }
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppNetworkImage(
                                path: item['imageUrl'],
                                category: 'featured',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final int index;
  final Color color;

  const _CategoryItem(this.icon, this.label, this.index, this.color);
}
