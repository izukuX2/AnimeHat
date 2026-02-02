import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for global app settings stored in Firestore
class GlobalSettings {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String latestVersion;
  final String minVersion;
  final String updateUrl;
  final String updateNotes;
  final bool forceUpdate;
  final DateTime? lastUpdated;

  Map<String, dynamic> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'latestVersion': latestVersion,
      'minVersion': minVersion,
      'updateUrl': updateUrl,
      'updateNotes': updateNotes,
      'forceUpdate': forceUpdate,
      'lastUpdated': FieldValue.serverTimestamp(),
      'adsEnabled': adsEnabled,
    };
  }

  final bool adsEnabled;

  GlobalSettings({
    this.maintenanceMode = false,
    this.maintenanceMessage =
        'App is under maintenance. Please try again later.',
    this.latestVersion = '1.0.0',
    this.minVersion = '1.0.0',
    this.updateUrl = '',
    this.updateNotes = '',
    this.forceUpdate = false,
    this.lastUpdated,
    this.adsEnabled = true,
  });

  factory GlobalSettings.fromMap(Map<String, dynamic> map) {
    return GlobalSettings(
      maintenanceMode: map['maintenanceMode'] ?? false,
      maintenanceMessage:
          map['maintenanceMessage'] ?? 'App is under maintenance.',
      latestVersion: map['latestVersion'] ?? '1.0.0',
      minVersion: map['minVersion'] ?? '1.0.0',
      updateUrl: map['updateUrl'] ?? '',
      updateNotes: map['updateNotes'] ?? '',
      forceUpdate: map['forceUpdate'] ?? false,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
      adsEnabled: map['adsEnabled'] ?? true,
    );
  }
}

/// Repository for admin operations
class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _settingsDoc = 'globals/settings';

  /// Get global app settings
  Future<GlobalSettings> getGlobalSettings() async {
    final doc = await _db.doc(_settingsDoc).get();
    if (doc.exists) {
      return GlobalSettings.fromMap(doc.data()!);
    }
    return GlobalSettings();
  }

  /// Stream global settings for real-time updates
  Stream<GlobalSettings> streamGlobalSettings() {
    return _db.doc(_settingsDoc).snapshots().map((doc) {
      if (doc.exists) {
        return GlobalSettings.fromMap(doc.data()!);
      }
      return GlobalSettings();
    });
  }

  /// Update global settings (Admin only)
  Future<void> updateGlobalSettings(GlobalSettings settings) async {
    await _db.doc(_settingsDoc).set(settings.toMap(), SetOptions(merge: true));
  }

  /// Toggle maintenance mode
  Future<void> toggleMaintenanceMode(bool enabled, {String? message}) async {
    final updates = <String, dynamic>{
      'maintenanceMode': enabled,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    if (message != null) {
      updates['maintenanceMessage'] = message;
    }
    await _db.doc(_settingsDoc).set(updates, SetOptions(merge: true));
  }

  /// Set force update version
  Future<void> setForceUpdate({
    required String latestVersion,
    required String minVersion,
    required String updateUrl,
    String? notes,
    bool force = false,
  }) async {
    await _db.doc(_settingsDoc).set({
      'latestVersion': latestVersion,
      'minVersion': minVersion,
      'updateUrl': updateUrl,
      'updateNotes': notes ?? '',
      'forceUpdate': force,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get all users (Admin only)
  Future<List<Map<String, dynamic>>> getAllUsers({int limit = 50}) async {
    final snapshot = await _db.collection('users').limit(limit).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Ban/Unban user
  Future<void> setUserBanned(String uid, bool banned) async {
    await _db.collection('users').doc(uid).set({
      'isBanned': banned,
    }, SetOptions(merge: true));
  }

  /// Toggle Admin status
  Future<void> toggleAdminStatus(String uid, bool isAdmin) async {
    await _db.collection('users').doc(uid).set({
      'isAdmin': isAdmin,
    }, SetOptions(merge: true));
  }

  /// Delete anime (hide from view)
  Future<void> hideAnime(String animeId) async {
    await _db.collection('hidden_content').doc(animeId).set({
      'type': 'anime',
      'hiddenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unhide anime
  Future<void> unhideAnime(String animeId) async {
    await _db.collection('hidden_content').doc(animeId).delete();
  }

  /// Check if content is hidden
  Future<bool> isContentHidden(String contentId) async {
    final doc = await _db.collection('hidden_content').doc(contentId).get();
    return doc.exists;
  }

  /// Broadcast notification/news
  Future<void> broadcastNews({
    required String title,
    required String content,
    String? type,
    String? imageUrl,
  }) async {
    await _db.collection('announcements').add({
      'title': title,
      'content': content,
      'type': type ?? 'info',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  /// Get active announcements
  Stream<List<Map<String, dynamic>>> getAnnouncements() {
    return _db
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // ==================== Featured Anime Management ====================

  /// Add anime to featured list
  Future<void> addFeaturedAnime({
    required String animeId,
    required String title,
    required String imageUrl,
    String? description,
    int priority = 0,
  }) async {
    await _db.collection('featured_anime').doc(animeId).set({
      'animeId': animeId,
      'title': title,
      'imageUrl': imageUrl,
      'description': description ?? '',
      'priority': priority,
      'isActive': true,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove anime from featured list
  Future<void> removeFeaturedAnime(String animeId) async {
    await _db.collection('featured_anime').doc(animeId).delete();
  }

  /// Update featured anime priority
  Future<void> updateFeaturedPriority(String animeId, int priority) async {
    await _db.collection('featured_anime').doc(animeId).update({
      'priority': priority,
    });
  }

  /// Get all featured anime
  Stream<List<Map<String, dynamic>>> getFeaturedAnime() {
    return _db
        .collection('featured_anime')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Toggle featured anime active status
  Future<void> toggleFeaturedAnime(String animeId, bool isActive) async {
    await _db.collection('featured_anime').doc(animeId).update({
      'isActive': isActive,
    });
  }

  // ==================== App Statistics ====================

  /// Get basic app statistics
  Future<Map<String, int>> getAppStats() async {
    final usersCount = await _db.collection('users').count().get();
    final postsCount = await _db.collection('posts').count().get();
    final featuredCount = await _db.collection('featured_anime').count().get();

    return {
      'users': usersCount.count ?? 0,
      'posts': postsCount.count ?? 0,
      'featured': featuredCount.count ?? 0,
    };
  }

  /// Toggle ads globally
  Future<void> toggleAds(bool enabled) async {
    await _db.doc(_settingsDoc).set({
      'adsEnabled': enabled,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get simplified system logs
  Stream<List<Map<String, dynamic>>> getSystemLogs() {
    return _db
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Clear system logs
  Future<void> clearLogs() async {
    final snapshot = await _db.collection('logs').limit(100).get();
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
