// lib/screens/settings_screen.dart
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/services/profile_service.dart';
import 'package:dailydime/utils/settings_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class SettingsScreen extends StatefulWidget {
  final String? profileId;
  final String? userId;
  final int initialTab;

  const SettingsScreen({
    Key? key, 
    this.profileId, 
    this.userId,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  // Services
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _settingsStorage = SettingsStorage();
  
  // Tab controller
  late TabController _tabController;
  
  // Theme colors
  final Color primaryColor = const Color(0xFF26D07C); // Emerald
  final Color secondaryColor = const Color(0xFF0AB3B8); // Teal
  final Color accentColor = const Color(0xFF68EFC6); // Light emerald
  final Color backgroundColor = const Color(0xFFF8F9FA);
  
  // Settings state
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricsEnabled = false;
  bool _savingSettings = false;
  bool _isLoading = true;
  
  // Password controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, 
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadSettings();
    
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
    _tabController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Load settings from local storage first (for immediate display)
      final notificationsEnabled = await _settingsStorage.getNotificationsEnabled();
      final darkModeEnabled = await _settingsStorage.getDarkModeEnabled();
      final biometricsEnabled = await _settingsStorage.getBiometricsEnabled();
      
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _darkModeEnabled = darkModeEnabled;
        _biometricsEnabled = biometricsEnabled;
      });
      
      // If we have a profile ID, fetch the latest settings from Appwrite
      if (widget.profileId != null) {
        final profile = await _profileService.getProfileById(widget.profileId!);
        
        if (profile != null) {
          // Update local state with server values
          setState(() {
            if (profile.data.containsKey('notificationsEnabled')) {
              _notificationsEnabled = profile.data['notificationsEnabled'];
            }
            
            if (profile.data.containsKey('darkModeEnabled')) {
              _darkModeEnabled = profile.data['darkModeEnabled'];
            }
            
            if (profile.data.containsKey('biometricsEnabled')) {
              _biometricsEnabled = profile.data['biometricsEnabled'];
            }
          });
          
          // Update local storage with server values
          await _settingsStorage.setNotificationsEnabled(_notificationsEnabled);
          await _settingsStorage.setDarkModeEnabled(_darkModeEnabled);
          await _settingsStorage.setBiometricsEnabled(_biometricsEnabled);
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
      _showErrorSnackBar('Failed to load settings. Using cached values.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _toggleNotificationPreference(bool value) async {
    await _updatePreference('notificationsEnabled', value);
  }
  
  Future<void> _toggleDarkModePreference(bool value) async {
    await _updatePreference('darkModeEnabled', value);
  }
  
  Future<void> _toggleBiometricsPreference(bool value) async {
    await _updatePreference('biometricsEnabled', value);
  }
  
  Future<void> _updatePreference(String key, bool value) async {
    // Set saving state
    setState(() {
      if (key == 'notificationsEnabled') _notificationsEnabled = value;
      if (key == 'darkModeEnabled') _darkModeEnabled = value;
      if (key == 'biometricsEnabled') _biometricsEnabled = value;
      _savingSettings = true;
    });
    
    try {
      // Always update local storage first (for immediate feedback)
      if (key == 'notificationsEnabled') await _settingsStorage.setNotificationsEnabled(value);
      if (key == 'darkModeEnabled') await _settingsStorage.setDarkModeEnabled(value);
      if (key == 'biometricsEnabled') await _settingsStorage.setBiometricsEnabled(value);
      
      // If we have a profile ID, update Appwrite too
      if (widget.profileId != null) {
        await _profileService.updateUserPreference(
          profileId: widget.profileId!,
          key: key,
          value: value, preferenceKey: '', preferenceValue: null,
        );
      }
    } catch (e) {
      print('Error updating preference: $e');
      
      // Revert the change in UI
      setState(() {
        if (key == 'notificationsEnabled') _notificationsEnabled = !value;
        if (key == 'darkModeEnabled') _darkModeEnabled = !value;
        if (key == 'biometricsEnabled') _biometricsEnabled = !value;
      });
      
      // Revert local storage
      if (key == 'notificationsEnabled') await _settingsStorage.setNotificationsEnabled(!value);
      if (key == 'darkModeEnabled') await _settingsStorage.setDarkModeEnabled(!value);
      if (key == 'biometricsEnabled') await _settingsStorage.setBiometricsEnabled(!value);
      
      _showErrorSnackBar('Failed to update preference. Please try again.');
    } finally {
      setState(() => _savingSettings = false);
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
    
    setState(() => _savingSettings = true);
    
    try {
      await _authService.updatePassword(
        password: _newPasswordController.text,
        oldPassword: _currentPasswordController.text,
      );
      
      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      _showSuccessSnackBar('Password changed successfully');
    } catch (e) {
      print('Error changing password: $e');
      _showErrorSnackBar(_authService.handleAuthError(e));
    } finally {
      setState(() => _savingSettings = false);
    }
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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
                width: 120,
                height: 120,
              ),
            )
          : SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      pinned: true,
                      floating: true,
                      title: Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: Colors.grey[800],
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: primaryColor,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: 'Appearance'),
                          Tab(text: 'Notifications'),
                          Tab(text: 'Security'),
                          Tab(text: 'About'),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Appearance Tab
                    _buildAppearanceTab(),
                    
                    // Notifications Tab
                    _buildNotificationsTab(),
                    
                    // Security Tab
                    _buildSecurityTab(),
                    
                    // About Tab
                    _buildAboutTab(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildAppearanceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
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
              _showComingSoonDialog('Theme Customization');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Text Size',
            subtitle: 'Change the text size throughout the app',
            icon: Icons.text_fields,
            iconColor: const Color(0xFF11CDEF),
            onTap: () {
              // Navigate to text size settings
              _showComingSoonDialog('Text Size Settings');
            },
          ),
        ]).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Display'),
        const SizedBox(height: 16),
        
        _buildSettingsCard([
          _buildSettingsItem(
            title: 'Currency Format',
            subtitle: 'Select your preferred currency format',
            icon: FontAwesomeIcons.moneyBill,
            iconColor: const Color(0xFF2DCE89),
            onTap: () {
              // Navigate to currency format settings
              _showComingSoonDialog('Currency Format Settings');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Date Format',
            subtitle: 'Choose how dates are displayed',
            icon: Icons.calendar_today,
            iconColor: const Color(0xFFFF9500),
            onTap: () {
              // Navigate to date format settings
              _showComingSoonDialog('Date Format Settings');
            },
          ),
        ]).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
      ],
    );
  }
  
  Widget _buildNotificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSettingsCard([
          _buildSettingsToggle(
            title: 'Push Notifications',
            subtitle: 'Get notified about important updates',
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFFFF9500),
            value: _notificationsEnabled,
            onChanged: _toggleNotificationPreference,
          ),
        ]).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Alert Types'),
        const SizedBox(height: 16),
        
        _buildSettingsCard([
          _buildSettingsItem(
            title: 'Budget Alerts',
            subtitle: 'Get notified when you approach budget limits',
            icon: FontAwesomeIcons.bell,
            iconColor: const Color(0xFF11CDEF),
            onTap: () {
              // Navigate to budget alert settings
              _showComingSoonDialog('Budget Alert Settings');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Bill Reminders',
            subtitle: 'Receive reminders for upcoming bills',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            iconColor: const Color(0xFFFB6340),
            onTap: () {
              // Navigate to bill reminder settings
              _showComingSoonDialog('Bill Reminder Settings');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Savings Goals',
            subtitle: 'Get updates on your savings progress',
            icon: FontAwesomeIcons.piggyBank,
            iconColor: const Color(0xFF2DCE89),
            onTap: () {
              // Navigate to savings goal notification settings
              _showComingSoonDialog('Savings Goal Notifications');
            },
          ),
        ]).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Notification Schedule'),
        const SizedBox(height: 16),
        
        _buildSettingsCard([
          _buildSettingsItem(
            title: 'Quiet Hours',
            subtitle: 'Set times when notifications are silenced',
            icon: Icons.nightlight_outlined,
            iconColor: const Color(0xFF5E72E4),
            onTap: () {
              // Navigate to quiet hours settings
              _showComingSoonDialog('Quiet Hours Settings');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Weekly Summary',
            subtitle: 'Get a summary of your finances each week',
            icon: Icons.summarize_outlined,
            iconColor: const Color(0xFF007AFF),
            onTap: () {
              // Navigate to weekly summary settings
              _showComingSoonDialog('Weekly Summary Settings');
            },
          ),
        ]).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
      ],
    );
  }
  
  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSettingsCard([
          _buildSettingsToggle(
            title: 'Biometric Authentication',
            subtitle: 'Use fingerprint or face ID to login',
            icon: Icons.fingerprint,
            iconColor: primaryColor,
            value: _biometricsEnabled,
            onChanged: _toggleBiometricsPreference,
          ),
        ]).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Password'),
        const SizedBox(height: 16),
        
        _buildPasswordChangeCard().animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Privacy'),
        const SizedBox(height: 16),
        
        _buildSettingsCard([
          _buildSettingsItem(
            title: 'Data & Privacy',
            subtitle: 'Manage your personal data and privacy settings',
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF007AFF),
            onTap: () {
              // Navigate to privacy settings
              _showComingSoonDialog('Privacy Settings');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Export Data',
            subtitle: 'Export your financial data in various formats',
            icon: Icons.download_outlined,
            iconColor: const Color(0xFF34C759),
            onTap: () {
              // Navigate to data export
              _showComingSoonDialog('Data Export');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            icon: Icons.delete_forever_outlined,
            iconColor: Colors.red.shade700,
            onTap: () {
              // Show delete account confirmation
              _showDeleteAccountDialog();
            },
          ),
        ]).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
      ],
    );
  }
  
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // App logo and version
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              Text(
                'DailyDime',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${AppConfig.appVersion}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms),
        
        _buildSettingsCard([
          _buildSettingsItem(
            title: 'About DailyDime',
            subtitle: 'Learn more about the app',
            icon: Icons.info_outline,
            iconColor: const Color(0xFF007AFF),
            onTap: () {
              // Show about dialog
              _showAboutDialog();
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Rate the App',
            subtitle: 'If you enjoy using DailyDime, please rate it!',
            icon: Icons.star_outline,
            iconColor: const Color(0xFFFFCC00),
            onTap: () {
              // Open app store rating
              _showComingSoonDialog('App Rating');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Share with Friends',
            subtitle: 'Invite your friends to use DailyDime',
            icon: Icons.share_outlined,
            iconColor: const Color(0xFF34C759),
            onTap: () {
              // Share app link
              _showComingSoonDialog('Share App');
            },
          ),
        ]).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Legal'),
        const SizedBox(height: 16),
        
        _buildSettingsCard([
          _buildSettingsItem(
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF8E8E93),
            onTap: () {
              // Navigate to terms screen
              _showComingSoonDialog('Terms of Service');
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
              _showComingSoonDialog('Privacy Policy');
            },
          ),
          _buildSettingsDivider(),
          _buildSettingsItem(
            title: 'Licenses',
            subtitle: 'Open-source licenses and acknowledgements',
            icon: Icons.workspace_premium_outlined,
            iconColor: const Color(0xFF8E8E93),
            onTap: () {
              // Show licenses
              showLicensePage(
                context: context,
                applicationName: 'DailyDime',
                applicationVersion: AppConfig.appVersion,
                applicationIcon: Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                  width: 50,
                ),
              );
            },
          ),
        ]).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
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
              _showComingSoonDialog('Help Center');
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
              _showComingSoonDialog('Contact Support');
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
              _showComingSoonDialog('Bug Report');
            },
          ),
        ]).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 40),
        
        // Copyright
        Center(
          child: Text(
            '© ${DateTime.now().year} DailyDime. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        
        const SizedBox(height: 30),
      ],
    );
  }
  
  Widget _buildPasswordChangeCard() {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _savingSettings ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _savingSettings
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Update Password'),
            ),
          ),
        ],
      ),
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
            Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
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
            onChanged: _savingSettings ? null : onChanged,
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
  
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/coming_soon.json',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 16),
            Text(
              '$feature will be available in a future update!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 16),
            const Text('About DailyDime'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DailyDime is a personal finance app designed to help you manage your budget, track expenses, and save money more effectively.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Our mission is to make financial management simple, intuitive, and accessible for everyone.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Made with love in Kenya',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red[700],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'This action is permanent and cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Are you absolutely sure you want to delete your account?',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonDialog('Account Deletion');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Delete Account'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}