// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailydime/widgets/common/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _enableBiometrics = false;
  bool _enablePIN = true;
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF26D07C); // Emerald green
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern floating profile header
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Gradient background with pattern
                    Positioned.fill(
                      child: Container(
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
                        child: Stack(
                          children: [
                            // Pattern overlay
                            Opacity(
                              opacity: 0.1,
                              child: CustomPaint(
                                size: Size(size.width, 260),
                                painter: ProfilePatternPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Profile content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Profile avatar with shadow
                          Container(
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
                            child: Stack(
                              children: [
                                // Avatar or initials
                                Center(
                                  child: Text(
                                    'JD',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                                // Edit button overlay
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
                                      Icons.edit,
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
                          const Text(
                            'John Doe',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'johndoe@example.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Profile stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildProfileStat('4', 'months', Icons.calendar_today),
                              _buildProfileStat('27', 'budgets', Icons.pie_chart),
                              _buildProfileStat('3', 'goals', Icons.flag),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // App bar actions
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                              onPressed: () {},
                              tooltip: 'Notifications',
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
                              onPressed: () {},
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
            
            // Financial Snapshot
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Financial Snapshot',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.insights,
                            size: 16,
                            color: accentColor,
                          ),
                          label: Text(
                            'Full Report',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFinancialMetric(
                                'Net Worth',
                                'KES 250,450',
                                Icons.account_balance_wallet,
                                accentColor,
                              ),
                              _buildFinancialMetric(
                                'Monthly Income',
                                'KES 45,000',
                                Icons.trending_up,
                                Colors.blue,
                              ),
                              _buildFinancialMetric(
                                'Monthly Expenses',
                                'KES 32,541',
                                Icons.trending_down,
                                Colors.orange,
                              ),
                            ],
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFinancialMetric(
                                'Savings Rate',
                                '27.7%',
                                Icons.savings,
                                Colors.amber.shade700,
                              ),
                              _buildFinancialMetric(
                                'Budget Adherence',
                                '85%',
                                Icons.pie_chart,
                                Colors.purple,
                              ),
                              _buildFinancialMetric(
                                'Financial Health',
                                'Good',
                                Icons.favorite,
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Settings section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Account settings cards
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
                          _buildSettingsItem(
                            'Personal Information',
                            'Update your profile details',
                            Icons.person_outline,
                            Colors.blue,
                            () {},
                          ),
                          _buildSettingsItem(
                            'Security',
                            'Password, biometrics, PIN',
                            Icons.security,
                            Colors.orange,
                            () {},
                           
                          ),
                          _buildSecurityOptions(),
                          _buildSettingsItem(
                            'M-Pesa Integration',
                            'Connect your M-Pesa account',
                            Icons.account_balance,
                            Colors.green,
                            () {},
                          ),
                          _buildSettingsItem(
                            'SMS Permissions',
                            'Configure SMS transaction detection',
                            Icons.sms_outlined,
                            Colors.purple,
                            () {},
                          ),
                          _buildSettingsItem(
                            'Notifications',
                            'Configure alerts and reminders',
                            Icons.notifications_outlined,
                            Colors.red,
                            () {},
                           
                          ),
                          _buildSwitchSetting(
                            'Push Notifications',
                            'Receive push notifications',
                            _notificationsEnabled,
                            (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Preferences
                    Text(
                      'Preferences',
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
                          _buildSettingsItem(
                            'App Theme',
                            'Light, dark, or system default',
                            Icons.palette_outlined,
                            Colors.deepPurple,
                            () {},
                           
                          ),
                          _buildSwitchSetting(
                            'Dark Mode',
                            'Enable dark theme',
                            _darkMode,
                            (value) {
                              setState(() {
                                _darkMode = value;
                              });
                            },
                          ),
                          _buildSettingsItem(
                            'Currency',
                            'KES (Kenyan Shilling)',
                            Icons.currency_exchange,
                            Colors.amber.shade700,
                            () {},
                          ),
                          _buildSettingsItem(
                            'Language',
                            'English',
                            Icons.language,
                            Colors.teal,
                            () {},
                          ),
                          _buildSettingsItem(
                            'Data Management',
                            'Export, backup, or delete your data',
                            Icons.storage,
                            Colors.brown,
                            () {},
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI Preferences
                    Text(
                      'AI Assistant Preferences',
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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.smart_toy_outlined,
                                    color: accentColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Features',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Configure how AI helps your finances',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _buildAiSwitchSetting(
                            'Budget Suggestions',
                            'Allow AI to suggest personalized budgets',
                            Icons.lightbulb_outline,
                            false,
                          ),
                          _buildAiSwitchSetting(
                            'Spending Alerts',
                            'Get AI-powered spending alerts',
                            Icons.warning_amber_outlined,
                            false,
                          ),
                          _buildAiSwitchSetting(
                            'Savings Recommendations',
                            'Receive AI suggestions for saving money',
                            Icons.trending_up,
                            false,
                          ),
                          _buildAiSwitchSetting(
                            'Financial Insights',
                            'Get weekly financial insights from AI',
                            Icons.insights,
                            false,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Help & Support
                    Text(
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
                          _buildSettingsItem(
                            'Help Center',
                            'Guides and frequently asked questions',
                            Icons.help_outline,
                            Colors.blue,
                            () {},
                          ),
                          _buildSettingsItem(
                            'Contact Support',
                            'Get help from our team',
                            Icons.support_agent,
                            Colors.green,
                            () {},
                          ),
                          _buildSettingsItem(
                            'Report a Bug',
                            'Help us improve DailyDime',
                            Icons.bug_report_outlined,
                            Colors.orange,
                            () {},
                          ),
                          _buildSettingsItem(
                            'Privacy Policy',
                            'How we protect your data',
                            Icons.privacy_tip_outlined,
                            Colors.grey,
                            () {},
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    CustomButton(
                      isSmall: false,
                      text: 'Sign Out',
                      onPressed: () {},
                      isOutlined: true,
                      icon: Icons.logout,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Center(
                      child: Text(
                        'DailyDime v1.0.0',
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

  Widget _buildProfileStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildFinancialMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool showDivider = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
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
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildSecurityOptions() {
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitchSetting(
            'Enable PIN',
            'Use PIN for app access',
            _enablePIN,
            (value) {
              setState(() {
                _enablePIN = value;
              });
            },
          ),
          _buildSwitchSetting(
            'Enable Biometrics',
            'Use fingerprint or face ID',
            _enableBiometrics,
            (value) {
              setState(() {
                _enableBiometrics = value;
              });
            },
          ),
          InkWell(
            onTap: () {
              // Show change password dialog
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF26D07C),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSwitchSetting(
    String title,
    String subtitle,
    IconData icon,
    bool initialValue,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF26D07C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF26D07C),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: (value) {
              // In a real app, this would update the setting
              HapticFeedback.lightImpact();
            },
            activeColor: const Color(0xFF26D07C),
          ),
        ],
      ),
    );
  }
}

// Modern pattern painter for the profile header
class ProfilePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Create a more modern, dynamic pattern with curved lines
    for (int i = 0; i < size.width; i += 40) {
      // Wavy line pattern
      final path = Path();
      path.moveTo(i.toDouble(), 0);
      
      for (int j = 0; j < size.height; j += 20) {
        path.quadraticBezierTo(
          i + 20, j + 10, 
          i as double, j + 20
        );
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Add some circles for a more dynamic pattern
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < size.width; i += 80) {
      for (int j = 0; j < size.height; j += 80) {
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          4,
          circlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}