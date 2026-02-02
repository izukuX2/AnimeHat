import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String animeId;
  final String? episodeNumber; // Null for anime-level comments
  final String? parentId; // For replies
  final DateTime createdAt;
  final List<String> likedBy;
  final int repliesCount;

  Comment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.animeId,
    this.episodeNumber,
    this.parentId,
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
      'animeId': animeId,
      'episodeNumber': episodeNumber,
      'parentId': parentId,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': likedBy,
      'repliesCount': repliesCount,
    };
  }

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      animeId: data['animeId'] ?? '',
      episodeNumber: data['episodeNumber'],
      parentId: data['parentId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      repliesCount: data['repliesCount'] ?? 0,
    );
  }
}
