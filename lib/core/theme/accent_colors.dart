import 'package:flutter/material.dart';

/// Collection of beautiful accent colors for the theme engine
class AccentColors {
  // Primary gradient colors
  static const List<AccentPreset> presets = [
    AccentPreset(
      name: 'Indigo',
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      emoji: '💜',
    ),
    AccentPreset(
      name: 'Ocean',
      primary: Color(0xFF06B6D4),
      secondary: Color(0xFF3B82F6),
      emoji: '🌊',
    ),
    AccentPreset(
      name: 'Emerald',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF059669),
      emoji: '🌿',
    ),
    AccentPreset(
      name: 'Rose',
      primary: Color(0xFFF43F5E),
      secondary: Color(0xFFEC4899),
      emoji: '🌸',
    ),
    AccentPreset(
      name: 'Amber',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFEF4444),
      emoji: '🔥',
    ),
    AccentPreset(
      name: 'Violet',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFA855F7),
      emoji: '🔮',
    ),
    AccentPreset(
      name: 'Cyan',
      primary: Color(0xFF22D3EE),
      secondary: Color(0xFF06B6D4),
      emoji: '💎',
    ),
    AccentPreset(
      name: 'Sunset',
      primary: Color(0xFFFF6B6B),
      secondary: Color(0xFFFFE66D),
      emoji: '🌅',
    ),
    AccentPreset(
      name: 'Forest',
      primary: Color(0xFF2D5A27),
      secondary: Color(0xFF4ADE80),
      emoji: '🌲',
    ),
    AccentPreset(
      name: 'Midnight',
      primary: Color(0xFF1E293B),
      secondary: Color(0xFF475569),
      emoji: '🌙',
    ),
    AccentPreset(
      name: 'Coral',
      primary: Color(0xFFFF7F50),
      secondary: Color(0xFFFF6B9D),
      emoji: '🪸',
    ),
    AccentPreset(
      name: 'Arctic',
      primary: Color(0xFF60A5FA),
      secondary: Color(0xFFE0F2FE),
      emoji: '❄️',
    ),
    AccentPreset(
      name: 'Cherry',
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFFB7185),
      emoji: '🍒',
    ),
    AccentPreset(
      name: 'Lavender',
      primary: Color(0xFFA78BFA),
      secondary: Color(0xFFC4B5FD),
      emoji: '💐',
    ),
    AccentPreset(
      name: 'Gold',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFFBBF24),
      emoji: '✨',
    ),
    AccentPreset(
      name: 'Aqua',
      primary: Color(0xFF14B8A6),
      secondary: Color(0xFF5EEAD4),
      emoji: '🐬',
    ),
    AccentPreset(
      name: 'Berry',
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFFC084FC),
      emoji: '🫐',
    ),
    AccentPreset(
      name: 'Slate',
      primary: Color(0xFF64748B),
      secondary: Color(0xFF94A3B8),
      emoji: '🪨',
    ),
    AccentPreset(
      name: 'Lime',
      primary: Color(0xFF84CC16),
      secondary: Color(0xFFA3E635),
      emoji: '🍈',
    ),
    AccentPreset(
      name: 'Sakura',
      primary: Color(0xFFFFB7C5),
      secondary: Color(0xFFFFDAE0),
      emoji: '🌸',
    ),
  ];

  /// Get preset by name
  static AccentPreset? getByName(String name) {
    try {
      return presets.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Get default preset
  static AccentPreset get defaultPreset => presets.first;

  /// Get preset based on anime genre
  static AccentPreset getByGenre(String genres) {
    final g = genres.toLowerCase();

    if (g.contains('romance') || g.contains('shoujo')) {
      return getByName('Sakura') ?? presets[19]; // Sakura
    }
    if (g.contains('action') || g.contains('shounen')) {
      return getByName('Amber') ?? presets[4]; // Amber/Fire
    }
    if (g.contains('horror') ||
        g.contains('thriller') ||
        g.contains('mystery')) {
      return getByName('Midnight') ?? presets[9]; // Midnight
    }
    if (g.contains('slice of life') || g.contains('comedy')) {
      return getByName('Emerald') ?? presets[2]; // Emerald/Nature
    }
    if (g.contains('fantasy') || g.contains('magic')) {
      return getByName('Violet') ?? presets[5]; // Violet/Magic
    }
    if (g.contains('sports')) {
      return getByName('Indigo') ?? presets[0]; // Indigo
    }
    if (g.contains('scifi') || g.contains('mecha')) {
      return getByName('Ocean') ?? presets[1]; // Ocean/Tech
    }

    return defaultPreset;
  }
}

/// Accent color preset model
class AccentPreset {
  final String name;
  final Color primary;
  final Color secondary;
  final String emoji;

  const AccentPreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.emoji,
  });

  /// Get gradient from this preset
  LinearGradient get gradient => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Get a shimmer gradient for loading states
  LinearGradient get shimmerGradient => LinearGradient(
        colors: [
          primary.withValues(alpha: 0.3),
          secondary.withValues(alpha: 0.5),
          primary.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  /// Get a glow color for shadows
  Color get glowColor => primary.withValues(alpha: 0.4);

  /// Generate a color scheme from this preset
  ColorScheme toColorScheme({Brightness brightness = Brightness.dark}) {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
    );
  }
}

