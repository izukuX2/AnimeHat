import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/services/mal_service.dart';
import '../../../../core/services/anilist_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository();
  final MalService _malService = MalService();
  final AnilistService _anilistService = AnilistService();
  late TabController _tabController;
  AppUser? _cachedUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(
      () => _isLoading = _cachedUser == null,
    ); // Only show spinner if first load
    try {
      final user = await _userRepository.getUser(widget.uid);
      if (user == null &&
          widget.uid == FirebaseAuth.instance.currentUser?.uid) {
        // Only try to sync if we have a network connection
        try {
          final currentUser = FirebaseAuth.instance.currentUser!;
          await _userRepository
              .syncUser(
                currentUser.uid,
                currentUser.email ?? '',
                currentUser.displayName,
                currentUser.photoURL,
              )
              .timeout(const Duration(seconds: 5));
          final newUser = await _userRepository.getUser(widget.uid);
          if (mounted) setState(() => _cachedUser = newUser);
        } catch (e) {
          debugPrint('Sync failed (offline?): $e');
        }
      } else {
        if (mounted) setState(() => _cachedUser = user);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = currentUser?.uid == widget.uid;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cachedUser == null
              ? Center(child: Text(l10n.userNotFound))
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: _buildProfileContent(_cachedUser!, isMe, l10n),
                ),
    );
  }

  Widget _buildProfileContent(AppUser user, bool isMe, AppLocalizations l10n) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Photo
                  user.coverPhotoUrl != null
                      ? AppNetworkImage(
                          path: user.coverPhotoUrl!,
                          category:
                              'banners', // Assuming we might use this bucket or just verify url
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[800]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Profile Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: user.photoUrl != null
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? const Icon(
                                  LucideIcons.user,
                                  size: 40,
                                  color: Colors.white70,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user.bio != null && user.bio!.isNotEmpty)
                                Text(
                                  user.bio!,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (isMe)
                          IconButton(
                            icon: const Icon(
                              LucideIcons.edit3,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _showEditProfileDialog(context, user),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: l10n.overview),
                  Tab(text: l10n.activity),
                ],
              ),
            ),
            pinned: false,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(user, isMe, l10n),
          _buildActivityTab(user, l10n),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AppUser user, bool isMe, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatGrid(user, l10n),
        const SizedBox(height: 24),
        _buildAchievementsSection(
          user,
          l10n,
          Theme.of(context).brightness == Brightness.dark,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.socialLinks,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (user.socialLinks.isEmpty)
          Text(l10n.noSocialLinks, style: const TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            children: user.socialLinks.entries.map((e) {
              return ActionChip(
                avatar: const Icon(LucideIcons.link, size: 16),
                label: Text(e.key),
                onPressed: () {
                  // Open link logic
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        Text(
          DateFormat.yMMMd().format(user.joinDate),
          style: const TextStyle(color: Colors.grey),
        ),
        if (isMe) ...[
          const SizedBox(height: 24),
          const Text(
            "Account Integration",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Image.asset(
                'assets/images/mal_logo.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(LucideIcons.link),
              ),
              title: const Text("MyAnimeList"),
              subtitle: const Text("Sync your watch list automatically"),
              trailing: ElevatedButton(
                onPressed: () => _malService.login(),
                child: const Text("Connect"),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                LucideIcons.externalLink,
                color: Color(0xFF3DB4F2),
              ),
              title: const Text("AniList"),
              subtitle: const Text("Track your anime progress"),
              trailing: ElevatedButton(
                onPressed: () => _anilistService.login(),
                child: const Text("Connect"),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityTab(AppUser user, AppLocalizations l10n) {
    if (user.activityLog.isEmpty) {
      return Center(child: Text(l10n.noRecentActivity));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: user.activityLog.length,
      itemBuilder: (context, index) {
        final activity = user.activityLog[index];
        return ListTile(
          leading: const Icon(LucideIcons.history, color: AppColors.primary),
          title: Text(activity.description),
          subtitle: Text(
            DateFormat.yMMMd().add_jm().format(activity.timestamp),
          ),
        );
      },
    );
  }

  Widget _buildStatGrid(AppUser user, AppLocalizations l10n) {
    int totalEpisodes = user.history.length;
    int totalMinutes = user.history.fold(
      0,
      (sum, item) => sum + (item.positionInMs ~/ 60000),
    );
    int completedAnime =
        user.library.where((e) => e.category == 'Completed').length;
    int watchingAnime =
        user.library.where((e) => e.category == 'Watching').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.animeStats,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _buildStatItem(
              l10n.completed,
              "$completedAnime",
              LucideIcons.checkCircle,
              Colors.green,
            ),
            _buildStatItem(
              l10n.watching,
              "$watchingAnime",
              LucideIcons.playCircle,
              Colors.blue,
            ),
            _buildStatItem(
              l10n.episodes,
              "$totalEpisodes",
              LucideIcons.layers,
              Colors.orange,
            ),
            _buildStatItem(
              l10n.time,
              "${(totalMinutes / 60).toStringAsFixed(1)}h",
              LucideIcons.clock,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
    AppUser user,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final badges = _calculateBadges(user);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _buildBadgeItem(badges[index], isDark),
          ),
        ),
      ],
    );
  }

  List<_Badge> _calculateBadges(AppUser user) {
    final badges = <_Badge>[];

    // Member since
    final days = DateTime.now().difference(user.joinDate).inDays;
    if (days >= 365) {
      badges.add(
        const _Badge('Veteran', '🎉', 'Member for over a year', Colors.amber),
      );
    } else if (days >= 30) {
      badges.add(
        const _Badge('Regular', '📅', 'Member for over a month', Colors.blue),
      );
    }

    // Episode count
    if (user.history.length >= 1000) {
      badges.add(
        const _Badge('God-tier', '👑', 'Watched 1000+ episodes', Colors.purple),
      );
    } else if (user.history.length >= 100) {
      badges.add(
        const _Badge('Otaku', '🍱', 'Watched 100+ episodes', Colors.orange),
      );
    }

    // Completionist
    final completed =
        user.library.where((e) => e.category == 'Completed').length;
    if (completed >= 50) {
      badges.add(
        const _Badge('Elite', '🏆', 'Completed 50+ animes', Colors.red),
      );
    }

    // Diverse tastes (just a placeholder logic)
    if (user.favorites.length >= 10) {
      badges.add(
        const _Badge('Connoisseur', '💎', '10+ favorites added', Colors.cyan),
      );
    }

    return badges;
  }

  Widget _buildBadgeItem(_Badge badge, bool isDark) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: badge.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            badge.name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
    );
  }
}

class _Badge {
  final String name;
  final String emoji;
  final String description;
  final Color color;
  const _Badge(this.name, this.emoji, this.description, this.color);
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
