import 'package:flutter/foundation.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> favorites;
  final List<LibraryEntry> library;
  final Map<String, int> ratings; // animeId -> score
  final List<WatchHistoryItem> history;
  final List<String> customLibraryCategories;
  final List<ActivityLogEntry> activityLog;
  final String? bio;
  final String? coverPhotoUrl;
  final DateTime joinDate;
  final Map<String, String> socialLinks;
  final bool isAdmin;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.favorites = const [],
    this.library = const [],
    this.ratings = const {},
    this.history = const [],
    this.customLibraryCategories = const [],
    this.activityLog = const [],
    this.bio,
    this.coverPhotoUrl,
    required this.joinDate,
    this.socialLinks = const {},
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'favorites': favorites,
      'library': library.map((e) => e.toMap()).toList(),
      'ratings': ratings,
      'history': history.map((e) => e.toMap()).toList(),
      'customLibraryCategories': customLibraryCategories,
      'activityLog': activityLog.map((e) => e.toMap()).toList(),
      'bio': bio,
      'coverPhotoUrl': coverPhotoUrl,
      'joinDate': joinDate.toIso8601String(),
      'socialLinks': socialLinks,
      'isAdmin': isAdmin,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    try {
      return AppUser(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        displayName: map['displayName'] ?? '',
        favorites: _parseStringList(map['favorites']),
        library: _parseLibrary(map['library']),
        ratings: _parseRatings(map['ratings']),
        history: _parseHistory(map['history']),
        customLibraryCategories: _parseStringList(
          map['customLibraryCategories'],
        ),
        activityLog: _parseActivityLog(map['activityLog']),
        bio: map['bio'],
        coverPhotoUrl: map['coverPhotoUrl'],
        joinDate: _parseDate(map['joinDate']),
        socialLinks: _parseStringMap(map['socialLinks']),
        isAdmin: parseAdminFlag(map),
        photoUrl: parsePhotoUrl(map),
      );
    } catch (e) {
      debugPrint("CRITICAL ERROR parsing AppUser: $e");
      // Return a skeleton user to avoid app-wide crash
      return AppUser(
        uid: map['uid'] ?? 'error',
        email: map['email'] ?? '',
        displayName: 'Error Loading User',
        joinDate: DateTime.now(),
        isAdmin: false,
      );
    }
  }

  static List<LibraryEntry> _parseLibrary(dynamic data) {
    if (data is List) {
      return data.map((e) => LibraryEntry.fromMap(e)).toList();
    }
    return []; // Return empty if it's a Map (corrupted)
  }

  static List<WatchHistoryItem> _parseHistory(dynamic data) {
    if (data is List) {
      return data.map((e) => WatchHistoryItem.fromMap(e)).toList();
    }
    return []; // Return empty if it's a Map (corrupted)
  }

  static List<ActivityLogEntry> _parseActivityLog(dynamic data) {
    if (data is List) {
      return data.map((e) => ActivityLogEntry.fromMap(e)).toList();
    }
    return [];
  }

  static List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return List<String>.from(data);
    }
    return [];
  }

  static Map<String, int> _parseRatings(dynamic data) {
    if (data is Map) {
      return Map<String, int>.from(data);
    }
    return {};
  }

  static Map<String, String> _parseStringMap(dynamic data) {
    if (data is Map) {
      return Map<String, String>.from(data);
    }
    return {};
  }

  static DateTime _parseDate(dynamic data) {
    if (data is String) {
      try {
        return DateTime.parse(data);
      } catch (_) {}
    }
    return DateTime.now();
  }

  static bool parseAdminFlag(Map<String, dynamic> map) {
    // 1. Try root
    if (map['isAdmin'] != null) return _parseBool(map['isAdmin']);

    // 2. Fallback: check inside history (based on user screenshot)
    final history = map['history'];
    if (history is Map && history['isAdmin'] != null) {
      return _parseBool(history['isAdmin']);
    }

    return false;
  }

  static String? parsePhotoUrl(Map<String, dynamic> map) {
    // 1. Try root
    if (map['photoUrl'] != null) return map['photoUrl'] as String?;

    // 2. Fallback: check inside library (based on user screenshot)
    final library = map['library'];
    if (library is Map && library['photoUrl'] != null) {
      return library['photoUrl'] as String?;
    }

    return null;
  }

  /// Helper to parse bool from various types (String, bool, int)
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value != 0;
    return false;
  }
}

class WatchHistoryItem {
  final String animeId;
  final String episodeNumber;
  final DateTime watchedAt;
  final String title;
  final String imageUrl;
  final int positionInMs;
  final int totalDurationInMs;

  WatchHistoryItem({
    required this.animeId,
    required this.episodeNumber,
    required this.watchedAt,
    required this.title,
    required this.imageUrl,
    this.positionInMs = 0,
    this.totalDurationInMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'animeId': animeId,
      'episodeNumber': episodeNumber,
      'watchedAt': watchedAt.toIso8601String(),
      'title': title,
      'imageUrl': imageUrl,
      'positionInMs': positionInMs,
      'totalDurationInMs': totalDurationInMs,
    };
  }

  factory WatchHistoryItem.fromMap(Map<String, dynamic> map) {
    return WatchHistoryItem(
      animeId: map['animeId'] ?? '',
      episodeNumber: map['episodeNumber'] ?? '',
      watchedAt: DateTime.parse(
        map['watchedAt'] ?? DateTime.now().toIso8601String(),
      ),
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      positionInMs: map['positionInMs'] ?? 0,
      totalDurationInMs: map['totalDurationInMs'] ?? 0,
    );
  }
}

class LibraryEntry {
  final String animeId;
  final String category; // e.g., "Watching", "Completed", "Plan to Watch"
  final DateTime addedAt;

  LibraryEntry({
    required this.animeId,
    required this.category,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'animeId': animeId,
      'category': category,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory LibraryEntry.fromMap(dynamic map) {
    if (map is String) {
      // Handle legacy string-only library entries
      return LibraryEntry(
        animeId: map,
        category: 'Uncategorized',
        addedAt: DateTime.now(),
      );
    }
    return LibraryEntry(
      animeId: map['animeId'] ?? '',
      category: map['category'] ?? 'Uncategorized',
      addedAt: DateTime.parse(
        map['addedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class ActivityLogEntry {
  final String type; // e.g., "comment", "like", "rating", "library_update"
  final String targetId; // animeId, commentId, or postId
  final String description;
  final DateTime timestamp;

  ActivityLogEntry({
    required this.type,
    required this.targetId,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'targetId': targetId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLogEntry.fromMap(Map<String, dynamic> map) {
    return ActivityLogEntry(
      type: map['type'] ?? '',
      targetId: map['targetId'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
