// lib/services/appwrite_service.dart

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:flutter/material.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'dart:typed_data';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  late Functions functions;
  
  String? currentUserId;
  
  AppwriteService._internal() {
    _initializeAppwrite();
  }
  
  void _initializeAppwrite() {
    client = Client()
      ..setEndpoint(AppConfig.appwriteEndpoint)
      ..setProject(AppConfig.appwriteProjectId);
    
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    functions = Functions(client);
  }
  
  Future<void> initialize() async {
    try {
      final user = await account.get();
      currentUserId = user.$id;
    } catch (e) {
      // User is not logged in, proceed as anonymous
      debugPrint('Appwrite: No user logged in');
    }
  }

  // Helper method to check user session
  Future<void> _checkUserSession() async {
    if (currentUserId == null) {
      throw Exception('User is not logged in');
    }
  }

  // USER AUTHENTICATION METHODS

  /// Get current user
  Future<models.User?> getCurrentUser() async {
    try {
      final user = await account.get();
      currentUserId = user.$id;
      return user;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      currentUserId = null;
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      await account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Login user with email and password
  Future<models.Session?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      
      // Update current user ID
      final user = await account.get();
      currentUserId = user.$id;
      
      return session;
    } catch (e) {
      debugPrint('Error logging in user: $e');
      throw Exception('Failed to login: $e');
    }
  }

  /// Register new user
  Future<models.User?> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      
      // Auto-login after registration
      await loginUser(email: email, password: password);
      
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      throw Exception('Failed to register: $e');
    }
  }

  /// Logout current user
  Future<void> logoutUser() async {
    try {
      await account.deleteSession(sessionId: 'current');
      currentUserId = null;
    } catch (e) {
      debugPrint('Error logging out user: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  /// Delete current user account
  Future<void> deleteCurrentUser() async {
    try {
      await _checkUserSession();
      
      // Delete user profile first if it exists
      final profile = await getUserProfile(currentUserId!);
      if (profile != null) {
        await deleteUserProfile(profile.$id);
      }
      
      // Delete user account
      await account.updateStatus();
      currentUserId = null;
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  // USER PROFILE METHODS

  /// Create user profile
  Future<models.Document> createUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? occupation,
    String? location,
  }) async {
    try {
      return await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'name': name,
          'email': email,
          'phone': phone,
          'occupation': occupation,
          'location': location,
          'profileImageId': null,
          'notificationsEnabled': true,
          'darkModeEnabled': false,
          'biometricsEnabled': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  /// Get user profile by user ID
  Future<models.Document?> getUserProfile(String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      if (response.documents.isNotEmpty) {
        return response.documents.first;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Get profile by document ID
  Future<models.Document?> getProfileById(String profileId) async {
    try {
      return await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        documentId: profileId,
      );
    } catch (e) {
      if (e is AppwriteException && e.code == 404) {
        return null; // Profile not found
      }
      debugPrint('Error getting profile by ID: $e');
      return null;
    }
  }

  /// Update user profile
  Future<models.Document> updateUserProfile({
    required String profileId,
    String? name,
    String? phone,
    String? occupation,
    String? location,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? biometricsEnabled,
  }) async {
    try {
      Map<String, dynamic> data = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (occupation != null) data['occupation'] = occupation;
      if (location != null) data['location'] = location;
      if (notificationsEnabled != null) data['notificationsEnabled'] = notificationsEnabled;
      if (darkModeEnabled != null) data['darkModeEnabled'] = darkModeEnabled;
      if (biometricsEnabled != null) data['biometricsEnabled'] = biometricsEnabled;

      return await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        documentId: profileId,
        data: data,
      );
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String profileId) async {
    try {
      // First, get the profile to check for profile image
      final profile = await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        documentId: profileId,
      );
      
      // Delete profile image if exists
      final imageId = profile.data['profileImageId'];
      if (imageId != null) {
        try {
          await storage.deleteFile(
            bucketId: AppConfig.mainBucket,
            fileId: imageId,
          );
        } catch (e) {
          debugPrint('Error deleting profile image: $e');
        }
      }
      
      // Delete the profile document
      await databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        documentId: profileId,
      );
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      throw Exception('Failed to delete profile: $e');
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final file = await storage.createFile(
        bucketId: AppConfig.mainBucket,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: bytes,
          filename: fileName,
        ),
      );
      
      return file.$id;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Update profile image
  Future<models.Document> updateProfileImage({
    required String profileId,
    required String imageId,
  }) async {
    try {
      // Delete old profile image if exists
      final profile = await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        documentId: profileId,
      );
      
      final oldImageId = profile.data['profileImageId'];
      
      if (oldImageId != null) {
        try {
          await storage.deleteFile(
            bucketId: AppConfig.mainBucket,
            fileId: oldImageId,
          );
        } catch (e) {
          debugPrint('Error deleting old image: $e');
        }
      }
      
      // Update profile with new image ID
      return await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollection,
        documentId: profileId,
        data: {
          'profileImageId': imageId,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      throw Exception('Failed to update profile image: $e');
    }
  }

  /// Get profile image URL
  String getProfileImageUrl(String imageId) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${AppConfig.appwriteEndpoint}/storage/buckets/${AppConfig.mainBucket}/files/$imageId/view?project=${AppConfig.appwriteProjectId}&mode=admin&cache=$timestamp';
    } catch (e) {
      debugPrint('Error getting profile image URL: $e');
      throw Exception('Failed to get image URL: $e');
    }
  }

  /// Check if profile exists for user
  Future<bool> profileExists(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  /// Get current user profile (convenience method)
  Future<models.Document?> getCurrentUserProfile() async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        return await getUserProfile(user.$id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user profile: $e');
      return null;
    }
  }

  /// Create profile for current user
  Future<models.Document?> createCurrentUserProfile({
    required String name,
    String? phone,
    String? occupation,
    String? location,
  }) async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        return await createUserProfile(
          userId: user.$id,
          name: name,
          email: user.email,
          phone: phone,
          occupation: occupation,
          location: location,
        );
      }
      throw Exception('No user logged in');
    } catch (e) {
      debugPrint('Error creating current user profile: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  /// Send password recovery email
  Future<void> sendPasswordRecovery(String email) async {
    try {
      await account.createRecovery(
        email: email,
        url: '${AppConfig.appUrl}/reset-password', // Configure this URL
      );
    } catch (e) {
      debugPrint('Error sending password recovery: $e');
      throw Exception('Failed to send recovery email: $e');
    }
  }

  /// Complete password recovery
  Future<void> completePasswordRecovery({
    required String userId,
    required String secret,
    required String newPassword,
  }) async {
    try {
      await account.updateRecovery(
        userId: userId,
        secret: secret,
        password: newPassword,
      );
    } catch (e) {
      debugPrint('Error completing password recovery: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Update user password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await account.updatePassword(
        password: newPassword,
        oldPassword: currentPassword,
      );
    } catch (e) {
      debugPrint('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  /// Update user email
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      await account.updateEmail(
        email: newEmail,
        password: password,
      );
    } catch (e) {
      debugPrint('Error updating email: $e');
      throw Exception('Failed to update email: $e');
    }
  }

  /// Get user sessions
  Future<models.SessionList> getUserSessions() async {
    try {
      return await account.listSessions();
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      throw Exception('Failed to get sessions: $e');
    }
  }

  /// Delete specific session
  Future<void> deleteSession(String sessionId) async {
    try {
      await account.deleteSession(sessionId: sessionId);
    } catch (e) {
      debugPrint('Error deleting session: $e');
      throw Exception('Failed to delete session: $e');
    }
  }

  /// Delete all sessions except current
  Future<void> deleteAllOtherSessions() async {
    try {
      await account.deleteSessions();
    } catch (e) {
      debugPrint('Error deleting sessions: $e');
      throw Exception('Failed to delete sessions: $e');
    }
  }
  
  // BUDGET METHODS (keeping existing methods)
  
  // Get all budgets from Appwrite
  Future<List<Budget>> getBudgets({int? limit, String? cursor}) async {
    try {
      if (currentUserId == null) {
        return [];
      }
      
      final queries = [
        Query.equal('user_id', currentUserId!),
        Query.orderDesc('\$createdAt'),
      ];
      
      // Add limit if provided
      if (limit != null) {
        queries.add(Query.limit(limit));
      }
      
      // Add cursor for pagination if provided
      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
        queries: queries,
      );
      
      return response.documents.map((doc) {
        final data = doc.data;
        return _convertAppwriteToBudget(data, doc.$id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      return [];
    }
  }
  
  // Create a new budget in Appwrite
  Future<void> createBudget(Budget budget) async {
    try {
      if (currentUserId == null) {
        // Can't create without a user
        return;
      }
      
      final data = _convertBudgetToAppwrite(budget);
      data['user_id'] = currentUserId;
      
      await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
        documentId: budget.id,
        data: data,
      );
    } catch (e) {
      debugPrint('Error creating budget: $e');
      throw Exception('Failed to create budget in Appwrite: $e');
    }
  }
  
  // Update an existing budget in Appwrite
  Future<void> updateBudget(Budget budget) async {
    try {
      if (currentUserId == null) {
        // Can't update without a user
        return;
      }
      
      final data = _convertBudgetToAppwrite(budget);
      
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
        documentId: budget.id,
        data: data,
      );
    } catch (e) {
      debugPrint('Error updating budget: $e');
      throw Exception('Failed to update budget in Appwrite: $e');
    }
  }
  
  // Delete a budget from Appwrite
  Future<void> deleteBudget(String budgetId) async {
    try {
      await databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
        documentId: budgetId,
      );
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      throw Exception('Failed to delete budget from Appwrite: $e');
    }
  }

  // Get daily spending data for a specific budget category
  Future<List<double>> getDailySpendingForBudget(
    String categoryId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      if (currentUserId == null) {
        return List.filled(7, 0.0); // Return 7 days of zero spending
      }

      // Calculate the number of days between start and end dates
      final int daysDifference = endDate.difference(startDate).inDays + 1;
      final List<double> dailySpending = List.filled(daysDifference, 0.0);

      // Get transactions for the date range and category
      final queries = [
        Query.equal('user_id', currentUserId!),
        Query.greaterThanEqual('date', startDate.toIso8601String()),
        Query.lessThanEqual('date', endDate.toIso8601String()),
        Query.equal('category', categoryId),
        Query.orderAsc('date'),
      ];

      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        queries: queries,
      );

      // Process transactions and group by day
      for (final doc in response.documents) {
        final data = doc.data;
        final transaction = Transaction.fromJson(data);
        
        // Calculate the day index from start date
        final transactionDate = DateTime.parse(transaction.date as String);
        final dayIndex = transactionDate.difference(startDate).inDays;
        
        // Only include expenses (negative amounts)
        if (dayIndex >= 0 && dayIndex < daysDifference && transaction.amount < 0) {
          dailySpending[dayIndex] += transaction.amount.abs();
        }
      }

      return dailySpending;
    } catch (e) {
      debugPrint('Error fetching daily spending for budget: $e');
      // Return array filled with zeros as fallback
      final int daysDifference = endDate.difference(startDate).inDays + 1;
      return List.filled(daysDifference, 0.0);
    }
  }

  // Get spending by category for a date range
  Future<Map<String, double>> getSpendingByCategory(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      if (currentUserId == null) {
        return {};
      }

      final queries = [
        Query.equal('user_id', currentUserId!),
        Query.greaterThanEqual('date', startDate.toIso8601String()),
        Query.lessThanEqual('date', endDate.toIso8601String()),
        Query.orderDesc('date'),
      ];

      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        queries: queries,
      );

      final Map<String, double> categorySpending = {};

      for (final doc in response.documents) {
        final data = doc.data;
        final transaction = Transaction.fromJson(data);
        
        // Only include expenses (negative amounts)
        if (transaction.amount < 0) {
          final category = transaction.category ?? 'Other';
          categorySpending[category] = (categorySpending[category] ?? 0.0) + transaction.amount.abs();
        }
      }

      return categorySpending;
    } catch (e) {
      debugPrint('Error fetching spending by category: $e');
      return {};
    }
  }
  
  // Helper method to convert Budget to Appwrite format
  Map<String, dynamic> _convertBudgetToAppwrite(Budget budget) {
    return {
      'title': budget.title,
      'period_type': _periodToString(budget.period),
      'total_amount': (budget.amount * 100).toInt(), // Store as cents
      'spent_amount': (budget.spent * 100).toInt(), // Store as cents
      'categories': [budget.category],
      'status': budget.isActive ? 'active' : 'inactive',
      'start_date': budget.startDate.toIso8601String(),
      'end_date': budget.endDate.toIso8601String(),
      'created_at': budget.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
  
  // Helper method to convert Appwrite data to Budget
  Budget _convertAppwriteToBudget(Map<String, dynamic> data, String docId) {
    // Extract period from string
    final periodType = data['period_type'] ?? 'monthly';
    final period = _stringToPeriod(periodType);
    
    // Convert cents to dollars
    final totalAmount = (data['total_amount'] ?? 0) / 100.0;
    final spentAmount = (data['spent_amount'] ?? 0) / 100.0;
    
    // Extract category (use first category or default)
    final categories = data['categories'] as List<dynamic>? ?? [];
    final category = categories.isNotEmpty ? categories[0].toString() : 'Other';
    
    // Parse dates
    DateTime startDate;
    DateTime endDate;
    try {
      startDate = DateTime.parse(data['start_date']);
      endDate = DateTime.parse(data['end_date']);
    } catch (e) {
      // Default dates if parsing fails
      startDate = DateTime.now();
      endDate = DateTime.now().add(const Duration(days: 30));
    }
    
    // Extract timestamps
    DateTime? createdAt;
    DateTime? updatedAt;
    try {
      createdAt = data['created_at'] != null ? DateTime.parse(data['created_at']) : null;
      updatedAt = data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null;
    } catch (e) {
      // Ignore parsing errors for timestamps
    }
    
    // Create Budget object
    return Budget(
      id: docId,
      title: data['title'] ?? 'Budget',
      category: category,
      amount: totalAmount,
      spent: spentAmount,
      period: period,
      startDate: startDate,
      endDate: endDate,
      color: Colors.blue, // Default color
      icon: Icons.account_balance_wallet, // Default icon
      tags: List<String>.from(categories),
      isActive: data['status'] == 'active',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  // Helper to convert BudgetPeriod enum to string
  String _periodToString(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'daily';
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.yearly:
        return 'yearly';
      case BudgetPeriod.monthly:
      default:
        return 'monthly';
    }
  }
  
  // Helper to convert string to BudgetPeriod enum
  BudgetPeriod _stringToPeriod(String periodStr) {
    switch (periodStr.toLowerCase()) {
      case 'daily':
        return BudgetPeriod.daily;
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'yearly':
        return BudgetPeriod.yearly;
      case 'monthly':
      default:
        return BudgetPeriod.monthly;
    }
  }
  
  // TRANSACTION METHODS (keeping existing methods)
  
  // Sync transaction to Appwrite
  Future<void> syncTransaction(Transaction transaction) async {
    try {
      if (currentUserId == null) {
        // We can't sync without a logged-in user
        return;
      }
      
      final data = transaction.toJson();
      data['user_id'] = currentUserId;
      
      await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        documentId: transaction.id,
        data: data,
      );
    } catch (e) {
      debugPrint('Error syncing transaction: $e');
    }
  }

  // Get transactions with optional parameters
  Future<List<Transaction>> getTransactions({int? limit, String? cursor}) async {
    try {
      if (currentUserId == null) {
        return [];
      }
      
      final queries = [
        Query.equal('user_id', currentUserId!),
        Query.orderDesc('date'),
      ];
      
      // Add limit if provided
      if (limit != null) {
        queries.add(Query.limit(limit));
      }
      
      // Add cursor for pagination if provided
      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        queries: queries,
      );
      
      return response.documents.map((doc) {
        final data = doc.data;
        return Transaction.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  // Helper method to get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    String? cursor,
  }) async {
    try {
      if (currentUserId == null) {
        return [];
      }
      
      final queries = [
        Query.equal('user_id', currentUserId!),
        Query.greaterThanEqual('date', startDate.toIso8601String()),
        Query.lessThanEqual('date', endDate.toIso8601String()),
        Query.orderDesc('date'),
      ];
      
      // Add limit if provided
      if (limit != null) {
        queries.add(Query.limit(limit));
      }
      
      // Add cursor for pagination if provided
      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        queries: queries,
      );
      
      return response.documents.map((doc) {
        final data = doc.data;
        return Transaction.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions by date range: $e');
      return [];
    }
  }

  // Helper method to get recent transactions (last N days)
  Future<List<Transaction>> getRecentTransactions({
    int days = 90,
    int? limit,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    return await getTransactionsByDateRange(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        documentId: id,
      );
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
  }
  
  // Balance method
  Future<void> updateBalance(double balance) async {
    try {
      if (currentUserId == null) {
        return;
      }
      
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.usersCollection,
        documentId: currentUserId!,
        data: {
          'current_balance': balance,
        },
      );
    } catch (e) {
      debugPrint('Error updating balance: $e');
    }
  }

  // SAVINGS GOAL METHODS (keeping existing methods but truncated for space)

  // SAVINGS GOAL METHODS (continuing from previous)

  // Helper method to convert SavingsGoalCategory enum to string for Appwrite
  String _savingsGoalCategoryToString(SavingsGoalCategory category) {
    switch (category) {
      case SavingsGoalCategory.emergency:
        return 'emergency';
      case SavingsGoalCategory.education:
        return 'education';
      case SavingsGoalCategory.retirement:
        return 'retirement';
      case SavingsGoalCategory.investment:
        return 'investment';
      case SavingsGoalCategory.electronics:
        return 'electronics';
      case SavingsGoalCategory.other:
      default:
        return 'other';
    }
  }

  // Helper method to convert string to SavingsGoalCategory enum
  SavingsGoalCategory _stringToSavingsGoalCategory(String categoryStr) {
    switch (categoryStr.toLowerCase()) {
      case 'emergency':
        return SavingsGoalCategory.emergency;
      case 'education':
        return SavingsGoalCategory.education;
      case 'retirement':
        return SavingsGoalCategory.retirement;
      case 'investment':
        return SavingsGoalCategory.investment;
      case 'electronics':
        return SavingsGoalCategory.electronics;
      case 'other':
      default:
        return SavingsGoalCategory.other;
    }
  }

  // Helper method to convert SavingsGoalStatus enum to string for Appwrite
  String _savingsGoalStatusToString(SavingsGoalStatus status) {
    switch (status) {
      case SavingsGoalStatus.active:
        return 'active';
      case SavingsGoalStatus.paused:
        return 'paused';
      case SavingsGoalStatus.completed:
        return 'completed';
      case SavingsGoalStatus.upcoming:
        return 'upcoming';
      default:
        return 'active';
    }
  }

  // Helper method to convert string to SavingsGoalStatus enum
  SavingsGoalStatus _stringToSavingsGoalStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'active':
        return SavingsGoalStatus.active;
      case 'paused':
        return SavingsGoalStatus.paused;
      case 'completed':
        return SavingsGoalStatus.completed;
      case 'upcoming':
        return SavingsGoalStatus.upcoming;
      default:
        return SavingsGoalStatus.active;
    }
  }

  // Convert SavingsGoal to Appwrite format
  Map<String, dynamic> _convertSavingsGoalToAppwrite(SavingsGoal goal) {
    return {
      'user_id': currentUserId!,
      'title': goal.title,
      'description': goal.description ?? '',
      'target_amount': (goal.targetAmount * 100).toInt(), // Store as cents
      'current_amount': (goal.currentAmount * 100).toInt(), // Store as cents
      'daily_target': goal.dailyTarget != null ? (goal.dailyTarget! * 100).toInt() : null,
      'weekly_target': goal.weeklyTarget != null ? (goal.weeklyTarget! * 100).toInt() : null,
      'priority': goal.priority,
      'category': _savingsGoalCategoryToString(goal.category), // Convert enum to string
      'deadline': goal.targetDate.toIso8601String(),
      'status': _savingsGoalStatusToString(goal.status), // Convert enum to string
      'created_at': goal.createdAt.toIso8601String(),
      'updated_at': goal.updatedAt.toIso8601String(),
      'start_date': goal.startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'icon_asset': goal.iconAsset,
      'color': goal.color.value, // Store as integer
      'is_recurring': goal.isRecurring,
      'reminder_frequency': goal.reminderFrequency,
      'is_ai_suggested': goal.isAiSuggested ?? false,
      'ai_suggestion_reason': goal.aiSuggestionReason,
      'recommended_weekly_saving': goal.recommendedWeeklySaving != null 
          ? (goal.recommendedWeeklySaving! * 100).toInt() 
          : null,
      'is_automatic_saving': goal.isAutomaticSaving ?? false,
      'forecasted_completion': goal.forecastedCompletion?.toInt(),
      'image_url': goal.imageUrl,
    };
  }

  // Convert Appwrite data to SavingsGoal
  SavingsGoal _convertAppwriteToSavingsGoal(Map<String, dynamic> data, String docId) {
    try {
      return SavingsGoal(
        id: docId,
        title: data['title'] ?? '',
        description: data['description'],
        targetAmount: (data['target_amount'] ?? 0) / 100.0, // Convert from cents
        currentAmount: (data['current_amount'] ?? 0) / 100.0, // Convert from cents
        dailyTarget: data['daily_target'] != null ? data['daily_target'] / 100.0 : null,
        weeklyTarget: data['weekly_target'] != null ? data['weekly_target'] / 100.0 : null,
        priority: data['priority'] ?? 'medium',
        category: _stringToSavingsGoalCategory(data['category'] ?? 'other'), // Convert string to enum
        targetDate: data['deadline'] != null ? DateTime.parse(data['deadline']) : DateTime.now().add(const Duration(days: 30)),
        status: _stringToSavingsGoalStatus(data['status'] ?? 'active'), // Convert string to enum
        createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now(),
        updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now(),
        startDate: data['start_date'] != null ? DateTime.parse(data['start_date']) : null,
        iconAsset: data['icon_asset'] ?? 'savings',
        color: data['color'] != null ? Color(data['color']) : Colors.blue,
        isRecurring: data['is_recurring'] ?? false,
        reminderFrequency: data['reminder_frequency'] ?? 'weekly',
        isAiSuggested: data['is_ai_suggested'] ?? false,
        aiSuggestionReason: data['ai_suggestion_reason'],
        recommendedWeeklySaving: data['recommended_weekly_saving'] != null 
            ? data['recommended_weekly_saving'] / 100.0 
            : null,
        isAutomaticSaving: data['is_automatic_saving'] ?? false,
        forecastedCompletion: data['forecasted_completion']?.toDouble(),
        imageUrl: data['image_url'], 
        icon: null,
      );
    } catch (e) {
      debugPrint('Error converting Appwrite data to SavingsGoal: $e');
      debugPrint('Data: $data');
      rethrow;
    }
  }

  // Add getSavingsGoals method (alias for fetchSavingsGoals for backward compatibility)
  Future<List<SavingsGoal>> getSavingsGoals() async {
    return await fetchSavingsGoals();
  }

  // Create a new savings goal from map data (for debugging purposes)
  Future<SavingsGoal> addSavingsGoalFromMap(Map<String, dynamic> goalData) async {
    try {
      debugPrint('Creating goal from map data: $goalData');
      
      // Create SavingsGoal object from map
      final goal = SavingsGoal(
        id: ID.unique(),
        title: goalData['title'] ?? '',
        description: goalData['description'],
        targetAmount: (goalData['targetAmount'] ?? 0.0).toDouble(),
        currentAmount: (goalData['currentAmount'] ?? 0.0).toDouble(),
        targetDate: goalData['targetDate'] is String 
            ? DateTime.parse(goalData['targetDate'])
            : (goalData['targetDate'] ?? DateTime.now().add(const Duration(days: 30))),
        category: _stringToSavingsGoalCategory(goalData['category'] ?? 'other'),
        iconAsset: goalData['iconAsset'] ?? 'savings',
        color: goalData['color'] is String 
            ? Color(int.parse(goalData['color'].replaceAll('#', ''), radix: 16))
            : (goalData['color'] ?? Colors.blue),
        status: SavingsGoalStatus.active,
        createdAt: goalData['createdAt'] is String 
            ? DateTime.parse(goalData['createdAt'])
            : (goalData['createdAt'] ?? DateTime.now()),
        updatedAt: goalData['updatedAt'] is String 
            ? DateTime.parse(goalData['updatedAt'])
            : (goalData['updatedAt'] ?? DateTime.now()),
        isRecurring: goalData['isRecurring'] ?? false,
        reminderFrequency: goalData['reminderFrequency'] ?? 'weekly', 
        icon: null,
      );
      
      debugPrint('Created SavingsGoal object: ${goal.title}');
      
      // Create the goal in Appwrite
      return await createSavingsGoal(goal);
    } catch (e) {
      debugPrint('Error in addSavingsGoalFromMap: $e');
      rethrow;
    }
  }

  // Fetch all savings goals
  Future<List<SavingsGoal>> fetchSavingsGoals() async {
    try {
      await _checkUserSession();
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        queries: [
          Query.equal('user_id', currentUserId!),
          Query.orderDesc('\$createdAt'),
        ],
      );
      
      return response.documents.map((doc) {
        final data = doc.data;
        return _convertAppwriteToSavingsGoal(data, doc.$id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching savings goals: $e');
      rethrow;
    }
  }

  // Create a new savings goal
  Future<SavingsGoal> createSavingsGoal(SavingsGoal goal) async {
    try {
      await _checkUserSession();
      
      final goalData = _convertSavingsGoalToAppwrite(goal);
      
      final response = await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        documentId: goal.id.isNotEmpty ? goal.id : ID.unique(),
        data: goalData,
      );
      
      return _convertAppwriteToSavingsGoal(response.data, response.$id);
    } catch (e) {
      debugPrint('Error creating savings goal: $e');
      rethrow;
    }
  }

  // Update an existing savings goal
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    try {
      await _checkUserSession();
      
      final goalData = _convertSavingsGoalToAppwrite(goal);
      
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        documentId: goal.id,
        data: goalData,
      );
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
      rethrow;
    }
  }

  // Delete a savings goal
  Future<void> deleteSavingsGoal(String goalId) async {
    try {
      await _checkUserSession();
      
      await databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        documentId: goalId,
      );
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
      rethrow;
    }
  }

  // Update savings goal progress
  Future<void> updateSavingsGoalProgress(String goalId, double newAmount) async {
    try {
      await _checkUserSession();
      
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        documentId: goalId,
        data: {
          'current_amount': (newAmount * 100).toInt(), // Store as cents
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error updating savings goal progress: $e');
      rethrow;
    }
  }

  // SAVINGS CHALLENGE METHODS

  // Create a new savings challenge
  Future<void> createSavingsChallenge(Map<String, dynamic> challenge) async {
    try {
      await _checkUserSession();
      
      // Ensure proper data structure
      final challengeData = Map<String, dynamic>.from(challenge);
      challengeData['createdBy'] = currentUserId;
      challengeData['created_at'] = DateTime.now().toIso8601String();
      challengeData['updated_at'] = DateTime.now().toIso8601String();
      
      // Initialize participants list with creator
      if (!challengeData.containsKey('participants')) {
        challengeData['participants'] = [currentUserId];
      } else if (!(challengeData['participants'] as List).contains(currentUserId)) {
        (challengeData['participants'] as List).add(currentUserId);
      }
      
      // Set default status if not provided
      if (!challengeData.containsKey('status')) {
        challengeData['status'] = 'active';
      }
      
      // Initialize progress tracking
      if (!challengeData.containsKey('progress')) {
        challengeData['progress'] = <String, dynamic>{};
      }
      
      await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: ID.unique(),
        data: challengeData,
      );
    } catch (e) {
      debugPrint('Error creating savings challenge: $e');
      throw Exception('Failed to create savings challenge: $e');
    }
  }

  // Join an existing savings challenge
  Future<void> joinSavingsChallenge(String challengeId) async {
    try {
      await _checkUserSession();
      
      // First, get the current challenge data
      final challengeDoc = await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
      );
      
      final challengeData = Map<String, dynamic>.from(challengeDoc.data);
      
      // Get current participants list
      List<dynamic> participants = challengeData['participants'] ?? [];
      
      // Add current user if not already a participant
      if (!participants.contains(currentUserId)) {
        participants.add(currentUserId);
        
        // Initialize user progress
        Map<String, dynamic> progress = Map<String, dynamic>.from(challengeData['progress'] ?? {});
        progress[currentUserId!] = {
          'currentAmount': 0.0,
          'joinedAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
        };
        
        // Update the challenge document
        await databases.updateDocument(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.savingsChallengesCollection,
          documentId: challengeId,
          data: {
            'participants': participants,
            'progress': progress,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      debugPrint('Error joining savings challenge: $e');
      throw Exception('Failed to join savings challenge: $e');
    }
  }

  // Leave a savings challenge
  Future<void> leaveSavingsChallenge(String challengeId) async {
    try {
      await _checkUserSession();
      
      // Get the current challenge data
      final challengeDoc = await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
      );
      
      final challengeData = Map<String, dynamic>.from(challengeDoc.data);
      
      // Get current participants list
      List<dynamic> participants = challengeData['participants'] ?? [];
      
      // Remove current user from participants
      participants.remove(currentUserId);
      
      // Remove user from progress tracking
      Map<String, dynamic> progress = Map<String, dynamic>.from(challengeData['progress'] ?? {});
      progress.remove(currentUserId);
      
      // Update the challenge document
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
        data: {
          'participants': participants,
          'progress': progress,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error leaving savings challenge: $e');
      throw Exception('Failed to leave savings challenge: $e');
    }
  }

  // Update challenge progress for current user
  Future<void> updateChallengeProgress(String challengeId, double amount, double newProgress) async {
    try {
      await _checkUserSession();
      
      // Get the current challenge data
      final challengeDoc = await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
      );
      
      final challengeData = Map<String, dynamic>.from(challengeDoc.data);
      
      // Get current progress
      Map<String, dynamic> progress = Map<String, dynamic>.from(challengeData['progress'] ?? {});
      
      // Update user's progress
      if (!progress.containsKey(currentUserId)) {
        progress[currentUserId!] = {
          'currentAmount': amount,
          'joinedAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      } else {
        final userProgress = Map<String, dynamic>.from(progress[currentUserId!]);
        userProgress['currentAmount'] = amount;
        userProgress['lastUpdated'] = DateTime.now().toIso8601String();
        progress[currentUserId!] = userProgress;
      }
      
      // Check if challenge is completed
      final targetAmount = challengeData['targetAmount'] ?? 0.0;
      final challengeType = challengeData['type'] ?? 'individual';
      bool isCompleted = false;
      
      if (challengeType == 'individual') {
        // Individual challenge - check if user reached target
        final userProgress = progress[currentUserId!];
        isCompleted = (userProgress['currentAmount'] ?? 0.0) >= targetAmount;
      } else if (challengeType == 'group') {
        // Group challenge - check if total amount reached
        double totalAmount = 0.0;
        progress.values.forEach((userProgress) {
          totalAmount += (userProgress['currentAmount'] ?? 0.0);
        });
        isCompleted = totalAmount >= targetAmount;
      }
      
      // Update challenge data
      final updateData = {
        'progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (isCompleted && challengeData['status'] != 'completed') {
        updateData['status'] = 'completed';
        updateData['completedAt'] = DateTime.now().toIso8601String();
      }
      
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
        data: updateData,
      );
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
      throw Exception('Failed to update challenge progress: $e');
    }
  }

  // Fetch challenges where the current user is a participant
  Future<List<Map<String, dynamic>>> fetchUserChallenges() async {
    try {
      await _checkUserSession();
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        queries: [
          Query.contains('participants', [currentUserId!]),
          Query.orderDesc('\$createdAt'),
        ],
      );
      
      return response.documents.map((doc) {
        final data = Map<String, dynamic>.from(doc.data);
        data['id'] = doc.$id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user challenges: $e');
      return [];
    }
  }

  // Fetch all available challenges (for discovery)
  Future<List<Map<String, dynamic>>> fetchAvailableChallenges({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queries = [
        Query.equal('status', 'active'),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];
      
      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        queries: queries,
      );
      
      return response.documents.map((doc) {
        final data = Map<String, dynamic>.from(doc.data);
        data['id'] = doc.$id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching available challenges: $e');
      return [];
    }
  }

  // Get a specific challenge by ID
  Future<Map<String, dynamic>?> getChallengeById(String challengeId) async {
    try {
      final response = await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
      );
      
      final data = Map<String, dynamic>.from(response.data);
      data['id'] = response.$id;
      return data;
    } catch (e) {
      debugPrint('Error fetching challenge: $e');
      return null;
    }
  }

  // Delete a savings challenge (only for creator)
  Future<void> deleteSavingsChallenge(String challengeId) async {
    try {
      await _checkUserSession();
      
      // Verify that the current user is the creator
      final challengeDoc = await databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
      );
      
      if (challengeDoc.data['createdBy'] != currentUserId) {
        throw Exception('Only the challenge creator can delete this challenge');
      }
      
      await databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsChallengesCollection,
        documentId: challengeId,
      );
    } catch (e) {
      debugPrint('Error deleting savings challenge: $e');
      throw Exception('Failed to delete savings challenge: $e');
    }
  }
  Future<void> createOrUpdateBudget(Map<String, dynamic> budgetData) async {
  try {
    await _checkUserSession();
    
    final data = {
      'user_id': currentUserId!,
      'name': budgetData['name'] ?? 'Monthly Budget',
      'total_amount': (budgetData['total_amount'] * 100).toInt(), // Store as cents
      'spent': (budgetData['spent'] * 100).toInt(), // Store as cents
      'start_date': budgetData['start_date'] ?? DateTime.now().toIso8601String(),
      'end_date': budgetData['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'categories': budgetData['categories'] ?? {},
      'daily_limit': budgetData['daily_limit'] != null 
          ? (budgetData['daily_limit'] * 100).toInt() 
          : null,
      'weekly_limit': budgetData['weekly_limit'] != null 
          ? (budgetData['weekly_limit'] * 100).toInt() 
          : null,
      'notes': budgetData['notes'] ?? '',
      'recommendations': budgetData['recommendations'] ?? [],
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Check if budget already exists for this period
    final existingBudgets = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.budgetsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.equal('name', data['name']),
        Query.equal('start_date', data['start_date']),
      ],
    );
    
    if (existingBudgets.documents.isNotEmpty) {
      // Update existing budget
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
        documentId: existingBudgets.documents.first.$id,
        data: data,
      );
    } else {
      // Create new budget
      await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
        documentId: ID.unique(),
        data: data,
      );
    }
  } catch (e) {
    debugPrint('Error creating/updating budget: $e');
    throw Exception('Failed to save budget: $e');
  }
}

