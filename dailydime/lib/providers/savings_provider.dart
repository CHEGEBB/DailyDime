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
  List<Map<String, dynamic>> _userChallenges = [];
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
  List<Map<String, dynamic>> get userChallenges => _userChallenges;
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
  
  // Create a new savings challenge
  Future<bool> createSavingsChallenge({
    required String title,
    required String description,
    String? icon,
    Color? color,
    String difficulty = 'medium',
    int timeframeDays = 30,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Create challenge object
      final challenge = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'description': description,
        'icon': icon ?? 'savings',
        'color': (color ?? Colors.blue).value,
        'participants': 1, // Creator is first participant
        'isPopular': false,
        'isUserCreated': true,
        'difficulty': difficulty,
        'timeframeDays': timeframeDays,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': 'current_user', // You might want to get actual user ID
        'status': 'active',
      };
      
      // Save to Appwrite
      await _appwriteService.createSavingsChallenge(challenge);
      
      // Add to local challenges list
      _savingsChallenges.insert(0, challenge);
      
      // Automatically join the created challenge
      await _joinChallengeInternal(challenge);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create savings challenge: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Join a savings challenge
  Future<bool> joinSavingsChallenge(String challengeTitle) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Find the challenge
      final challenge = _savingsChallenges.firstWhere(
        (c) => c['title'] == challengeTitle,
        orElse: () => {},
      );
      
      if (challenge.isEmpty) {
        _error = 'Challenge not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Check if already joined
      final isAlreadyJoined = _userChallenges.any(
        (uc) => uc['challengeId'] == challenge['id'] || uc['title'] == challengeTitle,
      );
      
      if (isAlreadyJoined) {
        _error = 'You have already joined this challenge';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      await _joinChallengeInternal(challenge);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to join savings challenge: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Internal method to join a challenge
  Future<void> _joinChallengeInternal(Map<String, dynamic> challenge) async {
    // Create user challenge record
    final userChallenge = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'challengeId': challenge['id'] ?? challenge['title'].hashCode.toString(),
      'title': challenge['title'],
      'description': challenge['description'],
      'icon': challenge['icon'],
      'color': challenge['color'],
      'difficulty': challenge['difficulty'],
      'timeframeDays': challenge['timeframeDays'],
      'joinedAt': DateTime.now().toIso8601String(),
      'status': 'active',
      'progress': 0.0,
      'targetAmount': _calculateChallengeTargetAmount(challenge),
      'currentAmount': 0.0,
      'daysRemaining': challenge['timeframeDays'],
      'milestones': _generateChallengeMilestones(challenge),
    };
    
    // Save to Appwrite
    await _appwriteService.joinSavingsChallenge(userChallenge as String);
    
    // Add to local user challenges
    _userChallenges.add(userChallenge);
    
    // Update participant count in original challenge
    final challengeIndex = _savingsChallenges.indexWhere(
      (c) => (c['id'] ?? c['title'].hashCode.toString()) == (challenge['id'] ?? challenge['title'].hashCode.toString()),
    );
    if (challengeIndex != -1) {
      _savingsChallenges[challengeIndex]['participants'] = 
        (_savingsChallenges[challengeIndex]['participants'] ?? 0) + 1;
    }
    
    // Schedule challenge notifications
    _scheduleChallengeNotifications(userChallenge);
    
    // Show success notification
    _notificationService.showChallengeJoinedNotification(
      userChallenge['id'],
      userChallenge['title'],
    );
  }
  
  // Calculate target amount for a challenge based on type
  double _calculateChallengeTargetAmount(Map<String, dynamic> challenge) {
    final title = challenge['title'].toString().toLowerCase();
    
    if (title.contains('52-week')) {
      return 68900.0; // KES 68,900 for 52-week challenge
    } else if (title.contains('round-up')) {
      return mtdSavingsAmount * 2; // Estimate based on current savings
    } else if (title.contains('1%')) {
      return (totalSavingsAmount * 0.01 * challenge['timeframeDays']) ?? 10000.0;
    } else if (title.contains('no-spend')) {
      return averageDailySavings * challenge['timeframeDays'];
    } else {
      // Default calculation based on current savings pattern
      return averageDailySavings * challenge['timeframeDays'] * 1.5;
    }
  }
  
  // Generate milestones for a challenge
  List<Map<String, dynamic>> _generateChallengeMilestones(Map<String, dynamic> challenge) {
    final targetAmount = _calculateChallengeTargetAmount(challenge);
    final timeframeDays = challenge['timeframeDays'] as int;
    
    return [
      {
        'percentage': 0.25,
        'amount': targetAmount * 0.25,
        'description': '25% Complete - Great start!',
        'reached': false,
      },
      {
        'percentage': 0.5,
        'amount': targetAmount * 0.5,
        'description': '50% Complete - Halfway there!',
        'reached': false,
      },
      {
        'percentage': 0.75,
        'amount': targetAmount * 0.75,
        'description': '75% Complete - Almost done!',
        'reached': false,
      },
      {
        'percentage': 1.0,
        'amount': targetAmount,
        'description': '100% Complete - Challenge accomplished!',
        'reached': false,
      },
    ];
  }
  
  // Update challenge progress
  Future<bool> updateChallengeProgress(String challengeId, double amount) async {
    try {
      final index = _userChallenges.indexWhere((c) => c['id'] == challengeId);
      if (index == -1) return false;
      
      final challenge = _userChallenges[index];
      final newAmount = (challenge['currentAmount'] as double) + amount;
      final targetAmount = challenge['targetAmount'] as double;
      final newProgress = newAmount / targetAmount;
      
      // Update local challenge
      _userChallenges[index] = {
        ...challenge,
        'currentAmount': newAmount,
        'progress': newProgress.clamp(0.0, 1.0),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Check for milestone achievements
      _checkChallengeMilestones(challengeId, newProgress);
      
      // Update in Appwrite
      await _appwriteService.updateChallengeProgress(challengeId, newAmount, newProgress);
      
      // Check if challenge is completed
      if (newProgress >= 1.0) {
        _userChallenges[index]['status'] = 'completed';
        _notificationService.showChallengeCompletedNotification(
          challengeId,
          challenge['title'],
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
      return false;
    }
  }
  
  // Check and update challenge milestones
  void _checkChallengeMilestones(String challengeId, double progress) {
    final index = _userChallenges.indexWhere((c) => c['id'] == challengeId);
    if (index == -1) return;
    
    final challenge = _userChallenges[index];
    final milestones = List<Map<String, dynamic>>.from(challenge['milestones']);
    
    for (int i = 0; i < milestones.length; i++) {
      final milestone = milestones[i];
      if (!milestone['reached'] && progress >= milestone['percentage']) {
        milestones[i]['reached'] = true;
        
        // Show milestone notification
        _notificationService.showChallengeMilestoneNotification(
          challengeId,
          challenge['title'],
          (milestone['percentage'] * 100).toInt(),
        );
      }
    }
    
    _userChallenges[index]['milestones'] = milestones;
  }
  
  // Get user's active challenges
  List<Map<String, dynamic>> get activeChallenges => 
    _userChallenges.where((c) => c['status'] == 'active').toList();
  
  // Get user's completed challenges
  List<Map<String, dynamic>> get completedChallenges => 
    _userChallenges.where((c) => c['status'] == 'completed').toList();
  
  // Leave a challenge
  Future<bool> leaveSavingsChallenge(String challengeId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Remove from Appwrite
      await _appwriteService.leaveSavingsChallenge(challengeId);
      
      // Remove from local list
      _userChallenges.removeWhere((c) => c['id'] == challengeId);
      
      // Cancel challenge notifications
      _notificationService.cancelChallengeNotifications(challengeId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to leave challenge: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Fetch user's joined challenges
  Future<void> fetchUserChallenges() async {
    try {
      final challenges = await _appwriteService.fetchUserChallenges();
      _userChallenges = challenges;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user challenges: $e');
    }
  }
  
  // Schedule challenge notifications
void _scheduleChallengeNotifications(Map<String, dynamic> challenge) {
  final challengeId = challenge['id'];
  final title = challenge['title'];
  final timeframeDays = challenge['timeframeDays'] as int;
  final targetAmount = (challenge['targetAmount'] ?? 0.0) as double;
  final currentAmount = (challenge['currentAmount'] ?? 0.0) as double;
  
  // Calculate end date based on timeframe
  final endDate = DateTime.now().add(Duration(days: timeframeDays));
  
  // Daily progress reminders
  _notificationService.scheduleDailyChallengeReminder(
    challengeId,
    title,
    targetAmount,
    currentAmount,
    endDate,
  );
  
  // Weekly progress summary
  if (timeframeDays > 7) {
    _notificationService.scheduleWeeklyChallengeReminder(
      challengeId,
      title,
      targetAmount,
      currentAmount,
      endDate,
    );
  }
  
  // Final week countdown
  if (timeframeDays > 7) {
    _notificationService.scheduleChallengeCountdown(
      challengeId,
      title,
      targetAmount,
      currentAmount,
      endDate,
    );
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
          'id': 'challenge_52_week',
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
          'id': 'challenge_no_spend',
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
          'id': 'challenge_round_up',
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
          'id': 'challenge_1_percent',
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
          'id': 'challenge_ai_generated',
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
          'id': 'challenge_52_week',
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
          'id': 'challenge_no_spend',
          'title': '30-Day No-Spend Challenge',
          'description': 'Cut out non-essential spending for 30 days and see how much you can save!',
          'icon': 'timer',
          'color': Colors.blue.value,
          'participants': 857,
          'isPopular': false,
          'difficulty': 'hard',
          'timeframeDays': 30,
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
  // Replace your addSavingsGoalFromMap method in savings_provider.dart with this fixed version:

Future<bool> addSavingsGoalFromMap(Map<String, dynamic> goalData) async {
  _isLoading = true;
  _error = '';
  notifyListeners();
  
  try {
    print('Creating goal from map data: $goalData'); // Debug log
    
    // Create SavingsGoal object from map - properly convert string types to enums
    final goal = SavingsGoal(
      id: goalData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: goalData['title'] ?? '',
      description: goalData['description'] ?? '',
      targetAmount: (goalData['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (goalData['currentAmount'] ?? 0.0).toDouble(),
      targetDate: goalData['targetDate'] != null 
        ? (goalData['targetDate'] is DateTime 
           ? goalData['targetDate'] 
           : DateTime.parse(goalData['targetDate'].toString()))
        : DateTime.now().add(Duration(days: 30)),
      startDate: goalData['startDate'] != null
        ? (goalData['startDate'] is DateTime 
           ? goalData['startDate'] 
           : DateTime.parse(goalData['startDate'].toString()))
        : DateTime.now(),
      category: _stringToCategory(goalData['category']?.toString() ?? 'other'), // Use helper method
      iconAsset: goalData['iconAsset'] ?? 'savings',
      color: _stringToColor(goalData['color']?.toString() ?? '#ff2196f3'), // Use helper method
      priority: goalData['priority'] ?? 'medium',
      isRecurring: goalData['isRecurring'] ?? false,
      reminderFrequency: goalData['reminderFrequency'] ?? 'weekly',
      status: _stringToStatus(goalData['status']?.toString() ?? 'active'), // Use helper method
      dailyTarget: goalData['dailyTarget']?.toDouble(),
      weeklyTarget: goalData['weeklyTarget']?.toDouble(),
      createdAt: goalData['createdAt'] != null
        ? (goalData['createdAt'] is DateTime 
           ? goalData['createdAt'] 
           : DateTime.parse(goalData['createdAt'].toString()))
        : DateTime.now(),
      updatedAt: goalData['updatedAt'] != null
        ? (goalData['updatedAt'] is DateTime 
           ? goalData['updatedAt'] 
           : DateTime.parse(goalData['updatedAt'].toString()))
        : DateTime.now(),
    );
    
    print('Created SavingsGoal object: ${goal.title}'); // Debug log
    
    // Save to Appwrite
    final savedGoal = await _appwriteService.createSavingsGoal(goal);
    print('Saved to Appwrite successfully'); // Debug log
    
    // Add to local list
    _savingsGoals.add(savedGoal);
    
    // Schedule notification
    _scheduleGoalNotification(savedGoal);
    
    _isLoading = false;
    notifyListeners();
    print('Goal creation completed successfully'); // Debug log
    return true;
  } catch (e, stackTrace) {
    print('Error in addSavingsGoalFromMap: $e'); // Debug log
    print('Stack trace: $stackTrace'); // Debug log
    _error = 'Failed to add savings goal from map: $e';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

// Make sure these helper methods are also in your savings_provider.dart:

SavingsGoalCategory _stringToCategory(String categoryString) {
  switch (categoryString.toLowerCase()) {
    case 'travel':
      return SavingsGoalCategory.travel;
    case 'education':
      return SavingsGoalCategory.education;
    case 'electronics':
      return SavingsGoalCategory.electronics;
    case 'vehicle':
      return SavingsGoalCategory.vehicle;
    case 'housing':
      return SavingsGoalCategory.housing;
    case 'emergency':
      return SavingsGoalCategory.emergency;
    case 'retirement':
      return SavingsGoalCategory.retirement;
    case 'debt':
      return SavingsGoalCategory.debt;
    case 'investment':
      return SavingsGoalCategory.investment;
    default:
      return SavingsGoalCategory.other;
  }
}

SavingsGoalStatus _stringToStatus(String statusString) {
  switch (statusString.toLowerCase()) {
    case 'active':
      return SavingsGoalStatus.active;
    case 'completed':
      return SavingsGoalStatus.completed;
    case 'paused':
      return SavingsGoalStatus.paused;
    case 'upcoming':
      return SavingsGoalStatus.upcoming;
    default:
      return SavingsGoalStatus.active;
  }
}

Color _stringToColor(String colorString) {
  try {
    // Handle both #RRGGBB and #AARRGGBB formats
    String cleanColorString = colorString.replaceFirst('#', '');
    
    // If it's 6 characters, add FF for full opacity
    if (cleanColorString.length == 6) {
      cleanColorString = 'FF$cleanColorString';
    }
    
    return Color(int.parse(cleanColorString, radix: 16));
  } catch (e) {
    print('Error parsing color $colorString: $e');
    return Colors.blue; // Default fallback
  }
}
}