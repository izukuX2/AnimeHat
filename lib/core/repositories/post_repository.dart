import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createPost(
    String uid,
    String authorName,
    String? authorPhotoUrl,
    String content,
    String category,
  ) async {
    final post = Post(
      id: '', // Firestore will generate this
      authorUid: uid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      category: category,
      createdAt: DateTime.now(),
    );

    await _db.collection('posts').add(post.toMap());
  }

  /// Add a new post directly from a Post object
  Future<void> addPost(Post post) async {
    await _db.collection('posts').add(post.toMap());
  }

  Stream<List<Post>> getPosts({String? category}) {
    Query query = _db
        .collection('posts')
        .orderBy('createdAt', descending: true);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  Future<void> likePost(String postId, String uid) async {
    final postDoc = _db.collection('posts').doc(postId);
    final doc = await postDoc.get();

    if (doc.exists) {
      final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
      if (likedBy.contains(uid)) {
        await postDoc.update({
          'likedBy': FieldValue.arrayRemove([uid]),
        });
      } else {
        await postDoc.update({
          'likedBy': FieldValue.arrayUnion([uid]),
        });
      }
    }
  }

  Future<void> deletePost(String postId, String uid) async {
    final postDoc = _db.collection('posts').doc(postId);
    final doc = await postDoc.get();

    if (doc.exists && doc.data()?['authorUid'] == uid) {
      await postDoc.delete();
    }
  }

  Future<void> incrementReplyCount(String postId) async {
    await _db.collection('posts').doc(postId).update({
      'repliesCount': FieldValue.increment(1),
    });
  }
}
