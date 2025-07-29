// lib/models/transaction.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final DateTime date;
  
  @HiveField(4)
  final String category;
  
  @HiveField(5)
  final bool isExpense;
  
  @HiveField(6)
  final int iconCodePoint;
  
  @HiveField(7)
  final String? iconFontFamily;
  
  @HiveField(8)
  final int colorValue;
  
  @HiveField(9)
  final String? mpesaCode;
  
  @HiveField(10)
  final bool isSms;
  
  @HiveField(11)
  final String? rawSms;
  
  @HiveField(12)
  final String? sender;
  
  @HiveField(13)
  final String? recipient;
  
  @HiveField(14)
  final String? agent;
  
  @HiveField(15)
  final String? business;
  
  @HiveField(16)
  final double? balance;
  
  @HiveField(17)
  final String? description;
  
  @HiveField(18)
  final String? iconPath;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
    IconData? icon,
    Color? color,
    this.mpesaCode,
    this.isSms = false,
    this.rawSms,
    this.sender,
    this.recipient,
    this.agent,
    this.business,
    this.balance,
    this.description,
    this.iconPath,
  }) : iconCodePoint = icon?.codePoint ?? Icons.category.codePoint,
       iconFontFamily = icon?.fontFamily ?? Icons.category.fontFamily,
       colorValue = color?.value ?? Colors.grey.value;

  // Getters for convenience
  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);
  Color get color => Color(colorValue);
  String get type => isExpense ? 'expense' : 'income';
  
  // Create a copy with modified fields
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    bool? isExpense,
    IconData? icon,
    Color? color,
    String? mpesaCode,
    bool? isSms,
    String? rawSms,
    String? sender,
    String? recipient,
    String? agent,
    String? business,
    double? balance,
    String? description,
    String? iconPath,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isExpense: isExpense ?? this.isExpense,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      mpesaCode: mpesaCode ?? this.mpesaCode,
      isSms: isSms ?? this.isSms,
      rawSms: rawSms ?? this.rawSms,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      agent: agent ?? this.agent,
      business: business ?? this.business,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
    );
  }
  
  // For converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'isExpense': isExpense,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'colorValue': colorValue,
      'mpesaCode': mpesaCode,
      'isSms': isSms,
      'rawSms': rawSms,
      'sender': sender,
      'recipient': recipient,
      'agent': agent,
      'business': business,
      'balance': balance,
      'description': description,
      'iconPath': iconPath,
    };
  }
  
  // For creating from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
      category: json['category'] ?? 'Other',
      isExpense: json['isExpense'] ?? true,
      icon: IconData(
        json['iconCodePoint'] ?? Icons.category.codePoint,
        fontFamily: json['iconFontFamily'],
      ),
      color: Color(json['colorValue'] ?? Colors.grey.value),
      mpesaCode: json['mpesaCode'],
      isSms: json['isSms'] ?? false,
      rawSms: json['rawSms'],
      sender: json['sender'],
      recipient: json['recipient'],
      agent: json['agent'],
      business: json['business'],
      balance: json['balance']?.toDouble(),
      description: json['description'],
      iconPath: json['iconPath'],
    );
  }
  
  @override
  String toString() {
    return 'Transaction(id: $id, title: $title, amount: $amount, date: $date, category: $category, isExpense: $isExpense, description: $description)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.date == date &&
        other.category == category &&
        other.isExpense == isExpense;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      amount,
      date,
      category,
      isExpense,
    );
  }
}

// Alternative simple class without Hive annotations if you're not using Hive
class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String iconPath;
  
  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.iconPath,
  });
  
  bool get isExpense => amount < 0;
  String get type => isExpense ? 'expense' : 'income';
  
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      title: json['title'],
      amount: json['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
      category: json['category'] ?? 'Other',
      iconPath: json['iconPath'] ?? 'assets/images/default.png',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'iconPath': iconPath,
    };
  }
}