import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InteractionButtons extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int replyCount;
  final VoidCallback onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final bool canDelete;

  const InteractionButtons({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.replyCount,
    required this.onLike,
    this.onReply,
    this.onDelete,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final activeColor = Colors.redAccent;

    return Row(
      children: [
        // Like Button
        InkWell(
          onTap: onLike,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isLiked ? LucideIcons.heart : LucideIcons.heart,
                  size: 18,
                  color: isLiked ? activeColor : iconColor,
                ),
                const SizedBox(width: 4),
                Text(
                  "$likeCount",
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Reply Button
        InkWell(
          onTap: onReply,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(LucideIcons.messageCircle, size: 18, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  "$replyCount",
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (canDelete && onDelete != null) ...[
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18),
            color: Colors.redAccent.withValues(alpha: 0.8),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }
}
