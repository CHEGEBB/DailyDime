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

      // Construct the prompt for Gemini
      final prompt = '''
Analyze these financial transactions and provide 5 useful insights and money-saving tips:

Transaction Data: ${json.encode(txData)}

Please provide:
1. Patterns or trends in spending
2. Budget recommendations
3. Potential savings opportunities
4. Financial habits to improve
5. Goal setting suggestions

Format your response as a list of 5 distinct insights, each a single paragraph. Make the insights actionable, specific, and relevant to Kenyan consumers.
      ''';

      // Call Gemini API
      final insights = await _callGeminiAPI(prompt);
      
      if (insights != null) {
        // Parse insights into a list
        List<String> insightsList = insights
            .split('\n\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        
        // If we don't have enough insights or the parsing didn't work well
        if (insightsList.length < 3) {
          insightsList = insights
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList();
        }
        
        // Clean up any numbering or bullet points
        insightsList = insightsList.map((s) {
          // Remove numbered bullets (1., 2., etc.)
          if (RegExp(r'^\d+\.\s').hasMatch(s)) {
            return s.replaceFirst(RegExp(r'^\d+\.\s'), '');
          }
          // Remove bullet points
          if (s.startsWith('• ') || s.startsWith('* ')) {
            return s.substring(2);
          }
          return s;
        }).toList();
        
        return {
          'success': true,
          'insights': insightsList,
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

  Future<String> generateSimpleInsight(String prompt) async {
    try {
      final result = await _callGeminiAPI(prompt);
      return result ?? 'Unable to generate insights at this time.';
    } catch (e) {
      debugPrint('Error generating simple insight: $e');
      return 'Error generating insights. Please try again.';
    }
  }

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
          }
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

  // Additional AI functions can be added as needed
}