/// Theme manager for AnimeHat with multiple theme options
/// Supports dynamic theme switching with customizable colors
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accent_colors.dart';

/// Available app themes
enum AppThemeType {
  // Light themes
  classic, // Original light theme
  soft, // Softer, warmer colors
  ocean, // Blue-tinted light theme
  // Dark themes
  midnight, // Deep dark theme (original)
  amoled, // Pure black for AMOLED screens
  purple, // Purple accent dark theme
  teal, // Teal accent dark theme
  minimal, // High contrast, rectangular (light)
  minimalDark, // High contrast, rectangular (dark)
  modern, // Sleek, modern dark UI as seen in user images
}

/// Theme configuration data
class ThemeConfig {
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Brightness brightness;
  final Color? navigationBarColor;
  final Color? systemUiOverlayColor;

  const ThemeConfig({
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.brightness,
    this.navigationBarColor,
    this.systemUiOverlayColor,
  });
}

/// Theme manager singleton
class ThemeManager {
  static final ThemeManager _instance = ThemeManager._();
  static ThemeManager get instance => _instance;

  ThemeManager._();

  /// All available themes
  static const Map<AppThemeType, ThemeConfig> themes = {
    // Light Themes
    AppThemeType.classic: ThemeConfig(
      name: 'Classic',
      description: 'Original clean light theme',
      primaryColor: Color(0xFF007AFF),
      secondaryColor: Color(0xFF5856D6),
      accentColor: Color(0xFF34C759),
      backgroundColor: Color(0xFFF2F2F7),
      surfaceColor: Colors.white,
      cardColor: Colors.white,
      textPrimary: Color(0xFF1C1C1E),
      textSecondary: Color(0xFF8E8E93),
      brightness: Brightness.light,
    ),

    AppThemeType.soft: ThemeConfig(
      name: 'Soft',
      description: 'Warm and gentle colors',
      primaryColor: Color(0xFFE07B4A),
      secondaryColor: Color(0xFFD4A373),
      accentColor: Color(0xFF95B088),
      backgroundColor: Color(0xFFFAF8F5),
      surfaceColor: Color(0xFFFFFCF9),
      cardColor: Color(0xFFFFFCF9),
      textPrimary: Color(0xFF3D3D3D),
      textSecondary: Color(0xFF878787),
      brightness: Brightness.light,
    ),

    AppThemeType.ocean: ThemeConfig(
      name: 'Ocean',
      description: 'Cool blue tones',
      primaryColor: Color(0xFF0077B6),
      secondaryColor: Color(0xFF00B4D8),
      accentColor: Color(0xFF48CAE4),
      backgroundColor: Color(0xFFF0F7FA),
      surfaceColor: Color(0xFFFAFDFF),
      cardColor: Color(0xFFFAFDFF),
      textPrimary: Color(0xFF023047),
      textSecondary: Color(0xFF6B8A9A),
      brightness: Brightness.light,
    ),

    // Dark Themes
    AppThemeType.midnight: ThemeConfig(
      name: 'Midnight',
      description: 'Deep dark theme',
      primaryColor: Color(0xFF0A84FF),
      secondaryColor: Color(0xFF5E5CE6),
      accentColor: Color(0xFF30D158),
      backgroundColor: Color(0xFF000000),
      surfaceColor: Color(0xFF1C1C1E),
      cardColor: Color(0xFF1C1C1E),
      textPrimary: Colors.white,
      textSecondary: Color(0xFF8E8E93),
      brightness: Brightness.dark,
    ),

    AppThemeType.amoled: ThemeConfig(
      name: 'AMOLED',
      description: 'Pure black for battery saving',
      primaryColor: Color(0xFF00D4FF),
      secondaryColor: Color(0xFF7B68EE),
      accentColor: Color(0xFF00FF88),
      backgroundColor: Color(0xFF000000),
      surfaceColor: Color(0xFF0A0A0A),
      cardColor: Color(0xFF121212),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB0B0B0),
      brightness: Brightness.dark,
    ),

