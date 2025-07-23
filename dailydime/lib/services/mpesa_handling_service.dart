import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Configuration class reference
import 'package:dailydime/config/app_config.dart';

/// Models for M-Pesa integration
class PaymentRequest {
  final String phone;
  final String amount;
  final String accountReference;
  final String transactionDesc;

  PaymentRequest({
    required this.phone,
    required this.amount,
    this.accountReference = "DailyDime",
    this.transactionDesc = "DailyDime Payment",
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'amount': amount,
        'accountReference': accountReference,
        'transactionDesc': transactionDesc,
      };
}

class MpesaResponse {
  final bool success;
  final String? merchantRequestID;
  final String? checkoutRequestID;
  final String? responseCode;
  final String? customerMessage;
  final String? errorMessage;

  MpesaResponse({
    required this.success,
    this.merchantRequestID,
    this.checkoutRequestID,
    this.responseCode,
    this.customerMessage,
    this.errorMessage,
  });

  factory MpesaResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure from your API response
    final data = json['data'] as Map<String, dynamic>?;
    
    return MpesaResponse(
      success: json['success'] ?? false,
      merchantRequestID: data?['merchantRequestID'],
      checkoutRequestID: data?['checkoutRequestID'],
      responseCode: data?['responseCode'],
      customerMessage: data?['customerMessage'] ?? json['message'],
      errorMessage: json['error'] ?? (json['success'] == false ? json['message'] : null),
    );
  }

  factory MpesaResponse.error(String message) {
    return MpesaResponse(
      success: false,
      errorMessage: message,
    );
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  unknown,
}

class PaymentStatusResponse {
  final bool success;
  final PaymentStatus status;
  final String? responseCode;
  final String? resultCode;
  final String? resultDesc;
  final String? errorMessage;

  PaymentStatusResponse({
    required this.success,
    required this.status,
    this.responseCode,
    this.resultCode,
    this.resultDesc,
    this.errorMessage,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    PaymentStatus status = PaymentStatus.unknown;
    
    // Handle nested data structure
    final data = json['data'] as Map<String, dynamic>?;
    
    if (json['success'] == true && data != null) {
      final resultCode = data['ResultCode']?.toString() ?? '';
      
      switch (resultCode) {
        case '0':
          status = PaymentStatus.completed;
          break;
        case '1':
          status = PaymentStatus.failed;
          break;
        case '1032':
          status = PaymentStatus.cancelled;
          break;
        default:
          status = data['ResultDesc']?.toString()?.toLowerCase().contains('pending') ?? false
              ? PaymentStatus.pending
              : PaymentStatus.unknown;
      }
    }

    return PaymentStatusResponse(
      success: json['success'] ?? false,
      status: status,
      responseCode: data?['ResponseCode'],
      resultCode: data?['ResultCode']?.toString(),
      resultDesc: data?['ResultDesc'],
      errorMessage: json['error'] ?? (json['success'] == false ? json['message'] : null),
    );
  }

  factory PaymentStatusResponse.error(String message) {
    return PaymentStatusResponse(
      success: false,
      status: PaymentStatus.unknown,
      errorMessage: message,
    );
  }
}

class MpesaException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  MpesaException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'MpesaException: $message (Code: $statusCode)';
}

/// Service for handling M-Pesa integration with Appwrite Cloud Functions
class MpesaHandlingService {
  final http.Client _httpClient;
  
  // Function IDs from your Appwrite console
  static const String _mpesaAuthFunctionId = 'mpesa-auth';
  static const String _mpesaStkPushFunctionId = '6880bbaf0000f09b4c55';
  static const String _mpesaQueryFunctionId = '6880bd20000e7035d1b8';
  
  // Appwrite endpoints
  late final String _baseUrl;
  late final Map<String, String> _defaultHeaders;
  
  // Token cache management
  String? _cachedToken;
  DateTime? _tokenExpiry;
  