// Get current active budget
Future<Map<String, dynamic>?> getCurrentBudget() async {
  try {
    await _checkUserSession();
    
    final now = DateTime.now();
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.budgetsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.equal('status', 'active'),
        Query.lessThanEqual('start_date', now.toIso8601String()),
        Query.greaterThanEqual('end_date', now.toIso8601String()),
        Query.orderDesc('\$createdAt'),
        Query.limit(1),
      ],
    );
    
    if (response.documents.isNotEmpty) {
      final doc = response.documents.first;
      final data = Map<String, dynamic>.from(doc.data);
      data['id'] = doc.$id;
      
      // Convert cents back to dollars
      data['total_amount'] = (data['total_amount'] ?? 0) / 100.0;
      data['spent'] = (data['spent'] ?? 0) / 100.0;
      data['daily_limit'] = data['daily_limit'] != null ? data['daily_limit'] / 100.0 : null;
      data['weekly_limit'] = data['weekly_limit'] != null ? data['weekly_limit'] / 100.0 : null;
      
      return data;
    }
    
    return null;
  } catch (e) {
    debugPrint('Error getting current budget: $e');
    return null;
  }
}

// Update budget spent amount
Future<void> updateBudgetSpent(String budgetId, double spentAmount) async {
  try {
    await databases.updateDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.budgetsCollection,
      documentId: budgetId,
      data: {
        'spent': (spentAmount * 100).toInt(), // Store as cents
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  } catch (e) {
    debugPrint('Error updating budget spent: $e');
    throw Exception('Failed to update budget: $e');
  }
}
Future<List<models.Document>> getRecurringBills() async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.recurringBillsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.orderAsc('name'),
      ],
    );
    
    return response.documents;
  } catch (e) {
    debugPrint('Error getting recurring bills: $e');
    return [];
  }
}

