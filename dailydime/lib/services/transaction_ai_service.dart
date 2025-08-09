// lib/services/transaction_ai_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';

class TransactionAIService {
  static final TransactionAIService _instance = TransactionAIService._internal();
  factory TransactionAIService() => _instance;
  TransactionAIService._internal();

  // Category mapping with icons and colors
  final Map<String, Map<String, dynamic>> _categoryMapping = {
    'Food': {
      'icon': Icons.restaurant,
      'color': Colors.orange.shade700,
      'isExpense': true,
    },
    'Transport': {
      'icon': Icons.directions_bus,
      'color': Colors.blue.shade700,
      'isExpense': true,
    },
    'Shopping': {
      'icon': Icons.shopping_bag,
      'color': Colors.pink.shade700,
      'isExpense': true,
    },
    'Bills': {
      'icon': Icons.receipt,
      'color': Colors.red.shade700,
      'isExpense': true,
    },
    'Entertainment': {
      'icon': Icons.movie,
      'color': Colors.purple.shade700,
      'isExpense': true,
    },
    'Health': {
      'icon': Icons.local_hospital,
      'color': Colors.red.shade400,
      'isExpense': true,
    },
    'Education': {
      'icon': Icons.school,
      'color': Colors.blue.shade800,
      'isExpense': true,
    },
    'Income': {
      'icon': Icons.payments,
      'color': Colors.green.shade700,
      'isExpense': false,
    },
    'Salary': {
      'icon': Icons.work,
      'color': Colors.green.shade800,
      'isExpense': false,
    },
    'Transfer': {
      'icon': Icons.swap_horiz,
      'color': Colors.blue.shade600,
      'isExpense': false,
    },
    'Other': {
      'icon': Icons.category,
      'color': Colors.purple.shade700,
      'isExpense': true,
    },
  };

