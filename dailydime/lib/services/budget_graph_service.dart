import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

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
      return [];
    }

    try {
      List<BudgetCategory> budgetCategories = [];
      
      // Process each budget document
      for (var budget in budgetDocuments) {
        // Check if we have cached data for this budget
        String cacheKey = '${budget['id']}_${budget['updated_at']}';
        if (_cache.containsKey(cacheKey)) {
          budgetCategories.add(_cache[cacheKey]);
          continue;
        }
        
        // Extract basic budget information
        String title = budget['title'] ?? 'Unnamed Budget';
        double totalAmount = (budget['total_amount'] ?? 0).toDouble();
        double spentAmount = (budget['spent_amount'] ?? 0).toDouble();
        List<dynamic> categories = budget['categories'] ?? [];
        
        // Default category if none specified
        String categoryName = categories.isNotEmpty ? categories.first : 'General';
        
        // Generate daily spending data based on real or AI prediction
        List<double> dailyData = await _generateDailySpendingData(
          budget: budget,
          totalAmount: totalAmount,
          spentAmount: spentAmount,
        );
        
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
  }) async {
    // If we already have AI recommendations, parse them
    if (budget['ai_recommendations'] != null && budget['ai_recommendations'].toString().isNotEmpty) {
      try {
        // Try to parse existing AI recommendations
        return _parseDailyDataFromRecommendations(budget['ai_recommendations']);
      } catch (e) {
        print('Error parsing existing AI recommendations: $e');
        // Continue to generate new recommendations if parsing fails
      }
    }
    
    try {
      // Create a context for the AI model
      final startDate = budget['start_date'] != null 
          ? DateTime.parse(budget['start_date']) 
          : DateTime.now().subtract(Duration(days: 6));
      
      final endDate = budget['end_date'] != null 
          ? DateTime.parse(budget['end_date']) 
          : DateTime.now();
      
      final periodType = budget['period_type'] ?? 'weekly';
      final title = budget['title'] ?? 'Budget';
      final categories = budget['categories'] ?? [];
      final categoryText = categories.isNotEmpty ? categories.join(', ') : 'general expenses';
      
      // Calculate the budget duration
      final budgetDuration = endDate.difference(startDate).inDays + 1;
      
      // Generate a prompt for the AI model
      final prompt = '''
I need realistic daily spending data for a ${periodType} budget titled "${title}" for ${categoryText}.
Total budget amount: ${AppConfig.formatCurrency(totalAmount)}
Current spent amount: ${AppConfig.formatCurrency(spentAmount)}
Budget start date: ${DateFormat('yyyy-MM-dd').format(startDate)}
Budget end date: ${DateFormat('yyyy-MM-dd').format(endDate)}

Create a JSON array with 7 values representing daily spending for the most recent week (Monday to Sunday).
The values should:
1. Add up to approximately the spent amount of ${AppConfig.formatCurrency(spentAmount)}
2. Follow realistic spending patterns (higher on weekends, etc.)
3. Only include numbers without currency symbols
4. Be returned as a JSON array, nothing else

Example response: [150, 200, 180, 210, 350, 420, 290]
''';

      // Call the AI model
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text ?? '';
      
      // Extract the JSON array from the response
      final RegExp jsonArrayPattern = RegExp(r'\[\s*\d+(?:\s*,\s*\d+)*\s*\]');
      final match = jsonArrayPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonString = match.group(0)!;
        // Parse the JSON array
        final List<dynamic> jsonArray = _parseJsonArray(jsonString);
        
        // Convert to List<double>
        final List<double> dailyData = jsonArray.map((item) => double.parse(item.toString())).toList();
        
        // Make sure we have exactly 7 values
        while (dailyData.length < 7) {
          dailyData.add(0);
        }
        
        return dailyData.take(7).toList();
      } else {
        // Fallback if we couldn't extract a JSON array
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
    
    // Try to parse the JSON array
    try {
      return RegExp(r'\d+')
          .allMatches(cleanedJson)
          .map((match) => int.parse(match.group(0)!))
          .toList();
    } catch (e) {
      print('Error parsing JSON array: $e');
      throw Exception('Failed to parse AI response');
    }
  }
  
  List<double> _parseDailyDataFromRecommendations(String recommendations) {
    try {
      // Look for a pattern like [123, 456, 789, ...]
      final RegExp jsonArrayPattern = RegExp(r'\[\s*\d+(?:\s*,\s*\d+)*\s*\]');
      final match = jsonArrayPattern.firstMatch(recommendations);
      
      if (match != null) {
        final jsonString = match.group(0)!;
        final List<dynamic> jsonArray = _parseJsonArray(jsonString);
        return jsonArray.map((item) => double.parse(item.toString())).toList();
      }
      throw Exception('No daily data found in recommendations');
    } catch (e) {
      print('Error parsing recommendations: $e');
      throw e;
    }
  }
  
  List<double> _generateRandomDailyData(double totalSpent) {
    final random = math.Random();
    List<double> dailyData = List.generate(7, (_) => 0.0);
    
    // Create a realistic distribution with higher spending on weekends
    final weekdayWeight = 0.1;
    final weekendWeight = 0.25;
    final weights = [
      weekdayWeight, // Monday
      weekdayWeight, // Tuesday
      weekdayWeight, // Wednesday
      weekdayWeight, // Thursday
      weekdayWeight, // Friday
      weekendWeight, // Saturday
      weekendWeight, // Sunday
    ];
    
    // Normalize weights
    final totalWeight = weights.reduce((a, b) => a + b);
    final normalizedWeights = weights.map((w) => w / totalWeight).toList();
    
    // Calculate base values based on weights
    for (int i = 0; i < 7; i++) {
      dailyData[i] = totalSpent * normalizedWeights[i];
    }
    
    // Add some randomness
    for (int i = 0; i < 7; i++) {
      dailyData[i] *= 0.7 + random.nextDouble() * 0.6; // 70%-130% of base value
    }
    
    // Make sure the sum is close to totalSpent
    final sum = dailyData.reduce((a, b) => a + b);
    final adjustmentFactor = totalSpent / sum;
    
    return dailyData.map((value) => (value * adjustmentFactor)).toList();
  }
  
  List<BudgetCategory> _generateFallbackBudgetData() {
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