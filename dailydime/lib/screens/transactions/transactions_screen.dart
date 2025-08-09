// lib/screens/transactions/transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/providers/transaction_provider.dart';
import 'package:dailydime/providers/budget_provider.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/services/transaction_ai_service.dart';
import 'package:dailydime/services/expense_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:lottie/lottie.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:dailydime/services/appwrite_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: AppConfig.currencySymbol, decimalDigits: 2);
  
  bool _isScrolled = false;
  bool _isSearchExpanded = false;
  bool _isLoadingInsights = false;
  List<String> _insights = [];
  String _selectedCategory = 'All';
  String _selectedTimeFrame = 'This Week';
  List<String> _searchSuggestions = [];
  
  // Filter variables
  RangeValues _amountRange = const RangeValues(0, 100000);
  double _maxPossibleAmount = 100000;
  DateTimeRange? _dateRange;
  bool _showOnlyRecurring = false;

  // Weekly spending summary data
  double _weeklyTotal = 0;
  double _weeklyBudget = 5000; // Default value
  double _weeklyRemaining = 0;
  double _weeklyPercentage = 0;

  // Spending breakdown
  Map<String, double> _categorySpending = {};
  List<Color> _categoryColors = [];

  // View variables
  bool _isGridView = false;
  bool _showAnalytics = true;
  
  // Budget selection
  List<Budget> _userBudgets = [];
  Budget? _selectedBudget;
  bool _isLoadingBudgets = true;

  // AI assistance
  String _aiRecommendation = '';
  bool _isLoadingRecommendation = false;

  final ExpenseService _expenseService = ExpenseService();
  final AppwriteService _appwriteService = AppwriteService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);

    // Initialize provider and load transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.initialize();
      _loadUserBudgets();
      _expenseService.initialize();
    });

    // Listen for search input changes
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty) {
        _updateSearchSuggestions(_searchController.text);
      } else {
        setState(() {
          _searchSuggestions = [];
        });
      }
    });
  }

  Future<void> _loadUserBudgets() async {
    setState(() {
      _isLoadingBudgets = true;
    });

    try {
      final databases = Databases(_appwriteService.client);
      final response = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
      );

      List<Budget> budgets = [];
      
      for (var doc in response.documents) {
        try {
          Map<String, dynamic> data = doc.data;
          
          // Convert the Appwrite document to our Budget model
          budgets.add(Budget(
            id: doc.$id,
            title: data['title'] ?? 'Unnamed Budget',
            category: data['category'] ?? 'General',
            amount: (data['total_amount'] ?? 0) / 100, // Converting cents to currency
            spent: (data['spent_amount'] ?? 0) / 100, // Converting cents to currency
            period: _getPeriodFromString(data['period_type'] ?? 'monthly'),
            startDate: DateTime.parse(data['start_date'] ?? DateTime.now().toIso8601String()),
            endDate: DateTime.parse(data['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
            color: Colors.primaries[budgets.length % Colors.primaries.length],
            icon: Icons.account_balance_wallet,
          ));
        } catch (e) {
          debugPrint('Error parsing budget: $e');
        }
      }

      setState(() {
        _userBudgets = budgets;
        if (budgets.isNotEmpty) {
          _selectedBudget = budgets.first;
          _updateWeeklySummaryFromBudget(_selectedBudget!);
        }
        _isLoadingBudgets = false;
      });
    } catch (e) {
      debugPrint('Error loading budgets: $e');
      setState(() {
        _isLoadingBudgets = false;
      });
    }
  }

  BudgetPeriod _getPeriodFromString(String periodStr) {
    switch (periodStr.toLowerCase()) {
      case 'daily':
        return BudgetPeriod.daily;
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'yearly':
        return BudgetPeriod.yearly;
      case 'monthly':
      default:
        return BudgetPeriod.monthly;
    }
  }

  void _updateWeeklySummaryFromBudget(Budget budget) {
    double budgetAmount = budget.amount;
    
    // If it's a monthly budget, calculate weekly equivalent
    if (budget.period == BudgetPeriod.monthly) {
      budgetAmount = budget.amount / 4.35; // Average weeks in a month
    } else if (budget.period == BudgetPeriod.yearly) {
      budgetAmount = budget.amount / 52; // Weeks in a year
    } else if (budget.period == BudgetPeriod.daily) {
      budgetAmount = budget.amount * 7; // Convert daily to weekly
    }
    
    setState(() {
      _weeklyBudget = budgetAmount;
      _calculateWeeklySummary(
        Provider.of<TransactionProvider>(context, listen: false).filteredTransactions
      );
      
      // If the budget has personalized AI recommendations, show them
      if (_selectedBudget != null) {
        _getAIRecommendation();
      }
    });
  }
  
  Future<void> _getAIRecommendation() async {
    if (_selectedBudget == null) return;
    
    setState(() {
      _isLoadingRecommendation = true;
    });
    
    try {
      // Get all transactions relevant to this budget
      final transactions = Provider.of<TransactionProvider>(context, listen: false)
          .filteredTransactions
          .where((tx) => tx.category == _selectedBudget!.category)
          .toList();
      
      if (transactions.isEmpty) {
        setState(() {
          _aiRecommendation = "No transactions found for this budget category. Start tracking your spending to get AI insights.";
          _isLoadingRecommendation = false;
        });
        return;
      }
      
      final prompt = '''
      Analyze this budget and transactions data:
      
      Budget: ${_selectedBudget!.title}
      Category: ${_selectedBudget!.category}
      Budget Amount: ${currencyFormat.format(_selectedBudget!.amount)}
      Current Spent: ${currencyFormat.format(_selectedBudget!.spent)}
      Period: ${_selectedBudget!.period.name}
      
      Provide a brief, personalized recommendation to help the user stay within their budget.
      Focus on practical advice based on their spending patterns in this category.
      Keep your response under 200 characters and focus on actionable tips.
      ''';
      
      final result = await TransactionAIService().generateSimpleInsight(prompt);
      
      setState(() {
        _aiRecommendation = result;
        _isLoadingRecommendation = false;
      });
    } catch (e) {
      debugPrint('Error getting AI recommendation: $e');
      setState(() {
        _aiRecommendation = "Unable to generate recommendation at this time.";
        _isLoadingRecommendation = false;
      });
    }
  }

  void _updateSearchSuggestions(String query) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = provider.filteredTransactions;
    
    // Generate suggestions based on transaction titles, categories, and amounts
    final Set<String> suggestions = {};
    
    for (var tx in transactions) {
      if (tx.title.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(tx.title);
      }
      if (tx.category.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(tx.category);
      }
    }
    
    setState(() {
      _searchSuggestions = suggestions.take(5).toList();
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  Future<void> _loadInsights(List<dynamic> transactions) async {
    if (transactions.isEmpty) return;

    setState(() {
      _isLoadingInsights = true;
    });

    try {
      final typedTransactions = transactions.map((tx) => tx as Transaction).toList();
      final result = await TransactionAIService().generateSpendingInsights(
        typedTransactions,
        timeframe: 'week',
      );

      if (result['success'] && result['insights'].isNotEmpty) {
        setState(() {
          _insights = List<String>.from(result['insights']);
          _isLoadingInsights = false;
        });
      } else {
        setState(() {
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
      setState(() {
        _isLoadingInsights = false;
      });
    }
  }

  void _calculateWeeklySummary(List<dynamic> transactions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    double totalSpent = 0;
    
    // Filter transactions by selected budget category if available
    for (var tx in transactions) {
      if (tx.date.isAfter(startOfWeek) && 
          tx.date.isBefore(endOfWeek.add(const Duration(days: 1))) && 
          tx.isExpense &&
          (_selectedBudget == null || tx.category == _selectedBudget!.category)) {
        totalSpent += tx.amount;
      }
    }
    
    setState(() {
      _weeklyTotal = totalSpent;
      _weeklyRemaining = _weeklyBudget - totalSpent;
      _weeklyPercentage = (_weeklyTotal / _weeklyBudget) * 100;
      if (_weeklyPercentage > 100) _weeklyPercentage = 100;
    });
  }

  void _calculateSpendingBreakdown(List<dynamic> transactions) {
    final Map<String, double> categoryTotals = {};
    final Map<String, Color> categoryColorMap = {};
    final List<Color> predefinedColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.red,
      Colors.cyan,
    ];
    
    int colorIndex = 0;
    
    // Get transactions from last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    // Filter by selected budget if available
    final recentTransactions = transactions.where((tx) => 
      tx.date.isAfter(thirtyDaysAgo) && 
      tx.isExpense && 
      (_selectedBudget == null || tx.category == _selectedBudget!.category)
    ).toList();
    
    for (var tx in recentTransactions) {
      if (!categoryTotals.containsKey(tx.category)) {
        categoryTotals[tx.category] = 0;
        categoryColorMap[tx.category] = predefinedColors[colorIndex % predefinedColors.length];
        colorIndex++;
      }
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }
    
    // Sort categories by amount
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Get top 5 categories
    final topCategories = Map<String, double>.fromEntries(
      sortedEntries.take(sortedEntries.length > 5 ? 5 : sortedEntries.length)
    );
    
    // If there are more categories, add "Other"
    if (sortedEntries.length > 5) {
      double otherTotal = 0;
      for (int i = 5; i < sortedEntries.length; i++) {
        otherTotal += sortedEntries[i].value;
      }
      topCategories['Other'] = otherTotal;
      categoryColorMap['Other'] = Colors.grey;
    }
    
    setState(() {
      _categorySpending = topCategories;
      _categoryColors = topCategories.keys.map((category) => categoryColorMap[category]!).toList();
    });
  }

  void _refreshData(List<dynamic> transactions) {
    if (!_isLoadingInsights && transactions.isNotEmpty) {
      if (_insights.isEmpty) {
        _loadInsights(transactions);
      }
      _calculateWeeklySummary(transactions);
      _calculateSpendingBreakdown(transactions);
    }
  }

  void _onBudgetSelected(Budget budget) {
    setState(() {
      _selectedBudget = budget;
      _updateWeeklySummaryFromBudget(budget);
    });
    
    // Refresh data with the new budget selection
    final transactions = Provider.of<TransactionProvider>(context, listen: false).filteredTransactions;
    _refreshData(transactions);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.scaffoldColor,
      // Make the app extend behind the status bar
      extendBodyBehindAppBar: true,
      // Remove the app bar since we're including actions in the header
      appBar: null,
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final isLoading = transactionProvider.isLoading;
          final transactions = transactionProvider.filteredTransactions;
          final balance = transactionProvider.currentBalance;

          // Important: Use post-frame callback to update data after build
          if (!isLoading && transactions.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _refreshData(transactions);
            });
          }

          return Stack(
            children: [
              // Main content
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Search bar (if expanded) - move this before the header
                  if (_isSearchExpanded)
                    SliverToBoxAdapter(
                      child: Container(
                        // Add top padding to account for status bar
                        padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
                        color: themeService.surfaceColor,
                        child: _buildSearchBar(),
                      ),
                    ),
                  
                  // Main content
                  SliverToBoxAdapter(
                    child: !_isSearchExpanded 
                      ? _buildMainContent(transactions, balance, isLoading, themeService)
                      : _buildSearchResults(),
                  ),
                ],
              ),

              // Add Transaction FAB
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTransactionScreen(),
                      ),
                    );
                  },
                  backgroundColor: themeService.primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(List<dynamic> transactions, double balance, bool isLoading, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with balance and actions
        _buildHeader(balance, themeService),

        // Budget selection
        if (_userBudgets.isNotEmpty)
          _buildBudgetSelector(themeService),
        
        // Weekly spending summary
        _buildWeeklySummary(themeService),

        // AI Recommendations from budget
        if (_selectedBudget != null && _aiRecommendation.isNotEmpty)
          _buildAIRecommendationCard(themeService),

        // AI Insights card
        if (_insights.isNotEmpty)
          _buildAIInsightsCard(themeService),

        // Spending Breakdown chart
        if (_showAnalytics && _categorySpending.isNotEmpty)
          _buildSpendingBreakdown(themeService),

        // Tabs & Transactions List
        _buildTabBar(),
        
        _buildTransactionsSection(transactions, isLoading),
      ],
    );
  }

  Widget _buildHeader(double balance, ThemeService themeService) {
    return Container(
      // Add top padding to account for status bar
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        image: const DecorationImage(
          image: AssetImage('assets/images/patter12.png'),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add the app bar actions here since we're extending the header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isSearchExpanded ? Icons.close : Icons.search,
                      color: themeService.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                        if (!_isSearchExpanded) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: themeService.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: themeService.textColor,
                    ),
                    onPressed: () {
                      _showFilterBottomSheet(context);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _showAnalytics ? Icons.insights : Icons.insights_outlined,
                      color: themeService.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showAnalytics = !_showAnalytics;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.subtextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildQuickActionButton(
                    icon: Icons.add,
                    label: 'Add',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTransactionScreen(),
                        ),
                      );
                    },
                    color: themeService.successColor,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    icon: Icons.remove,
                    label: 'Spend',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTransactionScreen(),
                        ),
                      );
                    },
                    color: themeService.errorColor,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSelector(ThemeService themeService) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedBudget = null;
                      // Reset to show all transactions
                      final transactions = Provider.of<TransactionProvider>(context, listen: false).filteredTransactions;
                      _refreshData(transactions);
                    });
                  },
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingBudgets
                ? _buildLoadingBudgets(themeService)
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _userBudgets.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final budget = _userBudgets[index];
                      final isSelected = _selectedBudget?.id == budget.id;
                      
                      return GestureDetector(
                        onTap: () => _onBudgetSelected(budget),
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      themeService.primaryColor,
                                      themeService.primaryColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : themeService.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? themeService.primaryColor
                                  : themeService.accentColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                budget.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : themeService.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    currencyFormat.format(budget.amount),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : themeService.textColor,
                                    ),
                                  ),
                                  Text(
                                    '${(budget.percentageUsed * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : themeService.subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBudgets(ThemeService themeService) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            width: 160,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIRecommendationCard(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor.withOpacity(0.8),
            themeService.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tips_and_updates,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isLoadingRecommendation
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Text(
                    _aiRecommendation,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary(ThemeService themeService) {
    final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final dateRange = '${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd').format(endOfWeek)}';
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor,
            themeService.primaryColor.withBlue(themeService.primaryColor.blue + 20),
          ],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/pattern11.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedBudget != null 
                    ? '${_selectedBudget!.title} Spending'
                    : 'Weekly Spending Summary',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                dateRange,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeeklyInfoColumn(
                'Total Spent',
                currencyFormat.format(_weeklyTotal),
              ),
              _buildWeeklyInfoColumn(
                'Budget',
                currencyFormat.format(_weeklyBudget),
              ),
              _buildWeeklyInfoColumn(
                'Remaining',
                currencyFormat.format(_weeklyRemaining),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_weeklyPercentage.toInt()}% of weekly budget used',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${_weeklyPercentage.toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 
                      (_weeklyPercentage / 100) * 
                      ((MediaQuery.of(context).size.width - 40 - 40) / MediaQuery.of(context).size.width),
                decoration: BoxDecoration(
                  color: _weeklyPercentage > 90 ? Colors.red[300] : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightsCard(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: themeService.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: themeService.warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeService.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _insights.isNotEmpty ? _insights[0] : 'Loading insights...',
            style: TextStyle(
              fontSize: 14,
              color: themeService.subtextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _showAllInsights(themeService);
              },
              child: Text(
                'Get More Tips',
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllInsights(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: themeService.subtextColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeService.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: themeService.warningColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Financial Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: _insights.length,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeService.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: themeService.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: themeService.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _insights[index],
                            style: TextStyle(
                              fontSize: 14,
                              color: themeService.subtextColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSpendingBreakdown(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedBudget != null 
                    ? '${_selectedBudget!.category} Breakdown'
                    : 'Spending Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeService.textColor,
                ),
              ),
              Text(
                'Last 30 Days',
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_categorySpending.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Lottie.asset(
                      'assets/animations/No-Data.json',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No spending data available",
                      style: TextStyle(color: themeService.subtextColor),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _getCategorySections(),
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch events if needed
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Legend
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildLegendItems(themeService),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getCategorySections() {
    if (_categorySpending.isEmpty) return [];
    
    final List<PieChartSectionData> sections = [];
    final totalSpending = _categorySpending.values.fold<double>(0, (sum, value) => sum + value);
    
    if (totalSpending <= 0) return [];
    
    int i = 0;
    for (var entry in _categorySpending.entries) {
      final percentage = (entry.value / totalSpending) * 100;
      
      sections.add(
        PieChartSectionData(
          color: i < _categoryColors.length ? _categoryColors[i] : Colors.grey,
          value: entry.value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      i++;
    }
    
    return sections;
  }

  List<Widget> _buildLegendItems(ThemeService themeService) {
    if (_categorySpending.isEmpty) return [];
    
    final List<Widget> items = [];
    int i = 0;
    
    final totalSpending = _categorySpending.values.fold<double>(0, (sum, value) => sum + value);
    
    if (totalSpending <= 0) return [];
    
    for (var entry in _categorySpending.entries) {
      final percentage = (entry.value / totalSpending) * 100;
      
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: i < _categoryColors.length ? _categoryColors[i] : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeService.subtextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currencyFormat.format(entry.value),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: themeService.textColor,
                ),
              ),
            ],
          ),
        ),
      );
      
      i++;
    }
    
    return items;
  }
  
  Widget _buildTabBar() {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Income'),
          Tab(text: 'Expenses'),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(List<dynamic> transactions, bool isLoading) {
    if (isLoading) {
      return _buildLoadingSkeleton();
    }
    
    // Filter transactions by selected budget if needed
    List<dynamic> filteredTransactions = transactions;
    if (_selectedBudget != null) {
      filteredTransactions = transactions.where((tx) => 
        tx.category == _selectedBudget!.category
      ).toList();
    }
    
    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }
    
    return SizedBox(
      height: 500, // This is intentionally large to allow the list to scroll within the CustomScrollView
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsList(filteredTransactions),
          _buildTransactionsList(filteredTransactions.where((tx) => !tx.isExpense).toList()),
          _buildTransactionsList(filteredTransactions.where((tx) => tx.isExpense).toList()),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final themeService = Provider.of<ThemeService>(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: List.generate(5, (index) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Shimmer.fromColors(
              baseColor: themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeService = Provider.of<ThemeService>(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/notrans.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              _selectedBudget != null
                  ? "No transactions for ${_selectedBudget!.title} budget"
                  : "No transactions yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedBudget != null
                  ? "Start tracking your spending in ${_selectedBudget!.category} category"
                  : "Add your first transaction to start tracking your finances",
              style: TextStyle(
                fontSize: 14,
                color: themeService.subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Add Transaction"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<dynamic> transactions) {
    final themeService = Provider.of<ThemeService>(context);
    
    // Group transactions by date
    Map<String, List<dynamic>> groupedTransactions = {};
    
    for (var tx in transactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      groupedTransactions[dateStr] = groupedTransactions[dateStr] ?? [];
      groupedTransactions[dateStr]!.add(tx);
    }
    
    // Sort dates in descending order
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return _isGridView
        ? _buildGridView(transactions, themeService)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateStr = sortedDates[index];
              final txGroup = groupedTransactions[dateStr]!;
              final date = DateFormat('yyyy-MM-dd').parse(dateStr);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _formatTransactionDate(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                  ),
              ...txGroup.map((tx) => Padding(
  padding: const EdgeInsets.only(bottom: 8.0),
  child: TransactionCard(
    title: tx.title,
    category: tx.category,
    amount: tx.amount,
    date: tx.date,
    isExpense: tx.isExpense,
    icon: tx.icon,
    color: tx.color,
    isSms: tx.isSms,
    onTap: () {
      // Handle transaction tap - navigate to details, edit, etc.
      // Example:
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => TransactionDetailsPage(transaction: tx),
      //   ),
      // );
    },
  ),
)).toList(),
                ],
              );
            },
          );
  }

  Widget _buildGridView(List<dynamic> transactions, ThemeService themeService) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeService.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: tx.isExpense ? themeService.errorColor : themeService.successColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tx.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeService.subtextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tx.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(tx.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.subtextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(tx.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tx.isExpense ? themeService.errorColor : themeService.successColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateToCheck).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Widget _buildSearchBar() {
    final themeService = Provider.of<ThemeService>(context);
    return SizedBox(
      height: 44, // Reduced height
     child: TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
        suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            )
          : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: themeService.isDarkMode ? const Color(0xFF2D3748) : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    ),
    );
  }
  
  Widget _buildSearchResults() {
    final themeService = Provider.of<ThemeService>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    if (_searchController.text.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height - 150,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Enter a search term to find transactions',
            style: TextStyle(
              color: themeService.subtextColor,
            ),
          ),
        ),
      );
    }
    
final query = _searchController.text.toLowerCase();
final transactions = transactionProvider.filteredTransactions.where((tx) {
  return tx.title.toLowerCase().contains(query) ||
         tx.category.toLowerCase().contains(query) ||
         (tx.recipient?.toLowerCase().contains(query) ?? false) ||
         (tx.description?.toLowerCase().contains(query) ?? false) ||
         (tx.sender?.toLowerCase().contains(query) ?? false) ||
         (tx.agent?.toLowerCase().contains(query) ?? false) ||
         (tx.business?.toLowerCase().contains(query) ?? false) ||
         (tx.mpesaCode?.toLowerCase().contains(query) ?? false);
}).toList();
    
    if (transactions.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height - 150,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/notrans.json',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  color: themeService.subtextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Found ${transactions.length} transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
            ),
          ),
          ...transactions.map((tx) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TransactionCard(
    title: tx.title,
    category: tx.category,
    amount: tx.amount,
    date: tx.date,
    isExpense: tx.isExpense,
    icon: tx.icon,
    color: tx.color,
    isSms: tx.isSms,
    onTap: () {
      // Handle transaction tap - navigate to details, edit, etc.
      // Example:
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => TransactionDetailsPage(transaction: tx),
      //   ),
      // );
    },
  ),
)).toList(),

        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: themeService.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: themeService.subtextColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeService.textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _amountRange = const RangeValues(0, 100000);
                              _dateRange = null;
                              _selectedCategory = 'All';
                              _selectedTimeFrame = 'This Week';
                              _showOnlyRecurring = false;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: themeService.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildFilterSection(
                          'Amount Range',
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                RangeSlider(
                                  values: _amountRange,
                                  min: 0,
                                  max: _maxPossibleAmount,
                                  divisions: 20,
                                  labels: RangeLabels(
                                    currencyFormat.format(_amountRange.start),
                                    currencyFormat.format(_amountRange.end),
                                  ),
                                  onChanged: (values) {
                                    setState(() {
                                      _amountRange = values;
                                    });
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currencyFormat.format(_amountRange.start),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeService.subtextColor,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(_amountRange.end),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeService.subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildFilterSection(
                          'Date Range',
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFilterChip(
                                      'This Week',
                                      _selectedTimeFrame == 'This Week',
                                      () {
                                        setState(() {
                                          _selectedTimeFrame = 'This Week';
                                          _dateRange = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFilterChip(
                                      'This Month',
                                      _selectedTimeFrame == 'This Month',
                                      () {
                                        setState(() {
                                          _selectedTimeFrame = 'This Month';
                                          _dateRange = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFilterChip(
                                      'Last 3 Months',
                                      _selectedTimeFrame == 'Last 3 Months',
                                      () {
                                        setState(() {
                                          _selectedTimeFrame = 'Last 3 Months';
                                          _dateRange = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFilterChip(
                                      'Custom',
                                      _selectedTimeFrame == 'Custom',
                                      () async {
                                        final result = await showDateRangePicker(
                                          context: context,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                          initialDateRange: _dateRange,
                                        );
                                        if (result != null) {
                                          setState(() {
                                            _dateRange = result;
                                            _selectedTimeFrame = 'Custom';
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_dateRange != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeService.subtextColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildFilterSection(
                          'Categories',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildFilterChip(
                                'All',
                                _selectedCategory == 'All',
                                () {
                                  setState(() {
                                    _selectedCategory = 'All';
                                  });
                                },
                              ),
                              // Generate more category chips here
                              _buildFilterChip(
                                'Food',
                                _selectedCategory == 'Food',
                                () {
                                  setState(() {
                                    _selectedCategory = 'Food';
                                  });
                                },
                              ),
                              _buildFilterChip(
                                'Transport',
                                _selectedCategory == 'Transport',
                                () {
                                  setState(() {
                                    _selectedCategory = 'Transport';
                                  });
                                },
                              ),
                              _buildFilterChip(
                                'Shopping',
                                _selectedCategory == 'Shopping',
                                () {
                                  setState(() {
                                    _selectedCategory = 'Shopping';
                                  });
                                },
                              ),
                              _buildFilterChip(
                                'Bills',
                                _selectedCategory == 'Bills',
                                () {
                                  setState(() {
                                    _selectedCategory = 'Bills';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        _buildFilterSection(
                          'Other Filters',
                          SwitchListTile(
                            title: Text(
                              'Show only recurring transactions',
                              style: TextStyle(
                                fontSize: 14,
                                color: themeService.textColor,
                              ),
                            ),
                            value: _showOnlyRecurring,
                            onChanged: (value) {
                              setState(() {
                                _showOnlyRecurring = value;
                              });
                            },
                            activeColor: themeService.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        
                        // Implement the actual filtering based on the selected filters
                        // This would typically be done through your TransactionProvider
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeService.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
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
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final themeService = Provider.of<ThemeService>(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeService.primaryColor : themeService.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeService.primaryColor : themeService.subtextColor.withOpacity(0.5)
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : themeService.subtextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}