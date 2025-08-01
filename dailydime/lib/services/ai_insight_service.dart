// lib/services/ai_insights_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:intl/intl.dart';

class AIInsightsService {
  static final AIInsightsService _instance = AIInsightsService._internal();
  factory AIInsightsService() => _instance;
  AIInsightsService._internal();

  final AppwriteService _appwriteService = AppwriteService();
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
      final transactions = await _getTransactions();
      final budgets = await _getBudgets();
      final savingsGoals = await _getSavingsGoals();
      final currentBalance = await SmsService().getCurrentBalance();
      
      if (transactions.isEmpty) {
        return _getDefaultInsights();
      }

      // Prepare data for Gemini AI
      final analysisData = _prepareFinancialData(
        transactions, 
        budgets, 
        savingsGoals, 
        currentBalance
      );
      
      // Get AI insights
      final aiResponse = await _callGeminiAI(
        '''Analyze my financial data and provide personalized insights:
        1. Spending patterns and trends
        2. Budget performance
        3. Savings opportunities
        4. Financial health summary
        5. Top 3 actionable recommendations
        
        Make insights specific, data-driven and personalized to my situation.''',
        analysisData
      );
      
      final insights = _parseAIResponse(
        aiResponse, 
        transactions, 
        budgets,
        savingsGoals,
        currentBalance
      );
      
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
      final transactions = await _getTransactions();
      final budgets = await _getBudgets();
      final currentBalance = await SmsService().getCurrentBalance();
      
      if (transactions.isEmpty) {
        return [];
      }

      // Prepare data for Gemini AI
      final alertsData = {
        'transactions': _serializeTransactions(transactions),
        'budgets': _serializeBudgets(budgets),
        'currentBalance': currentBalance,
        'currency': AppConfig.primaryCurrency,
      };

      // Get AI alerts
      final aiResponse = await _callGeminiAI(
        '''Analyze my financial data and generate personalized alerts:
        1. Potential budget overspending
        2. Unusual spending patterns
        3. Recurring payment warnings
        4. Low balance alerts
        5. Fraudulent activity risks

        For each alert, provide:
        - Alert type
        - Severity (high/medium/low)
        - Specific details with amounts
        - Suggested action

        Format as JSON array with objects containing title, message, severity, and action.''',
        alertsData
      );
      
      List<Map<String, dynamic>> alerts = [];
      
      try {
        // Try to parse structured JSON from the AI response
        final parsedJson = jsonDecode(aiResponse);
        if (parsedJson is List) {
          alerts = List<Map<String, dynamic>>.from(parsedJson);
        }
      } catch (e) {
        // Fallback to manually creating alerts if JSON parsing fails
        alerts = _generateDefaultAlerts(transactions, budgets, currentBalance);
      }
      
      // Enrich alerts with UI metadata
      final enrichedAlerts = alerts.map((alert) {
        final severity = alert['severity'] ?? 'medium';
        
        IconData icon = Icons.info_outline;
        Color color = Colors.blue;
        
        if (alert['type'] == 'budget_warning' || alert['type'] == 'overspending') {
          icon = Icons.account_balance_wallet;
          color = Colors.orange;
        } else if (alert['type'] == 'low_balance') {
          icon = Icons.money_off;
          color = Colors.red;
        } else if (alert['type'] == 'unusual_spending') {
          icon = Icons.trending_up;
          color = Colors.purple;
        } else if (alert['type'] == 'fraudulent' || alert['type'] == 'security') {
          icon = Icons.security;
          color = Colors.red;
        } else if (alert['type'] == 'recurring') {
          icon = Icons.repeat;
          color = Colors.green;
        }
        
        return {
          ...alert,
          'icon': icon,
          'color': color,
        };
      }).toList();
      
