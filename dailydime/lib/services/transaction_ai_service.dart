// lib/services/transaction_ai_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class TransactionAIService {
  static final TransactionAIService _instance = TransactionAIService._internal();
  factory TransactionAIService() => _instance;
  TransactionAIService._internal();

  final String _geminiApiKey = AppConfig.geminiApiKey;
  final String _geminiModel = AppConfig.geminiModel;
  final String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  Future<Map<String, dynamic>> categorizeTransaction(String description, double amount) async {
    try {
      final prompt = '''
      Analyze this transaction and categorize it based on the description. Return the result as valid JSON with the following structure:
      {
        "category": "the best category", 
        "icon": "a suitable Material icon name",
        "color": "a suitable color for the category",
        "isExpense": true/false
      }
      
      Transaction: $description, Amount: ${AppConfig.currencySymbol} $amount
      
      Possible categories: Food, Transport, Shopping, Bills, Entertainment, Education, Health, Housing, Income, Salary, Transfer, Withdrawal, Saving, Investment, Other
      
      Common Material icon names: restaurant, directions_bus, shopping_bag, receipt, movie, school, local_hospital, home, payments, work, account_balance_wallet, savings, trending_up, category
      
      Color options: red, green, blue, orange, purple, teal, pink, amber, indigo, cyan
      ''';
      
      final response = await _callGeminiApi(prompt);
      
      if (response == null) {
        return _getDefaultCategory(description, amount);
      }
      
      // Extract JSON from response
      final jsonPattern = RegExp(r'{[\s\S]*}');
      final match = jsonPattern.firstMatch(response);
      
      if (match != null) {
        final jsonStr = match.group(0)!;
        try {
          final Map<String, dynamic> result = json.decode(jsonStr);
          
          // Convert string icon name to IconData
          final iconName = result['icon'] as String? ?? 'category';
          result['icon'] = _getIconFromName(iconName);
          
          // Convert string color to Color
          final colorName = result['color'] as String? ?? 'blue';
          result['color'] = _getColorFromName(colorName);
          
          return {
            'success': true,
            'category': result,
          };
        } catch (e) {
          debugPrint('Error parsing AI categorization: $e');
        }
      }
      
      return _getDefaultCategory(description, amount);
    } catch (e) {
      debugPrint('Error calling AI for categorization: $e');
      return _getDefaultCategory(description, amount);
    }
  }

  Future<Map<String, dynamic>> generateSpendingInsights(
    List<Transaction> transactions, {
    String timeframe = 'week',
  }) async {
    if (transactions.isEmpty) {
      return {'success': false, 'insights': []};
    }

    try {
      // Group transactions by category
      final Map<String, double> categorySpending = {};
      double totalIncome = 0;
      double totalExpense = 0;
      
      for (var tx in transactions) {
        if (tx.isExpense) {
          categorySpending[tx.category] = (categorySpending[tx.category] ?? 0) + tx.amount;
          totalExpense += tx.amount;
        } else {
          totalIncome += tx.amount;
        }
      }
      
      // Sort categories by spending amount
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Format categories for prompt
      final topCategories = sortedCategories.take(5).map((e) => 
        '${e.key}: ${AppConfig.currencySymbol} ${e.value.toStringAsFixed(2)}'
      ).join('\n');
      
      final startDate = transactions.map((tx) => tx.date).reduce(
        (a, b) => a.isBefore(b) ? a : b
      );
      
      final endDate = transactions.map((tx) => tx.date).reduce(
        (a, b) => a.isAfter(b) ? a : b
      );
      
      final dateRange = '${DateFormat('MMM d, yyyy').format(startDate)} to ${DateFormat('MMM d, yyyy').format(endDate)}';
      
      final prompt = '''
      Analyze this transaction data and generate 3-5 concise, actionable financial insights. Each insight should be one clear sentence with specific advice.

      Date Range: $dateRange
      Total Income: ${AppConfig.currencySymbol} ${totalIncome.toStringAsFixed(2)}
      Total Expenses: ${AppConfig.currencySymbol} ${totalExpense.toStringAsFixed(2)}
      
      Top Spending Categories:
      $topCategories
      
      Format your response as a valid JSON array of insights strings, like:
      ["Insight 1", "Insight 2", "Insight 3"]
      
      Focus on:
      - Spending patterns
      - Potential savings opportunities
      - Budget recommendations
      - Financial habits to improve
      ''';

      final response = await _callGeminiApi(prompt);
      
      if (response == null) {
        return {'success': false, 'insights': []};
      }
      
      // Extract JSON array from response
      final jsonPattern = RegExp(r'\[[\s\S]*\]');
      final match = jsonPattern.firstMatch(response);
      
      if (match != null) {
        final jsonStr = match.group(0)!;
        try {
          final List<dynamic> insightsList = json.decode(jsonStr);
          final List<String> insights = insightsList.map((e) => e.toString()).toList();
          
          return {'success': true, 'insights': insights};
        } catch (e) {
          debugPrint('Error parsing AI insights: $e');
        }
      }
      
      return {'success': false, 'insights': []};
    } catch (e) {
      debugPrint('Error generating spending insights: $e');
      return {'success': false, 'insights': []};
    }
  }

  Future<Map<String, dynamic>> generateTransactionInsight(
    Transaction transaction,
    List<Transaction> allTransactions,
  ) async {
    try {
      // Find similar transactions
      final similarTransactions = allTransactions.where((tx) => 
        tx.id != transaction.id && 
        tx.category == transaction.category &&
        tx.isExpense == transaction.isExpense
      ).toList();
      
      // Calculate average amount for this category
      double averageAmount = 0;
      if (similarTransactions.isNotEmpty) {
        averageAmount = similarTransactions.fold<double>(
          0, (sum, tx) => sum + tx.amount
        ) / similarTransactions.length;
      }
      
      // Find frequency pattern
      final frequency = _analyzeTransactionFrequency(
        transaction,
        similarTransactions,
      );
      
      final prompt = '''
      Generate a personalized financial insight for this specific transaction:
      
      Transaction: ${transaction.title}
      Category: ${transaction.category}
      Amount: ${AppConfig.currencySymbol} ${transaction.amount.toStringAsFixed(2)}
      Date: ${DateFormat('MMMM d, yyyy').format(transaction.date)}
      Type: ${transaction.isExpense ? 'Expense' : 'Income'}
      
      Additional context:
      - Average amount for this category: ${AppConfig.currencySymbol} ${averageAmount.toStringAsFixed(2)}
      - This transaction is ${transaction.amount > averageAmount ? 'above' : 'below'} average
      - Frequency pattern: $frequency
      
      Provide ONE concise paragraph (3-4 sentences) of insight that is:
      1. Specific to this transaction
      2. Actionable (gives practical advice)
      3. Contextual (compares to past behavior)
      4. Forward-looking (suggests future improvements)
      
      Don't include any JSON formatting, just return the plain text insight.
      ''';

      final response = await _callGeminiApi(prompt);
      
      if (response == null || response.isEmpty) {
        return {'success': false, 'insight': null};
      }
      
      // Clean up the response
      final cleanedResponse = response
          .replaceAll('"', '')
          .replaceAll('```', '')
          .trim();
      
      return {'success': true, 'insight': cleanedResponse};
    } catch (e) {
      debugPrint('Error generating transaction insight: $e');
      return {'success': false, 'insight': null};
    }
  }

  String _analyzeTransactionFrequency(
    Transaction currentTx,
    List<Transaction> similarTransactions,
  ) {
    if (similarTransactions.isEmpty) {
      return "First time transaction";
    }

    // Sort by date
    similarTransactions.sort((a, b) => a.date.compareTo(b.date));
    
    // Check if it's a recurring transaction
    final Map<String, int> dayOfMonthFrequency = {};
    final Map<int, int> dayOfWeekFrequency = {};
    
    for (var tx in similarTransactions) {
      final dayOfMonth = DateFormat('d').format(tx.date);
      dayOfMonthFrequency[dayOfMonth] = (dayOfMonthFrequency[dayOfMonth] ?? 0) + 1;
      
      final dayOfWeek = tx.date.weekday;
      dayOfWeekFrequency[dayOfWeek] = (dayOfWeekFrequency[dayOfWeek] ?? 0) + 1;
    }
    
    // Check monthly pattern
    final maxMonthDay = dayOfMonthFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b);
        
    if (maxMonthDay.value >= 2 && similarTransactions.length >= 3) {
      return "Recurring monthly transaction (usually on day ${maxMonthDay.key})";
    }
    
    // Check weekly pattern
    final maxWeekDay = dayOfWeekFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b);
        
    if (maxWeekDay.value >= 2 && similarTransactions.length >= 3) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return "Recurring weekly transaction (usually on ${weekdays[maxWeekDay.key - 1]})";
    }
    
    // Check frequency
    final daysPerTransaction = (currentTx.date.difference(similarTransactions.first.date).inDays) / 
                               (similarTransactions.length);
    
    if (daysPerTransaction <= 7) {
      return "Very frequent transaction (multiple times per week)";
    } else if (daysPerTransaction <= 14) {
      return "Frequent transaction (weekly/biweekly)";
    } else if (daysPerTransaction <= 35) {
      return "Regular transaction (monthly)";
    } else {
      return "Occasional transaction";
    }
  }

  Future<String?> _callGeminiApi(String prompt) async {
    try {
      final url = '$_geminiUrl/$_geminiModel:generateContent?key=$_geminiApiKey';
      
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
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final candidates = responseData['candidates'];
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            return content['parts'][0]['text'];
          }
        }
      }
      
      debugPrint('API error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> analyzeSmsTransaction(String smsBody) async {
    try {
      final prompt = '''
      Analyze this SMS message from a mobile money service and extract the transaction details.
      Return the result as valid JSON with the following structure:
      {
        "transactionType": "one of: payment, transfer, deposit, withdrawal, balance, bill",
        "amount": the transaction amount (as a number),
        "isExpense": true/false,
        "category": "best category name",
        "recipient": "name of recipient (if present)",
        "sender": "name of sender (if present)",
        "business": "name of business (if present)",
        "agent": "name of agent (if present)",
        "balance": the balance amount (if present, as a number),
        "transactionId": "the transaction code/ID"
      }
      
      SMS Message:
      $smsBody
      
      Possible categories: Food, Transport, Shopping, Bills, Entertainment, Education, Health, Housing, Income, Salary, Transfer, Withdrawal, Saving, Other
      ''';
      
      final response = await _callGeminiApi(prompt);
      
      if (response == null) {
        return {'success': false, 'transaction': null};
      }
      
      // Extract JSON from response
      final jsonPattern = RegExp(r'{[\s\S]*}');
      final match = jsonPattern.firstMatch(response);
      
      if (match != null) {
        final jsonStr = match.group(0)!;
        try {
          final Map<String, dynamic> result = json.decode(jsonStr);
          return {'success': true, 'transaction': result};
        } catch (e) {
          debugPrint('Error parsing SMS analysis: $e');
        }
      }
      
      return {'success': false, 'transaction': null};
    } catch (e) {
      debugPrint('Error analyzing SMS transaction: $e');
      return {'success': false, 'transaction': null};
    }
  }

  Map<String, dynamic> _getDefaultCategory(String description, double amount) {
    // Default categorization logic
    final desc = description.toLowerCase();
    
    if (desc.contains('food') || desc.contains('restaurant') || desc.contains('cafe')) {
      return {
        'success': true,
        'category': {
          'category': 'Food',
          'icon': Icons.restaurant,
          'color': Colors.orange,
          'isExpense': true
        }
      };
    } else if (desc.contains('uber') || desc.contains('transport') || desc.contains('taxi')) {
      return {
        'success': true,
        'category': {
          'category': 'Transport',
          'icon': Icons.directions_bus,
          'color': Colors.blue,
          'isExpense': true
        }
      };
    } else if (desc.contains('salary') || desc.contains('income') || desc.contains('payment received')) {
      return {
        'success': true,
        'category': {
          'category': 'Income',
          'icon': Icons.payments,
          'color': Colors.green,
          'isExpense': false
        }
      };
    } else {
      return {
        'success': true,
        'category': {
          'category': amount > 0 ? 'Income' : 'Other',
          'icon': amount > 0 ? Icons.payments : Icons.category,
          'color': amount > 0 ? Colors.green : Colors.purple,
          'isExpense': amount < 0
        }
      };
    }
  }

  IconData _getIconFromName(String name) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_bus': Icons.directions_bus,
      'shopping_bag': Icons.shopping_bag,
      'receipt': Icons.receipt,
      'movie': Icons.movie,
      'school': Icons.school,
      'local_hospital': Icons.local_hospital,
      'home': Icons.home,
      'payments': Icons.payments,
      'work': Icons.work,
      'account_balance_wallet': Icons.account_balance_wallet,
      'savings': Icons.savings,
      'trending_up': Icons.trending_up,
      'category': Icons.category,
      // Add more mappings as needed
    };

    return iconMap[name] ?? Icons.category;
  }

  Color _getColorFromName(String name) {
    final colorMap = {
      'red': Colors.red.shade700,
      'green': Colors.green.shade700,
      'blue': Colors.blue.shade700,
      'orange': Colors.orange.shade700,
      'purple': Colors.purple.shade700,
      'teal': Colors.teal.shade700,
      'pink': Colors.pink.shade700,
      'amber': Colors.amber.shade700,
      'indigo': Colors.indigo.shade700,
      'cyan': Colors.cyan.shade700,
      // Add more mappings as needed
    };

    return colorMap[name] ?? Colors.blue.shade700;
  }
}