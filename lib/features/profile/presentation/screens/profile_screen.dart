import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';

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
          print('Sync failed (offline?): $e');
        }
      } else {
        if (mounted) setState(() => _cachedUser = user);
      }
    } catch (e) {
      print('Error loading user: $e');
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

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cachedUser == null
          ? const Center(child: Text("User not found"))
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: _buildProfileContent(_cachedUser!, isMe),
            ),
    );
  }

  Widget _buildProfileContent(AppUser user, bool isMe) {
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
                          Colors.black.withOpacity(0.7),
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
                                  Icons.person,
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
                            icon: const Icon(Icons.edit, color: Colors.white),
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
                tabs: const [
                  Tab(text: "Overview"),
                  Tab(text: "Activity"),
                ],
              ),
            ),
            pinned: false,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(user), _buildActivityTab(user)],
      ),
    );
  }

  Widget _buildOverviewTab(AppUser user) {
    // Calculate stats
    int totalEpisodes = user.history.length;
    int totalMinutes = user.history.fold(
      0,
      (sum, item) => sum + (item.positionInMs ~/ 60000),
    );
    // Approximate, since we don't have exact duration for completed items if not in history fully,
    // but relying on history item properties.
    // Actually, history stores progress. Only finished items are 100%.
    // A better metric might be completed entries in library.

    int completedAnime = user.library
        .where((e) => e.category == 'Completed')
        .length;
    int watchingAnime = user.library
        .where((e) => e.category == 'Watching')
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard("Anime Stats", [
          _StatItem("Completed", "$completedAnime"),
          _StatItem("Watching", "$watchingAnime"),
          _StatItem("Episodes", "$totalEpisodes"),
          _StatItem("Time", "${(totalMinutes / 60).toStringAsFixed(1)}h"),
        ]),
        const SizedBox(height: 16),
        const Text(
          "Social Links",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (user.socialLinks.isEmpty)
          const Text(
            "No social links added.",
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            children: user.socialLinks.entries.map((e) {
              return ActionChip(
                avatar: const Icon(Icons.link, size: 16),
                label: Text(e.key),
                onPressed: () {
                  // Open link logic
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        const Text(
          "Joined",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          DateFormat.yMMMd().format(user.joinDate),
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActivityTab(AppUser user) {
    if (user.activityLog.isEmpty) {
      return const Center(child: Text("No recent activity"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: user.activityLog.length,
      itemBuilder: (context, index) {
        final activity = user.activityLog[index];
        return ListTile(
          leading: const Icon(Icons.history, color: AppColors.primary),
          title: Text(activity.description),
          subtitle: Text(
            DateFormat.yMMMd().add_jm().format(activity.timestamp),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, List<_StatItem> items) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                return Column(
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      item.label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
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

class _StatItem {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);
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