// Create a new recurring bill
Future<void> createRecurringBill(Map<String, dynamic> billData) async {
  try {
    await _checkUserSession();
    
    final data = Map<String, dynamic>.from(billData);
    data['user_id'] = currentUserId!;
    data['amount'] = (data['amount'] * 100).toInt(); // Store as cents
    
    await databases.createDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.recurringBillsCollection,
      documentId: data['id'] ?? ID.unique(),
      data: data,
    );
  } catch (e) {
    debugPrint('Error creating recurring bill: $e');
    throw Exception('Failed to create recurring bill: $e');
  }
}

// Update an existing recurring bill
Future<void> updateRecurringBill(String billId, Map<String, dynamic> billData) async {
  try {
    await _checkUserSession();
    
    final data = Map<String, dynamic>.from(billData);
    if (data.containsKey('amount')) {
      data['amount'] = (data['amount'] * 100).toInt(); // Store as cents
    }
    
    await databases.updateDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.recurringBillsCollection,
      documentId: billId,
      data: data,
    );
  } catch (e) {
    debugPrint('Error updating recurring bill: $e');
    throw Exception('Failed to update recurring bill: $e');
  }
}

// Delete a recurring bill
Future<void> deleteRecurringBill(String billId) async {
  try {
    await _checkUserSession();
    
    await databases.deleteDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.recurringBillsCollection,
      documentId: billId,
    );
  } catch (e) {
    debugPrint('Error deleting recurring bill: $e');
    throw Exception('Failed to delete recurring bill: $e');
  }
}

