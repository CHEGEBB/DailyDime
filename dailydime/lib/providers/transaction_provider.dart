// lib/providers/transaction_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/sms_service.dart';

class TransactionProvider with ChangeNotifier {
  final SmsService _smsService = SmsService();
  final StorageService _storageService = StorageService.instance;
  final AppwriteService _appwriteService = AppwriteService();
  
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  double _currentBalance = 0.0;
  bool _isLoading = true;
  String _filter = 'All';
  String _timeframe = 'This Month';
  Set<String> _selectedCategories = <String>{};
  
  // Available categories for filtering
  final List<String> _availableCategories = [
    'All Categories',
    'Food & Dining',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Transfer',
    'Balance',
    'Income',
    'Other'
  ];
  
  // Getters
  List<Transaction> get transactions => _transactions;
  List<Transaction> get filteredTransactions => _filteredTransactions;
  double get currentBalance => _currentBalance;
  bool get isLoading => _isLoading;
  String get filter => _filter;
  String get timeframe => _timeframe;
  Set<String> get selectedCategories => _selectedCategories;
  List<String> get availableCategories => _availableCategories;
  
  // Setter for selectedCategories
  set selectedCategories(Set<String> categories) {
    _selectedCategories = Set.from(categories);
    _applyFilters();
    notifyListeners();
  }
  
  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    // Initialize services
    await _storageService.initialize();
    await _appwriteService.initialize();
    
    // Load data
    await _loadTransactions();
    await _loadBalance();
    
    // Initialize SMS service and listen for new transactions
    final smsInitialized = await _smsService.initialize();
    if (smsInitialized) {
      _smsService.transactionStream.listen(_handleNewSmsTransaction);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Load all transactions from storage
  Future<void> _loadTransactions() async {
    try {
      // First load from local storage
      final localTransactions = await _storageService.getTransactions();
      
      // Then try to fetch from Appwrite if online
      try {
        final remoteTransactions = await _appwriteService.getTransactions();
        
        // Merge remote and local transactions, prioritizing remote
        final Map<String, Transaction> mergedMap = {};
        
        // Add local transactions first
        for (var transaction in localTransactions) {
          mergedMap[transaction.id] = transaction;
        }
        
        // Override with remote transactions
        for (var transaction in remoteTransactions) {
          mergedMap[transaction.id] = transaction;
        }
        
        _transactions = mergedMap.values.toList();
      } catch (e) {
        // If offline or error, use only local transactions
        _transactions = localTransactions;
      }
      
      // Sort by date (newest first)
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Apply current filter
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
      _filteredTransactions = [];
    }
  }
  
  // Load current balance
  Future<void> _loadBalance() async {
    try {
      _currentBalance = await _storageService.getCurrentBalance();
      
      // Try to update with the latest balance from SMS
      final balanceTransactions = _transactions
          .where((t) => t.category == 'Balance' && t.balance != null)
          .toList();
      
      if (balanceTransactions.isNotEmpty) {
        balanceTransactions.sort((a, b) => b.date.compareTo(a.date));
        _currentBalance = balanceTransactions.first.balance!;
        await _storageService.updateBalance(_currentBalance);
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
      _currentBalance = 0.0;
    }
  }
  
  // Handle new transaction from SMS
  void _handleNewSmsTransaction(Transaction transaction) async {
    // Add to list if not already present
    if (!_transactions.any((t) => t.id == transaction.id)) {
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Apply filters
      _applyFilters();
      
      // Update balance if it's a balance update
      if (transaction.category == 'Balance' && transaction.balance != null) {
        _currentBalance = transaction.balance!;
        await _storageService.updateBalance(_currentBalance);
      }
      
      notifyListeners();
    }
  }
  
  // Add a new transaction manually
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _storageService.saveTransaction(transaction);
      await _appwriteService.syncTransaction(transaction);
      
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Apply filters
      _applyFilters();
      
      // Update balance based on transaction type
      if (transaction.isExpense) {
        _currentBalance -= transaction.amount;
      } else {
        _currentBalance += transaction.amount;
      }
      
      await _storageService.updateBalance(_currentBalance);
      await _appwriteService.updateBalance(_currentBalance);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }
  
  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      final transaction = _transactions.firstWhere((t) => t.id == id);
      await _storageService.deleteTransaction(id);
      await _appwriteService.deleteTransaction(id);
      
      _transactions.removeWhere((t) => t.id == id);
      
      // Update balance based on deleted transaction
      if (transaction.isExpense) {
        _currentBalance += transaction.amount;
      } else {
        _currentBalance -= transaction.amount;
      }
      
      await _storageService.updateBalance(_currentBalance);
      await _appwriteService.updateBalance(_currentBalance);
      
      // Apply filters
      _applyFilters();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
  }
  
  // Set filter
  void setFilter(String filter) {
    _filter = filter;
    _applyFilters();
    notifyListeners();
  }
  
