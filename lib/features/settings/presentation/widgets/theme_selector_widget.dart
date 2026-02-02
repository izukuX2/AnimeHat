import 'package:flutter/material.dart';
import '../../../../core/theme/theme_manager.dart';

/// Theme selector dialog/sheet widget
class ThemeSelectorWidget extends StatelessWidget {
  final AppThemeType currentTheme;
  final Function(AppThemeType) onThemeChanged;

  const ThemeSelectorWidget({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeManager = ThemeManager.instance;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                'Choose Theme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize your app appearance',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Light Themes Section
          const Text(
            'Light Themes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

          const SizedBox(height: 24),

          // Dark Themes Section
          const Text(
            'Dark Themes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

          const SizedBox(height: 20),
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

  /// Show as bottom sheet
  static Future<void> show(
    BuildContext context,
    AppThemeType currentTheme,
    Function(AppThemeType) onThemeChanged,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ThemeSelectorWidget(
        currentTheme: currentTheme,
        onThemeChanged: (theme) {
          onThemeChanged(theme);
          Navigator.pop(context);
        },
      ),
    );
  }
}
