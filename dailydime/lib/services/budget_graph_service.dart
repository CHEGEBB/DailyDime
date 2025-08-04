import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/config/app_config.dart';

class BudgetGraphService {
  static final BudgetGraphService _instance = BudgetGraphService._internal();
  
  factory BudgetGraphService() {
    return _instance;
  }
  
  BudgetGraphService._internal();

  // Cache for generated data to avoid unnecessary API calls
  final Map<String, dynamic> _cache = {};
  
  // Initialize the Gemini model
  final model = GenerativeModel(
    model: AppConfig.geminiModel,
    apiKey: AppConfig.geminiApiKey,
  );

  Future<List<BudgetCategory>> processBudgetData(List<Map<String, dynamic>> budgetDocuments) async {
    // If no budget documents exist, return empty list
    if (budgetDocuments.isEmpty) {
      print('No budget documents provided');
      return [];
    }

    try {
      List<BudgetCategory> budgetCategories = [];
      
      // Process each budget document
      for (var budget in budgetDocuments) {
        print('Processing budget: ${budget}');
        
        // Check if we have cached data for this budget
        String cacheKey = '${budget['\$id'] ?? budget['id']}_${budget['updated_at'] ?? DateTime.now().millisecondsSinceEpoch}';
        if (_cache.containsKey(cacheKey)) {
          budgetCategories.add(_cache[cacheKey]);
          continue;
        }
        
        // Extract basic budget information with null safety
        String title = budget['title']?.toString() ?? 'Unnamed Budget';
        
        // Handle total_amount - it might be null, string, or number
        double totalAmount = 0.0;
        if (budget['total_amount'] != null) {
          if (budget['total_amount'] is num) {
            totalAmount = budget['total_amount'].toDouble();
          } else if (budget['total_amount'] is String) {
            totalAmount = double.tryParse(budget['total_amount']) ?? 0.0;
          }
        }
        
        // Handle spent_amount - it might be null, string, or number
        double spentAmount = 0.0;
        if (budget['spent_amount'] != null) {
          if (budget['spent_amount'] is num) {
            spentAmount = budget['spent_amount'].toDouble();
          } else if (budget['spent_amount'] is String) {
            spentAmount = double.tryParse(budget['spent_amount']) ?? 0.0;
          }
        }
        
        // Handle categories - it might be null, string, or array
        List<String> categories = [];
        if (budget['categories'] != null) {
          if (budget['categories'] is List) {
            categories = (budget['categories'] as List).map((e) => e.toString()).toList();
          } else if (budget['categories'] is String) {
            categories = [budget['categories']];
          }
        }
        
        // Default category if none specified
        String categoryName = categories.isNotEmpty ? categories.first : title.toLowerCase();
        
        print('Budget details - Title: $title, Total: $totalAmount, Spent: $spentAmount, Categories: $categories');
        
        // Generate daily spending data based on real or AI prediction
        List<double> dailyData = await _generateDailySpendingData(
          budget: budget,
          totalAmount: totalAmount,
          spentAmount: spentAmount,
          title: title,
          categories: categories,
        );
        
        print('Generated daily data: $dailyData');
        
        // Create budget category object
        BudgetCategory budgetCategory = BudgetCategory(
          name: title,
          icon: _getCategoryIcon(categoryName),
          color: _getCategoryColor(categoryName),
          spent: spentAmount,
          budget: totalAmount,
          dailyData: dailyData,
        );
        
        // Cache the results
        _cache[cacheKey] = budgetCategory;
        
        budgetCategories.add(budgetCategory);
      }
      
      print('Successfully processed ${budgetCategories.length} budget categories');
      return budgetCategories;
    } catch (e) {
      print('Error processing budget data: $e');
      // Return fallback data in case of error
      return _generateFallbackBudgetData();
    }
  }

