// lib/services/ai_insight_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/services/balance_service.dart';

class AIInsightService {
  static final AIInsightService _instance = AIInsightService._internal();
  factory AIInsightService() => _instance;
  AIInsightService._internal();

  final String _apiKey = AppConfig.geminiApiKey;
  final String _model = AppConfig.geminiModel;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // Cache insights to reduce API calls
  Map<String, dynamic> _cachedInsights = {};
  DateTime? _lastInsightUpdate;

  // Generate financial insights based on transaction data
  Future<List<Map<String, dynamic>>> generateInsights({
    required List<Transaction> transactions,
    List<Budget>? budgets,
    List<SavingsGoal>? savingsGoals,
    double? currentBalance,
  }) async {
    // Check if cache is valid (less than 6 hours old)
    final now = DateTime.now();
    if (_lastInsightUpdate != null && 
        now.difference(_lastInsightUpdate!).inHours < 6 &&
        _cachedInsights.isNotEmpty) {
      return _cachedInsights['insights'] ?? [];
    }

    try {
      // Prepare transaction data for AI analysis
      final transactionData = _prepareTransactionData(transactions);
      final budgetData = _prepareBudgetData(budgets);
      final savingsData = _prepareSavingsData(savingsGoals);
      final balanceData = await _prepareBalanceData(currentBalance);

      // Construct prompt for Gemini
      final prompt = _constructFinancialAnalysisPrompt(
        transactionData: transactionData,
        budgetData: budgetData,
        savingsData: savingsData,
        balanceData: balanceData,
      );

      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      // Parse insights from response
      final insights = _parseInsightsFromResponse(response);
      
      // Update cache
      _cachedInsights = {'insights': insights};
      _lastInsightUpdate = now;
      
      return insights;
    } catch (e) {
      debugPrint('Error generating insights: $e');
      // Return fallback insights if API call fails
      return _generateFallbackInsights(transactions, budgets);
    }
  }

  // Generate a spending forecast based on historical data
  Future<Map<String, dynamic>> generateSpendingForecast(List<Transaction> transactions) async {
    try {
      // Extract and prepare transaction data by date
      final transactionsByDate = _groupTransactionsByDate(transactions);
      
      // Construct prompt for Gemini
      final prompt = _constructForecastPrompt(transactionsByDate);
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      // Parse forecast data
      return _parseForecastFromResponse(response);
    } catch (e) {
      debugPrint('Error generating forecast: $e');
      return _generateFallbackForecast(transactions);
    }
  }

  // Generate budget recommendations based on spending patterns
  Future<List<Map<String, dynamic>>> generateBudgetRecommendations(
    List<Transaction> transactions, 
    double monthlyIncome
  ) async {
    try {
      // Categorize and sum transactions
      final categorizedSpending = _categorizeTotalSpending(transactions);
      
      // Construct prompt for Gemini
      final prompt = _constructBudgetRecommendationPrompt(
        categorizedSpending: categorizedSpending,
        monthlyIncome: monthlyIncome,
      );
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      // Parse budget recommendations
      return _parseBudgetRecommendationsFromResponse(response);
    } catch (e) {
      debugPrint('Error generating budget recommendations: $e');
      return _generateFallbackBudgetRecommendations(transactions, monthlyIncome);
    }
  }

  // Analyze specific spending category in depth
  Future<Map<String, dynamic>> analyzeCategorySpending(
    List<Transaction> transactions,
    String category
  ) async {
    try {
      // Filter transactions by category
      final categoryTransactions = transactions
          .where((t) => t.category.toLowerCase() == category.toLowerCase())
          .toList();
      
      // Prepare detailed category data
      final categoryData = _prepareCategoryData(categoryTransactions, category);
      
      // Construct prompt for Gemini
      final prompt = _constructCategoryAnalysisPrompt(categoryData);
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      // Parse category analysis
      return _parseCategoryAnalysisFromResponse(response, category);
    } catch (e) {
      debugPrint('Error analyzing category spending: $e');
      return _generateFallbackCategoryAnalysis(transactions, category);
    }
  }

  // Detect spending anomalies in transaction history
  Future<List<Map<String, dynamic>>> detectSpendingAnomalies(List<Transaction> transactions) async {
    try {
      // Prepare transaction data for anomaly detection
      final transactionData = _prepareTransactionData(transactions);
      
      // Construct prompt for Gemini
      final prompt = _constructAnomalyDetectionPrompt(transactionData);
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      // Parse anomalies
      return _parseAnomaliesFromResponse(response);
    } catch (e) {
      debugPrint('Error detecting anomalies: $e');
      return _generateFallbackAnomalies(transactions);
    }
  }

  // Generate savings recommendations
  Future<Map<String, dynamic>> generateSavingsRecommendations(
    List<Transaction> transactions,
    double monthlyIncome,
    List<SavingsGoal>? savingsGoals
  ) async {
    try {
      // Analyze income vs expenses
      final incomeVsExpenses = _analyzeIncomeVsExpenses(transactions, monthlyIncome);
      
      // Prepare savings goals data
      final savingsData = _prepareSavingsData(savingsGoals);
      
      // Construct prompt for Gemini
      final prompt = _constructSavingsRecommendationPrompt(
        incomeVsExpenses: incomeVsExpenses,
        savingsData: savingsData,
      );
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      // Parse savings recommendations
      return _parseSavingsRecommendationsFromResponse(response);
    } catch (e) {
      debugPrint('Error generating savings recommendations: $e');
      return _generateFallbackSavingsRecommendations(transactions, monthlyIncome);
    }
  }

  // Generate AI response to user question about finances
  Future<String> answerFinancialQuestion(
    String question,
    List<Transaction> recentTransactions
  ) async {
    try {
      // Prepare transaction context
      final transactionContext = _prepareTransactionContextForQuestion(recentTransactions);
      
      // Construct prompt for Gemini
      final prompt = _constructQuestionAnswerPrompt(
        question: question,
        transactionContext: transactionContext,
      );
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      // Extract answer
      return _extractAnswerFromResponse(response);
    } catch (e) {
      debugPrint('Error answering financial question: $e');
      return "I'm sorry, I couldn't process your question at the moment. Please try again later.";
    }
  }

