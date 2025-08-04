// lib/screens/home_screen.dart
import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:dailydime/screens/profile_screen.dart';
import 'package:dailydime/screens/settings_screen.dart';
import 'package:dailydime/screens/tools_screen.dart';
import 'package:dailydime/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/screens/mpesa_screen.dart';
import 'package:dailydime/services/balance_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/services/home_ai_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/screens/notifications_screen.dart';
import 'package:dailydime/services/app_notification_service.dart';
import 'package:dailydime/services/expense_service.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/models/budget.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:dailydime/services/profile_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:appwrite/models.dart';
import '../services/budget_graph_service.dart';
import '../services/budget_graph_service.dart' show BudgetCategory;


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
        late ProfileService _profileService;
  User? _currentUser;
  Document? _userProfile;
  String? _profileImageUrl;
  String? _profileImageId;
  bool _imageError = false;
  bool _isLoadingProfile = false;
  ExpenseService? _expenseService;
List<ExpenseAnalytics> _expenseAnalytics = [];
List<MonthlyExpenseData> _monthlyExpenseData = [];
bool _isLoadingExpenseData = false;
StreamSubscription<List<ExpenseAnalytics>>? _expenseAnalyticsSubscription;

StreamSubscription<Transaction>? _smsTransactionSubscription;
bool _isLoadingTransactions = false;
late BudgetGraphService _budgetGraphService;
List<BudgetCategory> _budgetCategories = [];
bool _isLoadingBudgets = true;
int _selectedBudgetCategoryIndex = 0;
  // Controllers
  late TabController _tabController;
  final TextEditingController _balanceController = TextEditingController();
  late AppNotificationService _notificationService;
int _unreadNotificationCount = 0;
StreamSubscription? _notificationSubscription;

  late ThemeService themeService;

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

  // Service data
  double _currentBalance = 0.0;
  String _lastUpdateTime = '';
  List<Transaction> _recentTransactions = [];
  List<SavingsGoal> _savingsGoals = [];
  // List<BudgetCategory> _budgetCategories = [];
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
    themeService = Provider.of<ThemeService>(context, listen: false);
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize data
    _initializeData();
  _initializeNotifications();
  _loadUserProfile();
  _initializeExpenseService();
   _budgetGraphService = BudgetGraphService();
  _loadBudgetData();
  }

  Future<void> _initializeExpenseService() async {
  try {
    _expenseService = ExpenseService();
    await _expenseService!.initialize();
    
    // Listen to expense analytics stream
    _expenseAnalyticsSubscription = _expenseService!.analyticsStream.listen((analytics) {
      if (mounted) {
        setState(() {
          _expenseAnalytics = analytics;
          _isLoadingExpenseData = false;
        });
      }
    });

    // Listen to monthly data stream
    _expenseService!.monthlyDataStream.listen((monthlyData) {
      if (mounted) {
        setState(() {
          _monthlyExpenseData = monthlyData;
        });
      }
    });

    setState(() {
      _isLoadingExpenseData = true;
    });
    
    // Generate initial analytics
    await _expenseService!.refreshData();
  } catch (e) {
    print('Error initializing expense service: $e');
    setState(() {
      _isLoadingExpenseData = false;
    });
  }
}

