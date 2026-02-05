import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/theme_manager.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/services/download_service.dart';
import 'features/anime_details/presentation/screens/anime_details_screen.dart';
import 'features/anime_playback/presentation/screens/episode_player_screen.dart';
import 'core/models/anime_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/anime_details/presentation/screens/episodes_list_screen.dart';
import 'core/repositories/sync_repository.dart';
import 'core/models/sync_settings.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'core/services/ad_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'core/config/env.dart';
import 'firebase_options.dart';
import 'core/services/update_service.dart';
import 'core/widgets/update_dialog.dart';
import 'core/repositories/admin_repository.dart';
import 'features/admin/presentation/widgets/force_update_wrapper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'features/schedule/presentation/screens/schedule_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'core/widgets/error_boundary.dart';
import 'core/theme/accent_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AdService.init();

  // Initialize Supabase
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // Initialize Push Notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().init();

  await DownloadService().init();

  runApp(const AnimeHatApp());
}

class AnimeHatApp extends StatefulWidget {
  const AnimeHatApp({super.key});

  @override
  State<AnimeHatApp> createState() => _AnimeHatAppState();
}

class _AnimeHatAppState extends State<AnimeHatApp> {
  Locale _locale = const Locale('en');

  // Initialize with classic theme
  AppThemeType _themeType = AppThemeType.classic;
  String? _accentColorName;
  SyncSettings _syncSettings = SyncSettings();
  final _authRepository = AuthRepository();
  final _syncRepository = SyncRepository();
  final _adminRepository = AdminRepository();
  SharedPreferences? _prefs;
  String _currentVersion = '1.0.0';
  bool _showOnboarding = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSettings().then((_) {
      _handleAppSync();
      _checkForUpdates();
      _initAdminSettingsListener();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService();
    final releaseData = await updateService.checkUpdate();
    if (releaseData != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(release: releaseData),
      );
    }
  }

  Future<void> _initSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Load Locale
    final langCode = _prefs?.getString('languageCode');
    if (langCode != null) {
      _locale = Locale(langCode);
    }

    // Load Theme
    final themeName = _prefs?.getString('themeType');
    if (themeName != null) {
      _themeType = AppThemeType.values.firstWhere(
        (e) => e.toString() == themeName,
        orElse: () => AppThemeType.classic,
      );
    }

    // Load Accent Color
    _accentColorName = _prefs?.getString('accentColorName');

    // Load Sync Settings
    final syncEnabled = _prefs?.getBool('syncEnabled') ?? true;
    final syncSpeedIndex = _prefs?.getInt('syncSpeed') ?? 1; // Normal default
    _syncSettings = SyncSettings(
      isEnabled: syncEnabled,
      speed: SyncSpeed.values[syncSpeedIndex],
    );
    _syncRepository.updateSettings(_syncSettings);

    // Load Version Info
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;

    // Check onboarding status
    _showOnboarding = !(_prefs?.getBool('onboarding_completed') ?? false);

    if (mounted) setState(() => _isInitialized = true);
  }

  void _initAdminSettingsListener() {
    // Listen for global admin changes (like ads or maintenance)
    _adminRepository.streamGlobalSettings().listen((settings) {
      // 1. Update Ads globally
      AdService.updateAdsEnabled(settings.adsEnabled);
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleAppSync() async {
    // 1. Sync latest content immediately
    await _syncRepository.syncLatestContent();

    // 2. Start incremental sync in background (non-blocking)
    _syncRepository.startIncrementalSync();
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    _prefs?.setString('languageCode', locale.languageCode);
  }

  void _setThemeType(AppThemeType type) {
    setState(() {
      _themeType = type;
    });
    _prefs?.setString('themeType', type.toString());
  }

  void _setAccentColor(String? name) {
    setState(() {
      _accentColorName = name;
    });
    if (name != null) {
      _prefs?.setString('accentColorName', name);
    } else {
      _prefs?.remove('accentColorName');
    }
  }

  void _setSyncSettings(SyncSettings settings) {
    setState(() {
      _syncSettings = settings;
    });
    _syncRepository.updateSettings(settings);
    _prefs?.setBool('syncEnabled', settings.isEnabled);
    _prefs?.setInt('syncSpeed', settings.speed.index);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp(
        navigatorKey: NotificationService().navigatorKey,
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
        // Use the selected theme for both light and dark slots
        // The theme's internal brightness will handle the actual look
        // We force ThemeMode.light so that our custom theme (which might be dark)
        // is used as the 'current' theme without system interference overriding it
        themeMode: ThemeMode.light,
        theme: ThemeManager.instance.buildTheme(
          _themeType,
          locale: _locale,
          accentOverride: AccentColors.getByName(_accentColorName ?? ''),
        ),
        // darkTheme is technically not needed if we force ThemeMode.light,
        // but providing it doesn't hurt.
        darkTheme: ThemeManager.instance.buildTheme(
          _themeType,
          locale: _locale,
          accentOverride: AccentColors.getByName(_accentColorName ?? ''),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/anime-details') {
            final anime = settings.arguments as Anime;
            return MaterialPageRoute(
              builder: (context) => AnimeDetailsScreen(anime: anime),
            );
          }
          if (settings.name == '/episodes') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => EpisodesListScreen(
                anime: args['anime'] as Anime,
                episodes: args['episodes'] as List<Episode>,
              ),
            );
          }
          if (settings.name == '/episode-player') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => EpisodePlayerScreen(
                anime: args['anime'] as Anime,
                episode: args['episode'] as Episode,
                startAtMs: args['startAtMs'] as int? ?? 0,
                episodes: args['episodes'] as List<Episode>,
              ),
            );
          }
          return null;
        },
        routes: {
          '/': (context) {
            // Show loading while initializing
            if (!_isInitialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Show onboarding for new users
            if (_showOnboarding) {
              return OnboardingScreen(
                onComplete: () {
                  setState(() => _showOnboarding = false);
                },
              );
            }

            // Normal auth flow
            return StreamBuilder<User?>(
              stream: _authRepository.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) {
                  return ForceUpdateWrapper(
                    currentVersion: _currentVersion,
                    child: const HomeScreen(),
                  );
                }
                return const LoginScreen();
              },
            );
          },
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile': (context) {
            final uid = ModalRoute.of(context)?.settings.arguments as String?;
            final effectiveUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
            if (effectiveUid == null) return const LoginScreen();
            return ProfileScreen(uid: effectiveUid);
          },
          '/settings': (context) => SettingsScreen(
            currentLocale: _locale,
            onLocaleChange: _setLocale,
            currentTheme: _themeType,
            onThemeChange: _setThemeType,
            currentAccentName: _accentColorName,
            onAccentChange: _setAccentColor,
            syncSettings: _syncSettings,
            onSyncSettingsChange: _setSyncSettings,
          ),
          '/admin': (context) => const AdminDashboardScreen(),
          '/schedule': (context) => const ScheduleScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}
