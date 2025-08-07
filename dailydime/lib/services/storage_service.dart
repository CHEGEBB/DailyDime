// lib/services/storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Import the BalanceHistory class
class BalanceHistory {
  final double balance;
  final DateTime timestamp;
  final String? transactionId;
  final String source; // 'sms', 'manual', 'calculated'

  BalanceHistory({
    required this.balance,
    required this.timestamp,
    this.transactionId,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'timestamp': timestamp.toIso8601String(),
    'transactionId': transactionId,
    'source': source,
  };

  factory BalanceHistory.fromJson(Map<String, dynamic> json) => BalanceHistory(
    balance: json['balance']?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(json['timestamp']),
    transactionId: json['transactionId'],
    source: json['source'] ?? 'unknown',
  );
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  
  StorageService._internal();
  
  late Box<Transaction> _transactionsBox;
  late Box<double> _balanceBox;
  late Box _budgetsBox; // Using dynamic box for budgets
  late Box _balanceMetadataBox; // For balance metadata
  late Box _balanceHistoryBox; // For balance history
  late Box _generalDataBox; // For general data storage (insights, tips, etc.)
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ColorAdapter());
    }
    
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(IconDataAdapter());
    }
    
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(BudgetPeriodAdapter());
    }
    
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BalanceHistoryAdapter());
    }
    
    // Open boxes
    _transactionsBox = await Hive.openBox<Transaction>('transactions');
    _balanceBox = await Hive.openBox<double>('balance');
    _budgetsBox = await Hive.openBox('budgets');
    _balanceMetadataBox = await Hive.openBox('balance_metadata');
    _balanceHistoryBox = await Hive.openBox('balance_history');
    _generalDataBox = await Hive.openBox('general_data');
    
    _isInitialized = true;
  }
  
  // GENERAL DATA STORAGE OPERATIONS
  
  /// Save any data with a key-value pair
  Future<void> saveData(String key, dynamic value) async {
    await _ensureInitialized();
    try {
      await _generalDataBox.put(key, value);
    } catch (e) {
      print('Error saving data for key $key: $e');
      throw Exception('Failed to save data: $e');
    }
  }
  
  /// Get data by key
  Future<dynamic> getData(String key) async {
    await _ensureInitialized();
    try {
      return _generalDataBox.get(key);
    } catch (e) {
      print('Error getting data for key $key: $e');
      return null;
    }
  }
  
  /// Delete data by key
  Future<void> deleteData(String key) async {
    await _ensureInitialized();
    try {
      await _generalDataBox.delete(key);
    } catch (e) {
      print('Error deleting data for key $key: $e');
      throw Exception('Failed to delete data: $e');
    }
  }
  
  /// Check if key exists
  Future<bool> hasData(String key) async {
    await _ensureInitialized();
    return _generalDataBox.containsKey(key);
  }
  
  /// Get all keys
  Future<List<String>> getAllKeys() async {
    await _ensureInitialized();
    return _generalDataBox.keys.cast<String>().toList();
  }
  
  /// Clear all general data
  Future<void> clearGeneralData() async {
    await _ensureInitialized();
    await _generalDataBox.clear();
  }
  
  // INSIGHTS AND TIPS SPECIFIC METHODS
  
  /// Save insights data
  Future<void> saveInsights(String insightsJson) async {
    await saveData('insights_cache', insightsJson);
  }
  
  /// Get insights data
  Future<String?> getInsights() async {
    final data = await getData('insights_cache');
    return data?.toString();
  }
  
  /// Save money tips data
  Future<void> saveMoneyTips(String tipsJson) async {
    await saveData('money_tips_cache', tipsJson);
  }
  
  /// Get money tips data
  Future<String?> getMoneyTips() async {
    final data = await getData('money_tips_cache');
    return data?.toString();
  }
  
  /// Save insights generation metadata
  Future<void> saveInsightsMetadata(Map<String, dynamic> metadata) async {
    await saveData('insights_metadata', metadata);
  }
  
  /// Get insights generation metadata
  Future<Map<String, dynamic>?> getInsightsMetadata() async {
    final data = await getData('insights_metadata');
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
  
  /// Clear insights cache
  Future<void> clearInsightsCache() async {
    await deleteData('insights_cache');
    await deleteData('money_tips_cache');
    await deleteData('insights_metadata');
  }
  
  // BUDGET OPERATIONS
  
  // Load budgets from local storage
  Future<List<Budget>> loadBudgets() async {
    await _ensureInitialized();
    
    final List<Budget> budgets = [];
    
    try {
      final budgetMaps = _budgetsBox.values.toList();
      
      for (final budgetData in budgetMaps) {
        // Convert the dynamic Map to Budget object
        if (budgetData is Map) {
          try {
            final budget = Budget.fromMap(Map<String, dynamic>.from(budgetData));
            budgets.add(budget);
          } catch (e) {
            print('Error parsing budget: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading budgets: $e');
    }
    
    return budgets;
  }
  
  // Save a list of budgets to local storage
  Future<void> saveBudgets(List<Budget> budgets) async {
    await _ensureInitialized();
    
    try {
      // Clear existing budgets
      await _budgetsBox.clear();
      
      // Save each budget as a map
      for (final budget in budgets) {
        await _budgetsBox.put(budget.id, budget.toMap());
      }
    } catch (e) {
      print('Error saving budgets: $e');
      throw Exception('Failed to save budgets: $e');
    }
  }
  
  // Save a single budget
  Future<void> saveBudget(Budget budget) async {
    await _ensureInitialized();
    try {
      await _budgetsBox.put(budget.id, budget.toMap());
    } catch (e) {
      print('Error saving budget: $e');
      throw Exception('Failed to save budget: $e');
    }
  }
  
  // Delete a budget by ID
  Future<void> deleteBudget(String budgetId) async {
    await _ensureInitialized();
    try {
      await _budgetsBox.delete(budgetId);
    } catch (e) {
      print('Error deleting budget: $e');
      throw Exception('Failed to delete budget: $e');
    }
  }
  
  // Get budget by ID
  Future<Budget?> getBudgetById(String budgetId) async {
    await _ensureInitialized();
    try {
      final budgetData = _budgetsBox.get(budgetId);
      if (budgetData != null && budgetData is Map) {
        return Budget.fromMap(Map<String, dynamic>.from(budgetData));
      }
    } catch (e) {
      print('Error getting budget by ID: $e');
    }
    return null;
  }
  
  // TRANSACTION OPERATIONS
  Future<void> saveTransaction(Transaction transaction) async {
    await _ensureInitialized();
    await _transactionsBox.put(transaction.id, transaction);
  }
  
  Future<void> saveTransactions(List<Transaction> transactions) async {
    await _ensureInitialized();
    final Map<String, Transaction> transactionsMap = {
      for (var transaction in transactions) transaction.id: transaction
    };
    await _transactionsBox.putAll(transactionsMap);
  }
  
  Future<List<Transaction>> getTransactions() async {
    await _ensureInitialized();
    return _transactionsBox.values.toList();
  }
  
  // Added this method to match the one used in BudgetAIService
  Future<List<Transaction>> loadTransactions() async {
    return getTransactions();
  }
  
  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    await _ensureInitialized();
    return _transactionsBox.values
        .where((transaction) => transaction.category == category)
        .toList();
  }
  
  Future<List<Transaction>> getRecentTransactions(int limit) async {
    await _ensureInitialized();
    final transactions = _transactionsBox.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date)); // Sort by date (newest first)
    return transactions.take(limit).toList();
  }
  
  Future<List<Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    await _ensureInitialized();
    return _transactionsBox.values
        .where((transaction) => 
            transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }
  
  Future<Transaction?> getTransactionById(String id) async {
    await _ensureInitialized();
    return _transactionsBox.get(id);
  }
  
  Future<List<Transaction>> getTransactionsByMpesaCode(String mpesaCode) async {
    await _ensureInitialized();
    return _transactionsBox.values
        .where((transaction) => transaction.mpesaCode == mpesaCode)
        .toList();
  }
  
  // BALANCE OPERATIONS
  Future<void> updateBalance(double newBalance) async {
    await _ensureInitialized();
    await _balanceBox.put('current_balance', newBalance);
  }
  
  Future<double> getCurrentBalance() async {
    await _ensureInitialized();
    return _balanceBox.get('current_balance') ?? 0.0;
  }
  
  // Balance metadata operations
  Future<void> saveBalanceMetadata(Map<String, dynamic> metadata) async {
    await _ensureInitialized();
    
    try {
      // Save each metadata entry
      for (final entry in metadata.entries) {
        if (entry.value is DateTime) {
          await _balanceMetadataBox.put(entry.key, entry.value.toIso8601String());
        } else {
          await _balanceMetadataBox.put(entry.key, entry.value);
        }
      }
    } catch (e) {
      print('Error saving balance metadata: $e');
      throw Exception('Failed to save balance metadata: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getBalanceMetadata() async {
    await _ensureInitialized();
    
    try {
      if (_balanceMetadataBox.isEmpty) return null;
      
      final Map<String, dynamic> metadata = {};
      
      for (final key in _balanceMetadataBox.keys) {
        final value = _balanceMetadataBox.get(key);
        
        // Handle DateTime conversion
        if (key == 'lastUpdate' && value is String) {
          try {
            metadata[key] = DateTime.parse(value);
          } catch (e) {
            metadata[key] = value;
          }
        } else {
          metadata[key] = value;
        }
      }
      
      return metadata;
    } catch (e) {
      print('Error getting balance metadata: $e');
      return null;
    }
  }
  
  // Balance history operations
  Future<void> saveBalanceHistory(List<BalanceHistory> history) async {
    await _ensureInitialized();
    
    try {
      // Clear existing history
      await _balanceHistoryBox.clear();
      
      // Save each history record with a unique key
      for (int i = 0; i < history.length; i++) {
        await _balanceHistoryBox.put('history_$i', history[i].toJson());
      }
    } catch (e) {
      print('Error saving balance history: $e');
      throw Exception('Failed to save balance history: $e');
    }
  }
  
  Future<List<BalanceHistory>> getBalanceHistory() async {
    await _ensureInitialized();
    
    try {
      final List<BalanceHistory> history = [];
      
      final historyMaps = _balanceHistoryBox.values.toList();
      
      for (final historyData in historyMaps) {
        if (historyData is Map) {
          try {
            final historyRecord = BalanceHistory.fromJson(
              Map<String, dynamic>.from(historyData)
            );
            history.add(historyRecord);
          } catch (e) {
            print('Error parsing balance history record: $e');
          }
        }
      }
      
      // Sort by timestamp (newest first)
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return history;
    } catch (e) {
      print('Error loading balance history: $e');
      return [];
    }
  }
  
  Future<void> addBalanceHistoryRecord(BalanceHistory record) async {
    await _ensureInitialized();
    
    try {
      // Get current history
      final currentHistory = await getBalanceHistory();
      
      // Add new record
      currentHistory.add(record);
      
      // Keep only last 100 records
      if (currentHistory.length > 100) {
        currentHistory.removeRange(0, currentHistory.length - 100);
      }
      
      // Save updated history
      await saveBalanceHistory(currentHistory);
    } catch (e) {
      print('Error adding balance history record: $e');
      throw Exception('Failed to add balance history record: $e');
    }
  }
  
  Future<void> clearBalanceHistory() async {
    await _ensureInitialized();
    await _balanceHistoryBox.clear();
  }
  
  // DELETE OPERATIONS
  Future<void> deleteTransaction(String id) async {
    await _ensureInitialized();
    await _transactionsBox.delete(id);
  }
  
  Future<void> clearAllTransactions() async {
    await _ensureInitialized();
    await _transactionsBox.clear();
  }
  
  Future<void> clearAllBudgets() async {
    await _ensureInitialized();
    await _budgetsBox.clear();
  }
  
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _transactionsBox.clear();
    await _balanceBox.clear();
    await _budgetsBox.clear();
    await _balanceMetadataBox.clear();
    await _balanceHistoryBox.clear();
    await _generalDataBox.clear();
  }
  
  // UTILITY METHODS
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  Future<void> close() async {
    await _transactionsBox.close();
    await _balanceBox.close();
    await _budgetsBox.close();
    await _balanceMetadataBox.close();
    await _balanceHistoryBox.close();
    await _generalDataBox.close();
    _isInitialized = false;
  }
  
  // Statistics and analytics methods
  Future<Map<String, double>> getTransactionsByCategoryTotals({DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    List<Transaction> transactions = await getTransactions();
    
    // Filter by date range if provided
    if (startDate != null && endDate != null) {
      transactions = transactions.where((transaction) =>
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }
    
    final Map<String, double> categoryTotals = {};
    
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return categoryTotals;
  }
  
  Future<double> getTotalExpensesForPeriod(DateTime startDate, DateTime endDate) async {
    await _ensureInitialized();
    
    final transactions = await getTransactions();
    double total = 0.0;
    
    for (final transaction in transactions) {
      if (transaction.isExpense && 
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))) {
        total += transaction.amount;
      }
    }
    
    return total;
  }
  
  Future<double> getTotalIncomeForPeriod(DateTime startDate, DateTime endDate) async {
    await _ensureInitialized();
    
    final transactions = await getTransactions();
    double total = 0.0;
    
    for (final transaction in transactions) {
      if (!transaction.isExpense && 
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))) {
        total += transaction.amount;
      }
    }
    
    return total;
  }
  
  Future<Map<String, double>> getMonthlySpendingSummary(int year, int month) async {
    await _ensureInitialized();
    
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    
    final transactions = await getTransactionsByDateRange(startDate, endDate);
    
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        totalExpenses += transaction.amount;
      } else {
        totalIncome += transaction.amount;
      }
    }
    
    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'savings': totalIncome - totalExpenses,
    };
  }
  
  Future<List<Map<String, dynamic>>> getTopSpendingCategories(int limit, {DateTime? startDate, DateTime? endDate}) async {
    final categoryTotals = await getTransactionsByCategoryTotals(startDate: startDate, endDate: endDate);
    
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories.take(limit).map((entry) => {
      'category': entry.key,
      'amount': entry.value,
    }).toList();
  }
  
  Future<double> getAverageTransactionAmount({bool expensesOnly = true, DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    List<Transaction> transactions = await getTransactions();
    
    // Filter by date range if provided
    if (startDate != null && endDate != null) {
      transactions = transactions.where((transaction) =>
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }
    
    // Filter by expense type if needed
    if (expensesOnly) {
      transactions = transactions.where((t) => t.isExpense).toList();
    }
    
    if (transactions.isEmpty) return 0.0;
    
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    return total / transactions.length;
  }
  
  Future<int> getTransactionCount({DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    if (startDate == null || endDate == null) {
      return _transactionsBox.length;
    }
    
    final transactions = await getTransactionsByDateRange(startDate, endDate);
    return transactions.length;
  }
  
  // Export/Import methods
  Future<Map<String, dynamic>> exportAllData() async {
    await _ensureInitialized();
    
    return {
      'transactions': (await getTransactions()).map((t) => t.toJson()).toList(),
      'budgets': (await loadBudgets()).map((b) => b.toMap()).toList(),
      'balance': await getCurrentBalance(),
      'balanceMetadata': await getBalanceMetadata(),
      'balanceHistory': (await getBalanceHistory()).map((h) => h.toJson()).toList(),
      'insights': await getInsights(),
      'moneyTips': await getMoneyTips(),
      'insightsMetadata': await getInsightsMetadata(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }
  
  Future<void> importAllData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      // Clear existing data
      await clearAllData();
      
      // Import transactions
      if (data['transactions'] != null) {
        final transactions = (data['transactions'] as List)
            .map((t) => Transaction.fromJson(Map<String, dynamic>.from(t)))
            .toList();
        await saveTransactions(transactions);
      }
      
      // Import budgets
      if (data['budgets'] != null) {
        final budgets = (data['budgets'] as List)
            .map((b) => Budget.fromMap(Map<String, dynamic>.from(b)))
            .toList();
        await saveBudgets(budgets);
      }
      
      // Import balance
      if (data['balance'] != null) {
        await updateBalance(data['balance'].toDouble());
      }
      
      // Import balance metadata
      if (data['balanceMetadata'] != null) {
        await saveBalanceMetadata(Map<String, dynamic>.from(data['balanceMetadata']));
      }
      
      // Import balance history
      if (data['balanceHistory'] != null) {
        final history = (data['balanceHistory'] as List)
            .map((h) => BalanceHistory.fromJson(Map<String, dynamic>.from(h)))
            .toList();
        await saveBalanceHistory(history);
      }
      
      // Import insights
      if (data['insights'] != null) {
        await saveInsights(data['insights'].toString());
      }
      
      // Import money tips
      if (data['moneyTips'] != null) {
        await saveMoneyTips(data['moneyTips'].toString());
      }
      
      // Import insights metadata
      if (data['insightsMetadata'] != null) {
        await saveInsightsMetadata(Map<String, dynamic>.from(data['insightsMetadata']));
      }
      
    } catch (e) {
      print('Error importing data: $e');
      throw Exception('Failed to import data: $e');
    }
  }
  
  // Database maintenance methods
  Future<void> compactDatabase() async {
    await _ensureInitialized();
    
    try {
      await _transactionsBox.compact();
      await _balanceBox.compact();
      await _budgetsBox.compact();
      await _balanceMetadataBox.compact();
      await _balanceHistoryBox.compact();
      await _generalDataBox.compact();
    } catch (e) {
      print('Error compacting database: $e');
    }
  }
  
  Future<Map<String, int>> getDatabaseStats() async {
    await _ensureInitialized();
    
    return {
      'transactions': _transactionsBox.length,
      'budgets': _budgetsBox.length,
      'balanceHistory': _balanceHistoryBox.length,
      'generalData': _generalDataBox.length,
      'balanceMetadata': _balanceMetadataBox.length,
    };
  }
}

// HIVE ADAPTERS

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;
  
  @override
  Transaction read(BinaryReader reader) {
    return Transaction(
      id: reader.read(),
      title: reader.read(),
      amount: reader.read(),
      date: reader.read(),
      category: reader.read(),
      isExpense: reader.read(),
      icon: reader.read(),
      color: reader.read(),
      mpesaCode: reader.read(),
      isSms: reader.read(),
      rawSms: reader.read(),
      sender: reader.read(),
      recipient: reader.read(),
      agent: reader.read(),
      business: reader.read(),
      balance: reader.read(),
    );
  }
  
  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.amount);
    writer.write(obj.date);
    writer.write(obj.category);
    writer.write(obj.isExpense);
    writer.write(obj.icon);
    writer.write(obj.color);
    writer.write(obj.mpesaCode);
    writer.write(obj.isSms);
    writer.write(obj.rawSms);
    writer.write(obj.sender);
    writer.write(obj.recipient);
    writer.write(obj.agent);
    writer.write(obj.business);
    writer.write(obj.balance);
  }
}

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 1;
  
  @override
  Color read(BinaryReader reader) {
    return Color(reader.readInt());
  }
  
  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.value);
  }
}

