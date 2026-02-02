/// Profile caching service for offline access
/// Stores user profile and photo locally using SQLite and file system
library;

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

/// Service for caching user profile data locally
class ProfileCacheService {
  static final ProfileCacheService _instance = ProfileCacheService._();
  static ProfileCacheService get instance => _instance;

  ProfileCacheService._();

  SharedPreferences? _prefs;
  Directory? _cacheDir;

  /// Initialize the cache service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheDir = await getApplicationDocumentsDirectory();
  }

  /// Cache user profile to local storage
  Future<void> cacheProfile(AppUser user) async {
    try {
      // Cache profile data as JSON
      final json = jsonEncode(user.toMap());
      await _prefs?.setString('cached_profile_${user.uid}', json);
      await _prefs?.setString(
        'cached_profile_timestamp_${user.uid}',
        DateTime.now().toIso8601String(),
      );

      // Cache profile photo if exists
      if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
        await _cacheProfilePhoto(user.uid, user.photoUrl!);
      }

      debugPrint('ProfileCache: Cached profile for ${user.uid}');
    } catch (e) {
      debugPrint('ProfileCache: Error caching profile: $e');
    }
  }

  /// Get cached profile (for offline use)
  Future<AppUser?> getCachedProfile(String uid) async {
    try {
      final json = _prefs?.getString('cached_profile_$uid');
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return AppUser.fromMap(data);
    } catch (e) {
      debugPrint('ProfileCache: Error reading cached profile: $e');
      return null;
    }
  }

  /// Check if cached profile exists and is valid
  Future<bool> hasValidCache(
    String uid, {
    Duration maxAge = const Duration(days: 7),
  }) async {
    final timestamp = _prefs?.getString('cached_profile_timestamp_$uid');
    if (timestamp == null) return false;

    try {
      final cachedTime = DateTime.parse(timestamp);
      return DateTime.now().difference(cachedTime) < maxAge;
    } catch (e) {
      return false;
    }
  }

  /// Get cached profile photo path
  Future<String?> getCachedPhotoPath(String uid) async {
    if (_cacheDir == null) await init();
    final photoFile = File('${_cacheDir!.path}/profile_photos/$uid.jpg');
    if (await photoFile.exists()) {
      return photoFile.path;
    }
    return null;
  }

  /// Cache profile photo to local file
  Future<void> _cacheProfilePhoto(String uid, String photoUrl) async {
    try {
      if (_cacheDir == null) await init();

      final photoDir = Directory('${_cacheDir!.path}/profile_photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) {
        final photoFile = File('${photoDir.path}/$uid.jpg');
        await photoFile.writeAsBytes(response.bodyBytes);
        debugPrint('ProfileCache: Cached photo for $uid');
      }
    } catch (e) {
      debugPrint('ProfileCache: Error caching photo: $e');
    }
  }

  /// Clear cached profile
  Future<void> clearCache(String uid) async {
    await _prefs?.remove('cached_profile_$uid');
    await _prefs?.remove('cached_profile_timestamp_$uid');

    if (_cacheDir != null) {
      final photoFile = File('${_cacheDir!.path}/profile_photos/$uid.jpg');
      if (await photoFile.exists()) {
        await photoFile.delete();
      }
    }
  }

  /// Clear all cached profiles
  Future<void> clearAllCaches() async {
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('cached_profile_')) {
        await _prefs?.remove(key);
      }
    }

    if (_cacheDir != null) {
      final photoDir = Directory('${_cacheDir!.path}/profile_photos');
      if (await photoDir.exists()) {
        await photoDir.delete(recursive: true);
      }
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    int size = 0;

    if (_cacheDir != null) {
      final photoDir = Directory('${_cacheDir!.path}/profile_photos');
      if (await photoDir.exists()) {
        await for (final entity in photoDir.list()) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    }

    return size;
  }
}

/// Mixin for easy profile caching in repositories
mixin ProfileCacheMixin {
  final ProfileCacheService _profileCache = ProfileCacheService.instance;

  /// Get user with offline fallback
  Future<AppUser?> getUserWithOfflineFallback(
    String uid,
    Future<AppUser?> Function() onlineFetcher,
  ) async {
    try {
      // Try to fetch online first
      final onlineUser = await onlineFetcher();
      if (onlineUser != null) {
        // Cache for offline use
        await _profileCache.cacheProfile(onlineUser);
        return onlineUser;
      }
    } catch (e) {
      debugPrint('ProfileCacheMixin: Online fetch failed, trying cache: $e');
    }

    // Fall back to cached version
    return _profileCache.getCachedProfile(uid);
  }
}
