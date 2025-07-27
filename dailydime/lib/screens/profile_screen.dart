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
                child: _buildProfileContent(screenSize),
              ),
      ),
    );
  }
  
  Widget _buildProfileContent(Size screenSize) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Modern floating profile header
        SliverPersistentHeader(
          delegate: _ProfileHeaderDelegate(
            expandedHeight: 300,
            profileImageUrl: _profileImageUrl,
            userName: _currentUser?.name ?? 'Loading...',
            userEmail: _currentUser?.email ?? 'Loading...',
            isEditing: _isEditing,
            isSaving: _isSaving,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            accentColor: accentColor,
            onEditPressed: () {
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
            onSettingsPressed: _navigateToSettings,
            onImageTap: _isEditing ? _pickImage : null,
          ),
          pinned: true,
        ),
        
        // Profile form content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
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
    return Container(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatCard(
            title: 'Budget Goals',
            value: '3',
            icon: FontAwesomeIcons.bullseye,
            color: const Color(0xFF5E72E4),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: 'Transactions',
            value: '42',
            icon: FontAwesomeIcons.moneyBillTransfer,
            color: const Color(0xFFFAB027),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: 'Savings',
            value: '2',
            icon: FontAwesomeIcons.piggyBank,
            color: const Color(0xFF11CDEF),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
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
          onTap: () {
            // Navigate to change password in settings
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  profileId: _userProfile?.$id,
                  userId: _currentUser?.$id,
                  initialTab: 2, // Navigate to Security tab
                ),
              ),
            );
          },
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
}

// Custom delegate for the profile header
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final String? profileImageUrl;
  final String userName;
  final String userEmail;
  final bool isEditing;
  final bool isSaving;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final VoidCallback onEditPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onImageTap;

  _ProfileHeaderDelegate({
    required this.expandedHeight,
    required this.profileImageUrl,
    required this.userName,
    required this.userEmail,
    required this.isEditing,
    required this.isSaving,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.onEditPressed,
    required this.onSettingsPressed,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = shrinkOffset / expandedHeight;
    final double opacity = 1 - progress * 1.5 < 0 ? 0 : 1 - progress * 1.5;
    
    return Container(
      height: expandedHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background with pattern
          AnimatedOpacity(
            opacity: 1.0 - progress,
            duration: const Duration(milliseconds: 100),
            child: Container(
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
          ),
          
          // Collapsed app bar content (shown when scrolled)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: progress,
            child: Container(
              color: Colors.white,
              child: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isEditing ? Icons.check : Icons.edit_outlined,
                      color: primaryColor,
                    ),
                    onPressed: onEditPressed,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.grey[700],
                    ),
                    onPressed: onSettingsPressed,
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom curve
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: opacity,
              child: Container(
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          
          // Expanded profile content
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Profile avatar
                  GestureDetector(
                    onTap: onImageTap,
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
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: accentColor.withOpacity(0.2),
                              backgroundImage: profileImageUrl != null
                                  ? CachedNetworkImageProvider(profileImageUrl!)
                                  : null,
                              child: profileImageUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: primaryColor,
                                    )
                                  : null,
                            ),
                          ),
                          
                          // Loading indicator
                          if (isSaving)
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
                          if (isEditing)
                            Positioned(
                              right: 0,
                              bottom: 5,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User name
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // User email
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // App bar actions
          Positioned(
            top: 50,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: opacity,
              child: Row(
                children: [
                  // Edit button
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      onPressed: onEditPressed,
                      tooltip: isEditing ? 'Save Changes' : 'Edit Profile',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Settings button
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      onPressed: onSettingsPressed,
                      tooltip: 'Settings',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 30;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}