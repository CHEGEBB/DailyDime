// lib/models/budget.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly }
enum BudgetStatus { underBudget, onTrack, nearLimit, overBudget }

class Budget {
  final String id;
  final String title;
  final String category;
  final double amount;
  final double spent;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;
  final IconData icon;
  final List<String> tags;
  final String notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Budget({
    String? id,
    required this.title,
    required this.category,
    required this.amount,
    this.spent = 0.0,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.color,
    required this.icon,
    this.tags = const [],
    this.notes = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  double get percentageUsed => amount > 0 ? spent / amount : 0;
  
  BudgetStatus get status {
    final percentage = percentageUsed;
    if (percentage >= 1.0) return BudgetStatus.overBudget;
    if (percentage >= 0.9) return BudgetStatus.nearLimit;
    if (percentage >= 0.6) return BudgetStatus.onTrack;
    return BudgetStatus.underBudget;
  }
  
  double get remaining => amount - spent;
  
  bool get isOverBudget => spent > amount;

  // For daily budgets - how much is available to spend today
  double get dailyAllowance {
    if (period == BudgetPeriod.daily) return remaining;
    
    final now = DateTime.now();
    final daysLeft = endDate.difference(now).inDays + 1;
    return daysLeft > 0 ? remaining / daysLeft : 0;
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'spent': spent,
      'period': period.index,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'color': color.value,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'tags': tags,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Create from Map for storage retrieval
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      amount: map['amount']?.toDouble() ?? 0.0,
      spent: map['spent']?.toDouble() ?? 0.0,
      period: BudgetPeriod.values[map['period'] ?? 2], // Default to monthly
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      color: Color(map['color'] ?? Colors.blue.value),
      icon: IconData(
        map['icon'] ?? Icons.category.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      tags: List<String>.from(map['tags'] ?? []),
      notes: map['notes'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
          : null,
    );
  }

  // Create a copy with updates
  Budget copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    double? spent,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    Color? color,
    IconData? icon,
    List<String>? tags,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'spent': spent,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'color': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'tags': tags,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      amount: json['amount']?.toDouble() ?? 0.0,
      spent: json['spent']?.toDouble() ?? 0.0,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      color: Color(json['color'] ?? Colors.blue.value),
      icon: IconData(
        json['iconCodePoint'] ?? Icons.category.codePoint,
        fontFamily: json['iconFontFamily'] ?? 'MaterialIcons',
      ),
      tags: List<String>.from(json['tags'] ?? []),
      notes: json['notes'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

// Simple Budget Model for your app (matching your usage pattern)
class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spent;
  final String period;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spent,
    required this.period,
    required this.createdAt,
  });

  double get percentageUsed => budgetAmount > 0 ? spent / budgetAmount : 0;
  double get remaining => budgetAmount - spent;
  bool get isOverBudget => spent > budgetAmount;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      budgetAmount: json['budgetAmount']?.toDouble() ?? 0.0,
      spent: json['spent']?.toDouble() ?? 0.0,
      period: json['period'] ?? 'monthly',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'budgetAmount': budgetAmount,
      'spent': spent,
      'period': period,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}