import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String category; // e.g., "Trending", "Discussion", "News"
  final DateTime createdAt;
  final List<String> likedBy;
  final int repliesCount;

  Post({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.category,
    required this.createdAt,
    this.likedBy = const [],
    this.repliesCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': likedBy,
      'repliesCount': repliesCount,
    };
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      category: data['category'] ?? 'General',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      repliesCount: data['repliesCount'] ?? 0,
    );
  }
}
