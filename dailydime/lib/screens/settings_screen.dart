// lib/screens/settings_screen.dart
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/services/profile_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/utils/settings_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Settings state
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  bool _budgetAlertsEnabled = true;
  bool _billRemindersEnabled = true;
  bool _savingsGoalAlertsEnabled = true;
  bool _savingSettings = false;
  bool _isLoading = true;
  
  // UI Settings
  double _textScale = 1.0;
  String _selectedCurrency = 'KES';
  String _dateFormat = 'dd/MM/yyyy';
  
  // Custom colors
  Color _primaryColor = const Color(0xFF26D07C);
  Color _secondaryColor = const Color(0xFF0AB3B8);
  
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
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
        _budgetAlertsEnabled = prefs.getBool('budget_alerts_enabled') ?? true;
        _billRemindersEnabled = prefs.getBool('bill_reminders_enabled') ?? true;
        _savingsGoalAlertsEnabled = prefs.getBool('savings_goal_alerts_enabled') ?? true;
        _textScale = prefs.getDouble('text_scale') ?? 1.0;
        _selectedCurrency = prefs.getString('selected_currency') ?? 'KES';
        _dateFormat = prefs.getString('date_format') ?? 'dd/MM/yyyy';
        
        // Load custom colors
        final primaryColorValue = prefs.getInt('primary_color');
        final secondaryColorValue = prefs.getInt('secondary_color');
        if (primaryColorValue != null) _primaryColor = Color(primaryColorValue);
        if (secondaryColorValue != null) _secondaryColor = Color(secondaryColorValue);
      });
      
    } catch (e) {
      print('Error loading settings: $e');
      _showErrorSnackBar('Failed to load settings. Using default values.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _updateBoolSetting(String key, bool value) async {
    setState(() => _savingSettings = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      
      setState(() {
        switch (key) {
          case 'notifications_enabled':
            _notificationsEnabled = value;
            break;
          case 'biometrics_enabled':
            _biometricsEnabled = value;
            break;
          case 'budget_alerts_enabled':
            _budgetAlertsEnabled = value;
            break;
          case 'bill_reminders_enabled':
            _billRemindersEnabled = value;
            break;
          case 'savings_goal_alerts_enabled':
            _savingsGoalAlertsEnabled = value;
            break;
        }
      });
      
      _showSuccessSnackBar('Setting updated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to update setting');
    } finally {
      setState(() => _savingSettings = false);
    }
  }
  
  Future<void> _updateTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale', scale);
    setState(() => _textScale = scale);
    _showSuccessSnackBar('Text size updated');
  }
  
  Future<void> _updateCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
    setState(() => _selectedCurrency = currency);
    _showSuccessSnackBar('Currency updated');
  }
  
  Future<void> _updateDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_format', format);
    setState(() => _dateFormat = format);
    _showSuccessSnackBar('Date format updated');
  }
  
  Future<void> _updateCustomColors(Color primary, Color secondary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', primary.value);
    await prefs.setInt('secondary_color', secondary.value);
    setState(() {
      _primaryColor = primary;
      _secondaryColor = secondary;
    });
    _showSuccessSnackBar('Colors updated');
  }
  
  Future<void> _changePassword() async {
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
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      _showSuccessSnackBar('Password changed successfully');
    } catch (e) {
      _showErrorSnackBar(_authService.handleAuthError(e));
    } finally {
      setState(() => _savingSettings = false);
    }
  }
  
  void _navigateToBudgetScreen() {
    Navigator.pushNamed(context, '/budget');
  }
  
  void _navigateToSavingsScreen() {
    Navigator.pushNamed(context, '/savings');
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: themeService.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
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
                          backgroundColor: themeService.surfaceColor,
                          elevation: 0,
                          pinned: true,
                          floating: true,
                          title: Text(
                            'Settings',
                            style: TextStyle(
                              color: themeService.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              color: themeService.textColor,
                              size: 28,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          bottom: TabBar(
                            controller: _tabController,
                            labelColor: themeService.primaryColor,
                            unselectedLabelColor: themeService.subtextColor,
                            indicatorColor: themeService.primaryColor,
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
                        _buildAppearanceTab(themeService),
                        _buildNotificationsTab(themeService),
                        _buildSecurityTab(themeService),
                        _buildAboutTab(themeService),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
  
  Widget _buildAppearanceTab(ThemeService themeService) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSettingsCard(themeService, [
          _buildSettingsToggle(
            themeService: themeService,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme throughout the app',
            icon: Icons.dark_mode_outlined,
            iconColor: const Color(0xFF5E72E4),
            value: themeService.isDarkMode,
            onChanged: (value) => themeService.setTheme(value),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsItem(
            themeService: themeService,
            title: 'App Theme Colors',
            subtitle: 'Customize your app colors',
            icon: Icons.color_lens_outlined,
            iconColor: const Color(0xFFFB6340),
            onTap: () => _showColorPicker(themeService),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsItem(
            themeService: themeService,
            title: 'Text Size',
            subtitle: 'Change the text size: ${(_textScale * 100).round()}%',
            icon: Icons.text_fields,
            iconColor: const Color(0xFF11CDEF),
            onTap: () => _showTextSizeDialog(themeService),
          ),
        ]).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Display', themeService),
        const SizedBox(height: 16),
        
        _buildSettingsCard(themeService, [
          _buildSettingsItem(
            themeService: themeService,
            title: 'Currency Format',
            subtitle: 'Current: $_selectedCurrency',
            icon: FontAwesomeIcons.moneyBill,
            iconColor: const Color(0xFF2DCE89),
            onTap: () => _showCurrencyPicker(themeService),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsItem(
            themeService: themeService,
            title: 'Date Format',
            subtitle: 'Current: $_dateFormat',
            icon: Icons.calendar_today,
            iconColor: const Color(0xFFFF9500),
            onTap: () => _showDateFormatPicker(themeService),
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
  
  Widget _buildNotificationsTab(ThemeService themeService) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSettingsCard(themeService, [
          _buildSettingsToggle(
            themeService: themeService,
            title: 'Push Notifications',
            subtitle: 'Get notified about important updates',
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFFFF9500),
            value: _notificationsEnabled,
            onChanged: (value) => _updateBoolSetting('notifications_enabled', value),
          ),
        ]).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Alert Types', themeService),
        const SizedBox(height: 16),
        
        _buildSettingsCard(themeService, [
          _buildSettingsToggle(
            themeService: themeService,
            title: 'Budget Alerts',
            subtitle: 'Get notified when you approach budget limits',
            icon: FontAwesomeIcons.bell,
            iconColor: const Color(0xFF11CDEF),
            value: _budgetAlertsEnabled,
            onChanged: (value) => _updateBoolSetting('budget_alerts_enabled', value),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsItem(
            themeService: themeService,
            title: 'View Budget Screen',
            subtitle: 'Manage your budgets and set limits',
            icon: FontAwesomeIcons.chartPie,
            iconColor: const Color(0xFF11CDEF),
            onTap: _navigateToBudgetScreen,
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsToggle(
            themeService: themeService,
            title: 'Bill Reminders',
            subtitle: 'Receive reminders for upcoming bills',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            iconColor: const Color(0xFFFB6340),
            value: _billRemindersEnabled,
            onChanged: (value) => _updateBoolSetting('bill_reminders_enabled', value),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsToggle(
            themeService: themeService,
            title: 'Savings Goals',
            subtitle: 'Get updates on your savings progress',
            icon: FontAwesomeIcons.piggyBank,
            iconColor: const Color(0xFF2DCE89),
            value: _savingsGoalAlertsEnabled,
            onChanged: (value) => _updateBoolSetting('savings_goal_alerts_enabled', value),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsItem(
            themeService: themeService,
            title: 'View Savings Screen',
            subtitle: 'Manage your savings goals and progress',
            icon: FontAwesomeIcons.piggyBank,
            iconColor: const Color(0xFF2DCE89),
            onTap: _navigateToSavingsScreen,
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
  
  Widget _buildSecurityTab(ThemeService themeService) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSettingsCard(themeService, [
          _buildSettingsToggle(
            themeService: themeService,
            title: 'Biometric Authentication',
            subtitle: 'Use fingerprint or face ID to login',
            icon: Icons.fingerprint,
            iconColor: themeService.primaryColor,
            value: _biometricsEnabled,
            onChanged: (value) => _updateBoolSetting('biometrics_enabled', value),
          ),
        ]).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Password', themeService),
        const SizedBox(height: 16),
        
        _buildPasswordChangeCard(themeService).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSectionHeader('Privacy', themeService),
        const SizedBox(height: 16),
        
        _buildSettingsCard(themeService, [
          _buildSettingsItem(
            themeService: themeService,
            title: 'Data Export',
            subtitle: 'Export your financial data',
            icon: Icons.download_outlined,
            iconColor: const Color(0xFF34C759),
            onTap: () => _exportData(themeService),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsItem(
            themeService: themeService,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            icon: Icons.delete_forever_outlined,
            iconColor: Colors.red.shade700,
            onTap: () => _showDeleteAccountDialog(themeService),
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
  
  Widget _buildAboutTab(ThemeService themeService) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
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
                  color: themeService.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${AppConfig.appVersion}',
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.subtextColor,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms),
        
        _buildSettingsCard(themeService, [
          _buildSettingsItem(
            themeService: themeService,
            title: 'About DailyDime',
            subtitle: 'Learn more about the app',
            icon: Icons.info_outline,
            iconColor: const Color(0xFF007AFF),
            onTap: () => _showAboutDialog(themeService),
          ),
          _buildSettingsDivider(themeService),
          _buildSettingsItem(
            themeService: themeService,
            title: 'Licenses',
            subtitle: 'Open-source licenses and acknowledgements',
            icon: Icons.workspace_premium_outlined,
            iconColor: const Color(0xFF8E8E93),
            onTap: () => _showLicenses(),
          ),
        ]).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: 500.ms,
        ),
        
        const SizedBox(height: 40),
        
        Center(
          child: Text(
            '© ${DateTime.now().year} DailyDime. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: themeService.subtextColor,
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        
        const SizedBox(height: 30),
      ],
    );
  }
  
  Widget _buildPasswordChangeCard(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            themeService: themeService,
            controller: _currentPasswordController,
            labelText: 'Current Password',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            themeService: themeService,
            controller: _newPasswordController,
            labelText: 'New Password',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            themeService: themeService,
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
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _savingSettings
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasswordField({
    required ThemeService themeService,
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: themeService.textColor),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: themeService.subtextColor),
        filled: true,
        fillColor: themeService.isDarkMode 
            ? const Color(0xFF2D3748)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: themeService.subtextColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
  
  Widget _buildSettingsSectionHeader(String title, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeService.textColor,
        ),
      ),
    );
  }
  
  Widget _buildSettingsCard(ThemeService themeService, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
  
  Widget _buildSettingsItem({
    required ThemeService themeService,
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
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeService.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: themeService.subtextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsToggle({
    required ThemeService themeService,
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
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeService.subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _savingSettings ? null : onChanged,
            activeColor: themeService.primaryColor,
            activeTrackColor: themeService.primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsDivider(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 0.5,
      color: themeService.subtextColor.withOpacity(0.2),
    );
  }

  // Dialog Methods
  void _showColorPicker(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('Choose Theme Colors', style: TextStyle(color: themeService.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Primary Color', style: TextStyle(color: themeService.textColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                const Color(0xFF26D07C),
                const Color(0xFF3B82F6),
                const Color(0xFF8B5CF6),
                const Color(0xFFEF4444),
                const Color(0xFFF59E0B),
                const Color(0xFF10B981),
              ].map((color) => GestureDetector(
                onTap: () => _updateCustomColors(color, _secondaryColor),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _primaryColor == color 
                        ? Border.all(color: themeService.textColor, width: 2)
                        : null,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: themeService.primaryColor)),
          ),
        ],
      ),
    );
  }
  
  void _showTextSizeDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('Text Size', style: TextStyle(color: themeService.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${(_textScale * 100).round()}%', 
                 style: TextStyle(color: themeService.textColor)),
            Slider(
              value: _textScale,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              activeColor: themeService.primaryColor,
              onChanged: (value) {
                setState(() => _textScale = value);
                _updateTextScale(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: themeService.primaryColor)),
          ),
        ],
      ),
    );
  }
  
  void _showCurrencyPicker(ThemeService themeService) {
    final currencies = ['KES', 'USD', 'EUR', 'GBP', 'UGX', 'TZS'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('Select Currency', style: TextStyle(color: themeService.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) => ListTile(
            title: Text(currency, style: TextStyle(color: themeService.textColor)),
            leading: Radio<String>(
              value: currency,
              groupValue: _selectedCurrency,
              activeColor: themeService.primaryColor,
              onChanged: (value) {
                _updateCurrency(value!);
                Navigator.pop(context);
              },
            ),
          )).toList(),
        ),
      ),
    );
  }
  
  void _showDateFormatPicker(ThemeService themeService) {
    final formats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('Date Format', style: TextStyle(color: themeService.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) => ListTile(
            title: Text(format, style: TextStyle(color: themeService.textColor)),
            leading: Radio<String>(
              value: format,
              groupValue: _dateFormat,
              activeColor: themeService.primaryColor,
              onChanged: (value) {
                _updateDateFormat(value!);
                Navigator.pop(context);
              },
            ),
          )).toList(),
        ),
      ),
    );
  }
  
  void _exportData(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('Export Data', style: TextStyle(color: themeService.textColor)),
        content: Text(
          'Your financial data will be exported to a CSV file and saved to your device.',
          style: TextStyle(color: themeService.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeService.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Data export started. Check your downloads.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: themeService.primaryColor),
            child: const Text('Export', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('Delete Account?', style: TextStyle(color: themeService.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 64),
            const SizedBox(height: 16),
            Text(
              'This action is permanent and cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: themeService.textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeService.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Account deletion request submitted.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 40, height: 40),
            const SizedBox(width: 16),
            Text('About DailyDime', style: TextStyle(color: themeService.textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DailyDime is a personal finance app designed to help you manage your budget, track expenses, and save money more effectively.',
              style: TextStyle(fontSize: 14, color: themeService.textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Our mission is to make financial management simple, intuitive, and accessible for everyone.',
              style: TextStyle(fontSize: 14, color: themeService.textColor),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Made with love in Kenya',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: themeService.textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: themeService.primaryColor)),
          ),
        ],
      ),
    );
  }
  
  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'DailyDime',
      applicationVersion: AppConfig.appVersion,
      applicationIcon: Image.asset('assets/images/logo.png', height: 50, width: 50),
    );
  }
}