    AppThemeType.purple: ThemeConfig(
      name: 'Purple Night',
      description: 'Elegant purple accents',
      primaryColor: Color(0xFFBB86FC),
      secondaryColor: Color(0xFF7C4DFF),
      accentColor: Color(0xFFCF6679),
      backgroundColor: Color(0xFF121212),
      surfaceColor: Color(0xFF1E1E2E),
      cardColor: Color(0xFF2D2D44),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFB0B0B0),
      brightness: Brightness.dark,
    ),

    AppThemeType.teal: ThemeConfig(
      name: 'Teal Dark',
      description: 'Modern teal theme',
      primaryColor: Color(0xFF03DAC6),
      secondaryColor: Color(0xFF018786),
      accentColor: Color(0xFF64FFDA),
      backgroundColor: Color(0xFF0D1B1E),
      surfaceColor: Color(0xFF152D33),
      cardColor: Color(0xFF1A3840),
      textPrimary: Color(0xFFE0F2F1),
      textSecondary: Color(0xFF80CBC4),
      brightness: Brightness.dark,
    ),

    AppThemeType.minimal: ThemeConfig(
      name: 'Minimal Light',
      description: 'Fast, rectangular, high contrast',
      primaryColor: Colors.black,
      secondaryColor: Colors.grey,
      accentColor: Colors.black,
      backgroundColor: Colors.white,
      surfaceColor: Colors.white,
      cardColor: Colors.white,
      textPrimary: Colors.black,
      textSecondary: Colors.black87,
      brightness: Brightness.light,
      navigationBarColor: Colors.white,
      systemUiOverlayColor: Colors.transparent,
    ),

    AppThemeType.minimalDark: ThemeConfig(
      name: 'Minimal Dark',
      description: 'Deep black, rectangular, high contrast',
      primaryColor: Colors.white,
      secondaryColor: Colors.grey,
      accentColor: Colors.white,
      backgroundColor: Colors.black,
      surfaceColor: Colors.black,
      cardColor: Colors.black,
      textPrimary: Colors.white,
      textSecondary: Colors.white70,
      brightness: Brightness.dark,
      navigationBarColor: Colors.black,
      systemUiOverlayColor: Colors.transparent,
    ),

    AppThemeType.modern: ThemeConfig(
      name: 'Modern Dark',
      description: 'Sleek, modern dark UI with rounded borders',
      primaryColor: const Color(0xFF00D1FF),
      secondaryColor: const Color(0xFF1E1E2E),
      accentColor: const Color(0xFF00FF88),
      backgroundColor: const Color(0xFF0F0F14),
      surfaceColor: const Color(0xFF161621),
      cardColor: const Color(0xFF1E1E2E),
      textPrimary: Colors.white,
      textSecondary: const Color(0xFFA0A0B0),
      brightness: Brightness.dark,
      navigationBarColor: const Color(0xFF0F0F14),
    ),
  };

  /// Build ThemeData from theme type
  ThemeData buildTheme(
    AppThemeType type, {
    Locale locale = const Locale('en'),
    AccentPreset? accentOverride,
  }) {
    final config = themes[type]!;
    final isDark = config.brightness == Brightness.dark;

    final primary = accentOverride?.primary ?? config.primaryColor;
    final secondary = accentOverride?.secondary ?? config.secondaryColor;

    // Select font based on language
    final String languageCode = locale.languageCode;
    final TextTheme baseTextTheme = ThemeData(
      brightness: config.brightness,
    ).textTheme;

    TextTheme selectedTextTheme;
    if (languageCode == 'ar') {
      selectedTextTheme = GoogleFonts.cairoTextTheme(baseTextTheme);
    } else {
      selectedTextTheme = GoogleFonts.outfitTextTheme(baseTextTheme);
    }

    return ThemeData(
      useMaterial3: true,
      brightness: config.brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: config.backgroundColor,

      colorScheme: ColorScheme(
        brightness: config.brightness,
        primary: primary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: secondary,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: const Color(0xFFCF6679),
        onError: Colors.black,
        surface: config.surfaceColor,
        onSurface: config.textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: config.backgroundColor,
        foregroundColor: config.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:
              config.navigationBarColor ?? config.backgroundColor,
        ),
      ),

      // Rectangular shapes for Minimal theme
      cardTheme: CardThemeData(
        color: config.cardColor,
        elevation:
            (type == AppThemeType.minimal || type == AppThemeType.minimalDark)
            ? 0
            : (isDark ? 0 : 2),
        shape:
            (type == AppThemeType.minimal || type == AppThemeType.minimalDark)
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: type == AppThemeType.minimal
                      ? Colors.black12
                      : Colors.white12,
                  width: 0.5,
                ),
              )
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  type == AppThemeType.modern ? 12 : 16,
                ),
                side: isDark
                    ? BorderSide(color: config.textSecondary.withOpacity(0.1))
                    : BorderSide.none,
              ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.navigationBarColor ?? config.backgroundColor,
        selectedItemColor: config.primaryColor,
        unselectedItemColor: config.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: config.backgroundColor,
        surfaceTintColor: config.surfaceColor,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      iconTheme: IconThemeData(color: config.textPrimary, size: 24),

      textTheme: selectedTextTheme.copyWith(
        headlineLarge: selectedTextTheme.headlineLarge?.copyWith(
          color: config.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: selectedTextTheme.headlineMedium?.copyWith(
          color: config.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: selectedTextTheme.titleLarge?.copyWith(
          color: config.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: selectedTextTheme.bodyLarge?.copyWith(
          color: config.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: selectedTextTheme.bodyMedium?.copyWith(
          color: config.textSecondary,
          fontSize: 14,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),

      dividerTheme: DividerThemeData(
        color: config.textSecondary.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF333333),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }

  /// Get list of light themes
  List<AppThemeType> get lightThemes => AppThemeType.values
      .where((t) => themes[t]!.brightness == Brightness.light)
      .toList();

  /// Get list of dark themes
  List<AppThemeType> get darkThemes => AppThemeType.values
      .where((t) => themes[t]!.brightness == Brightness.dark)
      .toList();
}
