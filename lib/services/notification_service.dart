import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  // FlutterLocalNotifications instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ✅ Initialize Notifications
  Future<void> initNotification() async {
    // Initialize timezones once
    try {
      tz.initializeTimeZones();
      debugPrint("✅ Timezones initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing timezones: $e");
    }

    // Define platform-specific settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    try {
      await flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      debugPrint("✅ Flutter Local Notifications initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing Flutter Local Notifications: $e");
    }

    // Create notification channel for Android
    if (Platform.isAndroid) {
      try {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'aa_readings_channel_id',
          'AA Readings Notifications',
          description: 'Daily reminders for AA readings',
          importance: Importance.max,
          playSound: true,
        );

        // Register the channel with the system
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        debugPrint("✅ Android notification channel created successfully");

        // Check if channel was actually created
        final channels = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.getNotificationChannels();

        debugPrint("📢 Available notification channels: ${channels?.length}");
        channels?.forEach((c) => debugPrint("📢 Channel: ${c.id}, ${c.name}"));
      } catch (e) {
        debugPrint("❌ Error creating Android notification channel: $e");
      }
    }
  }

  // ✅ Schedule a Notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // Convert to timezone-aware datetime
      final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      debugPrint("🕒 Current time: ${DateTime.now()}");
      debugPrint("🕒 Local timezone: ${tz.local.name}");
      debugPrint("📅 Scheduling notification for: $scheduledTime");

      // Define notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'aa_readings_channel_id',
        'AA Readings Notifications',
        channelDescription: 'Daily reminders for AA readings',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body, scheduledTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Changed from exactAllowWhileIdle to alarmClock to comply with Google Play policies
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );

      debugPrint("✅ Notification scheduled successfully for: $scheduledTime");
    } catch (e) {
      debugPrint("❌ Error scheduling notification: $e");
    }
  }

  // Check notification permission status
  Future<bool> checkPermissionStatus() async {
    if (Platform.isAndroid) {
      final status = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return status ?? false;
    } else if (Platform.isIOS) {
      final status = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return status ?? false;
    }
    return false;
  }

  // Cancel a Notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel All Notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // ✅ Schedule Daily Notifications based on user preferences
  Future<void> scheduleDailyNotifications() async {
    try {
      final prefs = await SharedPreferences
          .getInstance(); // Check if notifications are enabled
      final notificationsEnabled =
          prefs.getBool('push_notifications_consent') ??
              true; // Default to true to match UI

      debugPrint("🔍 Notification preference check: $notificationsEnabled");
      debugPrint(
          "🔍 Raw preference value: ${prefs.getBool('push_notifications_consent')}");

      if (!notificationsEnabled) {
        debugPrint(
            "🔕 Notifications disabled by user - canceling all notifications");
        await cancelAllNotifications();
        return;
      }

      // Get notification time preference
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;

      debugPrint(
          "⏰ Setting up daily notifications for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}"); // Cancel existing notifications first
      await cancelAllNotifications(); // Schedule notifications for the next 365 days (1 year)
      for (int i = 0; i < 365; i++) {
        final now = DateTime.now();
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day + i,
          hour,
          minute,
        );

        // If the scheduled time today has already passed, start from tomorrow
        if (i == 0 && scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
          // Don't continue here - we still want to schedule the notification for tomorrow
        }

        await scheduleNotification(
          id: i + 1, // Start from ID 1
          title: "Daily AA Reading",
          body: "Time for your daily AA reading and reflection",
          scheduledDate: scheduledDate,
        );
      }
      debugPrint(
          "✅ Daily notifications scheduled successfully for next 365 days");
    } catch (e) {
      debugPrint("❌ Error scheduling daily notifications: $e");
    }
  }

  // ✅ Get pending notifications count (for debugging)
  Future<int> getPendingNotificationsCount() async {
    try {
      final pending =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint("📋 Pending notifications: ${pending.length}");
      return pending.length;
    } catch (e) {
      debugPrint("❌ Error getting pending notifications: $e");
      return 0;
    }
  }

  // ✅ Check if app has notification permission and show user-friendly message
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      try {
        final android = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (android != null) {
          final granted = await android.requestNotificationsPermission();
          debugPrint("🔔 Android notification permission granted: $granted");
          return granted ?? false;
        }
      } catch (e) {
        debugPrint("❌ Error requesting Android notification permission: $e");
      }
    } else if (Platform.isIOS) {
      try {
        final iOS = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iOS != null) {
          final granted = await iOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint("🔔 iOS notification permission granted: $granted");
          return granted ?? false;
        }
      } catch (e) {
        debugPrint("❌ Error requesting iOS notification permission: $e");
      }
    }
    return false;
  }
}
