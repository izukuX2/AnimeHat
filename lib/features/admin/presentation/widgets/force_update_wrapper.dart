import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget that checks for app updates and blocks if force update is required
class ForceUpdateWrapper extends StatefulWidget {
  final Widget child;
  final String currentVersion;

  const ForceUpdateWrapper({
    super.key,
    required this.child,
    required this.currentVersion,
  });

  @override
  State<ForceUpdateWrapper> createState() => _ForceUpdateWrapperState();
}

class _ForceUpdateWrapperState extends State<ForceUpdateWrapper> {
  final AdminRepository _adminRepo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalSettings>(
      stream: _adminRepo.streamGlobalSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return widget.child;
        }

        final settings = snapshot.data!;

        // Check maintenance mode first
        if (settings.maintenanceMode) {
          return _buildMaintenanceScreen(settings);
        }

        // Check if force update is needed
        if (settings.forceUpdate &&
            _isVersionLower(widget.currentVersion, settings.minVersion)) {
          return _buildForceUpdateScreen(settings);
        }

        // Check for optional update
        if (_isVersionLower(widget.currentVersion, settings.latestVersion)) {
          // Show snackbar or banner for optional update
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showOptionalUpdateBanner(context, settings);
          });
        }

        return widget.child;
      },
    );
  }

  bool _isVersionLower(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = minimum.split('.').map(int.parse).toList();

      for (int i = 0; i < minParts.length && i < currentParts.length; i++) {
        if (currentParts[i] < minParts[i]) return true;
        if (currentParts[i] > minParts[i]) return false;
      }

      return currentParts.length < minParts.length;
    } catch (e) {
      return false;
    }
  }

  Widget _buildMaintenanceScreen(GlobalSettings settings) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.construction, size: 100, color: Colors.white),
                const SizedBox(height: 32),
                const Text(
                  'Maintenance Mode',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  settings.maintenanceMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForceUpdateScreen(GlobalSettings settings) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 100, color: Colors.white),
                const SizedBox(height: 32),
                const Text(
                  'Update Required',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A new version (${settings.latestVersion}) is available.\nPlease update to continue using the app.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                if (settings.updateNotes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "What's New:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          settings.updateNotes,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _launchUpdateUrl(settings.updateUrl),
                  icon: const Icon(Icons.download),
                  label: const Text('Update Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionalUpdateBanner(
    BuildContext context,
    GlobalSettings settings,
  ) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text('New version ${settings.latestVersion} available!'),
        leading: const Icon(Icons.system_update, color: AppColors.primary),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _launchUpdateUrl(settings.updateUrl);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUpdateUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
