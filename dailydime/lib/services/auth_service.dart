import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:dailydime/config/app_config.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Initialize Appwrite client
  final Client client = Client()
    ..setEndpoint(AppConfig.appwriteEndpoint)
    ..setProject(AppConfig.appwriteProjectId)
    ..setSelfSigned(status: true); // Remove this in production
  
  late final Account account;
  
  // Initialize the account instance
  void initialize() {
    account = Account(client);
  }

  // Get the current user
  Future<models.User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }
  // Create OAuth2 session (Google, Facebook, Apple)
Future<void> createOAuthSession(String provider) async {
  try {
    OAuthProvider oauthProvider;
    switch (provider.toLowerCase()) {
      case 'google':
        oauthProvider = OAuthProvider.google;
        break;
      case 'facebook':
        oauthProvider = OAuthProvider.facebook;
        break;
      case 'apple':
        oauthProvider = OAuthProvider.apple;
        break;
      default:
        throw ArgumentError('Unsupported OAuth provider: $provider');
    }
    await account.createOAuth2Session(provider: oauthProvider);
  } catch (e) {
    rethrow;
  }
}

  // Create a new account
  Future<models.User> createAccount({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      
      // Create session after account creation
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login with email and password
  Future<models.Session> login({
    required String email,
    required String password,
  }) async {
    try {
      return await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await account.createRecovery(
        email: email,
        url: 'https://dailydime.com/recovery', // Update with your recovery URL
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update account
  Future<models.User> updateAccount({
    String? name,
    String? phone,
  }) async {
    try {
      return await account.updateName(name: name ?? '');
    } catch (e) {
      rethrow;
    }
  }



  // Create phone session
  Future<models.Token> createPhoneSession({required String phone}) async {
    try {
      return await account.createPhoneToken(
        userId: ID.unique(),
        phone: phone,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Verify phone session
  Future<models.Session> verifyPhoneSession({
    required String userId,
    required String secret,
  }) async {
    try {
      return await account.updatePhoneSession(
        userId: userId,
        secret: secret,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Handle authentication errors
  String handleAuthError(Object e) {
    if (e is AppwriteException) {
      return e.message ?? 'An unknown error occurred';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}