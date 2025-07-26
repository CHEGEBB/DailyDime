// lib/services/profile_service.dart
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:dailydime/config/app_config.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Initialize Appwrite client
  final Client client = Client()
    ..setEndpoint(AppConfig.appwriteEndpoint)
    ..setProject(AppConfig.appwriteProjectId)
    ..setSelfSigned(status: true); // Remove this in production

  // Initialize Appwrite services
  late final Databases _databases = Databases(client);
  late final Storage _storage = Storage(client);

  // Create a profile for a user
  Future<models.Document> createUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? occupation,
    String? location,
  }) async {
    try {
      return await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872', // We'll create this collection
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
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get a user's profile by their user ID
  Future<models.Document?> getUserProfile(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        queries: [
          Query.equal('userId', userId),
        ],
      );

      if (response.documents.isNotEmpty) {
        return response.documents.first;
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update a user's profile
  Future<models.Document> updateUserProfile({
    required String profileId,
    String? phone,
    String? occupation,
    String? location,
    bool? notificationsEnabled,
  }) async {
    try {
      Map<String, dynamic> data = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (phone != null) data['phone'] = phone;
      if (occupation != null) data['occupation'] = occupation;
      if (location != null) data['location'] = location;
      if (notificationsEnabled != null) data['notificationsEnabled'] = notificationsEnabled;

      return await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        documentId: profileId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload a profile image
  Future<String?> uploadProfileImage(String filePath, String fileName) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppConfig.mainBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: filePath,
          filename: fileName,
        ),
      );
      
      return file.$id;
    } catch (e) {
      rethrow;
    }
  }

  // Update profile with new image ID
  Future<models.Document> updateProfileImage({
    required String profileId,
    required String imageId,
  }) async {
    try {
      // Delete old profile image if exists
      final profile = await _databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        documentId: profileId,
      );
      
      final oldImageId = profile.data['profileImageId'];
      
      if (oldImageId != null) {
        try {
          await _storage.deleteFile(
            bucketId: AppConfig.mainBucket,
            fileId: oldImageId,
          );
        } catch (e) {
          // Ignore errors when deleting old images
          print('Error deleting old image: $e');
        }
      }
      
      // Update profile with new image ID
      return await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        documentId: profileId,
        data: {
          'profileImageId': imageId,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get profile image URL
  Future<String> getProfileImageUrl(String imageId) async {
    try {
      return _storage.getFileView(
        bucketId: AppConfig.mainBucket,
        fileId: imageId,
      ).toString();
    } catch (e) {
      rethrow;
    }
  }
}