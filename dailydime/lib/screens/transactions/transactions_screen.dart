// lib/screens/transactions/transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/services/transaction_ai_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dailydime/services/theme_service.dart';

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
  double _weeklyBudget = 5000; // This should come from your budget provider
  double _weeklyRemaining = 0;
  double _weeklyPercentage = 0;

  // Spending breakdown
  Map<String, double> _categorySpending = {};
  List<Color> _categoryColors = [];

  // View variables
  bool _isGridView = false;
  bool _showAnalytics = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);

    // Initialize provider and load transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.initialize();
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
    
    for (var tx in transactions) {
      if (tx.date.isAfter(startOfWeek) && 
          tx.date.isBefore(endOfWeek.add(const Duration(days: 1))) && 
          tx.isExpense) {
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
    final recentTransactions = transactions.where((tx) => 
      tx.date.isAfter(thirtyDaysAgo) && tx.isExpense
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

        // Weekly spending summary
        _buildWeeklySummary(themeService),

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
    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20), // Increased top padding from 40 to 60
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
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
              const Text(
                'Weekly Spending Summary',
                style: TextStyle(
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
                  color: Colors.white,
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
                'Spending Breakdown',
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
                child: Text(
                  "No spending data available",
                  style: TextStyle(color: themeService.subtextColor),
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
    
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }
    
    return SizedBox(
      height: 500, // This is intentionally large to allow the list to scroll within the CustomScrollView
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsList(transactions),
          _buildTransactionsList(transactions.where((tx) => !tx.isExpense).toList()),
          _buildTransactionsList(transactions.where((tx) => tx.isExpense).toList()),
        ],
      ),
    );
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
    if (_searchController.text.isEmpty) {
      return _buildSearchSuggestions();
    }

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final allTransactions = provider.filteredTransactions;
    
    // Filter transactions based on search query
    final filteredTransactions = allTransactions.where((tx) {
      final query = _searchController.text.toLowerCase();
      return tx.title.toLowerCase().contains(query) ||
             tx.category.toLowerCase().contains(query) ||
             (tx.amount.toString().contains(query));
    }).toList();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Text(
                '${filteredTransactions.length} found',
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height - 170, // Adjust based on your header size
          child: _buildTransactionsList(filteredTransactions),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    final themeService = Provider.of<ThemeService>(context);
    // Show recent searches or popular categories
    final categories = [
      'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment',
      'Groceries', 'Health', 'Education', 'Travel', 'Salary'
    ];
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (_searchSuggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
          ..._searchSuggestions.map((suggestion) => ListTile(
            leading: Icon(Icons.history, color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
            title: Text(suggestion, style: TextStyle(color: themeService.textColor)),
            onTap: () {
              _searchController.text = suggestion;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: suggestion.length),
              );
            },
          )),
          const Divider(),
        ],
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) => InkWell(
              onTap: () {
                _searchController.text = category;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: category.length),
                );
              },
              child: Chip(
                label: Text(category),
                backgroundColor: themeService.isDarkMode ? const Color(0xFF2D3748) : Colors.grey.shade100,
                labelStyle: TextStyle(color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            )).toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        const Divider(),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Advanced Search',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
        
        ListTile(
          leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
          title: Text('Search by Date', style: TextStyle(color: themeService.textColor)),
          onTap: () {
            _showDateRangePicker(context);
          },
        ),
        
        ListTile(
          leading: Icon(Icons.monetization_on, color: Theme.of(context).colorScheme.primary),
          title: Text('Search by Amount', style: TextStyle(color: themeService.textColor)),
          onTap: () {
            _showAmountFilterDialog();
          },
        ),
        
        ListTile(
          leading: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
          title: Text('Search by Category', style: TextStyle(color: themeService.textColor)),
          onTap: () {
            _showCategoryFilterBottomSheet();
          },
        ),
      ],
    );
  }

  Widget _buildTransactionsList(List<dynamic> transactions) {
    // Group transactions by date
    final Map<String, List<dynamic>> groupedTransactions = {};
    for (var transaction in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // Sort dates (newest first)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionGridItem(transaction);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateTransactions = groupedTransactions[date]!;

        return FadeInUp(
          delay: Duration(milliseconds: index * 30),
          duration: const Duration(milliseconds: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(date),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: dateTransactions.length,
                itemBuilder: (context, txIndex) {
                  final transaction = dateTransactions[txIndex];
                  return _buildTransactionItem(transaction);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    final themeService = Provider.of<ThemeService>(context);
    // Safe access to status property with null check
    String status = '';
    Color statusColor = Colors.transparent;
    
    // Check if the transaction object has a status property before accessing it
    try {
      // Use reflection or try-catch to safely access the status
      if (transaction is Transaction && transaction.toString().contains('status')) {
        // If your Transaction model has a status field, access it directly
        // status = transaction.status ?? '';
        
        // For now, we'll set a default status or remove status functionality
        status = 'Successful'; // Default status
        statusColor = Colors.green;
      }
    } catch (e) {
      // If status property doesn't exist, just ignore it
      status = '';
      statusColor = Colors.transparent;
    }

    return InkWell(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeService.isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Transaction icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: transaction.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.icon,
                color: transaction.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('hh:mm a').format(transaction.date)} · ${transaction.category}',
                    style: TextStyle(
                      fontSize: 13,
                      color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Amount and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.isExpense
                      ? '-${currencyFormat.format(transaction.amount)}'
                      : '+${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: transaction.isExpense ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionGridItem(dynamic transaction) {
    final themeService = Provider.of<ThemeService>(context);
    return InkWell(
      onTap: () => _showTransactionDetails(transaction),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeService.isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 5,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transaction.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    transaction.icon,
                    color: transaction.color,
                    size: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.isExpense 
                      ? Colors.red.shade50 
                      : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.isExpense ? 'Expense' : 'Income',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: transaction.isExpense 
                        ? Colors.red.shade700 
                        : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              transaction.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              transaction.category,
              style: TextStyle(
                fontSize: 12,
                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              DateFormat('MMM d, yyyy').format(transaction.date),
              style: TextStyle(
                fontSize: 11,
                color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              transaction.isExpense
                  ? '-${currencyFormat.format(transaction.amount)}'
                  : '+${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: transaction.isExpense ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    String formattedDate;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      formattedDate = 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      formattedDate = 'Yesterday';
    } else {
      formattedDate = DateFormat('EEEE, MMMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        formattedDate,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeService = Provider.of<ThemeService>(context);
    return SizedBox(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 100,
                color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'No transactions yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start by adding a transaction or wait for SMS messages to be detected',
                style: TextStyle(
                  fontSize: 16,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add First Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final themeService = Provider.of<ThemeService>(context);
    return Shimmer.fromColors(
      baseColor: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
      highlightColor: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
      child: Column(
        children: List.generate(
          6,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 80,
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsightSkeleton() {
    final themeService = Provider.of<ThemeService>(context);
    return Shimmer.fromColors(
      baseColor: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
      highlightColor: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity * 0.7,
              height: 12,
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final themeService = Provider.of<ThemeService>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeService.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemSafe(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildDetailItem(label, value);
  }

  void _showFilterBottomSheet(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final categories = [
      'All', 'Food', 'Transport', 'Shopping', 'Bills', 
      'Entertainment', 'Education', 'Health', 'Salary'
    ];
    
    final timeFrames = [
      'Today', 'This Week', 'This Month', 'Last 3 Months', 'This Year', 'Custom'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeService.textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: themeService.isDarkMode ? Colors.white54 : Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeService.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) => ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            }
                          },
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _selectedCategory == category ? Theme.of(context).colorScheme.primary : themeService.textColor,
                            fontWeight: _selectedCategory == category ? FontWeight.w600 : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Time Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeService.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: timeFrames.map((timeFrame) => ChoiceChip(
                          label: Text(timeFrame),
                          selected: _selectedTimeFrame == timeFrame,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTimeFrame = timeFrame;
                              });
                              
                              if (timeFrame == 'Custom') {
                                _showDateRangePicker(context);
                              }
                            }
                          },
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _selectedTimeFrame == timeFrame ? Theme.of(context).colorScheme.primary : themeService.textColor,
                            fontWeight: _selectedTimeFrame == timeFrame ? FontWeight.w600 : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Amount Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeService.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: _amountRange,
                        min: 0,
                        max: _maxPossibleAmount,
                        divisions: 100,
                        labels: RangeLabels(
                          currencyFormat.format(_amountRange.start),
                          currencyFormat.format(_amountRange.end),
                        ),
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _amountRange = values;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(_amountRange.start),
                              style: TextStyle(
                                fontSize: 12,
                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              currencyFormat.format(_amountRange.end),
                              style: TextStyle(
                                fontSize: 12,
                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      CheckboxListTile(
                        title: Text('Show only recurring transactions', style: TextStyle(color: themeService.textColor)),
                        value: _showOnlyRecurring,
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyRecurring = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = 'All';
                                  _selectedTimeFrame = 'This Week';
                                  _amountRange = const RangeValues(0, 100000);
                                  _showOnlyRecurring = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Apply filters
                                Navigator.pop(context);
                                // TODO: Apply filters to transaction provider
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Apply Filters'),
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
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      setState(() {
        _dateRange = pickedDateRange;
        _selectedTimeFrame = '${DateFormat('MMM d').format(pickedDateRange.start)} - ${DateFormat('MMM d').format(pickedDateRange.end)}';
      });
      // TODO: Apply date range filter
    }
  }

  void _showAmountFilterDialog() {
    final themeService = Provider.of<ThemeService>(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('Filter by Amount', style: TextStyle(color: themeService.textColor)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select amount range:', style: TextStyle(color: themeService.textColor)),
              const SizedBox(height: 24),
              RangeSlider(
                values: _amountRange,
                min: 0,
                max: _maxPossibleAmount,
                divisions: 100,
                labels: RangeLabels(
                  currencyFormat.format(_amountRange.start),
                  currencyFormat.format(_amountRange.end),
                ),
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                onChanged: (RangeValues values) {
                  setState(() {
                    _amountRange = values;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(_amountRange.start),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_amountRange.end),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Apply amount filter
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showCategoryFilterBottomSheet() {
    final themeService = Provider.of<ThemeService>(context);
    final categories = [
      'All', 'Food', 'Transport', 'Shopping', 'Bills', 
      'Entertainment', 'Education', 'Health', 'Salary',
      'Housing', 'Groceries', 'Investment', 'Transfer', 'Withdrawal',
      'Saving', 'Utilities', 'Insurance', 'Gifts', 'Travel', 'Other'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: themeService.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: themeService.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: categories.map((category) => RadioListTile<String>(
                  title: Text(category, style: TextStyle(color: themeService.textColor)),
                  value: category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                    Navigator.pop(context);
                    // TODO: Apply category filter
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(dynamic transaction) {
    final themeService = Provider.of<ThemeService>(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaction Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: themeService.textColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: themeService.isDarkMode ? Colors.white54 : Colors.black54),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Transaction Header Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: transaction.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: themeService.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: themeService.isDarkMode 
                                              ? Colors.black.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      transaction.icon,
                                      color: transaction.color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: themeService.cardColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            transaction.category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: transaction.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                transaction.isExpense
                                    ? '-${currencyFormat.format(transaction.amount)}'
                                    : '+${currencyFormat.format(transaction.amount)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: transaction.isExpense ? Colors.red.shade700 : Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(transaction.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Transaction Info
                        Text(
                          'Transaction Info',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode ? const Color(0xFF2D3748) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildDetailItem('Date & Time', DateFormat('MMM d, yyyy • h:mm a').format(transaction.date)),
                              
                              // Safe access to optional properties
                              _buildDetailItemSafe('Transaction ID', () {
                                try {
                                  return (transaction as dynamic).mpesaCode?.toString();
                                } catch (e) {
                                  return null;
                                }
                              }()),
                              
                              _buildDetailItemSafe('From', () {
                                try {
                                  return (transaction as dynamic).sender?.toString();
                                } catch (e) {
                                  return null;
                                }
                              }()),
                              
                              _buildDetailItemSafe('To', () {
                                try {
                                  return (transaction as dynamic).recipient?.toString();
                                } catch (e) {
                                  return null;
                                }
                              }()),
                              
                              _buildDetailItemSafe('Agent', () {
                                try {
                                  return (transaction as dynamic).agent?.toString();
                                } catch (e) {
                                  return null;
                                }
                              }()),
                              
                              _buildDetailItemSafe('Business', () {
                                try {
                                  return (transaction as dynamic).business?.toString();
                                } catch (e) {
                                  return null;
                                }
                              }()),
                              
                              _buildDetailItemSafe('Balance After', () {
                                try {
                                  final balance = (transaction as dynamic).balance;
                                  return balance != null ? currencyFormat.format(balance) : null;
                                } catch (e) {
                                  return null;
                                }
                              }()),
                              
                              _buildDetailItemSafe('Status', () {
                                try {
                                  return (transaction as dynamic).status?.toString();
                                } catch (e) {
                                  return 'Successful'; // Default status
                                }
                              }()),
                              
                              _buildDetailItemSafe('Notes', () {
                                try {
                                  return (transaction as dynamic).notes?.toString();
                                } catch (e) {
                                  return null;
                                }
                              }()),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // AI Insights
                        Text(
                          'AI Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        FutureBuilder<Map<String, dynamic>>(
                          future: TransactionAIService().generateTransactionInsight(
                            transaction,
                            Provider.of<TransactionProvider>(context, listen: false)
                                .filteredTransactions
                                .map((tx) => tx as Transaction)
                                .toList(),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildAIInsightSkeleton();
                            }

                            if (snapshot.hasData && snapshot.data!['success']) {
                              final insight = snapshot.data!['insight'];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: themeService.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          size: 18,
                                          color: Colors.amber.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Smart Analysis',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: themeService.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      insight ?? 'No insight available for this transaction.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeService.isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF4B5563),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: themeService.isDarkMode ? const Color(0xFF2D3748) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'No AI insights available for this transaction.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: themeService.isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF4B5563),
                                ),
                              ),
                            );
                          },
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
}