// Create a bill payment record
Future<void> createBillPayment(Map<String, dynamic> paymentData) async {
  try {
    await _checkUserSession();
    
    final data = Map<String, dynamic>.from(paymentData);
    data['user_id'] = currentUserId!;
    
    await databases.createDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.billPaymentsCollection,
      documentId: ID.unique(),
      data: data,
    );
  } catch (e) {
    debugPrint('Error creating bill payment: $e');
    throw Exception('Failed to record bill payment: $e');
  }
}

// Get payment history for a specific bill
Future<List<models.Document>> getBillPayments(String billId) async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.billPaymentsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.equal('billId', billId),
        Query.orderDesc('paidDate'),
      ],
    );
    
    return response.documents;
  } catch (e) {
    debugPrint('Error getting bill payments: $e');
    return [];
  }
}

// Get all bill payments for current user
Future<List<models.Document>> getAllBillPayments() async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.billPaymentsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.orderDesc('paidDate'),
      ],
    );
    
    return response.documents;
  } catch (e) {
    debugPrint('Error getting all bill payments: $e');
    return [];
  }
}

// Get upcoming bills (bills due within specified days)
Future<List<Map<String, dynamic>>> getUpcomingBills({int daysAhead = 30}) async {
  try {
    final bills = await getRecurringBills();
    final upcomingBills = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (final billDoc in bills) {
      final bill = billDoc.data;
      final frequency = bill['frequency'] as String;
      final dueDay = bill['dueDay'] as int;
      
      // Calculate next due date based on frequency
      DateTime nextDueDate;
      
      switch (frequency.toLowerCase()) {
        case 'daily':
          nextDueDate = now.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDueDate = now.add(const Duration(days: 7));
          break;
        case 'biweekly':
          nextDueDate = now.add(const Duration(days: 14));
          break;
        case 'monthly':
          nextDueDate = DateTime(now.year, now.month, dueDay);
          if (nextDueDate.isBefore(now)) {
            nextDueDate = DateTime(now.year, now.month + 1, dueDay);
          }
          break;
        case 'quarterly':
          nextDueDate = DateTime(now.year, now.month + 3, dueDay);
          break;
        case 'yearly':
          nextDueDate = DateTime(now.year + 1, now.month, dueDay);
          break;
        default:
          nextDueDate = DateTime(now.year, now.month, dueDay);
          if (nextDueDate.isBefore(now)) {
            nextDueDate = DateTime(now.year, now.month + 1, dueDay);
          }
      }
      
      // Only include bills due within the specified days
      final daysDifference = nextDueDate.difference(now).inDays;
      if (daysDifference <= daysAhead && daysDifference >= 0) {
        final billData = Map<String, dynamic>.from(bill);
        billData['id'] = billDoc.$id;
        billData['amount'] = (billData['amount'] ?? 0) / 100.0; // Convert from cents
        billData['dueDate'] = nextDueDate;
        billData['daysUntilDue'] = daysDifference;
        upcomingBills.add(billData);
      }
    }
    
    // Sort by due date
    upcomingBills.sort((a, b) {
      final dateA = a['dueDate'] as DateTime;
      final dateB = b['dueDate'] as DateTime;
      return dateA.compareTo(dateB);
    });
    
    return upcomingBills;
  } catch (e) {
    debugPrint('Error getting upcoming bills: $e');
    return [];
  }
}
Future<Map<String, dynamic>> getSpendingAnalytics({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.transactionsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.greaterThanEqual('date', startDate.toIso8601String()),
        Query.lessThanEqual('date', endDate.toIso8601String()),
        Query.orderDesc('date'),
      ],
    );
    
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    Map<String, double> categorySpending = {};
    Map<String, int> categoryCount = {};
    List<double> dailyExpenses = [];
    
    // Initialize daily expenses array
    int daysDifference = endDate.difference(startDate).inDays + 1;
    dailyExpenses = List.filled(daysDifference, 0.0);
    
    for (final doc in response.documents) {
      final data = doc.data;
      final amount = (data['amount'] ?? 0.0).toDouble();
      final category = data['category'] ?? 'Other';
      final isExpense = data['isExpense'] ?? false;
      
      if (isExpense) {
        totalExpenses += amount.abs();
        categorySpending[category] = (categorySpending[category] ?? 0.0) + amount.abs();
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        
        // Add to daily expenses
        final transactionDate = DateTime.parse(data['date']);
        final dayIndex = transactionDate.difference(startDate).inDays;
        if (dayIndex >= 0 && dayIndex < daysDifference) {
          dailyExpenses[dayIndex] += amount.abs();
        }
      } else {
        totalIncome += amount.abs();
      }
    }
    
    // Calculate averages
    final dailyAverage = totalExpenses / daysDifference;
    final weeklyAverage = totalExpenses / (daysDifference / 7);
    final monthlyAverage = totalExpenses / (daysDifference / 30);
    
    // Find top spending categories
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netSavings': totalIncome - totalExpenses,
      'categorySpending': categorySpending,
      'categoryCount': categoryCount,
      'dailyExpenses': dailyExpenses,
      'averages': {
        'daily': dailyAverage,
        'weekly': weeklyAverage,
        'monthly': monthlyAverage,
      },
      'topCategories': sortedCategories.take(5).map((e) => {
        'category': e.key,
        'amount': e.value,
        'count': categoryCount[e.key] ?? 0,
      }).toList(),
      'period': {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'days': daysDifference,
      },
    };
  } catch (e) {
    debugPrint('Error getting spending analytics: $e');
    return {
      'totalIncome': 0.0,
      'totalExpenses': 0.0,
      'netSavings': 0.0,
      'categorySpending': <String, double>{},
      'categoryCount': <String, int>{},
      'dailyExpenses': <double>[],
      'averages': {'daily': 0.0, 'weekly': 0.0, 'monthly': 0.0},
      'topCategories': [],
      'period': {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'days': 0,
      },
    };
  }
}

