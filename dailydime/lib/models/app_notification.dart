// lib/models/app_notification.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:timeago/timeago.dart' as timeago;

part 'app_notification.g.dart';

@HiveType(typeId: 5)
enum NotificationType {
  @HiveField(0)
  transaction,
  
  @HiveField(1)
  budget,
  
  @HiveField(2)
  goal,
  
  @HiveField(3)
  balance,
  
  @HiveField(4)
  system,
  
  @HiveField(5)
  reminder,
  
  @HiveField(6)
  challenge,
  
  @HiveField(7)
  alert,
  
  @HiveField(8)
  achievement,
}

@HiveType(typeId: 4)
class AppNotification extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String body;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final NotificationType type;
  
  @HiveField(5)
  bool isRead;
  
  @HiveField(6)
  final Map<String, dynamic>? data;
  
  @HiveField(7)
  final String? actionData;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
    this.actionData, String? iconName,
  });

  String get timeAgo => timeago.format(timestamp);

  IconData get icon {
    switch (type) {
      case NotificationType.transaction:
        return Icons.receipt_long;
      case NotificationType.budget:
        return Icons.account_balance_wallet;
      case NotificationType.goal:
        return Icons.flag;
      case NotificationType.balance:
        return Icons.account_balance;
      case NotificationType.system:
        return Icons.notifications;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.challenge:
        return Icons.emoji_events;
      case NotificationType.alert:
        return Icons.warning_amber;
      case NotificationType.achievement:
        return Icons.star;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.transaction:
        return Colors.blue;
      case NotificationType.budget:
        return Colors.green;
      case NotificationType.goal:
        return Colors.purple;
      case NotificationType.balance:
        return Colors.teal;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.challenge:
        return Colors.indigo;
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.achievement:
        return Colors.amber;
    }
  }

  get iconName => null;
}