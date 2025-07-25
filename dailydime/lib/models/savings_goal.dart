// lib/models/savings_goal.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum SavingsGoalStatus {
  active,
  completed,
  upcoming,
  paused
}

enum SavingsGoalCategory {
  travel,
  education,
  electronics,
  vehicle,
  housing,
  emergency,
  retirement,
  debt,
  investment,
  other, vacation
}

class SavingsGoal {
  final String id;
  final String title;
  final String description;
  final double targetAmount;
  double currentAmount;
  final DateTime startDate;
  final DateTime targetDate;
  SavingsGoalStatus status;
  final SavingsGoalCategory category;
  final String iconAsset;
  final Color color;
  List<SavingsTransaction> transactions;
  final bool isAiSuggested;
  String? aiSuggestionReason;
  double? recommendedWeeklySaving;
  bool isAutomaticSaving;
  double? forecastedCompletion;
  String? imageUrl;
  
  // Additional fields to match provider usage
  final double? dailyTarget;
  final double? weeklyTarget;
  final String priority;
  final bool isRecurring;
  final String reminderFrequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoal({
    String? id,
    required this.title,
    this.description = '',
    required this.targetAmount,
    this.currentAmount = 0.0,
    DateTime? startDate,
    required this.targetDate,
    this.status = SavingsGoalStatus.active,
    required this.category,
    required this.iconAsset,
    required this.color,
    List<SavingsTransaction>? transactions,
    this.isAiSuggested = false,
    this.aiSuggestionReason,
    this.recommendedWeeklySaving,
    this.isAutomaticSaving = false,
    this.forecastedCompletion,
    this.imageUrl,
    this.dailyTarget,
    this.weeklyTarget,
    this.priority = 'medium',
    this.isRecurring = false,
    this.reminderFrequency = 'weekly',
    DateTime? createdAt,
    DateTime? updatedAt, DateTime? deadline,
  }) : 
    id = id ?? const Uuid().v4(),
    startDate = startDate ?? DateTime.now(),
    transactions = transactions ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  double get progressPercentage => currentAmount / targetAmount;
  
  bool get isOnTrack {
    if (targetDate.isBefore(DateTime.now())) return false;
    
    final totalDays = targetDate.difference(startDate).inDays;
    final daysElapsed = DateTime.now().difference(startDate).inDays;
    
    if (totalDays == 0) return true;
    
    final expectedProgress = daysElapsed / totalDays;
    final actualProgress = currentAmount / targetAmount;
    
    // On track if we've saved at least 90% of expected amount
    return actualProgress >= (expectedProgress * 0.9);
  }
  
  int get daysLeft => targetDate.difference(DateTime.now()).inDays;
  
  bool get isCompleted => currentAmount >= targetAmount;
  
  double get dailySavingNeeded {
    final daysRemaining = targetDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return 0;
    return (targetAmount - currentAmount) / daysRemaining;
  }
  
