// lib/services/savings_ai_service.dart

import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class SavingsAIService {
  static final SavingsAIService _instance = SavingsAIService._internal();
  factory SavingsAIService() => _instance;
  SavingsAIService._internal();

  final GenerativeModel _model = GenerativeModel(
    model: AppConfig.geminiModel,
    apiKey: AppConfig.geminiApiKey,
  );

  // Analyze SMS transactions to find saving opportunities
  Future<Map<String, dynamic>> analyzeSavingOpportunities(List<Transaction> transactions) async {
    try {
      // Structure the transaction data for the AI
      final List<Map<String, dynamic>> transactionData = transactions
          .where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .map((t) => {
                'amount': t.amount,
                'isExpense': t.isExpense,
                'category': t.category,
                'date': t.date.toIso8601String(),
                'title': t.title,
              })
          .toList();
      
      // Build the prompt
      final prompt = '''
        Analyze these recent transactions and identify potential savings opportunities.
        Specifically, suggest:
        1. Recurring expenses that could be reduced
        2. Categories where the user is overspending
        3. A specific amount that could be saved today or this week
        4. Which existing savings goal this amount should go towards
        
        Transactions: ${jsonEncode(transactionData)}
        
        Return a JSON response with these fields:
        {
          "savingAmount": (number),
          "reason": (string explanation),
          "recommendedGoal": (string - either "emergency", "existing goal name", or "new goal"),
          "insights": [array of strings with insights],
          "recurringExpenses": [array of objects with name and amount]
        }
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final textResponse = response.text;
      
      if (textResponse == null) {
        return {'error': 'No response from AI model'};
      }
      
      // Extract the JSON from the response (handling potential markdown formatting)
      final jsonRegExp = RegExp(r'```json\s*({[\s\S]*?})\s*```|({[\s\S]*})');
      final match = jsonRegExp.firstMatch(textResponse);
      
      if (match != null) {
        final jsonStr = (match.group(1) ?? match.group(2))?.trim();
        if (jsonStr != null) {
          return jsonDecode(jsonStr);
        }
      }
      
      // Fallback simple parsing attempt
      return jsonDecode(textResponse.trim());
    } catch (e) {
      debugPrint('Error analyzing saving opportunities: $e');
      return {
        'savingAmount': 500.0,
        'reason': 'Based on your recent spending patterns',
        'recommendedGoal': 'emergency',
        'insights': ['You could save more by reducing food delivery expenses'],
        'recurringExpenses': [{'name': 'Subscriptions', 'amount': 1200}]
      };
    }
  }
  
  // Detect recurring expenses from SMS transactions
  Future<List<Map<String, dynamic>>> detectRecurringExpenses(List<Transaction> transactions) async {
    try {
      // Filter to at least 2 months of data
      final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
      final filteredTransactions = transactions
          .where((t) => t.date.isAfter(twoMonthsAgo) && t.isExpense)
          .toList();
          
      // Structure data for the AI
      final List<Map<String, dynamic>> transactionData = filteredTransactions
          .map((t) => {
                'amount': t.amount,
                'category': t.category,
                'date': t.date.toIso8601String(),
                'title': t.title,
              })
          .toList();
      
      final prompt = '''
        Analyze these transactions and identify recurring expenses/subscriptions.
        Look for patterns in similar payment amounts or to the same recipient on a regular schedule.
        
        Transactions: ${jsonEncode(transactionData)}
        
        Return a JSON array of objects with these fields:
        [
          {
            "name": (string - recipient or service name),
            "amount": (number - the typical amount),
            "frequency": (string - "daily", "weekly", "monthly", or "yearly"),
            "category": (string)
          }
        ]
      ''';

      final response = await _model.generateContent(content: [Content.text(prompt)]);
      final textResponse = response.text;
      
      if (textResponse == null) {
        return [];
      }
      
      // Extract the JSON array from the response
      final jsonRegExp = RegExp(r'```json\s*(\[[\s\S]*?\])\s*```|(\[[\s\S]*\])');
      final match = jsonRegExp.firstMatch(textResponse);
      
      if (match != null) {
        final jsonStr = (match.group(1) ?? match.group(2))?.trim();
        if (jsonStr != null) {
          return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
        }
      }
      
      // Fallback
      return List<Map<String, dynamic>>.from(jsonDecode(textResponse.trim()));
    } catch (e) {
      debugPrint('Error detecting recurring expenses: $e');
      return [
        {'name': 'Netflix', 'amount': 1100, 'frequency': 'monthly', 'category': 'Entertainment'},
        {'name': 'Gym', 'amount': 2500, 'frequency': 'monthly', 'category': 'Health'}
      ];
    }
  }
  
  // Generate personalized savings suggestions
  Future<List<Map<String, dynamic>>> generateSavingsSuggestions(
    List<Transaction> recentTransactions,
    double monthlyIncome,
    List<SavingsGoal> existingGoals,
  ) async {
    try {
      // Prepare context data
      final Map<String, dynamic> userData = {
        'monthlyIncome': monthlyIncome,
        'existingGoals': existingGoals.map((g) => {
          'title': g.title,
          'targetAmount': g.targetAmount,
          'currentAmount': g.currentAmount,
          'daysLeft': g.daysLeft,
          'category': g.category.toString().split('.').last,
        }).toList(),
        'recentTransactions': recentTransactions
            .take(30)
            .map((t) => {
                  'amount': t.amount,
                  'isExpense': t.isExpense,
                  'category': t.category,
                })
            .toList(),
      };
      
      final prompt = '''
        Based on this user's financial data, suggest 3-5 personalized savings goals that would be appropriate.
        
        User Data: ${jsonEncode(userData)}
        
        For each goal suggestion, provide:
        1. A title
        2. Target amount
        3. Recommended timeframe (in months)
        4. A compelling reason why this goal would benefit them
        5. A category
        
        Return a JSON array of goal suggestions with these properties.
      ''';

      final response = await _model.generateContent(content: [Content.text(prompt)]);
      final textResponse = response.text;
      
      if (textResponse == null) {
        return [];
      }
      
      // Extract JSON
      final jsonRegExp = RegExp(r'```json\s*(\[[\s\S]*?\])\s*```|(\[[\s\S]*\])');
      final match = jsonRegExp.firstMatch(textResponse);
      
      if (match != null) {
        final jsonStr = (match.group(1) ?? match.group(2))?.trim();
        if (jsonStr != null) {
          return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
        }
      }
      
      // Fallback
      return List<Map<String, dynamic>>.from(jsonDecode(textResponse.trim()));
    } catch (e) {
      debugPrint('Error generating savings suggestions: $e');
      return [
        {
          'title': 'Emergency Fund',
          'targetAmount': 60000,
          'timeframeMonths': 6,
          'reason': 'Financial security in case of unexpected expenses',
          'category': 'emergency'
        },
        {
          'title': 'Dream Vacation',
          'targetAmount': 120000,
          'timeframeMonths': 12,
          'reason': 'Based on your spending patterns, you deserve a break',
          'category': 'travel'
        }
      ];
    }
  }
  
  // Generate motivation or goal adjustment based on progress
  Future<Map<String, dynamic>> getGoalInsights(SavingsGoal goal) async {
    try {
      final Map<String, dynamic> goalData = {
        'title': goal.title,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'progressPercentage': goal.progressPercentage,
        'startDate': goal.startDate.toIso8601String(),
        'targetDate': goal.targetDate.toIso8601String(),
        'daysLeft': goal.daysLeft,
        'isOnTrack': goal.isOnTrack,
        'transactions': goal.transactions.map((t) => {
          'amount': t.amount,
          'date': t.date.toIso8601String(),
        }).toList(),
      };
      
      final prompt = '''
        Analyze this savings goal and provide insights.
        
        Goal Data: ${jsonEncode(goalData)}
        
        Return a JSON object with:
        1. A motivational message appropriate to their progress
        2. Practical advice to help them stay on track or catch up
        3. Whether they need to adjust their goal (yes/no)
        4. If adjustment needed, a suggested new target date or amount
        5. A forecast on whether they'll meet their goal on time
        6. Weekly savings needed to stay on track
      ''';

      final response = await _model.generateContent(content: [Content.text(prompt)]);
      final textResponse = response.text;
      
      if (textResponse == null) {
        return {
          'motivationalMessage': 'Keep up the good work! You\'re making progress.',
          'practicalAdvice': 'Try to save a little bit more each week to reach your goal faster.',
          'needsAdjustment': false,
          'forecast': 'on track',
          'weeklySavingsNeeded': goal.dailySavingNeeded * 7
        };
      }
      
      // Extract JSON
      final jsonRegExp = RegExp(r'```json\s*({[\s\S]*?})\s*```|({[\s\S]*})');
      final match = jsonRegExp.firstMatch(textResponse);
      
      if (match != null) {
        final jsonStr = (match.group(1) ?? match.group(2))?.trim();
        if (jsonStr != null) {
          return jsonDecode(jsonStr);
        }
      }
      
      // Fallback
      return jsonDecode(textResponse.trim());
    } catch (e) {
      debugPrint('Error getting goal insights: $e');
      return {
        'motivationalMessage': 'Keep up the good work! You\'re making progress.',
        'practicalAdvice': 'Try to save a little bit more each week to reach your goal faster.',
        'needsAdjustment': false,
        'forecast': 'on track',
        'weeklySavingsNeeded': goal.dailySavingNeeded * 7
      };
    }
  }
  
  // Generate a new savings challenge or goal based on user data
  Future<Map<String, dynamic>> generateSavingsChallenge(
    List<Transaction> transactions, 
    double averageMonthlySavings
  ) async {
    try {
      final Map<String, dynamic> userData = {
        'averageMonthlySavings': averageMonthlySavings,
        'recentTransactions': transactions
            .take(30)
            .map((t) => {
                  'amount': t.amount,
                  'isExpense': t.isExpense,
                  'category': t.category,
                })
            .toList(),
      };
      
      final prompt = '''
        Create a personalized savings challenge for this user based on their transaction history.
        
        User Data: ${jsonEncode(userData)}
        
        The challenge should be:
        1. Realistic based on their spending patterns
        2. Have a specific timeframe (1-3 months)
        3. Have a specific savings target
        4. Include a daily or weekly action plan
        5. Be motivating and achievable
        
        Return a JSON object with the challenge details.
      ''';

      final response = await _model.generateContent(content: [Content.text(prompt)]);
      final textResponse = response.text;
      
      if (textResponse == null) {
        return {
          'title': '30-Day Money-Saving Challenge',
          'description': 'Save KES 100 more each day than the previous day',
          'timeframeDays': 30,
          'targetAmount': 45000,
          'dailyPlan': 'Start with KES 100 on day 1, increase by KES 100 each day',
          'difficulty': 'moderate'
        };
      }
      
      // Extract JSON
      final jsonRegExp = RegExp(r'```json\s*({[\s\S]*?})\s*```|({[\s\S]*})');
      final match = jsonRegExp.firstMatch(textResponse);
      
      if (match != null) {
        final jsonStr = (match.group(1) ?? match.group(2))?.trim();
        if (jsonStr != null) {
          return jsonDecode(jsonStr);
        }
      }
      
      // Fallback
      return jsonDecode(textResponse.trim());
    } catch (e) {
      debugPrint('Error generating savings challenge: $e');
      return {
        'title': '30-Day Money-Saving Challenge',
        'description': 'Save KES 100 more each day than the previous day',
        'timeframeDays': 30,
        'targetAmount': 45000,
        'dailyPlan': 'Start with KES 100 on day 1, increase by KES 100 each day',
        'difficulty': 'moderate'
      };
    }
  }
}