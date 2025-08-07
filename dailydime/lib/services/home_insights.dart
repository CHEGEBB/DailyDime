// lib/services/home_insights.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class InsightItem {
  final String id;
  final String type; // 'alert', 'opportunity', 'tip', etc.
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? actionText;
  final DateTime generatedAt;
  final Map<String, dynamic>? additionalData;
  final bool isDismissible;

  InsightItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.actionText,
    required this.generatedAt,
    this.additionalData,
    this.isDismissible = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'actionText': actionText,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'additionalData': additionalData,
      'isDismissible': isDismissible,
    };
  }

  factory InsightItem.fromMap(Map<String, dynamic> map) {
    return InsightItem(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(map['iconCodePoint'] ?? Icons.insights.codePoint,
          fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] ?? Colors.blue.value),
      actionText: map['actionText'],
      generatedAt: DateTime.fromMillisecondsSinceEpoch(map['generatedAt'] ?? 0),
      additionalData: map['additionalData'],
      isDismissible: map['isDismissible'] ?? true,
    );
  }
}

class MoneyTip {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime generatedAt;

  MoneyTip({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
    };
  }

  factory MoneyTip.fromMap(Map<String, dynamic> map) {
    return MoneyTip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(map['iconCodePoint'] ?? Icons.lightbulb.codePoint,
          fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] ?? Colors.blue.value),
      generatedAt: DateTime.fromMillisecondsSinceEpoch(map['generatedAt'] ?? 0),
    );
  }
}

class HomeInsightsService {
  static final HomeInsightsService _instance = HomeInsightsService._internal();
  factory HomeInsightsService() => _instance;
  HomeInsightsService._internal();

  final SmsService _smsService = SmsService();
  final AppwriteService _appwriteService = AppwriteService();
  final StorageService _storageService = StorageService.instance;

  // Cached data
  List<Transaction> _cachedTransactions = [];
  List<InsightItem> _cachedInsights = [];
  List<MoneyTip> _cachedTips = [];
  DateTime _lastCacheRefresh = DateTime(2000); // Long ago to force initial refresh
  DateTime _lastInsightGeneration = DateTime(2000);

  // Stream controllers
  final _insightsStreamController = StreamController<List<InsightItem>>.broadcast();
  final _tipsStreamController = StreamController<List<MoneyTip>>.broadcast();

  // Streams
  Stream<List<InsightItem>> get insightsStream => _insightsStreamController.stream;
  Stream<List<MoneyTip>> get tipsStream => _tipsStreamController.stream;

  // Get cached insights and tips
  List<InsightItem> get cachedInsights => _cachedInsights;
  List<MoneyTip> get cachedTips => _cachedTips;

  // Initialize the service
  Future<void> initialize() async {
    // Initialize dependencies
    await _smsService.initialize();
    await _loadCachedData();
    
    // Setup listeners
    _smsService.transactionStream.listen((transaction) {
      _refreshData();
    });
    
    // Generate initial insights
    await generateInsights(forceRefresh: true);
    
    // Setup periodic refresh (every 6 hours)
    Timer.periodic(Duration(hours: 6), (_) async {
      await generateInsights(forceRefresh: true);
    });
  }

  // Load cached insights and tips
  Future<void> _loadCachedData() async {
    try {
      final insightsData = await _storageService.getInsights();
      if (insightsData != null) {
        _cachedInsights = (jsonDecode(insightsData) as List)
            .map((item) => InsightItem.fromMap(item))
            .toList();
        _insightsStreamController.add(_cachedInsights);
      }
      
      final tipsData = await _storageService.getMoneyTips();
      if (tipsData != null) {
        _cachedTips = (jsonDecode(tipsData) as List)
            .map((item) => MoneyTip.fromMap(item))
            .toList();
        _tipsStreamController.add(_cachedTips);
      }
    } catch (e) {
      debugPrint('Error loading cached insights: $e');
    }
  }

  // Save insights to storage
  Future<void> _saveInsights(List<InsightItem> insights) async {
    try {
      final insightsJson = jsonEncode(insights.map((i) => i.toMap()).toList());
      await _storageService.saveInsights(insightsJson);
    } catch (e) {
      debugPrint('Error saving insights: $e');
    }
  }

  // Save money tips to storage
  Future<void> _saveTips(List<MoneyTip> tips) async {
    try {
      final tipsJson = jsonEncode(tips.map((t) => t.toMap()).toList());
      await _storageService.saveMoneyTips(tipsJson);
    } catch (e) {
      debugPrint('Error saving money tips: $e');
    }
  }

