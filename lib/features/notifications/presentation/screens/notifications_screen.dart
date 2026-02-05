import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/repositories/notification_repository.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_manager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repository = NotificationRepository();
  List<NotificationModel> _personal = [];
  List<NotificationModel> _global = [];
  bool _isLoading = true;
  StreamSubscription? _personalSub;
  StreamSubscription? _globalSub;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _personalSub = _repository.getPersonalNotifications().listen((data) {
      if (mounted) {
        setState(() {
          _personal = data;
          _isLoading = false;
        });
      }
    });

    _globalSub = _repository.getGlobalNotifications().listen((data) {
      if (mounted) {
        setState(() {
          _global = data;
          // If personal is empty, loading might depend on this too?
          // Just let _isLoading be false if either returns or fails.
          if (_personal.isEmpty) _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _personalSub?.cancel();
    _globalSub?.cancel();
    super.dispose();
  }

  List<NotificationModel> get _sortedNotifications {
    final combined = [..._personal, ..._global];
    // Remove duplicates if any (though types differ usually)
    // Sort by date descending
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _sortedNotifications;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              // Only clears/marks personal for now as Global are read-only streams usually
              // Implement if needed
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear history',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Clear Notifications?'),
                  content: const Text(
                    'This will remove all your personal notifications.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _repository.clearAll();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                    );
                  },
                ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead &&
        notification.type == NotificationType.commentReply) {
      _repository.markAsRead(notification.id);
    }

    switch (notification.type) {
      case NotificationType.newEpisode:
        // Navigate to Anime Details or Player
        // We need an Anime object. Since we only have ID, we might need to fetch it
        // OR navigate to a route that fetches it.
        // Assuming we have a route that handles ID or fetch.
        // For now, let's try to navigate to /anime-details if we can fetch,
        // but cleaner is to have a "Loading" intermediate or fetch here.
        // Let's just show a SnackBar for "Not Implemented" for ID-only nav unless
        // we implement a designated route handler.

        // Actually, we can use the 'anime_details_screen' but it requires an 'Anime' object.
        // We really need a 'fetchAnime(id)' in a provider/repo.
        // Since I don't want to overcomplicate, I will leave a TODO or check if HomeRepository has it.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Anime... (Implementation Pending)'),
          ),
        );
        break;

      case NotificationType.commentReply:
        // Navigate to the comment section (Anime Details -> Comments)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Reply... (Implementation Pending)'),
          ),
        );
        break;

      default:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead ||
        notification.type ==
            NotificationType
                .newEpisode; // Global assumed read or highlighted differently

    return Container(
      color: isRead ? null : theme.colorScheme.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIconColor(theme),
          child: Icon(_getIcon(), color: Colors.white, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(notification.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.newEpisode:
        return Icons.play_circle_fill_outlined;
      case NotificationType.commentReply:
        return Icons.reply;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (notification.type) {
      case NotificationType.newEpisode:
        return Colors.redAccent;
      case NotificationType.commentReply:
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
