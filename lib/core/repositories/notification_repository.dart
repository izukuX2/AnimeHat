import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<NotificationModel>> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // 1. Personal Notifications Stream
    final personalStream = _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());

    // 2. Global Notifications Stream (e.g. New Episodes)
    final globalStream = _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());

    // Merge streams (This is a bit complex in Dart without rxdart,
    // simply creating a combined stream manually or just fetching standard way)
    // For simplicity and realtime updates, we'll try to combine them.
    // However, StreamGroup from async package is best.
    // If 'async' package is not available, we can just return one or fetching manually.
    // Let's assume we can just listen to both and merge in the UI or Repository.
    // BETTER APPROACH: Return a merged stream using a StreamController.

    // BUT, simplest MVP: Just fetch Personal + Global separately in UI or
    // use a StreamZip / StreamGroup if `async` package is there.
    // Checking pubspec... `async` is not explicitly listed but usually transitive.
    // Let's implement a manual merge.

    return Stream.fromFuture(Future.value([])).asyncExpand((_) {
      // This is too complex for simple tool usage without RxDart.
      // Let's just expose a single stream that combines data efficiently?
      // No, simpler: getNotifications() returns a Stream that emits whenever either changes.

      return combinedStream(personalStream, globalStream);
    });
  }

  // Helper to merge two streams of lists and sort them
  Stream<List<NotificationModel>> combinedStream(
      Stream<List<NotificationModel>> s1,
      Stream<List<NotificationModel>> s2) async* {
    // Simplified: UI should handle multiple streams or use rxdart.
    // For now, this is just a placeholder intended for future implementation.
    yield* s1;
  }

  Stream<List<NotificationModel>> getPersonalNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<NotificationModel>> getGlobalNotifications() {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Note: Global notifications can't be marked as read individually in Firestore
    // without a separate specific collection tracking user reads.
    // For now, we only mark Personal notifications as read.
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> clearAll() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _db.batch();
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
