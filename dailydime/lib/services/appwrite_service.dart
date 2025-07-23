// lib/services/appwrite_service.dart

import 'package:appwrite/appwrite.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:flutter/material.dart';

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
  
  // User authentication methods can be added here
}