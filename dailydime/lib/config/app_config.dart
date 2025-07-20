  class AppConfig {
  // ========== APPWRITE CONFIGURATION ==========
  static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  static const String appwriteProjectId = '687ccf6e002704f4d3c8'; // YOUR ACTUAL PROJECT ID
  
  // Database Configuration
  static const String databaseId = '687cd2a600076b9b4bdf'; // YOUR ACTUAL DATABASE ID
  
  // ========== COLLECTIONS ==========
  static const String usersCollection = '687d25c5003848963461';
  static const String transactionsCollection = '687d279f0017bd2ecce1';
  static const String budgetsCollection = '687d29390004ed2dfd95';
  static const String savingsGoalsCollection = '687d2ae7002eba8fad3c';
  static const String categoriesCollection = 'categories';
  
  // ========== STORAGE BUCKETS ==========
  static const String mainBucket = 'dailydime'; // Your existing bucket
  
  // ========== M-PESA DARAJA CONFIGURATION ==========
  static const String mpesaConsumerKey = 'YOUR_CONSUMER_KEY';
  static const String mpesaConsumerSecret = 'YOUR_CONSUMER_SECRET';
  static const String mpesaPasskey = 'YOUR_PASSKEY';
  static const String mpesaShortcode = '174379'; // Sandbox shortcode
  static const String mpesaEnvironment = 'sandbox'; // Change to 'production' later
  
  // M-Pesa URLs
  static const String mpesaBaseUrl = 'https://sandbox.safaricom.co.ke';
  static const String mpesaAuthUrl = '/oauth/v1/generate?grant_type=client_credentials';
  static const String mpesaStkPushUrl = '/mpesa/stkpush/v1/processrequest';
  static const String mpesaAccountBalanceUrl = '/mpesa/accountbalance/v1/query';
  static const String mpesaTransactionStatusUrl = '/mpesa/transactionstatus/v1/query';
  
  // ========== AI CONFIGURATION ==========
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String geminiModel = 'gemini-2.0-flash-exp';
  
  // ========== APP SETTINGS ==========
  static const String appName = 'DailyDime';
  static const String appVersion = '1.0.0';
  static const String primaryCurrency = 'KES';
  static const String currencySymbol = 'Ksh';
  
  // ========== HELPER METHODS ==========
  static String formatCurrency(int amountInCents) {
    double amount = amountInCents / 100.0;
    return '$currencySymbol ${amount.toStringAsFixed(2)}';
  }
  
  static int parseAmountToCents(double amount) {
    return (amount * 100).round();
  }
  
  static bool isValidPhoneNumber(String phone) {
    // Kenyan phone number validation
    final RegExp phoneRegex = RegExp(r'^\+?254[17]\d{8}$|^0[17]\d{8}$');
    return phoneRegex.hasMatch(phone);
  }
  
  static String formatPhoneNumber(String phone) {
    // Convert to international format
    if (phone.startsWith('0')) {
      return '254${phone.substring(1)}';
    } else if (phone.startsWith('+254')) {
      return phone.substring(1);
    } else if (phone.startsWith('254')) {
      return phone;
    }
    return phone;
  }
  
  // Environment check
  static bool get isProduction => mpesaEnvironment == 'production';
  static bool get isDevelopment => !isProduction;
}