  // Helper methods for data preparation
  Map<String, dynamic> _prepareTransactionData(List<Transaction> transactions) {
    // Group transactions by categories
    final categoriesMap = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final category = transaction.category;
      if (!categoriesMap.containsKey(category)) {
        categoriesMap[category] = [];
      }
      categoriesMap[category]!.add(transaction);
    }

    // Calculate metrics
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    final thisMonthTransactions = transactions
        .where((t) => t.date.isAfter(oneMonthAgo))
        .toList();
    
    final lastThreeMonthsTransactions = transactions
        .where((t) => t.date.isAfter(threeMonthsAgo))
        .toList();

    // Total income and expenses
    final thisMonthIncome = thisMonthTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final thisMonthExpenses = thisMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Categorized spending
    final categorizedSpending = <String, double>{};
    for (final category in categoriesMap.keys) {
      final categoryTransactions = categoriesMap[category]!
          .where((t) => t.isExpense && t.date.isAfter(oneMonthAgo))
          .toList();
      
      final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      if (totalSpent > 0) {
        categorizedSpending[category] = totalSpent;
      }
    }

    // Weekly spending pattern
    final weeklySpendings = <String, double>{};
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    for (final day in daysOfWeek) {
      final dayTransactions = thisMonthTransactions
          .where((t) => t.isExpense && _getDayOfWeek(t.date) == day)
          .toList();
      
      weeklySpendings[day] = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
    }

