import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class MpesaService {
  static final Dio _dio = Dio();
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // Generate OAuth Access Token
  static Future<String> _getAccessToken() async {
    if (_accessToken != null && 
        _tokenExpiry != null && 
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    try {
      final credentials = base64Encode(
        utf8.encode('${AppConfig.mpesaConsumerKey}:${AppConfig.mpesaConsumerSecret}')
      );

      final response = await _dio.get(
        '${AppConfig.mpesaBaseUrl}${AppConfig.mpesaAuthUrl}',
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
          },
        ),
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: 3600));
        print('✅ M-Pesa Access Token Generated');
        return _accessToken!;
      } else {
        throw Exception('Failed to get M-Pesa access token');
      }
    } catch (e) {
      print('❌ M-Pesa Auth Error: $e');
      throw Exception('M-Pesa authentication failed: $e');
    }
  }

  // STK Push (Prompt user to enter M-Pesa PIN)
  static Future<Map<String, dynamic>> stkPush({
    required String phoneNumber,
    required int amount,
    required String accountReference,
    required String transactionDesc,
    required String callbackUrl,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(0, 14);
      
      // Generate password
      final password = base64Encode(
        utf8.encode('${AppConfig.mpesaShortcode}${AppConfig.mpesaPasskey}$timestamp')
      );

      final requestData = {
        'BusinessShortCode': AppConfig.mpesaShortcode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount,
        'PartyA': AppConfig.formatPhoneNumber(phoneNumber),
        'PartyB': AppConfig.mpesaShortcode,
        'PhoneNumber': AppConfig.formatPhoneNumber(phoneNumber),
        'CallBackURL': callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc,
      };

      final response = await _dio.post(
        '${AppConfig.mpesaBaseUrl}${AppConfig.mpesaStkPushUrl}',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ STK Push Response: ${response.data}');
      return response.data;
    } catch (e) {
      print('❌ STK Push Error: $e');
      throw Exception('STK Push failed: $e');
    }
  }

  // Check M-Pesa Account Balance
  static Future<Map<String, dynamic>> checkAccountBalance() async {
    try {
      final accessToken = await _getAccessToken();

      final requestData = {
        'Initiator': 'apitest',
        'SecurityCredential': 'YOUR_SECURITY_CREDENTIAL', // Get this from Daraja
        'CommandID': 'AccountBalance',
        'PartyA': AppConfig.mpesaShortcode,
        'IdentifierType': '4',
        'ResultURL': 'https://your-callback-url/balance-result',
        'QueueTimeOutURL': 'https://your-callback-url/balance-timeout',
        'Remarks': 'DailyDime Balance Check',
      };

      final response = await _dio.post(
        '${AppConfig.mpesaBaseUrl}${AppConfig.mpesaAccountBalanceUrl}',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      print('❌ Balance Check Error: $e');
      throw Exception('Balance check failed: $e');
    }
  }

  // Query Transaction Status
  static Future<Map<String, dynamic>> queryTransactionStatus({
    required String transactionId,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final requestData = {
        'Initiator': 'apitest',
        'SecurityCredential': 'YOUR_SECURITY_CREDENTIAL',
        'CommandID': 'TransactionStatusQuery',
        'TransactionID': transactionId,
        'PartyA': AppConfig.mpesaShortcode,
        'IdentifierType': '4',
        'ResultURL': 'https://your-callback-url/status-result',
        'QueueTimeOutURL': 'https://your-callback-url/status-timeout',
        'Remarks': 'DailyDime Transaction Query',
        'Occasion': 'Transaction Status Check',
      };

      final response = await _dio.post(
        '${AppConfig.mpesaBaseUrl}${AppConfig.mpesaTransactionStatusUrl}',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      print('❌ Transaction Status Error: $e');
      throw Exception('Transaction status query failed: $e');
    }
  }
}