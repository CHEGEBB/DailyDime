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

  // Store userId temporarily for email verification flow
  String? _tempUserId;
  String? get tempUserId => _tempUserId;

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

  // Create a new account (without session - for email verification flow)
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
      
      // Store the userId for verification
      _tempUserId = user.$id;
      
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Create account and immediately create session (skip email verification)
  Future<models.User> createAccountWithSession({
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

  // Create email verification (for existing users with session)
  Future<models.Token> createEmailVerification() async {
    try {
      return await account.createVerification(
        url: 'https://dailydime.com/verify', // Replace with your verification URL
      );
    } catch (e) {
      rethrow;
    }
  }

  // Verify the email verification (for existing users)
  Future<models.Token> confirmVerification({
    required String userId,
    required String secret,
  }) async {
    try {
      return await account.updateVerification(
        userId: userId, 
        secret: secret
      );
    } catch (e) {
      rethrow;
    }
  }

  // Create email token (6-digit code for new user verification/login)
  Future<models.Token> createEmailToken({required String email}) async {
    try {
      final token = await account.createEmailToken(
        userId: ID.unique(),
        email: email,
      );
      
      // Store the userId from the token for later use
      _tempUserId = token.userId;
      
      return token;
    } catch (e) {
      rethrow;
    }
  }

  // Send verification code for existing user (without creating new user)
  Future<models.Token> sendVerificationCode({required String email}) async {
    try {
      // For existing users, we can use the email token method
      // But we need to find the user first or use a different approach
      return await createEmailToken(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Verify email token (6-digit code) and create session
  Future<models.Session> verifyEmailToken({
    required String userId,
    required String secret,
  }) async {
    try {
      final session = await account.createSession(
        userId: userId,
        secret: secret,
      );
      
      // Clear temp userId after successful verification
      _tempUserId = null;
      
      return session;
    } catch (e) {
      rethrow;
    }
  }

  // Verify code and create account (complete registration flow)
  Future<models.Session> verifyCodeAndCreateSession({
    required String code,
  }) async {
    try {
      if (_tempUserId == null) {
        throw Exception('No pending verification. Please request a new code.');
      }
      
      return await verifyEmailToken(
        userId: _tempUserId!,
        secret: code,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Alternative method: Create magic link session (if your app supports it)
  Future<models.Token> createMagicLinkSession({
    required String email,
    String? url,
  }) async {
    try {
      return await account.createMagicURLToken(
        userId: ID.unique(),
        email: email,
        url: url ?? 'https://dailydime.com/auth',
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

  // Check if user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = await getCurrentUser();
      return user?.emailVerification ?? false;
    } catch (e) {
      return false;
    }
  }

  // Clear temporary user ID (call this if user cancels verification)
  void clearTempUserId() {
    _tempUserId = null;
  }

  // Handle authentication errors
  String handleAuthError(Object e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 401:
          return 'Invalid credentials. Please check your email and verification code.';
        case 409:
          return 'An account with this email already exists.';
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        case 500:
          return 'Server error. Please try again later.';
        case 400:
          if (e.message?.contains('verification') == true) {
            return 'Invalid verification code. Please check and try again.';
          }
          if (e.message?.contains('token') == true) {
            return 'Verification code expired or invalid. Please request a new one.';
          }
          return 'Invalid request: ${e.message}';
        default:
          return e.message ?? 'An unknown error occurred';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}