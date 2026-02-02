import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalStorageService _local = LocalStorageService();

  Future<void> createUser(AppUser user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true))
        .then((_) => _local.saveUser(user))
        .catchError((e) => print("Error creating user: $e"));
  }

  Future<void> syncUser(
    String uid,
    String email,
    String? displayName,
    String? photoUrl,
  ) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await createUser(
        AppUser(
          uid: uid,
          email: email,
          displayName: displayName ?? email.split('@')[0],
          photoUrl: photoUrl,
          joinDate: DateTime.now(),
        ),
      );
      print("User document created for $uid");
    } else {
      final data = doc.data()!;
      // HEALING LOGIC: Detect misplaced fields and pull them to root
      final currentAdmin = AppUser.parseAdminFlag(data);
      final currentPhoto = AppUser.parsePhotoUrl(data);

      final updates = {
        'email': email,
        'displayName':
            displayName ?? data['displayName'] ?? email.split('@')[0],
        'photoUrl': photoUrl ?? currentPhoto ?? data['photoUrl'],
        'isAdmin': currentAdmin,
        'lastSynced': FieldValue.serverTimestamp(),
      };

      print("HEALING USER: Moving nested fields to root for $uid");
      await _db
          .collection('users')
          .doc(uid)
          .set(updates, SetOptions(merge: true));

      // Refresh local cache with latest info from server
      await _fetchAndCacheUser(uid, forceRefresh: true);
    }
  }

  Future<AppUser?> getUser(String uid, {bool forceRefresh = false}) async {
    // Try local first for speed/offline unless force refresh is requested
    if (!forceRefresh) {
      final cachedUser = await _local.getUser();
      if (cachedUser != null && cachedUser.uid == uid) {
        // In background, try to refresh if online, but don't wait for it
        _fetchAndCacheUser(uid).catchError((e) {
          print("Background fetch failed (offline?): $e");
          return null;
        });
        return cachedUser;
      }
    }

    // No cache, wrong user, or force refresh requested
    return _fetchAndCacheUser(uid, forceRefresh: forceRefresh);
  }

  Future<AppUser?> _fetchAndCacheUser(
    String uid, {
    bool forceRefresh = false,
  }) async {
    try {
      final source = forceRefresh ? Source.server : Source.serverAndCache;
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: source))
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        final user = AppUser.fromMap(doc.data()!);
        await _local.saveUser(user);
        return user;
      }
    } catch (e) {
      print("Error fetching user for cache: $e");
      // If server fetch failed, try to return local as last resort
      return await _local.getUser();
    }
    return null;
  }

  /// Stream user data for real-time updates
  Stream<AppUser?> getUserStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);

    final controller = StreamController<AppUser?>.broadcast();
    StreamSubscription? firestoreSub;

    void startSync() async {
      // 1. emit cached value first if available
      final cached = await _local.getUser();
      if (cached != null && cached.uid == uid && !controller.isClosed) {
        controller.add(cached);
      }

      // 2. Then listen for Firestore updates
      firestoreSub = _db
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen(
            (doc) {
              if (doc.exists && doc.data() != null) {
                final user = AppUser.fromMap(doc.data()!);
                _local.saveUser(user); // update cache
                if (!controller.isClosed) controller.add(user);
              } else {
                if (!controller.isClosed) {
                  controller.add(
                    (cached != null && cached.uid == uid) ? cached : null,
                  );
                }
              }
            },
            onError: (e) {
              print("Error in user stream: $e");
              // On error, we still have the cached value emitted already
            },
          );
    }

    controller.onListen = () {
      if (firestoreSub == null) startSync();
    };

    controller.onCancel = () {
      firestoreSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> addToHistory(String uid, WatchHistoryItem item) async {
    final userDoc = _db.collection('users').doc(uid);
    final doc = await userDoc.get();

    if (doc.exists) {
      final historyList = (doc.data()?['history'] as List? ?? [])
          .map((e) => WatchHistoryItem.fromMap(e))
          .toList();

      // Find existing entry for this anime/episode
      final existingIndex = historyList.indexWhere(
        (e) =>
            e.animeId == item.animeId && e.episodeNumber == item.episodeNumber,
      );

      if (existingIndex != -1) {
        final existing = historyList[existingIndex];
        // Merge: keep the latest progress, only update if the new one has position or the old one was empty
        if (item.positionInMs > 0 || existing.positionInMs == 0) {
          historyList[existingIndex] = item;
        } else {
          // Keep existing progress but update timestamp and other info (like title, imageUrl if they changed)
          historyList[existingIndex] = WatchHistoryItem(
            animeId: item.animeId,
            episodeNumber: item.episodeNumber,
            watchedAt: item.watchedAt,
            title: item.title,
            imageUrl: item.imageUrl,
            positionInMs: existing.positionInMs,
            totalDurationInMs: existing.totalDurationInMs,
          );
        }
      } else {
        historyList.add(item);
      }

      // Keep only last 50 items
      if (historyList.length > 50) {
        historyList.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
        historyList.removeRange(50, historyList.length);
      }

      await userDoc.update({
        'history': historyList.map((e) => e.toMap()).toList(),
      });
    }
  }

  Future<void> toggleFavorite(String uid, String animeId) async {
    if (uid.isEmpty || animeId.isEmpty) return;
    final userDoc = _db.collection('users').doc(uid);
    final doc = await userDoc.get();
    if (doc.exists) {
      final favorites = List<String>.from(doc.data()?['favorites'] ?? []);
      if (favorites.contains(animeId)) {
        favorites.remove(animeId);
      } else {
        favorites.add(animeId);
      }
      await userDoc.update({'favorites': favorites});
    }
  }

  Future<void> updateLibraryCategory(
    String uid,
    String animeId,
    String category,
  ) async {
    if (uid.isEmpty || animeId.isEmpty) return;
    final userDoc = _db.collection('users').doc(uid);
    final doc = await userDoc.get();

    if (doc.exists) {
      final library = (doc.data()?['library'] as List? ?? [])
          .map((e) => LibraryEntry.fromMap(e))
          .toList();

      final existingIndex = library.indexWhere((e) => e.animeId == animeId);

      if (existingIndex != -1) {
        if (category == 'Remove') {
          library.removeAt(existingIndex);
        } else {
          library[existingIndex] = LibraryEntry(
            animeId: animeId,
            category: category,
            addedAt: DateTime.now(),
          );
        }
      } else if (category != 'Remove') {
        library.add(
          LibraryEntry(
            animeId: animeId,
            category: category,
            addedAt: DateTime.now(),
          ),
        );
      }

      await userDoc.update({'library': library.map((e) => e.toMap()).toList()});
    }
  }

  Future<void> updateRating(String uid, String animeId, int rating) async {
    if (uid.isEmpty || animeId.isEmpty) return;
    await _db.collection('users').doc(uid).update({'ratings.$animeId': rating});
  }

  Future<void> addCustomCategory(String uid, String category) async {
    if (uid.isEmpty || category.isEmpty) return;
    await _db.collection('users').doc(uid).update({
      'customLibraryCategories': FieldValue.arrayUnion([category]),
    });
  }

  Future<void> removeCustomCategory(String uid, String category) async {
    if (uid.isEmpty || category.isEmpty) return;
    await _db.collection('users').doc(uid).update({
      'customLibraryCategories': FieldValue.arrayRemove([category]),
    });
  }

  Future<void> logActivity(String uid, ActivityLogEntry entry) async {
    if (uid.isEmpty) return;
    final userDoc = _db.collection('users').doc(uid);

    // We want to append to the log, but also keep it within a reasonable size (e.g., 50 items)
    // Firestore arrayUnion appends, but doesn't limit.
    // To limit, we'd need to read, update, and write, or use a subcollection.
    // user_model.dart defines it as a list in AppUser, implying it's a field.
    // For simplicity and performance on a list that might grow, a subcollection is usually better,
    // but sticking to the requested single-document model for now as per AppUser definition.
    // We will read, append/truncate, and update.

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return;

      final currentLog = (snapshot.data()?['activityLog'] as List? ?? [])
          .map((e) => ActivityLogEntry.fromMap(e))
          .toList();

      currentLog.insert(0, entry); // Add new at the top
      if (currentLog.length > 50) {
        currentLog.removeLast();
      }

      transaction.update(userDoc, {
        'activityLog': currentLog.map((e) => e.toMap()).toList(),
      });
    });
  }

  Future<void> updateProfile({
    required String uid,
    String? bio,
    String? coverPhotoUrl,
    String? displayName,
    String? photoUrl,
    Map<String, String>? socialLinks,
  }) async {
    if (uid.isEmpty) return;
    final Map<String, dynamic> updates = {};
    if (bio != null) updates['bio'] = bio;
    if (bio != null) updates['bio'] = bio;
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (coverPhotoUrl != null) updates['coverPhotoUrl'] = coverPhotoUrl;
    if (socialLinks != null) updates['socialLinks'] = socialLinks;

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
      // Re-load and cache fresh data
      _fetchAndCacheUser(uid);
    }
  }
}
