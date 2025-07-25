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
  other
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
  }) : 
    id = id ?? const Uuid().v4(),
    startDate = startDate ?? DateTime.now(),
    transactions = transactions ?? [];

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
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.millisecondsSinceEpoch,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'status': status.index,
      'category': category.index,
      'iconAsset': iconAsset,
      'color': color.value,
      'isAiSuggested': isAiSuggested,
      'aiSuggestionReason': aiSuggestionReason,
      'recommendedWeeklySaving': recommendedWeeklySaving,
      'isAutomaticSaving': isAutomaticSaving,
      'forecastedCompletion': forecastedCompletion,
      'imageUrl': imageUrl,
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }
  
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'] ?? 0.0,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate']),
      status: SavingsGoalStatus.values[map['status'] ?? 0],
      category: SavingsGoalCategory.values[map['category'] ?? 0],
      iconAsset: map['iconAsset'],
      color: Color(map['color']),
      isAiSuggested: map['isAiSuggested'] ?? false,
      aiSuggestionReason: map['aiSuggestionReason'],
      recommendedWeeklySaving: map['recommendedWeeklySaving'],
      isAutomaticSaving: map['isAutomaticSaving'] ?? false,
      forecastedCompletion: map['forecastedCompletion'],
      imageUrl: map['imageUrl'],
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
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'source': source,
    };
  }

  factory SavingsTransaction.fromMap(Map<String, dynamic> map) {
    return SavingsTransaction(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      note: map['note'] ?? '',
      source: map['source'],
    );
  }
}