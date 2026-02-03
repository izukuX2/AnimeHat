import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Service for sharing content to social media and other platforms
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Base URL for deep links
  static const String _baseUrl = 'https://animehat.app';

  /// Share an anime
  Future<void> shareAnime({
    required String animeId,
    required String title,
    String? imageUrl,
    String? synopsis,
    Rect? sharePositionOrigin,
  }) async {
    final url = '$_baseUrl/anime/$animeId';
    final text =
        '🎬 Check out "$title" on AnimeHat!\n\n'
        '${synopsis != null ? "${synopsis.length > 100 ? '${synopsis.substring(0, 100)}...' : synopsis}\n\n" : ""}'
        '$url';

    await Share.share(
      text,
      subject: 'Watch $title on AnimeHat',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share an episode
  Future<void> shareEpisode({
    required String animeId,
    required String episodeNumber,
    required String animeTitle,
    Rect? sharePositionOrigin,
  }) async {
    final url = '$_baseUrl/anime/$animeId/episode/$episodeNumber';
    final text =
        '🎬 Watch "$animeTitle" Episode $episodeNumber on AnimeHat!\n\n$url';

    await Share.share(
      text,
      subject: '$animeTitle - Episode $episodeNumber',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share user profile
  Future<void> shareProfile({
    required String userId,
    required String username,
    Rect? sharePositionOrigin,
  }) async {
    final url = '$_baseUrl/user/$userId';
    final text =
        '👤 Check out $username\'s anime collection on AnimeHat!\n\n$url';

    await Share.share(
      text,
      subject: '$username on AnimeHat',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share a post from community
  Future<void> sharePost({
    required String postId,
    required String authorName,
    String? content,
    Rect? sharePositionOrigin,
  }) async {
    final url = '$_baseUrl/community/post/$postId';
    final previewContent = content != null && content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
    final text =
        '💬 $authorName on AnimeHat:\n\n'
        '${previewContent != null ? '"$previewContent"\n\n' : ""}'
        '$url';

    await Share.share(
      text,
      subject: 'Post by $authorName - AnimeHat',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share app download link
  Future<void> shareApp({Rect? sharePositionOrigin}) async {
    const text =
        '🎬 AnimeHat - Your Ultimate Anime Companion!\n\n'
        'Stream thousands of anime, track your progress, and join the community.\n\n'
        'Download now: $_baseUrl/download';

    await Share.share(
      text,
      subject: 'AnimeHat - Anime Streaming App',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Copy link to clipboard
  Future<void> copyLink({
    required BuildContext context,
    required String url,
    String? successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: url));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? 'Link copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Generate shareable anime card image (placeholder for future implementation)
  Future<String?> generateShareCard({
    required String animeTitle,
    required String imageUrl,
    String? rating,
    String? status,
  }) async {
    // TODO: Implement image generation using a canvas or external service
    // For now, return null to indicate image generation is not available
    return null;
  }
}

/// Widget for share button with popup menu
class ShareButton extends StatelessWidget {
  final VoidCallback? onShare;
  final VoidCallback? onCopyLink;
  final Color? iconColor;
  final double iconSize;

  const ShareButton({
    super.key,
    this.onShare,
    this.onCopyLink,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.share_outlined, color: iconColor, size: iconSize),
      onSelected: (value) {
        switch (value) {
          case 'share':
            onShare?.call();
            break;
          case 'copy':
            onCopyLink?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [Icon(Icons.share), SizedBox(width: 12), Text('Share')],
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy),
              SizedBox(width: 12),
              Text('Copy Link'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quick share floating action button
class QuickShareFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;

  const QuickShareFab({super.key, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip ?? 'Share',
      child: const Icon(Icons.share),
    );
  }
}
