import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addComment(Comment comment) async {
    await _db.collection('comments').add(comment.toMap());

    if (comment.parentId != null) {
      // 1. Increment replies count on parent
      final parentRef = _db.collection('comments').doc(comment.parentId);
      await parentRef.update({'repliesCount': FieldValue.increment(1)});

      // 2. Notify Parent Author (Client-Side Logic)
      try {
        final parentSnapshot = await parentRef.get();
        if (parentSnapshot.exists) {
          final parentData = parentSnapshot.data();
          final targetUid = parentData?['authorUid'];

          if (targetUid != null && targetUid != comment.authorUid) {
            await _db
                .collection('users')
                .doc(targetUid)
                .collection('notifications')
                .add({
              'title': 'New Reply',
              'body': '${comment.authorName} replied to your comment.',
              'type': 'comment_reply',
              'relatedId': comment.animeId,
              'secondaryId':
                  comment.parentId, // Link to the parent comment thread
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
        }
      } catch (e) {
        debugPrint('Error sending notification: $e');
        // Non-blocking error
      }
    }
  }

  Stream<List<Comment>> getComments({
    String? animeId,
    String? episodeNumber,
    String? parentId,
  }) {
    Query query =
        _db.collection('comments').orderBy('createdAt', descending: true);

    if (animeId != null) {
      query = query.where('animeId', isEqualTo: animeId);
    }

    if (episodeNumber != null) {
      query = query.where('episodeNumber', isEqualTo: episodeNumber);
    } else if (animeId != null && parentId == null) {
      // Ensure we only get top-level comments for the anime if no episode or parent is specified
      query = query.where('episodeNumber', isNull: true);
    }

    if (parentId != null) {
      query = query.where('parentId', isEqualTo: parentId);
    } else {
      query = query.where('parentId', isNull: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  Future<void> toggleLike(String commentId, String uid) async {
    final commentDoc = _db.collection('comments').doc(commentId);
    final doc = await commentDoc.get();

    if (doc.exists) {
      final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
      if (likedBy.contains(uid)) {
        await commentDoc.update({
          'likedBy': FieldValue.arrayRemove([uid]),
        });
      } else {
        await commentDoc.update({
          'likedBy': FieldValue.arrayUnion([uid]),
        });
      }
    }
  }

  Future<void> deleteComment(String commentId, String uid) async {
    final commentDoc = _db.collection('comments').doc(commentId);
    final doc = await commentDoc.get();

    if (doc.exists && doc.data()?['authorUid'] == uid) {
      final parentId = doc.data()?['parentId'];
      await commentDoc.delete();

      if (parentId != null) {
        await _db.collection('comments').doc(parentId).update({
          'repliesCount': FieldValue.increment(-1),
        });
      }
    }
  }
}
