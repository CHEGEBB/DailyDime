// lib/services/mpesa_handling_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class MpesaHandlingService {
  // Singleton pattern
  static final MpesaHandlingService _instance = MpesaHandlingService._internal();
  factory MpesaHandlingService() => _instance;
  MpesaHandlingService._internal();

  // Store the access token with expiry
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Get access token from Safaricom
  Future<String> _getAccessToken() async {
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
          'Content-Type': 'application/json',
        },
      );

      print('Auth Response Status: ${response.statusCode}');
      print('Auth Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        _accessToken = jsonResponse['access_token'];
        // Token usually expires in 1 hour, set expiry to 50 minutes to be safe
        _tokenExpiry = DateTime.now().add(Duration(minutes: 50));
        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Network error when getting access token: $e');
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
    try {
      // Format phone number to required format (254XXXXXXXXX)
      phoneNumber = AppConfig.formatPhoneNumber(phoneNumber);
      
      // Validate phone number
      if (!AppConfig.isValidPhoneNumber(phoneNumber)) {
        throw Exception('Invalid phone number format');
      }
      
      // Get access token
      final accessToken = await _getAccessToken();
      
      // Generate timestamp in the required format: YYYYMMDDHHMMSS
      final now = DateTime.now();
      final timestamp = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      
      // Generate password (base64 of shortcode+passkey+timestamp)
      final password = base64Encode(utf8.encode('${AppConfig.mpesaShortcode}${AppConfig.mpesaPasskey}$timestamp'));
      
      // Create the request body
      final body = {
        'BusinessShortCode': AppConfig.mpesaShortcode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt().toString(), // Ensure it's an integer string
        'PartyA': phoneNumber,
        'PartyB': AppConfig.mpesaShortcode,
        'PhoneNumber': phoneNumber,
        'CallBackURL': 'https://your-callback-url.com/callback', // Replace with your actual callback URL
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc ?? 'Payment for services',
      };

      print('STK Push Request Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('${AppConfig.mpesaBaseUrl}${AppConfig.mpesaStkPushUrl}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('STK Push Response Status: ${response.statusCode}');
      print('STK Push Response Body: ${response.body}');

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      print('Error initiating STK push: $e');
      throw Exception('Error initiating STK push: $e');
    }
  }

  // Check status of STK push
  Future<Map<String, dynamic>> checkSTKStatus({
    required String checkoutRequestID,
  }) async {
    try {
      // Get access token
      final accessToken = await _getAccessToken();
      
      // Generate timestamp
      final now = DateTime.now();
      final timestamp = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      
      // Generate password
      final password = base64Encode(utf8.encode('${AppConfig.mpesaShortcode}${AppConfig.mpesaPasskey}$timestamp'));
      
      // Create the request body
      final body = {
        'BusinessShortCode': AppConfig.mpesaShortcode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestID,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.mpesaBaseUrl}${AppConfig.mpesaStkQueryUrl}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error checking STK status: $e');
    }
  }

  // B2C Payment (Business to Customer) - Mock implementation
  Future<Map<String, dynamic>> sendMoneyToCustomer({
    required String phoneNumber,
    required double amount,
    required String remarks,
  }) async {
    // B2C requires additional security credentials and backend implementation
    // For demo purposes, we'll just return a mock response
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    
    return {
      'success': true,
      'message': 'Money sent successfully to $phoneNumber',
      'amount': amount,
      'transactionId': 'MOCK-${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toString(),
    };
  }

  // Check account balance - Mock implementation
  Future<Map<String, dynamic>> checkAccountBalance() async {
    // Account balance requires additional security credentials and backend implementation
    // Just mocking the response for now
    await Future.delayed(Duration(seconds: 1));
    
    return {
      'success': true,
      'balance': 25000.00,
      'currency': 'KES',
      'timestamp': DateTime.now().toString(),
    };
  }

  // Transaction status query - Mock implementation
  Future<Map<String, dynamic>> checkTransactionStatus({
    required String transactionId,
  }) async {
    // For demo, we're returning mock data
    await Future.delayed(Duration(seconds: 1));
    
    return {
      'success': true,
      'transactionId': transactionId,
      'status': 'Completed',
      'amount': 1500.00,
      'receiverPhoneNumber': '254712345678',
      'timestamp': DateTime.now().subtract(Duration(days: 1)).toString(),
    };
  }

  // Register C2B URLs (would usually be done at the backend/server)
  Future<Map<String, dynamic>> registerC2BUrls() async {
    // This is typically a one-time setup done at the backend
    return {
      'success': true,
      'message': 'URLs registered successfully',
    };
  }

  // Parse MPESA SMS for transaction data
  Map<String, dynamic>? parseMpesaSMS(String message) {
    // Pattern to match M-PESA messages
    RegExp mpesaRegex = RegExp(
      r'([A-Z0-9]+) Confirmed\.[\s\S]*?Ksh([0-9,]+\.[0-9]{2})[\s\S]*?from ([A-Z ]+)[\s\S]*?on ([0-9/]+) at ([0-9:]+)[\s\S]*?New M-PESA balance is Ksh([0-9,]+\.[0-9]{2})',
      caseSensitive: true,
    );

    // Alternative pattern for payments
    RegExp paymentRegex = RegExp(
      r'([A-Z0-9]+) Confirmed\.[\s\S]*?Ksh([0-9,]+\.[0-9]{2})[\s\S]*?paid to ([A-Z ]+)[\s\S]*?on ([0-9/]+) at ([0-9:]+)[\s\S]*?New M-PESA balance is Ksh([0-9,]+\.[0-9]{2})',
      caseSensitive: true,
    );

    Match? match = mpesaRegex.firstMatch(message);
    bool isIncoming = true;

    if (match == null) {
      match = paymentRegex.firstMatch(message);
      isIncoming = false;
      
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
      'type': isIncoming ? 'RECEIVED' : 'PAID',
    };
  }
}