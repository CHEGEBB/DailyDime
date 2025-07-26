import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/services/profile_service.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:dailydime/widgets/common/custom_text_field_profile.dart';
import 'package:dailydime/widgets/common/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as path;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  late final ProfileService _profileService;
  
  // User data
  models.User? _currentUser;
  models.Document? _userProfile;
  String? _profileImageUrl;
  File? _imageFile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _notificationsEnabled = true;
  bool _savingPreferences = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Password change controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Image picker
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _loadUserData();
    
    // Set status bar to transparent to allow our custom background to show through
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _locationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user from Appwrite
      _currentUser = await _authService.getCurrentUser();
      
      if (_currentUser != null) {
        // Initialize controllers with current user data
        _nameController.text = _currentUser!.name;
        _emailController.text = _currentUser!.email;
        
        // Try to fetch user profile document
        try {
          _userProfile = await _profileService.getUserProfile(_currentUser!.$id);
          
          if (_userProfile != null) {
            // Set phone number if available
            if (_userProfile!.data.containsKey('phone') && _userProfile!.data['phone'] != null) {
              _phoneController.text = _userProfile!.data['phone'];
            }
            
            // Set occupation if available
            if (_userProfile!.data.containsKey('occupation') && _userProfile!.data['occupation'] != null) {
              _occupationController.text = _userProfile!.data['occupation'];
            }
            
            // Set location if available
            if (_userProfile!.data.containsKey('location') && _userProfile!.data['location'] != null) {
              _locationController.text = _userProfile!.data['location'];
            }
            
            // Set notification preference if available
            if (_userProfile!.data.containsKey('notificationsEnabled')) {
              _notificationsEnabled = _userProfile!.data['notificationsEnabled'];
            }
            
            // Get profile image URL if available
            if (_userProfile!.data.containsKey('profileImageId') && 
                _userProfile!.data['profileImageId'] != null) {
              _profileImageUrl = await _profileService.getProfileImageUrl(
                _userProfile!.data['profileImageId']
              );
            }
          } else {
            // Create a new profile document if none exists
            await _createNewProfile();
          }
        } catch (e) {
          print('Error loading profile: $e');
          // Create a new profile document if there was an error
          await _createNewProfile();
        }
      }
    } catch (e) {
      print('Error in _loadUserData: $e');
      _showErrorSnackBar('Failed to load profile data. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _createNewProfile() async {
    if (_currentUser == null) return;
    
    try {
      // Create a new profile document with basic user info
      _userProfile = await _profileService.createUserProfile(
        userId: _currentUser!.$id,
        name: _currentUser!.name,
        email: _currentUser!.email,
      );
    } catch (e) {
      print('Error creating profile: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // Upload image immediately
        await _uploadProfileImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image. Please try again.');
    }
  }
  
  Future<void> _uploadProfileImage() async {
    if (_imageFile == null || _currentUser == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final fileName = '${_currentUser!.$id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_imageFile!.path)}';
      
      // Upload image to Appwrite storage
      final imageId = await _profileService.uploadProfileImage(
        _imageFile!.path,
        fileName,
      );
      
      if (imageId != null) {
        // Update profile with new image ID
        await _profileService.updateProfileImage(
          profileId: _userProfile!.$id,
          imageId: imageId,
        );
        
        // Get the image URL
        _profileImageUrl = await _profileService.getProfileImageUrl(imageId);
        
        _showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      print('Error uploading image: $e');
      _showErrorSnackBar('Failed to upload profile picture. Please try again.');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _updateProfile() async {
    if (_currentUser == null || _userProfile == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Update user name in account if changed
      if (_nameController.text != _currentUser!.name) {
        await _authService.updateAccountName(name: _nameController.text);
        // Reload current user to get updated name
        _currentUser = await _authService.getCurrentUser();
      }
      
      // Update profile data
      await _profileService.updateUserProfile(
        profileId: _userProfile!.$id,
        phone: _phoneController.text,
        occupation: _occupationController.text,
        location: _locationController.text,
        notificationsEnabled: _notificationsEnabled,
      );
      
      // Reload profile data
      _userProfile = await _profileService.getUserProfile(_currentUser!.$id);
      
      setState(() => _isEditing = false);
      _showSuccessSnackBar('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      _showErrorSnackBar('Failed to update profile. Please try again.');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _changePassword() async {
    // Validate passwords
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('All password fields are required');
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }
    
    if (_newPasswordController.text.length < 8) {
      _showErrorSnackBar('Password must be at least 8 characters long');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      await _authService.updatePassword(
        password: _newPasswordController.text,
        oldPassword: _currentPasswordController.text,
      );
      
      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      Navigator.of(context).pop(); // Close dialog
      _showSuccessSnackBar('Password changed successfully');
    } catch (e) {
      print('Error changing password: $e');
      _showErrorSnackBar(_authService.handleAuthError(e));
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _toggleNotificationPreference(bool value) async {
    if (_currentUser == null || _userProfile == null) return;
    
    setState(() {
      _notificationsEnabled = value;
      _savingPreferences = true;
    });
    
    try {
      await _profileService.updateUserProfile(
        profileId: _userProfile!.$id,
        notificationsEnabled: value,
      );
      
      _showSuccessSnackBar('Notification preference updated');
    } catch (e) {
      print('Error updating notification preference: $e');
      setState(() => _notificationsEnabled = !value); // Revert change
      _showErrorSnackBar('Failed to update notification preference');
    } finally {
      setState(() => _savingPreferences = false);
    }
  }
  
  Future<void> _showChangePasswordDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _currentPasswordController,
                  labelText: 'Current Password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _newPasswordController,
                  labelText: 'New Password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm New Password',
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26D07C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Change Password'),
              onPressed: _changePassword,
            ),
          ],
        );
      },
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF26D07C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  Future<void> _confirmLogout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _logout() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.logout();
      
      // Navigate to login screen - replace with your navigation logic
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error logging out: $e');
      _showErrorSnackBar('Failed to log out. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF26D07C); // Emerald green
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern floating profile header
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: accentColor,
              elevation: 0,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background with pattern
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.8),
                            accentColor.withOpacity(0.7),
                          ],
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/pattern8.png'),
                          fit: BoxFit.cover,
                          opacity: 0.4,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    
                    // Profile content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Profile avatar with shadow
                          GestureDetector(
                            onTap: _isEditing ? _pickImage : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Hero(
                                  tag: 'profileAvatar',
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: _isSaving
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: _imageFile != null
                                                ? Image.file(
                                                    _imageFile!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : _profileImageUrl != null
                                                    ? CachedNetworkImage(
                                                        imageUrl: _profileImageUrl!,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => Center(
                                                          child: CircularProgressIndicator(
                                                            color: accentColor,
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                        errorWidget: (context, url, error) => const Icon(
                                                          Icons.person,
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                          ),
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // User name and email
                          Text(
                            _currentUser?.name ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?.email ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // App bar actions
                    Positioned(
                      top: 50,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isEditing ? Icons.check : Icons.edit_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_isEditing) {
                                  // Save changes
                                  _updateProfile();
                                } else {
                                  // Enter edit mode
                                  setState(() {
                                    _isEditing = true;
                                  });
                                }
                              },
                              tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.settings_outlined, color: Colors.white),
                              onPressed: () {
                                // Navigate to settings screen or expand settings
                              },
                              tooltip: 'Settings',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Profile form content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? Center(
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          width: 100,
                          height: 100,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Section
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Personal Info Form
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Name field
                                CustomTextField(
                                  controller: _nameController,
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  enabled: _isEditing,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Email field (read-only as changing email requires verification)
                                CustomTextField(
                                  controller: _emailController,
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  enabled: false, // Email change requires verification
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Phone field
                                CustomTextField(
                                  controller: _phoneController,
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.phone,
                                  hintText: 'E.g., +254712345678',
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Occupation field
                                CustomTextField(
                                  controller: _occupationController,
                                  labelText: 'Occupation',
                                  prefixIcon: const Icon(Icons.work_outline),
                                  enabled: _isEditing,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Location field
                                CustomTextField(
                                  controller: _locationController,
                                  labelText: 'Location',
                                  prefixIcon: const Icon(Icons.location_on_outlined),
                                  enabled: _isEditing,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Account Settings Section
                          const Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Account Settings Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Change Password
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  title: const Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _showChangePasswordDialog,
                                ),
                                
                                const Divider(),
                                
                                // Notifications
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  title: const Text(
                                    'Push Notifications',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Switch(
                                    value: _notificationsEnabled,
                                    onChanged: _savingPreferences ? null : _toggleNotificationPreference,
                                    activeColor: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Help & Support Section
                          const Text(
                            'Help & Support',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Help Center
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.help_outline,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  title: const Text(
                                    'Help Center',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Navigate to help center
                                  },
                                ),
                                
                                const Divider(),
                                
                                // Privacy Policy
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.privacy_tip_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  title: const Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Navigate to privacy policy
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Logout Button
                          CustomButton(
                            isSmall: false,
                            text: 'Sign Out',
                            onPressed: _confirmLogout,
                            isOutlined: true,
                            icon: Icons.logout,
                            buttonColor: Colors.red,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // App Version
                          Center(
                            child: Text(
                              'DailyDime v${AppConfig.appVersion}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}