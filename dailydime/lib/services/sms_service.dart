// lib/services/sms_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart'; // Changed from telephony to another_telephony
import 'package:permission_handler/permission_handler.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/config/app_config.dart';

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  // This function runs in the background when SMS is received
  if (SmsService._isMpesaMessage(message)) {
    final transaction = SmsService._parseMpesaMessage(message);
    if (transaction != null) {
      // Store locally
      await StorageService.instance.saveTransaction(transaction);
      
      // Sync with Appwrite if connected
      try {
        final appwriteService = AppwriteService();
        await appwriteService.syncTransaction(transaction);
      } catch (e) {
        // Will sync later when app opens
      }
    }
  }
}

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();
  
  final Telephony _telephony = Telephony.instance;
  bool _isInitialized = false;
  final StreamController<Transaction> _transactionStreamController = 
      StreamController<Transaction>.broadcast();
  
  Stream<Transaction> get transactionStream => _transactionStreamController.stream;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Request SMS permissions
    final permissionStatus = await _requestSmsPermission();
    if (!permissionStatus) return false;
    
    // Set up SMS listener
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _processMessage(message);
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
    
    // Load historical messages on initialization
    await loadHistoricalMpesaMessages();
    
    _isInitialized = true;
    return true;
  }
  
  Future<bool> _requestSmsPermission() async {
    var status = await Permission.sms.status;
    
    if (status.isDenied) {
      status = await Permission.sms.request();
    }
    
    return status.isGranted;
  }
  
  void _processMessage(SmsMessage message) {
    if (_isMpesaMessage(message)) {
      final transaction = _parseMpesaMessage(message);
      if (transaction != null) {
        // Add to stream for UI updates
        _transactionStreamController.add(transaction);
        
        // Save locally
        StorageService.instance.saveTransaction(transaction);
        
        // Sync with Appwrite
        AppwriteService().syncTransaction(transaction);
      }
    }
  }
  
  Future<List<Transaction>> loadHistoricalMpesaMessages() async {
    List<Transaction> transactions = [];
    
    try {
      // Improved M-Pesa message filtering
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals('MPESA'),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)], // Sort by newest first
      );
      
      // Also get messages from M-PESA (sometimes it comes from different sender)
      final alternateMessages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals('M-PESA'),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      
      // Combine both message lists
      final allMessages = [...messages, ...alternateMessages];
      
      for (var message in allMessages) {
        final transaction = _parseMpesaMessage(message);
        if (transaction != null) {
          transactions.add(transaction);
          _transactionStreamController.add(transaction);
        }
      }
      
      // Remove duplicates and sort by date (newest first)
      final uniqueTransactions = <String, Transaction>{};
      for (var transaction in transactions) {
        uniqueTransactions[transaction.id] = transaction;
      }
      
      final finalTransactions = uniqueTransactions.values.toList();
      finalTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Save all to local storage
      await StorageService.instance.saveTransactions(finalTransactions);
      
      return finalTransactions;
      
    } catch (e) {
      debugPrint('Error loading historical M-Pesa messages: $e');
    }
    
    return transactions;
  }
  
  static bool _isMpesaMessage(SmsMessage message) {
    final address = message.address?.toUpperCase() ?? '';
    final body = message.body?.toUpperCase() ?? '';
    
    return address.contains('MPESA') || 
           address.contains('M-PESA') ||
           body.contains('MPESA') || 
           body.contains('M-PESA') ||
           body.contains('CONFIRMED') ||
           address == '21456'; // Official M-Pesa shortcode
  }
  
  static Transaction? _parseMpesaMessage(SmsMessage message) {
    final body = message.body ?? '';
    
    // Skip OTP and promotional messages
    if (body.contains('Your M-PESA PIN') || 
        body.contains('Your MPesa PIN') ||
        body.contains('Your M-PESA passcode') ||
        body.contains('promotion') ||
        body.contains('airtime') ||
        body.contains('Dear Customer') ||
        body.contains('You have received') && body.contains('airtime')) {
      return null;
    }
    
    // Parse transaction based on M-Pesa message patterns
    try {
      // Check for transaction confirmation
      if (body.contains('CONFIRMED')) {
        // M-Pesa payment confirmation message
        return _parseConfirmationMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      } 
      
      // M-Pesa deposit confirmation
      else if (body.contains('received from')) {
        return _parseDepositMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // M-Pesa withdrawal confirmation
      else if (body.contains('Withdraw') || body.contains('withdrawal')) {
        return _parseWithdrawalMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // M-Pesa payment to business
      else if (body.contains('sent to') && (body.contains('Business') || body.contains('Till'))) {
        return _parseBusinessPaymentMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // M-Pesa balance message
      else if (body.contains('balance is')) {
        return _parseBalanceMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('Error parsing M-Pesa message: $e');
    }
    
    // Return null if we can't parse
    return null;
  }
  
  static Transaction _parseConfirmationMessage(String body, int timestamp) {
    // Extract transaction code (usually appears after "Confirmed.")
    final codeRegex = RegExp(r'([A-Z0-9]+) Confirmed');
    final codeMatch = codeRegex.firstMatch(body);
    final code = codeMatch?.group(1) ?? 'Unknown';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract recipient/business name
    final nameRegex = RegExp(r'sent to (.+?)( on| \.)');
    final nameMatch = nameRegex.firstMatch(body);
    String recipient = nameMatch?.group(1) ?? 'Unknown';
    
    // Extract date
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Create transaction
    return Transaction(
      id: code,
      title: 'Payment to $recipient',
      amount: amount,
      date: dateTime,
      category: 'Payment',
      isExpense: true,
      icon: Icons.payment,
      color: Colors.red.shade700,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      recipient: recipient,
    );
  }
  
  static Transaction _parseDepositMessage(String body, int timestamp) {
    // Extract transaction code
    final codeRegex = RegExp(r'([A-Z0-9]+) Confirmed');
    final codeMatch = codeRegex.firstMatch(body);
    final code = codeMatch?.group(1) ?? 'Unknown';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract sender name
    final nameRegex = RegExp(r'from (.+?)( on|\.)');
    final nameMatch = nameRegex.firstMatch(body);
    String sender = nameMatch?.group(1) ?? 'Unknown';
    
    // Extract date
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Create transaction
    return Transaction(
      id: code,
      title: 'Received from $sender',
      amount: amount,
      date: dateTime,
      category: 'Income',
      isExpense: false,
      icon: Icons.arrow_downward,
      color: Colors.green.shade700,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      sender: sender,
    );
  }
  
  static Transaction _parseWithdrawalMessage(String body, int timestamp) {
    // Extract transaction code
    final codeRegex = RegExp(r'([A-Z0-9]+) Confirmed');
    final codeMatch = codeRegex.firstMatch(body);
    final code = codeMatch?.group(1) ?? 'Unknown';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract agent name
    final agentRegex = RegExp(r'from (.+?) New');
    final agentMatch = agentRegex.firstMatch(body);
    String agent = agentMatch?.group(1) ?? 'Unknown Agent';
    
    // Extract date
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Create transaction
    return Transaction(
      id: code,
      title: 'Withdrawal from $agent',
      amount: amount,
      date: dateTime,
      category: 'Withdrawal',
      isExpense: true,
      icon: Icons.account_balance,
      color: Colors.orange.shade700,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      agent: agent,
    );
  }
  
  static Transaction _parseBusinessPaymentMessage(String body, int timestamp) {
    // Extract transaction code
    final codeRegex = RegExp(r'([A-Z0-9]+) Confirmed');
    final codeMatch = codeRegex.firstMatch(body);
    final code = codeMatch?.group(1) ?? 'Unknown';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract business name
    final businessRegex = RegExp(r'sent to (.+?)( on|\.)');
    final businessMatch = businessRegex.firstMatch(body);
    String business = businessMatch?.group(1) ?? 'Unknown Business';
    
    // Extract date
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Enhanced category detection for Kenyan businesses
    String category = 'Shopping';
    IconData icon = Icons.business;
    Color color = Colors.blue.shade700;
    
    final businessLower = business.toLowerCase();
    
    // Food & Dining
    if (businessLower.contains('market') || businessLower.contains('food') || 
        businessLower.contains('restaurant') || businessLower.contains('cafe') ||
        businessLower.contains('supermarket') || businessLower.contains('naivas') ||
        businessLower.contains('carrefour') || businessLower.contains('quickmart')) {
      category = 'Food';
      icon = Icons.restaurant;
      color = Colors.green.shade700;
    }
    // Transport
    else if (businessLower.contains('matatu') || businessLower.contains('uber') ||
             businessLower.contains('bolt') || businessLower.contains('taxi') ||
             businessLower.contains('transport') || businessLower.contains('bus')) {
      category = 'Transport';
      icon = Icons.directions_bus;
      color = Colors.blue.shade700;
    }
    // Utilities
    else if (businessLower.contains('kplc') || businessLower.contains('water') ||
             businessLower.contains('electricity') || businessLower.contains('power') ||
             businessLower.contains('nairobi water') || businessLower.contains('gotv') ||
             businessLower.contains('dstv') || businessLower.contains('zuku')) {
      category = 'Utilities';
      icon = Icons.electrical_services;
      color = Colors.orange.shade700;
    }
    // Education
    else if (businessLower.contains('school') || businessLower.contains('college') ||
             businessLower.contains('university') || businessLower.contains('academy') ||
             businessLower.contains('education')) {
      category = 'Education';
      icon = Icons.school;
      color = Colors.purple.shade700;
    }
    // Health
    else if (businessLower.contains('hospital') || businessLower.contains('clinic') ||
             businessLower.contains('pharmacy') || businessLower.contains('medical') ||
             businessLower.contains('health') || businessLower.contains('doctor')) {
      category = 'Health';
      icon = Icons.local_hospital;
      color = Colors.red.shade300;
    }
    
    // Create transaction
    return Transaction(
      id: code,
      title: 'Paid to $business',
      amount: amount,
      date: dateTime,
      category: category,
      isExpense: true,
      icon: icon,
      color: color,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      business: business,
    );
  }
  
  static Transaction _parseBalanceMessage(String body, int timestamp) {
    // Extract balance amount
    final balanceRegex = RegExp(r'balance is Ksh([0-9,.]+)');
    final balanceMatch = balanceRegex.firstMatch(body);
    final balanceString = balanceMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final balance = double.tryParse(balanceString) ?? 0.0;
    
    // Extract date
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Create transaction
    return Transaction(
      id: 'balance-${DateTime.now().millisecondsSinceEpoch}',
      title: 'M-Pesa Balance Update',
      amount: balance,
      date: dateTime,
      category: 'Balance',
      isExpense: false,
      icon: Icons.account_balance_wallet,
      color: Colors.blue.shade700,
      mpesaCode: null,
      isSms: true,
      rawSms: body,
      balance: balance,
    );
  }
  
  void dispose() {
    _transactionStreamController.close();
  }
}