Future<void> _loadBudgetData() async {
  setState(() {
    _isLoadingBudgets = true;
  });
  
  try {
    // Initialize Appwrite client
    final client = Client()
      ..setEndpoint(AppConfig.appwriteEndpoint)
      ..setProject(AppConfig.appwriteProjectId);
    
    final databases = Databases(client);
    
    // Get current user ID from AppwriteService
    final AppwriteService appwriteService = AppwriteService();
    final currentUser = await appwriteService.getCurrentUser();
    final String userId = currentUser?.$id ?? '';
    
    print('Loading budget data for user: $userId');
    
    // Query budgets from Appwrite
    final response = await databases.listDocuments(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.budgetsCollection,
      queries: [
        // Add user filter if you have user_id field in your budget documents
        // Query.equal('user_id', userId),
      ],
    );
    
    print('Budget documents found: ${response.documents.length}');
    
    // Convert documents to map format with proper data handling
    List<Map<String, dynamic>> budgetDocs = [];
    
    if (response.documents.isNotEmpty) {
      for (var doc in response.documents) {
        print('Processing document: ${doc.$id}');
        print('Document data: ${doc.data}');
        
        // Create a clean map with the document data
        Map<String, dynamic> budgetDoc = {
          '\$id': doc.$id,
          'created_at': doc.$createdAt,
          'updated_at': doc.$updatedAt,
        };
        
        // Add all document data, handling nulls properly
        doc.data.forEach((key, value) {
          budgetDoc[key] = value;
        });
        
        // Set default values for missing required fields
        budgetDoc['title'] ??= 'Budget ${budgetDocs.length + 1}';
        budgetDoc['total_amount'] ??= 0.0;
        budgetDoc['spent_amount'] ??= 0.0;
        budgetDoc['categories'] ??= [];
        budgetDoc['period_type'] ??= 'monthly';
        
        // Handle date fields
        budgetDoc['start_date'] ??= DateTime.now().subtract(Duration(days: 30)).toIso8601String();
        budgetDoc['end_date'] ??= DateTime.now().add(Duration(days: 30)).toIso8601String();
        
        budgetDocs.add(budgetDoc);
        
        print('Processed budget document: ${budgetDoc['title']} - Total: ${budgetDoc['total_amount']}, Spent: ${budgetDoc['spent_amount']}');
      }
    }
    
    // If no real budgets exist or they're all empty, add some test data
    if (budgetDocs.isEmpty || budgetDocs.every((doc) => 
        (doc['total_amount'] == null || doc['total_amount'] == 0) && 
        (doc['spent_amount'] == null || doc['spent_amount'] == 0))) {
      
      print('No valid budgets found, creating test data');
      
      // Create test budget data based on your existing budget structure
      budgetDocs.addAll([
        {
          '\$id': 'test_food_budget',
          'title': 'Food & Dining',
          'total_amount': 15000.0,
          'spent_amount': 8500.0,
          'categories': ['food', 'dining'],
          'period_type': 'monthly',
          'start_date': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          'end_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          '\$id': 'test_transport_budget',
          'title': 'Transportation',
          'total_amount': 10000.0,
          'spent_amount': 6200.0,
          'categories': ['transport', 'fuel'],
          'period_type': 'monthly',
          'start_date': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          'end_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ]);
    }
    
    print('Processing ${budgetDocs.length} budget documents with BudgetGraphService');
    
    // Process budget data with the service
    final budgetCategories = await _budgetGraphService.processBudgetData(budgetDocs);
    
    print('Processed budget categories: ${budgetCategories.length}');
    
    setState(() {
      _budgetCategories = budgetCategories;
      _isLoadingBudgets = false;
      // Ensure selected index is valid
      if (_budgetCategories.isNotEmpty && _selectedBudgetCategoryIndex >= _budgetCategories.length) {
        _selectedBudgetCategoryIndex = 0;
      }
    });
    
    // Debug output
    if (_budgetCategories.isNotEmpty) {
      final selected = _budgetCategories[_selectedBudgetCategoryIndex];
      print('Selected budget: ${selected.name}');
      print('Daily data: ${selected.dailyData}');
      print('Spent: ${selected.spent}, Budget: ${selected.budget}');
      
      // Check for any NaN values
      bool hasNaN = selected.dailyData.any((value) => value.isNaN);
      if (hasNaN) {
        print('WARNING: NaN values detected in daily data!');
      }
    }
    
  } catch (e, stackTrace) {
    print('Error loading budget data: $e');
    print('Stack trace: $stackTrace');
    
    setState(() {
      _isLoadingBudgets = false;
    });
    
    // Show error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load budget data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
   Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final AppwriteService appwrite = AppwriteService();
      
      // Get current user
      _currentUser = await appwrite.getCurrentUser();
      
      if (_currentUser != null) {
        // Get user profile
        _userProfile = await appwrite.getUserProfile(_currentUser!.$id);
        
        // Load profile image
        await _loadProfileImage();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    if (_userProfile != null &&
        _userProfile!.data.containsKey('profileImageId') &&
        _userProfile!.data['profileImageId'] != null) {
      try {
        _profileImageId = _userProfile!.data['profileImageId'];
        
        // Generate the image URL with proper encoding and no cache-busting for now
        _profileImageUrl = '${AppConfig.appwriteEndpoint}/storage/buckets/${AppConfig.mainBucket}/files/$_profileImageId/view?project=${AppConfig.appwriteProjectId}&mode=admin';
        
        print('Profile image URL: $_profileImageUrl');
        _imageError = false;
        
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Error loading profile image: $e');
        _imageError = true;
        _profileImageUrl = null;
        
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      _profileImageUrl = null;
      _profileImageId = null;
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initializeNotifications() async {
  try {
    _notificationService = AppNotificationService();
    await _notificationService.initialize();
    
    // Listen to notification count changes
    _notificationSubscription = _notificationService.notificationsStream.listen((notifications) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = _notificationService.unreadCount;
        });
      }
    });

    // Get initial count
    setState(() {
      _unreadNotificationCount = _notificationService.unreadCount;
    });
  } catch (e) {
    print('Error initializing notifications: $e');
  }
}

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize balance service
      await BalanceService.instance.initialize();
      await _loadUserProfile();

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

      // Get initial balance - await the Future
      _currentBalance = await BalanceService.instance.getCurrentBalance();
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
    _currentBalance = 0.0;
    _balanceController.text = '00';
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
  setState(() {
    _isLoadingTransactions = true;
  });

  try {
    // Initialize SMS Service
    final smsService = SmsService();
    await smsService.initialize();

    // Get recent transactions from local storage (populated by SMS service)
    final transactions = await StorageService.instance.getTransactions();
    
    // Sort by date (newest first) and take the most recent ones
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      _recentTransactions = transactions.take(10).toList();
      _isLoadingTransactions = false;
    });

    // Listen to new SMS transactions in real-time
    _smsTransactionSubscription?.cancel();
    _smsTransactionSubscription = smsService.transactionStream.listen((newTransaction) {
      if (mounted) {
        setState(() {
          // Add new transaction to the beginning of the list
          _recentTransactions.insert(0, newTransaction);
          
          // Keep only the most recent 10 transactions
          if (_recentTransactions.length > 10) {
            _recentTransactions = _recentTransactions.take(10).toList();
          }
        });
      }
    });

  } catch (e) {
    print('Error loading recent transactions from SMS: $e');
    setState(() {
      _recentTransactions = [];
      _isLoadingTransactions = false;
    });
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

    // Create a simplified budget map for AI processing instead of Budget objects
    final List<Map<String, dynamic>> budgetMaps = _budgetCategories
        .map((b) => {
              'id': '',
              'title': b.name,
              'category': b.name,
              'spent': b.spent.toDouble(),
              'amount': b.budget.toDouble(),
              'period': 'monthly', // Simple string instead of enum
              'startDate': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
              'endDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
              'createdAt': DateTime.now().toIso8601String(),
            })
        .toList();

    // Generate savings opportunity with maps instead of Budget objects
    final savingsInsight = await aiService.generateSavingsOpportunityFromMaps(
      _recentTransactions,
      budgetMaps,
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
    _notificationSubscription?.cancel();
    _expenseAnalyticsSubscription?.cancel();
    _smsTransactionSubscription?.cancel();
    super.dispose();
  }

  void _showAddMoneyBottomSheet(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: themeService.cardColor,
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
                  color: themeService.subtextColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Add Money',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),

                  SizedBox(height: 16),

                  TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: themeService.textColor),
                    decoration: InputDecoration(
                      labelText: 'Amount (KES)',
                      labelStyle: TextStyle(color: themeService.subtextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: themeService.primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  TextField(
                    style: TextStyle(color: themeService.textColor),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: themeService.subtextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.description,
                        color: themeService.primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.primaryColor,
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
  Widget _buildProfileAvatar() {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(),
        ),
      );
    },
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: themeService.primaryColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: themeService.isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11), // Slightly smaller to show border
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: _isLoadingProfile
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeService.primaryColor.withOpacity(0.1),
                        themeService.primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeService.primaryColor,
                        ),
                      ),
                    ),
                  ),
                )
              : _profileImageUrl != null && !_imageError
                  ? CachedNetworkImage(
                      imageUrl: _profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeService.primaryColor.withOpacity(0.1),
                              themeService.primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeService.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('Error loading profile image: $error');
                        return _buildDefaultAvatar();
                      },
                    )
                  : _buildDefaultAvatar(),
        ),
      ),
    ),
  );
}

