// lib/screens/settings_screen.dart
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/utils/settings_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsStorage _settingsStorage = SettingsStorage();
  final _authService = AuthService();
  
  // Theme colors
  final Color primaryColor = const Color(0xFF26D07C); // Emerald
  final Color secondaryColor = const Color(0xFF0AB3B8); // Teal
  final Color backgroundColor = const Color(0xFFF8F9FA);
  
  // Settings state
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String _appVersion = '';
  String _appName = '';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      await _settingsStorage.init();
      
      setState(() {
        _darkModeEnabled = _settingsStorage.getDarkMode();
        _notificationsEnabled = _settingsStorage.getNotifications();
        _biometricsEnabled = _settingsStorage.getBiometrics();
      });
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appName = packageInfo.appName;
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      print('Error loading app info: $e');
      setState(() {
        _appName = 'DailyDime';
        _appVersion = AppConfig.appVersion;
      });
    }
  }
  
  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _isSaving = true;
      _darkModeEnabled = value;
    });
    
    try {
      await _settingsStorage.setDarkMode(value);
      await _syncSettingsWithServer();
    } catch (e) {
      print('Error saving dark mode setting: $e');
      setState(() => _darkModeEnabled = !value); // Revert if error
      _showErrorSnackBar('Failed to save setting');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isSaving = true;
      _notificationsEnabled = value;
    });
    
    try {
      await _settingsStorage.setNotifications(value);
      await _syncSettingsWithServer();
    } catch (e) {
      print('Error saving notifications setting: $e');
      setState(() => _notificationsEnabled = !value); // Revert if error
      _showErrorSnackBar('Failed to save setting');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _toggleBiometrics(bool value) async {
    setState(() {
      _isSaving = true;
      _biometricsEnabled = value;
    });
    
    try {
      await _settingsStorage.setBiometrics(value);
      await _syncSettingsWithServer();
    } catch (e) {
      print('Error saving biometrics setting: $e');
      setState(() => _biometricsEnabled = !value); // Revert if error
      _showErrorSnackBar('Failed to save setting');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _syncSettingsWithServer() async {
    // TODO: Implement sync with Appwrite server
    // This would typically update the user profile document with the settings
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network request
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
  
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar('Could not launch $url');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
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
            : _buildSettingsContent(),
      ),
    );
  }
  
  Widget _buildSettingsContent() {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          // Settings list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Appearance section
                _buildSectionHeader('Appearance'),
                const SizedBox(height: 10),
                
                _buildSettingsCard([
                  _buildSwitchTile(
                    title: 'Dark Mode',
                    subtitle: 'Enable dark theme throughout the app',
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF5E72E4),
                    value: _darkModeEnabled,
                    onChanged: _isSaving ? null : _toggleDarkMode,
                  ),
                  _buildSettingsTile(
                    title: 'App Theme',
                    subtitle: 'Customize app colors',
                    icon: Icons.color_lens_outlined,
                    iconColor: const Color(0xFFFB6340),
                    onTap: () {
                      // Navigate to theme settings
                      _showSuccessSnackBar('Theme customization coming soon!');
                    },
                  ),
                ]),
                
                const SizedBox(height: 20),
                
                // Notifications section
                _buildSectionHeader('Notifications'),
                const SizedBox(height: 10),
                
                _buildSettingsCard([
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Get important alerts and reminders',
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFFFF9500),
                    value: _notificationsEnabled,
                    onChanged: _isSaving ? null : _toggleNotifications,
                  ),
                  _buildSettingsTile(
                    title: 'Budget Alerts',
                    subtitle: 'Configure budget threshold notifications',
                    icon: Icons.money_off_outlined,
                    iconColor: const Color(0xFFFFD60A),
                    onTap: () {
                      // Navigate to budget alerts settings
                      _showSuccessSnackBar('Budget alerts configuration coming soon!');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Reminder Schedule',
                    subtitle: 'Set times for budget check reminders',
                    icon: Icons.schedule_outlined,
                    iconColor: const Color(0xFF11CDEF),
                    onTap: () {
                      // Navigate to reminder settings
                      _showSuccessSnackBar('Reminder settings coming soon!');
                    },
                  ),
                ]),
                
                const SizedBox(height: 20),
                
                // Security section
                _buildSectionHeader('Security'),
                const SizedBox(height: 10),
                
                _buildSettingsCard([
                  _buildSwitchTile(
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face ID to login',
                    icon: Icons.fingerprint,
                    iconColor: primaryColor,
                    value: _biometricsEnabled,
                    onChanged: _isSaving ? null : _toggleBiometrics,
                  ),
                  _buildSettingsTile(
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFFFF3B30),
                    onTap: () {
                      // Navigate back to profile to use the change password dialog
                      Navigator.of(context).pop();
                      _showSuccessSnackBar('Please use the Change Password button on your profile');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Privacy Settings',
                    subtitle: 'Manage your data and privacy',
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF007AFF),
                    onTap: () {
                      // Navigate to privacy settings
                      _showSuccessSnackBar('Privacy settings coming soon!');
                    },
                  ),
                ]),
                
                const SizedBox(height: 20),
                
                // Data & Sync section
                _buildSectionHeader('Data & Sync'),
                const SizedBox(height: 10),
                
                _buildSettingsCard([
                  _buildSettingsTile(
                    title: 'Export Data',
                    subtitle: 'Export your financial data as CSV or PDF',
                    icon: Icons.download_outlined,
                    iconColor: const Color(0xFF34C759),
                    onTap: () {
                      // Show export options
                      _showSuccessSnackBar('Data export feature coming soon!');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Backup & Restore',
                    subtitle: 'Backup your data to the cloud',
                    icon: Icons.cloud_upload_outlined,
                    iconColor: const Color(0xFF5856D6),
                    onTap: () {
                      // Navigate to backup settings
                      _showSuccessSnackBar('Backup feature coming soon!');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Sync Frequency',
                    subtitle: 'Choose how often data syncs to the cloud',
                    icon: Icons.sync_outlined,
                    iconColor: const Color(0xFF5AC8FA),
                    onTap: () {
                      // Navigate to sync settings
                      _showSuccessSnackBar('Sync settings coming soon!');
                    },
                  ),
                ]),
                
                const SizedBox(height: 20),
                
                // Support section
                _buildSectionHeader('Support & Feedback'),
                const SizedBox(height: 10),
                
                _buildSettingsCard([
                  _buildSettingsTile(
                    title: 'Help Center',
                    subtitle: 'Get help with using the app',
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFF34C759),
                    onTap: () {
                      _launchURL('https://example.com/help');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Contact Support',
                    subtitle: 'Email our support team',
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFF5856D6),
                    onTap: () {
                      _launchURL('mailto:support@dailydime.app');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Report a Bug',
                    subtitle: 'Help us improve the app',
                    icon: Icons.bug_report_outlined,
                    iconColor: const Color(0xFFFF2D55),
                    onTap: () {
                      _launchURL('https://example.com/bug-report');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Rate the App',
                    subtitle: 'Leave a review on the app store',
                    icon: Icons.star_outline,
                    iconColor: const Color(0xFFFFCC00),
                    onTap: () {
                      _launchURL('https://example.com/rate');
                    },
                  ),
                ]),
                
                const SizedBox(height: 20),
                
                // About section
                _buildSectionHeader('About'),
                const SizedBox(height: 10),
                
                _buildSettingsCard([
                  _buildSettingsTile(
                    title: 'About $_appName',
                    subtitle: 'Learn more about the app',
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF007AFF),
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Terms of Service',
                    subtitle: 'Read our terms and conditions',
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF8E8E93),
                    onTap: () {
                      _launchURL('https://example.com/terms');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF8E8E93),
                    onTap: () {
                      _launchURL('https://example.com/privacy');
                    },
                  ),
                  _buildSettingsTile(
                    title: 'Third-Party Licenses',
                    subtitle: 'View licenses for libraries we use',
                    icon: Icons.policy_outlined,
                    iconColor: const Color(0xFF8E8E93),
                    onTap: () {
                      // Show licenses page
                      showLicensePage(
                        context: context,
                        applicationName: _appName,
                        applicationVersion: _appVersion,
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 50,
                            height: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ]),
                
                // App version
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Center(
                    child: Text(
                      '$_appName v$_appVersion',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(
      begin: -0.1,
      end: 0,
      curve: Curves.easeOutQuad,
      duration: 500.ms,
    );
  }
  
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
  
  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
                      fontSize: 15,
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
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
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
                    fontSize: 15,
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
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
            activeTrackColor: primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                'assets/images/app_icon.png',
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 10),
              Text(_appName),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: $_appVersion'),
              const SizedBox(height: 10),
              const Text(
                'DailyDime is a personal finance app designed to help you track your expenses, '
                'set budgets, and achieve your financial goals.',
              ),
              const SizedBox(height: 10),
              const Text('Developed with ❤️ using Flutter.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}