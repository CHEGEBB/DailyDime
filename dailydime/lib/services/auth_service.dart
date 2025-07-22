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
  
  // Initialize account directly - no need for separate initialize method
  late final Account account = Account(client);

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

  // Logout from all sessions
  Future<void> logoutFromAllSessions() async {
    try {
      await account.deleteSessions();
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

  // Update account name
  Future<models.User> updateAccountName({required String name}) async {
    try {
      return await account.updateName(name: name);
    } catch (e) {
      rethrow;
    }
  }

  // Update account email
  Future<models.User> updateEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await account.updateEmail(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update account password
  Future<models.User> updatePassword({
    required String password,
    required String oldPassword,
  }) async {
    try {
      return await account.updatePassword(
        password: password,
        oldPassword: oldPassword,
      );
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

  // Create email verification
  Future<models.Token> createEmailVerification({required String url}) async {
    try {
      return await account.createVerification(url: url);
    } catch (e) {
      rethrow;
    }
  }

  // Confirm email verification
  Future<models.Token> confirmEmailVerification({
    required String userId,
    required String secret,
  }) async {
    try {
      return await account.updateVerification(
        userId: userId,
        secret: secret,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get current session
  Future<models.Session?> getCurrentSession() async {
    try {
      return await account.getSession(sessionId: 'current');
    } catch (e) {
      return null;
    }
  }

  // Get all sessions
  Future<models.SessionList?> getAllSessions() async {
    try {
      return await account.listSessions();
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Handle authentication errors
  String handleAuthError(Object e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 401:
          return 'Invalid credentials. Please check your email and password.';
        case 409:
          return 'An account with this email already exists.';
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return e.message ?? 'An unknown error occurred';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Clean up resources (optional)
  void dispose() {
    // Any cleanup code if needed
  }
}