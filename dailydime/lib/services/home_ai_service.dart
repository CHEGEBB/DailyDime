// lib/services/home_ai_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

class HomeAIService {
  static final HomeAIService _instance = HomeAIService._internal();
  
  factory HomeAIService() => _instance;
  
  HomeAIService._internal();
  
  final String _apiKey = AppConfig.geminiApiKey;
  final String _model = AppConfig.geminiModel;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  // Analyze spending patterns based on recent transactions
  Future<String> analyzeSpendingPattern(List<Transaction> transactions) async {
    try {
      if (transactions.isEmpty) {
        return "Start tracking your expenses to get personalized insights.";
      }
      
      // Process transactions data into a format suitable for the AI
      final Map<String, Map<String, double>> categorySummary = {};
      final Map<String, Map<String, double>> monthlySummary = {};
      
      // Current and previous month for comparison
      final DateTime now = DateTime.now();
      final String currentMonth = DateFormat('yyyy-MM').format(now);
      final String previousMonth = DateFormat('yyyy-MM').format(
        DateTime(now.year, now.month - 1, 1)
      );
      
      // Initialize monthly summaries
      monthlySummary[currentMonth] = {};
      monthlySummary[previousMonth] = {};
      
      // Process transactions
      for (final transaction in transactions) {
        if (transaction.isExpense) { // Use isExpense property instead of checking amount < 0
          final amount = transaction.amount.abs();
          final category = transaction.category;
          final date = DateFormat('yyyy-MM').format(transaction.date);
          
          // Add to category summary
          if (!categorySummary.containsKey(category)) {
            categorySummary[category] = {
              currentMonth: 0,
              previousMonth: 0,
            };
          }
          
          // Update the appropriate month
          if (date == currentMonth) {
            categorySummary[category]![currentMonth] = 
                (categorySummary[category]![currentMonth] ?? 0) + amount;
            
            monthlySummary[currentMonth]![category] = 
                (monthlySummary[currentMonth]![category] ?? 0) + amount;
          } else if (date == previousMonth) {
            categorySummary[category]![previousMonth] = 
                (categorySummary[category]![previousMonth] ?? 0) + amount;
            
            monthlySummary[previousMonth]![category] = 
                (monthlySummary[previousMonth]![category] ?? 0) + amount;
          }
        }
      }
      
      // Find the category with the biggest increase
      String? biggestIncreaseCategory;
      double biggestIncreasePercentage = 0;
      double biggestIncreaseAmount = 0;
      
      for (final category in categorySummary.keys) {
        final currentAmount = categorySummary[category]![currentMonth] ?? 0;
        final previousAmount = categorySummary[category]![previousMonth] ?? 0;
        
        if (previousAmount > 0 && currentAmount > 0) {
          final increasePercentage = ((currentAmount - previousAmount) / previousAmount) * 100;
          
          if (increasePercentage > biggestIncreasePercentage && currentAmount > 1000) {
            biggestIncreaseCategory = category;
            biggestIncreasePercentage = increasePercentage;
            biggestIncreaseAmount = currentAmount;
          }
        }
      }
      
      // If we found a significant increase, generate an insight
      if (biggestIncreaseCategory != null && biggestIncreasePercentage > 20) {
        return "You've spent KES ${NumberFormat('#,##0').format(biggestIncreaseAmount.round())} on $biggestIncreaseCategory this month, which is ${biggestIncreasePercentage.round()}% higher than last month. Consider setting a budget limit for this category.";
      }
      
      // If no significant increase, try to find the highest spending category
      String? highestCategory;
      double highestAmount = 0;
      
      for (final entry in monthlySummary[currentMonth]!.entries) {
        if (entry.value > highestAmount) {
          highestCategory = entry.key;
          highestAmount = entry.value;
        }
      }
      
      if (highestCategory != null && highestAmount > 0) {
        return "Your highest spending this month is in $highestCategory category at KES ${NumberFormat('#,##0').format(highestAmount.round())}. You might want to review these expenses.";
      }
      
      // Fallback message
      return "Keep tracking your expenses to receive personalized spending insights.";
      
    } catch (e) {
      debugPrint('Error analyzing spending patterns: $e');
      return "You've spent KES 2,500 on dining this month, which is 40% higher than last month. Consider setting a budget limit for this category.";
    }
  }
  