Widget _buildDefaultAvatar() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          themeService.primaryColor.withOpacity(0.15),
          themeService.primaryColor.withOpacity(0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(
      Icons.person_outline,
      size: 24,
      color: themeService.primaryColor,
    ),
  );
}

  Widget _buildTopUpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: themeService.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: themeService.subtextColor, fontSize: 14),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: themeService.subtextColor,
        ),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = Provider.of<ThemeService>(context);
    final size = MediaQuery.of(context).size;
    final accentColor = themeService.primaryColor;
    final bool isSmallScreen = size.width < 380;

    // Set status bar to match theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: themeService.scaffoldColor,
        statusBarIconBrightness: themeService.isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: themeService.scaffoldColor,
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
                style: TextStyle(
                  color: themeService.subtextColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeService.scaffoldColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _initializeData,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header - Theme aware bar
                Container(
                  color: themeService.scaffoldColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Icon on the left
                      _buildProfileAvatar(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: themeService.isDarkMode
                                    ? Colors.black.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          // child: Icon(
                          //   Icons.person_outline,
                          //   size: 24,
                          //   color: themeService.textColor,
                          // ),
                        ),
                      ),

                      // Right side icons (Notification and Settings)
                      Row(
                        children: [
                          // Notification Icon
                        GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(),
      ),
    );
  },
  child: Container(
    margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: themeService.isDarkMode
          ? Colors.white.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: themeService.isDarkMode
              ? Colors.black.withOpacity(0.1)
              : Colors.black.withOpacity(0.03),
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
          color: themeService.textColor,
        ),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: themeService.scaffoldColor,
                  width: 1.5,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    ),
  ),
                          ),
                          // Settings Icon
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: themeService.isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeService.isDarkMode
                                        ? Colors.black.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.settings_outlined,
                                size: 24,
                                color: themeService.textColor,
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
                                      iconColor: themeService.errorColor,
                                      bgColor: themeService.surfaceColor
                                          .withOpacity(0.2),
                                      iconBgColor: themeService.errorColor
                                          .withOpacity(0.2),
                                      title: 'Expense',
                                      amount:
                                          'KES ${_calculateTotalExpenses()}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildWalletStatItem(
                                      icon: Icons.arrow_downward_rounded,
                                      iconColor: themeService.textColor,
                                      bgColor: themeService.surfaceColor
                                          .withOpacity(0.2),
                                      iconBgColor: themeService.surfaceColor
                                          .withOpacity(0.2),
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
                          color: themeService.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: themeService.subtextColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.isDarkMode
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.02),
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
                                    iconColor: themeService.accentColor,
                                    label: 'Top up',
                                    onTap: () {
                                      _showAddMoneyBottomSheet(context);
                                    },
                                  ),
                                  _buildQuickAction(
                                    context,
                                    iconData: Icons.lightbulb,
                                    iconColor: themeService.successColor,
                                    label: 'Smart Tools',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ToolsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildQuickAction(
                                    context,
                                    iconData: Icons.savings,
                                    iconColor: themeService.warningColor,
                                    label: 'Savings',
                                    onTap: widget.onNavigateToSavings ?? () {},
                                  ),
                                  _buildQuickAction(
                                    context,
                                    iconData: Icons.pie_chart,
                                    iconColor: themeService.errorColor,
                                    label: 'Budget',
                                    onTap: widget.onNavigateToBudget ?? () {},
                                  ),
                                  _buildQuickAction(
                                    context,
                                    iconData: Icons.auto_awesome,
                                    iconColor: themeService.secondaryColor,
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
                                  iconColor: themeService.accentColor,
                                  label: 'Top up',
                                  onTap: () {
                                    _showAddMoneyBottomSheet(context);
                                  },
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.lightbulb,
                                  iconColor: themeService.successColor,
                                  label: 'Smart Tools',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ToolsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.savings,
                                  iconColor: themeService.warningColor,
                                  label: 'Savings',
                                  onTap: widget.onNavigateToSavings ?? () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.pie_chart,
                                  iconColor: themeService.errorColor,
                                  label: 'Budget',
                                  onTap: widget.onNavigateToBudget ?? () {},
                                ),
                                _buildQuickAction(
                                  context,
                                  iconData: Icons.auto_awesome,
                                  iconColor: themeService.secondaryColor,
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
              color: themeService.textColor,
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
                    color: themeService.subtextColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: themeService.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _showChart ? Icons.bar_chart : Icons.pie_chart,
                    size: 18,
                    color: themeService.accentColor,
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
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeService.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isLoadingExpenseData
          ? Center(
              child: SizedBox(
                height: 220,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(themeService.accentColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing your spending...',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _expenseAnalytics.isEmpty
            ? SizedBox(
                height: 220,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: themeService.subtextColor.withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No spending data available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your spending patterns will appear here as you use your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.subtextColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isLoadingExpenseData = true;
                        });
                        await _expenseService?.refreshData();
                        setState(() {
                          _isLoadingExpenseData = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeService.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Refresh Data'),
                    ),
                  ],
                ),
              )
            : Column(
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
                              painter: ExpensePieChartPainter(
                                analytics: _expenseAnalytics,
                              ),
                              child: Container(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'KES ${NumberFormat('#,##0', 'en_US').format(_expenseAnalytics.fold<double>(0, (sum, item) => sum + item.totalAmount).round())}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeService.textColor,
                                ),
                              ),
                              Text(
                                'Total Expenses',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: themeService.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: _monthlyExpenseData.isEmpty
                        ? Center(
                            child: Text(
                              'No monthly data available',
                              style: TextStyle(
                                color: themeService.subtextColor,
                              ),
                            ),
                          )
                        : ExpenseBarChart(
                            monthlyData: _monthlyExpenseData,
                            barColor: themeService.accentColor,
                            labelColor: themeService.subtextColor,
                          ),
                    ),

                  const SizedBox(height: 20),

                  // Expense Categories - Responsive grid/wrap
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _expenseAnalytics.take(5).map((analytics) {
                      return _buildCategoryLegend(
                        analytics.category,
                        analytics.color,
                        '${analytics.percentage.round()}%',
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
                              color: themeService.textColor,
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
                                color: themeService.accentColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'See all',
                                style: TextStyle(
                                  color: themeService.accentColor,
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
              color: themeService.textColor,
            ),
          ),
          Row(
            children: [
              // Refresh button
              GestureDetector(
                onTap: () async {
                  await _loadRecentTransactions();
                  // Also refresh SMS service data
                  final smsService = SmsService();
                  await smsService.refreshTransactions();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: themeService.subtextColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: themeService.accentColor,
                  ),
                ),
              ),
              // See all button
              GestureDetector(
                onTap: widget.onNavigateToTransactions,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeService.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: themeService.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
                      const SizedBox(height: 16),

      // Loading state
      if (_isLoadingTransactions)
        Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeService.accentColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading SMS transactions...',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        )
        
      else if (_recentTransactions.isEmpty)
        _buildEmptyTransactionsState()
      else
        Column(
          children: [
            ..._recentTransactions
                .take(_isExpanded ? 8 : 4) // Show more transactions
                .map(
                  (transaction) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTransactionItem(
                      context,
                      logo: transaction.iconPath ?? 'default_icon_path.png',
                      name: transaction.title,
                      date: DateFormat('dd/MM/yyyy HH:mm').format(transaction.date), // Include time for SMS transactions
                      amount: transaction.amount.toDouble(),
                      logoPlaceholder: _getCategoryIcon(transaction.category),
                      logoColor: _getCategoryColor(transaction.category),
                      category: transaction.category,
                      // Add SMS indicator
                      isSmsTransaction: transaction.isSms,
                      mpesaCode: transaction.mpesaCode,
                    ),
                  ),
                )
                .toList(),

            // Show more/less button if we have enough transactions
            if (_recentTransactions.length > 4)
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: themeService.subtextColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Show less' : 'Show more',
                            style: TextStyle(
                              color: themeService.subtextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: themeService.subtextColor,
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
              color: themeService.textColor,
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
                color: themeService.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'See all',
                style: TextStyle(
                  color: themeService.accentColor,
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
      _isLoadingBudgets
          ? _buildBudgetLoadingState()
          : _budgetCategories.isEmpty
              ? _buildEmptyBudgetState()
              : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          themeService.isDarkMode ? 0.2 : 0.05,
                        ),
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
                              color: themeService.subtextColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: themeService.accentColor
                                  .withOpacity(0.1),
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
                                    color: themeService.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: themeService.accentColor,
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
                                color: themeService.subtextColor
                                    .withOpacity(0.05),
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
                                      color:
                                          themeService.subtextColor,
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
                                          color: themeService
                                              .subtextColor,
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
                                color: themeService.subtextColor
                                    .withOpacity(0.05),
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
                                      color:
                                          themeService.subtextColor,
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
                                          color: themeService
                                              .subtextColor,
                                        ),
                                      ),
                                      Text(
                                        '${_budgetCategories[_selectedBudgetCategoryIndex].budget.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                          color: themeService
                                              .textColor,
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
                                color: themeService.subtextColor
                                    .withOpacity(0.05),
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
                                      color:
                                          themeService.subtextColor,
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
                                          color: themeService
                                              .subtextColor,
                                        ),
                                      ),
                                      Text(
                                        '${(_budgetCategories[_selectedBudgetCategoryIndex].budget - _budgetCategories[_selectedBudgetCategoryIndex].spent).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                          color: themeService
                                              .accentColor,
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
                                  color: themeService.subtextColor,
                                ),
                              ),
                              Text(
                                '${(_budgetCategories[_selectedBudgetCategoryIndex].spent / _budgetCategories[_selectedBudgetCategoryIndex].budget * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: themeService.accentColor,
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
                              backgroundColor: themeService
                                  .subtextColor
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
                                  color: themeService.subtextColor,
                                ),
                              ),
                              Text(
                                'KES ${_budgetCategories[_selectedBudgetCategoryIndex].budget.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.subtextColor,
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
                              color: themeService.textColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToAI,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: themeService.accentColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'More',
                                style: TextStyle(
                                  color: themeService.accentColor,
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
                          color: themeService.primaryColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.accentColor.withOpacity(0.3),
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
                                            foregroundColor:
                                                themeService.accentColor,
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
                                            foregroundColor:
                                                themeService.accentColor,
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
                          color: themeService.textColor,
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
                              color: themeService.accentColor,
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
  Widget _buildBudgetLoadingState() {
  return Container(
    height: 200,
    width: double.infinity,
    padding: EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: themeService.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            themeService.isDarkMode ? 0.2 : 0.05,
          ),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeService.accentColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading budget data...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: themeService.textColor,
            ),
          ),
        ],
      ),
    ),
  );
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
                color: themeService.textColor,
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
              color: themeService.textColor,
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
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              themeService.isDarkMode ? 0.2 : 0.05,
            ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
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
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.subtextColor,
                ),
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
  bool isSmsTransaction = false,
  String? mpesaCode,
}) {
  final themeService = Provider.of<ThemeService>(context);
  final isExpense = amount < 0;
  final displayAmount = amount.abs();
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: themeService.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: themeService.isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        // Transaction icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: logoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            logoPlaceholder,
            color: logoColor,
            size: 24,
          ),
        ),

        const SizedBox(width: 16),

        // Transaction details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // SMS indicator
                  if (isSmsTransaction)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SMS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeService.subtextColor,
                    ),
                  ),
                  if (mpesaCode != null) ...[
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.subtextColor,
                      ),
                    ),
                    Text(
                      mpesaCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.subtextColor,
                ),
              ),
            ],
          ),
        ),

        // Amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '-' : '+'}KES ${NumberFormat('#,##0', 'en_US').format(displayAmount.round())}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isExpense 
                    ? themeService.errorColor 
                    : themeService.successColor,
              ),
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
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              themeService.isDarkMode ? 0.2 : 0.05,
            ),
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
                color: themeService.textColor,
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
  final themeService = Provider.of<ThemeService>(context);
  
  return Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: themeService.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: themeService.isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(
          Icons.sms_outlined,
          size: 64,
          color: themeService.subtextColor.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'No SMS Transactions Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeService.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your M-Pesa transactions will appear here automatically when SMS messages are received.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: themeService.subtextColor,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () async {
            setState(() {
              _isLoadingTransactions = true;
            });
            final smsService = SmsService();
            await smsService.initialize();
            await smsService.loadHistoricalMpesaMessages();
            await _loadRecentTransactions();
          },
          icon: Icon(Icons.refresh, size: 18),
          label: Text('Scan SMS Messages'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
          Icon(Icons.savings, size: 48, color: themeService.subtextColor),
          SizedBox(height: 16),
          Text(
            'No savings goals yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a savings goal to get started',
            style: TextStyle(fontSize: 14, color: themeService.subtextColor),
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
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              themeService.isDarkMode ? 0.2 : 0.05,
            ),
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
          Icon(Icons.pie_chart, size: 48, color: themeService.subtextColor),
          SizedBox(height: 16),
          Text(
            'No budgets yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a budget to track your spending',
            style: TextStyle(fontSize: 14, color: themeService.subtextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onNavigateToBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.primaryColor,
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

class ExpensePieChartPainter extends CustomPainter {
  final List<ExpenseAnalytics> analytics;

  ExpensePieChartPainter({required this.analytics});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double strokeWidth = radius * 0.2;
    
    // Calculate total amount
    final double total = analytics.fold<double>(0, (sum, item) => sum + item.totalAmount);
    
    // Start from the top (negative y-axis)
    double startAngle = -math.pi / 2;
    
    for (var analytics in this.analytics) {
      // Skip items with zero or negative amounts
      if (analytics.totalAmount <= 0) continue;
      
      // Calculate the sweep angle based on the percentage
      final double sweepAngle = (analytics.totalAmount / total) * 2 * math.pi;
      
      // Create the paint for this segment
      final Paint segmentPaint = Paint()
        ..color = analytics.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      // Draw the arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );
      
      // Update the start angle for the next segment
      startAngle += sweepAngle;
    }
    
    // Draw inner circle
    final Paint innerCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius - strokeWidth, innerCirclePaint);
  }

  @override
  bool shouldRepaint(ExpensePieChartPainter oldDelegate) {
    return oldDelegate.analytics != analytics;
  }
}

// Expense Bar Chart Widget
class ExpenseBarChart extends StatelessWidget {
  final List<MonthlyExpenseData> monthlyData;
  final Color barColor;
  final Color labelColor;
  
  const ExpenseBarChart({
    Key? key,
    required this.monthlyData,
    required this.barColor,
    required this.labelColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Find maximum value for scaling
    double maxValue = monthlyData.fold<double>(0, (max, data) => math.max(max, data.amount));
    if (maxValue == 0) maxValue = 1; // Avoid division by zero
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: monthlyData.take(6).map((data) {
          // Calculate bar height (maximum height is 180)
          double height = (data.amount / maxValue) * 180;
          if (height < 2 && data.amount > 0) height = 2; // Minimum visible height
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Amount label
              if (data.amount > 0)
                Text(
                  '${(data.amount / 1000).toStringAsFixed(1)}k',
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                SizedBox(height: 14),
                
              const SizedBox(height: 4),
              
              // Bar
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: barColor.withOpacity(data.amount > 0 ? 0.7 : 0.15),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  boxShadow: data.amount > 0 ? [
                    BoxShadow(
                      color: barColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Month label
              Text(
                data.month,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
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