// Get monthly spending comparison
Future<Map<String, dynamic>> getMonthlySpendingComparison() async {
  try {
    await _checkUserSession();
    
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthEnd = DateTime(now.year, now.month, 0);
    
    // Get current month data
    final currentMonthData = await getSpendingAnalytics(
      startDate: currentMonthStart,
      endDate: currentMonthEnd,
    );
    
    // Get previous month data
    final previousMonthData = await getSpendingAnalytics(
      startDate: previousMonthStart,
      endDate: previousMonthEnd,
    );
    
    // Calculate changes
    final expenseChange = currentMonthData['totalExpenses'] - previousMonthData['totalExpenses'];
    final expenseChangePercent = previousMonthData['totalExpenses'] > 0 
        ? (expenseChange / previousMonthData['totalExpenses']) * 100 
        : 0.0;
    
    final incomeChange = currentMonthData['totalIncome'] - previousMonthData['totalIncome'];
    final incomeChangePercent = previousMonthData['totalIncome'] > 0 
        ? (incomeChange / previousMonthData['totalIncome']) * 100 
        : 0.0;
    
    return {
      'currentMonth': currentMonthData,
      'previousMonth': previousMonthData,
      'changes': {
        'expenses': {
          'amount': expenseChange,
          'percent': expenseChangePercent,
        },
        'income': {
          'amount': incomeChange,
          'percent': incomeChangePercent,
        },
      },
    };
  } catch (e) {
    debugPrint('Error getting monthly spending comparison: $e');
    return {};
  }
}

