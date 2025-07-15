// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/widgets/common/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: CustomPaint(
                            painter: PatternPainter(),
                          ),
                        ),
                      ),
                      // User profile content
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'JD',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'John Doe',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'john.doe@example.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                titlePadding: const EdgeInsets.all(0),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                  tooltip: 'Edit Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                  tooltip: 'Settings',
                ),
              ],
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Financial Snapshot
                  _buildSectionHeader('Financial Snapshot'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
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
                              theme.colorScheme.primary,
                            ),
                            _buildFinancialMetric(
                              'Monthly Income',
                              'KES 45,000',
                              Icons.trending_up,
                              Colors.green,
                            ),
                            _buildFinancialMetric(
                              'Monthly Expenses',
                              'KES 32,541',
                              Icons.trending_down,
                              theme.colorScheme.error,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFinancialMetric(
                              'Savings Rate',
                              '27.7%',
                              Icons.savings,
                              Colors.amber,
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
                  
                  const SizedBox(height: 24),
                  
                  // Account Settings
                  _buildSectionHeader('Account Settings'),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    'Personal Information',
                    'Name, email, phone number',
                    Icons.person,
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
                    Icons.sms,
                    Colors.purple,
                    () {},
                  ),
                  _buildSettingsItem(
                    'Notifications',
                    'Configure alerts and reminders',
                    Icons.notifications,
                    Colors.red,
                    () {},
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Preferences
                  _buildSectionHeader('Preferences'),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    'App Theme',
                    'Light, dark, or system default',
                    Icons.palette,
                    Colors.deepPurple,
                    () {},
                  ),
                  _buildSettingsItem(
                    'Currency',
                    'KES (Kenyan Shilling)',
                    Icons.currency_exchange,
                    Colors.amber,
                    () {},
                  ),
                  _buildSettingsItem(
                    'Language',
                    'English, Swahili, Sheng',
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
                  
                  const SizedBox(height: 24),
                  
                  // AI Customization
                  _buildSectionHeader('AI Assistant Preferences'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSwitchSetting(
                          'AI Budget Suggestions',
                          'Allow AI to suggest personalized budgets',
                          Icons.smart_toy,
                          theme.colorScheme.primary,
                          true,
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          'Spending Alerts',
                          'Get AI-powered spending alerts',
                          Icons.warning,
                          Colors.orange,
                          true,
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          'Savings Recommendations',
                          'Receive AI suggestions for saving money',
                          Icons.lightbulb_outline,
                          Colors.amber,
                          true,
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          'Financial Insights',
                          'Get weekly financial insights from AI',
                          Icons.insights,
                          Colors.purple,
                          false,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Help & Support
                  _buildSectionHeader('Help & Support'),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    'Help Center',
                    'Guides and frequently asked questions',
                    Icons.help,
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
                    Icons.bug_report,
                    Colors.orange,
                    () {},
                  ),
                  _buildSettingsItem(
                    'Privacy Policy',
                    'How we protect your data',
                    Icons.privacy_tip,
                    Colors.grey,
                    () {},
                  ),
                  
                  const SizedBox(height: 24),
                  
                  CustomButton(
                    isSmall: false, // or true, depending on your design choice
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
                  
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
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
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
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
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) {
            // In a real app, this would update the specific setting
          },
        ),
      ],
    );
  }
}

// Custom painter for the pattern background
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble() + 10, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}