  // Refresh transaction data
  Future<void> _refreshData() async {
    final now = DateTime.now();
    if (now.difference(_lastCacheRefresh).inMinutes < 15) {
      return; // Only refresh every 15 minutes max
    }
    
    _cachedTransactions = await _storageService.getTransactions();
    _lastCacheRefresh = now;
  }

  // Generate insights
  Future<List<InsightItem>> generateInsights({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Check if we should regenerate insights
    final shouldRegenerate = forceRefresh || 
                            _cachedInsights.isEmpty || 
                            now.difference(_lastInsightGeneration).inHours >= 12;
    
    if (!shouldRegenerate) {
      return _cachedInsights;
    }
    
    // Refresh data if needed
    if (forceRefresh || now.difference(_lastCacheRefresh).inMinutes >= 15) {
      await _refreshData();
    }
    
    // Get budgets from Appwrite
    final budgets = await _appwriteService.getBudgets();
    
    // Get savings goals from Appwrite
    final savingsGoals = await _appwriteService.getSavingsGoals();
    
    // Prepare data for AI analysis
    List<InsightItem> newInsights = [];
    List<MoneyTip> newTips = [];
    
    try {
      // Generate insights using Gemini AI
      final aiGeneratedData = await _generateAIInsights(
        transactions: _cachedTransactions,
        budgets: budgets.map((budget) => {
          'id': budget.id,
          'name': budget.title,
          'amount': budget.amount,
          'spent': budget.spent,
          'period': budget.period,
          'category': budget.category,
        }).toList(),
       savingsGoals: savingsGoals.map((goal) => {
  'id': goal.id,
  'name': goal.title,
  'targetAmount': goal.targetAmount,
  'currentAmount': goal.currentAmount,
  'deadline': goal.targetDate.millisecondsSinceEpoch,
  'category': goal.category,
}).toList(),
      );
      
      // Process AI insights
      if (aiGeneratedData != null) {
        if (aiGeneratedData.containsKey('insights')) {
          for (final insightData in aiGeneratedData['insights']) {
            try {
              final insight = InsightItem(
                id: insightData['id'] ?? 'insight_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
                type: insightData['type'] ?? 'general',
                title: insightData['title'] ?? 'Insight',
                description: insightData['description'] ?? '',
                icon: _getIconFromString(insightData['icon'] ?? 'insights'),
                color: _getColorFromString(insightData['color'] ?? 'blue'),
                actionText: insightData['actionText'],
                generatedAt: now,
                additionalData: insightData['additionalData'],
                isDismissible: insightData['isDismissible'] ?? true,
              );
              newInsights.add(insight);
            } catch (e) {
              debugPrint('Error processing insight: $e');
            }
          }
        }
        
        if (aiGeneratedData.containsKey('tips')) {
          for (final tipData in aiGeneratedData['tips']) {
            try {
              final tip = MoneyTip(
                id: tipData['id'] ?? 'tip_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
                title: tipData['title'] ?? 'Money Tip',
                description: tipData['description'] ?? '',
                icon: _getIconFromString(tipData['icon'] ?? 'lightbulb'),
                color: _getColorFromString(tipData['color'] ?? 'green'),
                generatedAt: now,
              );
              newTips.add(tip);
            } catch (e) {
              debugPrint('Error processing tip: $e');
            }
          }
        }
      }
      
      // If AI failed to generate insights, create fallback insights
      if (newInsights.isEmpty) {
        newInsights = _generateFallbackInsights();
      }
      
      // If AI failed to generate tips, create fallback tips
      if (newTips.isEmpty) {
        newTips = _generateFallbackTips();
      }
      
      // Save insights to storage
      _cachedInsights = newInsights;
      _cachedTips = newTips;
      
      await _saveInsights(newInsights);
      await _saveTips(newTips);
      
      // Update streams
      _insightsStreamController.add(newInsights);
      _tipsStreamController.add(newTips);
      
      _lastInsightGeneration = now;
      
      return newInsights;
    } catch (e) {
      debugPrint('Error generating insights: $e');
      // Return cached insights if there was an error
      return _cachedInsights;
    }
  }

  // Generate insights using Gemini AI
  Future<Map<String, dynamic>?> _generateAIInsights({
    required List<Transaction> transactions,
    required List<Map<String, dynamic>> budgets,
    required List<Map<String, dynamic>> savingsGoals,
  }) async {
    try {
      // Prepare transaction data for AI
      final transactionData = _prepareTransactionData(transactions);
      
      // Prepare budgets data
      final budgetsData = budgets.map((budget) => {
        'id': budget['id'] ?? '',
        'name': budget['name'] ?? 'Unnamed Budget',
        'amount': budget['amount'] ?? 0,
        'spent': budget['spent'] ?? 0,
        'period': budget['period'] ?? 'monthly',
        'category': budget['category'] ?? 'General',
      }).toList();
      
      // Prepare savings goals data
      final savingsGoalsData = savingsGoals.map((goal) => {
        'id': goal['id'] ?? '',
        'name': goal['name'] ?? 'Unnamed Goal',
        'targetAmount': goal['targetAmount'] ?? 0,
        'currentAmount': goal['currentAmount'] ?? 0,
        'deadline': goal['deadline'] != null ? 
            DateTime.fromMillisecondsSinceEpoch(goal['deadline']).toString() : null,
        'category': goal['category'] ?? 'General',
      }).toList();
      
      // Current date and time for context
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final monthName = DateFormat('MMMM').format(now);
      
      // Construct the prompt for Gemini
      final prompt = '''
Generate financial insights and money tips based on the user's transaction history, budgets, and savings goals.

Today's date: $dateStr
Current month: $monthName

TRANSACTION DATA:
${jsonEncode(transactionData)}

BUDGETS:
${jsonEncode(budgetsData)}

SAVINGS GOALS:
${jsonEncode(savingsGoalsData)}

Analyze this data and generate:
1. Two to three personalized financial insights (spending alerts, savings opportunities, budget status)
2. Three to five smart money tips that could help the user improve their financial health

IMPORTANT GUIDELINES:
- Be realistic, practical, and specific
- Use Kenyan Shillings (KSH) as the currency
- Focus on actionable advice
- Consider the user's spending patterns and budget adherence
- Highlight both positive behaviors and areas for improvement
- For savings goals, suggest specific amounts to save based on current spending
- Keep insights and tips concise but informative

Format your response as a valid JSON object with this structure:
{
  "insights": [
    {
      "id": "unique_id",
      "type": "alert|opportunity|status|general",
      "title": "Short title",
      "description": "Longer description with specific details",
      "icon": "icon_name",
      "color": "color_name",
      "actionText": "Call to action text (optional)",
      "additionalData": {
        "any": "relevant data"
      },
      "isDismissible": true|false
    }
  ],
  "tips": [
    {
      "id": "unique_id",
      "title": "Tip title",
      "description": "Tip description",
      "icon": "icon_name",
      "color": "color_name"
    }
  ]
}

Available icon names: insights, trending_up, trending_down, warning, check_circle, savings, account_balance, payment, receipt, shopping_cart, food, transportation, utilities, entertainment, health, education, travel, work, home, family, gift, phone, money

Available color names: blue, green, red, orange, purple, teal, cyan, amber, pink, indigo
''';

      // Call Gemini API
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': AppConfig.geminiApiKey,
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": prompt
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.2,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final generatedText = responseData['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract the JSON from the response
        // The response might have markdown code block indicators
        String jsonText = generatedText;
        if (generatedText.contains('```json')) {
          jsonText = generatedText.split('```json')[1].split('```')[0].trim();
        } else if (generatedText.contains('```')) {
          jsonText = generatedText.split('```')[1].split('```')[0].trim();
        }
        
        // Parse the JSON
        final Map<String, dynamic> parsedData = jsonDecode(jsonText);
        return parsedData;
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating AI insights: $e');
      return null;
    }
  }

  // Prepare transaction data for AI analysis
  Map<String, dynamic> _prepareTransactionData(List<Transaction> transactions) {
    // Get transactions from the last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();
    
    // Get transactions from the current month
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthTransactions = transactions
        .where((t) => t.date.isAfter(currentMonthStart))
        .toList();
    
    // Calculate total spending and income for current month
    double totalSpending = 0;
    double totalIncome = 0;
    for (var t in currentMonthTransactions) {
      if (t.isExpense) {
        totalSpending += t.amount;
      } else {
        totalIncome += t.amount;
      }
    }
    
    // Get spending by category
    Map<String, double> spendingByCategory = {};
    for (var t in currentMonthTransactions) {
      if (t.isExpense) {
        final category = t.category;
        spendingByCategory[category] = (spendingByCategory[category] ?? 0) + t.amount;
      }
    }
    
    // Top spending categories
    final sortedCategories = spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).map((e) => {
      'category': e.key,
      'amount': e.value,
    }).toList();
    
    // Recent large transactions
    final largeTransactions = recentTransactions
        .where((t) => t.isExpense && t.amount > 1000) // Transactions over 1000 KSH
        .take(5)
        .map((t) => {
          'title': t.title,
          'amount': t.amount,
          'date': t.date.toString(),
          'category': t.category,
        })
        .toList();
    
    // Recurring transactions
    final recurringTransactions = _identifyRecurringTransactions(transactions);
    
    // Average daily spending
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysSoFar = min(now.day, daysInCurrentMonth);
    final averageDailySpending = totalSpending / daysSoFar;
    
    // Get most recent balance
    double? latestBalance;
    if (transactions.isNotEmpty) {
      transactions.sort((a, b) => b.date.compareTo(a.date));
      for (var t in transactions) {
        if (t.balance != null && t.balance! > 0) {
          latestBalance = t.balance;
          break;
        }
      }
    }
    
    // Return structured data
    return {
      'summary': {
        'totalSpending': totalSpending,
        'totalIncome': totalIncome,
        'balance': latestBalance,
        'savingsRate': totalIncome > 0 ? (totalIncome - totalSpending) / totalIncome : 0,
        'averageDailySpending': averageDailySpending,
        'transactionCount': currentMonthTransactions.length,
      },
      'spendingByCategory': spendingByCategory,
      'topCategories': topCategories,
      'largeTransactions': largeTransactions,
      'recurringTransactions': recurringTransactions,
      'currentMonth': DateFormat('MMMM').format(now),
      'currentYear': now.year.toString(),
    };
  }

  // Identify potential recurring transactions
  List<Map<String, dynamic>> _identifyRecurringTransactions(List<Transaction> transactions) {
    // Group transactions by similar titles and amounts
    Map<String, List<Transaction>> transactionGroups = {};
    
    for (var t in transactions) {
      // Create a simplified key based on title and amount
      final simplifiedTitle = _simplifyTitle(t.title);
      final roundedAmount = (t.amount / 100).round() * 100; // Round to nearest 100
      final key = '$simplifiedTitle-$roundedAmount-${t.isExpense}';
      
      if (!transactionGroups.containsKey(key)) {
        transactionGroups[key] = [];
      }
      transactionGroups[key]!.add(t);
    }
    
    // Filter for groups that have at least 2 transactions
    final recurringGroups = transactionGroups.entries
        .where((entry) => entry.value.length >= 2)
        .toList();
    
    // Convert to output format
    return recurringGroups.map((entry) {
      final transactions = entry.value;
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return {
        'title': transactions.first.title,
        'amount': transactions.first.amount,
        'category': transactions.first.category,
        'isExpense': transactions.first.isExpense,
        'frequency': _estimateFrequency(transactions),
        'count': transactions.length,
        'lastDate': transactions.first.date.toString(),
      };
    }).toList();
  }

  // Simplify transaction title for grouping
  String _simplifyTitle(String title) {
    // Remove numbers and special characters
    var simplified = title.replaceAll(RegExp(r'[0-9]'), '')
                         .replaceAll(RegExp(r'[^\w\s]'), '')
                         .trim()
                         .toLowerCase();
    
    // Remove common words that change between similar transactions
    final wordsToRemove = ['on', 'at', 'to', 'from', 'for', 'the', 'of', 'in'];
    for (var word in wordsToRemove) {
      simplified = simplified.replaceAll(' $word ', ' ');
    }
    
    return simplified;
  }

  // Estimate transaction frequency
  String _estimateFrequency(List<Transaction> transactions) {
    if (transactions.length < 2) return 'unknown';
    
    // Sort by date
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Calculate average days between transactions
    int totalDays = 0;
    for (int i = 0; i < transactions.length - 1; i++) {
      totalDays += transactions[i].date.difference(transactions[i + 1].date).inDays;
    }
    
    final avgDays = totalDays / (transactions.length - 1);
    
    // Determine frequency
    if (avgDays <= 3) return 'daily';
    if (avgDays <= 9) return 'weekly';
    if (avgDays <= 16) return 'biweekly';
    if (avgDays <= 35) return 'monthly';
    if (avgDays <= 95) return 'quarterly';
    return 'yearly';
  }

  // Generate fallback insights if AI fails
  List<InsightItem> _generateFallbackInsights() {
    final now = DateTime.now();
    final insights = <InsightItem>[];
    
    // Add a spending alert
    insights.add(InsightItem(
      id: 'fallback_alert_${now.millisecondsSinceEpoch}',
      type: 'alert',
      title: 'Spending Alert',
      description: 'Start tracking your expenses to get personalized insights.',
      icon: Icons.warning,
      color: Colors.orange,
      actionText: 'Set Budget',
      generatedAt: now,
      isDismissible: true,
    ));
    
    // Add a savings opportunity
    insights.add(InsightItem(
      id: 'fallback_opportunity_${now.millisecondsSinceEpoch}',
      type: 'opportunity',
      title: 'Savings Opportunity',
      description: 'Great job staying within budget! You could save an additional KES 290 by maintaining your current spending habits. Consider putting this into a savings goal.',
      icon: Icons.savings,
      color: Colors.green,
      actionText: 'Start Challenge',
      generatedAt: now,
      isDismissible: true,
    ));
    
    return insights;
  }

  // Generate fallback money tips if AI fails
  List<MoneyTip> _generateFallbackTips() {
    final now = DateTime.now();
    final tips = <MoneyTip>[];
    
    // Add saving tip
    tips.add(MoneyTip(
      id: 'fallback_tip_1_${now.millisecondsSinceEpoch}',
      title: 'Save 20% of your income',
      description: 'The 50/30/20 rule suggests saving 20% of your income for financial goals.',
      icon: Icons.savings,
      color: Colors.green,
      generatedAt: now,
    ));
    
    // Add expense tracking tip
    tips.add(MoneyTip(
      id: 'fallback_tip_2_${now.millisecondsSinceEpoch}',
      title: 'Track all expenses',
      description: 'People who track expenses save 15% more than those who don\'t.',
      icon: Icons.receipt_long,
      color: Colors.purple,
      generatedAt: now,
    ));
    
    // Add emergency fund tip
    tips.add(MoneyTip(
      id: 'fallback_tip_3_${now.millisecondsSinceEpoch}',
      title: 'Build an emergency fund',
      description: 'Aim to save 3-6 months of essential expenses for unexpected situations.',
      icon: Icons.account_balance_wallet,
      color: Colors.blue,
      generatedAt: now,
    ));
    
    return tips;
  }

  // Dismiss an insight
  Future<void> dismissInsight(String insightId) async {
    _cachedInsights.removeWhere((insight) => insight.id == insightId);
    _insightsStreamController.add(_cachedInsights);
    await _saveInsights(_cachedInsights);
  }

  // Get insights by type
  List<InsightItem> getInsightsByType(String type) {
    return _cachedInsights.where((insight) => insight.type == type).toList();
  }

  // Get money tips
  List<MoneyTip> getMoneyTips() {
    return _cachedTips;
  }

  // Helper method to get icon from string
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'insights': return Icons.insights;
      case 'trending_up': return Icons.trending_up;
      case 'trending_down': return Icons.trending_down;
      case 'warning': return Icons.warning;
      case 'check_circle': return Icons.check_circle;
      case 'savings': return Icons.savings;
      case 'account_balance': return Icons.account_balance;
      case 'payment': return Icons.payment;
      case 'receipt': return Icons.receipt;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'food': return Icons.restaurant;
      case 'transportation': return Icons.directions_car;
      case 'utilities': return Icons.electrical_services;
      case 'entertainment': return Icons.movie;
      case 'health': return Icons.health_and_safety;
      case 'education': return Icons.school;
      case 'travel': return Icons.flight;
      case 'work': return Icons.work;
      case 'home': return Icons.home;
      case 'family': return Icons.family_restroom;
      case 'gift': return Icons.card_giftcard;
      case 'phone': return Icons.phone;
      case 'money': return Icons.attach_money;
      case 'lightbulb': return Icons.lightbulb;
      default: return Icons.insights;
    }
  }

  // Helper method to get color from string
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      case 'cyan': return Colors.cyan;
      case 'amber': return Colors.amber;
      case 'pink': return Colors.pink;
      case 'indigo': return Colors.indigo;
      default: return Colors.blue;
    }
  }

  // Dispose method
  void dispose() {
    _insightsStreamController.close();
    _tipsStreamController.close();
  }
}

// Extensions for the StorageService to handle insights and tips
extension InsightsStorageExtension on StorageService {
  Future<void> saveInsights(String insightsJson) async {
    await saveData('insights_cache', insightsJson);
  }

  Future<String?> getInsights() async {
    return await getData('insights_cache');
  }

  Future<void> saveMoneyTips(String tipsJson) async {
    await saveData('money_tips_cache', tipsJson);
  }

  Future<String?> getMoneyTips() async {
    return await getData('money_tips_cache');
  }
}

// Extensions for AppwriteService to handle budgets and savings goals
extension InsightsAppwriteExtension on AppwriteService {
  Future<List<Map<String, dynamic>>> getBudgets() async {
    try {
      // Create a Databases instance from the client
      final databases = Databases(client);
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
      );
      
      return response.documents.map((doc) => doc.data).toList();
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    try {
      // Create a Databases instance from the client
      final databases = Databases(client);
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
      );
      
      return response.documents.map((doc) => doc.data).toList();
    } catch (e) {
      debugPrint('Error fetching savings goals: $e');
      return [];
    }
  }
}
