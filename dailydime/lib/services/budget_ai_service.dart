// lib/services/budget_ai_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class BudgetAIService {
  final String _apiKey = AppConfig.geminiApiKey;
  final String _model = AppConfig.geminiModel;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final StorageService _storageService = StorageService.instance;

  // Generate budget insights based on spending patterns
  Future<List<String>> generateBudgetInsights(List<Budget> budgets) async {
    if (budgets.isEmpty) {
      return [
        "Create your first budget to get personalized insights.",
        "Track your expenses across different categories to manage your finances better."
      ];
    }

    try {
      // Prepare budget data for AI
      final budgetData = budgets.map((b) => {
        'category': b.category,
        'amount': b.amount,
        'spent': b.spent,
        'percentageUsed': b.percentageUsed,
        'period': b.period.toString().split('.').last,
        'isOverBudget': b.isOverBudget,
      }).toList();

      // Get recent transactions
      final transactions = await _storageService.loadTransactions();
      final recentTransactions = transactions
          .where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .take(15)
          .map((t) => {
            'category': t.category,
            'amount': t.amount,
            'date': t.date.toIso8601String(),
            'isExpense': t.isExpense,
            'title': t.title,
          })
          .toList();

      // Calculate category spending
      final categorySpending = <String, double>{};
      for (var transaction in transactions) {
        if (transaction.isExpense) {
          categorySpending[transaction.category] = 
              (categorySpending[transaction.category] ?? 0) + transaction.amount;
        }
      }

      // Prepare prompt for Gemini
      final prompt = '''
You are a financial advisor AI providing budget insights. Analyze this data:

Budget Information:
${jsonEncode(budgetData)}

Recent Transactions:
${jsonEncode(recentTransactions)}

Category Spending:
${jsonEncode(categorySpending)}

Generate 3-5 specific, actionable budget insights based on the data. Focus on:
1. Overspending categories
2. Savings opportunities
3. Unusual spending patterns
4. Specific recommendations with numbers
5. Recent transaction patterns

Format each insight as a separate string in a JSON array. Make insights specific, realistic, and personalized.
      ''';

      // Make API request to Gemini
      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final generatedText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract JSON array from response
        final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
        final match = jsonRegex.firstMatch(generatedText);
        
        if (match != null) {
          final jsonArray = jsonDecode(match.group(0)!);
          return List<String>.from(jsonArray);
        } else {
          // Fallback if JSON parsing fails
          final insights = generatedText
              .split('\n')
              .where((line) => line.trim().isNotEmpty && line.contains('.'))
              .take(5)
              .toList();
          
          return insights.isNotEmpty ? insights : _getDefaultInsights(budgets);
        }
      } else {
        return _getDefaultInsights(budgets);
      }
    } catch (e) {
      debugPrint('Error generating budget insights: $e');
      return _getDefaultInsights(budgets);
    }
  }

  // Get default insights as fallback
  List<String> _getDefaultInsights(List<Budget> budgets) {
    final insights = <String>[];
    
    // Check for overspending
    final overBudgets = budgets.where((b) => b.isOverBudget).toList();
    if (overBudgets.isNotEmpty) {
      final worst = overBudgets.reduce((a, b) => 
          (a.spent - a.amount) > (b.spent - b.amount) ? a : b);
      insights.add('You\'ve exceeded your ${worst.category} budget by KES ${(worst.spent - worst.amount).toInt()}. Consider adjusting this budget or reducing spending.');
    }
    
    // Check for near limits
    final nearLimitBudgets = budgets.where((b) => 
        b.percentageUsed >= 0.8 && b.percentageUsed < 1.0).toList();
    if (nearLimitBudgets.isNotEmpty) {
      final nearest = nearLimitBudgets.reduce((a, b) => 
          a.percentageUsed > b.percentageUsed ? a : b);
      insights.add('Your ${nearest.category} budget is at ${(nearest.percentageUsed * 100).toInt()}%. You have KES ${nearest.remaining.toInt()} left to spend.');
    }
    
    // General advice
    insights.add('Try setting up automatic savings transfers to meet your financial goals faster.');
    
    if (insights.length < 3) {
      insights.add('Creating smaller, more specific budget categories can help you track your spending more accurately.');
    }
    
    return insights;
  }

  // Suggest budget category for a transaction
  Future<String?> suggestCategoryForTransaction(Transaction transaction) async {
    try {
      final prompt = '''
Analyze this M-Pesa transaction and determine the most appropriate budget category.

Transaction details:
Title: ${transaction.title}
Amount: KES ${transaction.amount}
Date: ${transaction.date.toIso8601String()}
SMS content: ${transaction.rawSms ?? 'Not available'}
Business: ${transaction.business ?? 'Not available'}
Recipient: ${transaction.recipient ?? 'Not available'}

Possible categories: Food, Transport, Shopping, Entertainment, Utilities, Rent, Health, Education, Personal Care, Subscriptions, Travel, Gifts

Return only the single most appropriate category name, without explanation or additional text.
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 32,
            'topP': 0.95,
            'maxOutputTokens': 256,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final category = jsonResponse['candidates'][0]['content']['parts'][0]['text'].trim();
        return category;
      }
    } catch (e) {
      debugPrint('Error suggesting category: $e');
    }
    return null;
  }

  // Generate daily summary for the user
  Future<String> generateDailySummary(List<Budget> budgets) async {
    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Get yesterday's transactions
      final transactions = await _storageService.loadTransactions();
      final yesterdayTransactions = transactions
          .where((t) => 
              t.date.day == yesterday.day && 
              t.date.month == yesterday.month && 
              t.date.year == yesterday.year &&
              t.isExpense)
          .toList();
      
      final totalSpent = yesterdayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      // Calculate budget status
      final budgetStatus = <String, Map<String, dynamic>>{};
      for (var budget in budgets.where((b) => b.isActive)) {
        final yesterdaySpent = yesterdayTransactions
            .where((t) => t.category.toLowerCase() == budget.category.toLowerCase())
            .fold(0.0, (sum, t) => sum + t.amount);
        
        budgetStatus[budget.category] = {
          'spent': yesterdaySpent,
          'remaining': budget.remaining,
          'dailyAllowance': budget.dailyAllowance,
          'isOverBudget': budget.isOverBudget,
        };
      }

      final prompt = '''
Create a brief, helpful daily budget summary for a user based on this data:

Yesterday's spending: KES ${totalSpent.toInt()}
Number of transactions: ${yesterdayTransactions.length}
Date: ${yesterday.day}/${yesterday.month}/${yesterday.year}

Budget status by category:
${jsonEncode(budgetStatus)}

Create a concise, friendly daily summary (max 2-3 sentences) that:
1. Mentions if they stayed within budget yesterday
2. Highlights one key insight or recommendation
3. Is encouraging and actionable
4. Includes specific numbers

Return only the summary text, no additional explanations.
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 256,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final summary = jsonResponse['candidates'][0]['content']['parts'][0]['text'].trim();
        return summary;
      } else {
        return _getDefaultDailySummary(totalSpent, budgets);
      }
    } catch (e) {
      debugPrint('Error generating daily summary: $e');
      return 'Yesterday you spent KES ${budgets.fold(0.0, (sum, b) => sum + b.spent).toInt()}. Check your budgets to stay on track!';
    }
  }

  // Default daily summary
  String _getDefaultDailySummary(double totalSpent, List<Budget> budgets) {
    final overBudgetCategories = budgets.where((b) => b.isOverBudget).map((b) => b.category).toList();
    
    if (overBudgetCategories.isNotEmpty) {
      return 'Yesterday you spent KES ${totalSpent.toInt()}. Watch out for your ${overBudgetCategories.first} budget which is over limit.';
    } else {
      return 'Yesterday you spent KES ${totalSpent.toInt()}. You\'re staying within budget - great job!';
    }
  }

  // Recommend budgets based on spending history
  Future<List<Budget>> recommendBudgets() async {
    try {
      final transactions = await _storageService.loadTransactions();
      if (transactions.isEmpty) return [];
      
      // Calculate spending by category
      final categorySpending = <String, double>{};
      final categoryCount = <String, int>{};
      
      for (var transaction in transactions.where((t) => t.isExpense)) {
        if (transaction.category.isNotEmpty) {
          categorySpending[transaction.category] = (categorySpending[transaction.category] ?? 0) + transaction.amount;
          categoryCount[transaction.category] = (categoryCount[transaction.category] ?? 0) + 1;
        }
      }
      
      // For categories with more than one transaction, create recommended budgets
      final recommendations = <Budget>[];
      
      categorySpending.forEach((category, amount) {
        if ((categoryCount[category] ?? 0) > 1) {
          // Calculate monthly amount (add 10% buffer)
          final monthlyAmount = amount * 1.1;
          
          // Determine color and icon
          final color = _getCategoryColor(category);
          final icon = _getCategoryIcon(category);
          
          final now = DateTime.now();
          final firstDayOfMonth = DateTime(now.year, now.month, 1);
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
          
          recommendations.add(Budget(
            title: category,
            category: category,
            amount: monthlyAmount,
            period: BudgetPeriod.monthly,
            startDate: firstDayOfMonth,
            endDate: lastDayOfMonth,
            color: color,
            icon: icon,
            tags: [category.toLowerCase()], name: null,
          ));
        }
      });
      
      return recommendations;
    } catch (e) {
      debugPrint('Error recommending budgets: $e');
      return [];
    }
  }

  // Helper to get category color
  Color _getCategoryColor(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('food') || categoryLower.contains('grocery')) {
      return Colors.green;
    } else if (categoryLower.contains('transport') || categoryLower.contains('travel')) {
      return Colors.blue;
    } else if (categoryLower.contains('shopping')) {
      return Colors.purple;
    } else if (categoryLower.contains('entertainment')) {
      return Colors.orange;
    } else if (categoryLower.contains('utilities') || categoryLower.contains('bill')) {
      return Colors.teal;
    } else if (categoryLower.contains('rent') || categoryLower.contains('housing')) {
      return Colors.brown;
    } else if (categoryLower.contains('health') || categoryLower.contains('medical')) {
      return Colors.red;
    } else if (categoryLower.contains('education')) {
      return Colors.indigo;
    } else {
      return Colors.blueGrey;
    }
  }

  // Helper to get category icon
  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('food') || categoryLower.contains('grocery')) {
      return Icons.restaurant;
    } else if (categoryLower.contains('transport') || categoryLower.contains('travel')) {
      return Icons.directions_bus;
    } else if (categoryLower.contains('shopping')) {
      return Icons.shopping_bag;
    } else if (categoryLower.contains('entertainment')) {
      return Icons.movie;
    } else if (categoryLower.contains('utilities') || categoryLower.contains('bill')) {
      return Icons.power;
    } else if (categoryLower.contains('rent') || categoryLower.contains('housing')) {
      return Icons.home;
    } else if (categoryLower.contains('health') || categoryLower.contains('medical')) {
      return Icons.medical_services;
    } else if (categoryLower.contains('education')) {
      return Icons.school;
    } else {
      return Icons.category;
    }
  }
}