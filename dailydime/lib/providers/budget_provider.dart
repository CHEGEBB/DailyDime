// lib/providers/budget_provider.dart
import 'package:flutter/material.dart';
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/budget_ai_service.dart';
import 'package:dailydime/services/notification_service.dart';

class BudgetProvider extends ChangeNotifier {
  final List<Budget> _budgets = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final BudgetAIService _aiService = BudgetAIService();
  final AppwriteService _appwriteService = AppwriteService();
  final StorageService _storageService = StorageService.instance;
  final NotificationService _notificationService = NotificationService();

  // Getters
  List<Budget> get budgets => List.unmodifiable(_budgets);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  
  // Filtered budgets
  List<Budget> get activeBudgets => _budgets.where((b) => b.isActive).toList();
  List<Budget> get dailyBudgets => _budgets.where((b) => b.period == BudgetPeriod.daily && b.isActive).toList();
  List<Budget> get weeklyBudgets => _budgets.where((b) => b.period == BudgetPeriod.weekly && b.isActive).toList();
  List<Budget> get monthlyBudgets => _budgets.where((b) => b.period == BudgetPeriod.monthly && b.isActive).toList();
  List<Budget> get yearlyBudgets => _budgets.where((b) => b.period == BudgetPeriod.yearly && b.isActive).toList();
  
  // Budget insights
  double get totalBudgetAmount => _budgets.fold(0.0, (sum, b) => sum + (b.isActive ? b.amount : 0.0));
  double get totalSpent => _budgets.fold(0.0, (sum, b) => sum + (b.isActive ? b.spent : 0.0));
  double get totalRemaining => totalBudgetAmount - totalSpent;
  double get overallPercentage => totalBudgetAmount > 0 ? (totalSpent / totalBudgetAmount) : 0.0;

  // Category with highest spending
  String get highestSpendingCategory {
    if (_budgets.isEmpty) return 'None';
    
    final categorySpending = <String, double>{};
    for (var budget in _budgets) {
      if (budget.isActive) {
        categorySpending[budget.category] = (categorySpending[budget.category] ?? 0.0) + budget.spent;
      }
    }
    
    if (categorySpending.isEmpty) return 'None';
    
    return categorySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Budget with highest percentage used
  Budget? get mostConsumedBudget {
    if (_budgets.isEmpty) return null;
    
    final activeBudgets = _budgets.where((b) => b.isActive).toList();
    if (activeBudgets.isEmpty) return null;
    
    return activeBudgets.reduce((a, b) => a.percentageUsed > b.percentageUsed ? a : b);
  }

  // Get budget by ID
  Budget? getBudgetById(String id) {
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get budgets by category
  List<Budget> getBudgetsByCategory(String category) {
    return _budgets.where((b) => 
      b.category.toLowerCase() == category.toLowerCase() ||
      b.tags.any((tag) => tag.toLowerCase() == category.toLowerCase())
    ).toList();
  }

  // Get budgets by period
  List<Budget> getBudgetsByPeriod(BudgetPeriod period) {
    return _budgets.where((b) => b.period == period && b.isActive).toList();
  }

  // Check if category exists in any budget
  bool categoryHasBudget(String category) {
    return _budgets.any((b) => 
      b.isActive && 
      (b.category.toLowerCase() == category.toLowerCase() ||
       b.tags.any((tag) => tag.toLowerCase() == category.toLowerCase()))
    );
  }

  // Init - Load budgets from storage and Appwrite
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // First load from local storage for faster UI
      final localBudgets = await _storageService.loadBudgets();
      if (localBudgets.isNotEmpty) {
        _budgets.clear();
        _budgets.addAll(localBudgets);
        notifyListeners();
      }
      
      // Then try to sync with Appwrite
      await syncWithAppwrite();
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize budgets: $e');
    }
  }

  // Refresh budgets
  Future<void> refresh() async {
    await initialize();
  }

  // Sync with Appwrite
  Future<void> syncWithAppwrite() async {
    try {
      final remoteBudgets = await _appwriteService.getBudgets();
      
      // Compare and merge local and remote budgets
      if (remoteBudgets.isNotEmpty) {
        final mergedBudgets = _mergeBudgets(_budgets, remoteBudgets);
        _budgets.clear();
        _budgets.addAll(mergedBudgets);
        
        // Save merged budgets to local storage
        await _storageService.saveBudgets(_budgets);
        
        notifyListeners();
      } else if (_budgets.isNotEmpty) {
        // If no remote budgets but we have local ones, upload them
        for (var budget in _budgets) {
          try {
            await _appwriteService.createBudget(budget);
          } catch (e) {
            print('Error uploading budget ${budget.id}: $e');
          }
        }
      }
    } catch (e) {
      print('Error syncing with Appwrite: $e');
      // Continue with local budgets only
    }
  }
  
