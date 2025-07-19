// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTransactions;
  final VoidCallback? onNavigateToBudget;
  final VoidCallback? onNavigateToSavings;
  final VoidCallback? onNavigateToAI;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onAddTransaction;

  const HomeScreen({
    Key? key,
    this.onNavigateToTransactions,
    this.onNavigateToBudget,
    this.onNavigateToSavings,
    this.onNavigateToAI,
    this.onNavigateToProfile,
    this.onAddTransaction,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _timeFrames = ['Week', 'Month', '3 Month', '6 Month', 'Year'];
  int _selectedTimeFrame = 1; // Default to Month
  bool _showChart = false; // Changed to false to show bar chart by default
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final accentColor = Color(0xFF26D07C); // Emerald green
    final bool isSmallScreen = size.width < 380;
    
    // Set status bar to match white theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header - White bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App Name/Logo instead of hamburger
                    Text(
                      'Daily Dime',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    Row(
                      children: [
                        // Notification Icon
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                size: 24,
                                color: Colors.black,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Profile Image
                        GestureDetector(
                          onTap: widget.onNavigateToProfile,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/profile.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.person, color: Colors.grey.shade600),
                                  ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 5),
              
              // Wallet Balance Card with pattern background
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage('assets/images/pattern2.png'),
                      fit: BoxFit.cover,
                      opacity: 0.1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Wallet Balance',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'KES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'KES 24,550',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Updated: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+8.2%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Income & Expense Stats
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 300) {
                              // Stack vertically on very small screens
                              return Column(
                                children: [
                                  _buildWalletStatItem(
                                    icon: Icons.arrow_upward_rounded,
                                    iconColor: Colors.red,
                                    bgColor: Colors.white.withOpacity(0.2),
                                    iconBgColor: Colors.red.withOpacity(0.2),
                                    title: 'Expense',
                                    amount: 'KES 3,430',
                                    isFullWidth: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildWalletStatItem(
                                    icon: Icons.arrow_downward_rounded,
                                    iconColor: Colors.white,
                                    bgColor: Colors.white.withOpacity(0.2),
                                    iconBgColor: Colors.white.withOpacity(0.2),
                                    title: 'Income',
                                    amount: 'KES 15,000',
                                    isFullWidth: true,
                                  ),
                                ],
                              );
                            }
                            
                            // Side by side for normal screens
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildWalletStatItem(
                                    icon: Icons.arrow_upward_rounded,
                                    iconColor: Colors.red,
                                    bgColor: Colors.white.withOpacity(0.2),
                                    iconBgColor: Colors.red.withOpacity(0.2),
                                    title: 'Expense',
                                    amount: 'KES 3,430',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildWalletStatItem(
                                    icon: Icons.arrow_downward_rounded,
                                    iconColor: Colors.white,
                                    bgColor: Colors.white.withOpacity(0.2),
                                    iconBgColor: Colors.white.withOpacity(0.2),
                                    title: 'Income',
                                    amount: 'KES 15,000',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Quick Action Icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool useCompactLayout = constraints.maxWidth < 350;
                          
                          if (useCompactLayout) {
                            // Compact layout with Wrap for very small screens
                            return Wrap(
                              alignment: WrapAlignment.spaceAround,
                              spacing: 8,
                              runSpacing: 12,
                              children: [
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.add,
                                  iconColor: accentColor,
                                  label: 'Top up',
                                  onTap: () {
                                    _showAddMoneyBottomSheet(context);
                                  },
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.qr_code_scanner_rounded,
                                  iconColor: Colors.blue,
                                  label: 'Receive',
                                  onTap: () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.send_rounded,
                                  iconColor: Colors.purple,
                                  label: 'Send',
                                  onTap: () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.payment_rounded,
                                  iconColor: Colors.orange,
                                  label: 'Pay',
                                  onTap: () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.pie_chart,
                                  iconColor: Colors.red,
                                  label: 'Budget',
                                  onTap: widget.onNavigateToBudget ?? () {},
                                ),
                              ],
                            );
                          }
                          
                          // Default layout with Row
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickAction(
                                context,
                                iconData: Icons.add,
                                iconColor: accentColor,
                                label: 'Top up',
                                onTap: () {
                                  _showAddMoneyBottomSheet(context);
                                },
                              ),
                              _buildQuickAction(
                                context,
                                iconData: Icons.qr_code_scanner_rounded,
                                iconColor: Colors.blue,
                                label: 'Receive',
                                onTap: () {},
                              ),
                              _buildQuickAction(
                                context,
                                iconData: Icons.send_rounded,
                                iconColor: Colors.purple,
                                label: 'Send',
                                onTap: () {},
                              ),
                              _buildQuickAction(
                                context,
                                iconData: Icons.payment_rounded,
                                iconColor: Colors.orange,
                                label: 'Pay',
                                onTap: () {},
                              ),
                              _buildQuickAction(
                                context,
                                iconData: Icons.pie_chart,
                                iconColor: Colors.red,
                                label: 'Budget',
                                onTap: widget.onNavigateToBudget ?? () {},
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Spending Overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spending Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showChart = !_showChart;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _showChart ? Icons.bar_chart : Icons.pie_chart,
                                  size: 18,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Chart container with shadow
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Chart view
                          if (_showChart)
                            SizedBox(
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 200,
                                    width: 200,
                                    child: CustomPaint(
                                      painter: PieChartPainter(),
                                      child: Container(),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'KES 24,550',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              height: 220,
                              child: SpendingBarChart(),
                            ),
                            
                          const SizedBox(height: 20),
                          
                          // Expense Categories - Responsive grid/wrap
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildCategoryLegend('Food', Colors.orange, '38%'),
                              _buildCategoryLegend('Transport', Colors.blue, '25%'),
                              _buildCategoryLegend('Shopping', Colors.green, '18%'),
                              _buildCategoryLegend('Bills', Colors.red, '12%'),
                              _buildCategoryLegend('Others', Colors.purple, '7%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Savings Goals
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Savings Goals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToSavings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Savings Goal Cards
                    SizedBox(
                      height: 170,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        children: [
                          _buildSavingsGoalCard(
                            context, 
                            title: 'Emergency Fund',
                            icon: Icons.account_balance,
                            currentAmount: 15000,
                            targetAmount: 50000,
                            color: Colors.blue,
                            progress: 0.3,
                          ),
                          _buildSavingsGoalCard(
                            context, 
                            title: 'New Laptop',
                            icon: Icons.laptop_mac,
                            currentAmount: 25000,
                            targetAmount: 80000,
                            color: accentColor,
                            progress: 0.31,
                          ),
                          _buildSavingsGoalCard(
                            context, 
                            title: 'Holiday',
                            icon: Icons.beach_access,
                            currentAmount: 5000,
                            targetAmount: 45000,
                            color: Colors.orange,
                            progress: 0.11,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Recent Transactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToTransactions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Transactions list
                    Column(
                      children: [
                        _buildTransactionItem(
                          context,
                          logo: 'assets/images/kfc.png',
                          name: 'KFC Restaurant',
                          date: '18/07/2025',
                          amount: -1250.0,
                          logoPlaceholder: Icons.fastfood,
                          logoColor: Colors.red,
                          category: 'Food',
                        ),
                        const SizedBox(height: 12),
                        _buildTransactionItem(
                          context,
                          logo: 'assets/images/mpesa.png',
                          name: 'M-Pesa Transfer',
                          date: '18/07/2025',
                          amount: -500.0,
                          logoPlaceholder: Icons.swap_horiz,
                          logoColor: Colors.green,
                          category: 'Transfer',
                        ),
                        
                        // Show expanded transactions
                        if (_isExpanded) ...[
                          const SizedBox(height: 12),
                          _buildTransactionItem(
                            context,
                            logo: 'assets/images/salary.png',
                            name: 'Salary',
                            date: '15/07/2025',
                            amount: 45000.0,
                            logoPlaceholder: Icons.work,
                            logoColor: Colors.blue,
                            category: 'Income',
                          ),
                          const SizedBox(height: 12),
                          _buildTransactionItem(
                            context,
                            logo: 'assets/images/safaricom.png',
                            name: 'Safaricom',
                            date: '14/07/2025',
                            amount: -1000.0,
                            logoPlaceholder: Icons.phone_android,
                            logoColor: Colors.green,
                            category: 'Bills',
                          ),
                        ],
                      ],
                    ),
                    
                    // Show more/less button
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'Show less' : 'Show more',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.grey[800],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Budget Status with better visualization
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budget Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToBudget,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Budget visualization
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Budget overview chart
                          SizedBox(
                            height: 180,
                            child: CustomPaint(
                              painter: BudgetChartPainter(),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Budget categories
                          _buildModernBudgetItem(
                            context,
                            category: 'Food & Dining',
                            icon: Icons.restaurant,
                            iconColor: Colors.orange,
                            currentAmount: 3430,
                            budgetAmount: 5000,
                            progress: 3430 / 5000,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          _buildModernBudgetItem(
                            context,
                            category: 'Transportation',
                            icon: Icons.directions_car,
                            iconColor: Colors.blue,
                            currentAmount: 2800,
                            budgetAmount: 3000,
                            progress: 2800 / 3000,
                            isWarning: true,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          _buildModernBudgetItem(
                            context,
                            category: 'Entertainment',
                            icon: Icons.movie,
                            iconColor: Colors.purple,
                            currentAmount: 1200,
                            budgetAmount: 2000,
                            progress: 1200 / 2000,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // AI Insights Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.9),
                        accentColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage('assets/images/pattern.png'),
                      fit: BoxFit.cover,
                      opacity: 0.05,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'AI Insights',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: widget.onNavigateToAI,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'More',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // AI Insight Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Spending Alert',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You\'ve spent KES 2,500 on dining this month, which is 40% higher than last month. Consider setting a budget limit for this category.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Set Budget',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Second AI Insight Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.savings_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Savings Opportunity',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Based on your income pattern, you could save KES 3,000 more this month by reducing non-essential expenses. Would you like to try a savings challenge?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Start Challenge',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
              ),
              
              const SizedBox(height: 30),
              
              // Financial Tips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Smart Money Tips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Financial tips carousel
                    SizedBox(
                      height: 170,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        children: [
                          _buildFinancialTipCard(
                            context,
                            title: 'Save 20% of your income',
                            icon: Icons.savings,
                            description: 'The 50/30/20 rule suggests saving 20% of your income for financial goals.',
                            color: accentColor,
                          ),
                          _buildFinancialTipCard(
                            context,
                            title: 'Track all expenses',
                            icon: Icons.track_changes,
                            description: 'People who track expenses save 15% more than those who don\'t.',
                            color: Colors.purple,
                          ),
                          _buildFinancialTipCard(
                            context,
                            title: 'Build emergency fund',
                            icon: Icons.health_and_safety,
                            description: 'Aim for 3-6 months of expenses in your emergency fund.',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: widget.onAddTransaction != null ? FloatingActionButton(
        onPressed: widget.onAddTransaction,
        backgroundColor: accentColor,
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ) : null,
    );
  }
  
  // Wallet stat item widget
  Widget _buildWalletStatItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color iconBgColor,
    required String title,
    required String amount,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Updated quick action widget with colored icons
  Widget _buildQuickAction(
    BuildContext context, {
    required IconData iconData,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                iconData,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Updated transaction item with elevation
  Widget _buildTransactionItem(
    BuildContext context, {
    required String logo,
    required String name,
    required String date,
    required double amount,
    required IconData logoPlaceholder,
    required Color logoColor,
    required String category,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: logoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  logoPlaceholder,
                  color: logoColor,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: logoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 10,
                          color: logoColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${amount > 0 ? "+" : ""}KES ${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amount > 0 ? Color(0xFF26D07C) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  // Updated category legend with better contrast
  Widget _buildCategoryLegend(String title, Color color, String percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  // Updated savings goal card with better shadow
  Widget _buildSavingsGoalCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required double currentAmount,
    required double targetAmount,
    required Color color,
    required double progress,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7 > 250 ? 250 : MediaQuery.of(context).size.width * 0.7,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'KES ${currentAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / ${targetAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Updated modern progress indicator
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Container(
                      height: 8,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.7), color],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% completed',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Improved modern budget item
  Widget _buildModernBudgetItem(
    BuildContext context, {
    required String category,
    required IconData icon,
    required Color iconColor,
    required double currentAmount,
    required double budgetAmount,
    required double progress,
    bool isWarning = false,
  }) {
    Color progressColor = Color(0xFF26D07C); // Default green
    
    if (progress > 0.9) {
      progressColor = Colors.red;
    } else if (progress > 0.7) {
      progressColor = Colors.orange;
    }
    
    return Row(
      children: [
        // Category icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Category info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isWarning)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.priority_high,
                        size: 12,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Progress text
              Row(
                children: [
                  Text(
                    'KES ${currentAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                  Text(
                    ' / ${budgetAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Progress bar
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Container(
                          height: 6,
                          width: constraints.maxWidth * (progress > 1 ? 1 : progress),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [progressColor.withOpacity(0.7), progressColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: progressColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Improved financial tip card
  Widget _buildFinancialTipCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7 > 260 ? 260 : MediaQuery.of(context).size.width * 0.7,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.tips_and_updates,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                'AI Generated',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Add Money Bottom Sheet
  void _showAddMoneyBottomSheet(BuildContext context) {
    final accentColor = Color(0xFF26D07C);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Up Wallet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              Text(
                'Select Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Amount Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'KES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1,000.00',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 2,
                          color: accentColor,
                          margin: const EdgeInsets.only(left: 4, bottom: 4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                'Quick Amounts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick Amount Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAmountButton('500', accentColor),
                  _buildQuickAmountButton('1,000', accentColor, isSelected: true),
                  _buildQuickAmountButton('2,000', accentColor),
                  _buildQuickAmountButton('5,000', accentColor),
                ],
              ),
              
              const SizedBox(height: 30),
              
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Payment Methods
              _buildPaymentMethodItem(
                iconData: Icons.phone_android,
                iconColor: Colors.green,
                title: 'M-Pesa',
                subtitle: 'Connected: +254 7XX XXX XXX',
                accentColor: accentColor,
                isSelected: true,
              ),
              
              const SizedBox(height: 12),
              
              _buildPaymentMethodItem(
                iconData: Icons.credit_card,
                iconColor: Colors.blue,
                title: 'Credit/Debit Card',
                subtitle: 'Visa, Mastercard, etc.',
                accentColor: accentColor,
              ),
              
              const SizedBox(height: 12),
              
              _buildPaymentMethodItem(
                iconData: Icons.account_balance,
                iconColor: Colors.purple,
                title: 'Bank Transfer',
                subtitle: 'Direct bank deposit',
                accentColor: accentColor,
              ),
              
              const Spacer(),
              
              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Quick amount button
  Widget _buildQuickAmountButton(String amount, Color accentColor, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? accentColor : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Text(
        amount,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey[800],
        ),
      ),
    );
  }
  
  // Payment method item
  Widget _buildPaymentMethodItem({
    required IconData iconData,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color accentColor,
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: iconColor,
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accentColor : Colors.grey.withOpacity(0.1),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// Pie Chart Painter with improved shadow effects
class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Categories with colors and percentages
    final categories = [
      {'color': Colors.orange, 'percent': 0.38},
      {'color': Colors.blue, 'percent': 0.25},
      {'color': Colors.green, 'percent': 0.18},
      {'color': Colors.red, 'percent': 0.12},
      {'color': Colors.purple, 'percent': 0.07},
    ];
    
    double startAngle = 0;
    
    // Draw shadows first
    for (var category in categories) {
      final sweepAngle = 2 * math.pi * (category['percent'] as double);
      final shadowPaint = Paint()
        ..color = (category['color'] as Color).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 14),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Reset angle for actual segments
    startAngle = 0;
    
    // Draw segments
    for (var category in categories) {
      final sweepAngle = 2 * math.pi * (category['percent'] as double);
      final paint = Paint()
        ..color = category['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 12),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Inner circle with shadow
    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(center, radius - 30, innerShadowPaint);
    
    // Inner circle
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius - 30, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Budget Chart Painter - Doughnut chart with multiple categories
class BudgetChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    // Budget categories with colors, labels, and percentages
    final categories = [
      {'color': Colors.orange, 'label': 'Food', 'spent': 0.68, 'total': 0.35},
      {'color': Colors.blue, 'label': 'Transport', 'spent': 0.93, 'total': 0.25},
      {'color': Colors.purple, 'label': 'Entertainment', 'spent': 0.6, 'total': 0.15},
      {'color': Colors.teal, 'label': 'Shopping', 'spent': 0.4, 'total': 0.10},
      {'color': Colors.red, 'label': 'Bills', 'spent': 0.75, 'total': 0.15},
    ];
    
    double startAngle = -math.pi / 2; // Start from top
    
    // Draw total budget segments (background)
    for (var category in categories) {
      final sweepAngle = 2 * math.pi * (category['total'] as double);
      final bgPaint = Paint()
        ..color = (category['color'] as Color).withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        bgPaint,
      );
      
      // Draw spent amount on top
      final spentAngle = sweepAngle * (category['spent'] as double);
      final spentPaint = Paint()
        ..color = category['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        spentAngle,
        false,
        spentPaint,
      );
      
      // Draw label
      final labelAngle = startAngle + (sweepAngle / 2);
      final labelRadius = radius + 30;
      final labelPosition = Offset(
        center.dx + labelRadius * math.cos(labelAngle),
        center.dy + labelRadius * math.sin(labelAngle),
      );
      
      // Draw label dot
      final dotPaint = Paint()
        ..color = category['color'] as Color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(
          center.dx + (radius + 10) * math.cos(labelAngle),
          center.dy + (radius + 10) * math.sin(labelAngle),
        ),
        4,
        dotPaint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Center text
    final totalSpentPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final textSpan = TextSpan(
      text: '75%',
      style: TextStyle(
        color: Color(0xFF26D07C),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
    
    // "Used" text below
    final subTextSpan = TextSpan(
      text: 'Used',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
    );
    
    final subTextPainter = TextPainter(
      text: subTextSpan,
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    subTextPainter.layout();
    subTextPainter.paint(
      canvas,
      Offset(
        center.dx - subTextPainter.width / 2,
        center.dy + textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Enhanced Bar Chart for Spending
class SpendingBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarChartPainter(),
      child: Container(),
    );
  }
}

class BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 40.0;
    final spacing = (size.width - (7 * barWidth)) / 8;
    final maxBarHeight = size.height - 60;
    final accentColor = Color(0xFF26D07C);
    
    // Draw horizontal gridlines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 4; i++) {
      final y = size.height - 40 - (maxBarHeight / 4 * i);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Days and heights
    final List<Map<String, dynamic>> data = [
      {'label': 'Mon', 'height': 0.6, 'color': Colors.grey[300]},
      {'label': 'Tue', 'height': 0.8, 'color': Colors.grey[300]},
      {'label': 'Wed', 'height': 0.4, 'color': Colors.grey[300]},
      {'label': 'Thu', 'height': 0.9, 'color': Colors.grey[300]},
      {'label': 'Fri', 'height': 0.7, 'color': accentColor},
      {'label': 'Sat', 'height': 0.5, 'color': Colors.grey[300]},
      {'label': 'Sun', 'height': 0.3, 'color': Colors.grey[300]},
    ];
    
    // Draw bars with shadows
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight = maxBarHeight * (item['height'] as double);
      final left = spacing + i * (barWidth + spacing);
      final top = size.height - 40 - barHeight;
      final right = left + barWidth;
      final bottom = size.height - 40;
      
      // Draw shadow
      final shadowPaint = Paint()
        ..color = (item['color'] as Color?)?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top + 3, right, bottom + 3),
          Radius.circular(8),
        ),
        shadowPaint,
      );
      
      // Draw bar
      final paint = Paint()
        ..color = item['color'] as Color? ?? Colors.grey
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          Radius.circular(8),
        ),
        paint,
      );
      
      // Draw label
      final textSpan = TextSpan(
        text: item['label'] as String,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, bottom + 10),
      );
      
      // Draw amount for current day (Friday)
      if (item['label'] == 'Fri') {
        final amountSpan = TextSpan(
          text: 'KES 2,500',
          style: TextStyle(
            color: accentColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        
        final amountPainter = TextPainter(
          text: amountSpan,
          textDirection: ui.TextDirection.ltr,
        );
        
        amountPainter.layout();
        amountPainter.paint(
          canvas,
          Offset(left + (barWidth - amountPainter.width) / 2, top - 20),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}