  // Rate limiting
  DateTime? _lastRequestTime;
  final _minRequestInterval = const Duration(milliseconds: 500);
  
  // Retry configuration
  final int _maxRetries = 3;
  final Duration _retryDelay = const Duration(seconds: 2);

  MpesaHandlingService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client() {
    _baseUrl = 'https://cloud.appwrite.io/v1/functions';
    _defaultHeaders = {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': AppConfig.appwriteProjectId,
      'X-Appwrite-Key': AppConfig.appwriteApiKey,
    };
    
    debugPrint('MpesaHandlingService initialized with project: ${AppConfig.appwriteProjectId}');
  }

  /// Helper method to execute Appwrite Cloud Function with proper format
  Future<http.Response> _executeAppwriteFunction(String functionId, Map<String, dynamic> data) async {
    final url = '$_baseUrl/$functionId/executions';
    
    // FIXED: Properly format the request body for Appwrite Cloud Functions
    final requestBody = {
      'body': jsonEncode(data), // The actual payload must be JSON string in 'body' field
      'async': false, // Set to false for synchronous execution
    };
    
    debugPrint('Executing function: $functionId');
    debugPrint('Request URL: $url');
    debugPrint('Request body: ${jsonEncode(requestBody)}');
    
    final response = await _httpClient.post(
      Uri.parse(url),
      headers: _defaultHeaders,
      body: jsonEncode(requestBody),
    );
    
    debugPrint('Function execution response status: ${response.statusCode}');
    debugPrint('Function execution response: ${response.body}');
    
    return response;
  }

  /// Helper method to extract response from Appwrite function execution
  Map<String, dynamic> _extractFunctionResponse(http.Response response) {
    final executionData = jsonDecode(response.body);
    
    // Check if the execution was successful
    if (executionData['status'] != 'completed') {
      throw MpesaException(
        'Function execution failed: ${executionData['status']}',
        statusCode: response.statusCode,
      );
    }
    
    // Check the function's HTTP response status
    final functionStatusCode = executionData['responseStatusCode'] ?? 200;
    if (functionStatusCode >= 400) {
      final errorBody = executionData['responseBody'] ?? 'Unknown error';
      throw MpesaException(
        'Function returned error: $errorBody',
        statusCode: functionStatusCode,
      );
    }
    
    // Parse the actual response from the function
    final responseBody = executionData['responseBody'];
    if (responseBody == null || responseBody.isEmpty) {
      throw MpesaException('Empty response from function');
    }
    
    try {
      return jsonDecode(responseBody);
    } catch (e) {
      throw MpesaException('Invalid JSON response from function: $responseBody');
    }
  }

  /// Gets a valid access token for M-Pesa API, using cache if available
  Future<String?> getAccessToken() async {
    try {
      // Check if we have a valid cached token
      if (_cachedToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
        debugPrint('Using cached M-Pesa token');
        return _cachedToken;
      }

      await _respectRateLimit();
      
      final response = await _executeWithRetry(() => 
        _executeAppwriteFunction(_mpesaAuthFunctionId, {})
      );

      final responseData = _extractFunctionResponse(response);
      debugPrint('Auth response data: $responseData');
      
      // Handle the response structure correctly
      String? accessToken;
      int expiresIn = 3599;

      // Check if the response has the token directly or in a nested structure
      if (responseData['access_token'] != null) {
        accessToken = responseData['access_token'];
        expiresIn = responseData['expires_in'] ?? 3599;
      } else if (responseData['success'] == true) {
        // If wrapped in success response
        final data = responseData['data'];
        if (data != null) {
          accessToken = data['access_token'];
          expiresIn = data['expires_in'] ?? 3599;
        }
      }

      if (accessToken == null) {
        throw MpesaException(
          'No access token in response: $responseData',
        );
      }

      // Cache the token
      _cachedToken = accessToken;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // Buffer of 60 seconds
      
      debugPrint('Generated new M-Pesa token, expires in $expiresIn seconds');
      return _cachedToken;
    } catch (error) {
      final mpesaError = handleError(error);
      debugPrint('M-Pesa authentication error: ${mpesaError.toString()}');
      return null; // Return null instead of rethrowing to handle gracefully
    }
  }

