// lib/services/expense_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/config/app_config.dart';

class ExpenseAnalytics {
  final String category;
  final double totalAmount;
  final int transactionCount;
  final double percentage;
  final DateTime firstTransaction;
  final DateTime lastTransaction;
  final List<Transaction> transactions;
  final Color color;
  final IconData icon;

  ExpenseAnalytics({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
    required this.firstTransaction,
    required this.lastTransaction,
    required this.transactions,
    required this.color,
    required this.icon,
  });
}

class MonthlyExpenseData {
  final String month;
  final double amount;
  final int year;
  final int monthNumber;

  MonthlyExpenseData({
    required this.month,
    required this.amount,
    required this.year,
    required this.monthNumber,
  });
}

class DailyExpenseData {
  final DateTime date;
  final double amount;
  final int transactionCount;

  DailyExpenseData({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}

class GeminiAnalysisResult {
  final String category;
  final String subcategory;
  final double confidence;
  final String insights;
  final List<String> tags;

  GeminiAnalysisResult({
    required this.category,
    required this.subcategory,
    required this.confidence,
    required this.insights,
    required this.tags,
  });

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GeminiAnalysisResult(
      category: json['category'] ?? 'Other',
      subcategory: json['subcategory'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      insights: json['insights'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  final StreamController<List<ExpenseAnalytics>> _analyticsStreamController =
      StreamController<List<ExpenseAnalytics>>.broadcast();
  
  final StreamController<List<MonthlyExpenseData>> _monthlyDataStreamController =
      StreamController<List<MonthlyExpenseData>>.broadcast();

  Stream<List<ExpenseAnalytics>> get analyticsStream => _analyticsStreamController.stream;
  Stream<List<MonthlyExpenseData>> get monthlyDataStream => _monthlyDataStreamController.stream;

  bool _isInitialized = false;
  List<Transaction> _cachedTransactions = [];
  DateTime _lastCacheUpdate = DateTime.now();

  // Category colors and icons mapping
  static const Map<String, Map<String, dynamic>> categoryMapping = {
    'Food': {'color': Colors.orange, 'icon': Icons.restaurant},
    'Transport': {'color': Colors.blue, 'icon': Icons.directions_car},
    'Shopping': {'color': Colors.green, 'icon': Icons.shopping_cart},
    'Utilities': {'color': Colors.red, 'icon': Icons.electrical_services},
    'Entertainment': {'color': Colors.purple, 'icon': Icons.movie},
    'Health': {'color': Colors.pink, 'icon': Icons.local_hospital},
    'Education': {'color': Colors.indigo, 'icon': Icons.school},
    'Financial': {'color': Colors.teal, 'icon': Icons.account_balance},
    'Business': {'color': Colors.brown, 'icon': Icons.business},
    'Phone': {'color': Colors.cyan, 'icon': Icons.phone},
    'Transfer': {'color': Colors.amber, 'icon': Icons.swap_horiz},
    'Withdrawal': {'color': Colors.deepOrange, 'icon': Icons.account_balance_wallet},
    'Other': {'color': Colors.grey, 'icon': Icons.receipt},
  };

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Listen to SMS service for new transactions
      SmsService().transactionStream.listen((transaction) {
        if (transaction.isExpense) {
          _updateCacheWithNewTransaction(transaction);
          _refreshAnalytics();
        }
      });

      await _loadInitialData();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing ExpenseService: $e');
      return false;
    }
  }

  Future<void> _loadInitialData() async {
    try {
      _cachedTransactions = await StorageService.instance.getTransactions();
      _lastCacheUpdate = DateTime.now();
      await _refreshAnalytics();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  void _updateCacheWithNewTransaction(Transaction transaction) {
    _cachedTransactions.add(transaction);
    _cachedTransactions.sort((a, b) => b.date.compareTo(a.date));
    _lastCacheUpdate = DateTime.now();
  }

  Future<void> _refreshAnalytics() async {
    try {
      final analytics = await generateExpenseAnalytics();
      _analyticsStreamController.add(analytics);

      final monthlyData = await generateMonthlyExpenseData();
      _monthlyDataStreamController.add(monthlyData);
    } catch (e) {
      debugPrint('Error refreshing analytics: $e');
    }
  }

  Future<List<ExpenseAnalytics>> generateExpenseAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Refresh cache if needed
      if (DateTime.now().difference(_lastCacheUpdate).inMinutes > 5) {
        await _loadInitialData();
      }

      List<Transaction> expenses = _cachedTransactions
          .where((t) => t.isExpense)
          .toList();

      // Filter by date range if provided
      if (startDate != null) {
        expenses = expenses.where((t) => t.date.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        expenses = expenses.where((t) => t.date.isBefore(endDate)).toList();
      }

      if (expenses.isEmpty) {
        return [];
      }

      // Group by category
      Map<String, List<Transaction>> categoryGroups = {};
      for (var expense in expenses) {
        String category = expense.category;
        categoryGroups[category] = categoryGroups[category] ?? [];
        categoryGroups[category]!.add(expense);
      }

      // Calculate total expenses
      double totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);

      List<ExpenseAnalytics> analytics = [];

      for (var entry in categoryGroups.entries) {
        String category = entry.key;
        List<Transaction> categoryTransactions = entry.value;
        
        double categoryTotal = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
        double percentage = totalExpenses > 0 ? (categoryTotal / totalExpenses) * 100 : 0;
        
        categoryTransactions.sort((a, b) => a.date.compareTo(b.date));
        
        var mapping = categoryMapping[category] ?? categoryMapping['Other']!;
        
        analytics.add(ExpenseAnalytics(
          category: category,
          totalAmount: categoryTotal,
          transactionCount: categoryTransactions.length,
          percentage: percentage,
          firstTransaction: categoryTransactions.first.date,
          lastTransaction: categoryTransactions.last.date,
          transactions: categoryTransactions,
          color: mapping['color'],
          icon: mapping['icon'],
        ));
      }

      // Sort by total amount (descending)
      analytics.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      return analytics;
    } catch (e) {
      debugPrint('Error generating expense analytics: $e');
      return [];
    }
  }

  Future<List<MonthlyExpenseData>> generateMonthlyExpenseData({int months = 12}) async {
    try {
      if (DateTime.now().difference(_lastCacheUpdate).inMinutes > 5) {
        await _loadInitialData();
      }

      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month - months + 1, 1);
      
      List<Transaction> expenses = _cachedTransactions
          .where((t) => t.isExpense && t.date.isAfter(startDate))
          .toList();

      Map<String, double> monthlyTotals = {};
      
      for (var expense in expenses) {
        String monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0.0) + expense.amount;
      }

      List<MonthlyExpenseData> monthlyData = [];
      
      for (int i = 0; i < months; i++) {
        DateTime targetDate = DateTime(now.year, now.month - months + 1 + i, 1);
        String monthKey = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
        
        monthlyData.add(MonthlyExpenseData(
          month: _getMonthName(targetDate.month),
          amount: monthlyTotals[monthKey] ?? 0.0,
          year: targetDate.year,
          monthNumber: targetDate.month,
        ));
      }

      return monthlyData;
    } catch (e) {
      debugPrint('Error generating monthly expense data: $e');
      return [];
    }
  }

  Future<List<DailyExpenseData>> generateDailyExpenseData({int days = 30}) async {
    try {
      if (DateTime.now().difference(_lastCacheUpdate).inMinutes > 5) {
        await _loadInitialData();
      }

      DateTime now = DateTime.now();
      DateTime startDate = now.subtract(Duration(days: days));
      
      List<Transaction> expenses = _cachedTransactions
          .where((t) => t.isExpense && t.date.isAfter(startDate))
          .toList();

      Map<String, Map<String, dynamic>> dailyTotals = {};
      
      for (var expense in expenses) {
        String dateKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';
        dailyTotals[dateKey] = dailyTotals[dateKey] ?? {'amount': 0.0, 'count': 0};
        dailyTotals[dateKey]!['amount'] += expense.amount;
        dailyTotals[dateKey]!['count']++;
      }

      List<DailyExpenseData> dailyData = [];
      
      for (int i = 0; i < days; i++) {
        DateTime targetDate = now.subtract(Duration(days: days - 1 - i));
        String dateKey = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        
        dailyData.add(DailyExpenseData(
          date: targetDate,
          amount: dailyTotals[dateKey]?['amount'] ?? 0.0,
          transactionCount: dailyTotals[dateKey]?['count'] ?? 0,
        ));
      }

      return dailyData;
    } catch (e) {
      debugPrint('Error generating daily expense data: $e');
      return [];
    }
  }

  Future<GeminiAnalysisResult> analyzeTransactionWithGemini(Transaction transaction) async {
    try {
      final prompt = '''
Analyze this M-Pesa transaction and provide insights:

Transaction Details:
- Title: ${transaction.title}
- Amount: Ksh ${transaction.amount}
- Current Category: ${transaction.category}
- Raw SMS: ${transaction.rawSms ?? 'N/A'}
- Date: ${transaction.date}
- Business/Recipient: ${transaction.business ?? transaction.recipient ?? 'N/A'}

Please analyze this transaction and respond in JSON format with:
{
  "category": "primary category (Food, Transport, Shopping, etc.)",
  "subcategory": "more specific category",
  "confidence": confidence_score_0_to_1,
  "insights": "brief insight about spending pattern or recommendation",
  "tags": ["relevant", "tags", "for", "transaction"]
}

Focus on Kenyan context and M-Pesa transaction patterns.
''';

      final response = await _callGeminiAPI(prompt);
      
      if (response != null) {
        try {
          final jsonResponse = json.decode(response);
          return GeminiAnalysisResult.fromJson(jsonResponse);
        } catch (e) {
          debugPrint('Error parsing Gemini JSON response: $e');
        }
      }
    } catch (e) {
      debugPrint('Error analyzing transaction with Gemini: $e');
    }

    // Fallback result
    return GeminiAnalysisResult(
      category: transaction.category,
      subcategory: '',
      confidence: 0.5,
      insights: 'Analysis not available',
      tags: [],
    );
  }

  Future<String> generateSpendingInsights() async {
    try {
      final analytics = await generateExpenseAnalytics();
      final monthlyData = await generateMonthlyExpenseData(months: 3);
      
      if (analytics.isEmpty) {
        return "No expense data available for analysis.";
      }

      String analyticsText = analytics.take(5).map((a) => 
        "${a.category}: Ksh ${a.totalAmount.toStringAsFixed(2)} (${a.percentage.toStringAsFixed(1)}%)"
      ).join(', ');

      String monthlyTrend = monthlyData.map((m) => 
        "${m.month}: Ksh ${m.amount.toStringAsFixed(2)}"
      ).join(', ');

      final prompt = '''
Analyze this spending data from M-Pesa transactions and provide personalized insights:

Top Spending Categories (last period): $analyticsText

Monthly Spending Trend: $monthlyTrend

Total Categories: ${analytics.length}
Total Transactions: ${analytics.fold(0, (sum, a) => sum + a.transactionCount)}

Please provide:
1. Key spending patterns
2. Areas for potential savings
3. Spending behavior insights
4. Practical recommendations for better financial management

Keep it concise and actionable for a Kenyan M-Pesa user.
''';

      return await _callGeminiAPI(prompt) ?? "Unable to generate insights at this time.";
    } catch (e) {
      debugPrint('Error generating spending insights: $e');
      return "Error generating insights. Please try again.";
    }
  }

  Future<String?> _callGeminiAPI(String prompt) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      } else {
        debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
    }
    return null;
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

