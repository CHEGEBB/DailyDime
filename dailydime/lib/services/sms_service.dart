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
  // This function runs in the background when SMS is received
  if (SmsService._isMpesaMessage(message)) {
    final transaction = SmsService._parseMpesaMessage(message);
    if (transaction != null) {
      // Initialize services
      await StorageService.instance.initialize();
      
      // Store locally
      await StorageService.instance.saveTransaction(transaction);
      
      // Show notification for the new transaction
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
  bool _isBackgroundServiceRunning = false;
  final StreamController<Transaction> _transactionStreamController = 
      StreamController<Transaction>.broadcast();
  
  Stream<Transaction> get transactionStream => _transactionStreamController.stream;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Request SMS permissions with proper handling
    final permissionStatus = await _requestSmsPermissions();
    if (!permissionStatus) {
      debugPrint('SMS permission denied');
      return false;
    }
    
    // Initialize notification service
    await NotificationService().init();
    
    // Set up SMS listener with robust error handling
    try {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _processMessage(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );
      
      // Schedule background work for periodic SMS checks
      await _initializeBackgroundService();
      
      // Load historical messages on initialization
      await loadHistoricalMpesaMessages();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing SMS listener: $e');
      // Try alternative method if first method fails
      return _initializeAlternativeMethod();
    }
  }
  
  Future<bool> _initializeAlternativeMethod() async {
    try {
      // Alternative approach using simpler telephony setup
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _processMessage(message);
        },
        listenInBackground: false,
      );
      
      // Force load historical messages as fallback
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
      // Initialize Workmanager for background tasks
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: AppConfig.isDevelopment,
      );
      
      // Register periodic task to check for new messages
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
      // Check for Android version to handle permissions appropriately
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        // For Android 11+ (API 30+), we need special handling
        if (androidInfo.version.sdkInt >= 30) {
          // Request MANAGE_EXTERNAL_STORAGE permission
          await Permission.manageExternalStorage.request();
        }
      }
      
      // Request SMS permission
      var status = await Permission.sms.status;
      
      if (status.isDenied) {
        status = await Permission.sms.request();
      }
      
      // Need to request phone state for some devices
      var phoneStatus = await Permission.phone.status;
      if (phoneStatus.isDenied) {
        phoneStatus = await Permission.phone.request();
      }
      
      // Request notifications permission
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
    // Debug log for message receipt
    debugPrint('SMS received: ${message.address} - ${message.body?.substring(0, 20)}...');
    
    if (_isMpesaMessage(message)) {
      debugPrint('M-Pesa message detected');
      final transaction = _parseMpesaMessage(message);
      if (transaction != null) {
        debugPrint('Successfully parsed M-Pesa transaction: ${transaction.title}');
        
        // Add to stream for UI updates
        _transactionStreamController.add(transaction);
        
        // Save locally with proper error handling
        StorageService.instance.saveTransaction(transaction).then((_) {
          debugPrint('Transaction saved locally');
        }).catchError((e) {
          debugPrint('Error saving transaction locally: $e');
        });
        
        // Show notification
        NotificationService().showTransactionNotification(
          transaction.title,
          '${AppConfig.formatCurrency(transaction.amount.toInt() * 100)} ${transaction.isExpense ? 'sent' : 'received'}',
        );
        
        // Sync with Appwrite
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
      
      // Try multiple sender IDs to maximize message capture
      final senderIds = ['MPESA', 'M-PESA', '21456', 'SAFARICOM'];
      
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
      
      // If no messages found via address filter, try content filtering approach
      if (transactions.isEmpty) {
        debugPrint('No M-Pesa messages found by sender. Trying content filtering...');
        
        // Get all messages and filter manually
        final allMessages = await _telephony.getInboxSms(
          columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
          sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
        );
        
        for (var message in allMessages) {
          if (_isMpesaMessage(message)) {
            final transaction = _parseMpesaMessage(message);
            if (transaction != null) {
              transactions.add(transaction);
            }
          }
        }
      }
      
      debugPrint('Parsed ${transactions.length} M-Pesa transactions from SMS');
      
      // Remove duplicates and sort by date (newest first)
      final uniqueTransactions = <String, Transaction>{};
      for (var transaction in transactions) {
        uniqueTransactions[transaction.id] = transaction;
      }
      
      final finalTransactions = uniqueTransactions.values.toList();
      finalTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Save all to local storage
      if (finalTransactions.isNotEmpty) {
        await StorageService.instance.saveTransactions(finalTransactions);
        
        // Add to stream for UI updates
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
    
    // Enhanced detection logic
    return address.contains('MPESA') || 
           address.contains('M-PESA') ||
           address == '21456' || // Official M-Pesa shortcode
           address.contains('SAFARICOM') ||
           (body.contains('MPESA') && !body.contains('YOUR MPESA PIN')) || 
           (body.contains('M-PESA') && !body.contains('YOUR M-PESA PIN')) ||
           body.contains('CONFIRMED') ||
           body.contains('TRANSACTION') ||
           (body.contains('KSH') && body.contains('CONFIRMED')) ||
           (body.contains('RECEIVED') && !body.contains('AIRTIME')) ||
           (body.contains('SENT') && !body.contains('AIRTIME')) ||
           body.contains('WITHDRAW FROM') ||
           body.contains('PAID TO') ||
           body.contains(' TILL ') ||
           body.contains(' PAYBILL ');
  }
  
  static Transaction? _parseMpesaMessage(SmsMessage message) {
    final body = message.body ?? '';
    
    // Skip OTP, promotional messages, and airtime-related messages
    if (body.contains('Your M-PESA PIN') || 
        body.contains('Your MPesa PIN') ||
        body.contains('Your M-PESA passcode') ||
        body.contains('promotion') ||
        body.contains('M-PESA balance was last updated') ||
        (body.contains('airtime') && !body.contains('paid for airtime')) ||
        (body.contains('Dear Customer') && !body.contains('confirmed')) ||
        (body.contains('You have received') && body.contains('airtime'))) {
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
      else if ((body.contains('sent to') || body.contains('paid to')) && 
              (body.contains('Business') || body.contains('Till') || body.contains('Paybill'))) {
        return _parseBusinessPaymentMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // M-Pesa balance message
      else if (body.contains('balance is')) {
        return _parseBalanceMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
      }
      
      // B2C payment from company/organization to customer
      else if (body.contains('received from') && 
              (body.contains('Pay') || body.contains('Ltd') || body.contains('Limited'))) {
        return _parseB2CPaymentMessage(body, message.date ?? DateTime.now().millisecondsSinceEpoch);
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
    final code = codeMatch?.group(1) ?? 'TX${DateTime.now().millisecondsSinceEpoch}';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh[.|\s]?([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract recipient/business name
    final nameRegex = RegExp(r'sent to (.+?)( on| \.|,)');
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
    final code = codeMatch?.group(1) ?? 'TX${DateTime.now().millisecondsSinceEpoch}';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh[.|\s]?([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract sender name
    final nameRegex = RegExp(r'from (.+?)( on|\.|,)');
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
    final code = codeMatch?.group(1) ?? 'TX${DateTime.now().millisecondsSinceEpoch}';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh[.|\s]?([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract agent name
    final agentRegex = RegExp(r'from (.+?)( New| [a-zA-Z0-9]+)');
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
    final code = codeMatch?.group(1) ?? 'TX${DateTime.now().millisecondsSinceEpoch}';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh[.|\s]?([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract business name (try multiple patterns)
    String business = 'Unknown Business';
    final businessRegexOptions = [
      RegExp(r'sent to (.+?)( on|\.|,)'),
      RegExp(r'paid to (.+?)( on|\.|,)'),
      RegExp(r'to ([^.]+) for account'),
    ];
    
    for (var regex in businessRegexOptions) {
      final match = regex.firstMatch(body);
      if (match != null) {
        business = match.group(1) ?? business;
        break;
      }
    }
    
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
        businessLower.contains('carrefour') || businessLower.contains('quickmart') ||
        businessLower.contains('kfc') || businessLower.contains('java') ||
        businessLower.contains('pizza') || businessLower.contains('nakumatt')) {
      category = 'Food';
      icon = Icons.restaurant;
      color = Colors.green.shade700;
    }
    // Transport
    else if (businessLower.contains('matatu') || businessLower.contains('uber') ||
             businessLower.contains('bolt') || businessLower.contains('taxi') ||
             businessLower.contains('transport') || businessLower.contains('bus') ||
             businessLower.contains('little') || businessLower.contains('cab') ||
             businessLower.contains('car') || businessLower.contains('boda')) {
      category = 'Transport';
      icon = Icons.directions_bus;
      color = Colors.blue.shade700;
    }
    // Utilities
    else if (businessLower.contains('kplc') || businessLower.contains('water') ||
             businessLower.contains('electricity') || businessLower.contains('power') ||
             businessLower.contains('nairobi water') || businessLower.contains('gotv') ||
             businessLower.contains('dstv') || businessLower.contains('zuku') ||
             businessLower.contains('bill') || businessLower.contains('utility')) {
      category = 'Utilities';
      icon = Icons.electrical_services;
      color = Colors.orange.shade700;
    }
    // Education
    else if (businessLower.contains('school') || businessLower.contains('college') ||
             businessLower.contains('university') || businessLower.contains('academy') ||
             businessLower.contains('education') || businessLower.contains('learning') ||
             businessLower.contains('tuition') || businessLower.contains('fees')) {
      category = 'Education';
      icon = Icons.school;
      color = Colors.purple.shade700;
    }
    // Health
    else if (businessLower.contains('hospital') || businessLower.contains('clinic') ||
             businessLower.contains('pharmacy') || businessLower.contains('medical') ||
             businessLower.contains('health') || businessLower.contains('doctor') ||
             businessLower.contains('healthcare') || businessLower.contains('med')) {
      category = 'Health';
      icon = Icons.local_hospital;
      color = Colors.red.shade300;
    }
    // Entertainment
    else if (businessLower.contains('cinema') || businessLower.contains('movie') ||
             businessLower.contains('ticket') || businessLower.contains('entertainment') ||
             businessLower.contains('event') || businessLower.contains('concert') ||
             businessLower.contains('theatre') || businessLower.contains('game')) {
      category = 'Entertainment';
      icon = Icons.movie;
      color = Colors.purple.shade500;
    }
    // Shopping
    else if (businessLower.contains('shop') || businessLower.contains('store') ||
             businessLower.contains('mall') || businessLower.contains('mart') ||
             businessLower.contains('retail') || businessLower.contains('outlet')) {
      category = 'Shopping';
      icon = Icons.shopping_bag;
      color = Colors.pink.shade400;
    }
    // Telecom
    else if (businessLower.contains('safaricom') || businessLower.contains('airtel') ||
             businessLower.contains('telkom') || businessLower.contains('telecom') ||
             businessLower.contains('mobile') || businessLower.contains('phone') ||
             businessLower.contains('data') || businessLower.contains('bundle')) {
      category = 'Phone';
      icon = Icons.phone_android;
      color = Colors.green.shade800;
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
    final balanceRegex = RegExp(r'balance is Ksh[.|\s]?([0-9,.]+)');
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
  
  static Transaction _parseB2CPaymentMessage(String body, int timestamp) {
    // Extract transaction code
    final codeRegex = RegExp(r'([A-Z0-9]+) Confirmed');
    final codeMatch = codeRegex.firstMatch(body);
    final code = codeMatch?.group(1) ?? 'TX${DateTime.now().millisecondsSinceEpoch}';
    
    // Extract amount
    final amountRegex = RegExp(r'Ksh[.|\s]?([0-9,.]+)');
    final amountMatch = amountRegex.firstMatch(body);
    final amountString = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Extract sender organization
    final nameRegex = RegExp(r'from (.+?)( on|\.|,)');
    final nameMatch = nameRegex.firstMatch(body);
    String sender = nameMatch?.group(1) ?? 'Unknown Organization';
    
    // Extract date
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Determine category
    String category = 'Income';
    IconData icon = Icons.payments;
    Color color = Colors.green.shade700;
    
    final senderLower = sender.toLowerCase();
    
    // Salary/Payroll
    if (senderLower.contains('payroll') || senderLower.contains('salary') || 
        senderLower.contains('wage') || senderLower.contains('pay')) {
      category = 'Salary';
      icon = Icons.work;
    }
    // Government payment
    else if (senderLower.contains('gov') || senderLower.contains('ministry') || 
             senderLower.contains('county') || senderLower.contains('state')) {
      category = 'Government';
      icon = Icons.account_balance;
    }
    // Refund
    else if (body.toLowerCase().contains('refund') || body.toLowerCase().contains('return')) {
      category = 'Refund';
      icon = Icons.replay;
      color = Colors.amber.shade700;
    }
    
    // Create transaction
    return Transaction(
      id: code,
      title: 'Payment from $sender',
      amount: amount,
      date: dateTime,
      category: category,
      isExpense: false,
      icon: icon,
      color: color,
      mpesaCode: code,
      isSms: true,
      rawSms: body,
      sender: sender,
    );
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
  
  void dispose() {
    _transactionStreamController.close();
  }
}