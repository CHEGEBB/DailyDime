// lib/services/sms_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart' hide NetworkType;
import 'package:permission_handler/permission_handler.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/notification_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background handler for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final smsService = SmsService();
      await smsService.initialize();
      await smsService.loadHistoricalMpesaMessages();
      return true;
    } catch (e) {
      return false;
    }
  });
}

// Background handler for Telephony
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  if (SmsService._isMpesaMessage(message)) {
    final transaction = SmsService._parseMpesaMessage(message);
    if (transaction != null) {
      await StorageService.instance.initialize();
      await StorageService.instance.saveTransaction(transaction);
      
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'mpesa_channel', 
        'M-Pesa Transactions',
        channelDescription: 'Notifications for M-Pesa transactions',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      
      await flutterLocalNotificationsPlugin.show(
        transaction.hashCode, 
        'New Transaction Detected', 
        '${transaction.isExpense ? 'Spent' : 'Received'} ${AppConfig.formatCurrency(transaction.amount.toInt() * 100)}', 
        platformChannelSpecifics,
      );
      
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
  bool _isBackgroundServiceRunning = false;
  final StreamController<Transaction> _transactionStreamController = 
      StreamController<Transaction>.broadcast();
  
  Stream<Transaction> get transactionStream => _transactionStreamController.stream;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    final permissionStatus = await _requestSmsPermissions();
    if (!permissionStatus) {
      debugPrint('SMS permission denied');
      return false;
    }
    
    await NotificationService().init();
    
    try {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _processMessage(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );
      
      await _initializeBackgroundService();
      await loadHistoricalMpesaMessages();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing SMS listener: $e');
      return _initializeAlternativeMethod();
    }
  }
  
  Future<bool> _initializeAlternativeMethod() async {
    try {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _processMessage(message);
        },
        listenInBackground: false,
      );
      
      await loadHistoricalMpesaMessages();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Alternative SMS initialization also failed: $e');
      return false;
    }
  }
  
  Future<void> _initializeBackgroundService() async {
    if (_isBackgroundServiceRunning) return;
    
    try {
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: AppConfig.isDevelopment,
      );
      
      Workmanager().registerPeriodicTask(
        'sms-sync-task',
        'smsSync',
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      
      _isBackgroundServiceRunning = true;
    } catch (e) {
      debugPrint('Failed to initialize background service: $e');
    }
  }
  
  Future<bool> _requestSmsPermissions() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        if (androidInfo.version.sdkInt >= 30) {
          await Permission.manageExternalStorage.request();
        }
      }
      
      var status = await Permission.sms.status;
      if (status.isDenied) {
        status = await Permission.sms.request();
      }
      
      var phoneStatus = await Permission.phone.status;
      if (phoneStatus.isDenied) {
        phoneStatus = await Permission.phone.request();
      }
      
      var notificationStatus = await Permission.notification.status;
      if (notificationStatus.isDenied) {
        notificationStatus = await Permission.notification.request();
      }
      
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }
  
  void _processMessage(SmsMessage message) {
    debugPrint('SMS received: ${message.address} - ${message.body?.substring(0, 20)}...');
    
    if (_isMpesaMessage(message)) {
      debugPrint('M-Pesa message detected');
      final transaction = _parseMpesaMessage(message);
      if (transaction != null) {
        debugPrint('Successfully parsed M-Pesa transaction: ${transaction.title}');
        
        _transactionStreamController.add(transaction);
        
        StorageService.instance.saveTransaction(transaction).then((_) {
          debugPrint('Transaction saved locally');
        }).catchError((e) {
          debugPrint('Error saving transaction locally: $e');
        });
        
        NotificationService().showTransactionNotification(
          transaction.title,
          '${AppConfig.formatCurrency(transaction.amount.toInt() * 100)} ${transaction.isExpense ? 'sent' : 'received'}',
        );
        
        AppwriteService().syncTransaction(transaction).then((_) {
          debugPrint('Transaction synced with Appwrite');
        }).catchError((e) {
          debugPrint('Error syncing with Appwrite: $e');
        });
      }
    }
  }
  
  Future<List<Transaction>> loadHistoricalMpesaMessages() async {
    List<Transaction> transactions = [];
    
    try {
      debugPrint('Loading historical M-Pesa messages...');
      
      // Comprehensive list of M-Pesa sender IDs
      final senderIds = [
        'MPESA', 'M-PESA', 'M-Pesa', 'mpesa', 'm-pesa',
        '21456', '40665', '31000', '21050', '21051',
        'SAFARICOM', 'Safaricom', 'safaricom',
        'MSHWARI', 'KCB-MPESA', 'EQUITY',
        'PAYBILL', 'TILL', 'AGENT'
      ];
      
      for (final sender in senderIds) {
        try {
          final messages = await _telephony.getInboxSms(
            columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
            filter: SmsFilter.where(SmsColumn.ADDRESS).equals(sender),
            sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
          );
          
          debugPrint('Found ${messages.length} messages from $sender');
          
          for (var message in messages) {
            if (_isMpesaMessage(message)) {
              final transaction = _parseMpesaMessage(message);
              if (transaction != null) {
                transactions.add(transaction);
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching messages from $sender: $e');
        }
      }
      
      // Fallback: scan all messages for M-Pesa content
      if (transactions.isEmpty) {
        debugPrint('No M-Pesa messages found by sender. Trying content filtering...');
        
        try {
          final allMessages = await _telephony.getInboxSms(
            columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
            sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
          );
          
          for (var message in allMessages.take(1000)) { // Limit to last 1000 messages for performance
            if (_isMpesaMessage(message)) {
              final transaction = _parseMpesaMessage(message);
              if (transaction != null) {
                transactions.add(transaction);
              }
            }
          }
        } catch (e) {
          debugPrint('Error in fallback message scanning: $e');
        }
      }
      
      debugPrint('Parsed ${transactions.length} M-Pesa transactions from SMS');
      
      // Remove duplicates based on transaction ID
      final uniqueTransactions = <String, Transaction>{};
      for (var transaction in transactions) {
        uniqueTransactions[transaction.id] = transaction;
      }
      
      final finalTransactions = uniqueTransactions.values.toList();
      finalTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      if (finalTransactions.isNotEmpty) {
        await StorageService.instance.saveTransactions(finalTransactions);
        
        for (var transaction in finalTransactions) {
          _transactionStreamController.add(transaction);
        }
      }
      
      return finalTransactions;
      
    } catch (e) {
      debugPrint('Error loading historical M-Pesa messages: $e');
      return transactions;
    }
  }
  
  static bool _isMpesaMessage(SmsMessage message) {
    final address = message.address?.toUpperCase() ?? '';
    final body = message.body?.toUpperCase() ?? '';
    
    // Enhanced M-Pesa message detection
    return 
      // Sender-based detection
      address.contains('MPESA') || 
      address.contains('M-PESA') ||
      address == '21456' || // Primary M-Pesa shortcode
      address == '40665' || // Secondary shortcode
      address == '31000' || // Another shortcode
      address == '21050' ||
      address == '21051' ||
      address.contains('SAFARICOM') ||
      
      // Content-based detection
      (body.contains('MPESA') && !body.contains('YOUR MPESA PIN') && !body.contains('PASSCODE')) || 
      (body.contains('M-PESA') && !body.contains('YOUR M-PESA PIN') && !body.contains('PASSCODE')) ||
      
      // Transaction keywords
      body.contains('CONFIRMED.') ||
      body.contains('CONFIRMED ') ||
      (body.contains('KSH') && body.contains('CONFIRMED')) ||
      (body.contains('KSHH') && body.contains('CONFIRMED')) ||
      
      // Money movement keywords
      body.contains('SENT TO') ||
      body.contains('RECEIVED FROM') ||
      body.contains('WITHDRAW FROM') ||
      body.contains('PAID TO') ||
      body.contains('DEPOSIT TO') ||
      
      // Business payment indicators
      body.contains(' TILL ') ||
      body.contains(' PAYBILL ') ||
      body.contains('FOR ACCOUNT') ||
      
      // Balance and other M-Pesa services
      body.contains('BALANCE IS KSH') ||
      body.contains('YOUR BALANCE IS') ||
      body.contains('M-PESA BALANCE') ||
      body.contains('MPESA BALANCE') ||
      
      // Loan services
      body.contains('MSHWARI') ||
      body.contains('KCB M-PESA') ||
      body.contains('FULIZA') ||
      
      // Airtime and other services (but not promotional)
      (body.contains('AIRTIME') && body.contains('CONFIRMED') && !body.contains('PROMO')) ||
      (body.contains('BUNDLE') && body.contains('CONFIRMED')) ||
      
      // Agent transactions
      body.contains('AGENT') && body.contains('KSH') ||
      
      // International transfers
      body.contains('WESTERN UNION') && body.contains('MPESA') ||
      
      // Other M-Pesa services
      body.contains('LIPA NA MPESA') ||
      body.contains('BUY GOODS') ||
      body.contains('PAY BILL');
  }
  
  static Transaction? _parseMpesaMessage(SmsMessage message) {
    final body = message.body ?? '';
    final bodyUpper = body.toUpperCase();
    
    // Skip non-transactional messages
    if (_shouldSkipMessage(bodyUpper)) {
      return null;
    }
    
    try {
      // Parse different transaction types
      
      // 1. Money sent to person/business
      if (bodyUpper.contains('SENT TO') && bodyUpper.contains('CONFIRMED')) {
        return _parseSentTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 2. Money received from person/business
      if (bodyUpper.contains('RECEIVED FROM') && bodyUpper.contains('CONFIRMED')) {
        return _parseReceivedTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 3. Paybill payments
      if ((bodyUpper.contains('PAYBILL') || bodyUpper.contains('FOR ACCOUNT')) && bodyUpper.contains('CONFIRMED')) {
        return _parsePaybillTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 4. Till payments (Buy Goods)
      if (bodyUpper.contains('TILL') && bodyUpper.contains('CONFIRMED')) {
        return _parseTillTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 5. ATM/Agent withdrawals
      if ((bodyUpper.contains('WITHDRAW') || bodyUpper.contains('AGENT')) && bodyUpper.contains('CONFIRMED')) {
        return _parseWithdrawalTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 6. Deposits
      if (bodyUpper.contains('DEPOSIT') && bodyUpper.contains('CONFIRMED')) {
        return _parseDepositTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 7. Balance inquiries
      if (bodyUpper.contains('BALANCE IS') || bodyUpper.contains('YOUR BALANCE')) {
        return _parseBalanceTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 8. Airtime purchases
      if (bodyUpper.contains('AIRTIME') && bodyUpper.contains('CONFIRMED')) {
        return _parseAirtimeTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 9. Data bundles
      if (bodyUpper.contains('BUNDLE') && bodyUpper.contains('CONFIRMED')) {
        return _parseBundleTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 10. Loan services (Fuliza, KCB M-Pesa, etc.)
      if ((bodyUpper.contains('FULIZA') || bodyUpper.contains('KCB') || bodyUpper.contains('MSHWARI')) 
          && bodyUpper.contains('CONFIRMED')) {
        return _parseLoanTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 11. Utility payments
      if ((bodyUpper.contains('KPLC') || bodyUpper.contains('WATER') || bodyUpper.contains('NAIROBI WATER')) 
          && bodyUpper.contains('CONFIRMED')) {
        return _parseUtilityTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // 12. Generic confirmed transaction (fallback)
      if (bodyUpper.contains('CONFIRMED') && bodyUpper.contains('KSH')) {
        return _parseGenericTransaction(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
    } catch (e) {
      debugPrint('Error parsing M-Pesa message: $e');
      debugPrint('Message body: $body');
    }
    
    return null;
  }
  
  static bool _shouldSkipMessage(String bodyUpper) {
    return bodyUpper.contains('YOUR MPESA PIN') ||
           bodyUpper.contains('YOUR M-PESA PIN') ||
           bodyUpper.contains('YOUR PASSCODE') ||
           bodyUpper.contains('PROMOTION') ||
           bodyUpper.contains('PROMO') ||
           bodyUpper.contains('DEAR CUSTOMER') && !bodyUpper.contains('CONFIRMED') ||
           bodyUpper.contains('THANK YOU') && !bodyUpper.contains('CONFIRMED') ||
           bodyUpper.contains('SAFARICOM WISHES') ||
           bodyUpper.contains('TERMS AND CONDITIONS') ||
           bodyUpper.contains('TO STOP') ||
           bodyUpper.contains('SMS CHARGES') ||
           bodyUpper.contains('BALANCE WAS LAST UPDATED') ||
           bodyUpper.contains('YOU HAVE NOT USED') ||
           bodyUpper.contains('EXPIRES ON');
  }
  
  static Transaction _parseSentTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final recipient = _extractRecipient(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    return Transaction(
      id: code,
      title: 'Sent to $recipient',
      amount: amount,
      date: dateTime,
      category: 'Transfer',
      isExpense: true,
      icon: Icons.arrow_upward,
      color: Colors.red.shade700,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      recipient: recipient,
    );
  }
  
  static Transaction _parseReceivedTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final sender = _extractSender(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
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
  
  static Transaction _parsePaybillTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final business = _extractPaybillBusiness(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final categoryInfo = _categorizePaybillBusiness(business);
    
    return Transaction(
      id: code,
      title: 'Paid to $business',
      amount: amount,
      date: dateTime,
      category: categoryInfo['category'],
      isExpense: true,
      icon: categoryInfo['icon'],
      color: categoryInfo['color'],
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      business: business,
    );
  }
  
  static Transaction _parseTillTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final business = _extractTillBusiness(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final categoryInfo = _categorizeTillBusiness(business);
    
    return Transaction(
      id: code,
      title: 'Paid at $business',
      amount: amount,
      date: dateTime,
      category: categoryInfo['category'],
      isExpense: true,
      icon: categoryInfo['icon'],
      color: categoryInfo['color'],
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      business: business,
    );
  }
  
  static Transaction _parseWithdrawalTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final agent = _extractAgent(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
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
  
  static Transaction _parseDepositTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final agent = _extractAgent(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    return Transaction(
      id: code,
      title: 'Deposit at $agent',
      amount: amount,
      date: dateTime,
      category: 'Deposit',
      isExpense: false,
      icon: Icons.add_circle,
      color: Colors.green.shade700,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      agent: agent,
    );
  }
  
  static Transaction _parseBalanceTransaction(String body, int timestamp) {
    final balance = _extractBalance(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    return Transaction(
      id: 'balance-${timestamp}',
      title: 'M-Pesa Balance',
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
  
  static Transaction _parseAirtimeTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final phoneNumber = _extractPhoneNumber(body);
    
    return Transaction(
      id: code,
      title: phoneNumber.isNotEmpty ? 'Airtime for $phoneNumber' : 'Airtime Purchase',
      amount: amount,
      date: dateTime,
      category: 'Phone',
      isExpense: true,
      icon: Icons.phone,
      color: Colors.blue.shade600,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
    );
  }
  
  static Transaction _parseBundleTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    return Transaction(
      id: code,
      title: 'Data Bundle Purchase',
      amount: amount,
      date: dateTime,
      category: 'Phone',
      isExpense: true,
      icon: Icons.wifi,
      color: Colors.blue.shade600,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
    );
  }
  
  static Transaction _parseLoanTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final bodyUpper = body.toUpperCase();
    
    String service = 'Loan Service';
    String category = 'Loan';
    IconData icon = Icons.money;
    Color color = Colors.purple.shade600;
    bool isExpense = false;
    
    if (bodyUpper.contains('FULIZA')) {
      service = 'Fuliza Loan';
      isExpense = false; // Receiving loan
    } else if (bodyUpper.contains('KCB')) {
      service = 'KCB M-Pesa';
      isExpense = bodyUpper.contains('REPAY') || bodyUpper.contains('PAY');
    } else if (bodyUpper.contains('MSHWARI')) {
      service = 'M-Shwari';
      isExpense = bodyUpper.contains('REPAY') || bodyUpper.contains('PAY');
    }
    
    return Transaction(
      id: code,
      title: service,
      amount: amount,
      date: dateTime,
      category: category,
      isExpense: isExpense,
      icon: icon,
      color: color,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
    );
  }
  
  static Transaction _parseUtilityTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final utility = _extractUtility(body);
    
    return Transaction(
      id: code,
      title: 'Utility Payment - $utility',
      amount: amount,
      date: dateTime,
      category: 'Utilities',
      isExpense: true,
      icon: Icons.electrical_services,
      color: Colors.orange.shade600,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      business: utility,
    );
  }
  
  static Transaction _parseGenericTransaction(String body, int timestamp) {
    final code = _extractTransactionCode(body);
    final amount = _extractAmount(body);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final bodyUpper = body.toUpperCase();
    
    bool isExpense = true;
    String category = 'Other';
    IconData icon = Icons.receipt;
    Color color = Colors.grey.shade600;
    String title = 'M-Pesa Transaction';
    
    // Determine if it's income or expense
    if (bodyUpper.contains('RECEIVED') || bodyUpper.contains('DEPOSIT') || 
        bodyUpper.contains('CREDIT')) {
      isExpense = false;
      color = Colors.green.shade600;
      title = 'M-Pesa Receipt';
      icon = Icons.add_circle;
    } else if (bodyUpper.contains('SENT') || bodyUpper.contains('PAID') || 
               bodyUpper.contains('WITHDRAW')) {
      isExpense = true;
      color = Colors.red.shade600;
      title = 'M-Pesa Payment';
      icon = Icons.remove_circle;
    }
    
    return Transaction(
      id: code,
      title: title,
      amount: amount,
      date: dateTime,
      category: category,
      isExpense: isExpense,
      icon: icon,
      color: color,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
    );
  }
  
  // Helper methods for extracting information
  static String _extractTransactionCode(String body) {
    final patterns = [
      RegExp(r'([A-Z]{2}[0-9]{8,10})', caseSensitive: false),
      RegExp(r'([A-Z0-9]{10,12}) Confirmed', caseSensitive: false),
      RegExp(r'Confirmed\. ([A-Z0-9]{8,12})', caseSensitive: false),
      RegExp(r'([A-Z]{3}[0-9]{7,9})', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }
    
    return 'TX${DateTime.now().millisecondsSinceEpoch}';
  }
  
  static double _extractAmount(String body) {
    final patterns = [
      RegExp(r'Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'KSH\.?\s*([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'amount of Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'([0-9,]+\.?[0-9]*)\s*KSH', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amountString = match.group(1)?.replaceAll(',', '') ?? '0';
        return double.tryParse(amountString) ?? 0.0;
      }
    }
    
    return 0.0;
  }
  
  static String _extractRecipient(String body) {
    final patterns = [
      RegExp(r'sent to (.+?)(?:\s+on|\s+\.|,|\s+for|\s+New)', caseSensitive: false),
      RegExp(r'paid to (.+?)(?:\s+on|\s+\.|,|\s+for)', caseSensitive: false),
      RegExp(r'to (.+?)(?:\s+on|\s+\.|,)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown';
      }
    }
    
    return 'Unknown';
  }
  
  static String _extractSender(String body) {
    final patterns = [
      RegExp(r'received from (.+?)(?:\s+on|\s+\.|,|\s+New)', caseSensitive: false),
      RegExp(r'from (.+?)(?:\s+on|\s+\.|,|\s+New)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown';
      }
    }
    
    return 'Unknown';
  }
  
  static String _extractPaybillBusiness(String body) {
    final patterns = [
      RegExp(r'to (.+?) for account', caseSensitive: false),
      RegExp(r'paid to (.+?)(?:\s+on|\s+\.|,)', caseSensitive: false),
      RegExp(r'paybill (.+?)(?:\s+on|\s+\.|,)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown Business';
      }
    }
    
    return 'Unknown Business';
  }
  
  static String _extractTillBusiness(String body) {
    final patterns = [
      RegExp(r'till (\d+) (.+?)(?:\s+on|\s+\.|,)', caseSensitive: false),
      RegExp(r'buy goods till (\d+) (.+?)(?:\s+on|\s+\.|,)', caseSensitive: false),
      RegExp(r'to till (\d+) (.+?)(?:\s+on|\s+\.|,)', caseSensitive: false),
      RegExp(r'till (\d+)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final tillNumber = match.group(1) ?? '';
        final businessName = match.group(2)?.trim() ?? '';
        return businessName.isNotEmpty ? '$businessName (Till $tillNumber)' : 'Till $tillNumber';
      }
    }
    
    return 'Unknown Business';
  }
  
  static String _extractAgent(String body) {
    final patterns = [
      RegExp(r'(?:from|at) (.+?)(?:\s+Agent|\s+on|\s+\.|,)', caseSensitive: false),
      RegExp(r'agent (.+?)(?:\s+on|\s+\.|,)', caseSensitive: false),
      RegExp(r'withdraw from (.+?)(?:\s+New|\s+on|\s+\.|,)', caseSensitive: false),
      RegExp(r'deposit to (.+?)(?:\s+New|\s+on|\s+\.|,)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown Agent';
      }
    }
    
    return 'Unknown Agent';
  }
  
  static double _extractBalance(String body) {
    final patterns = [
      RegExp(r'balance is Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'balance Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'your balance is Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final balanceString = match.group(1)?.replaceAll(',', '') ?? '0';
        return double.tryParse(balanceString) ?? 0.0;
      }
    }
    
    return 0.0;
  }
  
  static String _extractPhoneNumber(String body) {
    final patterns = [
      RegExp(r'for (\+?254\d{9})', caseSensitive: false),
      RegExp(r'to (\+?254\d{9})', caseSensitive: false),
      RegExp(r'(\+?254\d{9})', caseSensitive: false),
      RegExp(r'for (07\d{8})', caseSensitive: false),
      RegExp(r'to (07\d{8})', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }
  
  static String _extractUtility(String body) {
    final bodyUpper = body.toUpperCase();
    
    if (bodyUpper.contains('KPLC')) return 'KPLC (Electricity)';
    if (bodyUpper.contains('NAIROBI WATER')) return 'Nairobi Water';
    if (bodyUpper.contains('WATER')) return 'Water Service';
    if (bodyUpper.contains('GOTV')) return 'GOtv';
    if (bodyUpper.contains('DSTV')) return 'DStv';
    if (bodyUpper.contains('ZUKU')) return 'Zuku';
    
    return 'Utility Service';
  }
  
  static Map<String, dynamic> _categorizePaybillBusiness(String business) {
    final businessLower = business.toLowerCase();
    
    // Utilities
    if (businessLower.contains('kplc') || businessLower.contains('electricity') || 
        businessLower.contains('power') || businessLower.contains('water') ||
        businessLower.contains('nairobi water') || businessLower.contains('utility')) {
      return {
        'category': 'Utilities',
        'icon': Icons.electrical_services,
        'color': Colors.orange.shade700,
      };
    }
    
    // TV/Entertainment
    if (businessLower.contains('gotv') || businessLower.contains('dstv') || 
        businessLower.contains('zuku') || businessLower.contains('showmax') ||
        businessLower.contains('netflix') || businessLower.contains('tv')) {
      return {
        'category': 'Entertainment',
        'icon': Icons.tv,
        'color': Colors.purple.shade600,
      };
    }
    
    // Banks/Financial
    if (businessLower.contains('bank') || businessLower.contains('sacco') || 
        businessLower.contains('loan') || businessLower.contains('credit') ||
        businessLower.contains('kcb') || businessLower.contains('equity') ||
        businessLower.contains('coop') || businessLower.contains('financial')) {
      return {
        'category': 'Financial',
        'icon': Icons.account_balance,
        'color': Colors.blue.shade700,
      };
    }
    
    // Insurance
    if (businessLower.contains('insurance') || businessLower.contains('nhif') || 
        businessLower.contains('britam') || businessLower.contains('jubilee') ||
        businessLower.contains('aar') || businessLower.contains('cover')) {
      return {
        'category': 'Insurance',
        'icon': Icons.security,
        'color': Colors.teal.shade600,
      };
    }
    
    // Education
    if (businessLower.contains('school') || businessLower.contains('university') || 
        businessLower.contains('college') || businessLower.contains('education') ||
        businessLower.contains('fees') || businessLower.contains('tuition')) {
      return {
        'category': 'Education',
        'icon': Icons.school,
        'color': Colors.indigo.shade600,
      };
    }
    
    // Government
    if (businessLower.contains('kra') || businessLower.contains('government') || 
        businessLower.contains('county') || businessLower.contains('ministry') ||
        businessLower.contains('revenue') || businessLower.contains('tax')) {
      return {
        'category': 'Government',
        'icon': Icons.account_balance,
        'color': Colors.brown.shade600,
      };
    }
    
    // Default business category
    return {
      'category': 'Business',
      'icon': Icons.business,
      'color': Colors.blue.shade600,
    };
  }
  
  static Map<String, dynamic> _categorizeTillBusiness(String business) {
    final businessLower = business.toLowerCase();
    
    // Food & Restaurants
    if (businessLower.contains('restaurant') || businessLower.contains('hotel') || 
        businessLower.contains('cafe') || businessLower.contains('pizza') ||
        businessLower.contains('kfc') || businessLower.contains('subway') ||
        businessLower.contains('java') || businessLower.contains('food') ||
        businessLower.contains('kitchen') || businessLower.contains('meals')) {
      return {
        'category': 'Food',
        'icon': Icons.restaurant,
        'color': Colors.orange.shade600,
      };
    }
    
    // Supermarkets & Shopping
    if (businessLower.contains('supermarket') || businessLower.contains('mart') || 
        businessLower.contains('naivas') || businessLower.contains('carrefour') ||
        businessLower.contains('quickmart') || businessLower.contains('shop') ||
        businessLower.contains('store') || businessLower.contains('mall') ||
        businessLower.contains('retail') || businessLower.contains('market')) {
      return {
        'category': 'Shopping',
        'icon': Icons.shopping_cart,
        'color': Colors.green.shade600,
      };
    }
    
    // Transport
    if (businessLower.contains('matatu') || businessLower.contains('bus') || 
        businessLower.contains('transport') || businessLower.contains('travel') ||
        businessLower.contains('taxi') || businessLower.contains('uber') ||
        businessLower.contains('bolt') || businessLower.contains('little') ||
        businessLower.contains('car') || businessLower.contains('parking')) {
      return {
        'category': 'Transport',
        'icon': Icons.directions_car,
        'color': Colors.blue.shade600,
      };
    }
    
    // Health & Pharmacy
    if (businessLower.contains('pharmacy') || businessLower.contains('chemist') || 
        businessLower.contains('hospital') || businessLower.contains('clinic') ||
        businessLower.contains('medical') || businessLower.contains('health') ||
        businessLower.contains('doctor') || businessLower.contains('lab')) {
      return {
        'category': 'Health',
        'icon': Icons.local_pharmacy,
        'color': Colors.red.shade400,
      };
    }
    
    // Fuel Stations
    if (businessLower.contains('petrol') || businessLower.contains('fuel') || 
        businessLower.contains('shell') || businessLower.contains('total') ||
        businessLower.contains('kenol') || businessLower.contains('kobil') ||
        businessLower.contains('oil') || businessLower.contains('station')) {
      return {
        'category': 'Fuel',
        'icon': Icons.local_gas_station,
        'color': Colors.amber.shade700,
      };
    }
    
    // Entertainment & Gaming
    if (businessLower.contains('cinema') || businessLower.contains('movie') || 
        businessLower.contains('game') || businessLower.contains('bet') ||
        businessLower.contains('sport') || businessLower.contains('casino') ||
        businessLower.contains('club') || businessLower.contains('bar')) {
      return {
        'category': 'Entertainment',
        'icon': Icons.sports_esports,
        'color': Colors.purple.shade600,
      };
    }
    
    // Default shopping category
    return {
      'category': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': Colors.pink.shade400,
    };
  }
  
  Future<bool> refreshTransactions() async {
    try {
      await loadHistoricalMpesaMessages();
      return true;
    } catch (e) {
      debugPrint('Error refreshing transactions: $e');
      return false;
    }
  }
  
  Future<void> cancelBackgroundService() async {
    try {
      await Workmanager().cancelAll();
      _isBackgroundServiceRunning = false;
    } catch (e) {
      debugPrint('Error cancelling background service: $e');
    }
  }
  
  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    try {
      final allTransactions = await StorageService.instance.getTransactions();
      return allTransactions.where((t) => t.category == category).toList();
    } catch (e) {
      debugPrint('Error getting transactions by category: $e');
      return [];
    }
  }
  
  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    try {
      final allTransactions = await StorageService.instance.getTransactions();
      return allTransactions.where((t) => 
        t.date.isAfter(start.subtract(const Duration(days: 1))) && 
        t.date.isBefore(end.add(const Duration(days: 1)))).toList();
    } catch (e) {
      debugPrint('Error getting transactions by date range: $e');
      return [];
    }
  }
  
  double getTotalExpenses() {
    try {
      // This would ideally come from stored transactions
      // For now, return 0 as a placeholder
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating total expenses: $e');
      return 0.0;
    }
  }
  
  double getTotalIncome() {
    try {
      // This would ideally come from stored transactions
      // For now, return 0 as a placeholder
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating total income: $e');
      return 0.0;
    }
  }
  
  Map<String, double> getExpensesByCategory() {
    try {
      // This would ideally come from stored transactions
      // For now, return empty map as a placeholder
      return {};
    } catch (e) {
      debugPrint('Error getting expenses by category: $e');
      return {};
    }
  }
  
  Future<void> forceSyncWithAppwrite() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      final appwriteService = AppwriteService();
      
      for (var transaction in transactions) {
        try {
          await appwriteService.syncTransaction(transaction);
        } catch (e) {
          debugPrint('Error syncing transaction ${transaction.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error during force sync: $e');
    }
  }
  
  Future<bool> testSmsPermissions() async {
    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals('MPESA'),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      
      debugPrint('SMS permission test: Found ${messages.length} M-Pesa messages');
      return true;
    } catch (e) {
      debugPrint('SMS permission test failed: $e');
      return false;
    }
  }
  
  void dispose() {
    _transactionStreamController.close();
    cancelBackgroundService();
  }
}