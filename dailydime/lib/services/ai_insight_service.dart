// lib/services/ai_insights_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/services/appwrite_service.dart';

class AIInsightsService {
  static final AIInsightsService _instance = AIInsightsService._internal();
  factory AIInsightsService() => _instance;
  AIInsightsService._internal();

  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final Map<String, dynamic> _cachedInsights = {};
  
  // Cache duration in minutes
  static const int _cacheMinutes = 30;

  Future<Map<String, dynamic>> getSmartInsights() async {
    final cacheKey = 'smart_insights';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _cachedInsights[cacheKey]['data'];
    }

    try {
      // Get transaction data
      final transactions = await StorageService.instance.getTransactions();
      final currentBalance = await SmsService().getCurrentBalance();
      
      if (transactions.isEmpty) {
        return _getDefaultInsights();
      }

      // Prepare data for Gemini AI
      final analysisData = _prepareTransactionData(transactions, currentBalance);
      
      // Get AI insights
      final aiResponse = await _callGeminiAI(
        'Analyze my financial data and provide insights',
        analysisData
      );
      
      final insights = _parseAIResponse(aiResponse, transactions, currentBalance);
      
      // Cache the results
      _cacheInsights(cacheKey, insights);
      
      return insights;
    } catch (e) {
      debugPrint('Error getting smart insights: $e');
      return _getDefaultInsights();
    }
  }

  Future<List<Map<String, dynamic>>> getPredictiveAlerts() async {
    final cacheKey = 'predictive_alerts';
    
    if (_isCacheValid(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cachedInsights[cacheKey]['data']);
    }

    try {
      final transactions = await StorageService.instance.getTransactions();
      final currentBalance = await SmsService().getCurrentBalance();
      
      if (transactions.isEmpty) {
        return [];
      }

      // Get recent spending patterns
      final recentTransactions = _getRecentTransactions(transactions, 30);
      final monthlySpending = _calculateMonthlySpending(recentTransactions);
      
      final alerts = <Map<String, dynamic>>[];
      
      // Budget overspend alert
      if (monthlySpending > currentBalance * 0.8) {
        alerts.add({
          'type': 'budget_warning',
          'title': 'High Spending Alert',
          'message': 'You\'ve spent ${AppConfig.formatCurrency((monthlySpending * 100).toInt())} this month',
          'severity': 'high',
          'icon': Icons.warning,
          'color': Colors.orange,
          'action': 'Review your budget'
        });
      }
      
      // Low balance warning
      if (currentBalance < 1000) {
        alerts.add({
          'type': 'low_balance',
          'title': 'Low Balance',
          'message': 'Your M-Pesa balance is running low',
          'severity': 'medium',
          'icon': Icons.account_balance_wallet,
          'color': Colors.red,
          'action': 'Consider topping up'
        });
      }
      
      // Unusual spending pattern
      final unusualSpending = _detectUnusualSpending(transactions);
      if (unusualSpending.isNotEmpty) {
        alerts.add({
          'type': 'unusual_spending',
          'title': 'Unusual Spending Detected',
          'message': unusualSpending,
          'severity': 'low',
          'icon': Icons.trending_up,
          'color': Colors.blue,
          'action': 'Review transactions'
        });
      }
      
      _cacheInsights(cacheKey, alerts);
      return alerts;
    } catch (e) {
      debugPrint('Error getting predictive alerts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getCashflowForecast() async {
    final cacheKey = 'cashflow_forecast';
    
    if (_isCacheValid(cacheKey)) {
      return _cachedInsights[cacheKey]['data'];
    }

    try {
      final transactions = await StorageService.instance.getTransactions();
      final currentBalance = await SmsService().getCurrentBalance();
      
      if (transactions.isEmpty) {
        return {'forecast': [], 'trend': 'stable'};
      }

      // Calculate daily average spending
      final recentTransactions = _getRecentTransactions(transactions, 30);
      final dailySpending = _calculateDailyAverageSpending(recentTransactions);
      final dailyIncome = _calculateDailyAverageIncome(recentTransactions);
      
      // Forecast next 30 days
      final forecast = <Map<String, dynamic>>[];
      var projectedBalance = currentBalance;
      
      for (int i = 1; i <= 30; i++) {
        projectedBalance = projectedBalance + dailyIncome - dailySpending;
        forecast.add({
          'day': i,
          'balance': projectedBalance,
          'date': DateTime.now().add(Duration(days: i)),
        });
      }
      
      String trend = 'stable';
      if (dailySpending > dailyIncome) {
        trend = 'declining';
      } else if (dailyIncome > dailySpending * 1.2) {
        trend = 'growing';
      }
      
      final result = {
        'forecast': forecast,
        'trend': trend,
        'dailySpending': dailySpending,
        'dailyIncome': dailyIncome,
        'projectedBalance30Days': forecast.isNotEmpty ? forecast.last['balance'] : currentBalance,
      };
      
      _cacheInsights(cacheKey, result);
      return result;
    } catch (e) {
      debugPrint('Error getting cashflow forecast: $e');
      return {'forecast': [], 'trend': 'stable'};
    }
  }

  Future<List<Map<String, dynamic>>> getSmartRecommendations() async {
    final cacheKey = 'smart_recommendations';
    
    if (_isCacheValid(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cachedInsights[cacheKey]['data']);
    }

    try {
      final transactions = await StorageService.instance.getTransactions();
      final currentBalance = await SmsService().getCurrentBalance();
      
      final recommendations = <Map<String, dynamic>>[];
      
      if (transactions.isEmpty) {
        recommendations.add({
          'title': 'Start Tracking',
          'description': 'Begin monitoring your spending patterns',
          'type': 'setup',
          'priority': 'high',
          'icon': Icons.track_changes,
        });
        return recommendations;
      }

      // Analyze spending patterns
      final categorySpending = await SmsService().getExpensesByCategory();
      final totalExpenses = await SmsService().getTotalExpenses();
      final totalIncome = await SmsService().getTotalIncome();
      
      // Savings recommendation
      if (totalIncome > totalExpenses) {
        final savingsPotential = totalIncome - totalExpenses;
        recommendations.add({
          'title': 'Savings Opportunity',
          'description': 'You could save ${AppConfig.formatCurrency((savingsPotential * 100).toInt())} monthly',
          'type': 'savings',
          'priority': 'high',
          'icon': Icons.savings,
          'action': 'Set up automatic savings'
        });
      }
      
      // Budget recommendation
      if (categorySpending.isNotEmpty) {
        final topCategory = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b);
        recommendations.add({
          'title': 'Budget Alert: ${topCategory.key}',
          'description': 'This is your highest spending category at ${AppConfig.formatCurrency((topCategory.value * 100).toInt())}',
          'type': 'budget',
          'priority': 'medium',
          'icon': Icons.pie_chart,
          'action': 'Set spending limit'
        });
      }
      
      // Emergency fund recommendation
      if (currentBalance < totalExpenses * 3) {
        recommendations.add({
          'title': 'Emergency Fund',
          'description': 'Consider building an emergency fund worth 3 months of expenses',
          'type': 'emergency',
          'priority': 'medium',
          'icon': Icons.security,
          'action': 'Start emergency savings'
        });
      }
      
      _cacheInsights(cacheKey, recommendations);
      return recommendations;
    } catch (e) {
      debugPrint('Error getting smart recommendations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSpendingPatterns() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      if (transactions.isEmpty) {
        return {'patterns': [], 'insights': 'No data available'};
      }

      final patterns = <String, dynamic>{};
      
      // Daily spending pattern
      final dailySpending = <String, double>{};
      for (var transaction in transactions.where((t) => t.isExpense)) {
        final day = _getDayOfWeek(transaction.date);
        dailySpending[day] = (dailySpending[day] ?? 0) + transaction.amount;
      }
      
      // Category distribution
      final categorySpending = await SmsService().getExpensesByCategory();
      
      // Peak spending day
      String peakDay = 'Monday';
      double maxSpending = 0;
      dailySpending.forEach((day, amount) {
        if (amount > maxSpending) {
          maxSpending = amount;
          peakDay = day;
        }
      });
      
      patterns['dailySpending'] = dailySpending;
      patterns['categoryDistribution'] = categorySpending;
      patterns['peakSpendingDay'] = peakDay;
      patterns['averageTransaction'] = transactions.isNotEmpty 
        ? transactions.where((t) => t.isExpense).map((t) => t.amount).reduce((a, b) => a + b) / transactions.where((t) => t.isExpense).length
        : 0.0;
      
      return patterns;
    } catch (e) {
      debugPrint('Error getting spending patterns: $e');
      return {'patterns': [], 'insights': 'Error analyzing patterns'};
    }
  }

  Future<List<Map<String, dynamic>>> getChartData() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      if (transactions.isEmpty) {
        return [];
      }

      final chartData = <Map<String, dynamic>>[];
      
      // Monthly spending trend
      final monthlyData = <String, double>{};
      for (var transaction in transactions.where((t) => t.isExpense)) {
        final month = '${transaction.date.month}/${transaction.date.year}';
        monthlyData[month] = (monthlyData[month] ?? 0) + transaction.amount;
      }
      
      chartData.add({
        'type': 'line',
        'title': 'Monthly Spending Trend',
        'data': monthlyData.entries.map((e) => {'x': e.key, 'y': e.value}).toList(),
      });
      
      // Category breakdown
      final categoryData = await SmsService().getExpensesByCategory();
      chartData.add({
        'type': 'pie',
        'title': 'Spending by Category',
        'data': categoryData.entries.map((e) => {'label': e.key, 'value': e.value}).toList(),
      });
      
      // Income vs Expenses
      final totalIncome = await SmsService().getTotalIncome();
      final totalExpenses = await SmsService().getTotalExpenses();
      chartData.add({
        'type': 'bar',
        'title': 'Income vs Expenses',
        'data': [
          {'label': 'Income', 'value': totalIncome, 'color': Colors.green},
          {'label': 'Expenses', 'value': totalExpenses, 'color': Colors.red},
        ],
      });
      
      return chartData;
    } catch (e) {
      debugPrint('Error getting chart data: $e');
      return [];
    }
  }

  // Private helper methods
  Future<String> _callGeminiAI(String prompt, Map<String, dynamic> data) async {
    try {
      final url = '$_baseUrl/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}';
      
      final requestBody = {
        'contents': [{
          'parts': [{
            'text': '$prompt\n\nFinancial Data: ${jsonEncode(data)}\n\nProvide practical insights and actionable advice in a friendly, conversational tone.'
          }]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No insights available';
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
        return 'Unable to generate insights at this time';
      }
    } catch (e) {
      debugPrint('Error calling Gemini AI: $e');
      return 'Error generating insights';
    }
  }

  Map<String, dynamic> _prepareTransactionData(List<Transaction> transactions, double currentBalance) {
    final recentTransactions = _getRecentTransactions(transactions, 30);
    
    return {
      'currentBalance': currentBalance,
      'totalTransactions': transactions.length,
      'recentTransactionsCount': recentTransactions.length,
      'totalExpenses': transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount),
      'totalIncome': transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount),
      'categoryBreakdown': _getCategoryBreakdown(recentTransactions),
      'averageTransaction': recentTransactions.isNotEmpty 
        ? recentTransactions.map((t) => t.amount).reduce((a, b) => a + b) / recentTransactions.length 
        : 0,
      'timespan': '${transactions.isNotEmpty ? transactions.first.date.toString() : 'N/A'} to ${DateTime.now()}',
    };
  }

  Map<String, dynamic> _parseAIResponse(String aiResponse, List<Transaction> transactions, double currentBalance) {
    // Extract key metrics
    final totalExpenses = transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final netFlow = totalIncome - totalExpenses;
    
    return {
      'aiInsight': aiResponse,
      'keyMetrics': {
        'currentBalance': currentBalance,
        'totalExpenses': totalExpenses,
        'totalIncome': totalIncome,
        'netFlow': netFlow,
        'transactionCount': transactions.length,
      },
      'quickStats': {
        'avgDailySpending': _calculateDailyAverageSpending(_getRecentTransactions(transactions, 30)),
        'topCategory': _getTopSpendingCategory(transactions),
        'spendingTrend': netFlow >= 0 ? 'positive' : 'negative',
      },
      'timestamp': DateTime.now(),
    };
  }

  List<Transaction> _getRecentTransactions(List<Transaction> transactions, int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return transactions.where((t) => t.date.isAfter(cutoffDate)).toList();
  }

  double _calculateMonthlySpending(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.isExpense);
    return expenses.fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateDailyAverageSpending(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) return 0.0;
    
    final totalSpending = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final days = expenses.isNotEmpty ? 30 : 1; // Assume 30 days for recent transactions
    return totalSpending / days;
  }

  double _calculateDailyAverageIncome(List<Transaction> transactions) {
    final income = transactions.where((t) => !t.isExpense).toList();
    if (income.isEmpty) return 0.0;
    
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final days = income.isNotEmpty ? 30 : 1;
    return totalIncome / days;
  }

  String _detectUnusualSpending(List<Transaction> transactions) {
    if (transactions.length < 10) return '';
    
    final recentTransactions = _getRecentTransactions(transactions, 7);
    final historicalTransactions = transactions.where((t) => 
      t.date.isBefore(DateTime.now().subtract(const Duration(days: 7)))).toList();
    
    if (recentTransactions.isEmpty || historicalTransactions.isEmpty) return '';
    
    final recentAvg = recentTransactions.where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount) / 7;
    final historicalAvg = historicalTransactions.where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount) / historicalTransactions.length;
    
    if (recentAvg > historicalAvg * 1.5) {
      return 'Your spending has increased by ${((recentAvg / historicalAvg - 1) * 100).toStringAsFixed(0)}% this week';
    }
    
    return '';
  }

  Map<String, double> _getCategoryBreakdown(List<Transaction> transactions) {
    final breakdown = <String, double>{};
    for (var transaction in transactions.where((t) => t.isExpense)) {
      breakdown[transaction.category] = (breakdown[transaction.category] ?? 0) + transaction.amount;
    }
    return breakdown;
  }

  String _getTopSpendingCategory(List<Transaction> transactions) {
    final categorySpending = _getCategoryBreakdown(transactions);
    if (categorySpending.isEmpty) return 'None';
    
    return categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Map<String, dynamic> _getDefaultInsights() {
    return {
      'aiInsight': 'Start tracking your transactions to get personalized insights!',
      'keyMetrics': {
        'currentBalance': 0.0,
        'totalExpenses': 0.0,
        'totalIncome': 0.0,
        'netFlow': 0.0,
        'transactionCount': 0,
      },
      'quickStats': {
        'avgDailySpending': 0.0,
        'topCategory': 'None',
        'spendingTrend': 'neutral',
      },
      'timestamp': DateTime.now(),
    };
  }

  bool _isCacheValid(String key) {
    if (!_cachedInsights.containsKey(key)) return false;
    
    final cacheTime = _cachedInsights[key]['timestamp'] as DateTime;
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _cacheMinutes;
  }

  void _cacheInsights(String key, dynamic data) {
    _cachedInsights[key] = {
      'data': data,
      'timestamp': DateTime.now(),
    };
  }

  void clearCache() {
    _cachedInsights.clear();
  }

  // Public method to refresh all insights
  Future<void> refreshAllInsights() async {
    clearCache();
    await Future.wait([
      getSmartInsights(),
      getPredictiveAlerts(),
      getCashflowForecast(),
      getSmartRecommendations(),
    ]);
  }
}