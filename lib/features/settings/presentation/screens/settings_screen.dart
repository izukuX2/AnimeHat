import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/theme/accent_colors.dart';
import '../../../../core/models/sync_settings.dart';
import '../../../../core/repositories/sync_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../widgets/theme_selector_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/backup_service.dart';
import '../../../home/data/home_repository.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final Locale currentLocale;
  final Function(Locale) onLocaleChange;
  final AppThemeType currentTheme;
  final Function(AppThemeType) onThemeChange;
  final String? currentAccentName;
  final Function(String?) onAccentChange;
  final SyncSettings syncSettings;
  final Function(SyncSettings) onSyncSettingsChange;

  const SettingsScreen({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
    required this.currentTheme,
    required this.onThemeChange,
    this.currentAccentName,
    required this.onAccentChange,
    required this.syncSettings,
    required this.onSyncSettingsChange,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<bool> _adminFuture;
  int _devTapCount = 0;
  bool _isDevMode = false;

  @override
  void initState() {
    super.initState();
    _adminFuture = _checkIsAdmin();
    _loadDevMode();
  }

  Future<void> _loadDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDevMode = prefs.getBool('dev_mode_enabled') ?? false;
    });
  }

  Future<void> _toggleDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDevMode = !_isDevMode;
      prefs.setBool('dev_mode_enabled', _isDevMode);
    });
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDevMode ? l10n.welcomeBack : 'Developer Mode Disabled',
          ),
          backgroundColor: _isDevMode ? Colors.green : Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use theme brightness from current theme config
    final config = ThemeManager.themes[widget.currentTheme]!;
    final isDark = config.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            context,
            l10n.darkMode,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    l10n.darkMode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) {
                    // Toggle between default light (Classic) and default dark (Midnight)
                    widget.onThemeChange(
                      value ? AppThemeType.midnight : AppThemeType.classic,
                    );
                  },
                  secondary: Icon(
                    isDark ? LucideIcons.moon : LucideIcons.sun,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    LucideIcons.palette,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                  title: Text(
                    l10n.appTheme,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.customizeAppearance,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    _showThemeSelector(context, isDark);
                  },
                ),
                if (widget.currentAccentName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 70, bottom: 12),
                    child: Row(
                      children: [
                        const Text(
                          'Active Accent:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AccentColors.getByName(
                                  widget.currentAccentName!,
                                )?.primary.withOpacity(0.1) ??
                                Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  AccentColors.getByName(
                                    widget.currentAccentName!,
                                  )?.primary.withOpacity(0.3) ??
                                  Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '${AccentColors.getByName(widget.currentAccentName!)?.emoji ?? ''} ${widget.currentAccentName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AccentColors.getByName(
                                widget.currentAccentName!,
                              )?.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Language Selection
          _buildSection(
            context,
            l10n.language,
            child: Column(
              children: [
                _buildLanguageOption(
                  context,
                  l10n.english,
                  const Locale('en'),
                  widget.currentLocale,
                  widget.onLocaleChange,
                ),
                const Divider(height: 1),
                _buildLanguageOption(
                  context,
                  l10n.arabic,
                  const Locale('ar'),
                  widget.currentLocale,
                  widget.onLocaleChange,
                ),
                const Divider(height: 1),
                _buildLanguageOption(
                  context,
                  l10n.french,
                  const Locale('fr'),
                  widget.currentLocale,
                  widget.onLocaleChange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /*
          _buildSection(
            context,
            'Ad Settings',
            child: StatefulBuilder(
              builder: (context, setState) {
                return SwitchListTile(
                  title: const Text(
                    'Show Ads',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Support the developer by enabling ads',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: AdService.adsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) async {
                    await AdService.updateAdsEnabled(value);
                    setState(() {});
                  },
                  secondary: const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.amber,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          */
          _buildSection(
            context,
            l10n.backgroundSync,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    l10n.autoUpload,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.updateLibraryBackground,
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: widget.syncSettings.isEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) {
                    widget.onSyncSettingsChange(
                      widget.syncSettings.copyWith(isEnabled: value),
                    );
                  },
                  secondary: Icon(
                    LucideIcons.cloud,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                if (widget.syncSettings.isEnabled) ...[
                  const Divider(indent: 70),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(70, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.syncSpeed,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: SyncSpeed.values.map((speed) {
                            final isSelected =
                                widget.syncSettings.speed == speed;
                            return ChoiceChip(
                              label: Text(speed.label),
                              selected: isSelected,
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  widget.onSyncSettingsChange(
                                    widget.syncSettings.copyWith(speed: speed),
                                  );
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(indent: 70),
                ListTile(
                  leading: const Icon(
                    LucideIcons.refreshCw,
                    color: Colors.orange,
                  ),
                  title: Text(
                    l10n.manualFullSync,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.forceUpdateLibrary,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      SyncRepository().startIncrementalSync(force: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Starting manual synchronization...'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.start),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.archive, color: Colors.green),
                  title: Text(
                    l10n.backupAllData,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.exportDataFolder,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _handleBackup(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    LucideIcons.history,
                    color: Colors.orange,
                  ),
                  title: Text(
                    l10n.restoreAllData,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.importBackupFile,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _handleRestore(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Colors.red),
                  title: Text(
                    l10n.syncUserProfile,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.createUpdateProfile,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing profile...')),
                      );
                      try {
                        print("DEBUG: Starting Sync for ${user.uid}");
                        await UserRepository().getUser(
                          user.uid,
                          forceRefresh: true,
                        );
                        print("DEBUG: Sync Success for ${user.uid}");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Profile healed & synced successfully!',
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        print("DEBUG: Sync Failed: $e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sync Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You are not logged in.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            l10n.offlineStorage,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.download, color: Colors.blue),
                  title: Text(
                    l10n.downloadAllData,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.storeInfoOffline,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _startOfflineSync(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Colors.red),
                  title: Text(
                    l10n.clearLocalCache,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.freeUpSpace,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Cache?'),
                        content: const Text(
                          'This will remove all stored anime data and links.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await DatabaseHelper().clearAll();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Local cache cleared.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Admin Tools Section - visible for quicker access
          FutureBuilder<bool>(
            future: _adminFuture,
            builder: (context, snapshot) {
              final isServerAdmin = snapshot.data == true;
              if (isServerAdmin || _isDevMode) {
                return _buildSection(
                  context,
                  'Developer Tools',
                  child: ListTile(
                    leading: const Icon(
                      LucideIcons.shieldCheck,
                      color: Colors.red,
                    ),
                    title: Text(
                      l10n.adminDashboard,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.manageApp,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin');
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            'App & Updates',
            child: ListTile(
              leading: const Icon(
                LucideIcons.arrowUpCircle,
                color: AppColors.primary,
              ),
              title: Text(
                l10n.checkForUpdates,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                l10n.ensureLatestVersion,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checking for updates...')),
                );
                try {
                  final updateService = UpdateService();
                  final releaseData = await updateService.checkUpdate();
                  if (mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    if (releaseData != null) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) =>
                            UpdateDialog(releaseData: releaseData),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('App is up to date!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
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
          ),
          const SizedBox(height: 40),
          // Version info with hidden gesture
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() => _devTapCount++);
                if (_devTapCount >= 7) {
                  _devTapCount = 0;
                  _toggleDevMode();
                }
              },
              child: Column(
                children: [
                  Text(
                    'AnimeHat v1.0.0',
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isDevMode)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '(Developer Mode)',
                        style: TextStyle(color: Colors.red, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<bool> _checkIsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final appUser = await UserRepository().getUser(
        user.uid,
        forceRefresh: true,
      );
      final isNameAdmin = appUser?.displayName.toLowerCase() == 'admin';
      final isAdminFlag = appUser?.isAdmin ?? false;

      print('DEBUG: Admin Check for ${appUser?.displayName}');
      print('DEBUG: isAdmin flag: $isAdminFlag (Source: Server Refresh)');
      print('DEBUG: isNameAdmin: $isNameAdmin');

      // Allow access if EITHER the flag is true OR the name is admin
      return isAdminFlag || isNameAdmin;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Widget _buildSection(
    BuildContext context,
    String title, {
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : AppColors.border,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(22), child: child),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    Locale locale,
    Locale currentLocale,
    Function(Locale) onLocaleChange,
  ) {
    return RadioListTile<Locale>(
      title: Text(title),
      value: locale,
      groupValue: currentLocale,
      activeColor: AppColors.primary,
      onChanged: (value) => onLocaleChange(value!),
    );
  }

  void _showThemeSelector(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => ThemeSelectorWidget(
        currentTheme: widget.currentTheme,
        onThemeChanged: (theme) {
          widget.onThemeChange(theme);
        },
        currentAccentName: widget.currentAccentName,
        onAccentChanged: (accent) {
          widget.onAccentChange(accent);
        },
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    final backupService = BackupService();
    if (!await backupService.requestPermissions()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
      return;
    }

    final path = await backupService.pickDirectory();
    if (path == null) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final success = await backupService.exportDatabase(path);
    if (mounted) Navigator.pop(context); // Close loading

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_directory', path);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Backup saved to $path' : 'Backup failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    final backupService = BackupService();
    if (!await backupService.requestPermissions()) return;

    final path = await backupService.pickBackupFile();
    if (path == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
          'This will overwrite your current data with the backup. The app may need to restart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Restore',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final success = await backupService.importDatabase(path);
    if (mounted) Navigator.pop(context); // Close loading

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Data restored successfully. Please restart the app.'
                : 'Restore failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _startOfflineSync(BuildContext context) {
    final repository = HomeRepository(apiClient: AnimeifyApiClient());
    final syncService = OfflineSyncService(repository);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<double>(
          stream: syncService.syncAll(),
          builder: (context, snapshot) {
            double progress = (snapshot.data ?? 0.0).clamp(-1.0, 1.0);
            bool isError = progress < 0;
            bool isDone = progress >= 1.0;

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isDone
                    ? 'Sync Complete'
                    : (isError ? 'Sync Failed' : 'Syncing Data...'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDone && !isError) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Downloading anime details and links...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ] else if (isError) ...[
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to download data.\nPlease check your connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Success!\nAll anime information and streaming links are now stored locally.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
              actions: [
                if (isDone || isError)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isDone) {
                        _triggerAutoBackup();
                      }
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: isError ? Colors.grey : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _triggerAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final backupPath = prefs.getString('backup_directory');
    if (backupPath != null) {
      final backupService = BackupService();
      await backupService.exportDatabase(backupPath);
      print('Auto-backup completed to $backupPath');
    }
  }
}
