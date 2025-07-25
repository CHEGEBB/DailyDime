// lib/providers/budget_provider.dart
import 'package:flutter/material.dart';
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/budget_ai_service.dart';
import 'package:dailydime/services/notification_service.dart';
import 'package:dailydime/config/app_config.dart';

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
  List<Budget> get budgets => _budgets;
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
  double get totalBudgetAmount => _budgets.fold(0, (sum, b) => sum + (b.isActive ? b.amount : 0));
  double get totalSpent => _budgets.fold(0, (sum, b) => sum + (b.isActive ? b.spent : 0));
  double get totalRemaining => totalBudgetAmount - totalSpent;
  double get overallPercentage => totalBudgetAmount > 0 ? (totalSpent / totalBudgetAmount) : 0;

  // Category with highest spending
  String get highestSpendingCategory {
    if (_budgets.isEmpty) return 'None';
    
    final categorySpending = <String, double>{};
    for (var budget in _budgets) {
      if (budget.isActive) {
        categorySpending[budget.category] = (categorySpending[budget.category] ?? 0) + budget.spent;
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
    
    return _budgets
        .where((b) => b.isActive)
        .reduce((a, b) => a.percentageUsed > b.percentageUsed ? a : b);
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
          await _appwriteService.createBudget(budget);
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
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        _budgets[index] = budget;
        notifyListeners();
        
        // Save to local storage
        await _storageService.saveBudgets(_budgets);
        
        // Update in Appwrite
        try {
          await _appwriteService.updateBudget(budget);
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

  // Process a new transaction and update related budgets
  Future<void> processTransaction(Transaction transaction) async {
    if (transaction.isExpense) {
      // Find all budgets that match this transaction's category
      final matchingBudgets = _budgets.where((b) => 
        b.isActive && 
        (b.category.toLowerCase() == transaction.category.toLowerCase() ||
         b.tags.contains(transaction.category.toLowerCase()))
      ).toList();
      
      if (matchingBudgets.isNotEmpty) {
        for (var budget in matchingBudgets) {
          final newSpent = budget.spent + transaction.amount;
          await updateBudget(budget.copyWith(spent: newSpent));
          
          // Check if this transaction puts the budget over limit
          if (budget.isOverBudget) {
            _sendBudgetAlert(budget);
          }
        }
      } else {
        // Use AI to suggest a budget category if no match found
        final suggestedCategory = await _aiService.suggestCategoryForTransaction(transaction);
        if (suggestedCategory != null) {
          final matchingBudgetsByAI = _budgets.where((b) => 
            b.isActive && 
            (b.category.toLowerCase() == suggestedCategory.toLowerCase() ||
             b.tags.contains(suggestedCategory.toLowerCase()))
          ).toList();
          
          if (matchingBudgetsByAI.isNotEmpty) {
            for (var budget in matchingBudgetsByAI) {
              final newSpent = budget.spent + transaction.amount;
              await updateBudget(budget.copyWith(spent: newSpent));
              
              if (budget.isOverBudget) {
                _sendBudgetAlert(budget);
              }
            }
          }
        }
      }
    }
  }

  // Send budget alerts for overspending
  void _sendBudgetAlert(Budget budget) {
    _notificationService.showBudgetAlert(
      budget.category, 
      budget.spent, 
      budget.amount
    );
  }

  // Get AI-powered budget insights
  Future<List<String>> getBudgetInsights() async {
    try {
      return await _aiService.generateBudgetInsights(_budgets);
    } catch (e) {
      print('Error getting budget insights: $e');
      return [
        'Try reducing spending in ${highestSpendingCategory} to stay on track.',
        'You\'ve used ${(overallPercentage * 100).toInt()}% of your total budget.'
      ];
    }
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
      
      _notificationService.showTransactionNotification(
        'Daily Budget Summary',
        dailySummary
      );
    } catch (e) {
      print('Error sending daily summary: $e');
    }
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
}