import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Abstract service for local notifications.
/// Currently implemented as a stub using SnackBar/Console.
/// Can be extended with flutter_local_notifications for real alerts.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Get Token (for debugging or specific targeting)
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Sync with User Profile if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await UserRepository().updateFcmToken(user.uid, token);
    }

    // Listens for token refreshes
    _fcm.onTokenRefresh.listen((newToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await UserRepository().updateFcmToken(currentUser.uid, newToken);
      }
    });

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        // Optional: Show in-app overlay or snackbar using navigatorKey.currentContext
        if (navigatorKey.currentContext != null) {
          showImmediateNotification(
            navigatorKey.currentContext!,
            message.notification?.title ?? 'Notification',
            message.notification?.body ?? '',
          );
        }
      }
    });

    // 4. Handle Background/Terminated Tap
    await setupInteractedMessage();

    // 5. Subscribe to default topic
    await subscribeToTopic('all');
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'new_episode') {
      // Navigate to Notifications Screen or directly to content if possible
      // For now, go to Notifications Screen which lists it
      navigatorKey.currentState?.pushNamed('/notifications');
    } else if (message.data['type'] == 'comment_reply') {
      navigatorKey.currentState?.pushNamed('/notifications');
    } else {
      // Default
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint('Subscribed to $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from $topic');
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
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/notifications');
          },
        ),
      ),
    );
  }
}
