// lib/services/gemini_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dailydime/config/app_config.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  late final String _apiKey;
  late final String _model;
  
  // HTTP client for API calls
  final http.Client _httpClient = http.Client();
  
  // Request tracking for rate limiting
  final List<DateTime> _requestHistory = [];
  static const int _maxRequestsPerMinute = 60;
  
  // Constructor
  GeminiService() {
    _apiKey = AppConfig.geminiApiKey;
    _model = AppConfig.geminiModel;
  }
  
  // ========== PUBLIC METHODS ==========
  
  /// Generate content using Gemini AI
  Future<String> generateContent(String prompt, {
    double temperature = 0.7,
    int maxTokens = 2048,
    List<String>? stopSequences,
  }) async {
    try {
      // Check rate limits
      await _checkRateLimit();
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
          'topK': 40,
          'topP': 0.95,
        },
        if (stopSequences != null && stopSequences.isNotEmpty)
          'generationConfig': {
            ...{
              'temperature': temperature,
              'maxOutputTokens': maxTokens,
              'topK': 40,
              'topP': 0.95,
            },
            'stopSequences': stopSequences,
          },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
        },
        body: json.encode(requestBody),
      );
      
      // Track request for rate limiting
      _requestHistory.add(DateTime.now());
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          return responseData['candidates'][0]['content']['parts'][0]['text'] ?? '';
        } else {
          throw GeminiException('No content generated', response.statusCode);
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw GeminiException('API Error: $errorMessage', response.statusCode);
      }
    } catch (e) {
      debugPrint('Error generating content with Gemini: $e');
      if (e is GeminiException) {
        rethrow;
      }
      throw GeminiException('Failed to generate content: ${e.toString()}', 500);
    }
  }
  
  /// Extract structured data from receipt text
  Future<Map<String, dynamic>> extractReceiptData(String ocrText) async {
    try {
      final prompt = '''
      You are a financial assistant that extracts structured data from receipt text. 
      Analyze the following OCR text from a receipt and extract the information in JSON format.
      
      Extract:
      1. Merchant/store name (string)
      2. Total amount (number only, no currency symbols)
      3. Date of purchase (in format YYYY-MM-DD if possible, or best guess)
      4. Category (Food, Grocery, Shopping, Transport, Health, Entertainment, etc.)
      5. List of items with prices if clearly identifiable
      
      Return ONLY a valid JSON object with this exact structure:
      {
        "merchant": "store name",
        "total": 0.00,
        "date": "YYYY-MM-DD",
        "category": "category name",
        "items": [
          {
            "name": "item name",
            "price": 0.00,
            "quantity": 1
          }
        ]
      }
      
      If any field cannot be determined, use reasonable defaults:
      - merchant: "Unknown Merchant"
      - total: 0.00
      - date: today's date
      - category: "Shopping"
      - items: empty array
      
      OCR Text:
      $ocrText
      ''';
      
      final response = await generateContent(
        prompt,
        temperature: 0.3, // Lower temperature for more consistent JSON output
        maxTokens: 1024,
      );
      
      // Clean the response to extract JSON
      final cleanedResponse = _extractJsonFromResponse(response);
      
      try {
        final parsedData = json.decode(cleanedResponse) as Map<String, dynamic>;
        
        // Validate and sanitize the data
        return _validateReceiptData(parsedData);
      } catch (e) {
        debugPrint('Failed to parse JSON response: $e');
        debugPrint('Raw response: $response');
        throw GeminiException('Invalid JSON response from AI', 422);
      }
    } catch (e) {
      debugPrint('Error extracting receipt data: $e');
      rethrow;
    }
  }
  
  /// Generate budget recommendations
  Future<Map<String, dynamic>> generateBudgetRecommendations({
    required double income,
    required double totalExpenses,
    required double savingsGoal,
    required List<Map<String, dynamic>> expenseCategories,
  }) async {
    try {
      final discretionary = income - totalExpenses - savingsGoal;
      
      final prompt = '''
      You are a financial advisor. Create a comprehensive budget plan based on the following:
      
      Financial Information:
      - Monthly Income: ${AppConfig.formatCurrency(income)}
      - Fixed Expenses: ${AppConfig.formatCurrency(totalExpenses)}
      - Savings Goal: ${AppConfig.formatCurrency(savingsGoal)}
      - Available for Discretionary Spending: ${AppConfig.formatCurrency(discretionary)}
      
      Current Expense Categories:
      ${expenseCategories.map((e) => '- ${e['name']}: ${AppConfig.formatCurrency(e['amount'] as double)}').join('\n')}
      
      Provide budget recommendations in this exact JSON format:
      {
        "income": $income,
        "totalExpenses": $totalExpenses,
        "savings": $savingsGoal,
        "discretionary": $discretionary,
        "dailyLimit": 0.00,
        "weeklyLimit": 0.00,
        "categoryBreakdown": {
          "Food": 0.00,
          "Transportation": 0.00,
          "Entertainment": 0.00,
          "Shopping": 0.00,
          "Health": 0.00,
          "Other": 0.00
        },
        "recommendations": [
          "specific actionable recommendation 1",
          "specific actionable recommendation 2",
          "specific actionable recommendation 3"
        ],
        "budgetHealth": "Excellent|Good|Fair|Poor",
        "riskFactors": [
          "potential risk or concern if any"
        ]
      }
      
      Calculate realistic daily and weekly limits for discretionary spending.
      Allocate the discretionary budget across categories based on typical spending patterns.
      Provide 3-5 personalized, actionable recommendations.
      Assess overall budget health and identify potential risks.
      ''';
      
      final response = await generateContent(
        prompt,
        temperature: 0.4,
        maxTokens: 1536,
      );
      
      final cleanedResponse = _extractJsonFromResponse(response);
      
      try {
        final parsedData = json.decode(cleanedResponse) as Map<String, dynamic>;
        return _validateBudgetData(parsedData, income, totalExpenses, savingsGoal);
      } catch (e) {
        debugPrint('Failed to parse budget JSON: $e');
        debugPrint('Raw response: $response');
        throw GeminiException('Invalid budget response from AI', 422);
      }
    } catch (e) {
      debugPrint('Error generating budget recommendations: $e');
      rethrow;
    }
  }
  
  /// Generate spending insights and suggestions
  Future<Map<String, dynamic>> generateSpendingInsights({
    required List<Map<String, dynamic>> transactions,
    required double dailyAverage,
    required double monthlyTotal,
    DateTime? analysisDate,
  }) async {
    try {
      final date = analysisDate ?? DateTime.now();
      final transactionSummary = _formatTransactionsForAnalysis(transactions);
      
      final prompt = '''
      You are a financial analyst. Analyze the following spending data and provide insights.
      
      Analysis Date: ${date.toIso8601String().split('T')[0]}
      Daily Average (Past 30 days): ${AppConfig.formatCurrency(dailyAverage)}
      Monthly Total: ${AppConfig.formatCurrency(monthlyTotal)}
      
      Today's Transactions:
      $transactionSummary
      
      Provide analysis in this exact JSON format:
      {
        "insights": [
          "insight about spending pattern 1",
          "insight about spending pattern 2",
          "insight about spending pattern 3"
        ],
        "suggestions": [
          "actionable suggestion 1",
          "actionable suggestion 2",
          "actionable suggestion 3"
        ],
        "spendingTrend": "increasing|decreasing|stable",
        "alertLevel": "low|medium|high",
        "topCategories": [
          {
            "category": "category name",
            "amount": 0.00,
            "percentage": 0.0
          }
        ],
        "comparison": {
          "vs_daily_average": "higher|lower|similar",
          "percentage_difference": 0.0
        }
      }
      
      Focus on:
      - Spending patterns and trends
      - Category-wise analysis
      - Comparison with historical data
      - Actionable improvement suggestions
      - Alert level based on unusual spending
      ''';
      
      final response = await generateContent(
        prompt,
        temperature: 0.5,
        maxTokens: 1280,
      );
      
      final cleanedResponse = _extractJsonFromResponse(response);
      
      try {
        final parsedData = json.decode(cleanedResponse) as Map<String, dynamic>;
        return _validateInsightsData(parsedData);
      } catch (e) {
        debugPrint('Failed to parse insights JSON: $e');
        debugPrint('Raw response: $response');
        throw GeminiException('Invalid insights response from AI', 422);
      }
    } catch (e) {
      debugPrint('Error generating spending insights: $e');
      rethrow;
    }
  }
  
  /// Analyze text for recurring bill detection
  Future<Map<String, dynamic>> analyzeBillPattern({
    required String businessName,
    required List<Map<String, dynamic>> transactions,
    required List<int> dayIntervals,
  }) async {
    try {
      final transactionSummary = transactions.map((t) {
        return '${t['date']}: ${AppConfig.formatCurrency(t['amount'] as double)}';
      }).join('\n');
      
      final prompt = '''
      Analyze this transaction pattern to determine if it represents a recurring bill:
      
      Business: $businessName
      Transactions:
      $transactionSummary
      
      Day intervals between transactions: ${dayIntervals.join(', ')}
      
      Determine:
      1. Is this likely a recurring bill? (yes/no)
      2. What type of bill category is this?
      3. What frequency pattern do you detect?
      4. Confidence level (0-100)
      5. Recommended due day of month
      
      Return in this JSON format:
      {
        "isRecurring": true|false,
        "category": "Utilities|Subscription|Phone|Internet|Insurance|Rent|Other",
        "frequency": "Weekly|Biweekly|Monthly|Quarterly|Yearly",
        "confidence": 0-100,
        "recommendedDueDay": 1-31,
        "reasoning": "explanation of the analysis",
        "averageAmount": 0.00
      }
      
      Consider:
      - Consistency of amounts
      - Regularity of timing
      - Business name patterns
      - Typical billing cycles
      ''';
      
      final response = await generateContent(
        prompt,
        temperature: 0.3,
        maxTokens: 512,
      );
      
      final cleanedResponse = _extractJsonFromResponse(response);
      
      try {
        final parsedData = json.decode(cleanedResponse) as Map<String, dynamic>;
        return _validateBillAnalysisData(parsedData);
      } catch (e) {
        debugPrint('Failed to parse bill analysis JSON: $e');
        debugPrint('Raw response: $response');
        throw GeminiException('Invalid bill analysis response from AI', 422);
      }
    } catch (e) {
      debugPrint('Error analyzing bill pattern: $e');
      rethrow;
    }
  }
  
  /// Generate financial summary and advice
  Future<Map<String, dynamic>> generateFinancialSummary({
    required double totalIncome,
    required double totalExpenses,
    required double totalSavings,
    required Map<String, double> categoryBreakdown,
    required int transactionCount,
  }) async {
    try {
      final savingsRate = totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0.0;
      final expenseRatio = totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0.0;
      
      final prompt = '''
      Generate a comprehensive financial summary and advice based on this data:
      
      Financial Overview:
      - Total Income: ${AppConfig.formatCurrency(totalIncome)}
      - Total Expenses: ${AppConfig.formatCurrency(totalExpenses)}
      - Total Savings: ${AppConfig.formatCurrency(totalSavings)}
      - Savings Rate: ${savingsRate.toStringAsFixed(1)}%
      - Expense Ratio: ${expenseRatio.toStringAsFixed(1)}%
      - Number of Transactions: $transactionCount
      
      Category Breakdown:
      ${categoryBreakdown.entries.map((e) => '- ${e.key}: ${AppConfig.formatCurrency(e.value)}').join('\n')}
      
      Provide analysis in this JSON format:
      {
        "overallHealth": "Excellent|Good|Fair|Poor",
        "savingsRating": "Excellent|Good|Fair|Poor", 
        "spendingRating": "Excellent|Good|Fair|Poor",
        "summary": "brief overall financial summary",
        "achievements": [
          "positive achievement 1",
          "positive achievement 2"
        ],
        "improvements": [
          "area for improvement 1",
          "area for improvement 2",
          "area for improvement 3"
        ],
        "recommendations": [
          "specific actionable recommendation 1",
          "specific actionable recommendation 2",
          "specific actionable recommendation 3"
        ],
        "nextSteps": [
          "immediate action item 1",
          "immediate action item 2"
        ]
      }
      
      Focus on practical, actionable advice for improving financial health.
      ''';
      
      final response = await generateContent(
        prompt,
        temperature: 0.4,
        maxTokens: 1024,
      );
      
      final cleanedResponse = _extractJsonFromResponse(response);
      
      try {
        final parsedData = json.decode(cleanedResponse) as Map<String, dynamic>;
        return _validateSummaryData(parsedData);
      } catch (e) {
        debugPrint('Failed to parse summary JSON: $e');
        debugPrint('Raw response: $response');
        throw GeminiException('Invalid summary response from AI', 422);
      }
    } catch (e) {
      debugPrint('Error generating financial summary: $e');
      rethrow;
    }
  }
  
  // ========== PRIVATE HELPER METHODS ==========
  
  /// Check and enforce rate limiting
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove old requests
    _requestHistory.removeWhere((time) => time.isBefore(oneMinuteAgo));
    
    // Check if we're at the limit
    if (_requestHistory.length >= _maxRequestsPerMinute) {
      final oldestRequest = _requestHistory.first;
      final waitTime = oldestRequest.add(const Duration(minutes: 1)).difference(now);
      
      if (waitTime.inMilliseconds > 0) {
        debugPrint('Rate limit reached, waiting ${waitTime.inSeconds} seconds');
        await Future.delayed(waitTime);
      }
    }
  }
  
  /// Extract JSON from AI response, handling code blocks and extra text
  String _extractJsonFromResponse(String response) {
    // Remove markdown code blocks
    String cleaned = response
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    
    // Try to find JSON object boundaries
    final startIndex = cleaned.indexOf('{');
    final lastIndex = cleaned.lastIndexOf('}');
    
    if (startIndex != -1 && lastIndex != -1 && lastIndex > startIndex) {
      cleaned = cleaned.substring(startIndex, lastIndex + 1);
    }
    
    return cleaned;
  }
  
  /// Validate and sanitize receipt data
  Map<String, dynamic> _validateReceiptData(Map<String, dynamic> data) {
    return {
      'merchant': data['merchant']?.toString() ?? 'Unknown Merchant',
      'total': _parseDouble(data['total']) ?? 0.0,
      'date': _parseDate(data['date']) ?? DateTime.now().toIso8601String().split('T')[0],
      'category': data['category']?.toString() ?? 'Shopping',
      'items': _validateItems(data['items']),
    };
  }
  
  /// Validate and sanitize budget data
  Map<String, dynamic> _validateBudgetData(
    Map<String, dynamic> data,
    double income,
    double totalExpenses,
    double savingsGoal,
  ) {
    final discretionary = income - totalExpenses - savingsGoal;
    
    return {
      'income': _parseDouble(data['income']) ?? income,
      'totalExpenses': _parseDouble(data['totalExpenses']) ?? totalExpenses,
      'savings': _parseDouble(data['savings']) ?? savingsGoal,
      'discretionary': _parseDouble(data['discretionary']) ?? discretionary,
      'dailyLimit': _parseDouble(data['dailyLimit']) ?? (discretionary / 30),
      'weeklyLimit': _parseDouble(data['weeklyLimit']) ?? (discretionary / 4.3),
      'categoryBreakdown': _validateCategoryBreakdown(data['categoryBreakdown'], discretionary),
      'recommendations': _validateStringList(data['recommendations']),
      'budgetHealth': data['budgetHealth']?.toString() ?? 'Fair',
      'riskFactors': _validateStringList(data['riskFactors']),
    };
  }
  
  /// Validate and sanitize insights data
  Map<String, dynamic> _validateInsightsData(Map<String, dynamic> data) {
    return {
      'insights': _validateStringList(data['insights']),
      'suggestions': _validateStringList(data['suggestions']),
      'spendingTrend': data['spendingTrend']?.toString() ?? 'stable',
      'alertLevel': data['alertLevel']?.toString() ?? 'low',
      'topCategories': _validateTopCategories(data['topCategories']),
      'comparison': _validateComparison(data['comparison']),
    };
  }
  
  /// Validate and sanitize bill analysis data
  Map<String, dynamic> _validateBillAnalysisData(Map<String, dynamic> data) {
    return {
      'isRecurring': data['isRecurring'] == true,
      'category': data['category']?.toString() ?? 'Other',
      'frequency': data['frequency']?.toString() ?? 'Monthly',
      'confidence': _parseInt(data['confidence']) ?? 50,
      'recommendedDueDay': _parseInt(data['recommendedDueDay']) ?? 1,
      'reasoning': data['reasoning']?.toString() ?? '',
      'averageAmount': _parseDouble(data['averageAmount']) ?? 0.0,
    };
  }
  
  /// Validate and sanitize summary data
  Map<String, dynamic> _validateSummaryData(Map<String, dynamic> data) {
    return {
      'overallHealth': data['overallHealth']?.toString() ?? 'Fair',
      'savingsRating': data['savingsRating']?.toString() ?? 'Fair',
      'spendingRating': data['spendingRating']?.toString() ?? 'Fair',
      'summary': data['summary']?.toString() ?? 'Financial summary not available',
      'achievements': _validateStringList(data['achievements']),
      'improvements': _validateStringList(data['improvements']),
      'recommendations': _validateStringList(data['recommendations']),
      'nextSteps': _validateStringList(data['nextSteps']),
    };
  }
  
  /// Helper methods for data validation
  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  String? _parseDate(dynamic value) {
    if (value is String) {
      try {
        final date = DateTime.parse(value);
        return date.toIso8601String().split('T')[0];
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  List<Map<String, dynamic>> _validateItems(dynamic items) {
    if (items is! List) return [];
    
    return items.where((item) => item is Map).map((item) {
      final map = item as Map<String, dynamic>;
      return {
        'name': map['name']?.toString() ?? 'Unknown Item',
        'price': _parseDouble(map['price']) ?? 0.0,
        'quantity': _parseInt(map['quantity']) ?? 1,
      };
    }).toList();
  }
  
  Map<String, double> _validateCategoryBreakdown(dynamic categories, double discretionary) {
    if (categories is! Map) {
      // Return default breakdown
      return {
        'Food': discretionary * 0.3,
        'Transportation': discretionary * 0.15,
        'Entertainment': discretionary * 0.2,
        'Shopping': discretionary * 0.2,
        'Health': discretionary * 0.1,
        'Other': discretionary * 0.05,
      };
    }
    
    final result = <String, double>{};
    categories.forEach((key, value) {
      result[key.toString()] = _parseDouble(value) ?? 0.0;
    });
    
    return result;
  }
  
  List<String> _validateStringList(dynamic list) {
    if (list is! List) return [];
    return list.where((item) => item != null).map((item) => item.toString()).toList();
  }
  
  List<Map<String, dynamic>> _validateTopCategories(dynamic categories) {
    if (categories is! List) return [];
    
    return categories.where((item) => item is Map).map((item) {
      final map = item as Map<String, dynamic>;
      return {
        'category': map['category']?.toString() ?? 'Unknown',
        'amount': _parseDouble(map['amount']) ?? 0.0,
        'percentage': _parseDouble(map['percentage']) ?? 0.0,
      };
    }).toList();
  }
  
  Map<String, dynamic> _validateComparison(dynamic comparison) {
    if (comparison is! Map) {
      return {
        'vs_daily_average': 'similar',
        'percentage_difference': 0.0,
      };
    }
    
    return {
      'vs_daily_average': comparison['vs_daily_average']?.toString() ?? 'similar',
      'percentage_difference': _parseDouble(comparison['percentage_difference']) ?? 0.0,
    };
  }
  
  String _formatTransactionsForAnalysis(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) return 'No transactions';
    
    return transactions.map((t) {
      final time = t['time']?.toString() ?? 'Unknown time';
      final title = t['title']?.toString() ?? 'Unknown transaction';
      final amount = _parseDouble(t['amount']) ?? 0.0;
      final category = t['category']?.toString() ?? 'Unknown';
      
      return '$time: $title - ${AppConfig.formatCurrency(amount)} ($category)';
    }).join('\n');
  }
  
  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exception for Gemini API errors
class GeminiException implements Exception {
  final String message;
  final int statusCode;
  
  const GeminiException(this.message, this.statusCode);
  
  @override
  String toString() => 'GeminiException($statusCode): $message';
}