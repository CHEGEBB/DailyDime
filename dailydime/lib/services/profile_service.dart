// lib/services/profile_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
        collectionId: '68851a2d000ed1577872',
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
      rethrow;
    }
  }

  // Get a user's profile by their user ID
  Future<models.Document?> getUserProfile(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
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

  // Get a profile by profile document ID
  Future<models.Document?> getProfileById(String profileId) async {
    try {
      return await _databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        documentId: profileId,
      );
    } catch (e) {
      if (e is AppwriteException && e.code == 404) {
        return null; // Profile not found
      }
      rethrow;
    }
  }

  // Update a user's profile with expanded preferences
  Future<models.Document> updateUserProfile({
    required String profileId,
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

      if (phone != null) data['phone'] = phone;
      if (occupation != null) data['occupation'] = occupation;
      if (location != null) data['location'] = location;
      if (notificationsEnabled != null) data['notificationsEnabled'] = notificationsEnabled;
      if (darkModeEnabled != null) data['darkModeEnabled'] = darkModeEnabled;
      if (biometricsEnabled != null) data['biometricsEnabled'] = biometricsEnabled;

      return await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        documentId: profileId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update a specific user preference
  Future<models.Document> updateUserPreference({
    required String profileId,
    required String preferenceKey,
    required dynamic preferenceValue, required String key, required bool value,
  }) async {
    try {
      // Validate preference keys
      final validPreferences = [
        'notificationsEnabled',
        'darkModeEnabled',
        'biometricsEnabled',
        'phone',
        'occupation',
        'location',
        'name',
        'email'
      ];

      if (!validPreferences.contains(preferenceKey)) {
        throw Exception('Invalid preference key: $preferenceKey');
      }

      return await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        documentId: profileId,
        data: {
          preferenceKey: preferenceValue,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Convenience methods for updating specific preferences
  Future<models.Document> updateNotificationPreference({
    required String profileId,
    required bool enabled,
  }) async {
    return await updateUserPreference(
      profileId: profileId,
      preferenceKey: 'notificationsEnabled',
      preferenceValue: enabled,
    );
  }

  Future<models.Document> updateDarkModePreference({
    required String profileId,
    required bool enabled,
  }) async {
    return await updateUserPreference(
      profileId: profileId,
      preferenceKey: 'darkModeEnabled',
      preferenceValue: enabled,
    );
  }

  Future<models.Document> updateBiometricsPreference({
    required String profileId,
    required bool enabled,
  }) async {
    return await updateUserPreference(
      profileId: profileId,
      preferenceKey: 'biometricsEnabled',
      preferenceValue: enabled,
    );
  }

  Future<models.Document> updatePhoneNumber({
    required String profileId,
    required String phone,
  }) async {
    return await updateUserPreference(
      profileId: profileId,
      preferenceKey: 'phone',
      preferenceValue: phone,
    );
  }

  Future<models.Document> updateOccupation({
    required String profileId,
    required String occupation,
  }) async {
    return await updateUserPreference(
      profileId: profileId,
      preferenceKey: 'occupation',
      preferenceValue: occupation,
    );
  }

  Future<models.Document> updateLocation({
    required String profileId,
    required String location,
  }) async {
    return await updateUserPreference(
      profileId: profileId,
      preferenceKey: 'location',
      preferenceValue: location,
    );
  }

  // Update multiple user preferences at once
  Future<models.Document> updateUserPreferences({
    required String profileId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      // Validate preference keys
      final validPreferences = [
        'notificationsEnabled',
        'darkModeEnabled',
        'biometricsEnabled',
        'phone',
        'occupation',
        'location',
        'name',
        'email'
      ];

      for (String key in preferences.keys) {
        if (!validPreferences.contains(key)) {
          throw Exception('Invalid preference key: $key');
        }
      }

      Map<String, dynamic> data = Map<String, dynamic>.from(preferences);
      data['updatedAt'] = DateTime.now().toIso8601String();

      return await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        documentId: profileId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload a profile image (supports both web and mobile)
  Future<String?> uploadProfileImage(dynamic fileSource, String fileName) async {
    try {
      InputFile inputFile;
      
      if (kIsWeb) {
        // For web, expect Uint8List bytes
        if (fileSource is Uint8List) {
          inputFile = InputFile.fromBytes(
            bytes: fileSource,
            filename: fileName,
          );
        } else {
          throw Exception('For web platform, file must be provided as Uint8List');
        }
      } else {
        // For mobile/desktop, expect file path
        if (fileSource is String) {
          inputFile = InputFile.fromPath(
            path: fileSource,
            filename: fileName,
          );
        } else {
          throw Exception('For mobile/desktop platforms, file must be provided as file path');
        }
      }
      
      final file = await _storage.createFile(
        bucketId: AppConfig.mainBucket,
        fileId: ID.unique(),
        file: inputFile,
      );
      
      return file.$id;
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to upload from bytes (useful for web)
  Future<String?> uploadProfileImageFromBytes(Uint8List bytes, String fileName) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppConfig.mainBucket,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: bytes,
          filename: fileName,
        ),
      );
      
      return file.$id;
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to upload from path (useful for mobile)
  Future<String?> uploadProfileImageFromPath(String filePath, String fileName) async {
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
        collectionId: '68851a2d000ed1577872',
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
        collectionId: '68851a2d000ed1577872',
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

  // Delete a profile
  Future<void> deleteProfile(String profileId) async {
    try {
      // First, get the profile to check for profile image
      final profile = await _databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        documentId: profileId,
      );
      
      // Delete profile image if exists
      final imageId = profile.data['profileImageId'];
      if (imageId != null) {
        try {
          await _storage.deleteFile(
            bucketId: AppConfig.mainBucket,
            fileId: imageId,
          );
        } catch (e) {
          print('Error deleting profile image: $e');
        }
      }
      
      // Delete the profile document
      await _databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        documentId: profileId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  // Get profile preference value
  Future<T?> getProfilePreference<T>(String profileId, String preferenceKey) async {
    try {
      final profile = await getProfileById(profileId);
      if (profile != null) {
        return profile.data[preferenceKey] as T?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Additional helper methods for better error handling and validation

  // Validate profile data before creation/update
  bool _validateProfileData(Map<String, dynamic> data) {
    // Check for required fields
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      return false;
    }
    if (data['email'] == null || data['email'].toString().trim().isEmpty) {
      return false;
    }
    
    // Validate email format (basic validation)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(data['email'].toString())) {
      return false;
    }
    
    return true;
  }

  // Get all profiles (admin function - use with caution)
  Future<List<models.Document>> getAllProfiles({
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        queries: [
          Query.limit(limit),
          Query.offset(offset),
          Query.orderDesc('createdAt'),
        ],
      );
      
      return response.documents;
    } catch (e) {
      rethrow;
    }
  }

  // Search profiles by name or email
  Future<List<models.Document>> searchProfiles(String searchTerm, {
    int limit = 10,
  }) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        queries: [
          Query.search('name', searchTerm),
          Query.limit(limit),
        ],
      );
      
      return response.documents;
    } catch (e) {
      rethrow;
    }
  }

  // Get profile statistics
  Future<Map<String, dynamic>> getProfileStats(String profileId) async {
    try {
      final profile = await getProfileById(profileId);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      final createdAt = DateTime.parse(profile.data['createdAt']);
      final updatedAt = DateTime.parse(profile.data['updatedAt']);
      final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
      final daysSinceLastUpdate = DateTime.now().difference(updatedAt).inDays;

      return {
        'profileId': profileId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'daysSinceCreation': daysSinceCreation,
        'daysSinceLastUpdate': daysSinceLastUpdate,
        'hasProfileImage': profile.data['profileImageId'] != null,
        'notificationsEnabled': profile.data['notificationsEnabled'] ?? false,
        'darkModeEnabled': profile.data['darkModeEnabled'] ?? false,
        'biometricsEnabled': profile.data['biometricsEnabled'] ?? false,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Batch update profiles (admin function)
  Future<List<models.Document>> batchUpdateProfiles({
    required List<String> profileIds,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      List<models.Document> updatedProfiles = [];
      
      for (String profileId in profileIds) {
        try {
          final updatedProfile = await _databases.updateDocument(
            databaseId: AppConfig.databaseId,
            collectionId: '68851a2d000ed1577872',
            documentId: profileId,
            data: {
              ...updateData,
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
          updatedProfiles.add(updatedProfile);
        } catch (e) {
          print('Error updating profile $profileId: $e');
          // Continue with other profiles
        }
      }
      
      return updatedProfiles;
    } catch (e) {
      rethrow;
    }
  }

  // Export profile data (for data portability)
  Future<Map<String, dynamic>> exportProfileData(String profileId) async {
    try {
      final profile = await getProfileById(profileId);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // Create a clean export of profile data
      Map<String, dynamic> exportData = {
        'profile': {
          'name': profile.data['name'],
          'email': profile.data['email'],
          'phone': profile.data['phone'],
          'occupation': profile.data['occupation'],
          'location': profile.data['location'],
          'preferences': {
            'notifications': profile.data['notificationsEnabled'],
            'darkMode': profile.data['darkModeEnabled'],
            'biometrics': profile.data['biometricsEnabled'],
          },
          'metadata': {
            'createdAt': profile.data['createdAt'],
            'updatedAt': profile.data['updatedAt'],
          },
        },
        'exportedAt': DateTime.now().toIso8601String(),
      };

      return exportData;
    } catch (e) {
      rethrow;
    }
  }
}