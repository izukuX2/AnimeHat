import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/repositories/comment_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/interaction_buttons.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final Function(String) onLike;

  const CommentItem({
    super.key,
    required this.comment,
    this.onReply,
    this.onDelete,
    required this.onLike,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showReplies = false;
  List<Comment> _replies = [];
  bool _loadingReplies = false;
  final CommentRepository _repository = CommentRepository();

  Future<void> _toggleReplies() async {
    if (_showReplies) {
      setState(() => _showReplies = false);
      return;
    }

    setState(() {
      _showReplies = true;
      _loadingReplies = true;
    });

    try {
      final stream = _repository.getComments(
        animeId: widget.comment.animeId,
        parentId: widget.comment.id,
      );
      stream.listen((replies) {
        if (mounted) {
          setState(() {
            _replies = replies;
            _loadingReplies = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingReplies = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked =
        currentUser != null && widget.comment.likedBy.contains(currentUser.uid);
    final canDelete =
        currentUser != null && widget.comment.authorUid == currentUser.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  backgroundImage: widget.comment.authorPhotoUrl != null
                      ? NetworkImage(widget.comment.authorPhotoUrl!)
                      : null,
                  child: widget.comment.authorPhotoUrl == null
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(widget.comment.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.comment.content),
            const SizedBox(height: 8),
            Row(
              children: [
                InteractionButtons(
                  isLiked: isLiked,
                  likeCount: widget.comment.likedBy.length,
                  replyCount: widget.comment.repliesCount,
                  onLike: () => widget.onLike(widget.comment.id),
                  onReply: widget.onReply,
                  canDelete: canDelete,
                  onDelete: widget.onDelete,
                ),
                if (widget.comment.repliesCount > 0)
                  TextButton(
                    onPressed: _toggleReplies,
                    child: Text(
                      _showReplies ? "Hide Replies" : "View Replies",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (_showReplies) ...[
              const Divider(),
              if (_loadingReplies)
                const Center(child: CircularProgressIndicator())
              else
                ..._replies.map(
                  (reply) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4),
                    child: CommentItem(
                      comment: reply,
                      onLike: widget.onLike,
                      onReply: null, // Limit nesting depth? Or allow infinite?
                      onDelete: null, // Simplify for now
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
