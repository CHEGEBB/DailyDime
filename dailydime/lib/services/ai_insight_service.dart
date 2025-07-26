// lib/services/ai_insight_service.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

class AIInsightService {
  final AppwriteService _appwriteService;
  final String _apiKey = AppConfig.geminiApiKey;
  GenerativeModel? _model;

  AIInsightService(this._appwriteService) {
    _initializeGemini();
  }

  void _initializeGemini() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
      );
    }
  }

  // Fetch financial data from Appwrite
  Future<Map<String, dynamic>> fetchFinancialData() async {
    try {
      // Get transactions for last 3 months
      final transactions = await _appwriteService.getTransactions(limit: 100);
      final goals = await _appwriteService.getSavingsGoals();
      
      // Group and analyze the data
      return {
        'transactions': transactions,
        'goals': goals,
        'stats': _calculateFinancialStats(transactions, goals),
        'insights': await _generateInsights(transactions, goals),
      };
    } catch (e) {
      print('Error fetching financial data: $e');
      return {
        'transactions': [],
        'goals': [],
        'stats': _getEmptyStats(),
        'insights': [],
      };
    }
  }

  // Calculate financial statistics
  Map<String, dynamic> _calculateFinancialStats(
      List<Transaction> transactions, List<SavingsGoal> goals) {
    // Filter transactions by date
    final now = DateTime.now();
    final thisMonth = transactions.where((t) => 
      t.date.month == now.month && t.date.year == now.year).toList();
    
    // Calculate basic metrics
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalSavings = 0;
    
    for (var t in thisMonth) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
      }
    }
    
    // Calculate savings and goals progress
    for (var goal in goals) {
      totalSavings += goal.currentAmount;
    }
    
    // Calculate financial health score (0-100)
    int financialHealthScore = _calculateFinancialHealthScore(
      totalIncome, totalExpenses, totalSavings, goals);
    
    // Generate category breakdown
    final categoryBreakdown = _getCategoryBreakdown(transactions);
    
    // Generate weekly spending data
    final weeklySpending = _getWeeklySpending(transactions);
    
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalSavings': totalSavings,
      'monthlySavings': totalIncome - totalExpenses,
      'dailyAverage': totalExpenses / 30,
      'activeGoalsCount': goals.where((g) => !g.isCompleted).length,
      'financialHealthScore': financialHealthScore,
      'savingsGrowthPercentage': _calculateSavingsGrowth(transactions, goals),
      'categoryBreakdown': categoryBreakdown,
      'weeklySpending': weeklySpending,
      'predictedSpending': _getPredictedSpending(transactions),
      'spendingPatterns': _getSpendingPatterns(transactions),
    };
  }

  // Calculate financial health score
  int _calculateFinancialHealthScore(
      double income, double expenses, double savings, List<SavingsGoal> goals) {
    if (income == 0) return 50; // Default middle score
    
    // Factors that contribute to score
    double savingsRatio = savings / (income * 3); // Savings relative to 3 months income
    double expenseToIncomeRatio = expenses / income;
    double goalsProgress = 0;
    
    if (goals.isNotEmpty) {
      double totalGoalAmount = 0;
      double totalCurrentAmount = 0;
      
      for (var goal in goals) {
        totalGoalAmount += goal.targetAmount;
        totalCurrentAmount += goal.currentAmount;
      }
      
      goalsProgress = totalCurrentAmount / totalGoalAmount;
    }
    
    // Calculate score (higher is better)
    int score = 50;
    
    // Good savings ratio improves score
    if (savingsRatio > 0.5) score += 20;
    else if (savingsRatio > 0.25) score += 10;
    else if (savingsRatio > 0.1) score += 5;
    
    // Low expense to income ratio improves score
    if (expenseToIncomeRatio < 0.5) score += 20;
    else if (expenseToIncomeRatio < 0.7) score += 10;
    else if (expenseToIncomeRatio < 0.9) score += 5;
    
    // Good goal progress improves score
    if (goalsProgress > 0.8) score += 10;
    else if (goalsProgress > 0.5) score += 5;
    
    // Cap score at 100
    return score > 100 ? 100 : score;
  }

  // Calculate savings growth percentage
  double _calculateSavingsGrowth(
      List<Transaction> transactions, List<SavingsGoal> goals) {
    // Default if not enough data
    if (goals.isEmpty) return 0;
    
    // Simple positive number for demo - in production would compare to previous period
    return 12.5; // Example growth percentage
  }

  // Get category breakdown
  List<Map<String, dynamic>> _getCategoryBreakdown(List<Transaction> transactions) {
    Map<String, double> categoryTotals = {};
    
    // Get only expense transactions from current month
    final now = DateTime.now();
    final thisMonthExpenses = transactions.where((t) => 
      t.type == 'expense' && 
      t.date.month == now.month && 
      t.date.year == now.year).toList();
    
    // Sum amounts by category
    for (var t in thisMonthExpenses) {
      if (categoryTotals.containsKey(t.category)) {
        categoryTotals[t.category] = categoryTotals[t.category]! + t.amount;
      } else {
        categoryTotals[t.category] = t.amount;
      }
    }
    
    // Convert to list and sort by amount (descending)
    List<Map<String, dynamic>> result = [];
    categoryTotals.forEach((category, amount) {
      result.add({
        'name': category,
        'amount': amount,
        'color': _getCategoryColor(category),
      });
    });
    
    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    // Return top 5 categories or all if less than 5
    return result.take(5).toList();
  }

  // Get category color
  Color _getCategoryColor(String category) {
    final Map<String, Color> categoryColors = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Housing': Colors.purple,
      'Entertainment': Colors.pink,
      'Shopping': Colors.teal,
      'Health': Colors.red,
      'Education': Colors.amber,
      'Utilities': Colors.indigo,
      'Other': Colors.grey,
    };
    
    return categoryColors[category] ?? Colors.grey;
  }

  // Get weekly spending data
  List<Map<String, dynamic>> _getWeeklySpending(List<Transaction> transactions) {
    // Get only expenses from last 4 weeks
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    
    final recentExpenses = transactions.where((t) => 
      t.type == 'expense' && 
      t.date.isAfter(fourWeeksAgo)).toList();
    
    // Group by week
    Map<int, double> weeklyTotals = {};
    
    for (var t in recentExpenses) {
      // Calculate week number (0 = current week, 1 = last week, etc.)
      int daysSinceToday = now.difference(t.date).inDays;
      int weekNumber = daysSinceToday ~/ 7;
      
      if (weekNumber < 4) { // Only consider last 4 weeks
        if (weeklyTotals.containsKey(weekNumber)) {
          weeklyTotals[weekNumber] = weeklyTotals[weekNumber]! + t.amount;
        } else {
          weeklyTotals[weekNumber] = t.amount;
        }
      }
    }
    
    // Convert to list format for charts
    List<Map<String, dynamic>> result = [];
    
    for (int i = 3; i >= 0; i--) {
      String weekLabel = i == 0 ? 'This Week' : '${i} Week${i > 1 ? 's' : ''} Ago';
      result.add({
        'week': weekLabel,
        'amount': weeklyTotals[i] ?? 0,
      });
    }
    
    return result;
  }

  // Get predicted spending for next month
  List<Map<String, dynamic>> _getPredictedSpending(List<Transaction> transactions) {
    // In a real app, this would use ML to predict future spending
    // For demo, we'll just project based on current month's spending
    
    // Get current month's daily spending average
    final now = DateTime.now();
    final thisMonthExpenses = transactions.where((t) => 
      t.type == 'expense' && 
      t.date.month == now.month && 
      t.date.year == now.year).toList();
    
    double dailyAverage = 0;
    if (thisMonthExpenses.isNotEmpty) {
      double totalExpenses = thisMonthExpenses.fold(0, (sum, t) => sum + t.amount);
      int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      dailyAverage = totalExpenses / daysInMonth;
    }
    
    // Project next month spending (with some variation)
    List<Map<String, dynamic>> result = [];
    int daysInNextMonth = DateTime(now.year, now.month + 2, 0).day;
    
    for (int week = 1; week <= 4; week++) {
      // Add some randomness to predictions for visual interest
      double weeklyAmount = dailyAverage * 7 * (1 + (week % 3 - 1) * 0.1);
      
      result.add({
        'week': 'Week $week',
        'amount': weeklyAmount > 0 ? weeklyAmount : dailyAverage * 7,
        'isPrediction': true,
      });
    }
    
    return result;
  }

  // Get spending patterns
  List<Map<String, dynamic>> _getSpendingPatterns(List<Transaction> transactions) {
    // In production, this would use clustering algorithms to find patterns
    // For demo, we'll use predefined patterns
    
    return [
      {'name': 'Essentials', 'percentage': 45, 'color': Colors.blue},
      {'name': 'Impulse Buys', 'percentage': 25, 'color': Colors.orange},
      {'name': 'Entertainment', 'percentage': 20, 'color': Colors.purple},
      {'name': 'Investments', 'percentage': 10, 'color': Colors.green},
    ];
  }

  // Generate AI insights using Gemini
  Future<List<Map<String, dynamic>>> _generateInsights(
      List<Transaction> transactions, List<SavingsGoal> goals) async {
    // Default insights if Gemini not available
    List<Map<String, dynamic>> defaultInsights = [
      {
        'title': 'Spending Pattern',
        'description': 'You spend more on weekends than weekdays. Consider planning weekend activities in advance.',
        'icon': Icons.calendar_today,
        'color': Colors.blue,
        'showChart': false,
        'actionable': true,
        'actionText': 'View Weekend Expenses',
      },
      {
        'title': 'Savings Opportunity',
        'description': 'You could save KSh 4,500 by reducing dining out expenses this month.',
        'icon': Icons.restaurant,
        'color': Colors.green,
        'showChart': false,
        'actionable': true,
        'actionText': 'See How',
      },
      {
        'title': 'Budget Alert',
        'description': 'You\'re spending faster than usual this month. Consider slowing down to stay on budget.',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'showChart': true,
        'chartData': _getWeeklySpending(transactions),
        'actionable': false,
      },
    ];
    
    // If no Gemini API key or not enough data, return default insights
    if (_model == null || transactions.length < 5) {
      return defaultInsights;
    }
    
    try {
      // Prepare data for Gemini
      final promptData = _prepareDataForGemini(transactions, goals);
      
      // Get response from Gemini
      final content = [Content.text(promptData)];
      final response = await _model!.generateContent(content);
      final responseText = response.text ?? '';
      
      // Parse response to insights
      if (responseText.isNotEmpty) {
        return _parseGeminiResponse(responseText) ?? defaultInsights;
      }
      
      return defaultInsights;
    } catch (e) {
      print('Error generating insights with Gemini: $e');
      return defaultInsights;
    }
  }

  // Prepare data for Gemini prompt
  String _prepareDataForGemini(
      List<Transaction> transactions, List<SavingsGoal> goals) {
    // Create a simplified representation of data for the prompt
    String transactionSummary = '';
    String goalSummary = '';
    
    // Summarize recent transactions
    final recentTransactions = transactions.take(20).toList();
    for (var t in recentTransactions) {
      transactionSummary += '${t.date.toString().substring(0, 10)}: ${t.type} of ${t.amount} for ${t.category}\n';
    }
    
    // Summarize goals
    for (var g in goals) {
      goalSummary += '${g.title}: ${g.currentAmount}/${g.targetAmount} (${(g.currentAmount/g.targetAmount*100).toStringAsFixed(0)}% complete)\n';
    }
    
    // Create prompt
    return '''
    You are a financial advisor analyzing user spending patterns. Please provide 3 financial insights based on the following data:
    
    RECENT TRANSACTIONS:
    $transactionSummary
    
    SAVING GOALS:
    $goalSummary
    
    Generate 3 insights in the following JSON format:
    [
      {
        "title": "Brief insight title",
        "description": "Detailed explanation of the insight in 1-2 sentences",
        "actionable": true/false (whether this has an action the user can take),
        "actionText": "Text for action button if actionable is true"
      }
    ]
    
    Only return the JSON array, nothing else.
    ''';
  }

  // Parse Gemini response to insights
  List<Map<String, dynamic>>? _parseGeminiResponse(String response) {
    try {
      // Extract JSON part if there's other text
      String jsonPart = response;
      if (response.contains('[') && response.contains(']')) {
        jsonPart = response.substring(
          response.indexOf('['),
          response.lastIndexOf(']') + 1,
        );
      }
      
      // Parse JSON
      List<dynamic> parsed = jsonDecode(jsonPart);
      
      // Convert to insight format
      List<Map<String, dynamic>> insights = [];
      
      // Icons to use for different insight types
      final Map<String, IconData> insightIcons = {
        'spend': Icons.money_off,
        'save': Icons.savings,
        'budget': Icons.account_balance_wallet,
        'goal': Icons.flag,
        'pattern': Icons.insights,
        'alert': Icons.warning_amber,
        'opportunity': Icons.lightbulb_outline,
      };
      
      // Colors to use for different insight types
      final Map<String, Color> insightColors = {
        'spend': Colors.red,
        'save': Colors.green,
        'budget': Colors.blue,
        'goal': Colors.purple,
        'pattern': Colors.teal,
        'alert': Colors.orange,
        'opportunity': Colors.amber,
      };
      
      for (var item in parsed) {
        // Determine icon and color based on title keywords
        String title = item['title'].toLowerCase();
        IconData icon = Icons.insights;
        Color color = Colors.blue;
        
        for (var key in insightIcons.keys) {
          if (title.contains(key)) {
            icon = insightIcons[key]!;
            color = insightColors[key]!;
            break;
          }
        }
        
        insights.add({
          'title': item['title'],
          'description': item['description'],
          'icon': icon,
          'color': color,
          'showChart': false,
          'actionable': item['actionable'] ?? false,
          'actionText': item['actionText'] ?? 'Learn More',
        });
      }
      
      return insights;
    } catch (e) {
      print('Error parsing Gemini response: $e');
      return null;
    }
  }

  // Get weekly spending trend
  Map<String, dynamic> getWeeklyTrend(List<Transaction> transactions) {
    final weeklySpendings = _getWeeklySpending(transactions);
    
    if (weeklySpendings.length < 2) {
      return {
        'isPositive': true,
        'title': 'Not Enough Data',
        'description': 'Add more transactions to see your weekly trends.',
      };
    }
    
    // Compare this week with last week
    double thisWeek = weeklySpendings.last['amount'];
    double lastWeek = weeklySpendings[weeklySpendings.length - 2]['amount'];
    
    bool isPositive = thisWeek < lastWeek; // Lower spending is positive
    double percentChange = lastWeek > 0 
        ? ((lastWeek - thisWeek) / lastWeek * 100).abs() 
        : 0;
    
    String title = isPositive
        ? 'Spending Decreased'
        : 'Spending Increased';
        
    String description = isPositive
        ? 'You spent ${percentChange.toStringAsFixed(0)}% less this week compared to last week.'
        : 'You spent ${percentChange.toStringAsFixed(0)}% more this week compared to last week.';
    
    return {
      'isPositive': isPositive,
      'title': title,
      'description': description,
    };
  }

  // Get smart saving recommendation
  Map<String, dynamic> getSmartSavingRecommendation(List<Transaction> transactions) {
    // In production, this would analyze spending patterns to find saving opportunities
    // For demo, we'll use a predefined recommendation
    
    return {
      'amount': 65,
      'title': 'Reduce dining out expenses',
      'description': 'By cooking at home 2 out of 4 times instead of eating out, you can save roughly KSh 65 based on your previous spending.',
      'category': 'Food',
    };
  }

  // Get empty stats for initialization
  Map<String, dynamic> _getEmptyStats() {
    return {
      'totalIncome': 0.0,
      'totalExpenses': 0.0,
      'totalSavings': 0.0,
      'monthlySavings': 0.0,
      'dailyAverage': 0.0,
      'activeGoalsCount': 0,
      'financialHealthScore': 50,
      'savingsGrowthPercentage': 0.0,
      'categoryBreakdown': [],
      'weeklySpending': [],
      'predictedSpending': [],
      'spendingPatterns': [],
    };
  }

  // Get financial advice from Gemini
  Future<String> getFinancialAdvice(String question) async {
    if (_model == null) {
      return "I'm sorry, but the AI advisor is currently unavailable. Please try again later.";
    }
    
    try {
      // Create prompt
      String prompt = '''
      You are a helpful financial advisor named Gemini. The user is asking for financial advice.
      Answer their question in a friendly, helpful way. Keep your response concise (maximum 3 paragraphs).
      Focus on practical, actionable advice. Here's their question:
      
      "$question"
      ''';
      
      // Get response from Gemini
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text ?? '';
      
      if (responseText.isEmpty) {
        return "I'm sorry, but I couldn't generate advice at this time. Please try asking in a different way.";
      }
      
      return responseText;
    } catch (e) {
      print('Error getting financial advice: $e');
      return "I'm sorry, but I encountered an error while generating advice. Please try again later.";
    }
  }
}