// // lib/services/balance_service.dart

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:another_telephony/telephony.dart' hide NetworkType;
// import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' hide SmsMessage;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:dailydime/services/storage_service.dart';
// import 'package:dailydime/services/appwrite_service.dart';
// import 'package:dailydime/services/notification_service.dart';
// import 'package:dailydime/models/transaction.dart';
// import 'package:workmanager/workmanager.dart';

// // Background handler for balance updates
// @pragma('vm:entry-point')
// void balanceCallbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     try {
//       final balanceService = BalanceService();
//       await balanceService.initialize();
//       await balanceService.checkAndUpdateBalance();
//       return true;
//     } catch (e) {
//       debugPrint('Balance background task failed: $e');
//       return false;
//     }
//   });
// }

// class BalanceService {
//   static final BalanceService _instance = BalanceService._internal();
//   factory BalanceService() => _instance;
//   BalanceService._internal();

//   final Telephony _telephony = Telephony.instance;
//   final SmsQuery _smsQuery = SmsQuery();
  
//   bool _isInitialized = false;
//   bool _isBackgroundServiceRunning = false;
  
//   // Current balance tracking
//   double _currentBalance = 0.0;
//   DateTime? _lastBalanceUpdate;
//   List<BalanceHistory> _balanceHistory = [];
  
//   // Stream controllers for real-time updates
//   final StreamController<double> _balanceStreamController = 
//       StreamController<double>.broadcast();
//   final StreamController<BalanceHistory> _balanceHistoryStreamController = 
//       StreamController<BalanceHistory>.broadcast();
  
//   // Getters for streams
//   Stream<double> get balanceStream => _balanceStreamController.stream;
//   Stream<BalanceHistory> get balanceHistoryStream => _balanceHistoryStreamController.stream;
  
//   // Getter for current balance
//   double get currentBalance => _currentBalance;
//   DateTime? get lastBalanceUpdate => _lastBalanceUpdate;
//   List<BalanceHistory> get balanceHistory => List.unmodifiable(_balanceHistory);

//   Future<bool> initialize() async {
//     if (_isInitialized) return true;

//     try {
//       // Check SMS permissions
//       final permissionStatus = await _requestSmsPermissions();
//       if (!permissionStatus) {
//         debugPrint('SMS permission denied for balance service');
//         return false;
//       }

//       // Initialize storage service
//       await StorageService.instance.initialize();
      
//       // Load existing balance data
//       await _loadStoredBalance();
//       await _loadBalanceHistory();
      
//       // Set up SMS listeners for balance updates
//       await _setupBalanceListeners();
      
//       // Initialize background service
//       await _initializeBackgroundService();
      
//       // Perform initial balance check
//       await checkAndUpdateBalance();
      
//       _isInitialized = true;
//       debugPrint('BalanceService initialized successfully');
//       return true;
//     } catch (e) {
//       debugPrint('Error initializing BalanceService: $e');
//       return false;
//     }
//   }

//   Future<bool> _requestSmsPermissions() async {
//     try {
//       var status = await Permission.sms.status;
//       if (status.isDenied) {
//         status = await Permission.sms.request();
//       }
//       return status.isGranted;
//     } catch (e) {
//       debugPrint('Error requesting SMS permissions: $e');
//       return false;
//     }
//   }

//   Future<void> _loadStoredBalance() async {
//     try {
//       _currentBalance = await StorageService.instance.getCurrentBalance();
//       final balanceData = await StorageService.instance.getBalanceMetadata();
//       if (balanceData != null) {
//         _lastBalanceUpdate = balanceData['lastUpdate'] as DateTime?;
//       }
//       debugPrint('Loaded stored balance: $_currentBalance');
//     } catch (e) {
//       debugPrint('Error loading stored balance: $e');
//     }
//   }

//   Future<void> _loadBalanceHistory() async {
//     try {
//       _balanceHistory = await StorageService.instance.getBalanceHistory();
//       debugPrint('Loaded ${_balanceHistory.length} balance history records');
//     } catch (e) {
//       debugPrint('Error loading balance history: $e');
//     }
//   }

