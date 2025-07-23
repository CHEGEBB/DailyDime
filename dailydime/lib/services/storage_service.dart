// lib/services/storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  
  StorageService._internal();
  
  late Box<Transaction> _transactionsBox;
  late Box<double> _balanceBox;
  
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
    
    // Open boxes
    _transactionsBox = await Hive.openBox<Transaction>('transactions');
    _balanceBox = await Hive.openBox<double>('balance');
    
    _isInitialized = true;
  }
  
  // Transaction operations
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
  
  // Balance operations
  Future<void> updateBalance(double newBalance) async {
    await _ensureInitialized();
    await _balanceBox.put('current_balance', newBalance);
  }
  
  Future<double> getCurrentBalance() async {
    await _ensureInitialized();
    return _balanceBox.get('current_balance') ?? 0.0;
  }
  
  // Delete operations
  Future<void> deleteTransaction(String id) async {
    await _ensureInitialized();
    await _transactionsBox.delete(id);
  }
  
  Future<void> clearAllTransactions() async {
    await _ensureInitialized();
    await _transactionsBox.clear();
  }
  
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  Future<void> close() async {
    await _transactionsBox.close();
    await _balanceBox.close();
    _isInitialized = false;
  }
}

// Hive Adapters
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