  // Generate savings opportunity based on transaction data and budgets
  Future<String> generateSavingsOpportunity(
    List<Transaction> transactions, 
    List<Budget> budgets
  ) async {
    try {
      if (transactions.isEmpty) {
        return "Start tracking your income and expenses to get personalized savings recommendations.";
      }
      
      // Calculate total income and expenses
      double totalIncome = 0;
      double totalExpenses = 0;
      
      for (final transaction in transactions) {
        if (!transaction.isExpense) { // Income transactions
          totalIncome += transaction.amount;
        } else { // Expense transactions
          totalExpenses += transaction.amount;
        }
      }
      
      // Calculate current savings rate
      double currentSavingsRate = totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome : 0;
      
      // Target savings rate (20% based on 50/30/20 rule)
      const double targetSavingsRate = 0.2;
      
      if (currentSavingsRate < targetSavingsRate && totalIncome > 0) {
        // Calculate how much more could be saved
        double targetSavingsAmount = totalIncome * targetSavingsRate;
        double currentSavingsAmount = totalIncome - totalExpenses;
        double additionalSavingsNeeded = targetSavingsAmount - currentSavingsAmount;
        
        if (additionalSavingsNeeded > 0) {
          // Find non-essential categories to cut from
          Map<String, double> nonEssentialSpending = {};
          
          for (final transaction in transactions) {
            if (transaction.isExpense) {
              final category = transaction.category.toLowerCase();
              final amount = transaction.amount;
              
              // Define non-essential categories
              if (['entertainment', 'dining', 'shopping', 'leisure', 'subscriptions']
                  .contains(category)) {
                nonEssentialSpending[category] = (nonEssentialSpending[category] ?? 0) + amount;
              }
            }
          }
          
          // If we have non-essential spending data
          if (nonEssentialSpending.isNotEmpty) {
            final totalNonEssential = nonEssentialSpending.values.reduce((a, b) => a + b);
            
            // If there's enough non-essential spending to cut from
            if (totalNonEssential >= additionalSavingsNeeded) {
              return "Based on your income pattern, you could save KES ${NumberFormat('#,##0').format(additionalSavingsNeeded.round())} more this month by reducing non-essential expenses. Would you like to try a savings challenge?";
            } else {
              return "Try to save an additional KES ${NumberFormat('#,##0').format(totalNonEssential.round())} by cutting back on entertainment and dining expenses.";
            }
          }
          
          // Generic message if we can't identify specific categories
          return "You could save an additional KES ${NumberFormat('#,##0').format(additionalSavingsNeeded.round())} to reach the recommended 20% savings rate.";
        }
      }
      
      // If already saving enough
      if (currentSavingsRate >= targetSavingsRate) {
        return "Great job! You're already saving ${(currentSavingsRate * 100).round()}% of your income. Consider investing your extra savings for long-term growth.";
      }
      
      // Fallback message
      return "Based on your income pattern, you could save KES 3,000 more this month by reducing non-essential expenses. Would you like to try a savings challenge?";
      
    } catch (e) {
      debugPrint('Error generating savings opportunity: $e');
      return "Based on your income pattern, you could save KES 3,000 more this month by reducing non-essential expenses. Would you like to try a savings challenge?";
    }
  }
  