//   Future<void> _setupBalanceListeners() async {
//     try {
//       // Listen for incoming SMS messages using another_telephony
//       _telephony.listenIncomingSms(
//         onNewMessage: (SmsMessage message) {
//           _processBalanceMessage(message);
//         },
//         listenInBackground: false,
//       );
//     } catch (e) {
//       debugPrint('Error setting up balance listeners: $e');
//     }
//   }

//   Future<void> _initializeBackgroundService() async {
//     if (_isBackgroundServiceRunning) return;

//     try {
//       Workmanager().initialize(
//         balanceCallbackDispatcher,
//         isInDebugMode: false,
//       );

//       Workmanager().registerPeriodicTask(
//         'balance-check-task',
//         'balanceCheck',
//         frequency: const Duration(hours: 2),
//         constraints: Constraints(
//           networkType: NetworkType.connected,
//           requiresBatteryNotLow: true,
//         ),
//         existingWorkPolicy: ExistingWorkPolicy.replace,
//       );

//       _isBackgroundServiceRunning = true;
//       debugPrint('Balance background service initialized');
//     } catch (e) {
//       debugPrint('Failed to initialize balance background service: $e');
//     }
//   }

//   void _processBalanceMessage(SmsMessage message) {
//     if (_isBalanceMessage(message)) {
//       final balance = _extractBalanceFromMessage(message);
//       if (balance != null) {
//         _updateBalance(balance, 'sms', message.date?.millisecondsSinceEpoch.toString());
//       }
//     }
//   }

//   bool _isBalanceMessage(SmsMessage message) {
//     final address = message.address?.toUpperCase() ?? '';
//     final body = message.body?.toUpperCase() ?? '';

//     return (address.contains('MPESA') || 
//             address.contains('M-PESA') ||
//             address == '21456' || 
//             address == '40665' ||
//             address.contains('SAFARICOM')) &&
//            (body.contains('BALANCE IS KSH') ||
//             body.contains('YOUR BALANCE IS') ||
//             body.contains('M-PESA BALANCE') ||
//             body.contains('MPESA BALANCE') ||
//             body.contains('ACCOUNT BALANCE'));
//   }

//   double? _extractBalanceFromMessage(SmsMessage message) {
//     final body = message.body ?? '';
    
//     final patterns = [
//       RegExp(r'balance is Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
//       RegExp(r'balance Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
//       RegExp(r'your balance is Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
//       RegExp(r'account balance is Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
//       RegExp(r'M-PESA balance is Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
//       RegExp(r'balance:\s*Ksh\.?([0-9,]+\.?[0-9]*)', caseSensitive: false),
//     ];

//     for (var pattern in patterns) {
//       final match = pattern.firstMatch(body);
//       if (match != null) {
//         final balanceString = match.group(1)?.replaceAll(',', '') ?? '0';
//         return double.tryParse(balanceString);
//       }
//     }

//     return null;
//   }

//   Future<void> checkAndUpdateBalance() async {
//     try {
//       debugPrint('Checking for balance updates...');
      
//       // Check recent SMS messages for balance information
//       await _checkRecentBalanceMessages();
      
//       // Calculate balance from recent transactions if no direct balance found
//       await _calculateBalanceFromTransactions();
      
//     } catch (e) {
//       debugPrint('Error checking balance updates: $e');
//     }
//   }

//   Future<void> _checkRecentBalanceMessages() async {
//     try {
//       // Use another_telephony to get recent messages
//       List<SmsMessage> telephonyMessages = [];
//       try {
//         telephonyMessages = await _telephony.getInboxSms(
//           columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
//           filter: SmsFilter.where(SmsColumn.ADDRESS).like('MPESA') |
//                   SmsFilter.where(SmsColumn.ADDRESS).like('M-PESA') |
//                   SmsFilter.where(SmsColumn.ADDRESS).equals('21456') |
//                   SmsFilter.where(SmsColumn.ADDRESS).equals('40665'),
//           sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
//         );
//       } catch (e) {
//         debugPrint('another_telephony error: $e');
//       }