  // Updated toMap method that converts enums to strings for Appwrite compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'status': status.toString().split('.').last, // Convert enum to string
      'category': category.toString().split('.').last, // Convert enum to string
      'iconAsset': iconAsset,
      'color': color.value,
      'isAiSuggested': isAiSuggested,
      'aiSuggestionReason': aiSuggestionReason,
      'recommendedWeeklySaving': recommendedWeeklySaving,
      'isAutomaticSaving': isAutomaticSaving,
      'forecastedCompletion': forecastedCompletion,
      'imageUrl': imageUrl,
      'dailyTarget': dailyTarget,
      'weeklyTarget': weeklyTarget,
      'priority': priority,
      'isRecurring': isRecurring,
      'reminderFrequency': reminderFrequency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }
  
  // Updated fromMap method that converts strings back to enums
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    // Helper to convert string to SavingsGoalCategory
    SavingsGoalCategory _stringToCategory(String categoryString) {
      switch (categoryString.toLowerCase()) {
        case 'travel':
          return SavingsGoalCategory.travel;
        case 'education':
          return SavingsGoalCategory.education;
        case 'electronics':
          return SavingsGoalCategory.electronics;
        case 'vehicle':
          return SavingsGoalCategory.vehicle;
        case 'housing':
          return SavingsGoalCategory.housing;
        case 'emergency':
          return SavingsGoalCategory.emergency;
        case 'retirement':
          return SavingsGoalCategory.retirement;
        case 'debt':
          return SavingsGoalCategory.debt;
        case 'investment':
          return SavingsGoalCategory.investment;
        default:
          return SavingsGoalCategory.other;
      }
    }

    // Helper to convert string to SavingsGoalStatus
    SavingsGoalStatus _stringToStatus(String statusString) {
      switch (statusString.toLowerCase()) {
        case 'active':
          return SavingsGoalStatus.active;
        case 'completed':
          return SavingsGoalStatus.completed;
        case 'paused':
          return SavingsGoalStatus.paused;
        case 'upcoming':
          return SavingsGoalStatus.upcoming;
        default:
          return SavingsGoalStatus.active;
      }
    }

    return SavingsGoal(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
      startDate: DateTime.parse(map['startDate']),
      targetDate: DateTime.parse(map['targetDate']),
      status: _stringToStatus(map['status'] ?? 'active'),
      category: _stringToCategory(map['category'] ?? 'other'),
      iconAsset: map['iconAsset'] ?? 'savings',
      color: Color(map['color'] ?? Colors.blue.value),
      isAiSuggested: map['isAiSuggested'] ?? false,
      aiSuggestionReason: map['aiSuggestionReason'],
      recommendedWeeklySaving: map['recommendedWeeklySaving']?.toDouble(),
      isAutomaticSaving: map['isAutomaticSaving'] ?? false,
      forecastedCompletion: map['forecastedCompletion']?.toDouble(),
      imageUrl: map['imageUrl'],
      dailyTarget: map['dailyTarget']?.toDouble(),
      weeklyTarget: map['weeklyTarget']?.toDouble(),
      priority: map['priority'] ?? 'medium',
      isRecurring: map['isRecurring'] ?? false,
      reminderFrequency: map['reminderFrequency'] ?? 'weekly',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      transactions: map['transactions'] != null 
          ? List<SavingsTransaction>.from(
              map['transactions'].map((t) => SavingsTransaction.fromMap(t))
            )
          : [],
    );
  }
  
  SavingsGoal copyWith({
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    SavingsGoalStatus? status,
    SavingsGoalCategory? category,
    String? iconAsset,
    Color? color,
    List<SavingsTransaction>? transactions,
    bool? isAiSuggested,
    String? aiSuggestionReason,
    double? recommendedWeeklySaving,
    bool? isAutomaticSaving,
    double? forecastedCompletion,
    String? imageUrl,
    double? dailyTarget,
    double? weeklyTarget,
    String? priority,
    bool? isRecurring,
    String? reminderFrequency,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      category: category ?? this.category,
      iconAsset: iconAsset ?? this.iconAsset,
      color: color ?? this.color,
      transactions: transactions ?? this.transactions,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
      aiSuggestionReason: aiSuggestionReason ?? this.aiSuggestionReason,
      recommendedWeeklySaving: recommendedWeeklySaving ?? this.recommendedWeeklySaving,
      isAutomaticSaving: isAutomaticSaving ?? this.isAutomaticSaving,
      forecastedCompletion: forecastedCompletion ?? this.forecastedCompletion,
      imageUrl: imageUrl ?? this.imageUrl,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      priority: priority ?? this.priority,
      isRecurring: isRecurring ?? this.isRecurring,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class SavingsTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final String note;
  final String? source;

  SavingsTransaction({
    String? id,
    required this.amount,
    required this.date,
    this.note = '',
    this.source,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(), // Use ISO string instead of milliseconds
      'note': note,
      'source': source,
    };
  }

  factory SavingsTransaction.fromMap(Map<String, dynamic> map) {
    return SavingsTransaction(
      id: map['id'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
      source: map['source'],
    );
  }
}