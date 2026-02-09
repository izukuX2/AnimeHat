import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/services/extension_service.dart';
import '../../../../core/theme/app_colors.dart';

class ExtensionManagerScreen extends StatefulWidget {
  const ExtensionManagerScreen({super.key});

  @override
  State<ExtensionManagerScreen> createState() => _ExtensionManagerScreenState();
}

class _ExtensionManagerScreenState extends State<ExtensionManagerScreen> {
  final ExtensionService _extensionService = ExtensionService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Extensions & Sources'),
          backgroundColor: isDark ? Colors.black : AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sources', icon: Icon(LucideIcons.list)),
              Tab(text: 'Mods', icon: Icon(LucideIcons.palette)),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: ListenableBuilder(
          listenable: _extensionService,
          builder: (context, _) {
            return TabBarView(
              children: [
                _buildProviderList(),
                _buildModList(),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddExtensionDialog,
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add extension'),
        ),
      ),
    );
  }

  Widget _buildProviderList() {
    final activeProvider = _extensionService.activeProvider;
    final providers = _extensionService.availableProviders;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final isActive = provider.id == activeProvider.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(LucideIcons.puzzle, color: AppColors.primary),
            ),
            title: Text(
              provider.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(provider.baseUrl),
            trailing: isActive
                ? const Icon(LucideIcons.checkCircle, color: Colors.green)
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _extensionService.setActiveProvider(provider.id);
                      });
                    },
                    child: const Text('Use'),
                  ),
            onLongPress: provider.id == 'animeify_legacy'
                ? null
                : () => _showUninstallConfirm(provider.id, provider.name),
          ),
        );
      },
    );
  }

  Widget _buildModList() {
    final activeMod = _extensionService.activeMod;
    final mods = _extensionService.installedMods;

    if (mods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.palette,
                size: 64, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No UI Mods installed',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Install a mod to customize your app!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mods.length,
      itemBuilder: (context, index) {
        final mod = mods[index];
        final isActive = mod.id == activeMod?.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isActive ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accent.withOpacity(0.1),
              child: const Icon(LucideIcons.palette, color: AppColors.accent),
            ),
            title: Text(
              mod.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('by ${mod.author} • v${mod.version}'),
            trailing: isActive
                ? ElevatedButton(
                    onPressed: () => _extensionService.setActiveMod(null),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Reset'),
                  )
                : ElevatedButton(
                    onPressed: () => _extensionService.setActiveMod(mod.id),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent),
                    child: const Text('Apply'),
                  ),
            onLongPress: () => _showUninstallConfirm(mod.id, mod.name),
          ),
        );
      },
    );
  }

  void _showAddExtensionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Extension'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://example.com/extension.json',
              labelText: 'Extension JSON URL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  try {
                    await _extensionService.installExtensionFromUrl(url);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Install'),
            ),
          ],
        );
      },
    );
  }

  void _showUninstallConfirm(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Extension'),
        content: Text('Are you sure you want to uninstall $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _extensionService.uninstallExtension(id);
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}