      _cacheInsights(cacheKey, enrichedAlerts);
      return enrichedAlerts;
    } catch (e) {
      debugPrint('Error getting predictive alerts: $e');
      return _generateDefaultAlerts(await _getTransactions(), await _getBudgets(), await SmsService().getCurrentBalance());
    }
  }

  Future<Map<String, dynamic>> getCashflowForecast() async {
    final cacheKey = 'cashflow_forecast';
    
    if (_isCacheValid(cacheKey)) {
      return _cachedInsights[cacheKey]['data'];
    }

    try {
      final transactions = await _getTransactions();
      final currentBalance = await SmsService().getCurrentBalance();
      
      if (transactions.isEmpty) {
        return {'forecast': [], 'trend': 'stable'};
      }

      // Calculate daily average spending and income
      final recentTransactions = _getRecentTransactions(transactions, 30);
      final totalDays = 30; // Days to analyze
      
      // Group transactions by day
      final Map<String, List<Transaction>> dailyTransactions = {};
      
      for (var transaction in recentTransactions) {
        final day = DateFormat('yyyy-MM-dd').format(transaction.date);
        if (!dailyTransactions.containsKey(day)) {
          dailyTransactions[day] = [];
        }
        dailyTransactions[day]?.add(transaction);
      }
      
      // Calculate daily spending and income
      final List<Map<String, dynamic>> dailyData = [];
      
      dailyTransactions.forEach((day, txns) {
        final expenses = txns.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
        final income = txns.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
        
        dailyData.add({
          'date': day,
          'expenses': expenses,
          'income': income,
          'net': income - expenses,
        });
      });
      
      // Sort by date
      dailyData.sort((a, b) => a['date'].compareTo(b['date']));
      
      // Calculate averages
      final totalExpenses = dailyData.fold(0.0, (sum, day) => sum + (day['expenses'] ?? 0.0));
      final totalIncome = dailyData.fold(0.0, (sum, day) => sum + (day['income'] ?? 0.0));
      
      final dailyExpenseAvg = totalExpenses / totalDays;
      final dailyIncomeAvg = totalIncome / totalDays;
      
      // Detect recurring expenses and income
      final recurringTransactions = _detectRecurringTransactions(transactions);
      
      // Forecast next 30 days
      final List<Map<String, dynamic>> forecast = [];
      double projectedBalance = currentBalance;
      DateTime now = DateTime.now();
      
      for (int i = 1; i <= 30; i++) {
        final forecastDate = now.add(Duration(days: i));
        final forecastDay = DateFormat('yyyy-MM-dd').format(forecastDate);
        
        // Add daily average
        double dailyExpense = dailyExpenseAvg;
        double dailyIncome = dailyIncomeAvg;
        
        // Add recurring transactions for this day
        for (var recurring in recurringTransactions) {
          final nextOccurrence = _calculateNextOccurrence(
            recurring['lastDate'],
            recurring['frequency'],
            forecastDate,
          );
          
          if (nextOccurrence != null && 
              DateFormat('yyyy-MM-dd').format(nextOccurrence) == forecastDay) {
            if (recurring['isExpense']) {
              dailyExpense += recurring['amount'];
            } else {
              dailyIncome += recurring['amount'];
            }
          }
        }
        
        // Daily net flow
        final netFlow = dailyIncome - dailyExpense;
        projectedBalance += netFlow;
        
        forecast.add({
          'day': i,
          'date': forecastDate,
          'expenses': dailyExpense,
          'income': dailyIncome,
          'netFlow': netFlow,
          'balance': projectedBalance,
        });
      }
      
      // Determine trend
      String trend = 'stable';
      if (dailyExpenseAvg > dailyIncomeAvg) {
        trend = 'declining';
      } else if (dailyIncomeAvg > dailyExpenseAvg * 1.2) {
        trend = 'growing';
      }
      
      // Predict dates when balance might be low
      final lowBalanceDates = forecast.where((day) => day['balance'] < 1000).map((day) => day['date']).toList();
      
      final result = {
        'forecast': forecast,
        'trend': trend,
        'dailyExpenseAvg': dailyExpenseAvg,
        'dailyIncomeAvg': dailyIncomeAvg,
        'projectedBalance30Days': forecast.isNotEmpty ? forecast.last['balance'] : currentBalance,
        'recurringTransactions': recurringTransactions,
        'lowBalanceDates': lowBalanceDates,
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
      final transactions = await _getTransactions();
      final budgets = await _getBudgets();
      final savingsGoals = await _getSavingsGoals();
      final currentBalance = await SmsService().getCurrentBalance();
      
      // Prepare data for Gemini AI
      final recommendationsData = {
        'transactions': _serializeTransactions(transactions),
        'budgets': _serializeBudgets(budgets),
        'savingsGoals': _serializeSavingsGoals(savingsGoals),
        'currentBalance': currentBalance,
        'currency': AppConfig.primaryCurrency,
      };
      
      // Get AI recommendations
      final aiResponse = await _callGeminiAI(
        '''Based on my financial data, provide personalized financial recommendations:
        1. Savings opportunities
        2. Budget adjustments
        3. Spending optimization
        4. Financial goals suggestions
        5. Emergency fund advice
        
        For each recommendation:
        - Clear title
        - Detailed description with amounts
        - Specific actionable advice
        - Priority (high/medium/low)
        - Type (savings/budget/spending/goals/emergency)
        
        Format response as JSON array with objects containing title, description, type, priority, and action.''',
        recommendationsData
      );
      
      List<Map<String, dynamic>> recommendations = [];
      
      try {
        // Try to parse structured JSON from the AI response
        final parsedJson = jsonDecode(aiResponse);
        if (parsedJson is List) {
          recommendations = List<Map<String, dynamic>>.from(parsedJson);
        }
      } catch (e) {
        // Fallback to creating default recommendations
        recommendations = _generateDefaultRecommendations(
          transactions, 
          budgets, 
          savingsGoals, 
          currentBalance
        );
      }
      
      // Enrich recommendations with UI metadata
      final enrichedRecommendations = recommendations.map((rec) {
        IconData icon = Icons.lightbulb_outline;
        
        if (rec['type'] == 'savings') {
          icon = Icons.savings;
        } else if (rec['type'] == 'budget') {
          icon = Icons.account_balance_wallet;
        } else if (rec['type'] == 'spending') {
          icon = Icons.money_off;
        } else if (rec['type'] == 'goals') {
          icon = Icons.flag;
        } else if (rec['type'] == 'emergency') {
          icon = Icons.shield;
        }
        
        return {
          ...rec,
          'icon': icon,
        };
      }).toList();
      
      _cacheInsights(cacheKey, enrichedRecommendations);
      return enrichedRecommendations;
    } catch (e) {
      debugPrint('Error getting smart recommendations: $e');
      return _generateDefaultRecommendations(
        await _getTransactions(), 
        await _getBudgets(), 
        await _getSavingsGoals(), 
        await SmsService().getCurrentBalance()
      );
    }
  }

  Future<List<Map<String, dynamic>>> getChartData() async {
    final cacheKey = 'chart_data';
    
    if (_isCacheValid(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cachedInsights[cacheKey]['data']);
    }

    try {
      final transactions = await _getTransactions();
      final budgets = await _getBudgets();
      final savingsGoals = await _getSavingsGoals();
      
      if (transactions.isEmpty) {
        return _getEmptyChartData();
      }

      final chartData = <Map<String, dynamic>>[];
      
      // 1. Weekly spending trend
      final weeklySpendingData = _getWeeklySpendingTrend(transactions);
      chartData.add({
        'type': 'line',
        'title': 'Weekly Spending Trend',
        'data': weeklySpendingData,
      });
      
      // 2. Category breakdown
      final categoryData = await _getCategoryBreakdown(transactions);
      chartData.add({
        'type': 'pie',
        'title': 'Spending by Category',
        'data': categoryData,
      });
      
      // 3. Income vs Expenses by month
      final monthlyComparisonData = _getMonthlyIncomeVsExpenses(transactions);
      chartData.add({
        'type': 'bar',
        'title': 'Monthly Income vs Expenses',
        'data': monthlyComparisonData,
      });
      
      // 4. Budget progress
      final budgetProgressData = _getBudgetProgress(transactions, budgets);
      chartData.add({
        'type': 'horizontalBar',
        'title': 'Budget Progress',
        'data': budgetProgressData,
      });
      
      // 5. Savings goals progress
      final savingsProgressData = _getSavingsGoalsProgress(savingsGoals);
      chartData.add({
        'type': 'donut',
        'title': 'Savings Goals Progress',
        'data': savingsProgressData,
      });
      
      _cacheInsights(cacheKey, chartData);
      return chartData;
    } catch (e) {
      debugPrint('Error getting chart data: $e');
      return _getEmptyChartData();
    }
  }

  Future<Map<String, dynamic>> getTransactionCategorizationSuggestions(List<Transaction> unassignedTransactions) async {
    try {
      if (unassignedTransactions.isEmpty) {
        return {'suggestions': []};
      }

      // Format unassigned transactions for Gemini
      final transactionsForAI = unassignedTransactions.map((t) => {
        'id': t.id,
        'description': t.description,
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'isExpense': t.isExpense,
      }).toList();

      // Call Gemini AI
      final aiResponse = await _callGeminiAI(
        '''Analyze these transactions and suggest appropriate categories for each one.
        Choose from these categories: Food, Transport, Shopping, Bills, Entertainment, Health, Education, Travel, Housing, Other.
        For each transaction, provide the transaction ID and the suggested category.
        Also add a confidence score between 0.0 and 1.0 for each suggestion.
        Format the response as a JSON array of objects with id, category, and confidence fields.''',
        {'transactions': transactionsForAI}
      );

      List<Map<String, dynamic>> suggestions = [];
      
      try {
        // Try to parse structured JSON from the AI response
        final parsedJson = jsonDecode(aiResponse);
        if (parsedJson is List) {
          suggestions = List<Map<String, dynamic>>.from(parsedJson);
        }
      } catch (e) {
        // Fallback to simple suggestions if parsing fails
        suggestions = unassignedTransactions.map((t) {
          String suggestedCategory = 'Other';
          
          final description = t.description?.toLowerCase() ?? '';
          if (description.contains('food') || description.contains('restaurant') || description.contains('cafe')) {
            suggestedCategory = 'Food';
          } else if (description.contains('transport') || description.contains('taxi') || description.contains('uber')) {
            suggestedCategory = 'Transport';
          } else if (description.contains('shop') || description.contains('store') || description.contains('market')) {
            suggestedCategory = 'Shopping';
          } else if (description.contains('bill') || description.contains('utility') || description.contains('electricity')) {
            suggestedCategory = 'Bills';
          }
          
          return {
            'id': t.id,
            'category': suggestedCategory,
            'confidence': 0.7,
          };
        }).toList();
      }
      
      return {'suggestions': suggestions};
    } catch (e) {
      debugPrint('Error getting categorization suggestions: $e');
      return {'suggestions': []};
    }
  }

  Future<Map<String, dynamic>> getFinancialGoalSuggestions() async {
    try {
      final transactions = await _getTransactions();
      final currentBalance = await SmsService().getCurrentBalance();
      
      // Prepare data
      final savingsData = {
        'transactions': _serializeTransactions(transactions),
        'currentBalance': currentBalance,
        'currency': AppConfig.primaryCurrency,
      };
      
      // Call Gemini AI
      final aiResponse = await _callGeminiAI(
        '''Based on my financial data, suggest realistic savings goals:
        1. Emergency fund goal
        2. Short-term savings goal (1-3 months)
        3. Medium-term savings goal (3-12 months)
        4. Long-term savings goal (1+ years)
        
        For each goal, provide:
        - Goal name
        - Target amount
        - Recommended monthly contribution
        - Timeframe to achieve
        - Priority level
        
        Format as JSON array with objects containing name, amount, monthlyContribution, timeframeMonths, and priority.''',
        savingsData
      );
      
      List<Map<String, dynamic>> goals = [];
      
      try {
        // Parse structured JSON from AI response
        final parsedJson = jsonDecode(aiResponse);
        if (parsedJson is List) {
          goals = List<Map<String, dynamic>>.from(parsedJson);
        }
      } catch (e) {
        // Generate fallback goals if parsing fails
        final monthlyIncome = transactions
            .where((t) => !t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount) / 3; // Rough estimate
        
        goals = [
          {
            'name': 'Emergency Fund',
            'amount': monthlyIncome * 3,
            'monthlyContribution': monthlyIncome * 0.1,
            'timeframeMonths': 6,
            'priority': 'high',
          },
          {
            'name': 'Travel Fund',
            'amount': monthlyIncome * 1.5,
            'monthlyContribution': monthlyIncome * 0.05,
            'timeframeMonths': 12,
            'priority': 'medium',
          },
          {
            'name': 'New Phone',
            'amount': 70000, // KES 700
            'monthlyContribution': 10000, // KES 100
            'timeframeMonths': 7,
            'priority': 'low',
          },
        ];
      }
      
      return {'goals': goals};
    } catch (e) {
      debugPrint('Error getting goal suggestions: $e');
      return {'goals': []};
    }
  }

  Future<void> generateFinancialReport(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _getTransactions();
      final budgets = await _getBudgets();
      final savingsGoals = await _getSavingsGoals();
      
      // Filter transactions by date range
      final filteredTransactions = transactions.where((t) => 
        t.date.isAfter(startDate) && t.date.isBefore(endDate)).toList();
      
      // Prepare data
      final reportData = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'transactions': _serializeTransactions(filteredTransactions),
        'budgets': _serializeBudgets(budgets),
        'savingsGoals': _serializeSavingsGoals(savingsGoals),
        'currency': AppConfig.primaryCurrency,
      };
      
      // Call Gemini AI
      final aiResponse = await _callGeminiAI(
        '''Generate a comprehensive financial report for the period ${DateFormat('MMM d, yyyy').format(startDate)} to ${DateFormat('MMM d, yyyy').format(endDate)}.

        Include these sections:
        1. Executive Summary
        2. Income Analysis
        3. Expense Analysis by Category
        4. Budget Performance
        5. Savings Progress
        6. Recommendations for Next Period

        Make the report data-driven, personalized, and actionable.''',
        reportData
      );
      
      // Here we would typically save the report or make it available to the user
      debugPrint('Financial report generated: ${aiResponse.substring(0, min(100, aiResponse.length))}...');
    } catch (e) {
      debugPrint('Error generating financial report: $e');
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
          'temperature': 0.2, // Lower temperature for more factual responses
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048, // Increased token limit
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

  Future<List<Transaction>> _getTransactions() async {
    try {
      // Try to get from local storage first
      final localTransactions = await StorageService.instance.getTransactions();
      if (localTransactions.isNotEmpty) {
        return localTransactions;
      }
      
      // If local storage is empty, fetch from Appwrite
      final appwriteTransactions = await _appwriteService.getTransactions();
      if (appwriteTransactions.isNotEmpty) {
        // Cache in local storage
        await StorageService.instance.saveTransactions(appwriteTransactions);
        return appwriteTransactions;
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  Future<List<Budget>> _getBudgets() async {
    try {
      // Try from AppWrite
      final budgets = await _appwriteService.getBudgets();
      return budgets;
    } catch (e) {
      debugPrint('Error getting budgets: $e');
      return [];
    }
  }

  Future<List<SavingsGoal>> _getSavingsGoals() async {
    try {
      // Try from AppWrite
      final goals = await _appwriteService.getSavingsGoals();
      return goals;
    } catch (e) {
      debugPrint('Error getting savings goals: $e');
      return [];
    }
  }

  Map<String, dynamic> _prepareFinancialData(
    List<Transaction> transactions,
    List<Budget> budgets,
    List<SavingsGoal> savingsGoals,
    double currentBalance
  ) {
    // Get last 90 days of transactions for better analysis
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    final recentTransactions = transactions.where((t) => t.date.isAfter(cutoffDate)).toList();
    
    return {
      'currentBalance': currentBalance,
      'totalTransactions': transactions.length,
      'recentTransactionsCount': recentTransactions.length,
      'totalExpenses': transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount),
      'totalIncome': transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount),
      'categoryBreakdown': _getCategoryBreakdownMap(recentTransactions),
      'budgets': _serializeBudgets(budgets),
      'savingsGoals': _serializeSavingsGoals(savingsGoals),
      'transactionSamples': _serializeTransactions(recentTransactions.take(20).toList()),
      'timespan': '${transactions.isNotEmpty ? DateFormat('MMM d, yyyy').format(transactions.first.date) : 'N/A'} to ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
      'currency': AppConfig.primaryCurrency,
    };
  }

  Map<String, dynamic> _parseAIResponse(
    String aiResponse, 
    List<Transaction> transactions, 
    List<Budget> budgets,
    List<SavingsGoal> savingsGoals,
    double currentBalance
  ) {
    // Extract key metrics
    final totalExpenses = transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final netFlow = totalIncome - totalExpenses;
    
    // Calculate budget utilization
    final budgetUtilization = budgets.isNotEmpty
        ? _calculateBudgetUtilization(transactions, budgets)
        : 0.0;
    
    // Calculate savings progress
    final savingsProgress = savingsGoals.isNotEmpty
        ? savingsGoals.map((g) => g.currentAmount / g.targetAmount).reduce((a, b) => a + b) / savingsGoals.length
        : 0.0;
    
    return {
      'aiInsight': aiResponse,
      'keyMetrics': {
        'currentBalance': currentBalance,
        'totalExpenses': totalExpenses,
        'totalIncome': totalIncome,
        'netFlow': netFlow,
        'transactionCount': transactions.length,
        'budgetUtilization': budgetUtilization,
        'savingsProgress': savingsProgress,
      },
      'quickStats': {
        'avgDailySpending': _calculateDailyAverageSpending(_getRecentTransactions(transactions, 30)),
        'topCategory': _getTopSpendingCategory(transactions),
        'spendingTrend': netFlow >= 0 ? 'positive' : 'negative',
        'budgetStatus': budgetUtilization <= 1.0 ? 'on_track' : 'over_budget',
      },
      'timestamp': DateTime.now(),
    };
  }

  double _calculateBudgetUtilization(List<Transaction> transactions, List<Budget> budgets) {
    if (budgets.isEmpty) return 0.0;
    
    double totalUtilization = 0.0;
    
    for (var budget in budgets) {
      // Find transactions for this budget's category
      final categoryTransactions = transactions.where((t) => 
        t.isExpense && t.category == budget.category).toList();
      
      // Calculate total spent in this category
      final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      // Calculate utilization (spent / budget)
      final utilization = budget.amount > 0 ? totalSpent / budget.amount : 0.0;
      
      totalUtilization += utilization;
    }
    
    // Return average utilization across all budgets
    return totalUtilization / budgets.length;
  }

  List<Transaction> _getRecentTransactions(List<Transaction> transactions, int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return transactions.where((t) => t.date.isAfter(cutoffDate)).toList();
  }

  double _calculateDailyAverageSpending(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) return 0.0;
    
    final totalSpending = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final days = max(1, (DateTime.now().difference(expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b)).inDays) + 1);
    return totalSpending / days;
  }

  String _getTopSpendingCategory(List<Transaction> transactions) {
    final categorySpending = _getCategoryBreakdownMap(transactions);
    if (categorySpending.isEmpty) return 'None';
    
    return categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, double> _getCategoryBreakdownMap(List<Transaction> transactions) {
    final breakdown = <String, double>{};
    for (var transaction in transactions.where((t) => t.isExpense)) {
      breakdown[transaction.category] = (breakdown[transaction.category] ?? 0) + transaction.amount;
    }
    return breakdown;
  }

  List<Map<String, dynamic>> _getWeeklySpendingTrend(List<Transaction> transactions) {
    // Get last 7 days
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final day = DateFormat('E').format(date); // Mon, Tue, etc.
      
      // Get transactions for this day
      final dayTransactions = transactions.where((t) => 
        t.isExpense && 
        t.date.day == date.day && 
        t.date.month == date.month && 
        t.date.year == date.year
      ).toList();
      
      final totalSpent = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      result.add({
        'x': day,
        'y': totalSpent,
      });
    }
    
    return result;
  }

  Future<List<Map<String, dynamic>>> _getCategoryBreakdown(List<Transaction> transactions) async {
    final categoryData = await SmsService().getExpensesByCategory();
    
    if (categoryData.isEmpty) {
      // Fallback if SMS service fails
      final manualCategoryData = _getCategoryBreakdownMap(transactions);
      
      return manualCategoryData.entries.map((entry) {
        return {
          'label': entry.key,
          'value': entry.value,
        };
      }).toList();
    }
    
    return categoryData.entries.map((entry) {
      return {
        'label': entry.key,
        'value': entry.value,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getMonthlyIncomeVsExpenses(List<Transaction> transactions) {
    // Group by month
    final monthlyData = <String, Map<String, double>>{};
    
    // Get last 6 months
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM').format(date); // Jan, Feb, etc.
      
      monthlyData[monthKey] = {
        'income': 0.0,
        'expenses': 0.0,
      };
    }
    
    // Fill with actual data
    for (var transaction in transactions) {
      final monthKey = DateFormat('MMM').format(transaction.date);
      
      if (monthlyData.containsKey(monthKey)) {
        if (transaction.isExpense) {
          monthlyData[monthKey]!['expenses'] = (monthlyData[monthKey]!['expenses'] ?? 0.0) + transaction.amount;
        } else {
          monthlyData[monthKey]!['income'] = (monthlyData[monthKey]!['income'] ?? 0.0) + transaction.amount;
        }
      }
    }
    
    // Convert to chart format
    final result = <Map<String, dynamic>>[];
    
    monthlyData.forEach((month, data) {
      result.add({
        'month': month,
        'income': data['income'] ?? 0.0,
        'expenses': data['expenses'] ?? 0.0,
      });
    });
    
    return result;
  }

  List<Map<String, dynamic>> _getBudgetProgress(List<Transaction> transactions, List<Budget> budgets) {
    final result = <Map<String, dynamic>>[];
    
    if (budgets.isEmpty) {
      // Sample data if no budgets
      result.addAll([
        {'category': 'Food', 'spent': 0, 'budget': 1000, 'percentage': 0.0},
        {'category': 'Transport', 'spent': 0, 'budget': 500, 'percentage': 0.0},
        {'category': 'Entertainment', 'spent': 0, 'budget': 300, 'percentage': 0.0},
      ]);
      return result;
    }
    
    for (var budget in budgets) {
      // Find transactions for this category
      final categoryTransactions = transactions.where((t) => 
        t.isExpense && t.category == budget.category).toList();
      
      // Calculate total spent
      final spent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      // Calculate percentage
      final percentage = budget.amount > 0 ? (spent / budget.amount) : 0.0;
      
      result.add({
        'category': budget.category,
        'spent': spent,
        'budget': budget.amount,
        'percentage': percentage,
      });
    }
    
    return result;
  }

  List<Map<String, dynamic>> _getSavingsGoalsProgress(List<SavingsGoal> goals) {
    final result = <Map<String, dynamic>>[];
    
    if (goals.isEmpty) {
      // Sample data if no goals
      result.add({
        'name': 'No Savings Goals',
        'current': 0,
        'target': 100,
        'percentage': 0.0,
      });
      return result;
    }
    
    for (var goal in goals) {
      final percentage = goal.targetAmount > 0 
          ? (goal.currentAmount / goal.targetAmount) 
          : 0.0;
      
      result.add({
        'name': goal.title,
        'current': goal.currentAmount,
        'target': goal.targetAmount,
        'percentage': percentage,
      });
    }
    
    return result;
  }

  List<Map<String, dynamic>> _generateDefaultAlerts(
    List<Transaction> transactions, 
    List<Budget> budgets,
    double currentBalance
  ) {
    final alerts = <Map<String, dynamic>>[];
    
    // Budget alert
    if (budgets.isNotEmpty) {
      for (var budget in budgets) {
        final categoryTransactions = transactions.where((t) => 
          t.isExpense && t.category == budget.category).toList();
        
        final spent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
        
        if (spent > budget.amount * 0.9) {
          alerts.add({
            'type': 'budget_warning',
            'title': '${budget.category} Budget Alert',
            'message': 'You\'ve spent ${AppConfig.formatCurrency((spent * 100).toInt() as double)} of your ${AppConfig.formatCurrency((budget.amount * 100).toInt() as double)} budget',
            'severity': spent > budget.amount ? 'high' : 'medium',
            'action': 'Review your spending'
          });
        }
      }
    }
    
    // Low balance warning
    if (currentBalance < 1000) {
      alerts.add({
        'type': 'low_balance',
        'title': 'Low Balance Warning',
        'message': 'Your balance is below ${AppConfig.formatCurrency(100000)} (${AppConfig.formatCurrency((currentBalance * 100).toInt() as double)})',
        'severity': 'high',
        'action': 'Add funds to your account'
      });
    }
    
    // Unusual spending (simplified logic)
    final recentTransactions = _getRecentTransactions(transactions, 7);
    final olderTransactions = _getRecentTransactions(transactions, 30).where(
      (t) => t.date.isBefore(DateTime.now().subtract(const Duration(days: 7)))
    ).toList();
    
    if (recentTransactions.isNotEmpty && olderTransactions.isNotEmpty) {
      final recentDaily = recentTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount) / 7;
      final olderDaily = olderTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount) / 23;
      
      if (recentDaily > olderDaily * 1.5) {
        alerts.add({
          'type': 'unusual_spending',
          'title': 'Unusual Spending',
          'message': 'Your spending has increased by ${((recentDaily / olderDaily - 1) * 100).toInt()}% recently',
          'severity': 'medium',
          'action': 'Check your recent transactions'
        });
      }
    }
    
    return alerts;
  }

  List<Map<String, dynamic>> _generateDefaultRecommendations(
    List<Transaction> transactions,
    List<Budget> budgets,
    List<SavingsGoal> savingsGoals,
    double currentBalance
  ) {
    final recommendations = <Map<String, dynamic>>[];
    
    if (transactions.isEmpty) {
      recommendations.add({
        'title': 'Start Tracking Your Finances',
        'description': 'Begin by tracking your daily expenses and income to get personalized insights.',
        'type': 'setup',
        'priority': 'high',
        'action': 'Add your first transaction'
      });
      return recommendations;
    }
    
    // Calculate key metrics
    final totalExpenses = transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final avgMonthlyIncome = totalIncome / 3; // Rough estimate
    
    // 1. Emergency fund recommendation
    if (savingsGoals.where((g) => g.title.contains('Emergency')).isEmpty) {
      recommendations.add({
        'title': 'Build an Emergency Fund',
        'description': 'Save ${AppConfig.formatCurrency((avgMonthlyIncome * 300).toInt() as double)} (3 months of expenses) for unexpected needs.',
        'type': 'emergency',
        'priority': 'high',
        'action': 'Start an emergency fund'
      });
    }
    
    // 2. Top spending category recommendation
    final categorySpending = _getCategoryBreakdownMap(transactions);
    if (categorySpending.isNotEmpty) {
      final topCategory = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b);
      
      recommendations.add({
        'title': 'Reduce ${topCategory.key} Spending',
        'description': 'This is your highest spending category at ${AppConfig.formatCurrency((topCategory.value * 100).toInt() as double)}. Try to reduce it by 10%.',
        'type': 'spending',
        'priority': 'medium',
        'action': 'Set a budget for ${topCategory.key}'
      });
    }
    
    // 3. Savings recommendation
    if (totalIncome > totalExpenses) {
      final savingsPotential = (totalIncome - totalExpenses) * 0.2;
      recommendations.add({
        'title': 'Increase Your Savings',
        'description': 'You could save an additional ${AppConfig.formatCurrency((savingsPotential * 100).toInt() as double)} per month.',
        'type': 'savings',
        'priority': 'medium',
        'action': 'Set up automatic savings'
      });
    }
    
    // 4. Budget recommendation
    if (budgets.isEmpty) {
      recommendations.add({
        'title': 'Create a Budget Plan',
        'description': 'Setting up budgets for your main spending categories will help you stay on track.',
        'type': 'budget',
        'priority': 'high',
        'action': 'Create your first budget'
      });
    }
    
    return recommendations;
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
        'budgetUtilization': 0.0,
        'savingsProgress': 0.0,
      },
      'quickStats': {
        'avgDailySpending': 0.0,
        'topCategory': 'None',
        'spendingTrend': 'neutral',
        'budgetStatus': 'no_budget',
      },
      'timestamp': DateTime.now(),
    };
  }

  List<Map<String, dynamic>> _getEmptyChartData() {
    return [
      {
        'type': 'line',
        'title': 'Weekly Spending Trend',
        'data': List.generate(7, (index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          return {
            'x': DateFormat('E').format(date),
            'y': 0.0,
          };
        }),
      },
      {
        'type': 'pie',
        'title': 'Spending by Category',
        'data': [
          {'label': 'No Data', 'value': 1.0},
        ],
      },
      {
        'type': 'bar',
        'title': 'Monthly Income vs Expenses',
        'data': List.generate(3, (index) {
          final date = DateTime.now().subtract(Duration(days: 30 * (2 - index)));
          return {
            'month': DateFormat('MMM').format(date),
            'income': 0.0,
            'expenses': 0.0,
          };
        }),
      },
    ];
  }

  List<Map<String, dynamic>> _detectRecurringTransactions(List<Transaction> transactions) {
    final result = <Map<String, dynamic>>[];
    final transactionsByDescription = <String, List<Transaction>>{};
    
    // Group transactions by description
    for (var transaction in transactions) {
      if (!transactionsByDescription.containsKey(transaction.description)) {
        if (transaction.description != null) {
          transactionsByDescription[transaction.description!] = [];
        }
      }
      transactionsByDescription[transaction.description]!.add(transaction);
    }
    
    // Find recurring patterns
    transactionsByDescription.forEach((description, txns) {
      if (txns.length >= 2) {
        // Sort by date
        txns.sort((a, b) => a.date.compareTo(b.date));
        
        // Check if amounts are similar
        final amounts = txns.map((t) => t.amount).toList();
        final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
        
        bool amountsSimilar = true;
        for (var amount in amounts) {
          if ((amount - avgAmount).abs() / avgAmount > 0.1) { // 10% variance allowed
            amountsSimilar = false;
            break;
          }
        }
        
        if (amountsSimilar) {
          // Try to detect frequency
          if (txns.length >= 3) {
            final intervals = <int>[];
            for (int i = 1; i < txns.length; i++) {
              intervals.add(txns[i].date.difference(txns[i-1].date).inDays);
            }
            
            final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
            
            // Check if intervals are consistent
            bool intervalsConsistent = true;
            for (var interval in intervals) {
              if ((interval - avgInterval).abs() > 3) { // 3 days variance allowed
                intervalsConsistent = false;
                break;
              }
            }
            
            if (intervalsConsistent) {
              String frequency = 'unknown';
              
              if (avgInterval >= 28 && avgInterval <= 31) {
                frequency = 'monthly';
              } else if (avgInterval >= 13 && avgInterval <= 15) {
                frequency = 'biweekly';
              } else if (avgInterval >= 6 && avgInterval <= 8) {
                frequency = 'weekly';
              } else if (avgInterval >= 85 && avgInterval <= 95) {
                frequency = 'quarterly';
              }
              
              if (frequency != 'unknown') {
                result.add({
                  'description': description,
                  'amount': avgAmount,
                  'frequency': frequency,
                  'lastDate': txns.last.date,
                  'isExpense': txns.last.isExpense,
                });
              }
            }
          }
        }
      }
    });
    
    return result;
  }

  DateTime? _calculateNextOccurrence(DateTime lastDate, String frequency, DateTime targetDate) {
    if (targetDate.isBefore(lastDate)) return null;
    
    int daysToAdd = 0;
    
    switch (frequency) {
      case 'monthly':
        daysToAdd = 30;
        break;
      case 'biweekly':
        daysToAdd = 14;
        break;
      case 'weekly':
        daysToAdd = 7;
        break;
      case 'quarterly':
        daysToAdd = 90;
        break;
      default:
        return null;
    }
    
    DateTime nextDate = lastDate;
    while (nextDate.isBefore(targetDate)) {
      nextDate = nextDate.add(Duration(days: daysToAdd));
    }
    
    // If we've gone too far, go back one period
    if (nextDate.isAfter(targetDate)) {
      final difference = nextDate.difference(targetDate).inDays;
      if (difference > daysToAdd / 2) {
        nextDate = nextDate.subtract(Duration(days: daysToAdd));
      }
    }
    
    // Check if the date matches closely enough
    if (nextDate.difference(targetDate).inDays.abs() <= 1) {
      return nextDate;
    }
    
    return null;
  }

  // Helper methods for serializing data for AI
  List<Map<String, dynamic>> _serializeTransactions(List<Transaction> transactions) {
    return transactions.map((t) => {
      'id': t.id,
      'description': t.description,
      'amount': t.amount,
      'date': t.date.toIso8601String(),
      'category': t.category,
      'isExpense': t.isExpense,
    }).toList();
  }

  List<Map<String, dynamic>> _serializeBudgets(List<Budget> budgets) {
    return budgets.map((b) => {
      'id': b.id,
      'category': b.category,
      'amount': b.amount,
      'period': b.period,
    }).toList();
  }

  List<Map<String, dynamic>> _serializeSavingsGoals(List<SavingsGoal> goals) {
    return goals.map((g) => {
      'id': g.id,
      'name': g.title,
      'targetAmount': g.targetAmount,
      'currentAmount': g.currentAmount,
      'targetDate': g.targetDate?.toIso8601String(),
    }).toList();
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
      getChartData(),
    ]);
  }
}