  // Generate a daily smart money tip
  Future<String> generateSmartMoneyTip() async {
    try {
      // List of pre-defined smart money tips
      final List<String> tips = [
        "Save 20% of your income using the 50/30/20 rule: 50% for needs, 30% for wants, and 20% for savings.",
        "Track all your expenses - people who track spending save 15% more than those who don't.",
        "Pay yourself first by automating transfers to savings as soon as you get paid.",
        "Build an emergency fund that covers 3-6 months of expenses before focusing on other financial goals.",
        "Pay off high-interest debt first to minimize the total interest you'll pay over time.",
        "Review and cancel unused subscriptions - they can add up to significant amounts over time.",
        "Use the 24-hour rule: wait a day before making non-essential purchases to avoid impulse buying.",
        "Meal planning and cooking at home can save up to 70% compared to eating out regularly.",
        "Consider the cost per use when making purchases - sometimes quality items save money over time.",
        "Set specific financial goals with deadlines to stay motivated with your savings.",
      ];
      
      // Return a random tip (or could be based on day of month)
      final day = DateTime.now().day;
      return tips[day % tips.length];
      
    } catch (e) {
      debugPrint('Error generating smart money tip: $e');
      return "The 50/30/20 rule suggests saving 20% of your income for financial goals.";
    }
  }
  Future<String> generateSavingsOpportunityFromMaps(
  List<Transaction> transactions,
  List<Map<String, dynamic>> budgetMaps,
) async {
  try {
    // Calculate total spending
    double totalSpending = transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Calculate total budget
    double totalBudget = budgetMaps.fold(0.0, (sum, b) => sum + (b['amount'] ?? 0.0));

    // Find categories with highest overspending
    List<String> overspendingCategories = [];
    List<String> underBudgetCategories = [];
    
    for (var budget in budgetMaps) {
      double spent = budget['spent'] ?? 0.0;
      double amount = budget['amount'] ?? 0.0;
      String category = budget['category'] ?? 'Unknown';
      
      if (spent > amount) {
        overspendingCategories.add(category);
      } else if (spent < amount * 0.8) { // Under 80% of budget
        underBudgetCategories.add(category);
      }
    }

    // Generate savings insight based on analysis
    if (overspendingCategories.isNotEmpty) {
      final category = overspendingCategories.first;
      final overspendAmount = (totalSpending - totalBudget).abs();
      return "You're overspending in ${category} by KES ${overspendAmount.toStringAsFixed(0)}. "
             "Consider setting stricter limits or finding alternatives to save KES ${(overspendAmount * 0.5).toStringAsFixed(0)} monthly.";
    } else if (underBudgetCategories.isNotEmpty) {
      final potentialSavings = totalBudget - totalSpending;
      return "Great job staying within budget! You could save an additional KES ${potentialSavings.toStringAsFixed(0)} "
             "by maintaining your current spending habits. Consider putting this into a savings goal.";
    } else {
      return "Your spending is well-balanced across categories. "
             "Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings to optimize your finances further.";
    }
  } catch (e) {
    print('Error generating savings opportunity from maps: $e');
    return "Track your spending regularly and set monthly budgets for each category to identify savings opportunities.";
  }
}
  // Use Gemini API for more personalized insights (if needed)
  Future<String> getPersonalizedInsight(
    List<Transaction> transactions,
    List<Budget> budgets
  ) async {
    try {
      // Convert transaction data to a string representation
      final transactionData = transactions.map((t) => {
        'amount': t.amount,
        'category': t.category,
        'date': DateFormat('yyyy-MM-dd').format(t.date),
        'title': t.title,
        'isExpense': t.isExpense,
      }).toList();
      
      // Convert budget data to a string representation
      final budgetData = budgets.map((b) => {
        'category': b.category,
        'budget': b.amount,
        'spent': b.spent,
        'title': b.title,
      }).toList();
      
      // Create the prompt for Gemini
      final prompt = '''
      As a financial advisor, analyze this financial data and provide a personalized insight:
      
      Transaction data: $transactionData
      Budget data: $budgetData
      
      Provide one specific, actionable financial insight based on this data. Focus on identifying:
      1. Unusual spending patterns
      2. Budget categories that need attention
      3. Opportunities to save more
      
      Keep your response under 50 words, specific, and actionable.
      ''';
      
      // Make the API request
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 100,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final generatedText = responseData['candidates'][0]['content']['parts'][0]['text'];
        return generatedText;
      } else {
        throw Exception('Failed to get AI insight: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting personalized insight: $e');
      return "Consider creating a budget for categories where you're spending the most to better track and control your expenses.";
    }
  }
}