  Future<List<double>> _generateDailySpendingData({
    required Map<String, dynamic> budget,
    required double totalAmount,
    required double spentAmount,
    required String title,
    required List<String> categories,
  }) async {
    print('Generating daily spending data for: $title');
    
    // If we already have AI recommendations, parse them
    if (budget['ai_recommendations'] != null && budget['ai_recommendations'].toString().isNotEmpty) {
      try {
        return _parseDailyDataFromRecommendations(budget['ai_recommendations']);
      } catch (e) {
        print('Error parsing existing AI recommendations: $e');
        // Continue to generate new recommendations if parsing fails
      }
    }
    
    // If spent amount is 0, return default pattern but with 0 values
    if (spentAmount <= 0) {
      print('No spending data, returning zeros');
      return List.generate(7, (index) => 0.0);
    }
    
    try {
      // Create a context for the AI model
      final startDate = budget['start_date'] != null 
          ? (budget['start_date'] is String 
              ? DateTime.tryParse(budget['start_date']) ?? DateTime.now().subtract(Duration(days: 6))
              : DateTime.now().subtract(Duration(days: 6)))
          : DateTime.now().subtract(Duration(days: 6));
      
      final endDate = budget['end_date'] != null 
          ? (budget['end_date'] is String 
              ? DateTime.tryParse(budget['end_date']) ?? DateTime.now()
              : DateTime.now())
          : DateTime.now();
      
      final periodType = budget['period_type']?.toString() ?? 'monthly';
      final categoryText = categories.isNotEmpty ? categories.join(', ') : 'general expenses';
      
      print('AI prompt parameters - Period: $periodType, Categories: $categoryText, Spent: $spentAmount');
      
      // Generate a prompt for the AI model
      final prompt = '''
I need realistic daily spending data for a ${periodType} budget titled "${title}" for ${categoryText}.
Budget details:
- Total budget amount: KES ${totalAmount.toStringAsFixed(0)}
- Current spent amount: KES ${spentAmount.toStringAsFixed(0)}
- Budget period: ${periodType}

Create a JSON array with exactly 7 numbers representing daily spending for one week (Monday to Sunday).
Requirements:
1. The 7 values should add up to approximately ${spentAmount.toStringAsFixed(0)} (the spent amount)
2. Use realistic spending patterns (higher on weekends for entertainment, consistent for food, etc.)
3. Only return numbers without currency symbols
4. Return ONLY a JSON array with 7 numbers, nothing else
5. Make sure all numbers are positive integers or zero

Example format: [150, 200, 180, 210, 350, 420, 290]
''';

      print('Sending prompt to Gemini AI...');
      
      // Call the AI model
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text ?? '';
      
      print('AI Response: $responseText');
      
      // Extract the JSON array from the response
      final RegExp jsonArrayPattern = RegExp(r'\[\s*\d+(?:\.\d+)?(?:\s*,\s*\d+(?:\.\d+)?)*\s*\]');
      final match = jsonArrayPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonString = match.group(0)!;
        print('Extracted JSON: $jsonString');
        
        // Parse the JSON array
        final List<dynamic> jsonArray = _parseJsonArray(jsonString);
        
        // Convert to List<double>
        final List<double> dailyData = jsonArray.map((item) {
          if (item is num) {
            return item.toDouble();
          } else {
            return double.tryParse(item.toString()) ?? 0.0;
          }
        }).toList();
        
        // Make sure we have exactly 7 values
        while (dailyData.length < 7) {
          dailyData.add(0.0);
        }
        
        // Trim to exactly 7 values
        final result = dailyData.take(7).toList();
        
        // Validate that none are NaN
        for (int i = 0; i < result.length; i++) {
          if (result[i].isNaN || result[i].isInfinite) {
            result[i] = 0.0;
          }
        }
        
        print('Final daily data: $result');
        return result;
      } else {
        print('Could not extract JSON array from AI response, using fallback');
        return _generateRandomDailyData(spentAmount);
      }
    } catch (e) {
      print('Error generating daily spending data with AI: $e');
      // Fallback to random data
      return _generateRandomDailyData(spentAmount);
    }
  }
  
  List<dynamic> _parseJsonArray(String jsonString) {
    // Clean the JSON string
    final cleanedJson = jsonString.trim();
    
    try {
      // Use regex to extract all numbers from the array
      final numbers = RegExp(r'\d+(?:\.\d+)?')
          .allMatches(cleanedJson)
          .map((match) => double.parse(match.group(0)!))
          .toList();
      
      if (numbers.isEmpty) {
        throw Exception('No numbers found in JSON array');
      }
      
      return numbers;
    } catch (e) {
      print('Error parsing JSON array: $e');
      throw Exception('Failed to parse AI response: $e');
    }
  }
  
  List<double> _parseDailyDataFromRecommendations(String recommendations) {
    try {
      // Look for a pattern like [123, 456, 789, ...]
      final RegExp jsonArrayPattern = RegExp(r'\[\s*\d+(?:\.\d+)?(?:\s*,\s*\d+(?:\.\d+)?)*\s*\]');
      final match = jsonArrayPattern.firstMatch(recommendations);
      
      if (match != null) {
        final jsonString = match.group(0)!;
        final List<dynamic> jsonArray = _parseJsonArray(jsonString);
        final result = jsonArray.map((item) => double.tryParse(item.toString()) ?? 0.0).toList();
        
        // Validate no NaN values
        for (int i = 0; i < result.length; i++) {
          if (result[i].isNaN || result[i].isInfinite) {
            result[i] = 0.0;
          }
        }
        
        return result;
      }
      throw Exception('No daily data found in recommendations');
    } catch (e) {
      print('Error parsing recommendations: $e');
      throw e;
    }
  }
  
  List<double> _generateRandomDailyData(double totalSpent) {
    print('Generating random daily data for total spent: $totalSpent');
    
    if (totalSpent <= 0) {
      return List.generate(7, (_) => 0.0);
    }
    
    final random = math.Random();
    List<double> dailyData = List.generate(7, (_) => 0.0);
    
    // Create a realistic distribution with higher spending on weekends
    final weekdayWeight = 0.12; // 12% for weekdays
    final weekendWeight = 0.20; // 20% for weekends
    final weights = [
      weekdayWeight, // Monday
      weekdayWeight, // Tuesday
      weekdayWeight, // Wednesday
      weekdayWeight, // Thursday
      weekdayWeight, // Friday
      weekendWeight, // Saturday
      weekendWeight, // Sunday
    ];
    
    // Normalize weights to ensure they sum to 1
    final totalWeight = weights.reduce((a, b) => a + b);
    final normalizedWeights = weights.map((w) => w / totalWeight).toList();
    
    // Calculate base values based on weights
    for (int i = 0; i < 7; i++) {
      dailyData[i] = totalSpent * normalizedWeights[i];
    }
    
    // Add some randomness (±30% variation)
    for (int i = 0; i < 7; i++) {
      final variation = 0.7 + random.nextDouble() * 0.6; // 70%-130% of base value
      dailyData[i] *= variation;
    }
    
    // Ensure the sum matches the total spent amount
    final sum = dailyData.reduce((a, b) => a + b);
    if (sum > 0) {
      final adjustmentFactor = totalSpent / sum;
      for (int i = 0; i < dailyData.length; i++) {
        dailyData[i] *= adjustmentFactor;
        
        // Ensure no NaN or infinite values
        if (dailyData[i].isNaN || dailyData[i].isInfinite) {
          dailyData[i] = 0.0;
        }
      }
    }
    
    print('Generated random daily data: $dailyData');
    return dailyData;
  }
  
  List<BudgetCategory> _generateFallbackBudgetData() {
    print('Using fallback budget data');
    return [
      BudgetCategory(
        name: 'Food & Dining',
        icon: Icons.restaurant,
        color: Colors.orange,
        spent: 12500,
        budget: 15000,
        dailyData: [1500, 1800, 1650, 2200, 2500, 1900, 950],
      ),
      BudgetCategory(
        name: 'Transportation',
        icon: Icons.directions_car,
        color: Colors.blue,
        spent: 8000,
        budget: 10000,
        dailyData: [1200, 1300, 1000, 1100, 1500, 1200, 700],
      ),
    ];
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
      case 'food & dining':
      case 'comrade special💗': // Handle your specific category
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
      case 'utilities':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'transfer':
        return Icons.swap_horiz;
      case 'income':
        return Icons.work;
      case 'groceries':
        return Icons.shopping_cart;
      case 'housing':
      case 'rent':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
      case 'food & dining':
      case 'comrade special💗': // Handle your specific category
        return Colors.orange;
      case 'transport':
      case 'transportation':
        return Colors.blue;
      case 'shopping':
        return Colors.teal;
      case 'bills':
      case 'utilities':
        return Colors.red;
      case 'entertainment':
        return Colors.purple;
      case 'health':
        return Colors.pink;
      case 'education':
        return Colors.indigo;
      case 'travel':
        return Colors.amber;
      case 'transfer':
        return Colors.green;
      case 'income':
        return Colors.green;
      case 'groceries':
        return Colors.lightGreen;
      case 'housing':
      case 'rent':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

class BudgetCategory {
  final String name;
  final IconData icon;
  final Color color;
  final double spent;
  final double budget;
  final List<double> dailyData;

  BudgetCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.spent,
    required this.budget,
    required this.dailyData,
  });
}