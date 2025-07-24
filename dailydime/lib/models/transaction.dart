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
  final IconData icon;
  
  @HiveField(7)
  final Color color;
  
  @HiveField(8)
  final String? mpesaCode;
  
  @HiveField(9)
  final bool isSms;
  
  @HiveField(10)
  final String? rawSms;
  
  @HiveField(11)
  final String? sender;
  
  @HiveField(12)
  final String? recipient;
  
  @HiveField(13)
  final String? agent;
  
  @HiveField(14)
  final String? business;
  
  @HiveField(15)
  final double? balance;
  
  @HiveField(16)
  final String? description;
  
  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
    required this.icon,
    required this.color,
    this.mpesaCode,
    required this.isSms,
    this.rawSms,
    this.sender,
    this.recipient,
    this.agent,
    this.business,
    this.balance,
    this.description,
  });
  
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
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'mpesaCode': mpesaCode,
      'isSms': isSms,
      'rawSms': rawSms,
      'sender': sender,
      'recipient': recipient,
      'agent': agent,
      'business': business,
      'balance': balance,
      'description': description,
    };
  }
  
  // For creating from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      isExpense: json['isExpense'],
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
      ),
      color: Color(json['colorValue']),
      mpesaCode: json['mpesaCode'],
      isSms: json['isSms'],
      rawSms: json['rawSms'],
      sender: json['sender'],
      recipient: json['recipient'],
      agent: json['agent'],
      business: json['business'],
      balance: json['balance'],
      description: json['description'],
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
        other.isExpense == isExpense &&
        other.icon == icon &&
        other.color == color &&
        other.mpesaCode == mpesaCode &&
        other.isSms == isSms &&
        other.rawSms == rawSms &&
        other.sender == sender &&
        other.recipient == recipient &&
        other.agent == agent &&
        other.business == business &&
        other.balance == balance &&
        other.description == description;
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
      icon,
      color,
      mpesaCode,
      isSms,
      rawSms,
      sender,
      recipient,
      agent,
      business,
      balance,
      description,
    );
  }
}