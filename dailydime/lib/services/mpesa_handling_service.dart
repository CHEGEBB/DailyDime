// lib/services/mpesa_handling_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'package:appwrite/appwrite.dart';

class MpesaHandlingService {
  // Singleton pattern
  static final MpesaHandlingService _instance = MpesaHandlingService._internal();
  factory MpesaHandlingService() => _instance;
  MpesaHandlingService._internal();

  // Store the access token with expiry
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  // Transaction types
  static const PAY = 'pay';
  static const SEND = 'send';
  static const WITHDRAW = 'withdraw';
  
  // Transaction statuses
  static const STATUS_PENDING = 'pending';
  static const STATUS_COMPLETED = 'completed';
  static const STATUS_FAILED = 'failed';

  // Get access token from Safaricom
  Future<String> getAccessToken() async {
    // Check if token exists and is valid
    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _accessToken!;
    }

    // Create the authentication string (base64 encoded)
    String auth = base64Encode(utf8.encode('${AppConfig.mpesaConsumerKey}:${AppConfig.mpesaConsumerSecret}'));
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.mpesaBaseUrl}${AppConfig.mpesaAuthUrl}'),
        headers: {
          'Authorization': 'Basic $auth',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        _accessToken = jsonResponse['access_token'];
        // Token expires in 1 hour, set expiry to 55 minutes to be safe
        _tokenExpiry = DateTime.now().add(Duration(minutes: 55));
        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error when getting access token: $e');
    }
  }

  // STK Push (Lipa Na MPesa Online)
  Future<Map<String, dynamic>> initiateSTKPush({
    required String phoneNumber, 
    required double amount, 
    required String accountReference,
    String? transactionDesc,
  }) async {
    // Format phone number to required format (254XXXXXXXXX)
    phoneNumber = AppConfig.formatPhoneNumber(phoneNumber);
    
    // Get access token
    final accessToken = await getAccessToken();
    
    // Generate timestamp in the format YYYYMMDDHHmmss
    final timestamp = DateTime.now().toUtc().toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    
    // Generate password (base64 of shortcode+passkey+timestamp)
    final password = base64Encode(utf8.encode('${AppConfig.mpesaShortcode}${AppConfig.mpesaPasskey}$timestamp'));
    
    // Create the request body
    final body = {
      'BusinessShortCode': AppConfig.mpesaShortcode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount.toStringAsFixed(0),
      'PartyA': phoneNumber,
      'PartyB': AppConfig.mpesaShortcode,
      'PhoneNumber': phoneNumber,
      'CallBackURL': AppConfig.isDevelopment 
          ? 'https://webhook.site/your-webhook-id' // For testing
          : 'https://yourdomain.com/api/mpesa/callback',
      'AccountReference': accountReference,
      'TransactionDesc': transactionDesc ?? 'Payment via DailyDime',
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.mpesaBaseUrl}${AppConfig.mpesaStkPushUrl}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);
      
      // Save transaction to database if request was successful
      if (responseData.containsKey('ResponseCode') && 
          responseData['ResponseCode'] == '0') {
        _saveTransaction(
          type: PAY,
          amount: amount,
          phoneNumber: phoneNumber,
          status: STATUS_PENDING,
          reference: accountReference,
          checkoutRequestId: responseData['CheckoutRequestID'],
        );
      }

      return responseData;
    } catch (e) {
      throw Exception('Error initiating STK push: $e');
    }
  }

  // Check status of STK push
  Future<Map<String, dynamic>> checkSTKStatus({
    required String checkoutRequestID,
  }) async {
    // Get access token
    final accessToken = await getAccessToken();
    
    // Generate timestamp in the format YYYYMMDDHHmmss
    final timestamp = DateTime.now().toUtc().toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    
    // Generate password
    final password = base64Encode(utf8.encode('${AppConfig.mpesaShortcode}${AppConfig.mpesaPasskey}$timestamp'));
    
    // Create the request body
    final body = {
      'BusinessShortCode': AppConfig.mpesaShortcode,
      'Password': password,
      'Timestamp': timestamp,
      'CheckoutRequestID': checkoutRequestID,
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.mpesaBaseUrl}${AppConfig.mpesaStkQueryUrl}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);
      
      // Update transaction status in database
      if (responseData.containsKey('ResultCode')) {
        String status = responseData['ResultCode'] == '0' 
            ? STATUS_COMPLETED 
            : STATUS_FAILED;
            
        _updateTransactionStatus(
          checkoutRequestId: checkoutRequestID,
          status: status,
        );
      }

      return responseData;
    } catch (e) {
      throw Exception('Error checking STK status: $e');
    }
  }

  // B2C Payment (Business to Customer)
  Future<Map<String, dynamic>> sendMoneyToCustomer({
    required String phoneNumber,
    required double amount,
    required String remarks,
  }) async {
    // In a real app, this would be implemented via a secure server-side endpoint
    // B2C requires security credentials that shouldn't be in client-side code
    
    // For demo purposes, create a mock transaction
    final transactionId = 'TX-${DateTime.now().millisecondsSinceEpoch}';
    
    // Save to database
    _saveTransaction(
      type: SEND,
      amount: amount,
      phoneNumber: AppConfig.formatPhoneNumber(phoneNumber),
      status: STATUS_COMPLETED, // Assume success for demo
      reference: remarks,
      transactionId: transactionId,
    );
    
    // Return mock response
    return {
      'success': true,
      'transactionId': transactionId,
      'amount': amount,
      'recipient': phoneNumber,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Check account balance
  Future<Map<String, dynamic>> checkAccountBalance() async {
    // In a real app, this would be implemented via a secure server-side endpoint
    // Get current balance from recent transactions
    try {
      final transactions = await getRecentTransactions(limit: 1);
      double balance = 25000.00; // Default fallback balance
      
      if (transactions.isNotEmpty && transactions[0].containsKey('runningBalance')) {
        balance = transactions[0]['runningBalance'];
      }
      
      return {
        'success': true,
        'balance': balance,
        'currency': 'KES',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve balance: $e',
      };
    }
  }

  // Get recent transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 10}) async {
    // In a real app, fetch from Appwrite database
    // For demo, return mock data
    final List<Map<String, dynamic>> mockTransactions = [
      {
        'id': 'tx1',
        'type': SEND,
        'amount': 1000.0,
        'recipient': '254712345678',
        'description': 'Payment to John',
        'status': STATUS_COMPLETED,
        'timestamp': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'runningBalance': 24000.0,
      },
      {
        'id': 'tx2',
        'type': PAY,
        'amount': 2500.0,
        'recipient': 'Supermarket',
        'description': 'Grocery shopping',
        'status': STATUS_COMPLETED,
        'timestamp': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'runningBalance': 25000.0,
      },
      {
        'id': 'tx3',
        'type': WITHDRAW,
        'amount': 5000.0,
        'recipient': 'ATM',
        'description': 'Cash withdrawal',
        'status': STATUS_COMPLETED,
        'timestamp': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
        'runningBalance': 27500.0,
      },
    ];
    
    return mockTransactions.take(limit).toList();
  }

  // Save transaction to database
  Future<void> _saveTransaction({
    required String type,
    required double amount,
    required String phoneNumber,
    required String status,
    required String reference,
    String? checkoutRequestId,
    String? transactionId,
  }) async {
    // In a real app, save to Appwrite database
    // For demo, just print to console
    debugPrint('Saving transaction: $type, $amount, $phoneNumber, $status, $reference');
    
    // Implementation with Appwrite would look like:
    /*
    try {
      final databases = Databases(Client());
      await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        documentId: ID.unique(),
        data: {
          'type': type,
          'amount': amount,
          'phoneNumber': phoneNumber,
          'status': status,
          'reference': reference,
          'checkoutRequestId': checkoutRequestId,
          'transactionId': transactionId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error saving transaction: $e');
    }
    */
  }
  
  // Update transaction status
  Future<void> _updateTransactionStatus({
    required String checkoutRequestId,
    required String status,
  }) async {
    // In a real app, update in Appwrite database
    debugPrint('Updating transaction status: $checkoutRequestId to $status');
    
    // Implementation with Appwrite would look like:
    /*
    try {
      final databases = Databases(Client());
      
      // First, query to find the document by checkoutRequestId
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        queries: [
          Query.equal('checkoutRequestId', checkoutRequestId),
        ],
      );
      
      if (response.documents.isNotEmpty) {
        final document = response.documents.first;
        
        await databases.updateDocument(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.transactionsCollection,
          documentId: document.$id,
          data: {
            'status': status,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      debugPrint('Error updating transaction status: $e');
    }
    */
  }

  // Parse MPESA SMS for transaction data
  Map<String, dynamic>? parseMpesaSMS(String message) {
    // Pattern to match M-PESA messages for received money
    RegExp receiveRegex = RegExp(
      r'([A-Z0-9]+) Confirmed\.[\s\S]*?Ksh([0-9,.]+)[\s\S]*?from ([A-Z0-9 ]+)[\s\S]*?on ([0-9/]+) at ([0-9:]+)[\s\S]*?New M-PESA balance is Ksh([0-9,.]+)',
      caseSensitive: true,
    );

    // Pattern for payments made
    RegExp payRegex = RegExp(
      r'([A-Z0-9]+) Confirmed\.[\s\S]*?Ksh([0-9,.]+)[\s\S]*?paid to ([A-Z0-9 ]+)[\s\S]*?on ([0-9/]+) at ([0-9:]+)[\s\S]*?New M-PESA balance is Ksh([0-9,.]+)',
      caseSensitive: true,
    );

    Match? match = receiveRegex.firstMatch(message);
    String type = 'RECEIVED';

    if (match == null) {
      match = payRegex.firstMatch(message);
      type = 'PAID';
      
      if (match == null) {
        return null; // Not a recognized M-PESA message
      }
    }

    // Parse amount (remove commas)
    double amount = double.parse(match.group(2)!.replaceAll(',', ''));
    
    // Parse balance
    double balance = double.parse(match.group(6)!.replaceAll(',', ''));
    
    // Parse date and time
    String date = match.group(4)!;
    String time = match.group(5)!;
    
    return {
      'transactionId': match.group(1),
      'amount': amount,
      'party': match.group(3),
      'date': date,
      'time': time,
      'balance': balance,
      'type': type,
    };
  }
}