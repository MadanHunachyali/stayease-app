import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

// Background message handler for FCM
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Show the notification when the app is in the background
  await NotificationService().showNotification(message);
  print('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Activate Firebase App Check for added security
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Initialize the notification service for handling local notifications
  await NotificationService().init();

  // Firebase Messaging instance for handling FCM
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Requesting permission to send notifications to the device
  NotificationSettings settings = await messaging.requestPermission();
  print('Permission: ${settings.authorizationStatus}');

  // Get the FCM token for the device
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Handle incoming messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Show notification when a message is received while the app is in the foreground
    NotificationService().showNotification(message);
    print('Foreground message: ${message.notification?.title}');
  });

  // Handle when the app is opened via a notification tap (notification click)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification clicked');
    // You can navigate based on the data received from the notification
    // Example: Navigate to a specific screen when the notification is tapped
    // Navigator.pushNamed(context, '/someScreen');
  });

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Run the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