//       // Also use flutter_sms_inbox as backup
//       List<SmsMessage> inboxMessages = [];
//       try {
//         inboxMessages = await _smsQuery.querySms(
//           kinds: [SmsQueryKind.inbox],
//           count: 100,
//         );
//       } catch (e) {
//         debugPrint('flutter_sms_inbox error: $e');
//       }

//       // Combine and process messages
//       final allMessages = [...telephonyMessages, ...inboxMessages];
      
//       for (var message in allMessages.take(50)) { // Check last 50 messages
//         if (_isBalanceMessage(message)) {
//           final balance = _extractBalanceFromMessage(message);
//           if (balance != null) {
//             final messageDate = message.date ?? DateTime.now();
//             if (_lastBalanceUpdate == null || 
//                 messageDate.isAfter(_lastBalanceUpdate!)) {
//               await _updateBalance(balance, 'sms', message.date?.millisecondsSinceEpoch.toString());
//               break; // Use the most recent balance
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error checking recent balance messages: $e');
//     }
//   }

//   Future<void> _calculateBalanceFromTransactions() async {
//     try {
//       // Get recent transactions from storage
//       final transactions = await StorageService.instance.getRecentTransactions(100);
      
//       if (transactions.isEmpty) return;

//       // Sort transactions by date
//       transactions.sort((a, b) => a.date.compareTo(b.date));

//       // Find the most recent balance transaction
//       Transaction? lastBalanceTransaction;
//       for (var transaction in transactions.reversed) {
//         if (transaction.category == 'Balance' && transaction.balance != null) {
//           lastBalanceTransaction = transaction;
//           break;
//         }
//       }

//       if (lastBalanceTransaction != null) {
//         double calculatedBalance = lastBalanceTransaction.balance!;
//         DateTime lastBalanceDate = lastBalanceTransaction.date;

//         // Apply subsequent transactions to calculate current balance
//         for (var transaction in transactions) {
//           if (transaction.date.isAfter(lastBalanceDate) && 
//               transaction.category != 'Balance') {
//             if (transaction.isExpense) {
//               calculatedBalance -= transaction.amount;
//             } else {
//               calculatedBalance += transaction.amount;
//             }
//           }
//         }

//         // Update balance if it's different and more recent
//         if (calculatedBalance != _currentBalance &&
//             (_lastBalanceUpdate == null || 
//              lastBalanceDate.isAfter(_lastBalanceUpdate!))) {
//           await _updateBalance(calculatedBalance, 'calculated', null);
//         }
//       }
//     } catch (e) {
//       debugPrint('Error calculating balance from transactions: $e');
//     }
//   }

//   Future<void> _updateBalance(double newBalance, String source, String? transactionId) async {
//     try {
//       if (newBalance == _currentBalance) return;

//       final oldBalance = _currentBalance;
//       _currentBalance = newBalance;
//       _lastBalanceUpdate = DateTime.now();

//       // Create balance history record
//       final historyRecord = BalanceHistory(
//         balance: newBalance,
//         timestamp: _lastBalanceUpdate!,
//         transactionId: transactionId,
//         source: source,
//       );

//       _balanceHistory.add(historyRecord);
      
//       // Keep only last 100 history records
//       if (_balanceHistory.length > 100) {
//         _balanceHistory.removeAt(0);
//       }

//       // Save to storage
//       await StorageService.instance.updateBalance(newBalance);
//       await StorageService.instance.saveBalanceMetadata({
//         'lastUpdate': _lastBalanceUpdate,
//         'source': source,
//       });
//       await StorageService.instance.saveBalanceHistory(_balanceHistory);

//       // Sync with Appwrite
//       try {
//         await AppwriteService().updateBalance(newBalance);
//         await AppwriteService().saveBalanceHistory(historyRecord);
//       } catch (e) {
//         debugPrint('Error syncing balance with Appwrite: $e');
//       }

//       // Notify listeners
//       _balanceStreamController.add(newBalance);
//       _balanceHistoryStreamController.add(historyRecord);

