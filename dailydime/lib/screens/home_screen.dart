// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/screens/mpesa_screen.dart';
import 'package:dailydime/services/balance_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/services/home_ai_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/models/budget.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTransactions;
  final VoidCallback? onNavigateToBudget;
  final VoidCallback? onNavigateToSavings;
  final VoidCallback? onNavigateToAI;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onAddTransaction;

  const HomeScreen({
    Key? key,
    this.onNavigateToTransactions,
    this.onNavigateToBudget,
    this.onNavigateToSavings,
    this.onNavigateToAI,
    this.onNavigateToSettings,
    this.onAddTransaction,
    required void Function() onNavigateToProfile,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  final TextEditingController _balanceController = TextEditingController();

  // UI state variables
  final List<String> _timeFrames = [
    'Week',
    'Month',
    '3 Month',
    '6 Month',
    'Year',
  ];
  int _selectedTimeFrame = 1; // Default to Month
  bool _showChart = false; // Show bar chart by default
  bool _isExpanded = false;
  bool _isEditingBalance = false;
  bool _isLoading = true;

  // Budget data
  int _selectedBudgetCategoryIndex = 0;

  // Service data
  double _currentBalance = 0.0;
  String _lastUpdateTime = '';
  List<Transaction> _recentTransactions = [];
  List<SavingsGoal> _savingsGoals = [];
  List<BudgetCategory> _budgetCategories = [];
  Map<String, double> _categoryPercentages = {};

  // AI Insights
  String _spendingAlertText = '';
  String _savingsOpportunityText = '';

  // Subscription handlers
  StreamSubscription? _balanceSubscription;
  StreamSubscription? _transactionsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize data
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize balance service
      await BalanceService.instance.initialize();

      // Listen to balance updates
      _balanceSubscription = BalanceService.instance.balanceStream.listen((
        balance,
      ) {
        setState(() {
          _currentBalance = balance;
          _balanceController.text = NumberFormat(
            '#,##0',
            'en_US',
          ).format(balance.round());
          _lastUpdateTime = DateFormat(
            'dd/MM/yyyy',
          ).format(BalanceService.instance.getLastUpdateTime());
        });
      });

      // Get initial balance
      _currentBalance = BalanceService.instance.getCurrentBalance();
      _balanceController.text = NumberFormat(
        '#,##0',
        'en_US',
      ).format(_currentBalance.round());
      _lastUpdateTime = DateFormat(
        'dd/MM/yyyy',
      ).format(BalanceService.instance.getLastUpdateTime());

      // Load recent transactions
      await _loadRecentTransactions();

      // Load savings goals
      await _loadSavingsGoals();

      // Load budget categories
      await _loadBudgetCategories();

      // Calculate category percentages for pie chart
      _calculateCategoryPercentages();

      // Generate AI Insights
      await _generateAIInsights();
    } catch (e) {
      print('Error initializing home screen data: $e');
      // Use mock data as fallback
      _loadMockData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMockData() {
    // Mock data for balance
    _currentBalance = 24550;
    _balanceController.text = '24,550';
    _lastUpdateTime = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Mock data for budget categories
    _budgetCategories = [
      BudgetCategory(
        name: 'Food & Dining',
        icon: Icons.restaurant,
        color: Colors.orange,
        spent: 3430,
        budget: 5000,
        dailyData: [750, 620, 350, 800, 910, 0, 0],
      ),
      BudgetCategory(
        name: 'Transportation',
        icon: Icons.directions_car,
        color: Colors.blue,
        spent: 2800,
        budget: 3000,
        dailyData: [400, 350, 500, 420, 1130, 0, 0],
      ),
      BudgetCategory(
        name: 'Entertainment',
        icon: Icons.movie,
        color: Colors.purple,
        spent: 1200,
        budget: 2000,
        dailyData: [0, 300, 0, 450, 450, 0, 0],
      ),
      BudgetCategory(
        name: 'Shopping',
        icon: Icons.shopping_bag,
        color: Colors.teal,
        spent: 5600,
        budget: 10000,
        dailyData: [1200, 0, 1400, 0, 3000, 0, 0],
      ),
    ];

    // Mock category percentages
    _categoryPercentages = {
      'Food': 38,
      'Transport': 25,
      'Shopping': 18,
      'Bills': 12,
      'Others': 7,
    };

    // Mock AI insights
    _spendingAlertText =
        "You've spent KES 2,500 on dining this month, which is 40% higher than last month. Consider setting a budget limit for this category.";
    _savingsOpportunityText =
        "Based on your income pattern, you could save KES 3,000 more this month by reducing non-essential expenses. Would you like to try a savings challenge?";
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final AppwriteService appwrite = AppwriteService();
      final transactionsList = await appwrite.getRecentTransactions(limit: 10);

      setState(() {
        _recentTransactions = transactionsList;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      // Mock transactions as fallback
      _recentTransactions = [
        Transaction(
          id: '1',
          title: 'KFC Restaurant',
          amount: -1250,
          date: DateTime.now().subtract(Duration(days: 1)),
          category: 'Food',
          isExpense: true,
          icon: Icons.fastfood,
          color: Colors.transparent,
          isSms: true,
        ),
        Transaction(
          id: '2',
          title: 'M-Pesa Transfer',
          amount: -500,
          date: DateTime.now().subtract(Duration(days: 1)),
          category: 'Transfer',
          isExpense: false,
          icon: Icons.transfer_within_a_station,
          color: Colors.grey,
          isSms: false,
        ),
      ];
    }
  }

  Future<void> _loadSavingsGoals() async {
    try {
      final AppwriteService appwrite = AppwriteService();
      final goalsList = await appwrite.getSavingsGoals();

      setState(() {
        _savingsGoals = goalsList;
      });
    } catch (e) {
      print('Error loading savings goals: $e');
      // Mock savings goals as fallback - FIXED COLOR HANDLING
      _savingsGoals = [
        SavingsGoal(
          id: '1',
          title: 'Emergency Fund',
          currentAmount: 15000,
          targetAmount: 50000,
          deadline: DateTime.now().add(Duration(days: 365)),
          color: ui.Color(0xFF26D07C), // Use ui.Color constructor
          targetDate: DateTime.now().add(Duration(days: 365)),
          category: SavingsGoalCategory.other,
          iconAsset: 'assets/icons/bank.png',
          icon: Icons.account_balance,
        ),
        SavingsGoal(
          id: '2',
          title: 'Laptop Fund',
          currentAmount: 25000,
          targetAmount: 80000,
          deadline: DateTime.now().add(Duration(days: 180)),
          color: ui.Color(0xFF26D07C), // Use ui.Color constructor
          targetDate: DateTime.now().add(Duration(days: 180)),
          category: SavingsGoalCategory.other,
          iconAsset: 'assets/icons/laptop.png',
          icon: Icons.laptop_mac,
        ),
        SavingsGoal(
          id: '3',
          title: 'Vacation Fund',
          currentAmount: 5000,
          targetAmount: 45000,
          deadline: DateTime.now().add(Duration(days: 120)),
          color: ui.Color(0xFFFF9800), // Use ui.Color constructor
          targetDate: DateTime.now().add(Duration(days: 120)),
          category: SavingsGoalCategory.other,
          iconAsset: 'assets/icons/vacation.png',
          icon: Icons.beach_access,
        ),
      ];
    }
  }

  Future<void> _loadBudgetCategories() async {
    try {
      final AppwriteService appwrite = AppwriteService();
      final budgetsList = await appwrite.getBudgets();

      final List<BudgetCategory> categories = [];

      for (final budget in budgetsList) {
        // Get daily data for this budget (from transactions)
        List<double> dailyData = await appwrite.getDailySpendingForBudget(
          budget.category,
          DateTime.now().subtract(Duration(days: 7)),
          DateTime.now(),
        );

        // Map icon based on category
        IconData icon = Icons.category;
        Color color = Colors.grey;

        switch (budget.category.toLowerCase()) {
          case 'food':
          case 'food & dining':
          case 'dining':
            icon = Icons.restaurant;
            color = Colors.orange;
            break;
          case 'transport':
          case 'transportation':
            icon = Icons.directions_car;
            color = Colors.blue;
            break;
          case 'entertainment':
            icon = Icons.movie;
            color = Colors.purple;
            break;
          case 'shopping':
            icon = Icons.shopping_bag;
            color = Colors.teal;
            break;
          case 'bills':
          case 'utilities':
            icon = Icons.receipt;
            color = Colors.red;
            break;
        }

        categories.add(
          BudgetCategory(
            name: budget.title,
            icon: icon,
            color: color,
            spent: budget.spent.toDouble(),
            budget: budget.amount.toDouble(),
            dailyData: dailyData.map((e) => e.toDouble()).toList(),
          ),
        );
      }

      if (categories.isNotEmpty) {
        setState(() {
          _budgetCategories = categories;
        });
      } else {
        // Use mock data if no budgets
        _loadMockData();
      }
    } catch (e) {
      print('Error loading budgets: $e');
      // Use mock data as fallback
      _loadMockData();
    }
  }

  void _calculateCategoryPercentages() {
    Map<String, double> totals = {};
    double overallTotal = 0;

    // Calculate totals per category
    for (final transaction in _recentTransactions) {
      if (transaction.amount < 0) {
        // Only include expenses
        final amount = transaction.amount.abs();
        totals[transaction.category] =
            (totals[transaction.category] ?? 0) + amount;
        overallTotal += amount;
      }
    }

    // Calculate percentages
    Map<String, double> percentages = {};

    if (overallTotal > 0) {
      totals.forEach((category, total) {
        percentages[category] = (total / overallTotal) * 100;
      });
    } else {
      // Fallback to mock data
      percentages = {
        'Food': 38,
        'Transport': 25,
        'Shopping': 18,
        'Bills': 12,
        'Others': 7,
      };
    }

    setState(() {
      _categoryPercentages = percentages;
    });
  }

  Future<void> _generateAIInsights() async {
    try {
      final HomeAIService aiService = HomeAIService();

      // Analyze spending patterns
      final spendingInsight = await aiService.analyzeSpendingPattern(
        _recentTransactions,
      );

      // Generate savings opportunity
      final savingsInsight = await aiService.generateSavingsOpportunity(
        _recentTransactions,
        _budgetCategories
            .map(
              (b) => Budget(
                id: '',
                // userId: '',
                // categoryId: '',
                // categoryName: b.name,
                // budgetAmount: b.budget.toDouble(),
                spent: b.spent.toDouble(),
                period: BudgetPeriod.monthly,
                createdAt: DateTime.now(),
                title: '',
                category: '',
                amount: 0.0,
                startDate: DateTime.now(),
                endDate: DateTime.now(),
                color: Colors.transparent,
                icon: Icons.help,
              ),
            )
            .toList(),
      );

      setState(() {
        _spendingAlertText = spendingInsight;
        _savingsOpportunityText = savingsInsight;
      });
    } catch (e) {
      print('Error generating AI insights: $e');
      // Use mock insights as fallback
      setState(() {
        _spendingAlertText =
            "You've spent KES 2,500 on dining this month, which is 40% higher than last month. Consider setting a budget limit for this category.";
        _savingsOpportunityText =
            "Based on your income pattern, you could save KES 3,000 more this month by reducing non-essential expenses. Would you like to try a savings challenge?";
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _balanceController.dispose();
    _balanceSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  void _showAddMoneyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 16),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Add Money',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildTopUpOption(
                    icon: Icons.phone_android,
                    title: 'M-PESA',
                    subtitle: 'Direct deposit from M-PESA',
                    iconColor: Colors.green,
                  ),

                  _buildTopUpOption(
                    icon: Icons.credit_card,
                    title: 'Debit/Credit Card',
                    subtitle: 'Link your bank card',
                    iconColor: Colors.blue,
                  ),

                  _buildTopUpOption(
                    icon: Icons.account_balance,
                    title: 'Bank Transfer',
                    subtitle: 'Direct bank deposit',
                    iconColor: Colors.purple,
                  ),

                  SizedBox(height: 24),

                  Text(
                    'Manual Entry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 16),

                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (KES)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),

                  SizedBox(height: 16),

                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),

                  SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF26D07C),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Funds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final accentColor = Color(0xFF26D07C); // Emerald green
    final bool isSmallScreen = size.width < 380;

    // Set status bar to match white theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // You can use Lottie animation here instead
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
              SizedBox(height: 20),
              Text(
                'Loading your financial data...',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _initializeData,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header - White bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Logo instead of text
                      Row(
                        children: [
                          Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'DailyDime',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
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
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Settings Icon (replacing profile)
                          GestureDetector(
                            onTap: widget.onNavigateToSettings,
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
                                Icons.settings_outlined,
                                size: 24,
                                color: Colors.black,
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
                        colors: [accentColor, accentColor.withOpacity(0.8)],
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
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

                          // Editable balance
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditingBalance = true;
                              });
                            },
                            child: _isEditingBalance
                                ? Container(
                                    height: 46,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'KES ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _balanceController,
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            autofocus: true,
                                            onSubmitted: (value) {
                                              _updateManualBalance(value);
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            _updateManualBalance(
                                              _balanceController.text,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Text(
                                        'KES ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _balanceController.text,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.edit,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Updated: $_lastUpdateTime',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
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
                                      amount:
                                          'KES ${_calculateTotalExpenses()}',
                                      isFullWidth: true,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildWalletStatItem(
                                      icon: Icons.arrow_downward_rounded,
                                      iconColor: Colors.white,
                                      bgColor: Colors.white.withOpacity(0.2),
                                      iconBgColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      title: 'Income',
                                      amount: 'KES ${_calculateTotalIncome()}',
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
                                      amount:
                                          'KES ${_calculateTotalExpenses()}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildWalletStatItem(
                                      icon: Icons.arrow_downward_rounded,
                                      iconColor: Colors.white,
                                      bgColor: Colors.white.withOpacity(0.2),
                                      iconBgColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      title: 'Income',
                                      amount: 'KES ${_calculateTotalIncome()}',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
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
                            final bool useCompactLayout =
                                constraints.maxWidth < 350;

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
                                    iconData: Icons.phone_android,
                                    iconColor: Colors.green,
                                    label: 'M-PESA',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MpesaScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildQuickAction(
                                    context,
                                    iconData: Icons.savings,
                                    iconColor: Colors.orange,
                                    label: 'Savings',
                                    onTap: widget.onNavigateToSavings ?? () {},
                                  ),
                                  _buildQuickAction(
                                    context,
                                    iconData: Icons.pie_chart,
                                    iconColor: Colors.red,
                                    label: 'Budget',
                                    onTap: widget.onNavigateToBudget ?? () {},
                                  ),
                                  _buildQuickAction(
                                    context,
                                    iconData: Icons.auto_awesome,
                                    iconColor: Colors.purple,
                                    label: 'AI Insights',
                                    onTap: widget.onNavigateToAI ?? () {},
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
                                  iconData: Icons.phone_android,
                                  iconColor: Colors.green,
                                  label: 'M-PESA',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MpesaScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.savings,
                                  iconColor: Colors.orange,
                                  label: 'Savings',
                                  onTap: widget.onNavigateToSavings ?? () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.pie_chart,
                                  iconColor: Colors.red,
                                  label: 'Budget',
                                  onTap: widget.onNavigateToBudget ?? () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.auto_awesome,
                                  iconColor: Colors.purple,
                                  label: 'AI Insights',
                                  onTap: widget.onNavigateToAI ?? () {},
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
                                    _showChart
                                        ? Icons.bar_chart
                                        : Icons.pie_chart,
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
                                        painter: PieChartPainter(
                                          categoryPercentages:
                                              _categoryPercentages,
                                        ),
                                        child: Container(),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'KES ${NumberFormat('#,##0', 'en_US').format(_currentBalance.round())}',
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
                                child: SpendingBarChart(
                                  weeklyData: _getWeeklySpendingData(),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Expense Categories - Responsive grid/wrap
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: _categoryPercentages.entries.map((
                                entry,
                              ) {
                                Color color = _getCategoryColor(entry.key);
                                return _buildCategoryLegend(
                                  entry.key,
                                  color,
                                  '${entry.value.round()}%',
                                );
                              }).toList(),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                      _savingsGoals.isEmpty
                          ? _buildEmptySavingsState()
                          : SizedBox(
                              height: 170,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: BouncingScrollPhysics(),
                                itemCount: _savingsGoals.length,
                                itemBuilder: (context, index) {
                                  final goal = _savingsGoals[index];
                                  return _buildSavingsGoalCard(
                                    context,
                                    title: goal.title ?? 'Goal ${index + 1}',
                                    icon: goal.icon ?? Icons.savings,
                                    currentAmount: goal.currentAmount.toInt(),
                                    targetAmount: goal.targetAmount.toInt(),
                                    // FIXED: Properly handle ui.Color type
                                    color: goal.color != null
                                        ? (goal.color is ui.Color
                                              ? goal.color as ui.Color
                                              : ui.Color(0xFF26D07C))
                                        : ui.Color(0xFF26D07C),
                                    progress:
                                        goal.currentAmount / goal.targetAmount,
                                  );
                                },
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                      _recentTransactions.isEmpty
                          ? _buildEmptyTransactionsState()
                          : Column(
                              children: [
                                ..._recentTransactions
                                    .take(_isExpanded ? 4 : 2)
                                    .map(
                                      (transaction) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildTransactionItem(
                                          context,
                                          logo:
                                              transaction.iconPath ??
                                              'default_icon_path.png',
                                          name: transaction.title,
                                          date: DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(transaction.date),
                                          amount: transaction.amount.toDouble(),
                                          logoPlaceholder: _getCategoryIcon(
                                            transaction.category,
                                          ),
                                          logoColor: _getCategoryColor(
                                            transaction.category,
                                          ),
                                          category: transaction.category,
                                        ),
                                      ),
                                    )
                                    .toList(),

                                // Show more/less button if we have enough transactions
                                if (_recentTransactions.length > 2)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isExpanded = !_isExpanded;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _isExpanded
                                                    ? 'Show less'
                                                    : 'Show more',
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Icon(
                                                _isExpanded
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
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
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Budget Status with interactive bar graph
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                      _budgetCategories.isEmpty
                          ? _buildEmptyBudgetState()
                          : Container(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Budget Period Selector
                                  Row(
                                    children: [
                                      Text(
                                        'Budget Period:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMMM yyyy',
                                              ).format(DateTime.now()),
                                              style: TextStyle(
                                                color: accentColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 16,
                                              color: accentColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 24),

                                  // Category selector for the chart
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: BouncingScrollPhysics(),
                                    child: Row(
                                      children: List.generate(
                                        _budgetCategories.length,
                                        (index) => GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedBudgetCategoryIndex =
                                                  index;
                                            });
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(right: 10),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _selectedBudgetCategoryIndex ==
                                                      index
                                                  ? _budgetCategories[index]
                                                        .color
                                                  : _budgetCategories[index]
                                                        .color
                                                        .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _budgetCategories[index].icon,
                                                  color:
                                                      _selectedBudgetCategoryIndex ==
                                                          index
                                                      ? Colors.white
                                                      : _budgetCategories[index]
                                                            .color,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  _budgetCategories[index].name,
                                                  style: TextStyle(
                                                    color:
                                                        _selectedBudgetCategoryIndex ==
                                                            index
                                                        ? Colors.white
                                                        : _budgetCategories[index]
                                                              .color,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  // Budget overview interactive bar chart
                                  Container(
                                    height: 220,
                                    width: double.infinity,
                                    child: BudgetBarChart(
                                      dailyData:
                                          _budgetCategories[_selectedBudgetCategoryIndex]
                                              .dailyData,
                                      color:
                                          _budgetCategories[_selectedBudgetCategoryIndex]
                                              .color,
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  // Budget category total summary
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Spent',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    'KES ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    '${_budgetCategories[_selectedBudgetCategoryIndex].spent.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _budgetCategories[_selectedBudgetCategoryIndex]
                                                              .color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Budget',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    'KES ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    '${_budgetCategories[_selectedBudgetCategoryIndex].budget.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Remaining',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    'KES ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    '${(_budgetCategories[_selectedBudgetCategoryIndex].budget - _budgetCategories[_selectedBudgetCategoryIndex].spent).toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: accentColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 16),

                                  // Monthly progress bar
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Monthly Progress',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            '${(_budgetCategories[_selectedBudgetCategoryIndex].spent / _budgetCategories[_selectedBudgetCategoryIndex].budget * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value:
                                              _budgetCategories[_selectedBudgetCategoryIndex]
                                                  .spent /
                                              _budgetCategories[_selectedBudgetCategoryIndex]
                                                  .budget,
                                          backgroundColor: Colors.grey
                                              .withOpacity(0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _budgetCategories[_selectedBudgetCategoryIndex]
                                                .color,
                                          ),
                                          minHeight: 8,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '0',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'KES ${_budgetCategories[_selectedBudgetCategoryIndex].budget.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // AI Insights
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AI Insights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToAI,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'More',
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

                      // AI Insights container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Spending Alert
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.warning_rounded,
                                    color: Colors.yellow,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Spending Alert',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _spendingAlertText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: widget.onNavigateToBudget,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: accentColor,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text('Set Budget'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24),
                            Divider(
                              color: Colors.white.withOpacity(0.2),
                              height: 1,
                            ),
                            SizedBox(height: 24),

                            // Savings Opportunity
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Savings Opportunity',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _savingsOpportunityText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Start savings challenge
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: accentColor,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text('Start Challenge'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Smart Money Tips
                      Text(
                        'Smart Money Tips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Smart Money Tips Cards - Horizontal scroll
                      SizedBox(
                        height: 180,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          children: [
                            _buildSmartTipCard(
                              icon: Icons.savings,
                              title: 'Save 20% of your income',
                              content:
                                  'The 50/30/20 rule suggests saving 20% of your income for financial goals.',
                              color: accentColor,
                            ),
                            _buildSmartTipCard(
                              icon: Icons.track_changes,
                              title: 'Track all expenses',
                              content:
                                  'People who track expenses save 15% more than those who don\'t.',
                              color: Colors.purple,
                            ),
                            _buildSmartTipCard(
                              icon: Icons.credit_card,
                              title: 'Pay off high-interest debt first',
                              content:
                                  'Focus on clearing debts with the highest interest rates to save money long-term.',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 100,
                ), // Bottom padding for navigation bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateManualBalance(String value) {
    setState(() {
      _isEditingBalance = false;
    });

    // Parse the input and update balance service
    try {
      // Remove commas and convert to double
      final cleanValue = value.replaceAll(',', '');
      final newBalance = double.parse(cleanValue);

      if (newBalance > 0) {
        BalanceService.instance.setBalance(newBalance, DateTime.now());
      }
    } catch (e) {
      print('Error updating manual balance: $e');
      // Reset to previous value
      _balanceController.text = NumberFormat(
        '#,##0',
        'en_US',
      ).format(_currentBalance.round());
    }
  }

  String _calculateTotalExpenses() {
    double total = 0;
    for (final transaction in _recentTransactions) {
      if (transaction.amount < 0) {
        total += transaction.amount.abs();
      }
    }
    return NumberFormat('#,##0', 'en_US').format(total.round());
  }

  String _calculateTotalIncome() {
    double total = 0;
    for (final transaction in _recentTransactions) {
      if (transaction.amount > 0) {
        total += transaction.amount;
      }
    }
    return NumberFormat('#,##0', 'en_US').format(total.round());
  }

  List<double> _getWeeklySpendingData() {
    // Get data for the last 7 days
    final List<double> data = List.generate(7, (index) => 0);
    final now = DateTime.now();

    for (final transaction in _recentTransactions) {
      if (transaction.amount < 0) {
        // Only expenses
        final daysDifference = now.difference(transaction.date).inDays;
        if (daysDifference < 7) {
          data[6 - daysDifference] += transaction.amount.abs();
        }
      }
    }

    return data;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
      case 'utilities':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'transfer':
        return Icons.swap_horiz;
      case 'income':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Colors.orange;
      case 'transport':
      case 'transportation':
        return Colors.blue;
      case 'shopping':
        return Colors.teal;
      case 'bills':
      case 'utilities':
        return Colors.red;
      case 'entertainment':
        return Colors.purple;
      case 'health':
        return Colors.pink;
      case 'education':
        return Colors.indigo;
      case 'travel':
        return Colors.amber;
      case 'transfer':
        return Colors.green;
      case 'income':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSavingsIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'bank':
      case 'account_balance':
        return Icons.account_balance;
      case 'laptop':
      case 'computer':
        return Icons.laptop_mac;
      case 'car':
      case 'vehicle':
        return Icons.directions_car;
      case 'house':
      case 'home':
        return Icons.home;
      case 'beach':
      case 'holiday':
      case 'vacation':
        return Icons.beach_access;
      case 'education':
      case 'school':
        return Icons.school;
      case 'wedding':
      case 'ring':
        return Icons.favorite;
      case 'baby':
      case 'child':
        return Icons.child_care;
      default:
        return Icons.savings;
    }
  }

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
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 12),
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
              SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(String category, Color color, String percentage) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Text(
            category,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int currentAmount,
    required int targetAmount,
    required Color color,
    required double progress,
  }) {
    final formattedCurrentAmount = NumberFormat(
      '#,##0',
      'en_US',
    ).format(currentAmount);
    final formattedTargetAmount = NumberFormat(
      '#,##0',
      'en_US',
    ).format(targetAmount);
    final percentComplete = (progress * 100).toStringAsFixed(0);

    return Container(
      width: 230,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text(
                'KES $formattedCurrentAmount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                ' / $formattedTargetAmount',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$percentComplete% completed',
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
    bool isExpense = amount < 0;
    final formattedAmount = NumberFormat('#,##0', 'en_US').format(amount.abs());

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo/Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: logoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  logo,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(logoPlaceholder, color: logoColor, size: 24),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: logoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
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
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'} KES $formattedAmount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(
                isExpense ? 'Expense' : 'Income',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTipCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: 240,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: color),
              SizedBox(width: 4),
              Text(
                'AI Generated',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsState() {
    return Container(
      height: 200,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // You can use Lottie animation here
          Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySavingsState() {
    return Container(
      height: 170,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // You can use Lottie animation here
          Icon(Icons.savings, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No savings goals yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a savings goal to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBudgetState() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: EdgeInsets.all(24),
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
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // You can use Lottie animation here
          Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No budgets yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a budget to track your spending',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onNavigateToBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF26D07C),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Create Budget'),
          ),
        ],
      ),
    );
  }
}

// ============================ CUSTOM WIDGETS ============================

class PieChartPainter extends CustomPainter {
  final Map<String, double> categoryPercentages;

  PieChartPainter({required this.categoryPercentages});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Define the list of categories with their colors
    final List<MapEntry<String, double>> sortedCategories =
        categoryPercentages.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate the total if not 100%
    final totalPercentage = sortedCategories.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );

    double startAngle = 0;
    double sweepAngle;

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final Color color = _getCategoryColor(entry.key);

      // Calculate the sweep angle based on the percentage
      sweepAngle = (entry.value / totalPercentage) * 2 * math.pi;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      // Draw the pie slice
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Update the start angle for the next slice
      startAngle += sweepAngle;
    }

    // Draw a smaller white circle in the center for the donut effect
    final innerCirclePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    canvas.drawCircle(center, radius * 0.6, innerCirclePaint);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.teal;
      case 'bills':
        return Colors.red;
      case 'others':
        return Colors.purple;
      case 'entertainment':
        return Colors.pink;
      case 'health':
        return Colors.indigo;
      case 'education':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class SpendingBarChart extends StatelessWidget {
  final List<double> weeklyData;

  const SpendingBarChart({Key? key, required this.weeklyData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth / 12;
        final spacing = (constraints.maxWidth - (barWidth * 7)) / 8;

        // Find the maximum value for scaling
        final maxValue = weeklyData.reduce(
          (curr, next) => curr > next ? curr : next,
        );

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 7; i++)
                    _buildDayBar(
                      value: weeklyData[i],
                      maxValue: maxValue,
                      barWidth: barWidth,
                      maxHeight: constraints.maxHeight * 0.7,
                      isHighlighted: i == 4, // Friday is highlighted
                      highlightedValue: i == 4 ? 'KES 2,500' : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDayLabel('Mon'),
                _buildDayLabel('Tue'),
                _buildDayLabel('Wed'),
                _buildDayLabel('Thu'),
                _buildDayLabel('Fri'),
                _buildDayLabel('Sat'),
                _buildDayLabel('Sun'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayBar({
    required double value,
    required double maxValue,
    required double barWidth,
    required double maxHeight,
    required bool isHighlighted,
    String? highlightedValue,
  }) {
    double heightPercentage = maxValue > 0 ? value / maxValue : 0;
    double height = maxHeight * heightPercentage;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isHighlighted && highlightedValue != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              highlightedValue,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF26D07C),
              ),
            ),
          ),
        Container(
          width: barWidth,
          height: height > 0 ? height : 5,
          decoration: BoxDecoration(
            color: isHighlighted
                ? Color(0xFF26D07C)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(6),
              bottom: Radius.circular(value > 0 ? 0 : 6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabel(String day) {
    return Text(day, style: TextStyle(fontSize: 12, color: Colors.grey[600]));
  }
}

class BudgetBarChart extends StatelessWidget {
  final List<double> dailyData;
  final Color color;

  const BudgetBarChart({Key? key, required this.dailyData, required this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth / 14;

        // Find the maximum value for scaling
        final maxValue = dailyData.reduce(
          (curr, next) => curr > next ? curr : next,
        );

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 0; i < dailyData.length; i++)
                    _buildBudgetBar(
                      value: dailyData[i],
                      maxValue: maxValue,
                      barWidth: barWidth,
                      maxHeight: constraints.maxHeight * 0.7,
                      color: color,
                      displayValue: 'KES ${dailyData[i].toInt()}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDayLabel('Mon'),
                _buildDayLabel('Tue'),
                _buildDayLabel('Wed'),
                _buildDayLabel('Thu'),
                _buildDayLabel('Fri'),
                _buildDayLabel('Sat'),
                _buildDayLabel('Sun'),
              ],
            ),
            const SizedBox(height: 16),
            // Daily Spending label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daily Spending - This Week',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetBar({
    required double value,
    required double maxValue,
    required double barWidth,
    required double maxHeight,
    required Color color,
    required String displayValue,
  }) {
    // Ensure we have a minimum bar height for aesthetic purposes
    double heightPercentage = maxValue > 0 ? value / maxValue : 0;
    double height = maxHeight * heightPercentage;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        Container(
          width: barWidth,
          height: height > 0 ? height : 5,
          decoration: BoxDecoration(
            color: value > 0 ? color : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(6),
              bottom: Radius.circular(value > 0 ? 0 : 6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabel(String day) {
    return Text(day, style: TextStyle(fontSize: 12, color: Colors.grey[600]));
  }
}

// ============================ MODELS ============================

class BudgetCategory {
  final String name;
  final IconData icon;
  final Color color;
  final double spent;
  final double budget;
  final List<double> dailyData;

  BudgetCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.spent,
    required this.budget,
    required this.dailyData,
  });
}
