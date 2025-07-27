// lib/screens/profile_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/services/profile_service.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dailydime/widgets/common/glass_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:blurrycontainer/blurrycontainer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late final ProfileService _profileService;
  
  // Animation controller
  late AnimationController _animationController;
  
  // Theme colors
  final Color primaryColor = const Color(0xFF26D07C); // Emerald
  final Color secondaryColor = const Color(0xFF0AB3B8); // Teal
  final Color accentColor = const Color(0xFF68EFC6); // Light emerald
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  
  // User data
  models.User? _currentUser;
  models.Document? _userProfile;
  String? _profileImageUrl;
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricsEnabled = false;
  bool _savingPreferences = false;
  bool _showSettings = false;
  
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadUserData();
    
    // Set status bar to transparent
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
    _animationController.dispose();
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
            
            // Set dark mode preference if available
            if (_userProfile!.data.containsKey('darkModeEnabled')) {
              _darkModeEnabled = _userProfile!.data['darkModeEnabled'];
            }
            
            // Set biometrics preference if available
            if (_userProfile!.data.containsKey('biometricsEnabled')) {
              _biometricsEnabled = _userProfile!.data['biometricsEnabled'];
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
      if (kIsWeb) {
        await _pickImageWeb();
      } else {
        await _pickImageMobile();
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image. Please try again.');
    }
  }
  
  Future<void> _pickImageWeb() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _webImageBytes = result.files.first.bytes;
      });
      
      // Upload image immediately
      await _uploadProfileImageWeb();
    }
  }
  
  Future<void> _pickImageMobile() async {
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
      await _uploadProfileImageMobile();
    }
  }
  
  Future<void> _uploadProfileImageWeb() async {
    if (_webImageBytes == null || _currentUser == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final fileName = '${_currentUser!.$id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload image to Appwrite storage using bytes for web
      final imageId = await _profileService.uploadProfileImageFromBytes(
        _webImageBytes!,
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
      _showErrorSnackBar('Error uploading image: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _uploadProfileImageMobile() async {
    if (_imageFile == null || _currentUser == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final fileName = '${_currentUser!.$id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload image to Appwrite storage using file path for mobile
      final imageId = await _profileService.uploadProfileImageFromPath(
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
      _showErrorSnackBar('Error uploading image: $e');
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
        darkModeEnabled: _darkModeEnabled,
        biometricsEnabled: _biometricsEnabled,
      );
      
      // Reload profile data
      _userProfile = await _profileService.getUserProfile(_currentUser!.$id);
      
      setState(() => _isEditing = false);
      _showSuccessSnackBar('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      _showErrorSnackBar('Error updating profile: $e');
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
    _updatePreference('notificationsEnabled', value);
  }
  
  Future<void> _toggleDarkModePreference(bool value) async {
    _updatePreference('darkModeEnabled', value);
  }
  
  Future<void> _toggleBiometricsPreference(bool value) async {
    _updatePreference('biometricsEnabled', value);
  }
  
  Future<void> _updatePreference(String key, bool value) async {
    if (_currentUser == null || _userProfile == null) return;
    
    setState(() {
      if (key == 'notificationsEnabled') _notificationsEnabled = value;
      if (key == 'darkModeEnabled') _darkModeEnabled = value;
      if (key == 'biometricsEnabled') _biometricsEnabled = value;
      _savingPreferences = true;
    });
    
    try {
      Map<String, dynamic> data = {
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      data[key] = value;
      
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: '68851a2d000ed1577872',
        documentId: _userProfile!.$id,
        data: data,
      );
      
      _showSuccessSnackBar('Preferences updated');
    } catch (e) {
      print('Error updating preference: $e');
      
      // Revert change on error
      setState(() {
        if (key == 'notificationsEnabled') _notificationsEnabled = !value;
        if (key == 'darkModeEnabled') _darkModeEnabled = !value;
        if (key == 'biometricsEnabled') _biometricsEnabled = !value;
      });
      
      _showErrorSnackBar('Failed to update preference');
    } finally {
      setState(() => _savingPreferences = false);
    }
  }
  
  // Get a reference to Databases
  Databases get _databases => Databases(_profileService.client);
  
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
                _buildPasswordField(
                  controller: _currentPasswordController,
                  labelText: 'Current Password',
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _newPasswordController,
                  labelText: 'New Password',
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm New Password',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Update Password'),
              onPressed: _changePassword,
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
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
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      
      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error logging out: $e');
      _showErrorSnackBar('Failed to log out. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  void _toggleSettingsScreen() {
    setState(() {
      _showSettings = !_showSettings;
    });
    
    if (_showSettings) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: _isLoading
            ? Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 120,
                  height: 120,
                ),
              )
            : Stack(
                children: [
                  // Main profile content
                  AnimatedOpacity(
                    opacity: _showSettings ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildProfileContent(screenSize),
                  ),
                  
                  // Settings screen (slide in from right)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          screenSize.width * (1 - _animationController.value), 
                          0
                        ),
                        child: child,
                      );
                    },
                    child: _showSettings ? _buildSettingsScreen(screenSize) : const SizedBox(),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildProfileContent(Size screenSize) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern floating profile header with glassmorphism
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                        primaryColor,
                        secondaryColor,
                      ],
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/pattern8.png'),
                      fit: BoxFit.cover,
                      opacity: 0.3,
                    ),
                  ),
                ),
                
                // Bottom curve
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                
                // Profile content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Profile avatar with glassmorphic effect
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Profile avatar
                              Hero(
                                tag: 'profileAvatar',
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 52,
                                    backgroundColor: accentColor.withOpacity(0.2),
                                    backgroundImage: _profileImageUrl != null
                                        ? NetworkImage(_profileImageUrl!)
                                        : null,
                                    child: _profileImageUrl == null
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: primaryColor,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              
                              // Loading indicator
                              if (_isSaving)
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                              
                              // Edit icon
                              if (_isEditing)
                                Positioned(
                                  right: 0,
                                  bottom: 5,
                                  child: GlassKit(
                                    borderRadius: BorderRadius.circular(50),
                                    blur: 10,
                                    linearGradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        primaryColor.withOpacity(0.5),
                                        primaryColor.withOpacity(0.2),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2), 
                                      width: 1.5,
                                    ),
                                    borderGradient: null,
                                    height: 36,
                                    width: 36,
                                    child: const Center(
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(
                        begin: 0.3, 
                        end: 0,
                        curve: Curves.easeOutQuad,
                        duration: 800.ms,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // User name
                      Text(
                        _currentUser?.name ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      
                      const SizedBox(height: 4),
                      
                      // User email
                      Text(
                        _currentUser?.email ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                    ],
                  ),
                ),
                
                // App bar actions
                Positioned(
                  top: 50,
                  right: 16,
                  child: Row(
                    children: [
                      // Edit button with glass effect
                      GlassKit(
                        height: 45,
                        width: 45,
                        borderRadius: BorderRadius.circular(15),
                        blur: 10,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2), 
                          width: 1.5,
                        ),
                        borderGradient: null,
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
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Settings button with glass effect
                      GlassKit(
                        height: 45,
                        width: 45,
                        borderRadius: BorderRadius.circular(15),
                        blur: 10,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2), 
                          width: 1.5,
                        ),
                        borderGradient: null,
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white),
                          onPressed: _toggleSettingsScreen,
                          tooltip: 'Settings',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                ),
              ],
            ),
          ),
        ),
        
        // Profile form content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Personal Information section
                _buildSectionHeader('Personal Information', Icons.person_outline),
                const SizedBox(height: 16),
                _buildProfileForm(),
                
                const SizedBox(height: 30),
                
                // Account Statistics section
                _buildSectionHeader('Account Statistics', Icons.bar_chart_outlined),
                const SizedBox(height: 16),
                _buildStatisticsSection(),
                
                const SizedBox(height: 30),
                
                // Action buttons
                _buildActionButtons(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(
      begin: -0.1,
      end: 0,
      curve: Curves.easeOutQuad,
      duration: 800.ms,
    );
  }
  
  Widget _buildProfileForm() {
    return BlurryContainer(
      blur: 5,
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          // Name field
          _buildProfileField(
            controller: _nameController,
            labelText: 'Full Name',
            icon: Icons.person_outline,
            enabled: _isEditing,
          ),
          
          const SizedBox(height: 16),
          
          // Email field
          _buildProfileField(
            controller: _emailController,
            labelText: 'Email',
            icon: Icons.email_outlined,
            enabled: false,
          ),
          
          const SizedBox(height: 16),
          
          // Phone field
          _buildProfileField(
            controller: _phoneController,
            labelText: 'Phone Number',
            icon: Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            hintText: 'E.g., +254712345678',
          ),
          
          const SizedBox(height: 16),
          
          // Occupation field
          _buildProfileField(
            controller: _occupationController,
            labelText: 'Occupation',
            icon: Icons.work_outline,
            enabled: _isEditing,
          ),
          
          const SizedBox(height: 16),
          
          // Location field
          _buildProfileField(
            controller: _locationController,
            labelText: 'Location',
            icon: FontAwesomeIcons.locationDot,
            enabled: _isEditing,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 600.ms);
  }
  
  Widget _buildProfileField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.grey[800],
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? primaryColor : Colors.grey[400],
          size: 20,
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatisticsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Budget Goals',
            value: '3',
            icon: FontAwesomeIcons.bullseye,
            color: const Color(0xFF5E72E4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Transactions',
            value: '42',
            icon: FontAwesomeIcons.moneyBillTransfer,
            color: const Color(0xFFFAB027),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Savings',
            value: '2',
            icon: FontAwesomeIcons.piggyBank,
            color: const Color(0xFF11CDEF),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassKit(
      borderRadius: BorderRadius.circular(20),
      blur: 8,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.5),
        ],
      ),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      borderGradient: null,
      height: 110,
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Change Password Button
        _buildActionButton(
          title: 'Change Password',
          icon: Icons.lock_outline,
          color: const Color(0xFFFB6340),
          onTap: _showChangePasswordDialog,
        ),
        
        const SizedBox(height: 16),
        
        // Logout Button
        _buildActionButton(
          title: 'Sign Out',
          icon: Icons.logout,
          color: Colors.red.shade700,
          onTap: _confirmLogout,
          isOutlined: true,
        ),
        
        const SizedBox(height: 24),
        
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
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms);
  }
  
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isOutlined 
              ? null 
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
          color: isOutlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined 
              ? Border.all(color: color, width: 2) 
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined ? color : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isOutlined ? color : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsScreen(Size screenSize) {
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Settings Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: _toggleSettingsScreen,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            // Settings List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Appearance Section
                  _buildSettingsSectionHeader('Appearance'),
                  const SizedBox(height: 16),
                  _buildSettingsCard([
                    _buildSettingsToggle(
                      title: 'Dark Mode',
                      subtitle: 'Enable dark theme throughout the app',
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFF5E72E4),
                      value: _darkModeEnabled,
                      onChanged: _toggleDarkModePreference,
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'App Theme',
                      subtitle: 'Customize your app colors',
                      icon: Icons.color_lens_outlined,
                      iconColor: const Color(0xFFFB6340),
                      onTap: () {
                        // Navigate to theme selection screen
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Notifications Section
                  _buildSettingsSectionHeader('Notifications'),
                  const SizedBox(height: 16),
                  _buildSettingsCard([
                    _buildSettingsToggle(
                      title: 'Push Notifications',
                      subtitle: 'Get notified about important updates',
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFFF9500),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotificationPreference,
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'Budget Alerts',
                      subtitle: 'Configure budget threshold notifications',
                      icon: FontAwesomeIcons.bell,
                      iconColor: const Color(0xFF11CDEF),
                      onTap: () {
                        // Navigate to notification settings screen
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Security Section
                  _buildSettingsSectionHeader('Security'),
                  const SizedBox(height: 16),
                  _buildSettingsCard([
                    _buildSettingsToggle(
                      title: 'Biometric Authentication',
                      subtitle: 'Use fingerprint or face ID to login',
                      icon: Icons.fingerprint,
                      iconColor: primaryColor,
                      value: _biometricsEnabled,
                      onChanged: _toggleBiometricsPreference,
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      icon: Icons.lock_outline,
                      iconColor: const Color(0xFFFF3B30),
                      onTap: _showChangePasswordDialog,
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'Privacy Settings',
                      subtitle: 'Manage your data and privacy',
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF007AFF),
                      onTap: () {
                        // Navigate to privacy settings
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Support Section
                  _buildSettingsSectionHeader('Support'),
                  const SizedBox(height: 16),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      title: 'Help Center',
                      subtitle: 'Get help with using the app',
                      icon: Icons.help_outline,
                      iconColor: const Color(0xFF34C759),
                      onTap: () {
                        // Navigate to help center
                      },
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'Contact Support',
                      subtitle: 'Email our support team',
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF5856D6),
                      onTap: () {
                        // Open email client
                      },
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'Report a Bug',
                      subtitle: 'Help us improve the app',
                      icon: Icons.bug_report_outlined,
                      iconColor: const Color(0xFFFF2D55),
                      onTap: () {
                        // Navigate to bug report form
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // About Section
                  _buildSettingsSectionHeader('About'),
                  const SizedBox(height: 16),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      title: 'About DailyDime',
                      subtitle: 'Learn more about the app',
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF007AFF),
                      onTap: () {
                        // Show about dialog
                      },
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'Terms of Service',
                      subtitle: 'Read our terms and conditions',
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFF8E8E93),
                      onTap: () {
                        // Navigate to terms screen
                      },
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsItem(
                      title: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF8E8E93),
                      onTap: () {
                        // Navigate to privacy policy screen
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 30),
                  
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
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }
  
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
  
  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _savingPreferences ? null : onChanged,
            activeColor: primaryColor,
            activeTrackColor: primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 0.5,
      color: Colors.grey.withOpacity(0.2),
    );
  }
}