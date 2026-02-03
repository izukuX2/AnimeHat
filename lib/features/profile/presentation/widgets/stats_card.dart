import 'package:flutter/material.dart';

/// Beautiful stats card for user profiles
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor.withOpacity(0.2), cardColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cardColor, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of stats cards
class StatsGrid extends StatelessWidget {
  final List<StatItem> stats;
  final int crossAxisCount;

  const StatsGrid({super.key, required this.stats, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return StatsCard(
          title: stat.title,
          value: stat.value,
          icon: stat.icon,
          color: stat.color,
          onTap: stat.onTap,
        );
      },
    );
  }
}

/// Data model for stat items
class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatItem({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });
}

/// Animated progress stat bar
class ProgressStatBar extends StatelessWidget {
  final String label;
  final double progress; // 0.0 to 1.0
  final Color? color;
  final String? valueLabel;

  const ProgressStatBar({
    super.key,
    required this.label,
    required this.progress,
    this.color,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = color ?? theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (valueLabel != null)
              Text(
                valueLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0, 1)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor, barColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Achievement badge widget
class AchievementBadge extends StatelessWidget {
  final String title;
  final String emoji;
  final bool isUnlocked;
  final String? description;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.emoji,
    this.isUnlocked = true,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: description ?? title,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUnlocked
              ? theme.primaryColor.withOpacity(0.15)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? theme.primaryColor.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 16,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isUnlocked
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress indicator with label
class CircularStatIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final String value;
  final Color? color;
  final double size;

  const CircularStatIndicator({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    this.color,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.primaryColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0, 1)),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  backgroundColor: indicatorColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(indicatorColor),
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
