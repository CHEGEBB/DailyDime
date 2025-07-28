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
    
    _isInitialized = true;
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
  
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _transactionsBox.clear();
    await _balanceBox.clear();
    await _budgetsBox.clear();
    await _balanceMetadataBox.clear();
    await _balanceHistoryBox.clear();
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
    _isInitialized = false;
  }
  
  // Statistics and analytics methods
  Future<Map<String, double>> getTransactionsByCategoryTotals() async {
    await _ensureInitialized();
    
    final transactions = await getTransactions();
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
  
  // Export/Import methods
  Future<Map<String, dynamic>> exportAllData() async {
    await _ensureInitialized();
    
    return {
      'transactions': (await getTransactions()).map((t) => t.toJson()).toList(),
      'budgets': (await loadBudgets()).map((b) => b.toMap()).toList(),
      'balance': await getCurrentBalance(),
      'balanceMetadata': await getBalanceMetadata(),
      'balanceHistory': (await getBalanceHistory()).map((h) => h.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
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
    } catch (e) {
      print('Error importing data: $e');
      throw Exception('Failed to import data: $e');
    }
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