  /// Categorize a transaction using AI
  Future<Map<String, dynamic>> categorizeTransaction(String title, double amount) async {
    try {
      // First try rule-based categorization for common patterns
      final ruleBasedResult = _ruleBasedCategorization(title, amount);
      if (ruleBasedResult != null) {
        return {
          'success': true,
          'category': ruleBasedResult,
        };
      }

      // If rule-based doesn't work, use AI
      final prompt = '''
Analyze this transaction and categorize it. Return ONLY the category name from this exact list:
Food, Transport, Shopping, Bills, Entertainment, Health, Education, Income, Salary, Transfer, Other

Transaction: "$title"
Amount: KSH ${amount.toStringAsFixed(2)}

Consider Kenyan context (M-Pesa, matatu, nyama choma, etc.). Return ONLY the category name, nothing else.
''';

      final aiResponse = await _callGeminiAPI(prompt);
      if (aiResponse != null) {
        final categoryName = aiResponse.trim();
        if (_categoryMapping.containsKey(categoryName)) {
          return {
            'success': true,
            'category': {
              'category': categoryName,
              'icon': _categoryMapping[categoryName]!['icon'],
              'color': _categoryMapping[categoryName]!['color'],
              'isExpense': _categoryMapping[categoryName]!['isExpense'],
            },
          };
        }
      }

      // Fallback to Other category
      return {
        'success': true,
        'category': {
          'category': 'Other',
          'icon': _categoryMapping['Other']!['icon'],
          'color': _categoryMapping['Other']!['color'],
          'isExpense': _categoryMapping['Other']!['isExpense'],
        },
      };
    } catch (e) {
      debugPrint('Error categorizing transaction: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Rule-based categorization for common patterns
  Map<String, dynamic>? _ruleBasedCategorization(String title, double amount) {
    final titleLower = title.toLowerCase();

    // Income patterns
    if (titleLower.contains('salary') || 
        titleLower.contains('wage') || 
        titleLower.contains('pay') ||
        titleLower.contains('allowance')) {
      return {
        'category': 'Salary',
        'icon': _categoryMapping['Salary']!['icon'],
        'color': _categoryMapping['Salary']!['color'],
        'isExpense': false,
      };
    }

    // M-Pesa patterns
    if (titleLower.contains('mpesa') || titleLower.contains('m-pesa')) {
      if (titleLower.contains('received') || titleLower.contains('deposit')) {
        return {
          'category': 'Income',
          'icon': _categoryMapping['Income']!['icon'],
          'color': _categoryMapping['Income']!['color'],
          'isExpense': false,
        };
      } else if (titleLower.contains('sent') || titleLower.contains('transfer')) {
        return {
          'category': 'Transfer',
          'icon': _categoryMapping['Transfer']!['icon'],
          'color': _categoryMapping['Transfer']!['color'],
          'isExpense': true,
        };
      }
    }

    // Transport patterns
    if (titleLower.contains('matatu') || 
        titleLower.contains('uber') || 
        titleLower.contains('taxi') ||
        titleLower.contains('bus') ||
        titleLower.contains('fuel') ||
        titleLower.contains('petrol')) {
      return {
        'category': 'Transport',
        'icon': _categoryMapping['Transport']!['icon'],
        'color': _categoryMapping['Transport']!['color'],
        'isExpense': true,
      };
    }

    // Food patterns
    if (titleLower.contains('restaurant') || 
        titleLower.contains('hotel') || 
        titleLower.contains('food') ||
        titleLower.contains('lunch') ||
        titleLower.contains('dinner') ||
        titleLower.contains('breakfast') ||
        titleLower.contains('nyama choma') ||
        titleLower.contains('kfc') ||
        titleLower.contains('pizza')) {
      return {
        'category': 'Food',
        'icon': _categoryMapping['Food']!['icon'],
        'color': _categoryMapping['Food']!['color'],
        'isExpense': true,
      };
    }

    // Shopping patterns
    if (titleLower.contains('shop') || 
        titleLower.contains('store') || 
        titleLower.contains('supermarket') ||
        titleLower.contains('mall') ||
        titleLower.contains('tuskys') ||
        titleLower.contains('naivas') ||
        titleLower.contains('carrefour')) {
      return {
        'category': 'Shopping',
        'icon': _categoryMapping['Shopping']!['icon'],
        'color': _categoryMapping['Shopping']!['color'],
        'isExpense': true,
      };
    }

    // Bills patterns
    if (titleLower.contains('electricity') || 
        titleLower.contains('water') || 
        titleLower.contains('rent') ||
        titleLower.contains('internet') ||
        titleLower.contains('airtel') ||
        titleLower.contains('safaricom') ||
        titleLower.contains('kplc')) {
      return {
        'category': 'Bills',
        'icon': _categoryMapping['Bills']!['icon'],
        'color': _categoryMapping['Bills']!['color'],
        'isExpense': true,
      };
    }

    // Entertainment patterns
    if (titleLower.contains('movie') || 
        titleLower.contains('cinema') || 
        titleLower.contains('game') ||
        titleLower.contains('club') ||
        titleLower.contains('bar') ||
        titleLower.contains('entertainment')) {
      return {
        'category': 'Entertainment',
        'icon': _categoryMapping['Entertainment']!['icon'],
        'color': _categoryMapping['Entertainment']!['color'],
        'isExpense': true,
      };
    }

    // Health patterns
    if (titleLower.contains('hospital') || 
        titleLower.contains('clinic') || 
        titleLower.contains('doctor') ||
        titleLower.contains('medicine') ||
        titleLower.contains('pharmacy') ||
        titleLower.contains('medical')) {
      return {
        'category': 'Health',
        'icon': _categoryMapping['Health']!['icon'],
        'color': _categoryMapping['Health']!['color'],
        'isExpense': true,
      };
    }

    // Education patterns
    if (titleLower.contains('school') || 
        titleLower.contains('fees') || 
        titleLower.contains('tuition') ||
        titleLower.contains('book') ||
        titleLower.contains('course') ||
        titleLower.contains('education')) {
      return {
        'category': 'Education',
        'icon': _categoryMapping['Education']!['icon'],
        'color': _categoryMapping['Education']!['color'],
        'isExpense': true,
      };
    }

    return null; // No rule matched
  }

  /// Generate spending insights from transactions
  Future<Map<String, dynamic>> generateSpendingInsights(
    List<Transaction> transactions, {
    String timeframe = 'month',
  }) async {
    try {
      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transaction data available for analysis',
          'insights': [],
        };
      }

      // Prepare transaction data for the AI model
      final List<Map<String, dynamic>> txData = transactions.map((tx) => {
        'title': tx.title,
        'amount': tx.amount,
        'category': tx.category,
        'date': tx.date.toIso8601String(),
        'isExpense': tx.isExpense,
      }).toList();

      // Calculate basic statistics
      final totalExpenses = transactions
          .where((tx) => tx.isExpense)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final totalIncome = transactions
          .where((tx) => !tx.isExpense)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final categorySpending = <String, double>{};
      
      for (final tx in transactions.where((tx) => tx.isExpense)) {
        categorySpending[tx.category] = 
            (categorySpending[tx.category] ?? 0) + tx.amount;
      }

      // Construct the prompt for Gemini
      final prompt = '''
Analyze these Kenyan financial transactions and provide 5 actionable insights:

Total Income: KSH ${totalIncome.toStringAsFixed(2)}
Total Expenses: KSH ${totalExpenses.toStringAsFixed(2)}
Category Breakdown: ${categorySpending.entries.map((e) => '${e.key}: KSH ${e.value.toStringAsFixed(2)}').join(', ')}

Transaction Data: ${json.encode(txData.take(20).toList())} ${txData.length > 20 ? '... and ${txData.length - 20} more' : ''}

Provide 5 specific insights for a Kenyan user:
1. Spending patterns analysis
2. Budget optimization suggestion
3. Money-saving opportunity
4. Financial habit improvement
5. Goal-setting recommendation

Keep each insight to 2-3 sentences. Be specific and actionable. Consider Kenyan context (M-Pesa, cost of living, etc.).
      ''';

      // Call Gemini API
      final insights = await _callGeminiAPI(prompt);
      
      if (insights != null) {
        // Parse insights into a list
        List<String> insightsList = _parseInsights(insights);
        
        return {
          'success': true,
          'insights': insightsList,
          'stats': {
            'totalIncome': totalIncome,
            'totalExpenses': totalExpenses,
            'netAmount': totalIncome - totalExpenses,
            'categoryBreakdown': categorySpending,
          },
        };
      }

      return {
        'success': false,
        'message': 'Failed to generate insights',
        'insights': [],
      };
    } catch (e) {
      debugPrint('Error generating spending insights: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'insights': [],
      };
    }
  }

  /// Parse AI-generated insights into a clean list
  List<String> _parseInsights(String insights) {
    // Split by numbered points or double newlines
    List<String> insightsList = insights
        .split(RegExp(r'\n\s*\n|\d+\.\s*'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    
    // If we don't have enough insights, try different splitting
    if (insightsList.length < 3) {
      insightsList = insights
          .split('\n')
          .where((s) => s.trim().isNotEmpty && s.length > 20)
          .toList();
    }
    
    // Clean up the insights
    insightsList = insightsList.map((s) {
      String cleaned = s.trim();
      // Remove numbered bullets (1., 2., etc.)
      cleaned = cleaned.replaceFirst(RegExp(r'^\d+\.\s*'), '');
      // Remove bullet points
      if (cleaned.startsWith('• ') || cleaned.startsWith('* ') || cleaned.startsWith('- ')) {
        cleaned = cleaned.substring(2);
      }
      return cleaned;
    }).where((s) => s.isNotEmpty && s.length > 10).toList();
    
    // Ensure we don't have too many insights
    if (insightsList.length > 5) {
      insightsList = insightsList.take(5).toList();
    }
    
    return insightsList;
  }

  /// Generate a simple AI insight from a prompt
  Future<String> generateSimpleInsight(String prompt) async {
    try {
      final result = await _callGeminiAPI(prompt);
      return result ?? 'Unable to generate insights at this time.';
    } catch (e) {
      debugPrint('Error generating simple insight: $e');
      return 'Error generating insights. Please try again.';
    }
  }

  /// Generate budget recommendations based on spending patterns
  Future<Map<String, dynamic>> generateBudgetRecommendations(
    List<Transaction> transactions,
    double monthlyIncome,
  ) async {
    try {
      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transaction data available',
        };
      }

      // Calculate current spending by category
      final categorySpending = <String, double>{};
      final totalExpenses = transactions
          .where((tx) => tx.isExpense)
          .fold(0.0, (sum, tx) => sum + tx.amount);

      for (final tx in transactions.where((tx) => tx.isExpense)) {
        categorySpending[tx.category] = 
            (categorySpending[tx.category] ?? 0) + tx.amount;
      }

      final prompt = '''
Create a budget recommendation for a Kenyan with monthly income of KSH ${monthlyIncome.toStringAsFixed(2)}.

Current spending:
${categorySpending.entries.map((e) => '${e.key}: KSH ${e.value.toStringAsFixed(2)}').join('\n')}
Total Expenses: KSH ${totalExpenses.toStringAsFixed(2)}

Recommend:
1. Percentage allocation for each spending category
2. Maximum amounts for each category
3. Savings target
4. Emergency fund goal

Format as: Category: X% (KSH Y)
Consider Kenyan cost of living and the 50/30/20 rule adapted for local context.
      ''';

      final recommendation = await _callGeminiAPI(prompt);
      
      if (recommendation != null) {
        return {
          'success': true,
          'recommendation': recommendation,
          'currentSpending': categorySpending,
          'totalExpenses': totalExpenses,
          'monthlyIncome': monthlyIncome,
        };
      }

      return {
        'success': false,
        'message': 'Failed to generate budget recommendations',
      };
    } catch (e) {
      debugPrint('Error generating budget recommendations: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Analyze spending trends over time
  Future<Map<String, dynamic>> analyzeSpendingTrends(
    List<Transaction> transactions,
  ) async {
    try {
      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transaction data available',
        };
      }

      // Group transactions by month
      final monthlySpending = <String, double>{};
      for (final tx in transactions.where((tx) => tx.isExpense)) {
        final monthKey = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
        monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + tx.amount;
      }

      final prompt = '''
Analyze spending trends from this monthly data:
${monthlySpending.entries.map((e) => '${e.key}: KSH ${e.value.toStringAsFixed(2)}').join('\n')}

Identify:
1. Spending trends (increasing/decreasing)
2. Seasonal patterns
3. Unusual spikes or drops
4. Recommendations for improvement

Keep response concise and actionable for a Kenyan user.
      ''';

      final analysis = await _callGeminiAPI(prompt);
      
      if (analysis != null) {
        return {
          'success': true,
          'analysis': analysis,
          'monthlyData': monthlySpending,
        };
      }

      return {
        'success': false,
        'message': 'Failed to analyze spending trends',
      };
    } catch (e) {
      debugPrint('Error analyzing spending trends: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Call Gemini API with the provided prompt
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
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
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

  /// Get available categories for manual selection
  Map<String, Map<String, dynamic>> getAvailableCategories() {
    return _categoryMapping;
  }

  /// Check if AI service is properly configured
  bool isConfigured() {
    return AppConfig.geminiApiKey.isNotEmpty && AppConfig.geminiModel.isNotEmpty;
  }
}