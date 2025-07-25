import 'dart:ui';

import 'package:dailydime/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permission for Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap here
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showTransactionNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Notifications for financial transactions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleWeeklySummaryNotification(DateTime scheduledDate) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'weekly_summary_channel',
      'Weekly Summary',
      channelDescription: 'Weekly financial summary notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Weekly Financial Summary',
      'Your spending summary for this week is ready',
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> showBudgetAlert(String category, double amount, double limit) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_alerts_channel',
      'Budget Alerts',
      channelDescription: 'Notifications for budget limit alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
      'Budget Alert: $category',
      'You\'ve spent \${amount.toStringAsFixed(2)} out of \${limit.toStringAsFixed(2)}',
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleRecurringReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required DateTimeComponents dateTimeComponents,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'recurring_reminders_channel',
      'Recurring Reminders',
      channelDescription: 'Recurring financial reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: dateTimeComponents,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    return false;
  }

  Future<void> showGoalCompletedNotification(String goalId, String goalTitle) async {
  await _flutterLocalNotificationsPlugin.show(
    goalId.hashCode,
    'Goal Completed! 🎉',
    'Congratulations! You\'ve reached your savings goal for "$goalTitle"',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'savings_channel',
        'Savings Goals',
        channelDescription: 'Notifications for savings goals',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF26D07C),
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

Future<void> showGoalMilestoneNotification(String goalId, String goalTitle, int percentage) async {
  await _flutterLocalNotificationsPlugin.show(
    goalId.hashCode + percentage,
    'Milestone Reached! 🏆',
    'You\'ve reached $percentage% of your "$goalTitle" savings goal',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'savings_channel',
        'Savings Goals',
        channelDescription: 'Notifications for savings goals',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF26D07C),
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

Future<void> scheduleWeeklyGoalReminder(
  String goalId,
  String goalTitle,
  double targetAmount,
  double currentAmount,
  DateTime targetDate,
) async {
  final tz.TZDateTime scheduledDate = _nextInstanceOfDayTime(
    DateTime.sunday,
    const TimeOfDay(hour: 10, minute: 0),
  );
  
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    goalId.hashCode + 1000,
    'Weekly Savings Reminder',
    'You\'ve saved ${((currentAmount / targetAmount) * 100).toInt()}% of your "$goalTitle" goal. Keep going!',
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'savings_channel',
        'Savings Goals',
        channelDescription: 'Notifications for savings goals',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF26D07C),
        icon: '@mipmap/ic_launcher',
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

Future<void> scheduleDailyGoalReminder(
  String goalId,
  String goalTitle,
  double targetAmount,
  double currentAmount,
  DateTime targetDate,
) async {
  final tz.TZDateTime scheduledDate = _nextInstanceOfTime(
    const TimeOfDay(hour: 19, minute: 0),
  );
  
  final daysLeft = targetDate.difference(DateTime.now()).inDays;
  final amountLeft = targetAmount - currentAmount;
  
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    goalId.hashCode + 2000,
    'Goal Deadline Approaching',
    'Only $daysLeft days left to save ${AppConfig.formatCurrency(amountLeft.toInt() * 100)} for your "$goalTitle" goal',
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'savings_channel',
        'Savings Goals',
        channelDescription: 'Notifications for savings goals',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF26D07C),
        icon: '@mipmap/ic_launcher',
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> scheduleGoalDeadlineReminder(
  String goalId,
  String goalTitle,
  double targetAmount,
  double currentAmount,
) async {
  final tz.TZDateTime scheduledDate = _nextInstanceOfTime(
    const TimeOfDay(hour: 9, minute: 0),
  );
  
  final amountLeft = targetAmount - currentAmount;
  
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    goalId.hashCode + 3000,
    'Goal Deadline Tomorrow',
    'Your "$goalTitle" goal deadline is tomorrow! You still need to save ${AppConfig.formatCurrency(amountLeft.toInt() * 100)}',
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'savings_channel',
        'Savings Goals',
        channelDescription: 'Notifications for savings goals',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF26D07C),
        icon: '@mipmap/ic_launcher',
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

Future<void> cancelNotificationsForGoal(String goalId) async {
  await _flutterLocalNotificationsPlugin.cancel(goalId.hashCode);
  await _flutterLocalNotificationsPlugin.cancel(goalId.hashCode + 1000);
  await _flutterLocalNotificationsPlugin.cancel(goalId.hashCode + 2000);
  await _flutterLocalNotificationsPlugin.cancel(goalId.hashCode + 3000);
  // Cancel milestone notifications too
  await _flutterLocalNotificationsPlugin.cancel(goalId.hashCode + 25);
  await _flutterLocalNotificationsPlugin.cancel(goalId.hashCode + 50);
  await _flutterLocalNotificationsPlugin.cancel(goalId.hashCode + 75);
}

tz.TZDateTime _nextInstanceOfDayTime(int day, TimeOfDay time) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  
  while (scheduledDate.weekday != day) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 7));
  }
  
  return scheduledDate;
}

tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  
  return scheduledDate;
}
}