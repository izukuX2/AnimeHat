import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/repositories/post_repository.dart';
import '../../../../core/repositories/comment_repository.dart';
import '../../../../core/models/post_model.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/widgets/interaction_buttons.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
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
  bool _isSpoiler = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final user = _auth.currentUser;
    if (user == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginToPost)));
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
          authorName:
              user.displayName ?? AppLocalizations.of(context)!.anonymous,
          authorPhotoUrl: user.photoURL,
          content: _postController.text.trim(),
          animeId: widget.animeId!,
          createdAt: DateTime.now(),
          isSpoiler: _isSpoiler,
        );
        await _commentRepository.addComment(comment);
      } else {
        // Create Post
        final post = Post(
          id: '',
          authorUid: user.uid,
          authorName:
              user.displayName ?? AppLocalizations.of(context)!.anonymous,
          authorPhotoUrl: user.photoURL,
          content: _postController.text.trim(),
          category: 'Discussion',
          createdAt: DateTime.now(),
          isSpoiler: _isSpoiler,
        );
        await _postRepository.addPost(post);
      }

      _postController.clear();
      setState(() => _isSpoiler = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.postedSuccessfully)));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${l10n.errorPrefix}: $e")));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.animeTitle != null
              ? "${widget.animeTitle} ${l10n.clubSuffix}"
              : l10n.community,
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
    final l10n = AppLocalizations.of(context)!;
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postController,
                  decoration: InputDecoration(
                    hintText: l10n.postHint,
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
                      icon: const Icon(LucideIcons.send),
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _isSpoiler,
                onChanged: (val) => setState(() => _isSpoiler = val ?? false),
                activeColor: AppColors.primary,
              ),
              Text(l10n.spoiler, style: const TextStyle(fontSize: 14)),
            ],
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
          final l10n = AppLocalizations.of(context)!;
          if (comments.isEmpty) {
            return Center(child: Text(l10n.noComments));
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
          final l10n = AppLocalizations.of(context)!;
          if (posts.isEmpty) {
            return Center(child: Text(l10n.noPosts));
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
                      ? const Icon(LucideIcons.user, color: Colors.white)
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
            const SizedBox(height: 12),
            _SpoilerContent(
              content: item.content,
              isSpoiler: item.isSpoiler,
              l10n: AppLocalizations.of(context)!,
            ),
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
                final l10n = AppLocalizations.of(context)!;
                if (currentUser == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.loginToReply)));
                  return;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.repliesSoon)));
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.replyLabel),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.replyHint),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
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
                    authorName: user.displayName ?? l10n.anonymous,
                    authorPhotoUrl: user.photoURL,
                    content: text,
                    animeId: parentComment.animeId, // Inherit animeId
                    parentId: parentComment.id,
                    createdAt: DateTime.now(),
                  );
                  try {
                    await _commentRepository.addComment(reply);
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.replyAdded)));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${l10n.errorPrefix}: $e")),
                      );
                    }
                  }
                }
              },
              child: Text(l10n.replyLabel),
            ),
          ],
        );
      },
    );
  }
}

class _SpoilerContent extends StatefulWidget {
  final String content;
  final bool isSpoiler;
  final AppLocalizations l10n;

  const _SpoilerContent({
    required this.content,
    required this.isSpoiler,
    required this.l10n,
  });

  @override
  State<_SpoilerContent> createState() => _SpoilerContentState();
}

class _SpoilerContentState extends State<_SpoilerContent> {
  late bool _showContent;

  @override
  void initState() {
    super.initState();
    _showContent = !widget.isSpoiler;
  }

  @override
  Widget build(BuildContext context) {
    if (_showContent) {
      return Text(widget.content);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _showContent = true),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.eyeOff, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.l10n.spoiler,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.l10n.showContent,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }
}
