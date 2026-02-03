import 'package:flutter/material.dart';
import '../../../../core/repositories/post_repository.dart';
import '../../../../core/models/post_model.dart';
import '../../../../core/widgets/interaction_buttons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityView extends StatefulWidget {
  const CommunityView({super.key});

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostRepository _postRepository = PostRepository();
  final categories = ['Global', 'Trending', 'Questions', 'Discussions'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: categories.map((cat) => Tab(text: cat)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories
                  .map((cat) => _buildPostList(cat, isDark))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final contentController = TextEditingController();
    String selectedCategory = 'Global';
    bool isSpoiler = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Post',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      setBottomSheetState(() => selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.spoiler),
                    value: isSpoiler,
                    onChanged: (value) {
                      setBottomSheetState(() => isSpoiler = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Please login first')),
                          );
                          return;
                        }

                        if (contentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please write something'),
                            ),
                          );
                          return;
                        }

                        await _postRepository.addPost(
                          Post(
                            id: '',
                            authorUid: user.uid,
                            authorName:
                                user.displayName ?? user.email ?? 'Anonymous',
                            content: contentController.text.trim(),
                            category: selectedCategory,
                            createdAt: DateTime.now(),
                            likedBy: [],
                            repliesCount: 0,
                            isSpoiler: isSpoiler,
                          ),
                        );

                        if (context.mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Post created!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Post'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostList(String category, bool isDark) {
    return StreamBuilder<List<Post>>(
      stream: _postRepository.getPosts(
        category: category == 'Global' ? null : category,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(child: Text("No posts in '$category' yet."));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(posts[index], isDark);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Post post, bool isDark) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked =
        currentUser != null && post.likedBy.contains(currentUser.uid);
    final canDelete = currentUser != null && post.authorUid == currentUser.uid;

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
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${post.createdAt.day}/${post.createdAt.month} ${post.createdAt.hour}:${post.createdAt.minute}",
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
            _SpoilerContent(
              content: post.content,
              isSpoiler: post.isSpoiler,
              l10n: AppLocalizations.of(context)!,
            ),
            const SizedBox(height: 12),
            InteractionButtons(
              isLiked: isLiked,
              likeCount: post.likedBy.length,
              replyCount: post.repliesCount,
              onLike: () {
                if (currentUser != null) {
                  _postRepository.likePost(post.id, currentUser.uid);
                }
              },
              onReply: () {
                // Open reply dialog or screen (placeholder for now)
              },
              canDelete: canDelete,
              onDelete: () {
                if (currentUser != null) {
                  _postRepository.deletePost(post.id, currentUser.uid);
                }
              },
            ),
          ],
        ),
      ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.l10n.spoiler,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showContent = true),
            child: Text(widget.l10n.showContent),
          ),
        ],
      ),
    );
  }
}