// Get budget performance analytics
Future<Map<String, dynamic>> getBudgetPerformance() async {
  try {
    final currentBudget = await getCurrentBudget();
    if (currentBudget == null) {
      return {
        'hasBudget': false,
        'message': 'No active budget found',
      };
    }
    
    final startDate = DateTime.parse(currentBudget['start_date']);
    final endDate = DateTime.parse(currentBudget['end_date']);
    final now = DateTime.now();
    
    // Calculate progress
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays.clamp(0, totalDays);
    final remainingDays = totalDays - elapsedDays;
    final progressPercent = totalDays > 0 ? (elapsedDays / totalDays) * 100 : 0.0;
    
    // Get spending data for budget period
    final spendingData = await getSpendingAnalytics(
      startDate: startDate,
      endDate: now.isBefore(endDate) ? now : endDate,
    );
    
    final totalBudget = currentBudget['total_amount'] ?? 0.0;
    final totalSpent = spendingData['totalExpenses'] ?? 0.0;
    final remaining = totalBudget - totalSpent;
    final spentPercent = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;
    
    // Calculate projected spending
    final dailySpendingRate = elapsedDays > 0 ? totalSpent / elapsedDays : 0.0;
    final projectedTotalSpending = dailySpendingRate * totalDays;
    
    // Determine status
    String status = 'on_track';
    if (spentPercent > 100) {
      status = 'over_budget';
    } else if (spentPercent > progressPercent + 10) {
      status = 'overspending';
    } else if (spentPercent < progressPercent - 10) {
      status = 'underspending';
    }
    
    return {
      'hasBudget': true,
      'budget': currentBudget,
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'remaining': remaining,
      'spentPercent': spentPercent,
      'progressPercent': progressPercent,
      'elapsedDays': elapsedDays,
      'remainingDays': remainingDays,
      'totalDays': totalDays,
      'dailySpendingRate': dailySpendingRate,
      'projectedTotalSpending': projectedTotalSpending,
      'status': status,
      'categoryBreakdown': spendingData['categorySpending'],
      'dailyExpenses': spendingData['dailyExpenses'],
    };
  } catch (e) {
    debugPrint('Error getting budget performance: $e');
    return {
      'hasBudget': false,
      'error': e.toString(),
    };
  }
}

// Get financial health score
Future<Map<String, dynamic>> getFinancialHealthScore() async {
  try {
    await _checkUserSession();
    
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    
    // Get 3-month analytics
    final analyticsData = await getSpendingAnalytics(
      startDate: threeMonthsAgo,
      endDate: now,
    );
    
    final totalIncome = analyticsData['totalIncome'] ?? 0.0;
    final totalExpenses = analyticsData['totalExpenses'] ?? 0.0;
    final netSavings = totalIncome - totalExpenses;
    
    // Calculate metrics
    double savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;
    double expenseRatio = totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 100.0;
    
    // Get budget adherence
    final budgetPerformance = await getBudgetPerformance();
    double budgetScore = 100.0;
    if (budgetPerformance['hasBudget'] == true) {
      final spentPercent = budgetPerformance['spentPercent'] ?? 0.0;
      if (spentPercent <= 80) {
        budgetScore = 100.0;
      } else if (spentPercent <= 100) {
        budgetScore = 80.0;
      } else if (spentPercent <= 120) {
        budgetScore = 60.0;
      } else {
        budgetScore = 40.0;
      }
    }
    
    // Calculate category diversity (spending across different categories)
    final categorySpending = analyticsData['categorySpending'] as Map<String, double>;
    double diversityScore = categorySpending.length.toDouble() * 10.0;
    diversityScore = diversityScore.clamp(0.0, 100.0);
    
    // Calculate overall health score
    double overallScore = (savingsRate.clamp(0.0, 30.0) / 30.0 * 30) + // 30% weight for savings
                         (budgetScore * 0.25) + // 25% weight for budget adherence
                         (diversityScore * 0.15) + // 15% weight for spending diversity
                         ((100 - expenseRatio.clamp(0.0, 100.0)) * 0.30); // 30% weight for expense control
    
    // Determine health level
    String healthLevel;
    String healthDescription;
    if (overallScore >= 80) {
      healthLevel = 'excellent';
      healthDescription = 'Your financial health is excellent! Keep up the great work.';
    } else if (overallScore >= 60) {
      healthLevel = 'good';
      healthDescription = 'Your financial health is good. There are some areas for improvement.';
    } else if (overallScore >= 40) {
      healthLevel = 'fair';
      healthDescription = 'Your financial health is fair. Consider reviewing your spending habits.';
    } else {
      healthLevel = 'poor';
      healthDescription = 'Your financial health needs attention. Consider creating a budget and reducing expenses.';
    }
    
    return {
      'overallScore': overallScore.round(),
      'healthLevel': healthLevel,
      'healthDescription': healthDescription,
      'metrics': {
        'savingsRate': savingsRate.round(),
        'expenseRatio': expenseRatio.round(),
        'budgetScore': budgetScore.round(),
        'diversityScore': diversityScore.round(),
      },
      'recommendations': _getHealthRecommendations(overallScore, savingsRate, expenseRatio, budgetScore),
      'period': {
        'startDate': threeMonthsAgo.toIso8601String(),
        'endDate': now.toIso8601String(),
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netSavings': netSavings,
      },
    };
  } catch (e) {
    debugPrint('Error calculating financial health score: $e');
    return {
      'overallScore': 0,
      'healthLevel': 'unknown',
      'healthDescription': 'Unable to calculate financial health score.',
      'error': e.toString(),
    };
  }
}

// Helper method to get health recommendations
List<String> _getHealthRecommendations(double overallScore, double savingsRate, double expenseRatio, double budgetScore) {
  List<String> recommendations = [];
  
  if (savingsRate < 10) {
    recommendations.add('Try to save at least 10% of your income each month.');
  }
  
  if (expenseRatio > 90) {
    recommendations.add('Your expenses are very high. Look for areas to cut back.');
  }
  
  if (budgetScore < 70) {
    recommendations.add('Improve your budget adherence by tracking expenses daily.');
  }
  
  if (overallScore < 60) {
    recommendations.add('Consider using the 50/30/20 rule: 50% needs, 30% wants, 20% savings.');
    recommendations.add('Set up automatic transfers to your savings account.');
  }
  
  if (recommendations.isEmpty) {
    recommendations.add('Keep maintaining your excellent financial habits!');
    recommendations.add('Consider increasing your savings rate or investing for the future.');
  }
  
  return recommendations;
}
Future<void> saveNotificationPreferences(Map<String, dynamic> preferences) async {
  try {
    await _checkUserSession();
    
    final data = {
      'user_id': currentUserId!,
      'push_notifications': preferences['push_notifications'] ?? true,
      'email_notifications': preferences['email_notifications'] ?? false,
      'sms_notifications': preferences['sms_notifications'] ?? false,
      'budget_alerts': preferences['budget_alerts'] ?? true,
      'bill_reminders': preferences['bill_reminders'] ?? true,
      'savings_goal_updates': preferences['savings_goal_updates'] ?? true,
      'weekly_reports': preferences['weekly_reports'] ?? false,
      'monthly_reports': preferences['monthly_reports'] ?? true,
      'expense_threshold': preferences['expense_threshold'] ?? 100.0,
      'daily_limit_alerts': preferences['daily_limit_alerts'] ?? true,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Check if preferences already exist
    final existing = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationPreferencesCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
      ],
    );
    
    if (existing.documents.isNotEmpty) {
      // Update existing preferences
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.notificationPreferencesCollection,
        documentId: existing.documents.first.$id,
        data: data,
      );
    } else {
      // Create new preferences
      data['created_at'] = DateTime.now().toIso8601String();
      await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.notificationPreferencesCollection,
        documentId: ID.unique(),
        data: data,
      );
    }
  } catch (e) {
    debugPrint('Error saving notification preferences: $e');
    throw Exception('Failed to save notification preferences: $e');
  }
}

// Get user notification preferences
Future<Map<String, dynamic>?> getNotificationPreferences() async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationPreferencesCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
      ],
    );
    
    if (response.documents.isNotEmpty) {
      final data = Map<String, dynamic>.from(response.documents.first.data);
      data['id'] = response.documents.first.$id;
      return data;
    }
    
    // Return default preferences if none exist
    return {
      'push_notifications': true,
      'email_notifications': false,
      'sms_notifications': false,
      'budget_alerts': true,
      'bill_reminders': true,
      'savings_goal_updates': true,
      'weekly_reports': false,
      'monthly_reports': true,
      'expense_threshold': 100.0,
      'daily_limit_alerts': true,
    };
  } catch (e) {
    debugPrint('Error getting notification preferences: $e');
    return null;
  }
}

