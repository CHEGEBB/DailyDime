// lib/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:dailydime/screens/home_screen.dart';
import 'package:dailydime/screens/transactions/transactions_screen.dart';
import 'package:dailydime/screens/budget/budget_screen.dart';
import 'package:dailydime/screens/savings/savings_screen.dart';
import 'package:dailydime/screens/ai_insight_screen.dart';
import 'package:dailydime/screens/profile_screen.dart';
import 'package:dailydime/services/theme_service.dart';

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
    const AIInsightsScreen(),
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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
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
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
              boxShadow: [
                BoxShadow(
                  color: themeService.isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: themeService.isDarkMode 
                  ? Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
              child: Container(
                height: isSmallScreen ? 75 : 80,
                child: Row(
                  children: [
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                      index: 0,
                      isSelected: _currentIndex == 0,
                      themeService: themeService,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildNavItem(
                      icon: Icons.receipt_long_outlined,
                      selectedIcon: Icons.receipt_long,
                      label: 'Transactions',
                      index: 1,
                      isSelected: _currentIndex == 1,
                      themeService: themeService,
                      isSmallScreen: isSmallScreen,
                    ),
                    // Center space for FAB with Budget label
                    Expanded(
                      flex: 1,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _navigateToTab(2),
                          child: Container(
                            height: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: isSmallScreen ? 50 : 58,
                                  height: isSmallScreen ? 50 : 58,
                                  decoration: BoxDecoration(
                                    gradient: themeService.primaryGradient,
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 29),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeService.primaryColor.withOpacity(0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 3 : 4),
                                Flexible(
                                  child: Text(
                                    'Budget',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: _currentIndex == 2 ? FontWeight.w600 : FontWeight.w500,
                                      color: _currentIndex == 2 
                                          ? themeService.primaryColor
                                          : themeService.subtextColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_outlined,
                      selectedIcon: Icons.account_balance,
                      label: 'Savings',
                      index: 3,
                      isSelected: _currentIndex == 3,
                      themeService: themeService,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildNavItem(
                      icon: Icons.trending_up_rounded,
                      selectedIcon: Icons.trending_up_rounded,
                      label: 'Analytics',
                      index: 4,
                      isSelected: _currentIndex == 4,
                      themeService: themeService,
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _currentIndex == 1 ? Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: themeService.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: themeService.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ) : null,
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
    required ThemeService themeService,
    required bool isSmallScreen,
    VoidCallback? onTap,
  }) {
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? themeService.primaryColor.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected ? (selectedIcon ?? icon) : icon,
                        size: isSmallScreen ? 20 : 22,
                        color: isSelected 
                            ? themeService.primaryColor
                            : themeService.subtextColor,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 3 : 4),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                              ? themeService.primaryColor
                              : themeService.subtextColor,
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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