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
import 'package:dailydime/services/theme_service.dart';
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
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late final ProfileService _profileService;
  final _settingsStorage = SettingsStorage();
  
  // Animation controller
  late AnimationController _animationController;
  
  // User data
  models.User? _currentUser;
  models.Document? _userProfile;
  String? _profileImageUrl;
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _imageError = false;
  
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
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
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
            
            // Store preferences in local storage
            if (_userProfile!.data.containsKey('notificationsEnabled')) {
              await _settingsStorage.setNotificationsEnabled(
                _userProfile!.data['notificationsEnabled']
              );
            }
            
            // Get profile image URL if available
            if (_userProfile!.data.containsKey('profileImageId') && 
                _userProfile!.data['profileImageId'] != null) {
              try {
                _profileImageUrl = await _profileService.getProfileImageUrl(
                  _userProfile!.data['profileImageId']
                );
                _imageError = false;
              } catch (e) {
                print('Error loading profile image: $e');
                _imageError = true;
              }
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
      _animationController.forward();
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
        _imageError = false;
        
        _showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      print('Error uploading image: $e');
      _showErrorSnackBar('Error uploading image. Please try again.');
      _imageError = true;
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
        _imageError = false;
        
        _showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      print('Error uploading image: $e');
      _showErrorSnackBar('Error uploading image. Please try again.');
      _imageError = true;
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
    final isDarkMode = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[800],
                ),
              ),
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
              child: const Text('Sign Out'),
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
    final isDarkMode = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final primaryColor = isDarkMode ? const Color(0xFF26D07C) : const Color(0xFF26D07C);
    
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
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    
    // Theme colors
    final primaryColor = const Color(0xFF26D07C); // Emerald
    final secondaryColor = const Color(0xFF0AB3B8); // Teal
    final accentColor = const Color(0xFF68EFC6); // Light emerald
    final backgroundColor = isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8F9FA);
    final cardColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];
    final subtextColor = isDarkMode ? Colors.white70 : Colors.grey[600];
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: _isLoading
            ? Center(
                child: Lottie.asset(
                  isDarkMode 
                      ? 'assets/animations/loading_dark.json'
                      : 'assets/animations/loading.json',
                  width: 120,
                  height: 120,
                ),
              )
            : RefreshIndicator(
                color: primaryColor,
                backgroundColor: cardColor,
                onRefresh: _loadUserData,
                child: _buildProfileContent(
                  screenSize: screenSize, 
                  isSmallScreen: isSmallScreen,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  accentColor: accentColor,
                  backgroundColor: backgroundColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
      ),
    );
  }
  
  Widget _buildProfileContent({
    required Size screenSize,
    required bool isSmallScreen,
    required bool isDarkMode,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required Color backgroundColor,
    required Color cardColor,
    required Color? textColor,
    required Color? subtextColor,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header with profile info
          _buildProfileHeader(
            screenSize: screenSize,
            isSmallScreen: isSmallScreen,
            isDarkMode: isDarkMode,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            accentColor: accentColor,
            backgroundColor: backgroundColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width < 360 ? 16.0 : 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Profile information section
                _buildSectionHeader(
                  title: 'Personal Information',
                  icon: FontAwesomeIcons.userGear,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                _buildProfileForm(
                  screenSize: screenSize, 
                  isSmallScreen: isSmallScreen,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Account Statistics section
                _buildSectionHeader(
                  title: 'Account Statistics',
                  icon: FontAwesomeIcons.chartSimple,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                _buildStatisticsSection(
                  screenSize: screenSize, 
                  isSmallScreen: isSmallScreen,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Account Actions section
                _buildSectionHeader(
                  title: 'Account Actions',
                  icon: FontAwesomeIcons.gear,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                _buildActionButtons(
                  screenSize: screenSize, 
                  isSmallScreen: isSmallScreen,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                ),
                
                SizedBox(height: isSmallScreen ? 20 : 40),
                
                // App Version
                Center(
                  child: Text(
                    'DailyDime v${AppConfig.appVersion}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: subtextColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    ).animate(controller: _animationController).fadeIn(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
Widget _buildProfileHeader({
  required Size screenSize,
  required bool isSmallScreen,
  required bool isDarkMode,
  required Color primaryColor,
  required Color secondaryColor,
  required Color accentColor,
  required Color backgroundColor,
  required Color? textColor,
  required Color? subtextColor,
}) {
  final double avatarSize = isSmallScreen ? 90.0 : 110.0;
  
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0AB3B8), // Teal
          const Color(0xFF26D07C), // Emerald
        ],
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF26D07C).withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/pattern10.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _buildIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onPressed: () => Navigator.of(context).pop(),
                    isDarkMode: true, // Force white icons on gradient
                    primaryColor: Colors.white,
                  ),
                  
                  // Title
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Settings button
                  _buildIconButton(
                    icon: Icons.settings_outlined,
                    onPressed: _navigateToSettings,
                    isDarkMode: true, // Force white icons on gradient
                    primaryColor: Colors.white,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Profile picture with edit capability
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Profile image
                  Container(
                    height: avatarSize,
                    width: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(avatarSize / 2),
                        child: _buildProfileImage(avatarSize),
                      ),
                    ),
                  ),
                  
                  // Loading indicator
                  if (_isSaving)
                    Container(
                      width: avatarSize,
                      height: avatarSize,
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
                  
                  // Edit button
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User name
            Text(
              _currentUser?.name ?? 'User',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            // User email
            Text(
              _currentUser?.email ?? 'email@example.com',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Edit/Save Profile button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () {
                  if (_isEditing) {
                    _updateProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                                color: primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? 'Save Profile' : 'Edit Profile',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
  
  Widget _buildProfileImage(double size) {
    // If there's a web image that's been selected but not yet uploaded
    if (_webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }
    
    // If there's a mobile image that's been selected but not yet uploaded
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }
    
    // If there's a profile image URL and no error loading it
    if (_profileImageUrl != null && !_imageError) {
      return CachedNetworkImage(
        imageUrl: _profileImageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: size,
            height: size,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) {
          // Set image error flag if there's an error loading the image
          if (!_imageError) {
            setState(() => _imageError = true);
          }
          return Icon(
            Icons.person,
            size: size * 0.6,
            color: Colors.white,
          );
        },
      );
    }
    
    // Default placeholder
    return Icon(
      Icons.person,
      size: size * 0.6,
      color: Colors.white,
    );
  }
  
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
    required Color primaryColor,
  }) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey[800]!.withOpacity(0.3) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDarkMode ? Colors.white : Colors.grey[800],
          size: 18,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
  
  Widget _buildEditButton({
    required bool isDarkMode,
    required Color primaryColor,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: () {
        if (_isEditing) {
          _updateProfile();
        } else {
          setState(() => _isEditing = true);
        }
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, const Color(0xFF0AB3B8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'Save Profile' : 'Edit Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required Color primaryColor,
    required Color? textColor,
  }) {
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
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
      delay: const Duration(milliseconds: 100),
    );
  }
  
  Widget _buildProfileForm({
    required Size screenSize,
    required bool isSmallScreen,
    required bool isDarkMode,
    required Color primaryColor,
    required Color cardColor,
    required Color? textColor,
    required Color? subtextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Name field
            _buildProfileField(
              controller: _nameController,
              labelText: 'Full Name',
              icon: FontAwesomeIcons.user,
              enabled: _isEditing,
              isSmallScreen: isSmallScreen,
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            
            const SizedBox(height: 16),
            
            // Email field
            _buildProfileField(
              controller: _emailController,
              labelText: 'Email',
              icon: FontAwesomeIcons.envelope,
              enabled: false,
              isSmallScreen: isSmallScreen,
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            
            const SizedBox(height: 16),
            
            // Phone field
            _buildProfileField(
              controller: _phoneController,
              labelText: 'Phone Number',
              icon: FontAwesomeIcons.phone,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              hintText: '+254712345678',
              isSmallScreen: isSmallScreen,
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            
            const SizedBox(height: 16),
            
            // Occupation field
            _buildProfileField(
              controller: _occupationController,
              labelText: 'Occupation',
              icon: FontAwesomeIcons.briefcase,
              enabled: _isEditing,
              isSmallScreen: isSmallScreen,
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            
            const SizedBox(height: 16),
            
            // Location field
            _buildProfileField(
              controller: _locationController,
              labelText: 'Location',
              icon: FontAwesomeIcons.locationDot,
              enabled: _isEditing,
              isSmallScreen: isSmallScreen,
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
      delay: const Duration(milliseconds: 200),
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
    required bool isDarkMode,
    required Color primaryColor,
    required Color? textColor,
    required Color? subtextColor,
  }) {
    final fieldColor = isDarkMode
        ? enabled ? const Color(0xFF2D3748) : const Color(0xFF1E293B)
        : enabled ? Colors.grey[50] : Colors.grey[100];
    
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled 
              ? isDarkMode ? Colors.grey[700]! : Colors.grey[200]!
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(
            color: subtextColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 6),
            width: 40,
            child: Icon(
              icon,
              color: enabled ? primaryColor : subtextColor,
              size: 16,
            ),
          ),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }
  
  Widget _buildStatisticsSection({
    required Size screenSize,
    required bool isSmallScreen,
    required bool isDarkMode,
    required Color cardColor,
    required Color? textColor,
    required Color? subtextColor,
  }) {
    return Container(
      height: isSmallScreen ? 120 : 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatCard(
            title: 'Budget Goals',
            value: '3',
            icon: FontAwesomeIcons.bullseye,
            color: const Color(0xFF5E72E4),
            isSmallScreen: isSmallScreen,
            isDarkMode: isDarkMode,
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
            delay: 300,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: 'Transactions',
            value: '42',
            icon: FontAwesomeIcons.moneyBillTransfer,
            color: const Color(0xFFFAB027),
            isSmallScreen: isSmallScreen,
            isDarkMode: isDarkMode,
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
            delay: 400,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: 'Savings',
            value: '2',
            icon: FontAwesomeIcons.piggyBank,
            color: const Color(0xFF11CDEF),
            isSmallScreen: isSmallScreen,
            isDarkMode: isDarkMode,
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
            delay: 500,
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
    required bool isSmallScreen,
    required bool isDarkMode,
    required Color cardColor,
    required Color? textColor,
    required Color? subtextColor,
    required int delay,
  }) {
    return Container(
      width: isSmallScreen ? 120 : 140,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: subtextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: delay),
    ).slideX(
      begin: 0.2,
      end: 0,
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: delay),
      curve: Curves.easeOutQuad,
    );
  }
  
  Widget _buildActionButtons({
    required Size screenSize,
    required bool isSmallScreen,
    required bool isDarkMode,
    required Color primaryColor,
  }) {
    return Column(
      children: [
        // Theme Toggle
        _buildActionButton(
          title: 'Dark Mode',
          icon: isDarkMode ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
          color: const Color(0xFF5E72E4),
          onTap: () {
            final themeService = Provider.of<ThemeService>(context, listen: false);
            themeService.toggleTheme();
          },
          isToggle: true,
          isToggled: isDarkMode,
          isSmallScreen: isSmallScreen,
          isDarkMode: isDarkMode,
          delay: 300,
        ),
        
        const SizedBox(height: 16),
        
        // Change Password Button
        _buildActionButton(
          title: 'Change Password',
          icon: FontAwesomeIcons.lock,
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
          isDarkMode: isDarkMode,
          delay: 400,
        ),
        
        const SizedBox(height: 16),
        
        // Logout Button
        _buildActionButton(
          title: 'Sign Out',
          icon: FontAwesomeIcons.rightFromBracket,
          color: Colors.red.shade700,
          onTap: _confirmLogout,
          isOutlined: true,
          isSmallScreen: isSmallScreen,
          isDarkMode: isDarkMode,
          delay: 500,
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
    bool isToggle = false,
    bool isToggled = false,
    required bool isSmallScreen,
    required bool isDarkMode,
    required int delay,
  }) {
    final cardColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : cardColor,
          gradient: isOutlined 
              ? null 
              : isToggle 
                  ? null 
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
          borderRadius: BorderRadius.circular(16),
          border: isOutlined 
              ? Border.all(color: color, width: 1.5) 
              : isToggle
                  ? Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    )
                  : null,
          boxShadow: isOutlined || isToggle
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side with icon and title
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOutlined 
                          ? color.withOpacity(0.1) 
                          : isToggle
                              ? color.withOpacity(0.1)
                              : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isOutlined 
                          ? color 
                          : isToggle
                              ? color
                              : Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: isOutlined 
                          ? color 
                          : isToggle
                              ? isDarkMode ? Colors.white : Colors.grey[800]
                              : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              
              // Right side with toggle or arrow
              if (isToggle)
                Switch(
                  value: isToggled,
                  onChanged: (_) => onTap(),
                  activeColor: color,
                  activeTrackColor: color.withOpacity(0.3),
                )
              else if (!isOutlined)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withOpacity(0.7),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: delay),
    ).slideY(
      begin: 0.2,
      end: 0,
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: delay),
      curve: Curves.easeOutQuad,
    );
  }
}