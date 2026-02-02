import 'package:flutter/material.dart';
import '../../../../core/repositories/post_repository.dart';
import '../../../../core/repositories/comment_repository.dart';
import '../../../../core/models/post_model.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/widgets/interaction_buttons.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/comment_item.dart';

class CommunityScreen extends StatefulWidget {
  final String? animeId;
  final String? animeTitle;

  const CommunityScreen({super.key, this.animeId, this.animeTitle});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final PostRepository _postRepository = PostRepository();
  final CommentRepository _commentRepository = CommentRepository();
  final AuthRepository _auth = AuthRepository();
  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login to post")));
      return;
    }

    if (_postController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    try {
      if (widget.animeId != null) {
        // Create Comment
        final comment = Comment(
          id: '',
          authorUid: user.uid,
          authorName: user.displayName ?? "Anonymous",
          authorPhotoUrl: user.photoURL,
          content: _postController.text.trim(),
          animeId: widget.animeId!,
          createdAt: DateTime.now(),
        );
        await _commentRepository.addComment(comment);
      } else {
        // Create Post
        await _postRepository.createPost(
          user.uid,
          user.displayName ?? "Anonymous",
          user.photoURL,
          _postController.text.trim(),
          'Discussion',
        );
      }

      _postController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Posted successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.animeTitle != null ? "${widget.animeTitle} Club" : "Community",
        ),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
      ),
      body: Column(
        children: [
          _buildPostInput(isDark),
          Expanded(child: _buildPostsList(isDark)),
        ],
      ),
    );
  }

  Widget _buildPostInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          _isPosting
              ? const CircularProgressIndicator()
              : IconButton(
                  onPressed: _submitPost,
                  icon: const Icon(Icons.send),
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
        ],
      ),
    );
  }

  Widget _buildPostsList(bool isDark) {
    if (widget.animeId != null) {
      return StreamBuilder<List<Comment>>(
        stream: _commentRepository.getComments(animeId: widget.animeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final comments = snapshot.data ?? [];
          if (comments.isEmpty) {
            return const Center(child: Text("No comments yet."));
          }
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) =>
                _buildItemCard(comments[index], isDark),
          );
        },
      );
    } else {
      return StreamBuilder<List<Post>>(
        stream: _postRepository.getPosts(category: 'Discussion'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text("No posts yet."));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) =>
                _buildItemCard(posts[index], isDark),
          );
        },
      );
    }
  }

  Widget _buildItemCard(dynamic item, bool isDark) {
    if (item is Comment) {
      return CommentItem(
        comment: item,
        onLike: (id) => _commentRepository.toggleLike(
          id,
          FirebaseAuth.instance.currentUser!.uid,
        ),
        onReply: () => _showReplyDialog(item),
        onDelete: () => _commentRepository.deleteComment(
          item.id,
          FirebaseAuth.instance.currentUser!.uid,
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked =
        currentUser != null && item.likedBy.contains(currentUser.uid);
    final canDelete = currentUser != null && item.authorUid == currentUser.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  backgroundImage: item.authorPhotoUrl != null
                      ? NetworkImage(item.authorPhotoUrl!)
                      : null,
                  child: item.authorPhotoUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${item.createdAt.day}/${item.createdAt.month} ${item.createdAt.hour}:${item.createdAt.minute}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.content),
            const SizedBox(height: 12),
            InteractionButtons(
              isLiked: isLiked,
              likeCount: item.likedBy.length,
              replyCount: item.repliesCount,
              onLike: () {
                if (currentUser == null) return;
                _postRepository.likePost(item.id, currentUser.uid);
              },
              onReply: () {
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please login to reply")),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Replies to posts coming soon!"),
                  ),
                );
              },
              canDelete: canDelete,
              onDelete: () {
                if (currentUser == null) return;
                _postRepository.deletePost(item.id, currentUser.uid);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(Comment parentComment) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reply"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Write a reply..."),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context);
                  final user = FirebaseAuth.instance.currentUser!;
                  final reply = Comment(
                    id: '', // Generated by Repo
                    authorUid: user.uid,
                    authorName: user.displayName ?? "Anonymous",
                    authorPhotoUrl: user.photoURL,
                    content: text,
                    animeId: parentComment.animeId, // Inherit animeId
                    parentId: parentComment.id,
                    createdAt: DateTime.now(),
                  );
                  try {
                    await _commentRepository.addComment(reply);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reply added!")),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                }
              },
              child: const Text("Reply"),
            ),
          ],
        );
      },
    );
  }
}