//       // Show notification for significant balance changes
//       if ((newBalance - oldBalance).abs() > 100) {
//         try {
//           await NotificationService().showBalanceUpdateNotification(
//             oldBalance, 
//             newBalance
//           );
//         } catch (e) {
//           debugPrint('Error showing balance notification: $e');
//         }
//       }

//       debugPrint('Balance updated: $oldBalance -> $newBalance (source: $source)');
//     } catch (e) {
//       debugPrint('Error updating balance: $e');
//     }
//   }

//   Future<void> manualBalanceUpdate(double balance) async {
//     await _updateBalance(balance, 'manual', null);
//   }

//   Future<void> requestBalanceCheck() async {
//     try {
//       // This would typically send an SMS to check balance
//       // For now, we'll just trigger a balance check from existing messages
//       await checkAndUpdateBalance();
//     } catch (e) {
//       debugPrint('Error requesting balance check: $e');
//     }
//   }

//   Future<List<BalanceHistory>> getBalanceHistoryByDateRange(
//     DateTime startDate, 
//     DateTime endDate
//   ) async {
//     return _balanceHistory
//         .where((record) => 
//             record.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
//             record.timestamp.isBefore(endDate.add(const Duration(days: 1))))
//         .toList();
//   }

//   double getBalanceChangeForPeriod(DateTime startDate, DateTime endDate) {
//     final periodHistory = _balanceHistory
//         .where((record) => 
//             record.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
//             record.timestamp.isBefore(endDate.add(const Duration(days: 1))))
//         .toList();
    
//     if (periodHistory.isEmpty) return 0.0;

//     periodHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//     return periodHistory.last.balance - periodHistory.first.balance;
//   }

//   Future<void> syncWithTransactions() async {
//     try {
//       final transactions = await StorageService.instance.getTransactions();
      
//       // Process transactions to update balance accordingly
//       for (var transaction in transactions) {
//         if (transaction.category == 'Balance' && transaction.balance != null) {
//           if (_balanceHistory.isEmpty || 
//               transaction.date.isAfter(_balanceHistory.last.timestamp)) {
//             await _updateBalance(
//               transaction.balance!, 
//               'transaction_sync', 
//               transaction.id
//             );
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error syncing balance with transactions: $e');
//     }
//   }

//   Future<void> cancelBackgroundService() async {
//     try {
//       await Workmanager().cancelByUniqueName('balance-check-task');
//       _isBackgroundServiceRunning = false;
//     } catch (e) {
//       debugPrint('Error cancelling balance background service: $e');
//     }
//   }

//   // Additional utility methods
//   Future<double> getAverageBalance() async {
//     if (_balanceHistory.isEmpty) return _currentBalance;
    
//     final total = _balanceHistory.fold(0.0, (sum, record) => sum + record.balance);
//     return total / _balanceHistory.length;
//   }

//   Future<double> getMaxBalance() async {
//     if (_balanceHistory.isEmpty) return _currentBalance;
    
//     return _balanceHistory.map((record) => record.balance).reduce(
//       (a, b) => a > b ? a : b
//     );
//   }

//   Future<double> getMinBalance() async {
//     if (_balanceHistory.isEmpty) return _currentBalance;
    
//     return _balanceHistory.map((record) => record.balance).reduce(
//       (a, b) => a < b ? a : b
//     );
//   }

//   Future<List<BalanceHistory>> getRecentBalanceHistory(int count) async {
//     final sortedHistory = List<BalanceHistory>.from(_balanceHistory);
//     sortedHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//     return sortedHistory.take(count).toList();
//   }

//   bool get hasBalanceData => _balanceHistory.isNotEmpty;
  
//   bool get isBalanceStale {
//     if (_lastBalanceUpdate == null) return true;
//     return DateTime.now().difference(_lastBalanceUpdate!).inHours > 24;
//   }

//   void dispose() {
//     _balanceStreamController.close();
//     _balanceHistoryStreamController.close();
//     cancelBackgroundService();
//   }
// }

// extension on int? {
//   get millisecondsSinceEpoch => null;
// }