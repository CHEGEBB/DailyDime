class AppConfig {
  // ========================================
  // APPWRITE CONFIGURATION
  // ========================================
  
  // 🔧 Replace these values with your actual Appwrite project details
  static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  static const String appwriteProjectId = '687ccf6e002704f4d3c8';
  
  // 🗄️ DATABASE CONFIGURATION
  static const String databaseId = '687cd2a600076b9b4bdf'; // Replace if you used different name
  
  // 📊 COLLECTION IDs (You'll create these next)
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String budgetsCollection = 'budgets';
  static const String savingsGoalsCollection = 'savings_goals';
  static const String categoriesCollection = 'categories';
  
  // 📁 STORAGE BUCKET IDs
  static const String receiptsBucket = 'receipts';
  static const String documentsBucket = 'documents';
  static const String dailydimeBucket = 'dailydime'; // Your existing bucket
  
  // ⚙️ APPWRITE FUNCTION IDs (For later when you create functions)
  static const String aiBudgetFunction = 'ai-budget-generator';
  static const String mpesaFunction = 'mpesa-integration';
  static const String smsAnalyzerFunction = 'sms-analyzer';
  
  // ========================================
  // AI & EXTERNAL API CONFIGURATION
  // ========================================
  
  // 🤖 AI Configuration (Add when you get Gemini API key)
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Replace later
  
  // 💰 M-Pesa Configuration (Add when you get M-Pesa credentials)
  static const String mpesaConsumerKey = 'YOUR_MPESA_CONSUMER_KEY';
  static const String mpesaConsumerSecret = 'YOUR_MPESA_CONSUMER_SECRET';
  static const String mpesaPasskey = 'YOUR_MPESA_PASSKEY';
  static const String mpesaShortcode = 'YOUR_MPESA_SHORTCODE';
  
  // ========================================
  // APP CONFIGURATION
  // ========================================
  
  // 🌍 Environment
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool enableLogging = !isProduction;
  
  // 📱 App Settings
  static const String appName = 'DailyDime';
  static const String appVersion = '1.0.0';
  
  // 🔔 Notification Settings
  static const bool enablePushNotifications = true;
  static const bool enableSMSParsing = true;
  
  // 💾 Local Storage Settings
  static const String hiveBoxName = 'dailydime_box';
  static const String userPrefsKey = 'user_preferences';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Get full collection path for Appwrite operations
  static String getCollectionPath(String collectionId) {
    return 'databases.$databaseId.collections.$collectionId';
  }
  
  /// Get full bucket path for Appwrite operations
  static String getBucketPath(String bucketId) {
    return 'buckets.$bucketId';
  }
  
  /// Check if all required Appwrite configs are set
  static bool get isAppwriteConfigured {
    return appwriteProjectId != 'YOUR_PROJECT_ID' && 
           appwriteProjectId.isNotEmpty;
  }
  
  /// Get environment display name
  static String get environmentName {
    return isProduction ? 'Production' : 'Development';
  }
}

