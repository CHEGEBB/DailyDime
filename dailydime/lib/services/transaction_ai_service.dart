// lib/services/transaction_ai_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:intl/intl.dart';

class TransactionAIService {
  static final TransactionAIService _instance = TransactionAIService._internal();
  factory TransactionAIService() => _instance;
  TransactionAIService._internal();
  
  final String _apiKey = AppConfig.geminiApiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent';
  
  // Generate spending insights based on recent transactions
  Future<Map<String, dynamic>> generateSpendingInsights(
    List<Transaction> transactions, {
    String timeframe = 'week',
  }) async {
    try {
      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transactions available for analysis',
          'insights': []
        };
      }
      
      // Filter transactions by timeframe
      final filteredTransactions = _filterTransactionsByTimeframe(transactions, timeframe);
      
      if (filteredTransactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transactions in the selected timeframe',
          'insights': []
        };
      }
      
      // Prepare transaction data for AI
      final transactionData = _prepareTransactionData(filteredTransactions);
      
      // Build prompt for the AI
      final prompt = _buildInsightPrompt(transactionData, timeframe);
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      if (response['success']) {
        // Parse insights from the response
        final insights = _parseInsights(response['content']);
        
        return {
          'success': true,
          'message': 'Successfully generated insights',
          'insights': insights,
          'summary': insights.isNotEmpty ? insights[0] : null,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to generate insights: ${response['error']}',
          'insights': []
        };
      }
    } catch (e) {
      debugPrint('Error generating spending insights: $e');
      return {
        'success': false,
        'message': 'Error generating insights: $e',
        'insights': []
      };
    }
  }
  
  // Generate an insight for a specific transaction
  Future<Map<String, dynamic>> generateTransactionInsight(
    Transaction transaction,
    List<Transaction> recentTransactions,
  ) async {
    try {
      // Build prompt for the AI
      final prompt = _buildTransactionSpecificPrompt(transaction, recentTransactions);
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      if (response['success']) {
        return {
          'success': true,
          'message': 'Successfully generated insight',
          'insight': response['content'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to generate insight: ${response['error']}',
          'insight': null,
        };
      }
    } catch (e) {
      debugPrint('Error generating transaction insight: $e');
      return {
        'success': false,
        'message': 'Error generating insight: $e',
        'insight': null,
      };
    }
  }
  
  // Get spending recommendations based on transaction history
  Future<Map<String, dynamic>> getSpendingRecommendations(
    List<Transaction> transactions,
    double monthlyIncome,
  ) async {
    try {
      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transactions available for analysis',
          'recommendations': []
        };
      }
      
      // Prepare transaction data for AI
      final transactionData = _prepareTransactionData(transactions);
      
      // Build prompt for the AI
      final prompt = _buildRecommendationPrompt(transactionData, monthlyIncome);
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      if (response['success']) {
        // Parse recommendations from the response
        final recommendations = _parseRecommendations(response['content']);
        
        return {
          'success': true,
          'message': 'Successfully generated recommendations',
          'recommendations': recommendations,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to generate recommendations: ${response['error']}',
          'recommendations': []
        };
      }
    } catch (e) {
      debugPrint('Error generating spending recommendations: $e');
      return {
        'success': false,
        'message': 'Error generating recommendations: $e',
        'recommendations': []
      };
    }
  }
  
  // Detect transaction anomalies (unusual spending patterns)
  Future<Map<String, dynamic>> detectAnomalies(List<Transaction> transactions) async {
    try {
      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transactions available for analysis',
          'anomalies': []
        };
      }
      
      // Prepare transaction data for AI
      final transactionData = _prepareTransactionData(transactions);
      
      // Build prompt for the AI
      final prompt = _buildAnomalyPrompt(transactionData);
      
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      
      if (response['success']) {
        // Parse anomalies from the response
        final anomalies = _parseAnomalies(response['content']);
        
        return {
          'success': true,
          'message': 'Successfully detected anomalies',
          'anomalies': anomalies,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to detect anomalies: ${response['error']}',
          'anomalies': []
        };
      }
    } catch (e) {
      debugPrint('Error detecting anomalies: $e');
      return {
        'success': false,
        'message': 'Error detecting anomalies: $e',
        'anomalies': []
      };
    }
  }
  
  // Helper method to call Gemini API
  Future<Map<String, dynamic>> _callGeminiAPI(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': prompt
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        
        return {
          'success': true,
          'content': content,
        };
      } else {
        debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'API Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      return {
        'success': false,
        'error': 'API Call Error: $e',
      };
    }
  }
  
  // Helper method to filter transactions by timeframe
  List<Transaction> _filterTransactionsByTimeframe(
    List<Transaction> transactions,
    String timeframe,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (timeframe.toLowerCase()) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        // Start of the current week (Sunday)
        startDate = now.subtract(Duration(days: now.weekday % 7));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case '3months':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case '6months':
        startDate = DateTime(now.year, now.month - 5, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1); // Default to current month
    }
    
    return transactions.where((tx) => tx.date.isAfter(startDate)).toList();
  }
  
  // Helper method to prepare transaction data for AI
  Map<String, dynamic> _prepareTransactionData(List<Transaction> transactions) {
    // Calculate total income and expenses
    double totalIncome = 0;
    double totalExpense = 0;
    
    // Group by category
    Map<String, double> categorySums = {};
    
    // Group by day of week
    Map<String, double> dayOfWeekSums = {};
    
    // Time series data
    Map<String, Map<String, double>> dailyData = {};
    
    // Process each transaction
    for (var tx in transactions) {
      // Income vs Expense
      if (tx.isExpense) {
        totalExpense += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
      
      // Category grouping
      final category = tx.category;
      if (categorySums.containsKey(category)) {
        categorySums[category] = categorySums[category]! + tx.amount;
      } else {
        categorySums[category] = tx.amount;
      }
      
      // Day of week grouping
      final dayOfWeek = DateFormat('EEEE').format(tx.date);
      if (dayOfWeekSums.containsKey(dayOfWeek)) {
        dayOfWeekSums[dayOfWeek] = dayOfWeekSums[dayOfWeek]! + (tx.isExpense ? tx.amount : 0);
      } else {
        dayOfWeekSums[dayOfWeek] = tx.isExpense ? tx.amount : 0;
      }
      
      // Daily data for time series
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      if (!dailyData.containsKey(dateStr)) {
        dailyData[dateStr] = {'income': 0, 'expense': 0};
      }
      
      if (tx.isExpense) {
        dailyData[dateStr]!['expense'] = dailyData[dateStr]!['expense']! + tx.amount;
      } else {
        dailyData[dateStr]!['income'] = dailyData[dateStr]!['income']! + tx.amount;
      }
    }
    
    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Get top 20 transactions for analysis
    final recentTransactions = transactions.take(20).map((tx) => {
      'title': tx.title,
      'amount': tx.amount,
      'category': tx.category,
      'date': DateFormat('yyyy-MM-dd').format(tx.date),
      'isExpense': tx.isExpense,
    }).toList();
    
    // Get top expense categories
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.take(5).map((e) => {
      'category': e.key,
      'amount': e.value,
      'percentage': e.value / (totalExpense > 0 ? totalExpense : 1) * 100,
    }).toList();
    
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netSavings': totalIncome - totalExpense,
      'savingsRate': totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0,
      'categories': categorySums,
      'topCategories': topCategories,
      'dayOfWeekSums': dayOfWeekSums,
      'dailyData': dailyData,
      'recentTransactions': recentTransactions,
      'transactionCount': transactions.length,
      'dateRange': {
        'start': DateFormat('yyyy-MM-dd').format(transactions.last.date),
        'end': DateFormat('yyyy-MM-dd').format(transactions.first.date),
      },
      'currency': AppConfig.primaryCurrency,
    };
  }
  
  // Helper method to build prompt for spending insights
  String _buildInsightPrompt(Map<String, dynamic> data, String timeframe) {
    final currency = data['currency'];
    final totalIncome = data['totalIncome'];
    final totalExpense = data['totalExpense'];
    final savingsRate = data['savingsRate'];
    final topCategories = data['topCategories'];
    
    final topCategoriesStr = topCategories.map((cat) => 
      "${cat['category']}: ${currency} ${cat['amount'].toStringAsFixed(2)} (${cat['percentage'].toStringAsFixed(1)}%)"
    ).join('\n');
    
    return '''
You are a financial advisor analyzing spending patterns to provide helpful insights.

TRANSACTION DATA SUMMARY:
- Timeframe: $timeframe
- Total Income: $currency ${totalIncome.toStringAsFixed(2)}
- Total Expenses: $currency ${totalExpense.toStringAsFixed(2)}
- Savings Rate: ${savingsRate.toStringAsFixed(1)}%
- Number of Transactions: ${data['transactionCount']}

TOP EXPENSE CATEGORIES:
$topCategoriesStr

Based on this information, please provide:
1. A concise summary of overall spending health (1-2 sentences)
2. Three specific insights about spending patterns
3. One actionable tip to improve financial health

Format your response as a JSON array of strings with exactly 5 items:
1. Overall summary
2-4. Three specific insights
5. One actionable tip

Keep each point short and specific (under 100 characters if possible).
''';
  }
  
  // Helper method to build prompt for transaction-specific insight
  String _buildTransactionSpecificPrompt(
    Transaction transaction,
    List<Transaction> recentTransactions,
  ) {
    // Find similar transactions in the same category
    final similarTransactions = recentTransactions
        .where((tx) => tx.category == transaction.category && tx.id != transaction.id)
        .take(5)
        .toList();
    
    // Calculate average amount for this category
    double categoryAverage = 0;
    if (similarTransactions.isNotEmpty) {
      categoryAverage = similarTransactions.fold(0.0, (sum, tx) => sum + tx.amount) / 
          similarTransactions.length;
    }
    
    // Calculate percentage difference
    double percentageDifference = 0;
    if (categoryAverage > 0) {
      percentageDifference = (transaction.amount - categoryAverage) / categoryAverage * 100;
    }
    
    final currency = AppConfig.primaryCurrency;
    final formattedDate = DateFormat('EEEE, MMMM d').format(transaction.date);
    
    return '''
You are a financial advisor providing a personalized insight for a specific transaction.

TRANSACTION DETAILS:
- Description: ${transaction.title}
- Amount: $currency ${transaction.amount.toStringAsFixed(2)}
- Category: ${transaction.category}
- Date: $formattedDate
- Type: ${transaction.isExpense ? 'Expense' : 'Income'}

CATEGORY CONTEXT:
- Average amount in this category: $currency ${categoryAverage.toStringAsFixed(2)}
- This transaction is ${percentageDifference.abs().toStringAsFixed(1)}% ${percentageDifference >= 0 ? 'higher' : 'lower'} than average

Based on this information, provide ONE specific, personalized insight or tip about this transaction. 
Make it actionable, specific to the transaction type and category, and under 100 characters if possible.
''';
  }
  
  // Helper method to build prompt for spending recommendations
  String _buildRecommendationPrompt(Map<String, dynamic> data, double monthlyIncome) {
    final currency = data['currency'];
    final totalExpense = data['totalExpense'];
    final categories = data['categories'];
    
    // Format categories
    final categoriesStr = categories.entries.map((entry) => 
      "${entry.key}: $currency ${entry.value.toStringAsFixed(2)}"
    ).join('\n');
    
    return '''
You are a financial advisor providing spending recommendations based on transaction history.

FINANCIAL DATA:
- Monthly Income: $currency ${monthlyIncome.toStringAsFixed(2)}
- Total Expenses: $currency ${totalExpense.toStringAsFixed(2)}
- Expense to Income Ratio: ${monthlyIncome > 0 ? (totalExpense / monthlyIncome * 100).toStringAsFixed(1) : 'N/A'}%

SPENDING BY CATEGORY:
$categoriesStr

Based on this information, please provide:
1. Overall assessment of budget health
2. Three specific recommendations to optimize spending
3. Suggested budget allocation (% of income) for top 3-5 categories

Format your response as a JSON array with exactly 5 items:
1. Overall assessment (1-2 sentences)
2-4. Three specific recommendations (1 sentence each)
5. Suggested budget allocation in format "Category: X%, Category: Y%, etc."

Keep each point concise and specific.
''';
  }
  
  // Helper method to build prompt for anomaly detection
  String _buildAnomalyPrompt(Map<String, dynamic> data) {
    final recentTransactions = data['recentTransactions'];
    final currency = data['currency'];
    
    // Convert transactions to string format
    final transactionsStr = recentTransactions.map((tx) =>
      "${tx['date']} | ${tx['title']} | $currency ${tx['amount'].toStringAsFixed(2)} | ${tx['category']} | ${tx['isExpense'] ? 'Expense' : 'Income'}"
    ).join('\n');
    
    return '''
You are a financial analyst looking for unusual patterns or anomalies in transaction history.

RECENT TRANSACTIONS:
$transactionsStr

Please identify any anomalies in these transactions, such as:
1. Unusually large transactions
2. Duplicate or potentially fraudulent transactions
3. Unexpected spending patterns
4. Transactions in unusual categories

Format your response as a JSON array of anomalies, where each anomaly has:
- "transaction": Brief description of the anomaly
- "reason": Why this is unusual
- "recommendation": Suggested action

If no anomalies are found, return an empty array.
Limit to at most 3 anomalies.
''';
  }
  
  // Helper methods to parse API responses
  
  List<String> _parseInsights(String content) {
    try {
      // Try to parse as JSON first
      final List<dynamic> insights = jsonDecode(content);
      return insights.cast<String>();
    } catch (e) {
      // If JSON parsing fails, try to extract numbered points
      final RegExp pointsRegex = RegExp(r'\d+\.\s+(.*?)(?=\d+\.\s+|$)', dotAll: true);
      final matches = pointsRegex.allMatches(content);
      
      if (matches.isNotEmpty) {
        return matches.map((m) => m.group(1)?.trim() ?? '').toList();
      } else {
        // Last resort: split by newlines and filter
        return content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .take(5)
            .toList();
      }
    }
  }
  
  List<Map<String, String>> _parseRecommendations(String content) {
    try {
      // Try to parse as JSON first
      final List<dynamic> recs = jsonDecode(content);
      return recs.map((item) => item is String ? {'text': item} : Map<String, String>.from(item)).toList();
    } catch (e) {
      // If JSON parsing fails, extract text
      final lines = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('```'))
          .toList();
      
      return lines.map((line) => {'text': line}).toList();
    }
  }
  
  List<Map<String, String>> _parseAnomalies(String content) {
    try {
      // Try to parse as JSON array
      final List<dynamic> anomalies = jsonDecode(content);
      return anomalies.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      // Fallback parsing
      final matches = RegExp(r'- Transaction:\s*(.*?)\s*- Reason:\s*(.*?)\s*- Recommendation:\s*(.*?)(?=- Transaction:|\Z)', 
          dotAll: true).allMatches(content);
      
      if (matches.isNotEmpty) {
        return matches.map((m) => {
          'transaction': m.group(1)?.trim() ?? '',
          'reason': m.group(2)?.trim() ?? '',
          'recommendation': m.group(3)?.trim() ?? '',
        }).toList();
      } else {
        // Last resort: just return the content as a single anomaly
        return [
          {
            'transaction': 'Potential anomaly detected',
            'reason': 'Unusual pattern in recent transactions',
            'recommendation': content.trim(),
          }
        ];
      }
    }
  }
}