/// Beautiful gradient background presets
class GradientBackgrounds {
  static const List<GradientPreset> presets = [
    GradientPreset(
      name: 'Deep Space',
      colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E)],
      angle: 135,
    ),
    GradientPreset(
      name: 'Night Sky',
      colors: [Color(0xFF141E30), Color(0xFF243B55)],
      angle: 180,
    ),
    GradientPreset(
      name: 'Ocean Deep',
      colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      angle: 135,
    ),
    GradientPreset(
      name: 'Dark Forest',
      colors: [Color(0xFF0A1F0A), Color(0xFF142514)],
      angle: 180,
    ),
    GradientPreset(
      name: 'Midnight Purple',
      colors: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
      angle: 135,
    ),
    GradientPreset(
      name: 'Carbon',
      colors: [Color(0xFF0F0F0F), Color(0xFF1C1C1C)],
      angle: 180,
    ),
    GradientPreset(
      name: 'Aurora',
      colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF0D1117)],
      angle: 135,
    ),
    GradientPreset(
      name: 'Ember',
      colors: [Color(0xFF1A0000), Color(0xFF2D0A0A)],
      angle: 180,
    ),
  ];

  static GradientPreset get defaultPreset => presets.first;
}

/// Gradient background preset model
class GradientPreset {
  final String name;
  final List<Color> colors;
  final double angle;

  const GradientPreset({
    required this.name,
    required this.colors,
    this.angle = 135,
  });

  /// Convert angle to alignment
  LinearGradient toGradient() {
    final rad = angle * 3.14159 / 180;
    return LinearGradient(
      begin: Alignment(-1 * (rad.abs() < 1.57 ? 1 : -1), -1),
      end: Alignment(rad.abs() < 1.57 ? 1 : -1, 1),
      colors: colors,
    );
  }

  /// Create a decoration with this gradient
  BoxDecoration toDecoration() {
    return BoxDecoration(gradient: toGradient());
  }
}

/// Widget for gradient background
class GradientBackground extends StatelessWidget {
  final Widget child;
  final GradientPreset? preset;
  final List<Color>? customColors;

  const GradientBackground({
    super.key,
    required this.child,
    this.preset,
    this.customColors,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePreset = preset ?? GradientBackgrounds.defaultPreset;
    final colors = customColors ?? effectivePreset.colors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}

/// Animated gradient background
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<List<Color>> colorSets;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.colorSets,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.colorSets.length;
          });
          _controller.reset();
          _controller.forward();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColors = widget.colorSets[_currentIndex];
    final nextColors =
        widget.colorSets[(_currentIndex + 1) % widget.colorSets.length];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(currentColors[0], nextColors[0], _controller.value)!,
                Color.lerp(
                  currentColors.last,
                  nextColors.last,
                  _controller.value,
                )!,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
