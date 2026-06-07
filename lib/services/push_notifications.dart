// =============================================================
// PUSH NOTIFICATIONS (#8)
// System-tray notifications via Firebase Cloud Messaging (FCM)
// + flutter_local_notifications.
//
// Tiers of delivery:
//   - App in FOREGROUND  -> onMessage -> shown via local notifications
//   - App in BACKGROUND  -> the OS shows the FCM notification itself
//   - App KILLED / phone was OFF -> delivered by FCM on reconnect
//
// REQUIRES Firebase setup (see PUSH_SETUP.md):
//   - android/app/google-services.json
//   - iOS APNs key + GoogleService-Info.plist
//   - pubspec deps: firebase_core, firebase_messaging,
//     flutter_local_notifications
// =============================================================
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Must be a top-level function (firebase_messaging requirement).
@pragma('vm:entry-point')
Future<void> firebaseBgHandler(RemoteMessage message) async {
  // When the app is backgrounded or killed, the OS renders the
  // notification from the FCM payload automatically. Nothing needed here
  // unless you want to process data-only messages.
}

class PushNotifications {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tickety_important',
    'Tickety alerts',
    description: 'Ticket calls and swap requests',
    importance: Importance.high,
  );

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Call once after Firebase.initializeApp() and after the user has logged
  /// in (so we know which user owns this device).
  static Future<void> init({required String userId}) async {
    final messaging = FirebaseMessaging.instance;

    // 1) Permission (iOS + Android 13+).
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2) Local-notification plugin (renders FCM messages while foregrounded).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3) Register this device's FCM token with the backend.
    final token = await messaging.getToken();
    if (token != null) {
      await ApiService().registerDeviceToken(
        userId: userId, token: token, platform: _platform);
    }
    messaging.onTokenRefresh.listen((t) {
      ApiService().registerDeviceToken(
        userId: userId, token: t, platform: _platform);
    });

    // 4) Foreground messages -> show in the tray (OS handles bg/killed).
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title ?? 'Tickety',
        n.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }
}