// lib/services/appwrite_service.dart

import 'package:appwrite/appwrite.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:flutter/material.dart';
import 'package:dailydime/models/savings_goal.dart';

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
      .setEndpoint(AppConfig.appwriteEndpoint)
      .setProject(AppConfig.appwriteProjectId);
    
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
  
  // BUDGET METHODS
  
  // Get all budgets from Appwrite
  Future<List<Budget>> getBudgets() async {
    try {
      if (currentUserId == null) {
        return [];
      }
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
        queries: [
          Query.equal('user_id', currentUserId!),
        ],
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
      name: data['title'] ?? 'Budget',
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
  
  // Transaction methods
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
  
  Future<List<Transaction>> getTransactions() async {
    try {
      if (currentUserId == null) {
        return [];
      }
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        queries: [
          Query.equal('user_id', currentUserId!),
          Query.orderDesc('date'),
        ],
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

  // SAVINGS GOAL METHODS

  // Fetch all savings goals
  Future<List<SavingsGoal>> fetchSavingsGoals() async {
    try {
      await _checkUserSession();
      
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        queries: [
          Query.equal('userId', currentUserId!),
          Query.orderDesc('\$createdAt'),
        ],
      );
      
      return response.documents.map((doc) {
        final data = doc.data;
        return SavingsGoal.fromMap({
          'id': doc.$id,
          ...data,
        });
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
      
      final goalMap = goal.toMap();
      goalMap['userId'] = currentUserId;
      goalMap['created_at'] = DateTime.now().toIso8601String();
      goalMap['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        documentId: ID.unique(),
        data: goalMap,
      );
      
      return SavingsGoal.fromMap({
        'id': response.$id,
        ...response.data,
      });
    } catch (e) {
      debugPrint('Error creating savings goal: $e');
      rethrow;
    }
  }

  // Update an existing savings goal
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    try {
      await _checkUserSession();
      
      final goalMap = goal.toMap();
      goalMap['userId'] = currentUserId;
      goalMap['updated_at'] = DateTime.now().toIso8601String();
      
      await databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
        documentId: goal.id,
        data: goalMap,
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
        collectionId: AppConfig.savingsChallengesCollection, // Ensure this getter is defined in AppConfig
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
}