  /// Initiates an STK Push to the user's phone
  Future<MpesaResponse> initiateSTKPush(PaymentRequest request) async {
    try {
      // Validate the payment amount
      if (!validatePaymentAmount(double.tryParse(request.amount) ?? 0)) {
        return MpesaResponse.error('Invalid payment amount. Amount must be between KES 1 and KES 150,000');
      }

      // Format the phone number
      final formattedPhone = formatPhoneNumber(request.phone);
      if (formattedPhone == null) {
        return MpesaResponse.error('Invalid phone number format. Use format: 254XXXXXXXXX');
      }

      // Create a request with the formatted phone number
      final formattedRequest = PaymentRequest(
        phone: formattedPhone,
        amount: request.amount,
        accountReference: request.accountReference,
        transactionDesc: request.transactionDesc,
      );

      await _respectRateLimit();
      
      final response = await _executeWithRetry(() => 
        _executeAppwriteFunction(_mpesaStkPushFunctionId, formattedRequest.toJson())
      );

      final responseData = _extractFunctionResponse(response);
      return MpesaResponse.fromJson(responseData);
    } catch (error) {
      final mpesaError = handleError(error);
      debugPrint('STK Push error: ${mpesaError.toString()}');
      return MpesaResponse.error(mpesaError.message);
    }
  }

  /// Queries the status of a payment
  Future<PaymentStatusResponse> queryPaymentStatus(String checkoutRequestID) async {
    try {
      if (checkoutRequestID.isEmpty) {
        return PaymentStatusResponse.error('Checkout request ID cannot be empty');
      }

      await _respectRateLimit();
      
      final response = await _executeWithRetry(() => 
        _executeAppwriteFunction(_mpesaQueryFunctionId, {'checkoutRequestID': checkoutRequestID})
      );

      final responseData = _extractFunctionResponse(response);
      return PaymentStatusResponse.fromJson(responseData);
    } catch (error) {
      final mpesaError = handleError(error);
      debugPrint('Payment query error: ${mpesaError.toString()}');
      return PaymentStatusResponse.error(mpesaError.message);
    }
  }

  /// Formats a phone number to the required format (254XXXXXXXXX)
  String? formatPhoneNumber(String phone) {
    // Remove any spaces, dashes or other separators
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle case where user includes the + sign (e.g., +254...)
    if (phone.startsWith('+')) {
      cleaned = cleaned;
    }
    
    // If starts with 0, replace with 254
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      cleaned = '254${cleaned.substring(1)}';
    }
    
    // If starts with 7 or 1, prefix with 254
    if ((cleaned.startsWith('7') || cleaned.startsWith('1')) && cleaned.length == 9) {
      cleaned = '254$cleaned';
    }
    
    // Validate the resulting number
    if (cleaned.startsWith('254') && cleaned.length == 12) {
      return cleaned;
    }
    
    return null; // Invalid format
  }

  /// Validates if the payment amount is within acceptable range
  bool validatePaymentAmount(double amount) {
    // M-Pesa has minimum and maximum limits
    const double MIN_AMOUNT = 1.0;
    const double MAX_AMOUNT = 150000.0;
    
    return amount >= MIN_AMOUNT && amount <= MAX_AMOUNT;
  }

  /// Handles and formats errors from the API
  MpesaException handleError(dynamic error) {
    if (error is MpesaException) {
      return error;
    }
    
    if (error is http.ClientException) {
      return MpesaException(
        'Network error: ${error.message}',
        originalError: error,
      );
    }
    
    if (error is FormatException) {
      return MpesaException(
        'Invalid response format: ${error.message}',
        originalError: error,
      );
    }
    
    return MpesaException(
      'M-Pesa operation failed: ${error.toString()}',
      originalError: error,
    );
  }

