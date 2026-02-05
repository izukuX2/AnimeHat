import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newEpisode,
  commentReply,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String relatedId; // AnimeID or CommentID
  final String? secondaryId; // e.g., CommentID for replies
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    this.secondaryId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseType(map['type']),
      relatedId: map['relatedId'] ?? '',
      secondaryId: map['secondaryId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'new_episode':
        return NotificationType.newEpisode;
      case 'comment_reply':
        return NotificationType.commentReply;
      default:
        return NotificationType.general;
    }
  }
}
