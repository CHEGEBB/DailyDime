// lib/models/insight_model.dart

import 'package:flutter/material.dart';

class InsightModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final IconData icon;
  final Color color;
  final bool isActionable;
  final String? actionText;
  final String? actionRoute;
  final DateTime createdAt;
  final String category;
  final bool hasBeenRead;
  final bool isAiGenerated;
  final Map<String, dynamic>? chartData;
  final bool showChart;
  
  InsightModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.icon,
    required this.color,
    this.isActionable = false,
    this.actionText,
    this.actionRoute,
    required this.createdAt,
    required this.category,
    this.hasBeenRead = false,
    this.isAiGenerated = true,
    this.chartData,
    this.showChart = false,
  });
  
  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['color'] as int),
      isActionable: json['isActionable'] as bool,
      actionText: json['actionText'] as String?,
      actionRoute: json['actionRoute'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String,
      hasBeenRead: json['hasBeenRead'] as bool,
      isAiGenerated: json['isAiGenerated'] as bool,
      chartData: json['chartData'] as Map<String, dynamic>?,
      showChart: json['showChart'] as bool,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'iconCodePoint': icon.codePoint,
      'color': color.value,
      'isActionable': isActionable,
      'actionText': actionText,
      'actionRoute': actionRoute,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'hasBeenRead': hasBeenRead,
      'isAiGenerated': isAiGenerated,
      'chartData': chartData,
      'showChart': showChart,
    };
  }
  
  InsightModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    IconData? icon,
    Color? color,
    bool? isActionable,
    String? actionText,
    String? actionRoute,
    DateTime? createdAt,
    String? category,
    bool? hasBeenRead,
    bool? isAiGenerated,
    Map<String, dynamic>? chartData,
    bool? showChart,
  }) {
    return InsightModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActionable: isActionable ?? this.isActionable,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      hasBeenRead: hasBeenRead ?? this.hasBeenRead,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      chartData: chartData ?? this.chartData,
      showChart: showChart ?? this.showChart,
    );
  }
}