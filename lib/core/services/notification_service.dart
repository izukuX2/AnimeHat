import 'package:flutter/material.dart';

/// Abstract service for local notifications.
/// Currently implemented as a stub using SnackBar/Console.
/// Can be extended with flutter_local_notifications for real alerts.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Schedule a notification for an upcoming anime episode
  Future<void> scheduleEpisodeAlert({
    required String animeId,
    required String title,
    required DateTime scheduledTime,
  }) async {
    // Logic to calculate duration until alert
    final diff = scheduledTime.difference(DateTime.now());

    if (diff.isNegative) {
      print("Cannot schedule alert for past event: $title");
      return;
    }

    print(
      "ALERT SCHEDULED: '$title' at $scheduledTime (In ${diff.inHours}h ${diff.inMinutes % 60}m)",
    );

    // In a real implementation with flutter_local_notifications:
    // await _plugin.zonedSchedule(
    //   animeId.hashCode,
    //   "New Episode Airing!",
    //   "$title is about to start.",
    //   tz.TZDateTime.from(scheduledTime, tz.local),
    //   ...
    // );
  }

  /// Cancel all alerts for a specific anime
  Future<void> cancelAlerts(String animeId) async {
    print("ALERTS CANCELLED for: $animeId");
  }

  /// Check if an alert is already scheduled
  Future<bool> isAlertScheduled(String animeId) async {
    // Stub logic
    return false;
  }

  /// Show a simple immediate notification (wrapper for platform/plugin)
  void showImmediateNotification(
    BuildContext context,
    String title,
    String body,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
