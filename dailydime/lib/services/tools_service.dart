// lib/services/tools_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/gemini_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ToolsService extends ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();
  final StorageService _storageService = StorageService.instance;
  final SmsService _smsService = SmsService();
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final Uuid _uuid = const Uuid();
  
  // Track whether the service is initialized
  bool _isInitialized = false;
  
  // Cached data
  List<Map<String, dynamic>> _recurringBills = [];
  List<Map<String, dynamic>> _suggestedBills = [];
  
  // Recurring bill detection threshold (days)
  static const int _recurringThreshold = 90;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _storageService.initialize();
      await _smsService.initialize();
      
      // Check for necessary permissions
      await _checkPermissions();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing ToolsService: $e');
      rethrow;
    }
  }
  
  // Check and request necessary permissions
  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
    
    final storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }
    
    final smsStatus = await Permission.sms.status;
    if (!smsStatus.isGranted) {
      await Permission.sms.request();
    }
  }
  
  // =========== OCR RECEIPT SCANNER ===========
  
  // Scan a receipt using the camera
  Future<Map<String, dynamic>> scanReceipt() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (pickedImage == null) {
        throw Exception('No image selected');
      }
      
      // Compress the image to reduce processing time
      final compressedImage = await _compressImage(File(pickedImage.path));
      
      // Process the receipt
      return _processReceiptImage(compressedImage);
    } catch (e) {
      debugPrint('Error scanning receipt: $e');
      rethrow;
    }
  }
  
  // Scan a receipt from the gallery
  Future<Map<String, dynamic>> scanReceiptFromGallery() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (pickedImage == null) {
        throw Exception('No image selected');
      }
      
      // Compress the image to reduce processing time
      final compressedImage = await _compressImage(File(pickedImage.path));
      
      // Process the receipt
      return _processReceiptImage(compressedImage);
    } catch (e) {
      debugPrint('Error scanning receipt from gallery: $e');
      rethrow;
    }
  }
  
  // Compress the image to improve processing speed
  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70,
        minWidth: 1000,
        minHeight: 1000,
      );
      
      return File(result?.path ?? file.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }
  
  // Process the receipt image using OCR and AI
  Future<Map<String, dynamic>> _processReceiptImage(File imageFile) async {
    try {
      // Perform OCR on the image
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        throw Exception('No text recognized in the image');
      }
      
      // Use Gemini to extract structured data from the OCR text
      final prompt = '''
      Extract the following information from this receipt text:
      1. Merchant/store name
      2. Total amount (number only)
      3. Date of purchase (in format MM/DD/YYYY if possible)
      4. Category of purchase (like Food, Grocery, Shopping, etc.)
      5. List of items purchased with prices if available

      Format the response as a JSON object with keys: merchant, total, date, category, items.
      The 'items' should be an array of objects with 'name', 'price', and 'quantity' if available.

      Receipt text:
      $recognizedText
      ''';
      
      final extractedData = await _geminiService.generateContent(prompt);
      
      // Parse the JSON response
      Map<String, dynamic> parsedData;
      try {
        // Try to extract JSON from the text - handle potential text wrapping
        final jsonString = extractedData.replaceAll('```json', '').replaceAll('```', '').trim();
        parsedData = json.decode(jsonString);
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        debugPrint('Raw response: $extractedData');
        
        // Fallback to regex extraction
        parsedData = _extractReceiptDataWithRegex(recognizedText.text);
      }
      
      // Process the date
      if (parsedData['date'] != null) {
        try {
          // Handle various date formats
          final dateString = parsedData['date'].toString();
          DateTime? parsedDate;
          
          // Try common formats
          final dateFormats = [
            'MM/dd/yyyy',
            'M/d/yyyy',
            'yyyy-MM-dd',
            'dd/MM/yyyy',
            'dd-MM-yyyy',
            'yyyy/MM/dd',
            'MM-dd-yyyy',
          ];
          
          for (final format in dateFormats) {
            try {
              parsedDate = DateFormat(format).parse(dateString);
              break;
            } catch (e) {
              // Try next format
            }
          }
          
          // If no format worked, try to find just year, month, day
          if (parsedDate == null) {
            final yearMatch = RegExp(r'20[0-9]{2}').firstMatch(dateString);
            final monthMatch = RegExp(r'([0-9]{1,2})').firstMatch(dateString);
            final dayMatch = RegExp(r'([0-9]{1,2})').allMatches(dateString).elementAt(1);
            
            if (yearMatch != null && monthMatch != null && dayMatch != null) {
              final year = int.parse(yearMatch.group(0)!);
              final month = int.parse(monthMatch.group(0)!);
              final day = int.parse(dayMatch.group(0)!);
              
              if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                parsedDate = DateTime(year, month, day);
              }
            }
          }
          
          // If still no date, use today
          parsedData['date'] = parsedDate ?? DateTime.now();
        } catch (e) {
          debugPrint('Error parsing date: $e');
          parsedData['date'] = DateTime.now();
        }
      } else {
        parsedData['date'] = DateTime.now();
      }
      
      // Normalize total amount
      if (parsedData['total'] != null) {
        if (parsedData['total'] is String) {
          // Remove currency symbols and commas
          final amountString = parsedData['total']
              .toString()
              .replaceAll(RegExp(r'[^\d.]'), '')
              .trim();
          
          parsedData['total'] = double.tryParse(amountString) ?? 0.0;
        }
      }
      
      // Normalize category
      if (parsedData['category'] == null || parsedData['category'].toString().isEmpty) {
        parsedData['category'] = _inferCategory(
          parsedData['merchant']?.toString() ?? '',
          parsedData['items'] as List<dynamic>? ?? [],
        );
      }
      
      // Ensure items is an array
      if (parsedData['items'] == null) {
        parsedData['items'] = [];
      }
      
      return parsedData;
    } catch (e) {
      debugPrint('Error processing receipt: $e');
      rethrow;
    }
  }
  
  // Fallback method to extract receipt data using regex patterns
  Map<String, dynamic> _extractReceiptDataWithRegex(String text) {
    final result = <String, dynamic>{};
    
    // Extract merchant/store name (usually in the first few lines)
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      result['merchant'] = lines.first.trim();
    }
    
    // Extract total amount (look for patterns like "TOTAL", "AMOUNT", "$")
    final totalRegex = RegExp(r'(?:total|amount|sum).*?(\d+[\.,]\d{2})', caseSensitive: false);
    final totalMatch = totalRegex.firstMatch(text);
    if (totalMatch != null && totalMatch.groupCount >= 1) {
      final totalString = totalMatch.group(1)?.replaceAll(',', '.') ?? '0.0';
      result['total'] = double.tryParse(totalString) ?? 0.0;
    } else {
      // Try another pattern with currency symbols
      final currencyRegex = RegExp(r'(?:\$|Ksh|€|£).*?(\d+[\.,]\d{2})', caseSensitive: false);
      final currencyMatch = currencyRegex.firstMatch(text);
      if (currencyMatch != null && currencyMatch.groupCount >= 1) {
        final totalString = currencyMatch.group(1)?.replaceAll(',', '.') ?? '0.0';
        result['total'] = double.tryParse(totalString) ?? 0.0;
      } else {
        result['total'] = 0.0;
      }
    }
    
    // Extract date (common formats)
    final dateRegex = RegExp(
      r'(?:\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})|(?:\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})',
    );
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      result['date'] = dateMatch.group(0) ?? DateTime.now().toString();
    } else {
      result['date'] = DateTime.now().toString();
    }
    
    // Set default category
    result['category'] = 'Shopping';
    
    // Try to extract items (lines with prices)
    final itemRegex = RegExp(r'(.*?)\s+(\d+[\.,]\d{2})', caseSensitive: false);
    final itemMatches = itemRegex.allMatches(text);
    
    final items = <Map<String, dynamic>>[];
    for (final match in itemMatches) {
      if (match.groupCount >= 2) {
        final name = match.group(1)?.trim() ?? 'Unknown item';
        final priceString = match.group(2)?.replaceAll(',', '.') ?? '0.0';
        final price = double.tryParse(priceString) ?? 0.0;
        
        // Skip if it looks like a total or subtotal line
        if (name.toLowerCase().contains('total') || 
            name.toLowerCase().contains('subtotal') ||
            name.toLowerCase().contains('tax') ||
            name.toLowerCase().contains('amount')) {
          continue;
        }
        
        items.add({
          'name': name,
          'price': price,
          'quantity': 1,
        });
      }
    }
    
    result['items'] = items;
    
    return result;
  }
  
  // Infer the category based on merchant name and items
  String _inferCategory(String merchant, List<dynamic> items) {
    merchant = merchant.toLowerCase();
    
    // Check for common merchant categories
    if (merchant.contains('restaurant') || 
        merchant.contains('cafe') || 
        merchant.contains('pizza') ||
        merchant.contains('burger') ||
        merchant.contains('food') ||
        merchant.contains('kitchen')) {
      return 'Food';
    }
    
    if (merchant.contains('market') || 
        merchant.contains('grocery') || 
        merchant.contains('supermarket') ||
        merchant.contains('shop') ||
        merchant.contains('store')) {
      return 'Grocery';
    }
    
    if (merchant.contains('gas') || 
        merchant.contains('petrol') || 
        merchant.contains('fuel')) {
      return 'Transport';
    }
    
    if (merchant.contains('pharmacy') || 
        merchant.contains('drug') || 
        merchant.contains('health') ||
        merchant.contains('clinic') ||
        merchant.contains('hospital')) {
      return 'Health';
    }
    
    if (merchant.contains('cinema') || 
        merchant.contains('movie') || 
        merchant.contains('entertainment') ||
        merchant.contains('theater')) {
      return 'Entertainment';
    }
    
    // Check item list for clues
    final itemNames = items
        .map((item) => item['name']?.toString().toLowerCase() ?? '')
        .join(' ');
    
    if (itemNames.contains('food') || 
        itemNames.contains('meal') || 
        itemNames.contains('burger') ||
        itemNames.contains('pizza')) {
      return 'Food';
    }
    
    if (itemNames.contains('grocery') || 
        itemNames.contains('vegetable') || 
        itemNames.contains('fruit') ||
        itemNames.contains('milk') ||
        itemNames.contains('bread')) {
      return 'Grocery';
    }
    
    // Default to Shopping as a fallback
    return 'Shopping';
  }
  
  // Save the scanned receipt as a transaction
  Future<void> saveScannedReceipt(Map<String, dynamic> receiptData) async {
    try {
      final merchant = receiptData['merchant'] ?? 'Unknown Merchant';
      final amount = receiptData['total'] ?? 0.0;
      final date = receiptData['date'] as DateTime? ?? DateTime.now();
      final category = receiptData['category'] ?? 'Shopping';
      
      // Create a transaction object
      final transaction = Transaction(
        id: _uuid.v4(),
        title: 'Purchase at $merchant',
        amount: amount,
        date: date,
        category: category,
        isExpense: true,
        icon: Icons.receipt,
        color: Colors.blue.shade700,
        isSms: false,
        rawSms: json.encode(receiptData),
        business: merchant,
      );
      
      // Save locally
      await _storageService.saveTransaction(transaction);
      
      // Sync with Appwrite
      await _appwriteService.syncTransaction(transaction);
      
      // Notify listeners
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving scanned receipt: $e');
      rethrow;
    }
  }
  
  // =========== SMART BUDGET CALCULATOR ===========
  
  // Calculate budget based on income, expenses, and savings goal
  Future<Map<String, dynamic>> calculateBudget({
    required double income,
    required List<Map<String, dynamic>> expenses,
    double savingsGoal = 0.0,
  }) async {
    try {
      // Calculate total expenses
      double totalExpenses = 0.0;
      for (final expense in expenses) {
        totalExpenses += expense['amount'] as double;
      }
      
      // Prepare prompt for Gemini
      final prompt = '''
      Create a comprehensive budget plan based on the following information:
      - Monthly income: ${AppConfig.formatCurrency(income)}
      - Monthly fixed expenses: ${AppConfig.formatCurrency(totalExpenses)}
      - Desired monthly savings: ${AppConfig.formatCurrency(savingsGoal)}
      
      Fixed expenses breakdown:
      ${expenses.map((e) => '- ${e['name']}: ${AppConfig.formatCurrency(e['amount'] as double)}').join('\n')}
      
      Please provide:
      1. Amount available for discretionary spending
      2. Recommended daily spending limit
      3. Recommended weekly spending limit
      4. Suggested breakdown by category (what percentage of discretionary spending should go to Food, Transportation, Entertainment, etc.)
      5. At least 3 personalized budget recommendations or tips
      
      Format your response as a JSON object with the following structure:
      {
        "income": [total income],
        "totalExpenses": [total fixed expenses],
        "savings": [recommended savings amount],
        "discretionary": [discretionary spending amount],
        "dailyLimit": [daily spending limit],
        "weeklyLimit": [weekly spending limit],
        "categoryBreakdown": {
          "Food": [amount],
          "Transportation": [amount],
          "Entertainment": [amount],
          "Shopping": [amount],
          "Other": [amount]
        },
        "recommendations": [
          "recommendation 1",
          "recommendation 2",
          "recommendation 3"
        ]
      }
      ''';
      
      // Get budget recommendations from Gemini
      final response = await _geminiService.generateContent(prompt);
      
      // Parse the JSON response
      Map<String, dynamic> parsedData;
      try {
        // Try to extract JSON from the text - handle potential text wrapping
        final jsonString = response.replaceAll('```json', '').replaceAll('```', '').trim();
        parsedData = json.decode(jsonString);
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        debugPrint('Raw response: $response');
        
        // Fallback to a basic budget calculation
        final discretionary = income - totalExpenses - savingsGoal;
        final dailyLimit = discretionary / 30;
        final weeklyLimit = discretionary / 4.3;
        
        parsedData = {
          'income': income,
          'totalExpenses': totalExpenses,
          'savings': savingsGoal,
          'discretionary': discretionary,
          'dailyLimit': dailyLimit,
          'weeklyLimit': weeklyLimit,
          'categoryBreakdown': {
            'Food': discretionary * 0.3,
            'Transportation': discretionary * 0.15,
            'Entertainment': discretionary * 0.2,
            'Shopping': discretionary * 0.2,
            'Other': discretionary * 0.15,
          },
          'recommendations': [
            'Try to keep your daily spending under ${AppConfig.formatCurrency(dailyLimit)}',
            'Focus on essential expenses and reduce discretionary spending',
            'Track your expenses daily to stay within your budget',
          ],
        };
      }
      
      // Ensure all required fields are present
      return {
        'income': parsedData['income'] ?? income,
        'totalExpenses': parsedData['totalExpenses'] ?? totalExpenses,
        'savings': parsedData['savings'] ?? savingsGoal,
        'discretionary': parsedData['discretionary'] ?? (income - totalExpenses - savingsGoal),
        'dailyLimit': parsedData['dailyLimit'] ?? ((income - totalExpenses - savingsGoal) / 30),
        'weeklyLimit': parsedData['weeklyLimit'] ?? ((income - totalExpenses - savingsGoal) / 4.3),
        'categoryBreakdown': parsedData['categoryBreakdown'] ?? {
          'Food': (income - totalExpenses - savingsGoal) * 0.3,
          'Transportation': (income - totalExpenses - savingsGoal) * 0.15,
          'Entertainment': (income - totalExpenses - savingsGoal) * 0.2,
          'Shopping': (income - totalExpenses - savingsGoal) * 0.2,
          'Other': (income - totalExpenses - savingsGoal) * 0.15,
        },
        'recommendations': parsedData['recommendations'] ?? [
          'Try to keep your daily spending under ${AppConfig.formatCurrency((income - totalExpenses - savingsGoal) / 30)}',
          'Focus on essential expenses and reduce discretionary spending',
          'Track your expenses daily to stay within your budget',
        ],
      };
    } catch (e) {
      debugPrint('Error calculating budget: $e');
      rethrow;
    }
  }
  
  // Save the budget recommendation to Appwrite
  Future<void> saveBudgetRecommendation(Map<String, dynamic> budgetData) async {
    try {
      await _appwriteService.createOrUpdateBudget({
        'total_amount': budgetData['income'],
        'spent': 0,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'categories': budgetData['categoryBreakdown'],
        'daily_limit': budgetData['dailyLimit'],
        'weekly_limit': budgetData['weeklyLimit'],
        'name': 'Monthly Budget',
        'notes': 'Created with Smart Budget Calculator',
        'recommendations': budgetData['recommendations'],
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving budget recommendation: $e');
      rethrow;
    }
  }
  
  // =========== DAILY SPENDING REPORT ===========
  
  // Generate a daily spending report based on SMS transactions
  Future<Map<String, dynamic>> generateDailySpendingReport({DateTime? date}) async {
    try {
      final reportDate = date ?? DateTime.now();
      final startOfDay = DateTime(reportDate.year, reportDate.month, reportDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Get transactions for the day
      final dailyTransactions = await _getTransactionsForDateRange(startOfDay, endOfDay);
      
      if (dailyTransactions.isEmpty) {
        // No transactions for the day
        return {
          'totalSpent': 0.0,
          'transactions': [],
          'categories': {},
          'insights': ['No transactions found for this day.'],
          'suggestions': ['Try adding manual transactions if you made any purchases.'],
        };
      }
      
      // Calculate total spent
      double totalSpent = 0.0;
      for (final transaction in dailyTransactions) {
        if (transaction.isExpense) {
          totalSpent += transaction.amount;
        }
      }
      
      // Group by category
      final categoryMap = <String, double>{};
      for (final transaction in dailyTransactions) {
        if (transaction.isExpense) {
          final category = transaction.category;
          categoryMap[category] = (categoryMap[category] ?? 0.0) + transaction.amount;
        }
      }
      
      // Format transactions for the report
      final formattedTransactions = dailyTransactions.map((transaction) {
        return {
          'id': transaction.id,
          'title': transaction.title,
          'amount': transaction.amount,
          'time': DateFormat('h:mm a').format(transaction.date),
          'category': transaction.category,
          'isExpense': transaction.isExpense,
        };
      }).toList();
      
      // Use Gemini to generate insights and suggestions
      final insights = await _generateDailyInsights(dailyTransactions);
      
      return {
        'totalSpent': totalSpent,
        'transactions': formattedTransactions,
        'categories': categoryMap,
        'insights': insights['insights'],
        'suggestions': insights['suggestions'],
      };
    } catch (e) {
      debugPrint('Error generating daily spending report: $e');
      rethrow;
    }
  }
  
  // Get transactions for a specific date range
  Future<List<Transaction>> _getTransactionsForDateRange(DateTime start, DateTime end) async {
    try {
      // Get transactions from local storage
      final localTransactions = await _storageService.getTransactions();
      
      // Filter transactions by date range
      return localTransactions.where((transaction) {
        return transaction.date.isAfter(start) && transaction.date.isBefore(end);
      }).toList();
    } catch (e) {
      debugPrint('Error getting transactions for date range: $e');
      return [];
    }
  }
  
  // Generate insights and suggestions for daily spending
  Future<Map<String, List<String>>> _generateDailyInsights(List<Transaction> transactions) async {
    try {
      // Format transactions for Gemini
      final transactionsText = transactions.map((t) {
        return '- ${t.title}: ${AppConfig.formatCurrency(t.amount)} (${t.category}, ${t.isExpense ? 'expense' : 'income'})';
      }).join('\n');
      
      // Calculate total spent and income
      double totalSpent = 0.0;
      double totalIncome = 0.0;
      for (final transaction in transactions) {
        if (transaction.isExpense) {
          totalSpent += transaction.amount;
        } else {
          totalIncome += transaction.amount;
        }
      }
      
      // Get monthly average spending (from the past 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final monthTransactions = await _getTransactionsForDateRange(thirtyDaysAgo, now);
      
      double monthlySpent = 0.0;
      for (final transaction in monthTransactions) {
        if (transaction.isExpense) {
          monthlySpent += transaction.amount;
        }
      }
      
      final dailyAverage = monthlySpent / 30;
      
      // Prepare prompt for Gemini
      final prompt = '''
      Analyze the following transactions for a single day and provide insights and suggestions:
      
      Transactions:
      $transactionsText
      
      Total spent today: ${AppConfig.formatCurrency(totalSpent)}
      Total income today: ${AppConfig.formatCurrency(totalIncome)}
      
      Daily average spending (past 30 days): ${AppConfig.formatCurrency(dailyAverage)}
      
      Please provide:
      1. 2-3 insights about the day's spending patterns
      2. 2-3 actionable suggestions to improve financial habits
      
      Format your response as a JSON object with two arrays: "insights" and "suggestions".
      ''';
      
      // Get insights from Gemini
      final response = await _geminiService.generateContent(prompt);
      
      // Parse the JSON response
      Map<String, dynamic> parsedData;
      try {
        // Try to extract JSON from the text - handle potential text wrapping
        final jsonString = response.replaceAll('```json', '').replaceAll('```', '').trim();
        parsedData = json.decode(jsonString);
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        debugPrint('Raw response: $response');
        
        // Fallback to basic insights
        return {
          'insights': [
            'You spent ${AppConfig.formatCurrency(totalSpent)} today.',
            totalSpent > dailyAverage 
                ? 'This is higher than your daily average of ${AppConfig.formatCurrency(dailyAverage)}.'
                : 'This is lower than your daily average of ${AppConfig.formatCurrency(dailyAverage)}.',
          ],
          'suggestions': [
            'Try to keep your daily spending consistent to stay within your monthly budget.',
            'Consider setting up automatic savings to build your emergency fund.',
          ],
        };
      }
      
      return {
        'insights': List<String>.from(parsedData['insights'] ?? []),
        'suggestions': List<String>.from(parsedData['suggestions'] ?? []),
      };
    } catch (e) {
      debugPrint('Error generating daily insights: $e');
      return {
        'insights': ['Could not generate insights for today\'s spending.'],
        'suggestions': ['Track your expenses regularly to gain better insights.'],
      };
    }
  }
  
  // Export the daily report as a shareable text
  Future<void> exportDailyReport(Map<String, dynamic> reportData) async {
    try {
      final totalSpent = reportData['totalSpent'] ?? 0.0;
      final transactions = reportData['transactions'] as List<dynamic>? ?? [];
      final categories = reportData['categories'] as Map<String, dynamic>? ?? {};
      final insights = reportData['insights'] as List<dynamic>? ?? [];
      final suggestions = reportData['suggestions'] as List<dynamic>? ?? [];
      
      final formattedDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
      
      // Format the report text
      final reportText = StringBuffer();
      reportText.writeln('📊 Daily Spending Report - $formattedDate');
      reportText.writeln('');
      reportText.writeln('💰 Total Spent: ${AppConfig.formatCurrency(totalSpent)}');
      reportText.writeln('🧾 Transactions: ${transactions.length}');
      reportText.writeln('');
      
      // Categories
      reportText.writeln('📋 Spending by Category:');
      categories.forEach((category, amount) {
        reportText.writeln('- $category: ${AppConfig.formatCurrency(amount as double)}');
      });
      reportText.writeln('');
      
      // Insights
      reportText.writeln('💡 Insights:');
      for (final insight in insights) {
        reportText.writeln('- $insight');
      }
      reportText.writeln('');
      
      // Suggestions
      reportText.writeln('✅ Suggestions:');
      for (final suggestion in suggestions) {
        reportText.writeln('- $suggestion');
      }
      reportText.writeln('');
      reportText.writeln('Generated by DailyDime');
      
      // Share the report
      await Share.share(reportText.toString(), subject: 'Daily Spending Report');
    } catch (e) {
      debugPrint('Error exporting daily report: $e');
      rethrow;
    }
  }
  
  // =========== RECURRING BILLS MANAGER ===========
  
  // Get all recurring bills
  Future<List<Map<String, dynamic>>> getRecurringBills() async {
    try {
      if (_recurringBills.isNotEmpty) {
        return _recurringBills;
      }
      
      // Get bills from Appwrite
      final billsDocuments = await _appwriteService.getRecurringBills();
      
      // Format the bills
      _recurringBills = billsDocuments.map((doc) {
        return {
          'id': doc.$id,
          'name': doc.data['name'],
          'amount': doc.data['amount'],
          'frequency': doc.data['frequency'],
          'dueDay': doc.data['dueDay'],
          'category': doc.data['category'],
          'paymentMethod': doc.data['paymentMethod'],
          'reminderEnabled': doc.data['reminderEnabled'] ?? true,
          'notes': doc.data['notes'],
        };
      }).toList();
      
      notifyListeners();
      return _recurringBills;
    } catch (e) {
      debugPrint('Error getting recurring bills: $e');
      return [];
    }
  }
  
  // Get suggested recurring bills based on SMS analysis
  Future<List<Map<String, dynamic>>> getSuggestedRecurringBills() async {
    try {
      if (_suggestedBills.isNotEmpty) {
        return _suggestedBills;
      }
      
      // This would typically be populated by detectRecurringBills()
      return _suggestedBills;
    } catch (e) {
      debugPrint('Error getting suggested bills: $e');
      return [];
    }
  }
  
  // Get upcoming bills for the next 30 days
  Future<List<Map<String, dynamic>>> getUpcomingBills() async {
    try {
      final bills = await getRecurringBills();
      final upcomingBills = <Map<String, dynamic>>[];
      final now = DateTime.now();
      
      for (final bill in bills) {
        final frequency = bill['frequency'] as String;
        final dueDay = bill['dueDay'] as int;
        
        // Calculate next due date based on frequency
        DateTime nextDueDate;
        
        switch (frequency.toLowerCase()) {
          case 'daily':
            nextDueDate = now.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextDueDate = now.add(const Duration(days: 7));
            break;
          case 'biweekly':
            nextDueDate = now.add(const Duration(days: 14));
            break;
          case 'monthly':
            nextDueDate = DateTime(now.year, now.month, dueDay);
            if (nextDueDate.isBefore(now)) {
              nextDueDate = DateTime(now.year, now.month + 1, dueDay);
            }
            break;
          case 'quarterly':
            nextDueDate = DateTime(now.year, now.month + 3, dueDay);
            break;
          case 'yearly':
            nextDueDate = DateTime(now.year + 1, now.month, dueDay);
            break;
          default:
            nextDueDate = DateTime(now.year, now.month, dueDay);
            if (nextDueDate.isBefore(now)) {
              nextDueDate = DateTime(now.year, now.month + 1, dueDay);
            }
        }
        
        // Only include bills due within the next 30 days
        final daysDifference = nextDueDate.difference(now).inDays;
        if (daysDifference <= 30) {
          upcomingBills.add({
            ...bill,
            'dueDate': nextDueDate,
            'daysUntilDue': daysDifference,
          });
        }
      }
      
      // Sort by due date
      upcomingBills.sort((a, b) {
        final dateA = a['dueDate'] as DateTime;
        final dateB = b['dueDate'] as DateTime;
        return dateA.compareTo(dateB);
      });
      
      return upcomingBills;
    } catch (e) {
      debugPrint('Error getting upcoming bills: $e');
      return [];
    }
  }
  
  // Detect recurring bills from SMS transactions
  Future<void> detectRecurringBills() async {
    try {
      // Get all transactions from the last 6 months
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final transactions = await _storageService.getTransactions();
      
      // Filter SMS transactions from the last 6 months
      final smsTransactions = transactions
          .where((t) => t.isSms && t.date.isAfter(sixMonthsAgo))
          .toList();
      
      if (smsTransactions.isEmpty) {
        return;
      }
      
      // Group transactions by business/merchant
      final groupedTransactions = <String, List<Transaction>>{};
      for (final transaction in smsTransactions) {
        final business = transaction.business?.toLowerCase() ?? 'unknown';
        if (!groupedTransactions.containsKey(business)) {
          groupedTransactions[business] = [];
        }
        groupedTransactions[business]!.add(transaction);
      }
      
      // Analyze each group for recurring patterns
      final suggestedBills = <Map<String, dynamic>>[];
      
      for (final entry in groupedTransactions.entries) {
        final business = entry.key;
        final businessTransactions = entry.value;
        
        if (businessTransactions.length < 2) continue;
        
        // Sort by date
        businessTransactions.sort((a, b) => a.date.compareTo(b.date));
        
        // Check for recurring patterns
        final recurringPattern = _analyzeRecurringPattern(businessTransactions);
        
        if (recurringPattern != null) {
          final averageAmount = businessTransactions
              .map((t) => t.amount)
              .reduce((a, b) => a + b) / businessTransactions.length;
          
          suggestedBills.add({
            'name': _formatBusinessName(business),
            'amount': double.parse(averageAmount.toStringAsFixed(2)),
            'frequency': recurringPattern['frequency'],
            'dueDay': recurringPattern['dueDay'],
            'category': _inferBillCategory(business),
            'confidence': recurringPattern['confidence'],
            'transactionCount': businessTransactions.length,
            'lastTransaction': businessTransactions.last.date,
          });
        }
      }
      
      // Sort by confidence and amount
      suggestedBills.sort((a, b) {
        final confidenceCompare = (b['confidence'] as int).compareTo(a['confidence'] as int);
        if (confidenceCompare != 0) return confidenceCompare;
        return (b['amount'] as double).compareTo(a['amount'] as double);
      });
      
      _suggestedBills = suggestedBills;
      notifyListeners();
    } catch (e) {
      debugPrint('Error detecting recurring bills: $e');
      rethrow;
    }
  }
  
  // Analyze transactions for recurring patterns
  Map<String, dynamic>? _analyzeRecurringPattern(List<Transaction> transactions) {
    if (transactions.length < 2) return null;
    
    // Calculate intervals between transactions
    final intervals = <int>[];
    for (int i = 1; i < transactions.length; i++) {
      final interval = transactions[i].date.difference(transactions[i - 1].date).inDays;
      intervals.add(interval);
    }
    
    // Check for monthly pattern (25-35 days apart)
    final monthlyIntervals = intervals.where((interval) => interval >= 25 && interval <= 35).length;
    final monthlyConfidence = (monthlyIntervals / intervals.length * 100).round();
    
    // Check for weekly pattern (6-8 days apart)
    final weeklyIntervals = intervals.where((interval) => interval >= 6 && interval <= 8).length;
    final weeklyConfidence = (weeklyIntervals / intervals.length * 100).round();
    
    // Check for biweekly pattern (12-16 days apart)
    final biweeklyIntervals = intervals.where((interval) => interval >= 12 && interval <= 16).length;
    final biweeklyConfidence = (biweeklyIntervals / intervals.length * 100).round();
    
    // Determine the most likely pattern
    if (monthlyConfidence >= 70) {
      // Calculate average due day of month
      final dueDays = transactions.map((t) => t.date.day).toList();
      final averageDueDay = (dueDays.reduce((a, b) => a + b) / dueDays.length).round();
      
      return {
        'frequency': 'Monthly',
        'dueDay': averageDueDay,
        'confidence': monthlyConfidence,
      };
    } else if (weeklyConfidence >= 70) {
      return {
        'frequency': 'Weekly',
        'dueDay': transactions.last.date.day,
        'confidence': weeklyConfidence,
      };
    } else if (biweeklyConfidence >= 70) {
      return {
        'frequency': 'Biweekly',
        'dueDay': transactions.last.date.day,
        'confidence': biweeklyConfidence,
      };
    }
    
    // If no clear pattern but transactions are somewhat regular
    if (transactions.length >= 3 && intervals.isNotEmpty) {
      final averageInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      
      if (averageInterval >= 25 && averageInterval <= 35) {
        return {
          'frequency': 'Monthly',
          'dueDay': transactions.last.date.day,
          'confidence': 60,
        };
      }
    }
    
    return null;
  }
  
  // Format business name for display
  String _formatBusinessName(String business) {
    if (business == 'unknown') return 'Unknown Business';
    
    // Capitalize first letter of each word
    return business
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
  }
  
  // Infer bill category from business name
  String _inferBillCategory(String business) {
    business = business.toLowerCase();
    
    if (business.contains('electric') || 
        business.contains('power') || 
        business.contains('utility') ||
        business.contains('water') ||
        business.contains('gas')) {
      return 'Utilities';
    }
    
    if (business.contains('netflix') || 
        business.contains('spotify') || 
        business.contains('amazon') ||
        business.contains('disney') ||
        business.contains('subscription')) {
      return 'Subscription';
    }
    
    if (business.contains('safaricom') || 
        business.contains('airtel') || 
        business.contains('phone') ||
        business.contains('mobile') ||
        business.contains('telecom')) {
      return 'Phone';
    }
    
    if (business.contains('internet') || 
        business.contains('wifi') || 
        business.contains('broadband')) {
      return 'Internet';
    }
    
    if (business.contains('insurance') || 
        business.contains('cover') || 
        business.contains('policy')) {
      return 'Insurance';
    }
    
    if (business.contains('rent') || 
        business.contains('landlord') || 
        business.contains('property')) {
      return 'Rent/Mortgage';
    }
    
    return 'Bill';
  }
  
  // Add a new recurring bill
  Future<void> addRecurringBill(Map<String, dynamic> billData) async {
    try {
      final billId = _uuid.v4();
      
      final billDocument = {
        'id': billId,
        'name': billData['name'],
        'amount': billData['amount'],
        'frequency': billData['frequency'],
        'dueDay': billData['dueDay'],
        'category': billData['category'] ?? 'Bill',
        'paymentMethod': billData['paymentMethod'] ?? 'Unknown',
        'reminderEnabled': billData['reminderEnabled'] ?? true,
        'notes': billData['notes'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Save to Appwrite
      await _appwriteService.createRecurringBill(billDocument);
      
      // Update local cache
      _recurringBills.add(billDocument);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding recurring bill: $e');
      rethrow;
    }
  }
  
  // Update a recurring bill
  Future<void> updateRecurringBill(String billId, Map<String, dynamic> billData) async {
    try {
      final updatedData = {
        ...billData,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Update in Appwrite
      await _appwriteService.updateRecurringBill(billId, updatedData);
      
      // Update local cache
      final billIndex = _recurringBills.indexWhere((bill) => bill['id'] == billId);
      if (billIndex != -1) {
        _recurringBills[billIndex] = {
          ..._recurringBills[billIndex],
          ...updatedData,
        };
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating recurring bill: $e');
      rethrow;
    }
  }
  
  // Delete a recurring bill
  Future<void> deleteRecurringBill(String billId) async {
    try {
      // Delete from Appwrite
      await _appwriteService.deleteRecurringBill(billId);
      
      // Remove from local cache
      _recurringBills.removeWhere((bill) => bill['id'] == billId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting recurring bill: $e');
      rethrow;
    }
  }
  
  // Mark a bill as paid for a specific period
  Future<void> markBillAsPaid(String billId, DateTime paidDate) async {
    try {
      final paymentRecord = {
        'billId': billId,
        'paidDate': paidDate.toIso8601String(),
        'paidAt': DateTime.now().toIso8601String(),
      };
      
      // Save payment record to Appwrite
      await _appwriteService.createBillPayment(paymentRecord);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking bill as paid: $e');
      rethrow;
    }
  }
  
  // Get payment history for a bill
  Future<List<Map<String, dynamic>>> getBillPaymentHistory(String billId) async {
    try {
      final payments = await _appwriteService.getBillPayments(billId);
      
      return payments.map((doc) {
        return {
          'id': doc.$id,
          'billId': doc.data['billId'],
          'paidDate': DateTime.parse(doc.data['paidDate']),
          'paidAt': DateTime.parse(doc.data['paidAt']),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting bill payment history: $e');
      return [];
    }
  }
  
  // =========== UTILITY METHODS ===========
  
  // Clear all cached data
  void clearCache() {
    _recurringBills.clear();
    _suggestedBills.clear();
    notifyListeners();
  }
  
  // Refresh all data
  Future<void> refreshData() async {
    try {
      clearCache();
      await getRecurringBills();
      await detectRecurringBills();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      rethrow;
    }
  }
  
  // Get summary statistics
  Map<String, dynamic> getSummaryStats() {
    try {
      final totalBills = _recurringBills.length;
      final totalMonthlyAmount = _recurringBills
          .where((bill) => bill['frequency'] == 'Monthly')
          .fold<double>(0.0, (sum, bill) => sum + (bill['amount'] as double));
      
      final categoryCounts = <String, int>{};
      for (final bill in _recurringBills) {
        final category = bill['category'] as String;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
      
      return {
        'totalBills': totalBills,
        'totalMonthlyAmount': totalMonthlyAmount,
        'categoryCounts': categoryCounts,
        'suggestedBillsCount': _suggestedBills.length,
      };
    } catch (e) {
      debugPrint('Error getting summary stats: $e');
      return {
        'totalBills': 0,
        'totalMonthlyAmount': 0.0,
        'categoryCounts': <String, int>{},
        'suggestedBillsCount': 0,
      };
    }
  }
  
  // Dispose resources
  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}