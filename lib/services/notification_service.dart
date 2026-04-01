import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Initialize the awesome notifications plugin
  Future<void> init() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon', // Your app icon
      [
        NotificationChannel(
          channelKey: 'pg_notifications_channel',
          channelName: 'PG Notifications',
          channelDescription: 'Notifications for PG updates',
        ),
      ],
    );
  }

  // Show a notification
  Future<void> showNotification(RemoteMessage message) async {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'pg_notifications_channel',
        title: message.notification?.title ?? 'No Title',
        body: message.notification?.body ?? 'No Body',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