  /// Respects rate limiting by ensuring minimum time between requests
  Future<void> _respectRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        final waitTime = _minRequestInterval - elapsed;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Executes a function with retry logic
  Future<http.Response> _executeWithRetry(Future<http.Response> Function() operation) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        final response = await operation();
        
        // Check if we should retry based on status code
        if (response.statusCode >= 500) {
          throw http.ClientException('Server error: ${response.statusCode}');
        }
        
        return response;
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        
        // Only retry on network/server errors, not on client errors
        if (e is http.ClientException && e.message.contains('4')) {
          rethrow;
        }
        
        debugPrint('Retrying operation (${attempts}/${_maxRetries}) after error: $e');
        await Future.delayed(_retryDelay * attempts);
      }
    }
    
    throw MpesaException('Maximum retry attempts exceeded');
  }
  
  /// Complete payment flow with status monitoring
  Future<PaymentStatusResponse> processPaymentWithStatusCheck({
    required PaymentRequest request,
    Duration maxWaitTime = const Duration(minutes: 2),
    Duration checkInterval = const Duration(seconds: 5),
  }) async {
    try {
      // Step 1: Initiate STK Push
      final stkResponse = await initiateSTKPush(request);
      
      if (!stkResponse.success || stkResponse.checkoutRequestID == null) {
        return PaymentStatusResponse.error(
          stkResponse.errorMessage ?? 'Failed to initiate payment'
        );
      }

      // Step 2: Monitor payment status
      final checkoutRequestID = stkResponse.checkoutRequestID!;
      final startTime = DateTime.now();
      
      while (DateTime.now().difference(startTime) < maxWaitTime) {
        await Future.delayed(checkInterval);
        
        final statusResponse = await queryPaymentStatus(checkoutRequestID);
        
        if (statusResponse.success) {
          // If payment is completed or failed, return immediately
          if (statusResponse.status == PaymentStatus.completed ||
              statusResponse.status == PaymentStatus.failed ||
              statusResponse.status == PaymentStatus.cancelled) {
            return statusResponse;
          }
        }
      }
      
      // Timeout reached
      return PaymentStatusResponse.error('Payment status check timed out');
      
    } catch (error) {
      return PaymentStatusResponse.error(
        'Payment processing failed: ${error.toString()}'
      );
    }
  }

  /// Validates transaction before processing
  Future<Map<String, dynamic>> validateTransaction(PaymentRequest request) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Phone number validation
    if (formatPhoneNumber(request.phone) == null) {
      errors.add('Invalid phone number format');
    }
    
    // Amount validation
    final amount = double.tryParse(request.amount) ?? 0;
    if (!validatePaymentAmount(amount)) {
      errors.add('Amount must be between KES 1 and KES 150,000');
    }
    
    // Additional validations
    if (request.accountReference.isEmpty) {
      warnings.add('Account reference is empty');
    }
    
    if (request.transactionDesc.isEmpty) {
      warnings.add('Transaction description is empty');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// Utility method to test connection to M-Pesa services
  Future<bool> testConnection() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  /// Get payment method information
  Map<String, dynamic> getPaymentMethodInfo() {
    return {
      'name': 'M-Pesa',
      'currency': 'KES',
      'minAmount': 1.0,
      'maxAmount': 150000.0,
      'supportedCountries': ['KE'],
      'processingTime': '1-5 minutes',
      'fees': 'As per M-Pesa rates',
    };
  }

  /// Format amount for display
  String formatAmount(double amount, {String currency = 'KES'}) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Generate a unique transaction reference
  String generateTransactionReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'DDME_$timestamp';
  }

  /// Dispose method to clean up resources
  void dispose() {
    _cachedToken = null;
    _tokenExpiry = null;
    _lastRequestTime = null;
    _httpClient.close();
  }
}