  // Helper to merge local and remote budgets
  List<Budget> _mergeBudgets(List<Budget> local, List<Budget> remote) {
    final Map<String, Budget> mergedMap = {};
    
    // Add all local budgets to map
    for (var budget in local) {
      mergedMap[budget.id] = budget;
    }
    
    // Override with remote budgets if they exist
    for (var budget in remote) {
      if (mergedMap.containsKey(budget.id)) {
        // If budget exists in both, use the one with the most recent update
        final localBudget = mergedMap[budget.id]!;
        final localUpdated = localBudget.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final remoteUpdated = budget.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        
        if (remoteUpdated.isAfter(localUpdated)) {
          mergedMap[budget.id] = budget;
        }
      } else {
        // If budget only exists remotely, add it
        mergedMap[budget.id] = budget;
      }
    }
    
    return mergedMap.values.toList();
  }

  // Create a new budget
  Future<bool> createBudget(Budget budget) async {
    _setLoading(true);
    try {
      // Validate budget
      if (budget.amount <= 0) {
        _setError('Budget amount must be greater than 0');
        return false;
      }
      
      if (budget.category.trim().isEmpty) {
        _setError('Budget category cannot be empty');
        return false;
      }

      // Check for duplicate budgets in same category and period
      final existingBudget = _budgets.any((b) => 
        b.category.toLowerCase() == budget.category.toLowerCase() &&
        b.period == budget.period &&
        b.isActive
      );
      
      if (existingBudget) {
        _setError('A budget for this category and period already exists');
        return false;
      }
      
      // Add to local list
      _budgets.add(budget);
      notifyListeners();
      
      // Save to local storage
      await _storageService.saveBudgets(_budgets);
      
      // Upload to Appwrite
      try {
        await _appwriteService.createBudget(budget);
      } catch (e) {
        print('Error uploading budget to Appwrite: $e');
        // Continue even if Appwrite fails
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create budget: $e');
      return false;
    }
  }

  // Update an existing budget
  Future<bool> updateBudget(Budget budget) async {
    _setLoading(true);
    try {
      // Validate budget
      if (budget.amount <= 0) {
        _setError('Budget amount must be greater than 0');
        return false;
      }
      
      if (budget.category.trim().isEmpty) {
        _setError('Budget category cannot be empty');
        return false;
      }

      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        // Update the budget with current timestamp
        final updatedBudget = budget.copyWith(updatedAt: DateTime.now());
        _budgets[index] = updatedBudget;
        notifyListeners();
        
        // Save to local storage
        await _storageService.saveBudgets(_budgets);
        
        // Update in Appwrite
        try {
          await _appwriteService.updateBudget(updatedBudget);
        } catch (e) {
          print('Error updating budget in Appwrite: $e');
          // Continue even if Appwrite fails
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError('Budget not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to update budget: $e');
      return false;
    }
  }

  // Delete a budget
  Future<bool> deleteBudget(String budgetId) async {
    _setLoading(true);
    try {
      final budgetExists = _budgets.any((b) => b.id == budgetId);
      if (!budgetExists) {
        _setError('Budget not found');
        return false;
      }

      _budgets.removeWhere((b) => b.id == budgetId);
      notifyListeners();
      
      // Save to local storage
      await _storageService.saveBudgets(_budgets);
      
      // Delete from Appwrite
      try {
        await _appwriteService.deleteBudget(budgetId);
      } catch (e) {
        print('Error deleting budget from Appwrite: $e');
        // Continue even if Appwrite fails
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete budget: $e');
      return false;
    }
  }

  // Toggle budget active status
  Future<bool> toggleBudgetStatus(String budgetId) async {
    final budget = getBudgetById(budgetId);
    if (budget == null) {
      _setError('Budget not found');
      return false;
    }

    final updatedBudget = budget.copyWith(
      isActive: !budget.isActive,
      updatedAt: DateTime.now(),
    );
    
    return await updateBudget(updatedBudget);
  }

  // Reset budget spent amount
  Future<bool> resetBudgetSpent(String budgetId) async {
    final budget = getBudgetById(budgetId);
    if (budget == null) {
      _setError('Budget not found');
      return false;
    }

    final updatedBudget = budget.copyWith(
      spent: 0.0,
      updatedAt: DateTime.now(),
    );
    
    return await updateBudget(updatedBudget);
  }

  // Process a new transaction and update related budgets
  Future<void> processTransaction(Transaction transaction) async {
    if (!transaction.isExpense) return;

    try {
      // Find all budgets that match this transaction's category
      final matchingBudgets = _budgets.where((b) => 
        b.isActive && 
        (b.category.toLowerCase() == transaction.category.toLowerCase() ||
         b.tags.any((tag) => tag.toLowerCase() == transaction.category.toLowerCase()))
      ).toList();
      
      if (matchingBudgets.isNotEmpty) {
        for (var budget in matchingBudgets) {
          final newSpent = budget.spent + transaction.amount;
          final updatedBudget = budget.copyWith(
            spent: newSpent,
            updatedAt: DateTime.now(),
          );
          
          await updateBudget(updatedBudget);
          
          // Check if this transaction puts the budget over limit
          if (updatedBudget.isOverBudget) {
            _sendBudgetAlert(updatedBudget);
          } else if (updatedBudget.percentageUsed >= 0.8) {
            // Send warning when 80% of budget is used
            _sendBudgetWarning(updatedBudget);
          }
        }
      } else {
        // Use AI to suggest a budget category if no match found
        try {
          final suggestedCategory = await _aiService.suggestCategoryForTransaction(transaction);
          if (suggestedCategory != null && suggestedCategory.isNotEmpty) {
            final matchingBudgetsByAI = _budgets.where((b) => 
              b.isActive && 
              (b.category.toLowerCase() == suggestedCategory.toLowerCase() ||
               b.tags.any((tag) => tag.toLowerCase() == suggestedCategory.toLowerCase()))
            ).toList();
            
            if (matchingBudgetsByAI.isNotEmpty) {
              for (var budget in matchingBudgetsByAI) {
                final newSpent = budget.spent + transaction.amount;
                final updatedBudget = budget.copyWith(
                  spent: newSpent,
                  updatedAt: DateTime.now(),
                );
                
                await updateBudget(updatedBudget);
                
                if (updatedBudget.isOverBudget) {
                  _sendBudgetAlert(updatedBudget);
                } else if (updatedBudget.percentageUsed >= 0.8) {
                  _sendBudgetWarning(updatedBudget);
                }
              }
            }
          }
        } catch (e) {
          print('Error getting AI category suggestion: $e');
        }
      }
    } catch (e) {
      print('Error processing transaction for budgets: $e');
    }
  }

  // Process transaction removal (when transaction is deleted)
  Future<void> processTransactionRemoval(Transaction transaction) async {
    if (!transaction.isExpense) return;

    try {
      // Find all budgets that match this transaction's category
      final matchingBudgets = _budgets.where((b) => 
        b.isActive && 
        (b.category.toLowerCase() == transaction.category.toLowerCase() ||
         b.tags.any((tag) => tag.toLowerCase() == transaction.category.toLowerCase()))
      ).toList();
      
      for (var budget in matchingBudgets) {
        final newSpent = (budget.spent - transaction.amount).clamp(0.0, double.infinity);
        final updatedBudget = budget.copyWith(
          spent: newSpent,
          updatedAt: DateTime.now(),
        );
        
        await updateBudget(updatedBudget);
      }
    } catch (e) {
      print('Error processing transaction removal for budgets: $e');
    }
  }

  // Send budget alerts for overspending
  void _sendBudgetAlert(Budget budget) {
    try {
      _notificationService.showBudgetAlert(
        budget.category, 
        budget.spent, 
        budget.amount
      );
    } catch (e) {
      print('Error sending budget alert: $e');
    }
  }

  // Send budget warning when approaching limit
  void _sendBudgetWarning(Budget budget) {
    try {
      _notificationService.showTransactionNotification(
        'Budget Warning',
        'You\'ve used ${(budget.percentageUsed * 100).toInt()}% of your ${budget.category} budget'
      );
    } catch (e) {
      print('Error sending budget warning: $e');
    }
  }

  // Get AI-powered budget insights
  Future<List<String>> getBudgetInsights() async {
    try {
      final insights = await _aiService.generateBudgetInsights(_budgets);
      return insights.isNotEmpty ? insights : _getDefaultInsights();
    } catch (e) {
      print('Error getting budget insights: $e');
      return _getDefaultInsights();
    }
  }

  // Get default insights when AI service fails
  List<String> _getDefaultInsights() {
    final insights = <String>[];
    
    if (_budgets.isEmpty) {
      insights.add('Create your first budget to start tracking your expenses!');
      return insights;
    }

    // Overall spending insight
    if (overallPercentage > 1.0) {
      insights.add('You\'re overspending by ${((overallPercentage - 1) * 100).toInt()}% this period.');
    } else if (overallPercentage > 0.8) {
      insights.add('You\'ve used ${(overallPercentage * 100).toInt()}% of your total budget. Be careful!');
    } else if (overallPercentage > 0.5) {
      insights.add('You\'re halfway through your budget. You\'re doing well!');
    } else {
      insights.add('Great job! You\'re staying within your budget limits.');
    }

    // Highest spending category insight
    if (highestSpendingCategory != 'None') {
      insights.add('Your highest spending category is $highestSpendingCategory.');
    }

    // Most consumed budget insight
    final mostConsumed = mostConsumedBudget;
    if (mostConsumed != null && mostConsumed.percentageUsed > 0.8) {
      insights.add('Your ${mostConsumed.category} budget is ${(mostConsumed.percentageUsed * 100).toInt()}% used.');
    }

    return insights;
  }

  // Get AI-recommended budgets based on past transactions
  Future<List<Budget>> getRecommendedBudgets() async {
    try {
      return await _aiService.recommendBudgets();
    } catch (e) {
      print('Error getting recommended budgets: $e');
      return [];
    }
  }

  // Send daily summary notification
  Future<void> sendDailySummary() async {
    try {
      final dailySummary = await _aiService.generateDailySummary(_budgets);
      
      if (dailySummary.isNotEmpty) {
        _notificationService.showTransactionNotification(
          'Daily Budget Summary',
          dailySummary
        );
      }
    } catch (e) {
      print('Error sending daily summary: $e');
    }
  }

  // Reset all budgets for new period
  Future<void> resetAllBudgets() async {
    _setLoading(true);
    try {
      final List<Budget> updatedBudgets = [];
      
      for (var budget in _budgets) {
        if (budget.isActive) {
          final resetBudget = budget.copyWith(
            spent: 0.0,
            updatedAt: DateTime.now(),
          );
          updatedBudgets.add(resetBudget);
        } else {
          updatedBudgets.add(budget);
        }
      }
      
      _budgets.clear();
      _budgets.addAll(updatedBudgets);
      
      // Save to local storage
      await _storageService.saveBudgets(_budgets);
      
      // Update all in Appwrite
      for (var budget in updatedBudgets.where((b) => b.spent == 0.0)) {
        try {
          await _appwriteService.updateBudget(budget);
        } catch (e) {
          print('Error updating budget ${budget.id} in Appwrite: $e');
        }
      }
      
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to reset budgets: $e');
    }
  }

  // Clear all budgets (for testing or reset purposes)
  Future<void> clearAllBudgets() async {
    _setLoading(true);
    try {
      // Delete from Appwrite first
      for (var budget in _budgets) {
        try {
          await _appwriteService.deleteBudget(budget.id);
        } catch (e) {
          print('Error deleting budget ${budget.id} from Appwrite: $e');
        }
      }
      
      _budgets.clear();
      await _storageService.saveBudgets(_budgets);
      
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to clear budgets: $e');
    }
  }

  // Get spending summary for a specific period
  Map<String, double> getSpendingSummary([BudgetPeriod? period]) {
    final budgetsToAnalyze = period != null 
        ? getBudgetsByPeriod(period)
        : activeBudgets;
    
    final summary = <String, double>{};
    
    for (var budget in budgetsToAnalyze) {
      summary[budget.category] = budget.spent;
    }
    
    return summary;
  }

  // Get over-budget categories
  List<Budget> get overBudgetCategories {
    return _budgets.where((b) => b.isActive && b.isOverBudget).toList();
  }

  // Get under-budget categories
  List<Budget> get underBudgetCategories {
    return _budgets.where((b) => b.isActive && !b.isOverBudget && b.percentageUsed < 1.0).toList();
  }

  // Check if any budget is over limit
  bool get hasOverBudgetCategories => overBudgetCategories.isNotEmpty;

  // Get total over-budget amount
  double get totalOverBudgetAmount {
    return overBudgetCategories.fold(0.0, (sum, b) => sum + (b.spent - b.amount));
  }

  // Utility method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _hasError = false;
      _errorMessage = '';
    }
    notifyListeners();
  }

  // Utility method to set error state
  void _setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}