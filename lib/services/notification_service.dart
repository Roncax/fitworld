import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

// Handle background messages (top-level function required by FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are shown automatically by the system on Android.
  // Nothing to do here for now.
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirestoreService _firestore;

  NotificationService(this._firestore);

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+ and iOS)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Setup local notifications (for foreground display on Android)
    await _setupLocalNotifications();

    // Get FCM token and persist it so Cloud Functions can send notifications
    final token = await _fcm.getToken();
    if (token != null) {
      await _firestore.saveFcmToken(token);
    }

    // Refresh token when it rotates
    _fcm.onTokenRefresh.listen((newToken) {
      _firestore.saveFcmToken(newToken);
    });

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    // Create notification channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'fitworld_decay',
          'Salute personaggi',
          description: 'Avvisi quando i personaggi stanno per morire',
          importance: Importance.high,
        ));

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'fitworld_events',
          'Eventi mondo',
          description: 'Notifiche nascita personaggi e altri eventi',
          importance: Importance.defaultImportance,
        ));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final channelId =
        message.notification?.android?.channelId ?? 'fitworld_events';

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'fitworld_decay' ? 'Salute personaggi' : 'Eventi mondo',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
