import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/services/supabase_archive_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../l10n/app_localizations.dart';
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
    _tabController = TabController(length: 7, vsync: this);
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
      final isAuthAdmin =
          user.displayName?.toLowerCase() == 'admin' ||
          user.email == 'admin@animehat.com';

      if (!isNameAdmin && !isAdminFlag && !isAuthAdmin) {
        _closeAccess();
      }
    } catch (e) {
      _closeAccess();
    }
  }

  void _closeAccess() {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accessDenied), backgroundColor: Colors.red),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${l10n.errorPrefix}: $e")));
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

    final l10n = AppLocalizations.of(context)!;
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
                  title: Text(
                    l10n.adminDashboard,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: l10n.stats),
                      Tab(text: l10n.general),
                      Tab(text: l10n.updates),
                      Tab(text: l10n.ads),
                      Tab(text: l10n.featured),
                      Tab(text: l10n.users),
                      Tab(text: l10n.announce),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsTab(isDark, l10n),
                      _buildGeneralTab(isDark, l10n),
                      _buildUpdatesTab(isDark, l10n),
                      _buildAdsTab(isDark, l10n),
                      _buildFeaturedTab(isDark, l10n),
                      _buildUsersTab(isDark, l10n),
                      _buildAnnouncementsTab(isDark, l10n),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsTab(bool isDark, AppLocalizations l10n) {
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
                  l10n.totalUsers,
                  stats['users'].toString(),
                  LucideIcons.users,
                  Colors.blue,
                  isDark,
                ),
                _buildStatCard(
                  l10n.totalPosts,
                  stats['posts'].toString(),
                  LucideIcons.messageSquare,
                  Colors.green,
                  isDark,
                ),
                _buildStatCard(
                  l10n.featured,
                  stats['featured'].toString(),
                  LucideIcons.star,
                  Colors.amber,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDiagnosticsSection(isDark, l10n),
            const SizedBox(height: 24),
            _buildLogSection(isDark, l10n),
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

  Widget _buildLogSection(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.systemLogs,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                await _adminRepo.clearLogs();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.logsCleared)));
                }
              },
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: Text(l10n.clear),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _adminRepo.getSystemLogs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: Text(l10n.noLogsFound));
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
                    '[${log['type']?.toString().toUpperCase()}] ${log['message']}',
                    style: TextStyle(
                      color: _getLogColor(log['type']?.toString() ?? ''),
                      fontSize: 12,
                      fontFamily: 'monospace',
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

  Widget _buildDiagnosticsSection(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.systemDiagnostics,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _runDiagnostics(l10n),
          icon: const Icon(LucideIcons.activity),
          label: Text(l10n.runIntegrityCheck),
        ),
      ],
    );
  }

  Future<void> _runDiagnostics(AppLocalizations l10n) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.runningDiagnostics)));

    int errors = 0;
    // 1. Check Supabase Tables
    final hasServers = await SupabaseArchiveService.checkTableExists('servers');
    final hasAnimes = await SupabaseArchiveService.checkTableExists('animes');
    final hasCharacters = await SupabaseArchiveService.checkTableExists(
      'characters',
    );

    if (!hasServers || !hasAnimes || !hasCharacters) {
      errors++;
      _adminRepo.logSystemEvent(
        message: 'DIAGNOSTICS: Missing Supabase tables detected!',
        type: 'error',
      );
    }

    // 2. Check Firestore Indices (Simplified check)
    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
    } catch (e) {
      if (e.toString().contains('requires an index')) {
        errors++;
        _adminRepo.logSystemEvent(
          message: 'DIAGNOSTICS: Firestore Index missing for announcements!',
          type: 'error',
        );
      }
    }

    if (errors == 0) {
      _adminRepo.logSystemEvent(
        message: 'DIAGNOSTICS: All systems operational.',
        type: 'success',
      );
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.diagnosticsComplete),
          content: Text(
            errors == 0
                ? 'All core systems are operational.'
                : 'Found $errors potential issues. Check system logs for details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGeneralTab(bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAdminSection(
          title: l10n.maintenance,
          isDark: isDark,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(l10n.maintenanceMode),
                value: _settings?.maintenanceMode ?? false,
                onChanged: (val) async {
                  try {
                    await _adminRepo.toggleMaintenanceMode(val);
                    _loadSettings(silent: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Maintenance Mode: ${val ? 'On' : 'Off'}',
                          ),
                          backgroundColor: val ? Colors.orange : Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              TextField(
                controller: _maintenanceMessageController,
                decoration: InputDecoration(
                  labelText: l10n.maintenanceMessage,
                  hintText: 'e.g. App is under maintenance...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _adminRepo.toggleMaintenanceMode(
                        _settings?.maintenanceMode ?? false,
                        message: _maintenanceMessageController.text,
                      );
                      _loadSettings(silent: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Maintenance message updated'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(l10n.updateMessage),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatesTab(bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAdminSection(
          title: l10n.appUpdates,
          isDark: isDark,
          child: Column(
            children: [
              TextField(
                controller: _latestVersionController,
                decoration: InputDecoration(
                  labelText: l10n.latestVersion,
                  hintText: 'e.g. 1.0.5',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minVersionController,
                decoration: InputDecoration(
                  labelText: l10n.minVersion,
                  hintText: 'e.g. 1.0.0',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _updateUrlController,
                decoration: InputDecoration(
                  labelText: l10n.directUpdateUrl,
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _updateNotesController,
                decoration: InputDecoration(
                  labelText: l10n.updateNotes,
                  hintText: 'What\'s new in this version...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(l10n.forceUpdate),
                subtitle: const Text('Users below Min Version will be blocked'),
                value: _settings?.forceUpdate ?? false,
                onChanged: (val) async {
                  try {
                    await _adminRepo.setForceUpdate(
                      latestVersion: _latestVersionController.text,
                      minVersion: _minVersionController.text,
                      updateUrl: _updateUrlController.text,
                      notes: _updateNotesController.text,
                      force: val,
                    );
                    _loadSettings(silent: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Force Update: ${val ? 'ON' : 'OFF'}'),
                          backgroundColor: val ? Colors.red : Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _adminRepo.setForceUpdate(
                        latestVersion: _latestVersionController.text,
                        minVersion: _minVersionController.text,
                        updateUrl: _updateUrlController.text,
                        notes: _updateNotesController.text,
                        force: _settings?.forceUpdate ?? false,
                      );
                      _loadSettings(silent: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Update settings saved successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.save),
                  label: Text(l10n.saveUpdateSettings),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdsTab(bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAdminSection(
          title: l10n.adManagement,
          isDark: isDark,
          child: SwitchListTile(
            title: Text(l10n.showAdsGlobally),
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

  Widget _buildFeaturedTab(bool isDark, AppLocalizations l10n) {
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
                              const Icon(LucideIcons.imageOff),
                        )
                      : const Icon(LucideIcons.image),
                ),
                title: Text(item['title'] ?? 'Title'),
                subtitle: Text('Priority: ${item['priority'] ?? 0}'),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.trash, color: Colors.red),
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

  Widget _buildUsersTab(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: l10n.searchUsers,
              prefixIcon: const Icon(LucideIcons.search),
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
                                title: Text(l10n.activeAccount),
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
                                title: Text(l10n.administrator),
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

  Widget _buildAnnouncementsTab(bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAdminSection(
          title: l10n.newAnnouncement,
          isDark: isDark,
          child: Column(
            children: [
              TextField(
                controller: _announcementTitleController,
                decoration: InputDecoration(labelText: l10n.title),
              ),
              TextField(
                controller: _announcementContentController,
                decoration: InputDecoration(labelText: l10n.content),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _announcementType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  DropdownMenuItem(
                    value: 'info',
                    child: Text(l10n.information),
                  ),
                  DropdownMenuItem(
                    value: 'success',
                    child: Text(l10n.successImportant),
                  ),
                  DropdownMenuItem(
                    value: 'warning',
                    child: Text(l10n.warningMaintenance),
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.announcementBroadcasted)),
                    );
                  }
                },
                child: Text(l10n.broadcast),
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