// Create a notification
Future<void> createNotification(Map<String, dynamic> notificationData) async {
  try {
    await _checkUserSession();
    
    final data = {
      'user_id': currentUserId!,
      'title': notificationData['title'] ?? '',
      'message': notificationData['message'] ?? '',
      'type': notificationData['type'] ?? 'info', // info, warning, success, error
      'category': notificationData['category'] ?? 'general', // budget, bill, savings, transaction
      'is_read': false,
      'priority': notificationData['priority'] ?? 'normal', // low, normal, high
      'action_type': notificationData['action_type'], // Optional: what action this notification relates to
      'action_data': notificationData['action_data'], // Optional: data for the action
      'expires_at': notificationData['expires_at'], // Optional: when notification expires
      'created_at': DateTime.now().toIso8601String(),
    };
    
    await databases.createDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationsCollection,
      documentId: ID.unique(),
      data: data,
    );
  } catch (e) {
    debugPrint('Error creating notification: $e');
    throw Exception('Failed to create notification: $e');
  }
}

// Get user notifications
Future<List<Map<String, dynamic>>> getNotifications({
  bool unreadOnly = false,
  int limit = 50,
  String? cursor,
}) async {
  try {
    await _checkUserSession();
    
    final queries = [
      Query.equal('user_id', currentUserId!),
      Query.orderDesc('\$createdAt'),
      Query.limit(limit),
    ];
    
    if (unreadOnly) {
      queries.add(Query.equal('is_read', false));
    }
    
    if (cursor != null) {
      queries.add(Query.cursorAfter(cursor));
    }
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationsCollection,
      queries: queries,
    );
    
    return response.documents.map((doc) {
      final data = Map<String, dynamic>.from(doc.data);
      data['id'] = doc.$id;
      return data;
    }).toList();
  } catch (e) {
    debugPrint('Error getting notifications: $e');
    return [];
  }
}

// Mark notification as read
Future<void> markNotificationAsRead(String notificationId) async {
  try {
    await databases.updateDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationsCollection,
      documentId: notificationId,
      data: {
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      },
    );
  } catch (e) {
    debugPrint('Error marking notification as read: $e');
    throw Exception('Failed to mark notification as read: $e');
  }
}

// Mark all notifications as read
Future<void> markAllNotificationsAsRead() async {
  try {
    await _checkUserSession();
    
    final unreadNotifications = await getNotifications(unreadOnly: true);
    
    for (final notification in unreadNotifications) {
      await markNotificationAsRead(notification['id']);
    }
  } catch (e) {
    debugPrint('Error marking all notifications as read: $e');
    throw Exception('Failed to mark all notifications as read: $e');
  }
}

// Delete notification
Future<void> deleteNotification(String notificationId) async {
  try {
    await databases.deleteDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationsCollection,
      documentId: notificationId,
    );
  } catch (e) {
    debugPrint('Error deleting notification: $e');
    throw Exception('Failed to delete notification: $e');
  }
}

// Get unread notification count
Future<int> getUnreadNotificationCount() async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.equal('is_read', false),
      ],
    );
    
    return response.total;
  } catch (e) {
    debugPrint('Error getting unread notification count: $e');
    return 0;
  }
}

// Clean up expired notifications
Future<void> cleanupExpiredNotifications() async {
  try {
    await _checkUserSession();
    
    final now = DateTime.now().toIso8601String();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.lessThan('expires_at', now),
      ],
    );
    
    for (final doc in response.documents) {
      await deleteNotification(doc.$id);
    }
  } catch (e) {
    debugPrint('Error cleaning up expired notifications: $e');
  }
}

// BACKUP AND EXPORT METHODS

// Export user data
Future<Map<String, dynamic>> exportUserData() async {
  try {
    await _checkUserSession();
    
    // Get user profile
    final profile = await getCurrentUserProfile();
    
    // Get transactions
    final transactions = await getTransactions();
    
    // Get budgets
    final budgets = await getBudgets();
    
    // Get savings goals
    final savingsGoals = await fetchSavingsGoals();
    
    // Get recurring bills
    final recurringBills = await getRecurringBills();
    
    // Get notification preferences
    final notificationPrefs = await getNotificationPreferences();
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'userId': currentUserId,
      'profile': profile?.data ?? {},
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'budgets': budgets.map((b) => {
        'id': b.id,
        'title': b.title,
        'category': b.category,
        'amount': b.amount,
        'spent': b.spent,
        'period': b.period.toString(),
        'startDate': b.startDate.toIso8601String(),
        'endDate': b.endDate.toIso8601String(),
        'isActive': b.isActive,
      }).toList(),
      'savingsGoals': savingsGoals.map((g) => {
        'id': g.id,
        'title': g.title,
        'description': g.description,
        'targetAmount': g.targetAmount,
        'currentAmount': g.currentAmount,
        'targetDate': g.targetDate.toIso8601String(),
        'category': g.category.toString(),
        'status': g.status.toString(),
      }).toList(),
      'recurringBills': recurringBills.map((b) => b.data).toList(),
      'notificationPreferences': notificationPrefs ?? {},
    };
  } catch (e) {
    debugPrint('Error exporting user data: $e');
    throw Exception('Failed to export user data: $e');
  }
}

// Create data backup
Future<String> createDataBackup() async {
  try {
    await _checkUserSession();
    
    final userData = await exportUserData();
    
    // Create backup document
    final backupData = {
      'user_id': currentUserId!,
      'backup_data': userData,
      'backup_type': 'full',
      'created_at': DateTime.now().toIso8601String(),
      'size_bytes': userData.toString().length,
    };
    
    final response = await databases.createDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.backupsCollection,
      documentId: ID.unique(),
      data: backupData,
    );
    
    return response.$id;
  } catch (e) {
    debugPrint('Error creating data backup: $e');
    throw Exception('Failed to create backup: $e');
  }
}

// Get user backups
Future<List<Map<String, dynamic>>> getUserBackups() async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.backupsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.orderDesc('\$createdAt'),
      ],
    );
    
    return response.documents.map((doc) {
      final data = Map<String, dynamic>.from(doc.data);
      data['id'] = doc.$id;
      // Don't include the full backup data in the list
      data.remove('backup_data');
      return data;
    }).toList();
  } catch (e) {
    debugPrint('Error getting user backups: $e');
    return [];
  }
}

// Restore from backup
Future<void> restoreFromBackup(String backupId) async {
  try {
    await _checkUserSession();
    
    final backupDoc = await databases.getDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.backupsCollection,
      documentId: backupId,
    );
    
    final backupData = backupDoc.data['backup_data'] as Map<String, dynamic>;
    
    // Note: This is a simplified restore - in production you'd want more sophisticated restoration logic
    // that handles conflicts, allows selective restoration, etc.
    
    // Restore transactions
    if (backupData.containsKey('transactions')) {
      final transactions = backupData['transactions'] as List<dynamic>;
      for (final transactionData in transactions.take(100)) { // Limit to avoid overwhelming the system
        try {
          final transaction = Transaction.fromJson(transactionData);
          await syncTransaction(transaction);
        } catch (e) {
          debugPrint('Error restoring transaction: $e');
        }
      }
    }
    
    // Restore notification preferences
    if (backupData.containsKey('notificationPreferences')) {
      try {
        await saveNotificationPreferences(backupData['notificationPreferences']);
      } catch (e) {
        debugPrint('Error restoring notification preferences: $e');
      }
    }
    
    // Create restoration record
    await databases.createDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.restorationLogsCollection,
      documentId: ID.unique(),
      data: {
        'user_id': currentUserId!,
        'backup_id': backupId,
        'restored_at': DateTime.now().toIso8601String(),
        'status': 'completed',
      },
    );
  } catch (e) {
    debugPrint('Error restoring from backup: $e');
    throw Exception('Failed to restore from backup: $e');
  }
}
Future<List<Transaction>> searchTransactions(String searchQuery, {
  DateTime? startDate,
  DateTime? endDate,
  String? category,
  bool? isExpense,
  int limit = 50,
}) async {
  try {
    await _checkUserSession();
    
    final queries = [
      Query.equal('user_id', currentUserId!),
      Query.orderDesc('date'),
      Query.limit(limit),
    ];
    
    // Add date filters if provided
    if (startDate != null) {
      queries.add(Query.greaterThanEqual('date', startDate.toIso8601String()));
    }
    if (endDate != null) {
      queries.add(Query.lessThanEqual('date', endDate.toIso8601String()));
    }
    
    // Add category filter if provided
    if (category != null && category.isNotEmpty) {
      queries.add(Query.equal('category', category));
    }
    
    // Add expense/income filter if provided
    if (isExpense != null) {
      queries.add(Query.equal('isExpense', isExpense));
    }
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.transactionsCollection,
      queries: queries,
    );
    
    // Filter by search query on the client side (since Appwrite doesn't support full-text search on all fields)
    final transactions = response.documents
        .map((doc) => Transaction.fromJson(doc.data))
        .where((transaction) {
          final searchLower = searchQuery.toLowerCase();
          return transaction.title.toLowerCase().contains(searchLower) ||
                 (transaction.business?.toLowerCase().contains(searchLower) ?? false) ||
                 transaction.category.toLowerCase().contains(searchLower);
        })
        .toList();
    
    return transactions;
  } catch (e) {
    debugPrint('Error searching transactions: $e');
    return [];
  }
}

