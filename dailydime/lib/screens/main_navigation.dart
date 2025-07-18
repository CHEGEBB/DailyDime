// lib/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:dailydime/screens/home_screen.dart';
import 'package:dailydime/screens/transactions/transactions_screen.dart';
import 'package:dailydime/screens/budget/budget_screen.dart';
import 'package:dailydime/screens/savings/savings_screen.dart';
import 'package:dailydime/screens/ai_chat_screen.dart';
import 'package:dailydime/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Widget> get _screens => [
    HomeScreen(
      onNavigateToTransactions: () => _navigateToTab(1),
      onNavigateToBudget: () => _navigateToTab(2),
      onNavigateToSavings: () => _navigateToTab(3),
      onNavigateToAI: () => _navigateToTab(4),
      onNavigateToProfile: () => _navigateToProfile(),
    ),
    const TransactionsScreen(),
    const BudgetScreen(),
    const SavingsScreen(),
    const AIChatScreen(),
  ];

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(
          isSmallScreen ? 12 : 16, 
          0, 
          isSmallScreen ? 12 : 16, 
          isSmallScreen ? 12 : 16
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
          child: Container(
            height: isSmallScreen ? 65 : 70,
            child: Row(
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  isSelected: _currentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Activity',
                  index: 1,
                  isSelected: _currentIndex == 1,
                ),
                // Center space for FAB
                Expanded(
                  child: Container(
                    height: double.infinity,
                    child: Center(
                      child: Container(
                        width: isSmallScreen ? 48 : 56,
                        height: isSmallScreen ? 48 : 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981), // Emerald-500
                              const Color(0xFF059669), // Emerald-600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddTransactionScreen(),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 22 : 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  index: 4,
                  isSelected: _currentIndex == 4,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 5,
                  isSelected: false,
                  onTap: _navigateToProfile,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: null, // Remove external FAB since we have integrated one
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () => _navigateToTab(index),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: isSmallScreen ? 20 : 22,
                        color: isSelected 
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 3),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}