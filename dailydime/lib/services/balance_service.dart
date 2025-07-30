// lib/services/balance_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceService {
  static final BalanceService instance = BalanceService._internal();
  BalanceService._internal();
  
  // Stream controller for balance updates
  final _balanceStreamController = StreamController<double>.broadcast();
  Stream<double> get balanceStream => _balanceStreamController.stream;
  
  // Key for storing balance in SharedPreferences
  static const String _balanceKey = 'mpesa_current_balance';
  static const String _balanceUpdateTimeKey = 'mpesa_balance_update_time';
  
  bool _isInitialized = false;
  double _currentBalance = 0.0;
  DateTime _lastUpdateTime = DateTime(2000); // Default old date
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBalance = prefs.getDouble(_balanceKey) ?? 0.0;
      
      final lastUpdateTimeMs = prefs.getInt(_balanceUpdateTimeKey) ?? 0;
      if (lastUpdateTimeMs > 0) {
        _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdateTimeMs);
      }
      
      _isInitialized = true;
      _balanceStreamController.add(_currentBalance);
      
      debugPrint('BalanceService initialized: Current balance is ${_currentBalance.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('Error initializing BalanceService: $e');
    }
  }
  
  // Get the current balance - now returns Future<double>
  Future<double> getCurrentBalance() async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }
    return _currentBalance;
  }
  
  // If you still need synchronous access, keep this method
  double getCurrentBalanceSync() {
    return _currentBalance;
  }
  
  // Get the time of last balance update
  DateTime getLastUpdateTime() {
    return _lastUpdateTime;
  }
  
  // Update the balance from a transaction
  Future<void> updateBalance(double newBalance, DateTime updateTime) async {
    // Only update if the new balance time is more recent than our current one
    if (updateTime.isAfter(_lastUpdateTime) && newBalance > 0) {
      _currentBalance = newBalance;
      _lastUpdateTime = updateTime;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_balanceKey, _currentBalance);
        await prefs.setInt(_balanceUpdateTimeKey, _lastUpdateTime.millisecondsSinceEpoch);
        
        // Notify listeners
        _balanceStreamController.add(_currentBalance);
        debugPrint('Balance updated to ${_currentBalance.toStringAsFixed(2)}');
      } catch (e) {
        debugPrint('Error saving updated balance: $e');
      }
    }
  }
  
  // Manual balance update
  Future<void> setBalance(double balance, DateTime updateTime) async {
    await updateBalance(balance, updateTime);
  }
  
  // Check if balance is stale (older than 7 days)
  bool isBalanceStale() {
    final now = DateTime.now();
    return now.difference(_lastUpdateTime).inDays > 7;
  }
  
  // Get formatted balance with currency
  String getFormattedBalance() {
    return 'KSh ${_currentBalance.toStringAsFixed(2)}';
  }
  
  // Close streams when done
  void dispose() {
    _balanceStreamController.close();
  }
}