    // Monthly trend
    final monthlyTrend = <String, Map<String, double>>{};
    for (var i = 2; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(month);
      
      final monthTransactions = transactions
          .where((t) => 
              t.date.year == month.year && 
              t.date.month == month.month)
          .toList();
      
      final income = monthTransactions
          .where((t) => !t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final expenses = monthTransactions
          .where((t) => t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      monthlyTrend[monthName] = {
        'income': income,
        'expenses': expenses,
        'savings': income - expenses
      };
    }

    return {
      'total_transactions': transactions.length,
      'recent_transactions': thisMonthTransactions.length,
      'this_month_income': thisMonthIncome,
      'this_month_expenses': thisMonthExpenses,
      'categorized_spending': categorizedSpending,
      'weekly_pattern': weeklySpendings,
      'monthly_trend': monthlyTrend,
    };
  }

  Map<String, dynamic> _prepareBudgetData(List<Budget>? budgets) {
    if (budgets == null || budgets.isEmpty) {
      return {'has_budgets': false};
    }

    final budgetData = <String, dynamic>{
      'has_budgets': true,
      'budgets': <Map<String, dynamic>>[]
    };

    for (final budget in budgets) {
      budgetData['budgets'].add({
        'category': budget.category,
        'amount': budget.amount,
        'spent': budget.spent,
        'remaining': budget.amount - budget.spent,
        'progress': budget.spent / budget.amount
      });
    }

    return budgetData;
  }

  Map<String, dynamic> _prepareSavingsData(List<SavingsGoal>? savingsGoals) {
    if (savingsGoals == null || savingsGoals.isEmpty) {
      return {'has_savings_goals': false};
    }

    final savingsData = <String, dynamic>{
      'has_savings_goals': true,
      'goals': <Map<String, dynamic>>[]
    };

    for (final goal in savingsGoals) {
      savingsData['goals'].add({
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'deadline': goal.deadline?.toIso8601String(),
        'progress': goal.currentAmount / goal.targetAmount
      });
    }

    return savingsData;
  }

  Future<Map<String, dynamic>> _prepareBalanceData(double? currentBalance) async {
    double balance = currentBalance ?? 0.0;
    
    if (balance == 0) {
      balance = await BalanceService.instance.getCurrentBalance();
    }
    
    return {
      'current_balance': balance,
      'has_balance': balance > 0,
    };
  }

  // Helper methods for prompt construction
  String _constructFinancialAnalysisPrompt({
    required Map<String, dynamic> transactionData,
    required Map<String, dynamic> budgetData,
    required Map<String, dynamic> savingsData,
    required Map<String, dynamic> balanceData,
  }) {
    return '''
You are a financial analyst and advisor. Analyze the following financial data and provide clear, actionable insights and recommendations for the user.

TRANSACTION DATA:
${jsonEncode(transactionData)}

BUDGET DATA:
${jsonEncode(budgetData)}

SAVINGS GOALS DATA:
${jsonEncode(savingsData)}

BALANCE DATA:
${jsonEncode(balanceData)}

Based on this data, provide 3-5 key insights and recommendations. Each insight should have:
1. A short, clear title
2. A brief explanation of the insight
3. A specific, actionable recommendation
4. A relevant icon name (material icon)
5. A priority level (high, medium, low)

Format your response as a JSON array of objects with the following structure:
[
  {
    "title": "Insight title",
    "description": "Brief explanation",
    "recommendation": "Actionable advice",
    "icon": "material_icon_name",
    "priority": "priority_level",
    "type": "insight_type" (spending, saving, budget, income, or balance)
  }
]

Only include the JSON in your response, with no additional text.
''';
  }

  String _constructForecastPrompt(Map<DateTime, List<Transaction>> transactionsByDate) {
    return '''
You are a financial forecasting AI. Based on the following transaction history, predict spending patterns for the next 30 days.

TRANSACTION HISTORY:
${jsonEncode(transactionsByDate.map((k, v) => MapEntry(k.toIso8601String(), v.map((t) => {
      'amount': t.amount,
      'category': t.category,
      'isExpense': t.isExpense,
      'date': t.date.toIso8601String()
    }).toList())))}

Generate a 30-day spending forecast with the following:
1. Daily spending predictions
2. Expected major expenses
3. Category breakdown of predicted spending
4. Total month forecast amount
5. Comparison to previous month

Format your response as a JSON object with the following structure:
{
  "daily_forecast": [{"date": "YYYY-MM-DD", "amount": 000.00}],
  "major_expenses": [{"category": "Category", "amount": 000.00, "likelihood": 0.X}],
  "category_forecast": [{"category": "Category", "amount": 000.00, "percent": XX}],
  "total_forecast": 000.00,
  "previous_month_comparison": {"amount": 000.00, "percent_change": XX.X}
}

Only include the JSON in your response, with no additional text.
''';
  }

  String _constructBudgetRecommendationPrompt({
    required Map<String, double> categorizedSpending,
    required double monthlyIncome,
  }) {
    return '''
You are a budget planning AI. Based on the following spending patterns and income, recommend optimal budget allocations.

SPENDING BY CATEGORY:
${jsonEncode(categorizedSpending)}

MONTHLY INCOME: $monthlyIncome

Provide budget recommendations following the 50/30/20 rule or other appropriate methods. Create budget categories that make sense for the user's spending patterns.

Format your response as a JSON array of objects with the following structure:
[
  {
    "category": "Category name",
    "recommended_amount": 000.00,
    "percent_of_income": XX.X,
    "current_spending": 000.00,
    "adjustment_needed": 000.00,
    "icon": "material_icon_name",
    "priority": "essential/wants/savings"
  }
]

Only include the JSON in your response, with no additional text.
''';
  }

  String _constructCategoryAnalysisPrompt(Map<String, dynamic> categoryData) {
    return '''
You are a financial category analysis AI. Analyze the following spending in a specific category and provide insights.

CATEGORY DATA:
${jsonEncode(categoryData)}

Provide a detailed analysis including:
1. Spending trend over time
2. Comparison to overall budget
3. Top merchants/recipients in this category
4. Recommendations for optimizing spending
5. Potential savings opportunity

Format your response as a JSON object with the following structure:
{
  "category": "Category name",
  "total_spent": 000.00,
  "average_transaction": 000.00,
  "trend": "increasing/decreasing/stable",
  "percent_change": XX.X,
  "top_merchants": [{"name": "Merchant", "amount": 000.00, "percent": XX.X}],
  "recommendations": ["Recommendation 1", "Recommendation 2"],
  "savings_potential": 000.00,
  "insight": "Brief insight about spending in this category"
}

Only include the JSON in your response, with no additional text.
''';
  }

  String _constructAnomalyDetectionPrompt(Map<String, dynamic> transactionData) {
    return '''
You are a financial anomaly detection AI. Analyze the following transaction data and identify potential anomalies or unusual spending patterns.

TRANSACTION DATA:
${jsonEncode(transactionData)}

Identify 1-3 anomalies that might indicate:
1. Unusually large transactions
2. Unexpected spending patterns
3. Potential duplicate payments
4. Subscriptions or recurring charges that might be forgotten
5. Categories with sudden increases in spending

Format your response as a JSON array of objects with the following structure:
[
  {
    "title": "Anomaly description",
    "category": "Category affected",
    "amount": 000.00,
    "date": "YYYY-MM-DD" (or date range),
    "severity": "high/medium/low",
    "explanation": "Detailed explanation",
    "recommendation": "Suggested action",
    "icon": "material_icon_name"
  }
]

Only include the JSON in your response, with no additional text.
''';
  }

  String _constructSavingsRecommendationPrompt({
    required Map<String, dynamic> incomeVsExpenses,
    required Map<String, dynamic> savingsData,
  }) {
    return '''
You are a savings advisor AI. Based on the following financial data, provide recommendations for increasing savings.

INCOME VS EXPENSES:
${jsonEncode(incomeVsExpenses)}

SAVINGS GOALS:
${jsonEncode(savingsData)}

Provide recommendations for:
1. Optimal monthly savings amount
2. Strategies to increase savings
3. Timeline for meeting existing savings goals
4. Suggestions for new savings goals
5. Emergency fund recommendations

Format your response as a JSON object with the following structure:
{
  "recommended_monthly_saving": 000.00,
  "percent_of_income": XX.X,
  "strategies": ["Strategy 1", "Strategy 2"],
  "goal_timelines": [{"goal": "Goal name", "current_amount": 000.00, "target": 000.00, "estimated_completion": "YYYY-MM"}],
  "suggested_new_goals": [{"name": "Goal name", "target": 000.00, "timeline": "X months", "monthly_contribution": 000.00}],
  "emergency_fund": {"current": 000.00, "target": 000.00, "months_to_complete": X}
}

Only include the JSON in your response, with no additional text.
''';
  }

  String _constructQuestionAnswerPrompt({
    required String question,
    required Map<String, dynamic> transactionContext,
  }) {
    return '''
You are a personal finance assistant. Answer the following question based on the user's financial data.

USER QUESTION:
$question

FINANCIAL CONTEXT:
${jsonEncode(transactionContext)}

Provide a helpful, concise answer that directly addresses the user's question. If the question cannot be answered with the available data, clearly state what information is missing. Focus on providing actionable advice when possible.

Format your response as plain text with no special formatting or JSON.
''';
  }

  // API call function
  Future<String> _callGeminiAPI(String prompt) async {
    final url = '$_baseUrl/$_model:generateContent?key=$_apiKey';
    
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 2048,
        'topP': 0.8,
        'topK': 40
      }
    };
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API call failed with status: ${response.statusCode}');
    }
    
    final jsonResponse = jsonDecode(response.body);
    return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
  }

  // Response parsing functions
  List<Map<String, dynamic>> _parseInsightsFromResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(response);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        final List<dynamic> decoded = jsonDecode(jsonStr!);
        
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      
      // Alternative approach if regex fails
      final decoded = jsonDecode(response);
      if (decoded is List) {
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      
      throw Exception('Failed to parse insights response');
    } catch (e) {
      debugPrint('Error parsing insights: $e');
      debugPrint('Raw response: $response');
      return [];
    }
  }

  Map<String, dynamic> _parseForecastFromResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        return Map<String, dynamic>.from(jsonDecode(jsonStr!));
      }
      
      // Alternative approach if regex fails
      final decoded = jsonDecode(response);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      
      throw Exception('Failed to parse forecast response');
    } catch (e) {
      debugPrint('Error parsing forecast: $e');
      return {};
    }
  }

  List<Map<String, dynamic>> _parseBudgetRecommendationsFromResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(response);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        final List<dynamic> decoded = jsonDecode(jsonStr!);
        
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      
      // Alternative approach if regex fails
      final decoded = jsonDecode(response);
      if (decoded is List) {
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      
      throw Exception('Failed to parse budget recommendations response');
    } catch (e) {
      debugPrint('Error parsing budget recommendations: $e');
      return [];
    }
  }

  Map<String, dynamic> _parseCategoryAnalysisFromResponse(String response, String category) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        return Map<String, dynamic>.from(jsonDecode(jsonStr!));
      }
      
      // Alternative approach if regex fails
      final decoded = jsonDecode(response);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      
      throw Exception('Failed to parse category analysis response');
    } catch (e) {
      debugPrint('Error parsing category analysis: $e');
      return {'category': category, 'error': true};
    }
  }

  List<Map<String, dynamic>> _parseAnomaliesFromResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(response);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        final List<dynamic> decoded = jsonDecode(jsonStr!);
        
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      
      // Alternative approach if regex fails
      final decoded = jsonDecode(response);
      if (decoded is List) {
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      
      throw Exception('Failed to parse anomalies response');
    } catch (e) {
      debugPrint('Error parsing anomalies: $e');
      return [];
    }
  }

  Map<String, dynamic> _parseSavingsRecommendationsFromResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        return Map<String, dynamic>.from(jsonDecode(jsonStr!));
      }
      
      // Alternative approach if regex fails
      final decoded = jsonDecode(response);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      
      throw Exception('Failed to parse savings recommendations response');
    } catch (e) {
      debugPrint('Error parsing savings recommendations: $e');
      return {};
    }
  }

  String _extractAnswerFromResponse(String response) {
    // Clean up the response if needed
    return response.trim();
  }

  // Helper methods for fallback responses
  List<Map<String, dynamic>> _generateFallbackInsights(
    List<Transaction> transactions,
    List<Budget>? budgets
  ) {
    final insights = <Map<String, dynamic>>[];
    
    // Group transactions by date (month)
    final transactionsByMonth = <String, List<Transaction>>{};
    for (final t in transactions) {
      final monthKey = '${t.date.year}-${t.date.month}';
      if (!transactionsByMonth.containsKey(monthKey)) {
        transactionsByMonth[monthKey] = [];
      }
      transactionsByMonth[monthKey]!.add(t);
    }
    
    // Calculate last month's spending
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthKey = '${lastMonth.year}-${lastMonth.month}';
    final lastMonthTransactions = transactionsByMonth[lastMonthKey] ?? [];
    
    final lastMonthExpenses = lastMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Top spending category
    final categorizedSpending = _categorizeTotalSpending(transactions);
    String topCategory = 'Unknown';
    double topAmount = 0;
    
    categorizedSpending.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });
    
    // Add spending insight
    insights.add({
      'title': 'Monthly Spending Overview',
      'description': 'Last month, you spent ${AppConfig.formatCurrency(lastMonthExpenses.toInt() * 100)}.',
      'recommendation': 'Review your expenses to identify savings opportunities.',
      'icon': 'trending_up',
      'priority': 'medium',
      'type': 'spending'
    });
    
    // Add top category insight
    if (topCategory != 'Unknown') {
      insights.add({
        'title': 'Top Spending Category',
        'description': 'Your highest spending is in $topCategory (${AppConfig.formatCurrency(topAmount.toInt() * 100)}).',
        'recommendation': 'Consider setting a budget for this category.',
        'icon': 'category',
        'priority': 'high',
        'type': 'budget'
      });
    }
    
    // Add budget insight if available
    if (budgets != null && budgets.isNotEmpty) {
      final overBudgets = budgets.where((b) => b.spent > b.amount).toList();
      
      if (overBudgets.isNotEmpty) {
        insights.add({
          'title': 'Budget Alert',
          "description": "You've exceeded your budget in ${overBudgets.length} categories.",
          'recommendation': 'Adjust your spending or revise your budget goals.',
          'icon': 'warning',
          'priority': 'high',
          'type': 'budget'
        });
      }
    } else {
      insights.add({
        'title': 'Create Your First Budget',
        'description': 'Setting budgets helps track and control your spending.',
        'recommendation': 'Create a budget for your major spending categories.',
        'icon': 'add_chart',
        'priority': 'medium',
        'type': 'budget'
      });
    }
    
    // Add savings insight
    insights.add({
      'title': 'Start Saving Regularly',
      'description': 'Regular savings build financial security over time.',
      'recommendation': 'Try to save at least 10-20% of your income each month.',
      'icon': 'savings',
      'priority': 'medium',
      'type': 'saving'
    });
    
    return insights;
  }

  Map<String, dynamic> _generateFallbackForecast(List<Transaction> transactions) {
    // Simple forecast based on historical data
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    // Calculate average daily spending
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(DateTime(now.year, now.month - 3)))
        .where((t) => t.isExpense)
        .toList();
    
    final totalSpent = recentTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final daysCount = recentTransactions.isEmpty ? 1 : 90; // 3 months
    final avgDailySpending = totalSpent / daysCount;
    
    // Generate daily forecast
    final daysInMonth = monthEnd.day;
    final dailyForecast = <Map<String, dynamic>>[];
    
    for (var i = 1; i <= daysInMonth; i++) {
      final forecastDate = DateTime(now.year, now.month, i);
      if (forecastDate.isBefore(now)) {
        // Use actual data for past days
        final dayTransactions = transactions
            .where((t) => 
                t.date.year == forecastDate.year && 
                t.date.month == forecastDate.month &&
                t.date.day == forecastDate.day &&
                t.isExpense)
            .toList();
        
        final actualSpent = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
        
        dailyForecast.add({
          'date': forecastDate.toIso8601String().substring(0, 10),
          'amount': actualSpent,
          'actual': true
        });
      } else {
        // Forecast future days
        // Weekends might have higher spending
        double modifier = 1.0;
        if (forecastDate.weekday == DateTime.saturday) {
          modifier = 1.5;
        } else if (forecastDate.weekday == DateTime.sunday) {
          modifier = 1.3;
        }
        
        dailyForecast.add({
          'date': forecastDate.toIso8601String().substring(0, 10),
          'amount': avgDailySpending * modifier,
          'actual': false
        });
      }
    }
    
    // Major expenses (categories with highest spending)
    final categorizedSpending = _categorizeTotalSpending(recentTransactions);
    final majorExpenses = categorizedSpending.entries
        .map((e) => {
          'category': e.key,
          'amount': e.value / 3, // Monthly average
          'likelihood': 0.8
        })
        .toList();
    
    // Sort and limit to top 3
    majorExpenses.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    final top3Expenses = majorExpenses.take(3).toList();
    
    // Calculate total forecast
    final daysLeftInMonth = monthEnd.difference(now).inDays + 1;
    final spentSoFar = transactions
        .where((t) => 
            t.date.year == now.year && 
            t.date.month == now.month &&
            t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final forecastRemaining = avgDailySpending * daysLeftInMonth;
    final totalForecast = spentSoFar + forecastRemaining;
    
    // Previous month comparison
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthTransactions = transactions
        .where((t) => 
            t.date.year == lastMonth.year && 
            t.date.month == lastMonth.month &&
            t.isExpense)
        .toList();
    
    final lastMonthTotal = lastMonthTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final percentChange = lastMonthTotal > 0 
        ? ((totalForecast - lastMonthTotal) / lastMonthTotal) * 100
        : 0.0;
    
    return {
      'daily_forecast': dailyForecast,
      'major_expenses': top3Expenses,
      'category_forecast': categorizedSpending.entries
          .map((e) => {
            'category': e.key,
            'amount': e.value / 3, // Monthly average
            'percent': (e.value / totalSpent) * 100
          })
          .toList(),
      'total_forecast': totalForecast,
      'previous_month_comparison': {
        'amount': lastMonthTotal,
        'percent_change': percentChange
      }
    };
  }

  List<Map<String, dynamic>> _generateFallbackBudgetRecommendations(
    List<Transaction> transactions,
    double monthlyIncome
  ) {
    // Apply 50/30/20 rule
    final essentialsBudget = monthlyIncome * 0.5;
    final wantsBudget = monthlyIncome * 0.3;
    final savingsBudget = monthlyIncome * 0.2;
    
    // Categorize current spending
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final currentMonthTransactions = transactions
        .where((t) => t.date.isAfter(monthStart) && t.isExpense)
        .toList();
    
    final categorizedSpending = <String, double>{};
    for (final t in currentMonthTransactions) {
      if (!categorizedSpending.containsKey(t.category)) {
        categorizedSpending[t.category] = 0;
      }
      categorizedSpending[t.category] = categorizedSpending[t.category]! + t.amount;
    }
    
    // Map categories to priorities
    final essentialCategories = [
      'Housing', 'Rent', 'Mortgage', 'Utilities', 'Groceries', 
      'Health', 'Healthcare', 'Insurance', 'Transport', 'Transportation',
      'Debt', 'Loan'
    ];
    
    final wantsCategories = [
      'Entertainment', 'Dining', 'Shopping', 'Travel', 'Leisure',
      'Subscription', 'Hobbies', 'Clothing', 'Personal'
    ];
    
    final savingsCategories = [
      'Savings', 'Investment', 'Emergency Fund', 'Retirement'
    ];
    
    // Generate recommendations
    final recommendations = <Map<String, dynamic>>[];
    
    // Essential categories
    double totalEssentialsSpending = 0;
    categorizedSpending.forEach((category, amount) {
      if (essentialCategories.any((c) => category.toLowerCase().contains(c.toLowerCase()))) {
        totalEssentialsSpending += amount;
      }
    });
    
    recommendations.add({
      'category': 'Essentials',
      'recommended_amount': essentialsBudget,
      'percent_of_income': 50.0,
      'current_spending': totalEssentialsSpending,
      'adjustment_needed': essentialsBudget - totalEssentialsSpending,
      'icon': 'home',
      'priority': 'essential'
    });
    
    // Wants categories
    double totalWantsSpending = 0;
    categorizedSpending.forEach((category, amount) {
      if (wantsCategories.any((c) => category.toLowerCase().contains(c.toLowerCase()))) {
        totalWantsSpending += amount;
      }
    });
    
    recommendations.add({
      'category': 'Wants',
      'recommended_amount': wantsBudget,
      'percent_of_income': 30.0,
      'current_spending': totalWantsSpending,
      'adjustment_needed': wantsBudget - totalWantsSpending,
      'icon': 'shopping_bag',
      'priority': 'wants'
    });
    
    // Savings categories
    double totalSavingsSpending = 0;
    categorizedSpending.forEach((category, amount) {
      if (savingsCategories.any((c) => category.toLowerCase().contains(c.toLowerCase()))) {
        totalSavingsSpending += amount;
      }
    });
    
    recommendations.add({
      'category': 'Savings',
      'recommended_amount': savingsBudget,
      'percent_of_income': 20.0,
      'current_spending': totalSavingsSpending,
      'adjustment_needed': savingsBudget - totalSavingsSpending,
      'icon': 'savings',
      'priority': 'savings'
    });
    
    // Add specific category recommendations for top spending areas
    final sortedCategories = categorizedSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var i = 0; i < 3 && i < sortedCategories.length; i++) {
      final category = sortedCategories[i].key;
      final amount = sortedCategories[i].value;
      
      String priority = 'wants';
      IconData icon = Icons.category;
      
      if (essentialCategories.any((c) => category.toLowerCase().contains(c.toLowerCase()))) {
        priority = 'essential';
        icon = Icons.home;
      } else if (savingsCategories.any((c) => category.toLowerCase().contains(c.toLowerCase()))) {
        priority = 'savings';
        icon = Icons.savings;
      } else {
        icon = _getCategoryIcon(category);
      }
      
      // Recommend slight reduction for high spending categories
      final recommendedAmount = amount * 0.9;
      
      recommendations.add({
        'category': category,
        'recommended_amount': recommendedAmount,
        'percent_of_income': (recommendedAmount / monthlyIncome) * 100,
        'current_spending': amount,
        'adjustment_needed': recommendedAmount - amount,
        'icon': icon.toString().replaceAll('IconData(', '').replaceAll(')', ''),
        'priority': priority
      });
    }
    
    return recommendations;
  }

  Map<String, dynamic> _generateFallbackCategoryAnalysis(
    List<Transaction> transactions,
    String category
  ) {
    // Filter transactions for the category
    final categoryTransactions = transactions
        .where((t) => t.category.toLowerCase() == category.toLowerCase())
        .toList();
    
    if (categoryTransactions.isEmpty) {
      return {
        'category': category,
        'error': true,
        'message': 'No transactions found for this category'
      };
    }
    
    // Calculate metrics
    final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final avgTransaction = totalSpent / categoryTransactions.length;
    
    // Group by month to determine trend
    final byMonth = <String, double>{};
    for (final t in categoryTransactions) {
      final monthKey = '${t.date.year}-${t.date.month}';
      if (!byMonth.containsKey(monthKey)) {
        byMonth[monthKey] = 0;
      }
      byMonth[monthKey] = byMonth[monthKey]! + t.amount;
    }
    
    // Determine trend (need at least 2 months of data)
    String trend = 'stable';
    double percentChange = 0;
    
    if (byMonth.length >= 2) {
      final monthsSorted = byMonth.keys.toList()..sort();
      final latestMonth = monthsSorted.last;
      final previousMonth = monthsSorted[monthsSorted.length - 2];
      
      final latestAmount = byMonth[latestMonth]!;
      final previousAmount = byMonth[previousMonth]!;
      
      percentChange = previousAmount > 0
          ? ((latestAmount - previousAmount) / previousAmount) * 100
          : 0;
      
      if (percentChange > 10) {
        trend = 'increasing';
      } else if (percentChange < -10) {
        trend = 'decreasing';
      }
    }
    
    // Find top merchants
    final byMerchant = <String, double>{};
    for (final t in categoryTransactions) {
      final merchant = t.business ?? t.recipient ?? t.sender ?? 'Unknown';
      if (!byMerchant.containsKey(merchant)) {
        byMerchant[merchant] = 0;
      }
      byMerchant[merchant] = byMerchant[merchant]! + t.amount;
    }
    
    final topMerchants = byMerchant.entries
        .map((e) => {
          'name': e.key,
          'amount': e.value,
          'percent': (e.value / totalSpent) * 100
        })
        .toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    // Generate recommendations based on trend
    final recommendations = <String>[];
    double savingsPotential = 0;
    
    if (trend == 'increasing') {
      recommendations.add('Your spending in this category is increasing. Consider setting a budget.');
      recommendations.add('Review your recent transactions to identify unnecessary expenses.');
      savingsPotential = totalSpent * 0.15; // Suggest 15% reduction
    } else if (trend == 'stable' && totalSpent > 0) {
      recommendations.add('Your spending is consistent. Consider if you can optimize any recurring expenses.');
      savingsPotential = totalSpent * 0.1; // Suggest 10% reduction
    } else if (trend == 'decreasing') {
      recommendations.add('Great job reducing spending in this category! Keep it up.');
      savingsPotential = totalSpent * 0.05; // Suggest 5% further reduction
    }
    
    // Add category-specific recommendations
    if (category.toLowerCase().contains('subscription') || 
        category.toLowerCase().contains('entertainment')) {
      recommendations.add('Review your subscriptions to identify services you no longer use.');
      savingsPotential += totalSpent * 0.2;
    } else if (category.toLowerCase().contains('dining') || 
               category.toLowerCase().contains('food')) {
      recommendations.add('Consider cooking more meals at home to reduce dining expenses.');
      savingsPotential += totalSpent * 0.3;
    }
    
    return {
      'category': category,
      'total_spent': totalSpent,
      'average_transaction': avgTransaction,
      'trend': trend,
      'percent_change': percentChange,
      'top_merchants': topMerchants.take(3).toList(),
      'recommendations': recommendations,
      'savings_potential': savingsPotential,
      'insight': 'You spend an average of ${AppConfig.formatCurrency(avgTransaction.toInt() * 100)} per transaction in this category.'
    };
  }

  List<Map<String, dynamic>> _generateFallbackAnomalies(List<Transaction> transactions) {
    final anomalies = <Map<String, dynamic>>[];
    
    if (transactions.isEmpty) {
      return anomalies;
    }
    
    // Find unusually large transactions
    final amounts = transactions.map((t) => t.amount).toList();
    amounts.sort();
    
    final medianIndex = amounts.length ~/ 2;
    final medianAmount = amounts.length.isOdd
        ? amounts[medianIndex]
        : (amounts[medianIndex - 1] + amounts[medianIndex]) / 2;
    
    // Consider amounts more than 3x the median as potentially anomalous
    final threshold = medianAmount * 3;
    final largeTransactions = transactions
        .where((t) => t.amount > threshold && t.isExpense)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    
    if (largeTransactions.isNotEmpty) {
      final t = largeTransactions.first;
      anomalies.add({
        'title': 'Unusually Large Transaction',
        'category': t.category,
        'amount': t.amount,
        'date': t.date.toIso8601String().substring(0, 10),
        'severity': 'medium',
        'explanation': 'This transaction is significantly larger than your typical spending in this category.',
        'recommendation': 'Verify this transaction if it doesn\'t look familiar.',
        'icon': 'warning'
      });
    }
    
    // Detect potential duplicate payments
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();
    
    for (var i = 0; i < recentTransactions.length; i++) {
      for (var j = i + 1; j < recentTransactions.length; j++) {
        final t1 = recentTransactions[i];
        final t2 = recentTransactions[j];
        
        // Check if amounts match and they're close in time
        if (t1.amount == t2.amount && 
            t1.isExpense && 
            t2.isExpense &&
            t1.category == t2.category &&
            t1.date.difference(t2.date).inHours.abs() < 48) {
          
          final recipient = t1.business ?? t1.recipient ?? 'same recipient';
          
          anomalies.add({
            'title': 'Potential Duplicate Payment',
            'category': t1.category,
            'amount': t1.amount,
            'date': '${t1.date.toIso8601String().substring(0, 10)} & ${t2.date.toIso8601String().substring(0, 10)}',
            'severity': 'high',
            'explanation': 'You made two identical payments of ${AppConfig.formatCurrency(t1.amount.toInt() * 100)} to $recipient within 48 hours.',
            'recommendation': 'Check if one of these was a duplicate payment.',
            'icon': 'content_copy'
          });
          
          break; // Only report this pair once
        }
      }
    }
    
    // Detect sudden category increases
    final thisMonth = DateTime.now();
    final lastMonth = DateTime(thisMonth.year, thisMonth.month - 1);
    
    final thisMonthTransactions = transactions
        .where((t) => t.date.year == thisMonth.year && t.date.month == thisMonth.month)
        .toList();
    
    final lastMonthTransactions = transactions
        .where((t) => t.date.year == lastMonth.year && t.date.month == lastMonth.month)
        .toList();
    
    final thisMonthByCategory = <String, double>{};
    for (final t in thisMonthTransactions.where((t) => t.isExpense)) {
      if (!thisMonthByCategory.containsKey(t.category)) {
        thisMonthByCategory[t.category] = 0;
      }
      thisMonthByCategory[t.category] = thisMonthByCategory[t.category]! + t.amount;
    }
    
    final lastMonthByCategory = <String, double>{};
    for (final t in lastMonthTransactions.where((t) => t.isExpense)) {
      if (!lastMonthByCategory.containsKey(t.category)) {
        lastMonthByCategory[t.category] = 0;
      }
      lastMonthByCategory[t.category] = lastMonthByCategory[t.category]! + t.amount;
    }
    
    thisMonthByCategory.forEach((category, amount) {
      final lastMonthAmount = lastMonthByCategory[category] ?? 0;
      
      // Detect significant increases (>50%)
      if (lastMonthAmount > 0 && amount > lastMonthAmount * 1.5) {
        final increase = amount - lastMonthAmount;
        final percentIncrease = (increase / lastMonthAmount) * 100;
        
        anomalies.add({
          'title': 'Spending Increase',
          'category': category,
          'amount': increase,
          'date': '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')} to ${thisMonth.year}-${thisMonth.month.toString().padLeft(2, '0')}',
          'severity': percentIncrease > 100 ? 'high' : 'medium',
          'explanation': 'Your spending in $category increased by ${percentIncrease.toStringAsFixed(0)}% compared to last month.',
          'recommendation': 'Review your recent transactions in this category to identify the cause.',
          'icon': 'trending_up'
        });
      }
    });
    
    return anomalies;
  }

  Map<String, dynamic> _generateFallbackSavingsRecommendations(
    List<Transaction> transactions,
    double monthlyIncome
  ) {
    // Calculate average monthly expenses
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(threeMonthsAgo))
        .toList();
    
    final expenses = recentTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final avgMonthlyExpenses = expenses / 3;
    final currentSavingsRate = monthlyIncome > 0 
        ? ((monthlyIncome - avgMonthlyExpenses) / monthlyIncome) * 100
        : 0.0;
    
    // Recommended savings rate (aim for 20%)
    final targetSavingsRate = 20.0;
    final recommendedMonthlySaving = monthlyIncome * (targetSavingsRate / 100);
    
    // Strategies based on current savings rate
    final strategies = <String>[];
    
    if (currentSavingsRate < 10) {
      strategies.add('Reduce discretionary spending on entertainment and dining out');
      strategies.add('Review and cancel unused subscriptions');
      strategies.add('Consider a "no-spend" challenge for non-essential items');
    } else if (currentSavingsRate < 20) {
      strategies.add('Set up automatic transfers to your savings on payday');
      strategies.add('Look for better deals on regular expenses like insurance');
      strategies.add('Consider a side income to boost your savings rate');
    } else {
      strategies.add('Great job! Consider increasing investments for long-term growth');
      strategies.add('Review your tax strategy to maximize returns');
      strategies.add('Consider additional retirement contributions');
    }
    
    // Emergency fund recommendation (3-6 months of expenses)
    final recommendedEmergencyFund = avgMonthlyExpenses * 6;
    
    // Estimate current emergency fund (placeholder)
    final estimatedCurrentEmergencyFund = 0.0; // Would need actual data
    
    final monthsToCompleteEmergencyFund = recommendedEmergencyFund > 0 && recommendedMonthlySaving > 0
        ? (recommendedEmergencyFund - estimatedCurrentEmergencyFund) / recommendedMonthlySaving
        : 0;
    
    // Suggested new goals
    final suggestedNewGoals = <Map<String, dynamic>>[];
    
    if (estimatedCurrentEmergencyFund < recommendedEmergencyFund) {
      suggestedNewGoals.add({
        'name': 'Emergency Fund',
        'target': recommendedEmergencyFund,
        'timeline': '${monthsToCompleteEmergencyFund.ceil()} months',
        'monthly_contribution': recommendedMonthlySaving
      });
    }
    
    suggestedNewGoals.add({
      'name': 'Retirement Fund',
      'target': monthlyIncome * 12 * 10, // 10 years of income as example
      'timeline': '30 years',
      'monthly_contribution': monthlyIncome * 0.15
    });
    
    suggestedNewGoals.add({
      'name': 'Vacation Fund',
      'target': monthlyIncome * 2,
      'timeline': '12 months',
      'monthly_contribution': (monthlyIncome * 2) / 12
    });
    
    return {
      'recommended_monthly_saving': recommendedMonthlySaving,
      'percent_of_income': targetSavingsRate,
      'strategies': strategies,
      'goal_timelines': [],
      'suggested_new_goals': suggestedNewGoals,
      'emergency_fund': {
        'current': estimatedCurrentEmergencyFund,
        'target': recommendedEmergencyFund,
        'months_to_complete': monthsToCompleteEmergencyFund.ceil()
      }
    };
  }

  // Helper methods
  Map<String, double> _categorizeTotalSpending(List<Transaction> transactions) {
    final categorizedSpending = <String, double>{};
    
    for (final t in transactions.where((t) => t.isExpense)) {
      if (!categorizedSpending.containsKey(t.category)) {
        categorizedSpending[t.category] = 0;
      }
      categorizedSpending[t.category] = categorizedSpending[t.category]! + t.amount;
    }
    
    return categorizedSpending;
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final result = <DateTime, List<Transaction>>{};
    
    for (final t in transactions) {
      // Normalize to just the date part
      final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
      
      if (!result.containsKey(dateKey)) {
        result[dateKey] = [];
      }
      
      result[dateKey]!.add(t);
    }
    
    return result;
  }

  Map<String, dynamic> _prepareCategoryData(List<Transaction> transactions, String category) {
    // Group by month
    final byMonth = <String, double>{};
    for (final t in transactions) {
      final monthKey = '${t.date.year}-${t.date.month}';
      if (!byMonth.containsKey(monthKey)) {
        byMonth[monthKey] = 0;
      }
      byMonth[monthKey] = byMonth[monthKey]! + t.amount;
    }
    
    // Group by merchant
    final byMerchant = <String, double>{};
    for (final t in transactions) {
      final merchant = t.business ?? t.recipient ?? t.sender ?? 'Unknown';
      if (!byMerchant.containsKey(merchant)) {
        byMerchant[merchant] = 0;
      }
      byMerchant[merchant] = byMerchant[merchant]! + t.amount;
    }
    
    return {
      'category': category,
      'transaction_count': transactions.length,
      'total_amount': transactions.fold(0.0, (sum, t) => sum + t.amount),
      'by_month': byMonth,
      'by_merchant': byMerchant,
      'transactions': transactions.map((t) => {
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'merchant': t.business ?? t.recipient ?? t.sender ?? 'Unknown'
      }).toList()
    };
  }

  Map<String, dynamic> _analyzeIncomeVsExpenses(
    List<Transaction> transactions,
    double monthlyIncome
  ) {
    // Group by month
    final byMonth = <String, Map<String, double>>{};
    
    for (final t in transactions) {
      final monthKey = '${t.date.year}-${t.date.month}';
      
      if (!byMonth.containsKey(monthKey)) {
        byMonth[monthKey] = {'income': 0, 'expenses': 0};
      }
      
      if (t.isExpense) {
        byMonth[monthKey]!['expenses'] = byMonth[monthKey]!['expenses']! + t.amount;
      } else {
        byMonth[monthKey]!['income'] = byMonth[monthKey]!['income']! + t.amount;
      }
    }
    
    // Calculate savings rate
    final savingsRates = <String, double>{};
    for (final month in byMonth.keys) {
      final income = byMonth[month]!['income']!;
      final expenses = byMonth[month]!['expenses']!;
      
      savingsRates[month] = income > 0 ? ((income - expenses) / income) * 100 : 0;
    }
    
    return {
      'monthly_data': byMonth,
      'savings_rates': savingsRates,
      'reported_monthly_income': monthlyIncome,
      'average_expenses': byMonth.isNotEmpty 
          ? byMonth.values.fold(0.0, (sum, m) => sum + m['expenses']!) / byMonth.length
          : 0.0
    };
  }

  Map<String, dynamic> _prepareTransactionContextForQuestion(List<Transaction> transactions) {
    // Group transactions by date
    final byDate = _groupTransactionsByDate(transactions);
    
    // Calculate current month metrics
    final now = DateTime.now();
    final currentMonthTransactions = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    
    final currentMonthIncome = currentMonthTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final currentMonthExpenses = currentMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Get recent balance
    final balance = BalanceService.instance.getCurrentBalance();
    
    // Get top spending categories
    final categorizedSpending = _categorizeTotalSpending(transactions);
    final topCategories = categorizedSpending.entries
        .map((e) => {'category': e.key, 'amount': e.value})
        .toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    return {
      'transaction_count': transactions.length,
      'current_month': {
        'income': currentMonthIncome,
        'expenses': currentMonthExpenses,
        'balance': currentMonthIncome - currentMonthExpenses
      },
      'current_balance': balance,
      'top_spending_categories': topCategories.take(5).toList(),
      'recent_transactions': transactions
          .take(10)
          .map((t) => {
            'amount': t.amount,
            'category': t.category,
            'date': t.date.toIso8601String(),
            'is_expense': t.isExpense,
            'title': t.title
          })
          .toList()
    };
  }

  // Helper functions
  String _getDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonthName(DateTime date) {
    switch (date.month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('food') || categoryLower.contains('dining') || 
        categoryLower.contains('restaurant')) {
      return Icons.restaurant;
    } else if (categoryLower.contains('transport') || categoryLower.contains('travel') || 
              categoryLower.contains('uber')) {
      return Icons.directions_car;
    } else if (categoryLower.contains('shopping') || categoryLower.contains('clothing')) {
      return Icons.shopping_bag;
    } else if (categoryLower.contains('entertainment') || categoryLower.contains('movie')) {
      return Icons.movie;
    } else if (categoryLower.contains('health') || categoryLower.contains('medical')) {
      return Icons.health_and_safety;
    } else if (categoryLower.contains('education') || categoryLower.contains('school')) {
      return Icons.school;
    } else if (categoryLower.contains('home') || categoryLower.contains('rent') || 
              categoryLower.contains('mortgage')) {
      return Icons.home;
    } else if (categoryLower.contains('utilities') || categoryLower.contains('electric') || 
              categoryLower.contains('water')) {
      return Icons.electrical_services;
    } else if (categoryLower.contains('phone') || categoryLower.contains('mobile')) {
      return Icons.phone_android;
    } else if (categoryLower.contains('savings') || categoryLower.contains('investment')) {
      return Icons.savings;
    } else {
      return Icons.category;
    }
  }
}