    Future<double> getTotalExpensesForPeriod({DateTime? start, DateTime? end}) async {
    final analytics = await generateExpenseAnalytics(startDate: start, endDate: end);
    return analytics.fold<double>(0.0, (sum, a) => sum + a.totalAmount);
  }

  Future<double> getTransactionCountForPeriod({DateTime? start, DateTime? end}) async {
    final analytics = await generateExpenseAnalytics(startDate: start, endDate: end);
    return analytics.fold<double>(0.0, (sum, a) => sum + a.transactionCount);
  }

  Future<String> getTopSpendingCategory() async {
    final analytics = await generateExpenseAnalytics();
    return analytics.isNotEmpty ? analytics.first.category : 'No data';
  }

  Future<Map<String, dynamic>> getQuickStats() async {
    try {
      final thisMonth = await generateExpenseAnalytics(
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      );
      
      final lastMonth = await generateExpenseAnalytics(
        startDate: DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
        endDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      );

      double thisMonthTotal = thisMonth.fold(0.0, (sum, a) => sum + a.totalAmount);
      double lastMonthTotal = lastMonth.fold(0.0, (sum, a) => sum + a.totalAmount);
      
      double percentageChange = lastMonthTotal > 0 
          ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100 
          : 0;

      return {
        'thisMonthTotal': thisMonthTotal,
        'lastMonthTotal': lastMonthTotal,
        'percentageChange': percentageChange,
        'topCategory': thisMonth.isNotEmpty ? thisMonth.first.category : 'No data',
        'transactionCount': thisMonth.fold(0, (sum, a) => sum + a.transactionCount),
      };
    } catch (e) {
      debugPrint('Error getting quick stats: $e');
      return {
        'thisMonthTotal': 0.0,
        'lastMonthTotal': 0.0,
        'percentageChange': 0.0,
        'topCategory': 'No data',
        'transactionCount': 0,
      };
    }
  }

  Future<void> refreshData() async {
    await _loadInitialData();
  }

  void dispose() {
    _analyticsStreamController.close();
    _monthlyDataStreamController.close();
  }
}