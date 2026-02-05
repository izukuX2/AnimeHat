import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  // Unity Ads IDs
  static const String gameId = '6037307';
  static const String bannerPlacementId = 'izuku';
  static const String interstitialPlacementId = 'izuku1';
  static const String rewardedPlacementId = 'izuku2';

  static bool _adsEnabled = false; // Disabled by default
  static bool get adsEnabled => _adsEnabled;

  /// Initialize the Unity Ads SDK.
  static Future<void> init() async {
    try {
      // Load user preference
      final prefs = await SharedPreferences.getInstance();
      _adsEnabled = prefs.getBool('ads_enabled') ?? false; // Default to false
      debugPrint('DEBUG: Local Ads Preference: $_adsEnabled');

      await UnityAds.init(
        gameId: gameId,
        testMode: false, // Set to false for production
        onComplete: () =>
            debugPrint('DEBUG: Unity Ads Initialized Successfully'),
        onFailed: (error, message) =>
            debugPrint('DEBUG: Unity Ads Init Failed: $error - $message'),
      );

      // Attempt to load ads initially if enabled
      if (_adsEnabled) {
        loadInterstitial();
        loadRewarded();
      }
    } catch (e) {
      debugPrint('DEBUG: Unity Ads Init Error: $e');
    }
  }

  /// Update ads enabled status dynamically and save
  static Future<void> updateAdsEnabled(bool enabled) async {
    _adsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_enabled', enabled);
    debugPrint('DEBUG: AdService updated: adsEnabled = $_adsEnabled');

    if (enabled) {
      loadInterstitial();
      loadRewarded();
    }
  }

  // --- Interstitial Ads ---

  static Future<void> loadInterstitial() async {
    if (!_adsEnabled) return;
    await UnityAds.load(
      placementId: interstitialPlacementId,
      onComplete: (placementId) =>
          debugPrint('Interstitial Loaded: $placementId'),
      onFailed: (placementId, error, message) {
        debugPrint('Interstitial Load Failed: $placementId $error $message');
        // Retry after delay
        Future.delayed(const Duration(seconds: 30), () {
          debugPrint('Retrying Interstitial Load...');
          loadInterstitial();
        });
      },
    );
  }

  static Future<void> showInterstitial() async {
    if (!_adsEnabled) return;
    await UnityAds.showVideoAd(
      placementId: interstitialPlacementId,
      onComplete: (placementId) =>
          debugPrint('Interstitial Ad Complete: $placementId'),
      onFailed: (placementId, error, message) =>
          debugPrint('Interstitial Ad Failed: $placementId $error $message'),
      onStart: (placementId) =>
          debugPrint('Interstitial Ad Start: $placementId'),
      onSkipped: (placementId) =>
          debugPrint('Interstitial Ad Skipped: $placementId'),
    );
    // Reload for next time
    loadInterstitial();
  }

  // --- Rewarded Ads ---

  static Future<void> loadRewarded() async {
    if (!_adsEnabled) return;
    await UnityAds.load(
      placementId: rewardedPlacementId,
      onComplete: (placementId) => debugPrint('Rewarded Loaded: $placementId'),
      onFailed: (placementId, error, message) {
        debugPrint('Rewarded Load Failed: $placementId $error $message');
        // Retry after delay
        Future.delayed(const Duration(seconds: 30), () {
          debugPrint('Retrying Rewarded Load...');
          loadRewarded();
        });
      },
    );
  }

  static Future<void> showRewarded({
    required Function(String) onComplete,
    Function()? onFailed,
  }) async {
    if (!_adsEnabled) return;
    await UnityAds.showVideoAd(
      placementId: rewardedPlacementId,
      onComplete: (placementId) {
        debugPrint('Rewarded Ad Complete: $placementId');
        onComplete(placementId);
        // Reload for next time
        loadRewarded();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Rewarded Ad Failed: $placementId $error $message');
        if (onFailed != null) onFailed();
      },
      onStart: (placementId) => debugPrint('Rewarded Ad Start: $placementId'),
      onClick: (placementId) => debugPrint('Rewarded Ad Click: $placementId'),
      onSkipped: (placementId) =>
          debugPrint('Rewarded Ad Skipped: $placementId'),
    );
  }
}
