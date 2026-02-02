import 'package:flutter/material.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/ad_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminRepository _adminRepo = AdminRepository();
  GlobalSettings? _settings;
  bool _isLoading = true;

  final TextEditingController _latestVersionController =
      TextEditingController();
  final TextEditingController _minVersionController = TextEditingController();
  final TextEditingController _updateUrlController = TextEditingController();
  final TextEditingController _updateNotesController = TextEditingController();
  final TextEditingController _maintenanceMessageController =
      TextEditingController();
  final TextEditingController _announcementTitleController =
      TextEditingController();
  final TextEditingController _announcementContentController =
      TextEditingController();
  String _announcementType = 'info';
  final TextEditingController _userSearchController = TextEditingController();
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _verifyAdminAccess();
    _loadSettings();
  }

  Future<void> _verifyAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _closeAccess();
      return;
    }

    try {
      final appUser = await UserRepository().getUser(
        user.uid,
        forceRefresh: true,
      );
      final isNameAdmin = appUser?.displayName.toLowerCase() == 'admin';
      final isAdminFlag = appUser?.isAdmin ?? false;

      if (!isNameAdmin && !isAdminFlag) {
        _closeAccess();
      }
    } catch (e) {
      _closeAccess();
    }
  }

  void _closeAccess() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access Denied: You do not have permission to view this page.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadSettings({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final settings = await _adminRepo.getGlobalSettings();
      setState(() {
        _settings = settings;
        _latestVersionController.text = settings.latestVersion;
        _minVersionController.text = settings.minVersion;
        _updateUrlController.text = settings.updateUrl;
        _updateNotesController.text = settings.updateNotes;
        _maintenanceMessageController.text = settings.maintenanceMessage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latestVersionController.dispose();
    _minVersionController.dispose();
    _updateUrlController.dispose();
    _updateNotesController.dispose();
    _maintenanceMessageController.dispose();
    _announcementTitleController.dispose();
    _announcementContentController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 80,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDark ? Colors.black : Colors.white,
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  centerTitle: true,
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Stats'),
                      Tab(text: 'General'),
                      Tab(text: 'Ads'),
                      Tab(text: 'Featured'),
                      Tab(text: 'Users'),
                      Tab(text: 'Announce'),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsTab(isDark),
                      _buildGeneralTab(isDark),
                      _buildAdsTab(isDark),
                      _buildFeaturedTab(isDark),
                      _buildUsersTab(isDark),
                      _buildAnnouncementsTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsTab(bool isDark) {
    return FutureBuilder<Map<String, int>>(
      future: _adminRepo.getAppStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data ?? {'users': 0, 'posts': 0, 'featured': 0};
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Users',
                  stats['users'].toString(),
                  Icons.people,
                  Colors.blue,
                  isDark,
                ),
                _buildStatCard(
                  'Total Posts',
                  stats['posts'].toString(),
                  Icons.forum,
                  Colors.green,
                  isDark,
                ),
                _buildStatCard(
                  'Featured',
                  stats['featured'].toString(),
                  Icons.star,
                  Colors.amber,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLogSection(isDark),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLogSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'System Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                await _adminRepo.clearLogs();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Logs cleared')));
              },
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _adminRepo.getSystemLogs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: Text('No logs found'));
            final logs = snapshot.data!;
            return Container(
              height: 300,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Text(
                    '[${log['type']}] ${log['message']}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGeneralTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAdminSection(
          title: 'Maintenance',
          isDark: isDark,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Maintenance Mode'),
                value: _settings?.maintenanceMode ?? false,
                onChanged: (val) async {
                  await _adminRepo.toggleMaintenanceMode(val);
                  _loadSettings(silent: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Maintenance Mode: ${val ? 'On' : 'Off'}',
                        ),
                      ),
                    );
                  }
                },
              ),
              TextField(
                controller: _maintenanceMessageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await _adminRepo.toggleMaintenanceMode(
                    _settings?.maintenanceMode ?? false,
                    message: _maintenanceMessageController.text,
                  );
                  _loadSettings(silent: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maintenance message updated'),
                      ),
                    );
                  }
                },
                child: const Text('Update Message'),
              ),
            ],
          ),
        ),
        _buildAdminSection(
          title: 'App Updates',
          isDark: isDark,
          child: Column(
            children: [
              TextField(
                controller: _latestVersionController,
                decoration: const InputDecoration(labelText: 'Latest Version'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minVersionController,
                decoration: const InputDecoration(labelText: 'Min Version'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _updateUrlController,
                decoration: const InputDecoration(labelText: 'Update URL'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Force Update'),
                value: _settings?.forceUpdate ?? false,
                onChanged: (val) async {
                  await _adminRepo.setForceUpdate(
                    latestVersion: _latestVersionController.text,
                    minVersion: _minVersionController.text,
                    updateUrl: _updateUrlController.text,
                    force: val,
                  );
                  _loadSettings(silent: true);
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await _adminRepo.setForceUpdate(
                    latestVersion: _latestVersionController.text,
                    minVersion: _minVersionController.text,
                    updateUrl: _updateUrlController.text,
                    force: _settings?.forceUpdate ?? false,
                  );
                  _loadSettings(silent: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update settings saved')),
                    );
                  }
                },
                child: const Text('Save Update Settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAdminSection(
          title: 'Ad Management',
          isDark: isDark,
          child: SwitchListTile(
            title: const Text('Show Ads Globally'),
            subtitle: const Text('Toggling this affects all users'),
            value: _settings?.adsEnabled ?? true,
            onChanged: (val) async {
              await _adminRepo.toggleAds(val);
              AdService.updateAdsEnabled(val);
              _loadSettings(silent: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ads ${val ? 'Enabled' : 'Disabled'} Globally',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedTab(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminRepo.getFeaturedAnime(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No featured anime found'));
        }
        final featured = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: featured.length,
          itemBuilder: (context, index) {
            final item = featured[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item['imageUrl'] != null
                      ? Image.network(
                          item['imageUrl'],
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        )
                      : const Icon(Icons.image),
                ),
                title: Text(item['title'] ?? 'Title'),
                subtitle: Text('Priority: ${item['priority'] ?? 0}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await _adminRepo.removeFeaturedAnime(item['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from featured')),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _userSearchQuery = val.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _adminRepo.getAllUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              var users = snapshot.data!;
              if (_userSearchQuery.isNotEmpty) {
                users = users.where((u) {
                  final name = (u['displayName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final email = (u['email'] ?? '').toString().toLowerCase();
                  return name.contains(_userSearchQuery) ||
                      email.contains(_userSearchQuery);
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final bool isAdmin = user['isAdmin'] ?? false;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundImage: user['photoUrl'] != null
                            ? NetworkImage(user['photoUrl'])
                            : null,
                      ),
                      title: Text(user['displayName'] ?? 'User'),
                      subtitle: Text(user['email'] ?? 'No email'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Active Account'),
                                subtitle: const Text('Toggle to ban/unban'),
                                value: !(user['isBanned'] ?? false),
                                onChanged: (val) async {
                                  await _adminRepo.setUserBanned(
                                    user['id'],
                                    !val,
                                  );
                                  setState(() {});
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Administrator'),
                                subtitle: const Text('Grant admin privileges'),
                                value: isAdmin,
                                activeColor: AppColors.primary,
                                onChanged: (val) async {
                                  await _adminRepo.toggleAdminStatus(
                                    user['id'],
                                    val,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'User ${val ? 'Promoted to Admin' : 'Demoted from Admin'}',
                                        ),
                                      ),
                                    );
                                  }
                                  setState(() {});
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAdminSection(
          title: 'New Announcement',
          isDark: isDark,
          child: Column(
            children: [
              TextField(
                controller: _announcementTitleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _announcementContentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _announcementType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('Information')),
                  DropdownMenuItem(
                    value: 'success',
                    child: Text('Success/Important'),
                  ),
                  DropdownMenuItem(
                    value: 'warning',
                    child: Text('Warning/Maintenance'),
                  ),
                ],
                onChanged: (val) => setState(() => _announcementType = val!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _adminRepo.broadcastNews(
                    title: _announcementTitleController.text,
                    content: _announcementContentController.text,
                    type: _announcementType,
                  );
                  _announcementTitleController.clear();
                  _announcementContentController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement Broadcasted')),
                  );
                },
                child: const Text('Broadcast'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
