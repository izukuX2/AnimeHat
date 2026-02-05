import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/models/github_release.dart';
import '../../../../core/widgets/update_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/release_card.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final UpdateService _updateService = UpdateService();
  String _currentVersion = '...';
  List<GithubRelease> _releases = [];
  bool _isLoading = true;
  GithubRelease? _latestRelease;
  bool _isUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;

    try {
      final releases = await _updateService.getReleases();
      if (mounted) {
        setState(() {
          _releases = releases;
          if (releases.isNotEmpty) {
            _latestRelease = releases.first;
            // Simple string comparison for now, assuming semantic versioning
            // or we use the service helper if publicly exposed,
            // but for now let's just use the service check logic indirectly via matching tag
            _isUpdateAvailable = _latestRelease!.version != _currentVersion;
            // Actually, let's use the service logic properly
            // But we don't have access to private method.
            // Let's just rely on tag comparison which is what checkUpdate does internally roughly
            // Or better, let's just call checkUpdate to see if it returns something
          }
          _isLoading = false;
        });

        // precise check
        final update = await _updateService.checkUpdate();
        if (mounted && update != null) {
          setState(() {
            _isUpdateAvailable = true;
            _latestRelease = update;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking updates: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates & Changes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isUpdateAvailable
                            ? [Colors.orange.shade800, Colors.orange.shade400]
                            : [Colors.green.shade800, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _isUpdateAvailable
                              ? Colors.orange.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isUpdateAvailable
                              ? LucideIcons.refreshCw
                              : LucideIcons.checkCircle,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isUpdateAvailable
                              ? 'Update Available!'
                              : 'You are up to date',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Version: $_currentVersion',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (_isUpdateAvailable && _latestRelease != null) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => UpdateDialog(
                                  release: _latestRelease!,
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.download),
                            label: const Text('Download Update'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Release History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_releases.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No release history found.'),
                      ),
                    )
                  else
                    ..._releases.map(
                      (release) => ReleaseCard(
                        release: release,
                        isCurrent: release.version == _currentVersion,
                        isLatest: _releases.first == release,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
