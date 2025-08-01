// lib/models/app_notification.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_notification.g.dart'; 

@HiveType(typeId: 4)
class AppNotification extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  NotificationType type;

  @HiveField(5)
  bool isRead;

  @HiveField(6)
  Map<String, dynamic>? data;

  @HiveField(7)
  String? iconName;

  @HiveField(8)
  String? actionData;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
    this.iconName,
    this.actionData,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.transaction:
        return Icons.account_balance_wallet;
      case NotificationType.budget:
        return Icons.pie_chart;
      case NotificationType.goal:
        return Icons.flag;
      case NotificationType.challenge:
        return Icons.emoji_events;
      case NotificationType.balance:
        return Icons.account_balance;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.achievement:
        return Icons.star;
      case NotificationType.system:
        return Icons.settings;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.transaction:
        return Colors.blue;
      case NotificationType.budget:
        return Colors.orange;
      case NotificationType.goal:
        return Colors.green;
      case NotificationType.challenge:
        return Colors.purple;
      case NotificationType.balance:
        return Colors.teal;
      case NotificationType.reminder:
        return Colors.amber;
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.achievement:
        return Colors.yellow;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }
}

@HiveType(typeId: 5)
enum NotificationType {
  @HiveField(0)
  transaction,
  @HiveField(1)
  budget,
  @HiveField(2)
  goal,
  @HiveField(3)
  challenge,
  @HiveField(4)
  balance,
  @HiveField(5)
  reminder,
  @HiveField(6)
  alert,
  @HiveField(7)
  achievement,
  @HiveField(8)
  system,
}