// Get transactions by category
Future<List<Transaction>> getTransactionsByCategory(String category, {
  DateTime? startDate,
  DateTime? endDate,
  int limit = 100,
}) async {
  try {
    await _checkUserSession();
    
    final queries = [
      Query.equal('user_id', currentUserId!),
      Query.equal('category', category),
      Query.orderDesc('date'),
      Query.limit(limit),
    ];
    
    if (startDate != null) {
      queries.add(Query.greaterThanEqual('date', startDate.toIso8601String()));
    }
    if (endDate != null) {
      queries.add(Query.lessThanEqual('date', endDate.toIso8601String()));
    }
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.transactionsCollection,
      queries: queries,
    );
    
    return response.documents.map((doc) => Transaction.fromJson(doc.data)).toList();
  } catch (e) {
    debugPrint('Error getting transactions by category: $e');
    return [];
  }
}

// Get unique categories used by user
Future<List<String>> getUserCategories() async {
  try {
    await _checkUserSession();
    
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.transactionsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.orderDesc('date'),
      ],
    );
    
    final categories = <String>{};
    for (final doc in response.documents) {
      final category = doc.data['category'] as String?;
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    
    final categoryList = categories.toList()..sort();
    return categoryList;
  } catch (e) {
    debugPrint('Error getting user categories: $e');
    return [];
  }
}

// BATCH OPERATIONS

// Bulk create transactions
Future<List<String>> bulkCreateTransactions(List<Transaction> transactions) async {
  try {
    await _checkUserSession();
    
    final createdIds = <String>[];
    
    // Process in batches to avoid overwhelming the API
    const batchSize = 10;
    for (int i = 0; i < transactions.length; i += batchSize) {
      final batch = transactions.skip(i).take(batchSize).toList();
      
      for (final transaction in batch) {
        try {
          await syncTransaction(transaction);
          createdIds.add(transaction.id);
        } catch (e) {
          debugPrint('Error creating transaction ${transaction.id}: $e');
        }
      }
      
      // Small delay between batches
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return createdIds;
  } catch (e) {
    debugPrint('Error bulk creating transactions: $e');
    return [];
  }
}

// Bulk delete transactions
Future<int> bulkDeleteTransactions(List<String> transactionIds) async {
  try {
    await _checkUserSession();
    
    int deletedCount = 0;
    
    for (final id in transactionIds) {
      try {
        await deleteTransaction(id);
        deletedCount++;
      } catch (e) {
        debugPrint('Error deleting transaction $id: $e');
      }
    }
    
    return deletedCount;
  } catch (e) {
    debugPrint('Error bulk deleting transactions: $e');
    return 0;
  }
}

// DATA VALIDATION AND CLEANUP

// Validate and fix data integrity
Future<Map<String, dynamic>> validateDataIntegrity() async {
  try {
    await _checkUserSession();
    
    final issues = <String, List<String>>{
      'transactions': [],
      'budgets': [],
      'savingsGoals': [],
      'recurringBills': [],
    };
    
    int fixedIssues = 0;
    
    // Validate transactions
    final transactions = await getTransactions();
    for (final transaction in transactions) {
      // Check for missing required fields
      if (transaction.title.isEmpty) {
        issues['transactions']!.add('Transaction ${transaction.id} has empty title');
      }
      if (transaction.amount == 0) {
        issues['transactions']!.add('Transaction ${transaction.id} has zero amount');
      }
      if (transaction.category.isEmpty) {
        issues['transactions']!.add('Transaction ${transaction.id} has empty category');
        // Fix: Set default category
        try {
          // This would require updating the transaction
          // For now, just log the issue
        } catch (e) {
          debugPrint('Error fixing transaction category: $e');
        }
      }
    }
    
    // Validate budgets
    final budgets = await getBudgets();
    for (final budget in budgets) {
      if (budget.amount <= 0) {
        issues['budgets']!.add('Budget ${budget.id} has invalid amount: ${budget.amount}');
      }
      if (budget.endDate.isBefore(budget.startDate)) {
        issues['budgets']!.add('Budget ${budget.id} has end date before start date');
      }
    }
    
    // Validate savings goals
    final savingsGoals = await fetchSavingsGoals();
    for (final goal in savingsGoals) {
      if (goal.targetAmount <= 0) {
        issues['savingsGoals']!.add('Savings goal ${goal.id} has invalid target amount: ${goal.targetAmount}');
      }
      if (goal.currentAmount < 0) {
        issues['savingsGoals']!.add('Savings goal ${goal.id} has negative current amount: ${goal.currentAmount}');
      }
    }
    
    return {
      'issuesFound': issues.values.expand((list) => list).length,
      'issuesFixed': fixedIssues,
      'issues': issues,
      'validatedAt': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    debugPrint('Error validating data integrity: $e');
    return {
      'error': e.toString(),
      'validatedAt': DateTime.now().toIso8601String(),
    };
  }
}

// Clean up old data
Future<Map<String, int>> cleanupOldData({
  int transactionRetentionDays = 365 * 2, // 2 years
  int notificationRetentionDays = 90, // 3 months
  int backupRetentionDays = 180, // 6 months
}) async {
  try {
    await _checkUserSession();
    
    final now = DateTime.now();
    int cleanedTransactions = 0;
    int cleanedNotifications = 0;
    int cleanedBackups = 0;
    
    // Clean old transactions (only if user has many)
    final transactionCutoff = now.subtract(Duration(days: transactionRetentionDays));
    final oldTransactions = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.transactionsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.lessThan('date', transactionCutoff.toIso8601String()),
      ],
    );
    
    // Only delete if user has more than 1000 transactions
    final totalTransactions = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.transactionsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
      ],
    );
    
    if (totalTransactions.total > 1000) {
      for (final doc in oldTransactions.documents.take(100)) { // Limit cleanup
        try {
          await deleteTransaction(doc.$id);
          cleanedTransactions++;
        } catch (e) {
          debugPrint('Error deleting old transaction: $e');
        }
      }
    }
    
    // Clean old notifications
    final notificationCutoff = now.subtract(Duration(days: notificationRetentionDays));
    final oldNotifications = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.notificationsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.lessThan('created_at', notificationCutoff.toIso8601String()),
      ],
    );
    
    for (final doc in oldNotifications.documents) {
      try {
        await deleteNotification(doc.$id);
        cleanedNotifications++;
      } catch (e) {
        debugPrint('Error deleting old notification: $e');
      }
    }
    
    // Clean old backups (keep only the 5 most recent)
    final allBackups = await getUserBackups();
    if (allBackups.length > 5) {
      final backupsToDelete = allBackups.skip(5).toList();
      for (final backup in backupsToDelete) {
        try {
          await databases.deleteDocument(
            databaseId: AppConfig.databaseId,
            collectionId: AppConfig.backupsCollection,
            documentId: backup['id'],
          );
          cleanedBackups++;
        } catch (e) {
          debugPrint('Error deleting old backup: $e');
        }
      }
    }
    
    return {
      'transactions': cleanedTransactions,
      'notifications': cleanedNotifications,
      'backups': cleanedBackups,
    };
  } catch (e) {
    debugPrint('Error cleaning up old data: $e');
    return {
      'transactions': 0,
      'notifications': 0,
      'backups': 0,
    };
  }
}

// SYNC AND MIGRATION HELPERS

// Sync all local data to cloud
Future<Map<String, dynamic>> syncAllDataToCloud() async {
  try {
    await _checkUserSession();
    
    final results = {
      'transactions': {'synced': 0, 'failed': 0},
      'budgets': {'synced': 0, 'failed': 0},
      'savingsGoals': {'synced': 0, 'failed': 0},
      'startedAt': DateTime.now().toIso8601String(),
    };
    
    // This would typically involve getting data from local storage
    // and syncing it to Appwrite. Since we don't have access to local storage here,
    // this is a placeholder for the sync logic structure.
    
    results['completedAt'] = DateTime.now().toIso8601String();
    return results;
  } catch (e) {
    debugPrint('Error syncing data to cloud: $e');
    return {
      'error': e.toString(),
      'completedAt': DateTime.now().toIso8601String(),
    };
  }
}

// Get sync status
Future<Map<String, dynamic>> getSyncStatus() async {
  try {
    await _checkUserSession();
    
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    // Get recent transactions to determine sync status
    final recentTransactions = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.transactionsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.greaterThan('created_at', oneDayAgo.toIso8601String()),
      ],
    );
    
    final recentBudgets = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.budgetsCollection,
      queries: [
        Query.equal('user_id', currentUserId!),
        Query.greaterThan('created_at', oneDayAgo.toIso8601String()),
      ],
    );
    
    return {
      'lastSyncTime': now.toIso8601String(),
      'recentActivity': {
        'transactions': recentTransactions.total,
        'budgets': recentBudgets.total,
      },
      'status': 'synced', // This would be determined by comparing local vs remote data
      'pendingChanges': 0, // This would be the count of unsynced local changes
    };
  } catch (e) {
    debugPrint('Error getting sync status: $e');
    return {
      'status': 'error',
      'error': e.toString(),
      'lastSyncTime': DateTime.now().toIso8601String(),
    };
  }
}
}