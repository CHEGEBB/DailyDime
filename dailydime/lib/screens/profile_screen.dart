// lib/screens/profile_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/screens/settings_screen.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/services/profile_service.dart';
import 'package:dailydime/utils/settings_storage.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  late final ProfileService _profileService;
  final _settingsStorage = SettingsStorage();
  
  // Theme colors
  final Color primaryColor = const Color(0xFF26D07C); // Emerald
  final Color secondaryColor = const Color(0xFF0AB3B8); // Teal
  final Color accentColor = const Color(0xFF68EFC6); // Light emerald
  final Color backgroundColor = const Color(0xFFF8F9FA);
  
  // User data
  models.User? _currentUser;
  models.Document? _userProfile;
  String? _profileImageUrl;
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Image picker
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
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
            
            // Store preferences in local storage
            if (_userProfile!.data.containsKey('notificationsEnabled')) {
              await _settingsStorage.setNotificationsEnabled(
                _userProfile!.data['notificationsEnabled']
              );
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
      _showErrorSnackBar('Error uploading image. Please try again.');
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
      _showErrorSnackBar('Error uploading image. Please try again.');
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
      );
      
      // Reload profile data
      _userProfile = await _profileService.getUserProfile(_currentUser!.$id);
      
      setState(() => _isEditing = false);
      _showSuccessSnackBar('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      _showErrorSnackBar('Error updating profile. Please try again.');
    } finally {
      setState(() => _isSaving = false);
    }
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

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          profileId: _userProfile?.$id,
          userId: _currentUser?.$id,
        ),
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    
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
            : RefreshIndicator(
                color: primaryColor,
                onRefresh: _loadUserData,
                child: _buildProfileContent(screenSize, isSmallScreen),
              ),
      ),
    );
  }
  
  Widget _buildProfileContent(Size screenSize, bool isSmallScreen) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Fixed header with back button
          _buildFixedHeader(screenSize, isSmallScreen),
          
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width < 360 ? 12.0 : 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Personal Information section
                _buildSectionHeader('Personal Information', Icons.person_outline),
                const SizedBox(height: 12),
                _buildProfileForm(screenSize, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Account Statistics section
                _buildSectionHeader('Account Statistics', Icons.bar_chart_outlined),
                const SizedBox(height: 12),
                _buildStatisticsSection(screenSize, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Action buttons
                _buildActionButtons(screenSize, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 20 : 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFixedHeader(Size screenSize, bool isSmallScreen) {
    final headerHeight = isSmallScreen ? 280.0 : 320.0;
    final avatarRadius = isSmallScreen ? 40.0 : 50.0;
    
    return Container(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Gradient background
          Container(
            height: headerHeight - 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
            ),
          ),
          
          // Pattern overlay
          Container(
            height: headerHeight - 30,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pattern8.png'),
                fit: BoxFit.cover,
                opacity: 0.2,
              ),
            ),
          ),
          
          // Bottom curve
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
            ),
          ),
          
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          
          // Action buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Row(
              children: [
                // Edit button
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isEditing ? Icons.check : Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      if (_isEditing) {
                        _updateProfile();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Settings button
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _navigateToSettings,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          
          // Profile content
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Profile avatar
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: avatarRadius + 3,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: accentColor.withOpacity(0.2),
                            backgroundImage: _profileImageUrl != null
                                ? CachedNetworkImageProvider(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: avatarRadius * 0.8,
                                    color: primaryColor,
                                  )
                                : null,
                          ),
                        ),
                        
                        // Loading indicator
                        if (_isSaving)
                          Container(
                            width: (avatarRadius + 3) * 2,
                            height: (avatarRadius + 3) * 2,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        
                        // Edit icon
                        if (_isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // User name
                Container(
                  width: screenSize.width - 40,
                  child: Text(
                    _currentUser?.name ?? 'Loading...',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // User email
                Container(
                  width: screenSize.width - 40,
                  child: Text(
                    _currentUser?.email ?? 'Loading...',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileForm(Size screenSize, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      child: Column(
        children: [
          // Name field
          _buildProfileField(
            controller: _nameController,
            labelText: 'Full Name',
            icon: Icons.person_outline,
            enabled: _isEditing,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 14),
          
          // Email field
          _buildProfileField(
            controller: _emailController,
            labelText: 'Email',
            icon: Icons.email_outlined,
            enabled: false,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 14),
          
          // Phone field
          _buildProfileField(
            controller: _phoneController,
            labelText: 'Phone',
            icon: Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            hintText: '+254712345678',
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 14),
          
          // Occupation field
          _buildProfileField(
            controller: _occupationController,
            labelText: 'Occupation',
            icon: Icons.work_outline,
            enabled: _isEditing,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 14),
          
          // Location field
          _buildProfileField(
            controller: _locationController,
            labelText: 'Location',
            icon: FontAwesomeIcons.locationDot,
            enabled: _isEditing,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? hintText,
    required bool isSmallScreen,
  }) {
    return Container(
      height: isSmallScreen ? 48 : 52,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
          fontSize: isSmallScreen ? 13 : 14,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 12 : 13,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: isSmallScreen ? 12 : 13,
          ),
          prefixIcon: Container(
            width: 40,
            child: Icon(
              icon,
              color: enabled ? primaryColor : Colors.grey[400],
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          filled: true,
          fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isSmallScreen ? 12 : 14,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryColor,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatisticsSection(Size screenSize, bool isSmallScreen) {
    final cardHeight = isSmallScreen ? 80.0 : 95.0;
    final cardWidth = screenSize.width < 360 ? 120.0 : 140.0;
    
    return Container(
      height: cardHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatCard(
            title: 'Budget Goals',
            value: '3',
            icon: FontAwesomeIcons.bullseye,
            color: const Color(0xFF5E72E4),
            cardHeight: cardHeight,
            cardWidth: cardWidth,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Transactions',
            value: '42',
            icon: FontAwesomeIcons.moneyBillTransfer,
            color: const Color(0xFFFAB027),
            cardHeight: cardHeight,
            cardWidth: cardWidth,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Savings',
            value: '2',
            icon: FontAwesomeIcons.piggyBank,
            color: const Color(0xFF11CDEF),
            cardHeight: cardHeight,
            cardWidth: cardWidth,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double cardHeight,
    required double cardWidth,
    required bool isSmallScreen,
  }) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 2 : 3),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(Size screenSize, bool isSmallScreen) {
    return Column(
      children: [
        // Change Password Button
        _buildActionButton(
          title: 'Change Password',
          icon: Icons.lock_outline,
          color: const Color(0xFFFB6340),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  profileId: _userProfile?.$id,
                  userId: _currentUser?.$id,
                  initialTab: 2,
                ),
              ),
            );
          },
          isSmallScreen: isSmallScreen,
        ),
        
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Logout Button
        _buildActionButton(
          title: 'Sign Out',
          icon: Icons.logout,
          color: Colors.red.shade700,
          onTap: _confirmLogout,
          isOutlined: true,
          isSmallScreen: isSmallScreen,
        ),
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // App Version
        Center(
          child: Text(
            'DailyDime v${AppConfig.appVersion}',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: isSmallScreen ? 48 : 52,
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
          borderRadius: BorderRadius.circular(14),
          border: isOutlined 
              ? Border.all(color: color, width: 1.5) 
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined ? color : Colors.white,
              size: isSmallScreen ? 16 : 18,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: isOutlined ? color : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}