class IconDataAdapter extends TypeAdapter<IconData> {
  @override
  final int typeId = 2;
  
  @override
  IconData read(BinaryReader reader) {
    return IconData(
      reader.readInt(),
      fontFamily: reader.readString(),
      fontPackage: reader.readString(),
    );
  }
  
  @override
  void write(BinaryWriter writer, IconData obj) {
    writer.writeInt(obj.codePoint);
    writer.writeString(obj.fontFamily ?? '');
    writer.writeString(obj.fontPackage ?? '');
  }
}

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 3;
  
  @override
  BudgetPeriod read(BinaryReader reader) {
    return BudgetPeriod.values[reader.readInt()];
  }
  
  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    writer.writeInt(obj.index);
  }
}

class BalanceHistoryAdapter extends TypeAdapter<BalanceHistory> {
  @override
  final int typeId = 4;
  
  @override
  BalanceHistory read(BinaryReader reader) {
    return BalanceHistory(
      balance: reader.readDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      transactionId: reader.readString().isEmpty ? null : reader.readString(),
      source: reader.readString(),
    );
  }
  
  @override
  void write(BinaryWriter writer, BalanceHistory obj) {
    writer.writeDouble(obj.balance);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeString(obj.transactionId ?? '');
    writer.writeString(obj.source);
  }
}

// Extensions for the StorageService to handle insights and tips
extension InsightsStorageExtension on StorageService {
  Future<void> saveInsights(String insightsJson) async {
    await saveData('insights_cache', insightsJson);
  }

  Future<String?> getInsights() async {
    return await getData('insights_cache');
  }

  Future<void> saveMoneyTips(String tipsJson) async {
    await saveData('money_tips_cache', tipsJson);
  }

  Future<String?> getMoneyTips() async {
    return await getData('money_tips_cache');
  }
}