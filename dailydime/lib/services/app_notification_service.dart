// lib/services/app_notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailydime/models/app_notification.dart';
import 'package:dailydime/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class AppNotificationService extends ChangeNotifier {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  static const String _boxName = 'app_notifications';
  Box<AppNotification>? _notificationBox;
  final Uuid _uuid = const Uuid();
  bool _initialized = false;
  bool get initialized => _initialized;

  // Stream controller for real-time updates
  final StreamController<List<AppNotification>> _notificationsController = 
      StreamController<List<AppNotification>>.broadcast();
  
  Stream<List<AppNotification>> get notificationsStream => _notificationsController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(AppNotificationAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(NotificationTypeAdapter());
      }
      
      _notificationBox = await Hive.openBox<AppNotification>(_boxName);
      
      _initialized = true;
      _broadcastNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AppNotificationService: $e');
    }
  }

  List<AppNotification> get allNotifications {
    if (_notificationBox == null || !_initialized) return [];
    return _notificationBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<AppNotification> get unreadNotifications {
    return allNotifications.where((n) => !n.isRead).toList();
  }

  int get unreadCount => unreadNotifications.length;

  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? actionData,
    bool showSystemNotification = true,
  }) async {
    if (_notificationBox == null) await initialize();

    final notification = AppNotification(
      id: _uuid.v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      data: data,
      actionData: actionData,
    );

    await _notificationBox!.add(notification);
    
    // Show system notification if enabled
    if (showSystemNotification) {
      await NotificationService().showTransactionNotification(title, body);
    }

    _broadcastNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    if (_notificationBox == null || !_initialized) return;

    final notifications = _notificationBox!.values.where((n) => n.id == notificationId);
    if (notifications.isNotEmpty) {
      final notification = notifications.first;
      notification.isRead = true;
      await notification.save();
      _broadcastNotifications();
      notifyListeners();
    }
  }

  Future<void> markAsUnread(String notificationId) async {
    if (_notificationBox == null || !_initialized) return;

    final notifications = _notificationBox!.values.where((n) => n.id == notificationId);
    if (notifications.isNotEmpty) {
      final notification = notifications.first;
      notification.isRead = false;
      await notification.save();
      _broadcastNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_notificationBox == null || !_initialized) return;

    for (var notification in unreadNotifications) {
      notification.isRead = true;
      await notification.save();
    }
    
    _broadcastNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_notificationBox == null || !_initialized) return;

    final index = _notificationBox!.values.toList().indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      await _notificationBox!.deleteAt(index);
      _broadcastNotifications();
      notifyListeners();
    }
  }

  Future<void> deleteAllNotifications() async {
    if (_notificationBox == null || !_initialized) return;
    
    await _notificationBox!.clear();
    _broadcastNotifications();
    notifyListeners();
  }

  Future<void> deleteOldNotifications({int daysOld = 30}) async {
    if (_notificationBox == null || !_initialized) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final oldNotifications = allNotifications
        .where((n) => n.timestamp.isBefore(cutoffDate))
        .toList();

    for (var notification in oldNotifications) {
      final index = _notificationBox!.values.toList().indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        await _notificationBox!.deleteAt(index);
      }
    }

    _broadcastNotifications();
    notifyListeners();
  }

  void _broadcastNotifications() {
    if (_initialized) {
      _notificationsController.add(allNotifications);
    }
  }

  // Convenience methods for different notification types
  Future<void> addTransactionNotification(String title, String body, {Map<String, dynamic>? data}) async {
    await addNotification(
      title: title,
      body: body,
      type: NotificationType.transaction,
      data: data,
    );
  }

  Future<void> addBudgetNotification(String title, String body, {Map<String, dynamic>? data}) async {
    await addNotification(
      title: title,
      body: body,
      type: NotificationType.budget,
      data: data,
    );
  }

  Future<void> addGoalNotification(String title, String body, {Map<String, dynamic>? data}) async {
    await addNotification(
      title: title,
      body: body,
      type: NotificationType.goal,
      data: data,
    );
  }

  Future<void> addBalanceNotification(String title, String body, {Map<String, dynamic>? data}) async {
    await addNotification(
      title: title,
      body: body,
      type: NotificationType.balance,
      data: data,
    );
  }

  Future<void> addChallengeNotification(String title, String body, {Map<String, dynamic>? data}) async {
    await addNotification(
      title: title,
      body: body,
      type: NotificationType.challenge,
      data: data,
    );
  }

  Future<void> addAlertNotification(String title, String body, {Map<String, dynamic>? data}) async {
    await addNotification(
      title: title,
      body: body,
      type: NotificationType.alert,
      data: data,
    );
  }

  Future<void> addAchievementNotification(String title, String body, {Map<String, dynamic>? data}) async {
    await addNotification(
      title: title,
      body: body,
      type: NotificationType.achievement,
      data: data,
    );
  }

  @override
  void dispose() {
    _notificationsController.close();
    super.dispose();
  }
}