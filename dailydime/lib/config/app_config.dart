// lib/config/app_config.dart

class AppConfig {
  // API Keys
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String mpesaConsumerKey = 'YOUR_MPESA_CONSUMER_KEY';
  static const String mpesaConsumerSecret = 'YOUR_MPESA_CONSUMER_SECRET';
  static const String mpesaPasskey = 'YOUR_MPESA_PASSKEY';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
  
  // App Constants
  static const String appName = 'DailyDime';
  static const String appVersion = '1.0.0';
  
  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableSMSReading = true;
  static const bool enableMPesaIntegration = true;
  
  // AI Model Settings
  static const String aiModelVersion = 'Gemini 2.0 Flash';
  static const int maxTokens = 1024;
  static const double temperature = 0.7;
  
  // App URLs
  static const String privacyPolicyUrl = 'https://dailydime.app/privacy';
  static const String termsOfServiceUrl = 'https://dailydime.app/terms';
  static const String helpCenterUrl = 'https://dailydime.app/help';
}