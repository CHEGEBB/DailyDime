// lib/providers/savings_provider.dart

import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/notification_service.dart';
import 'package:dailydime/services/savings_ai_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SavingsProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();
  final SavingsAIService _aiService = SavingsAIService();
  final NotificationService _notificationService = NotificationService();
  final SmsService _smsService = SmsService();
  
  List<SavingsGoal> _savingsGoals = [];
  List<Map<String, dynamic>> _savingsChallenges = [];
  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic>? _aiSavingSuggestion;
  List<Map<String, dynamic>> _recurringExpenses = [];
  bool _aiSuggestionDismissed = false;
  
  // Getters
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<SavingsGoal> get activeGoals => _savingsGoals.where((g) => g.status == SavingsGoalStatus.active).toList();
  List<SavingsGoal> get completedGoals => _savingsGoals.where((g) => g.status == SavingsGoalStatus.completed).toList();
  List<SavingsGoal> get upcomingGoals => _savingsGoals.where((g) => g.status == SavingsGoalStatus.upcoming).toList();
  List<Map<String, dynamic>> get savingsChallenges => _savingsChallenges;
  bool get isLoading => _isLoading;
  String get error => _error;
  Map<String, dynamic>? get aiSavingSuggestion => _aiSavingSuggestion;
  List<Map<String, dynamic>> get recurringExpenses => _recurringExpenses;
  bool get aiSuggestionDismissed => _aiSuggestionDismissed;
  
  // Total savings amount
  double get totalSavingsAmount => _savingsGoals.fold(
    0, (total, goal) => total + goal.currentAmount);
  
  // Month-to-date savings
  double get mtdSavingsAmount {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    double total = 0;
    for (var goal in _savingsGoals) {
      for (var transaction in goal.transactions) {
        if (transaction.date.isAfter(startOfMonth)) {
          total += transaction.amount;
        }
      }
    }
    return total;
  }
  
  // Average daily savings
  double get averageDailySavings {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = now.difference(startOfMonth).inDays + 1;
    
    return mtdSavingsAmount / daysInMonth;
  }
  
  // Fetch all savings goals
  Future<void> fetchSavingsGoals() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final goals = await _appwriteService.fetchSavingsGoals();
      _savingsGoals = goals;
      
      // Update status based on progress
      _updateGoalStatuses();
      
      // Schedule notifications for goals
      _scheduleGoalNotifications();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch savings goals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a new savings goal
  Future<bool> addSavingsGoal(SavingsGoal goal) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Save to Appwrite
      final savedGoal = await _appwriteService.createSavingsGoal(goal);
      
      // Add to local list
      _savingsGoals.add(savedGoal);
      
      // Schedule notification
      _scheduleGoalNotification(savedGoal);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add savings goal: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update an existing savings goal
  Future<bool> updateSavingsGoal(SavingsGoal goal) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Update in Appwrite
      await _appwriteService.updateSavingsGoal(goal);
      
      // Update in local list
      final index = _savingsGoals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _savingsGoals[index] = goal;
      }
      
      // Update notification
      _scheduleGoalNotification(goal);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update savings goal: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete a savings goal
  Future<bool> deleteSavingsGoal(String goalId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Delete from Appwrite
      await _appwriteService.deleteSavingsGoal(goalId);
      
      // Remove from local list
      _savingsGoals.removeWhere((g) => g.id == goalId);
      
      // Cancel notifications
      _notificationService.cancelNotificationsForGoal(goalId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete savings goal: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Add a contribution to a savings goal
  Future<bool> addContribution(String goalId, double amount, String note) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Find the goal
      final index = _savingsGoals.indexWhere((g) => g.id == goalId);
      if (index == -1) {
        _error = 'Goal not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Create transaction
      final transaction = SavingsTransaction(
        amount: amount,
        date: DateTime.now(),
        note: note,
      );
      
      // Update goal locally
      final updatedGoal = _savingsGoals[index].copyWith(
        currentAmount: _savingsGoals[index].currentAmount + amount,
        transactions: [..._savingsGoals[index].transactions, transaction],
      );
      
      // Check if goal is now completed
      if (updatedGoal.currentAmount >= updatedGoal.targetAmount) {
        final completedGoal = updatedGoal.copyWith(
          status: SavingsGoalStatus.completed,
        );
        
        // Update in Appwrite
        await _appwriteService.updateSavingsGoal(completedGoal);
        
        // Update locally
        _savingsGoals[index] = completedGoal;
        
        // Send completion notification
        _notificationService.showGoalCompletedNotification(
          completedGoal.id,
          completedGoal.title,
        );
      } else {
        // Update in Appwrite
        await _appwriteService.updateSavingsGoal(updatedGoal);
        
        // Update locally
        _savingsGoals[index] = updatedGoal;
        
        // Send progress notification if milestone reached
        final progressPercentage = updatedGoal.progressPercentage;
        if (progressPercentage >= 0.25 && progressPercentage < 0.26 ||
            progressPercentage >= 0.5 && progressPercentage < 0.51 ||
            progressPercentage >= 0.75 && progressPercentage < 0.76) {
          _notificationService.showGoalMilestoneNotification(
            updatedGoal.id,
            updatedGoal.title,
            (progressPercentage * 100).toInt(),
          );
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add contribution: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get AI savings suggestion
  Future<void> getAISavingSuggestion() async {
    if (_aiSuggestionDismissed) return;
    
    try {
      // Get recent transactions from SMS
      final transactions = await _smsService.loadHistoricalMpesaMessages();
      
      // Get AI suggestion
      final suggestion = await _aiService.analyzeSavingOpportunities(transactions);
      
      // Update recurring expenses
      if (suggestion.containsKey('recurringExpenses')) {
        _recurringExpenses = List<Map<String, dynamic>>.from(suggestion['recurringExpenses']);
      }
      
      // Set AI suggestion
      _aiSavingSuggestion = suggestion;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting AI saving suggestion: $e');
    }
  }
  
  // Apply AI saving suggestion to goal
  Future<bool> applyAISavingSuggestion(String goalId) async {
    if (_aiSavingSuggestion == null) return false;
    
    final amount = _aiSavingSuggestion!['savingAmount'] as double;
    final reason = _aiSavingSuggestion!['reason'] as String;
    
    // Add contribution to goal
    final result = await addContribution(
      goalId,
      amount,
      'AI-suggested saving: $reason',
    );
    
    // Reset suggestion after applying
    _aiSavingSuggestion = null;
    _aiSuggestionDismissed = true;
    notifyListeners();
    
    return result;
  }
  
  // Dismiss AI suggestion
  void dismissAISuggestion() {
    _aiSavingSuggestion = null;
    _aiSuggestionDismissed = true;
    notifyListeners();
  }
  
  // Reset dismissal state (called daily)
  void resetAISuggestionDismissal() {
    _aiSuggestionDismissed = false;
    notifyListeners();
  }
  
  // Fetch savings challenges
  Future<void> fetchSavingsChallenges() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get recent transactions for context
      final transactions = await _smsService.loadHistoricalMpesaMessages();
      
      // Calculate average monthly savings
      double avgMonthlySavings = mtdSavingsAmount;
      if (avgMonthlySavings == 0) {
        avgMonthlySavings = 5000; // Default value if no data
      }
      
      // Generate challenge with AI
      final challenge = await _aiService.generateSavingsChallenge(
        transactions,
        avgMonthlySavings,
      );
      
      // Predefined challenges
      final predefinedChallenges = [
        {
          'title': '52-Week Challenge',
          'description': 'Save KES 50 in week 1, KES 100 in week 2, and so on. By week 52, you\'ll have saved KES 68,900!',
          'icon': 'calendar_month',
          'color': Colors.purple.value,
          'participants': 1245,
          'isPopular': true,
          'difficulty': 'medium',
          'timeframeDays': 365,
        },
        {
          'title': '30-Day No-Spend Challenge',
          'description': 'Cut out non-essential spending for 30 days and see how much you can save!',
          'icon': 'timer',
          'color': Colors.blue.value,
          'participants': 857,
          'isPopular': false,
          'difficulty': 'hard',
          'timeframeDays': 30,
        },
        {
          'title': 'Round-Up Challenge',
          'description': 'Round up every purchase to the nearest 100 KES and save the difference. Small amounts add up!',
          'icon': 'attach_money',
          'color': Colors.green.value,
          'participants': 924,
          'isPopular': true,
          'difficulty': 'easy',
          'timeframeDays': 90,
        },
        {
          'title': '1% Daily Challenge',
          'description': 'Save just 1% of your daily income. Within a year, you\'ll have saved over a third of your monthly income!',
          'icon': 'percent',
          'color': Colors.orange.value,
          'participants': 613,
          'isPopular': false,
          'difficulty': 'easy',
          'timeframeDays': 100,
        },
      ];
      
      // Add AI challenge to predefined ones
      _savingsChallenges = [
        {
          'title': challenge['title'],
          'description': challenge['description'],
          'icon': 'auto_awesome',
          'color': Colors.amber.value,
          'participants': 251,
          'isPopular': true,
          'isAiGenerated': true,
          'difficulty': challenge['difficulty'] ?? 'medium',
          'timeframeDays': challenge['timeframeDays'],
        },
        ...predefinedChallenges,
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching savings challenges: $e');
      // Fallback to predefined challenges
      _savingsChallenges = [
        {
          'title': '52-Week Challenge',
          'description': 'Save KES 50 in week 1, KES 100 in week 2, and so on. By week 52, you\'ll have saved KES 68,900!',
          'icon': 'calendar_month',
          'color': Colors.purple.value,
          'participants': 1245,
          'isPopular': true,
        },
        {
          'title': '30-Day No-Spend Challenge',
          'description': 'Cut out non-essential spending for 30 days and see how much you can save!',
          'icon': 'timer',
          'color': Colors.blue.value,
          'participants': 857,
          'isPopular': false,
        },
      ];
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get AI insights for a specific goal
  Future<Map<String, dynamic>> getGoalInsights(String goalId) async {
    try {
      final index = _savingsGoals.indexWhere((g) => g.id == goalId);
      if (index == -1) {
        return {
          'error': 'Goal not found',
        };
      }
      
      final goal = _savingsGoals[index];
      return await _aiService.getGoalInsights(goal);
    } catch (e) {
      debugPrint('Error getting goal insights: $e');
      return {
        'error': 'Failed to get insights',
      };
    }
  }
  
  // Helper methods
  void _updateGoalStatuses() {
    for (int i = 0; i < _savingsGoals.length; i++) {
      final goal = _savingsGoals[i];
      
      if (goal.currentAmount >= goal.targetAmount) {
        // Mark as completed if target reached
        _savingsGoals[i] = goal.copyWith(status: SavingsGoalStatus.completed);
      } else if (goal.targetDate.isBefore(DateTime.now())) {
        // Target date passed but not completed
        _savingsGoals[i] = goal.copyWith(status: SavingsGoalStatus.active);
      } else if (goal.startDate.isAfter(DateTime.now())) {
        // Start date in future
        _savingsGoals[i] = goal.copyWith(status: SavingsGoalStatus.upcoming);
      }
    }
  }
  
  void _scheduleGoalNotifications() {
    for (final goal in _savingsGoals) {
      _scheduleGoalNotification(goal);
    }
  }
  
  void _scheduleGoalNotification(SavingsGoal goal) {
    // Cancel existing notifications for this goal
    _notificationService.cancelNotificationsForGoal(goal.id);
    
    // Skip if goal is completed
    if (goal.status == SavingsGoalStatus.completed) return;
    
    // Reminder notifications
    if (goal.daysLeft > 0) {
      // Weekly reminder
      _notificationService.scheduleWeeklyGoalReminder(
        goal.id,
        goal.title,
        goal.targetAmount,
        goal.currentAmount,
        goal.targetDate,
      );
      
      // Final week countdown
      if (goal.daysLeft <= 7) {
        _notificationService.scheduleDailyGoalReminder(
          goal.id,
          goal.title,
          goal.targetAmount,
          goal.currentAmount,
          goal.targetDate,
        );
      }
      
      // Day before deadline
      if (goal.daysLeft == 1) {
        _notificationService.scheduleGoalDeadlineReminder(
          goal.id,
          goal.title,
          goal.targetAmount,
          goal.currentAmount,
        );
      }
    }
  }
}