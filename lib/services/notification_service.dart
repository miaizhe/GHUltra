import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'github_service.dart';
import 'package:flutter/material.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const String fetchBackground = "fetchBackground";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchBackground) {
      await NotificationService.fetchAndNotify();
    }
    return Future.value(true);
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static BuildContext? navigatorKey;

  Future<void> init() async {
    if (Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            _handleNotificationTap(response.payload!);
          }
        },
      );

      Workmanager().initialize(
        callbackDispatcher,
      );
      
      // Register periodic task every 15 minutes
      Workmanager().registerPeriodicTask(
        "ghultra_fetch_notifications",
        fetchBackground,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } else if (Platform.isWindows) {
      await localNotifier.setup(
        appName: 'GHUltra',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      // Polling timer for windows while app is open
      Timer.periodic(const Duration(minutes: 2), (timer) {
        fetchAndNotify();
      });
    }
  }

  static Future<void> fetchAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('github_token');
      if (token == null || token.isEmpty) return;

      final service = GitHubService(token);
      final notifications = await service.getNotifications();
      
      if (notifications.isEmpty) return;

      final lastIdStr = prefs.getString('last_notif_id');
      final lastId = lastIdStr != null ? int.tryParse(lastIdStr) ?? 0 : 0;
      
      int maxId = lastId;

      for (var notif in notifications) {
        int notifId = int.tryParse(notif['id'].toString()) ?? 0;
        if (notifId > lastId) {
          _showNotification(notif);
          if (notifId > maxId) {
            maxId = notifId;
          }
        }
      }

      if (maxId > lastId) {
        prefs.setString('last_notif_id', maxId.toString());
      }
    } catch (e) {
      debugPrint("Background fetch failed: $e");
    }
  }

  static Future<void> _showNotification(dynamic notif) async {
    int id = int.tryParse(notif['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String title = notif['subject']['title'] ?? 'New GitHub Notification';
    String body = notif['repository']['full_name'] ?? '';

    String payload = jsonEncode({
      'type': notif['subject']['type'],
      'url': notif['subject']['url'],
      'html_url': notif['subject']['url'], 
      'repo_full_name': notif['repository']['full_name'],
    });

    if (Platform.isAndroid) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'ghultra_notifications',
        'GitHub Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } else if (Platform.isWindows) {
      LocalNotification notification = LocalNotification(
        title: title,
        body: body,
      );
      notification.onClick = () {
        NotificationService()._handleNotificationTap(payload);
      };
      notification.show();
    }
  }

  void _handleNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload);
      NotificationStream.stream.add(data);
    } catch (e) {
      debugPrint("Error parsing payload: $e");
    }
  }
}

class NotificationStream {
  static final stream = StreamController<Map<String, dynamic>>.broadcast();
}
