// lib/services/ai_notification_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class AiNotificationService {
  static final AiNotificationService _instance = AiNotificationService._internal();
  factory AiNotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AppwriteService _appwriteService = AppwriteService();
  
  bool _isInitialized = false;
  
  AiNotificationService._internal();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        _handleNotificationTap(response.payload);
      },
    );
    
    _isInitialized = true;
    
    // Set up recurring checks for smart notifications
    _setupRecurringChecks();
  }
  
  void _setupRecurringChecks() {
    // Check daily for budget warnings
    Timer.periodic(const Duration(hours: 24), (_) {
      _checkBudgets();
    });
    
    // Check weekly for saving opportunities
    Timer.periodic(const Duration(days: 7), (_) {
      _identifySavingOpportunities();
    });
    
    // Check for upcoming expenses
    Timer.periodic(const Duration(hours: 12), (_) {
      _checkUpcomingExpenses();
    });
    
    // Monitor spending pace
    Timer.periodic(const Duration(hours: 6), (_) {
      _monitorSpendingPace();
    });
    
    // Check savings goals progress
    Timer.periodic(const Duration(days: 3), (_) {
      _checkSavingsGoalsProgress();
    });
  }
  
  Future<void> _checkBudgets() async {
    try {
      final budgets = await _appwriteService.getBudgets();
      
      for (var budget in budgets) {
        if (budget.isActive) {
          // Check if budget is getting close to limit
          final percentageUsed = budget.spent / budget.amount * 100;
          
          if (percentageUsed >= 85) {
            // Calculate days left in budget period
            final daysLeft = budget.endDate.difference(DateTime.now()).inDays;
            
            if (daysLeft > 0) {
              // Send warning notification
              _showAiNotification(
                title: 'Budget Warning',
                body: 'You\'ve used ${percentageUsed.toStringAsFixed(0)}% of your ${budget.title} budget with $daysLeft days left.',
                importance: Importance.high,
                payload: 'budget:${budget.id}',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking budgets: $e');
    }
  }
  
  Future<void> _identifySavingOpportunities() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      // Group transactions by category
      final categoryMap = <String, List<Transaction>>{};
      
      for (var transaction in transactions.where((t) => t.isExpense)) {
        if (!categoryMap.containsKey(transaction.category)) {
          categoryMap[transaction.category] = [];
        }
        
        categoryMap[transaction.category]!.add(transaction);
      }
      
      // Look for categories with high spending
      for (var entry in categoryMap.entries) {
        final category = entry.key;
        final categoryTransactions = entry.value;
        
        // Calculate total and average
        final total = categoryTransactions.map((t) => t.amount).fold(0.0, (prev, amount) => prev + amount);
        final average = total / categoryTransactions.length;
        
        // If this is a high-spending category (more than 5 transactions with high average)
        if (categoryTransactions.length >= 5 && average > 1000) {
          // Calculate potential savings (20% of current spending)
          final potentialSavings = total * 0.2;
          
          // Send saving opportunity notification
          _showAiNotification(
            title: 'Saving Opportunity',
            body: 'Reduce your ${category} spending by 20% to save ${AppConfig.currencySymbol} ${potentialSavings.toStringAsFixed(0)} per month.',
            importance: Importance.high,
            payload: 'saving:$category',
          );
          
          // Only suggest one category at a time
          break;
        }
      }
    } catch (e) {
      debugPrint('Error identifying saving opportunities: $e');
    }
  }
  
  Future<void> _checkUpcomingExpenses() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      // Look for recurring transactions
      final recurringMap = _identifyRecurringTransactions(transactions);
      
      // Check for upcoming recurring expenses
      final now = DateTime.now();
      
      for (var entry in recurringMap.entries) {
        final transaction = entry.key;
        final interval = entry.value;
        
        if (interval > 0 && transaction.isExpense) {
          // Calculate next expected date
          final lastDate = transaction.date;
          final nextExpectedDate = lastDate.add(Duration(days: interval));
          
          // If next expected date is within 3 days
          if (nextExpectedDate.difference(now).inDays <= 3 && nextExpectedDate.isAfter(now)) {
            // Send upcoming expense notification
            _showAiNotification(
              title: 'Upcoming Expense',
              body: '${transaction.title} (${AppConfig.currencySymbol} ${transaction.amount.toStringAsFixed(0)}) is expected in ${nextExpectedDate.difference(now).inDays} days.',
              importance: Importance.high,
              payload: 'upcoming:${transaction.id}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking upcoming expenses: $e');
    }
  }
  
  Map<Transaction, int> _identifyRecurringTransactions(List<Transaction> transactions) {
    final recurringMap = <Transaction, int>{};
    
    // Group transactions by similar title and amount
    final groups = <String, List<Transaction>>{};
    
    for (var transaction in transactions) {
      // Create a key based on title and amount (rounded to nearest 100)
      final key = '${transaction.title}_${(transaction.amount / 100).round() * 100}';
      
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      
      groups[key]!.add(transaction);
    }
    
    // Identify recurring patterns in each group
    for (var entry in groups.entries) {
      final groupTransactions = entry.value;
      
      // Need at least 2 transactions to identify a pattern
      if (groupTransactions.length >= 2) {
        // Sort by date
        groupTransactions.sort((a, b) => a.date.compareTo(b.date));
        
        // Calculate intervals between transactions
        final intervals = <int>[];
        
        for (int i = 0; i < groupTransactions.length - 1; i++) {
          final current = groupTransactions[i];
          final next = groupTransactions[i + 1];
          
          final interval = next.date.difference(current.date).inDays;
          intervals.add(interval);
        }
        
        // Check if intervals are consistent (within 2 days variation)
        if (intervals.isNotEmpty) {
          final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
          
          bool isConsistent = true;
          for (var interval in intervals) {
            if ((interval - avgInterval).abs() > 2) {
              isConsistent = false;
              break;
            }
          }
          
          if (isConsistent) {
            // This is likely a recurring transaction
            recurringMap[groupTransactions.last] = avgInterval.round();
          }
        }
      }
    }
    
    return recurringMap;
  }
  
  Future<void> _monitorSpendingPace() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      final now = DateTime.now();
      
      // Calculate monthly spending
      final monthStart = DateTime(now.year, now.month, 1);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysPassed = now.day;
      
      // Get expenses for current month
      final monthlyExpenses = transactions
          .where((t) => t.isExpense && t.date.isAfter(monthStart))
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      // Get income for current month
      final monthlyIncome = transactions
          .where((t) => !t.isExpense && t.date.isAfter(monthStart))
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      // Calculate ideal spending pace
      final idealPace = monthlyIncome / daysInMonth;
      final actualPace = monthlyExpenses / daysPassed;
      
      // If spending too fast (25% faster than ideal pace)
      if (actualPace > idealPace * 1.25 && daysPassed >= 7) {
        // Calculate days until funds run out
        final remainingFunds = monthlyIncome - monthlyExpenses;
        final daysRemaining = remainingFunds / actualPace;
        
        // If funds will run out before end of month
        if (daysRemaining < (daysInMonth - daysPassed)) {
          _showAiNotification(
            title: 'Spending Warning',
            body: 'You\'re spending too fast. At this rate, you\'ll run out of funds in ${daysRemaining.round()} days, before the end of the month.',
            importance: Importance.high,
            payload: 'pace:warning',
          );
        }
      }
    } catch (e) {
      debugPrint('Error monitoring spending pace: $e');
    }
  }
  
  Future<void> _checkSavingsGoalsProgress() async {
    try {
      final goals = await _appwriteService.fetchSavingsGoals();
      
      for (var goal in goals) {
        if (goal.status == SavingsGoalStatus.active) {
          // Calculate time progress percentage
          final totalDuration = goal.targetDate.difference(goal.startDate ?? DateTime.now()).inDays;
          final elapsed = DateTime.now().difference(goal.startDate ?? DateTime.now()).inDays;
          final timeProgress = elapsed / totalDuration;
          
          // Calculate amount progress percentage
          final amountProgress = goal.currentAmount / goal.targetAmount;
          
          // If significantly behind schedule (time progress > amount progress + 20%)
          if (timeProgress > amountProgress + 0.2 && timeProgress < 0.9) {
            // Calculate amount needed to catch up
            final targetProgress = timeProgress;
            final targetAmount = goal.targetAmount * targetProgress;
            final amountNeeded = targetAmount - goal.currentAmount;
            
            if (amountNeeded > 0) {
              _showAiNotification(
                title: 'Goal Progress Alert',
                body: 'Your "${goal.title}" goal is behind schedule. Add ${AppConfig.currencySymbol} ${amountNeeded.toStringAsFixed(0)} to catch up.',
                importance: Importance.high,
                payload: 'goal:${goal.id}',
              );
            }
          }
          // If almost complete (>90%)
          else if (amountProgress > 0.9 && amountProgress < 1.0) {
            final amountRemaining = goal.targetAmount - goal.currentAmount;
            
            _showAiNotification(
              title: 'Almost There!',
              body: 'You\'re ${(amountProgress * 100).toStringAsFixed(0)}% of the way to your "${goal.title}" goal. Just ${AppConfig.currencySymbol} ${amountRemaining.toStringAsFixed(0)} to go!',
              importance: Importance.high,
              payload: 'goal:${goal.id}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking savings goals progress: $e');
    }
  }
  
  Future<void> _showAiNotification({
    required String title,
    required String body,
    required Importance importance,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ai_insights_channel',
      'AI Insights',
      channelDescription: 'Financial insights and alerts from AI',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF32CD32),
      enableLights: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    // Handle different types of notifications
    if (payload.startsWith('budget:')) {
      // Navigate to budget details
      debugPrint('Navigate to budget details: ${payload.split(':')[1]}');
    } else if (payload.startsWith('saving:')) {
      // Navigate to savings opportunity
      debugPrint('Navigate to savings opportunity: ${payload.split(':')[1]}');
    } else if (payload.startsWith('upcoming:')) {
      // Navigate to transaction details
      debugPrint('Navigate to transaction: ${payload.split(':')[1]}');
    } else if (payload.startsWith('pace:')) {
      // Navigate to spending overview
      debugPrint('Navigate to spending overview');
    } else if (payload.startsWith('goal:')) {
      // Navigate to goal details
      debugPrint('Navigate to goal details: ${payload.split(':')[1]}');
    }
  }
  
  // Smart AI suggestion based on recent transactions
  Future<Map<String, dynamic>?> generateSmartSavingSuggestion() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      // Get recent transactions (last 30 days)
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      final recentTransactions = transactions
          .where((t) => t.isExpense && t.date.isAfter(recentDate))
          .toList();
      
      // Group by category
      final categoryMap = <String, List<Transaction>>{};
      
      for (var transaction in recentTransactions) {
        if (!categoryMap.containsKey(transaction.category)) {
          categoryMap[transaction.category] = [];
        }
        
        categoryMap[transaction.category]!.add(transaction);
      }
      
      // Identify highest spending categories
      final categories = categoryMap.entries.toList()
        ..sort((a, b) {
          final aTotal = a.value.map((t) => t.amount).fold(0.0, (prev, amount) => prev + amount);
          final bTotal = b.value.map((t) => t.amount).fold(0.0, (prev, amount) => prev + amount);
          return bTotal.compareTo(aTotal);
        });
      
      if (categories.isNotEmpty) {
        final topCategory = categories.first.key;
        final topCategoryTransactions = categories.first.value;
        
        // Calculate category total
        final categoryTotal = topCategoryTransactions
            .map((t) => t.amount)
            .fold(0.0, (prev, amount) => prev + amount);
        
        // Calculate average transaction
        final avgTransaction = categoryTotal / topCategoryTransactions.length;
        
        // Generate suggestion based on category
        if (topCategory == 'Food' || topCategory == 'Dining') {
          return {
            'category': topCategory,
            'suggestion': 'Reduce dining out expenses this week. By cooking at home 2 out of 4 times instead of eating out, you can save roughly ${AppConfig.currencySymbol} ${(avgTransaction * 2).toStringAsFixed(0)} based on your previous spending.',
            'savingAmount': avgTransaction * 2,
            'icon': Icons.restaurant,
          };
        } else if (topCategory == 'Transport' || topCategory == 'Travel') {
          return {
            'category': topCategory,
            'suggestion': 'Try carpooling or using public transport twice this week instead of your usual method. This could save you around ${AppConfig.currencySymbol} ${(avgTransaction * 0.6).toStringAsFixed(0)} based on your typical travel expenses.',
            'savingAmount': avgTransaction * 0.6,
            'icon': Icons.directions_car,
          };
        } else if (topCategory == 'Shopping' || topCategory == 'Clothing') {
          return {
            'category': topCategory,
            'suggestion': 'Consider a one-week pause on non-essential purchases. This small change could save you approximately ${AppConfig.currencySymbol} ${(avgTransaction * 1.5).toStringAsFixed(0)} this week.',
            'savingAmount': avgTransaction * 1.5,
            'icon': Icons.shopping_bag,
          };
        } else if (topCategory == 'Entertainment') {
          return {
            'category': topCategory,
            'suggestion': 'Try free entertainment options this weekend instead of paid activities. This could save you around ${AppConfig.currencySymbol} ${(avgTransaction * 1.2).toStringAsFixed(0)} based on your usual entertainment spending.',
            'savingAmount': avgTransaction * 1.2,
            'icon': Icons.movie,
          };
        } else {
          // Generic suggestion
          return {
            'category': topCategory,
            'suggestion': 'You could save ${AppConfig.currencySymbol} ${(avgTransaction).toStringAsFixed(0)} this week by reducing your ${topCategory} expenses by just one transaction.',
            'savingAmount': avgTransaction,
            'icon': Icons.savings,
          };
        }
      }
    } catch (e) {
      debugPrint('Error generating smart saving suggestion: $e');
    }
    
    return null;
  }
  
  // Schedule a future reminder about a goal
  Future<void> scheduleGoalReminder(SavingsGoal goal, {int daysFromNow = 3}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(days: daysFromNow));
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'goals_reminder_channel',
      'Goal Reminders',
      channelDescription: 'Reminders about your savings goals',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF32CD32),
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    // Calculate amount needed to stay on track
    final totalDays = goal.targetDate.difference(goal.startDate ?? DateTime.now()).inDays;
    final elapsedDays = DateTime.now().difference(goal.startDate ?? DateTime.now()).inDays + daysFromNow;
    final targetProgress = elapsedDays / totalDays;
    final targetAmount = goal.targetAmount * targetProgress;
    final currentAmount = goal.currentAmount;
    final amountNeeded = targetAmount - currentAmount > 0 ? targetAmount - currentAmount : 0;
    
    // Generate a motivational message
    String message;
    if (amountNeeded > 0) {
      message = 'Add ${AppConfig.currencySymbol} ${amountNeeded.toStringAsFixed(0)} to your "${goal.title}" goal to stay on track!';
    } else {
      message = 'Great job staying on track with your "${goal.title}" goal! Keep it up!';
    }
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      goal.id.hashCode,
      'Goal Reminder',
      message,
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'goal:${goal.id}',
    );
  }
  
  // Schedule a payday saving reminder
  Future<void> schedulePaydaySavingReminder(DateTime payday, double suggestedAmount) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Schedule for a few hours after expected payday
    final scheduledDate = tz.TZDateTime.from(
      payday.add(const Duration(hours: 3)),
      tz.local,
    );
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'payday_reminder_channel',
      'Payday Reminders',
      channelDescription: 'Reminders to save on payday',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF32CD32),
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      payday.millisecondsSinceEpoch % 100000,
      'Payday Saving Opportunity',
      'Payday! Consider saving ${AppConfig.currencySymbol} ${suggestedAmount.toStringAsFixed(0)} right now before you start spending.',
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'payday:saving',
    );
  }
  
  // Send a custom AI insight notification
  Future<void> sendAiInsightNotification(String title, String message) async {
    await _showAiNotification(
      title: title,
      body: message,
      importance: Importance.high,
    );
  }
  
  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}