  // Set timeframe
  void setTimeframe(String timeframe) {
    _timeframe = timeframe;
    _applyFilters();
    notifyListeners();
  }
  
  // Toggle category selection
  void toggleCategorySelection(String category) {
    if (category == 'All Categories') {
      // If "All Categories" is selected, clear all other selections
      _selectedCategories.clear();
    } else {
      // Remove "All Categories" if it was selected
      _selectedCategories.remove('All Categories');
      
      // Toggle the selected category
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    }
    
    _applyFilters();
    notifyListeners();
  }
  
  // Clear all category selections
  void clearCategorySelections() {
    _selectedCategories.clear();
    _applyFilters();
    notifyListeners();
  }
  
  // Set selected categories
  void setSelectedCategories(Set<String> categories) {
    _selectedCategories = Set.from(categories);
    _applyFilters();
    notifyListeners();
  }
  
  // Check if a category is selected
  bool isCategorySelected(String category) {
    if (category == 'All Categories') {
      return _selectedCategories.isEmpty;
    }
    return _selectedCategories.contains(category);
  }
  
  // Get unique categories from transactions
  List<String> getTransactionCategories() {
    final categories = _transactions
        .map((t) => t.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return ['All Categories', ...categories];
  }
  
  // Apply filters to transactions
  void _applyFilters() {
    // Start with all transactions
    _filteredTransactions = List.from(_transactions);
    
    // Apply category filter (legacy filter)
    if (_filter != 'All') {
      if (_filter == 'Income') {
        _filteredTransactions = _filteredTransactions.where((t) => !t.isExpense).toList();
      } else if (_filter == 'Expense') {
        _filteredTransactions = _filteredTransactions.where((t) => t.isExpense).toList();
      } else if (_filter == 'Transfers') {
        _filteredTransactions = _filteredTransactions.where((t) => t.category == 'Transfer').toList();
      }
    }
    
    // Apply selected categories filter
    if (_selectedCategories.isNotEmpty && !_selectedCategories.contains('All Categories')) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        _selectedCategories.contains(t.category)
      ).toList();
    }
    
    // Apply timeframe filter
    final now = DateTime.now();
    if (_timeframe == 'Today') {
      final today = DateTime(now.year, now.month, now.day);
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAfter(today.subtract(const Duration(minutes: 1)))
      ).toList();
    } else if (_timeframe == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAfter(startOfWeekDate.subtract(const Duration(minutes: 1)))
      ).toList();
    } else if (_timeframe == 'This Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAfter(startOfMonth.subtract(const Duration(minutes: 1)))
      ).toList();
    } else if (_timeframe == 'Last Month') {
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAfter(startOfLastMonth.subtract(const Duration(minutes: 1))) && 
        t.date.isBefore(endOfLastMonth.add(const Duration(days: 1)))
      ).toList();
    } else if (_timeframe == 'Last 3 Months') {
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAfter(threeMonthsAgo.subtract(const Duration(minutes: 1)))
      ).toList();
    } else if (_timeframe == 'Last 6 Months') {
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAfter(sixMonthsAgo.subtract(const Duration(minutes: 1)))
      ).toList();
    } else if (_timeframe == 'This Year') {
      final startOfYear = DateTime(now.year, 1, 1);
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAfter(startOfYear.subtract(const Duration(minutes: 1)))
      ).toList();
    }
    // Custom timeframe handling would go here
  }
  
  // Refresh transactions from local storage and Appwrite
  Future<void> refreshTransactions() async {
    _isLoading = true;
    notifyListeners();
    
    await _loadTransactions();
    await _loadBalance();
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Get transactions for a specific category
  List<Transaction> getTransactionsByCategory(String category) {
    if (category == 'All Categories') {
      return _transactions;
    }
    return _transactions.where((t) => t.category == category).toList();
  }
  
  // Get total amount for selected categories
  double getTotalAmountForSelectedCategories() {
    if (_selectedCategories.isEmpty) {
      return _filteredTransactions.fold(0.0, (sum, t) => sum + t.amount);
    }
    
    return _filteredTransactions
        .where((t) => _selectedCategories.contains(t.category))
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  // Get expense total for selected categories
  double getExpenseTotalForSelectedCategories() {
    if (_selectedCategories.isEmpty) {
      return _filteredTransactions
          .where((t) => t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
    }
    
    return _filteredTransactions
        .where((t) => t.isExpense && _selectedCategories.contains(t.category))
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  // Get income total for selected categories
  double getIncomeTotalForSelectedCategories() {
    if (_selectedCategories.isEmpty) {
      return _filteredTransactions
          .where((t) => !t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
    }
    
    return _filteredTransactions
        .where((t) => !t.isExpense && _selectedCategories.contains(t.category))
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  // Apply filters (public method)
  void applyFilters() {
    _applyFilters();
    notifyListeners();
  }
  
  // Dispose
  @override
  void dispose() {
    _smsService.dispose();
    super.dispose();
  }
}