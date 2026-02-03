import 'package:flutter/material.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/theme/accent_colors.dart';

/// Theme selector dialog/sheet widget
class ThemeSelectorWidget extends StatelessWidget {
  final AppThemeType currentTheme;
  final Function(AppThemeType) onThemeChanged;
  final String? currentAccentName;
  final Function(String?) onAccentChanged;

  const ThemeSelectorWidget({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.currentAccentName,
    required this.onAccentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeManager = ThemeManager.instance;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Accents Selection Section
                  const Text(
                    'Select Accent Color',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemCount: AccentColors.presets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Default (None) option
                        final isSelected = currentAccentName == null;
                        return _buildAccentItem(
                          context,
                          null,
                          isSelected,
                          isDark,
                        );
                      }
                      final preset = AccentColors.presets[index - 1];
                      final isSelected = currentAccentName == preset.name;
                      return _buildAccentItem(
                        context,
                        preset,
                        isSelected,
                        isDark,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Base Themes Section
                  const Text(
                    'Base Themes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Light Themes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: themeManager.lightThemes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final theme = themeManager.lightThemes[index];
                        return _buildThemeCard(context, theme);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dark Themes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: themeManager.darkThemes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final theme = themeManager.darkThemes[index];
                        return _buildThemeCard(context, theme);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentItem(
    BuildContext context,
    AccentPreset? preset,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => onAccentChanged(preset?.name),
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: preset?.gradient,
                color: preset == null
                    ? (isDark ? Colors.white10 : Colors.black12)
                    : null,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (preset?.primary ?? Colors.grey).withOpacity(
                            0.4,
                          ),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: preset == null
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.white,
                      size: 20,
                    )
                  : (preset == null
                        ? Icon(
                            Icons.close,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          )
                        : null),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preset?.name ?? 'Default',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, AppThemeType type) {
    final config = ThemeManager.themes[type]!;
    final isSelected = currentTheme == type;

    return GestureDetector(
      onTap: () => onThemeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? config.primaryColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: config.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            children: [
              // Theme preview
              Expanded(
                flex: 3,
                child: Container(
                  color: config.backgroundColor,
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mini app bar preview
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: config.surfaceColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Mini cards preview
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: config.cardColor,
                                  borderRadius: BorderRadius.circular(2),
                                  border: config.brightness == Brightness.dark
                                      ? Border.all(
                                          color: config.textSecondary
                                              .withOpacity(0.2),
                                          width: 0.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: config.cardColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Mini button preview
                      Container(
                        height: 6,
                        width: 30,
                        decoration: BoxDecoration(
                          color: config.primaryColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Theme name
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  color: config.surfaceColor,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        config.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: config.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          size: 10,
                          color: config.primaryColor,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context,
    AppThemeType currentTheme,
    Function(AppThemeType) onThemeChanged,
    String? currentAccentName,
    Function(String?) onAccentChanged,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ThemeSelectorWidget(
          currentTheme: currentTheme,
          onThemeChanged: (theme) {
            onThemeChanged(theme);
            Navigator.pop(context);
          },
          currentAccentName: currentAccentName,
          onAccentChanged: (accent) {
            onAccentChanged(accent);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
