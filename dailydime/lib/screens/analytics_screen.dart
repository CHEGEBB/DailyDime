// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dailydime/widgets/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Transaction>? transactions;
  final Map<String, dynamic>? forecastData;

  const AnalyticsScreen({
    Key? key,
    this.transactions,
    this.forecastData,
  }) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';
  bool _showExpenses = true; // Toggle between expenses and income
  TabController? _tabController;
  final Map<String, dynamic> _analyticsData = {};
  final Map<String, dynamic> _forecastData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _loadData();
    }
    if (widget.forecastData != oldWidget.forecastData) {
      setState(() {
        _forecastData.clear();
        if (widget.forecastData != null) {
          _forecastData.addAll(widget.forecastData!);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Transaction> loadedTransactions = widget.transactions ?? [];
      
      if (loadedTransactions.isEmpty) {
        final appwriteService = AppwriteService();
        loadedTransactions = await appwriteService.getTransactions();
      }

      setState(() {
        _transactions = loadedTransactions;
        _prepareAnalyticsData();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _prepareAnalyticsData() {
    if (_transactions.isEmpty) return;

    // Filter transactions based on selected period
    final filteredTransactions = _filterTransactionsByPeriod(_transactions, _selectedPeriod);
    
    // Calculate total income and expenses
    final totalIncome = filteredTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = filteredTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Prepare category data
    final categoryData = _prepareCategoryData(filteredTransactions);
    
    // Prepare weekly spending trend
    final weeklyTrend = _prepareWeeklyTrend(filteredTransactions);
    
    // Prepare monthly trend
    final monthlyTrend = _prepareMonthlyTrend(_transactions);
    
    // Prepare merchant data
    final merchantData = _prepareMerchantData(filteredTransactions);
    
    setState(() {
      _analyticsData['totalIncome'] = totalIncome;
      _analyticsData['totalExpenses'] = totalExpenses;
      _analyticsData['netSavings'] = totalIncome - totalExpenses;
      _analyticsData['savingsRate'] = totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome * 100 : 0;
      _analyticsData['categoryData'] = categoryData;
      _analyticsData['weeklyTrend'] = weeklyTrend;
      _analyticsData['monthlyTrend'] = monthlyTrend;
      _analyticsData['merchantData'] = merchantData;
    });
  }

  List<Transaction> _filterTransactionsByPeriod(List<Transaction> transactions, String period) {
    final now = DateTime.now();
    late DateTime startDate;
    
    switch (period) {
      case 'This Week':
        // Start from the beginning of the current week (Monday)
        final daysToSubtract = now.weekday - 1;
        startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }
    
    return transactions.where((t) => t.date.isAfter(startDate) || 
                                    (t.date.year == startDate.year && 
                                     t.date.month == startDate.month && 
                                     t.date.day == startDate.day)).toList();
  }

  List<Map<String, dynamic>> _prepareCategoryData(List<Transaction> transactions) {
    final Map<String, double> categoryTotals = {};
    
    // Filter by expense/income based on toggle
    final filteredTransactions = transactions.where((t) => t.isExpense == _showExpenses).toList();
    
    for (final transaction in filteredTransactions) {
      final category = transaction.category;
      if (!categoryTotals.containsKey(category)) {
        categoryTotals[category] = 0;
      }
      categoryTotals[category] = categoryTotals[category]! + transaction.amount;
    }
    
    // Convert to list of maps and sort by amount
    final result = categoryTotals.entries.map((entry) {
      return {
        'category': entry.key,
        'amount': entry.value,
      };
    }).toList();
    
    // Sort in descending order of amount
    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    return result;
  }

  Map<String, double> _prepareWeeklyTrend(List<Transaction> transactions) {
    final Map<String, double> dailyTotals = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    
    // Filter by expense/income based on toggle
    final filteredTransactions = transactions.where((t) => t.isExpense == _showExpenses).toList();
    
    for (final transaction in filteredTransactions) {
      final dayOfWeek = _getDayAbbreviation(transaction.date.weekday);
      dailyTotals[dayOfWeek] = dailyTotals[dayOfWeek]! + transaction.amount;
    }
    
    return dailyTotals;
  }

  List<Map<String, dynamic>> _prepareMonthlyTrend(List<Transaction> transactions) {
    final Map<String, Map<String, double>> monthlyTotals = {};
    final now = DateTime.now();
    
    // Create entries for the last 6 months
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = DateFormat('MMM').format(month);
      monthlyTotals[monthKey] = {'income': 0, 'expenses': 0};
    }
    
    // Calculate totals for each month
    for (final transaction in transactions) {
      // Only consider transactions from the last 6 months
      if (transaction.date.isAfter(DateTime(now.year, now.month - 6))) {
        final monthKey = DateFormat('MMM').format(transaction.date);
        
        if (monthlyTotals.containsKey(monthKey)) {
          final key = transaction.isExpense ? 'expenses' : 'income';
          monthlyTotals[monthKey]![key] = monthlyTotals[monthKey]![key]! + transaction.amount;
        }
      }
    }
    
    // Convert to list of maps and reverse to show oldest first
    return monthlyTotals.entries.map((entry) {
      return {
        'month': entry.key,
        'income': entry.value['income'],
        'expenses': entry.value['expenses'],
        'savings': entry.value['income']! - entry.value['expenses']!,
      };
    }).toList().reversed.toList();
  }

  List<Map<String, dynamic>> _prepareMerchantData(List<Transaction> transactions) {
    final Map<String, double> merchantTotals = {};
    
    // Filter by expense/income based on toggle
    final filteredTransactions = transactions.where((t) => t.isExpense == _showExpenses).toList();
    
    for (final transaction in filteredTransactions) {
      final merchant = transaction.business ?? 
                      transaction.recipient ?? 
                      transaction.sender ?? 
                      'Unknown';
      
      if (!merchantTotals.containsKey(merchant)) {
        merchantTotals[merchant] = 0;
      }
      merchantTotals[merchant] = merchantTotals[merchant]! + transaction.amount;
    }
    
    // Convert to list of maps and sort by amount
    final result = merchantTotals.entries.map((entry) {
      return {
        'merchant': entry.key,
        'amount': entry.value,
      };
    }).toList();
    
    // Sort in descending order of amount
    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    // Return top 5 merchants
    return result.take(5).toList();
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    return Scaffold(
      body: _isLoading 
          ? _buildLoadingState(themeService)
          : _transactions.isEmpty 
              ? EmptyState(
                  title: 'No Transactions Yet',
                  message: 'Start adding transactions to see analytics and insights.',
                  animation: 'assets/animations/empty_chart.json',
                  buttonText: 'Go to Transactions',
                  onButtonPressed: () {
                    Navigator.of(context).pushNamed('/transactions');
                  },
                )
              : _buildAnalyticsContent(themeService),
    );
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return Shimmer.fromColors(
      baseColor: themeService.isDarkMode 
          ? Colors.grey[800]! 
          : Colors.grey[300]!,
      highlightColor: themeService.isDarkMode 
          ? Colors.grey[700]! 
          : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 40,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(ThemeService themeService) {
    return Column(
      children: [
        _buildPeriodSelector(themeService),
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildSummaryCard(themeService),
                ),
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: themeService.primaryColor,
                    unselectedLabelColor: themeService.isDarkMode 
                        ? Colors.white70 
                        : Colors.black54,
                    indicatorColor: themeService.primaryColor,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Category'),
                      Tab(text: 'Trend'),
                      Tab(text: 'Forecast'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(themeService),
                _buildCategoryTab(themeService),
                _buildTrendTab(themeService),
                _buildForecastTab(themeService),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: themeService.primaryColor),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPeriod = newValue;
                  _prepareAnalyticsData();
                });
              }
            },
            items: <String>['This Week', 'This Month', 'Last 3 Months', 'This Year']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: themeService.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          Row(
            children: [
              TextButton.icon(
                icon: Icon(
                  _showExpenses ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _showExpenses ? Colors.red : Colors.green,
                  size: 16,
                ),
                label: Text(
                  _showExpenses ? 'Expenses' : 'Income',
                  style: TextStyle(
                    color: _showExpenses ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showExpenses = !_showExpenses;
                    _prepareAnalyticsData();
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: (_showExpenses ? Colors.red : Colors.green).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeService themeService) {
    final totalAmount = _showExpenses 
        ? _analyticsData['totalExpenses'] ?? 0.0 
        : _analyticsData['totalIncome'] ?? 0.0;
    
    final savingsRate = _analyticsData['savingsRate'] ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showExpenses ? 'Total Expenses' : 'Total Income',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConfig.formatCurrency(totalAmount.toInt() * 100),
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  themeService,
                  'Savings',
                  AppConfig.formatCurrency((_analyticsData['netSavings'] ?? 0.0).toInt() * 100),
                  _analyticsData['netSavings'] != null && (_analyticsData['netSavings'] as double) >= 0
                      ? Colors.green
                      : Colors.red,
                ),
                _buildSummaryItem(
                  themeService,
                  'Savings Rate',
                  '${savingsRate.toStringAsFixed(1)}%',
                  savingsRate >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeService themeService,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeService.subtextColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Weekly Spending Trend', themeService),
          const SizedBox(height: 8),
          _buildWeeklyTrendChart(themeService),
          const SizedBox(height: 24),
          _buildSectionTitle('Top Merchants', themeService),
          const SizedBox(height: 8),
          _buildMerchantList(themeService),
          const SizedBox(height: 24),
          _buildSectionTitle('Monthly Overview', themeService),
          const SizedBox(height: 8),
          _buildMonthlyOverview(themeService),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(ThemeService themeService) {
    final categoryData = _analyticsData['categoryData'] as List<Map<String, dynamic>>? ?? [];
    
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'No category data available for the selected period',
          style: TextStyle(
            color: themeService.subtextColor,
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Spending by Category', themeService),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildCategoryPieChart(categoryData, themeService),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Category Breakdown', themeService),
          const SizedBox(height: 8),
          ...categoryData.map((category) => _buildCategoryItem(category, themeService)),
        ],
      ),
    );
  }

  Widget _buildTrendTab(ThemeService themeService) {
    final monthlyTrend = _analyticsData['monthlyTrend'] as List<Map<String, dynamic>>? ?? [];
    
    if (monthlyTrend.isEmpty) {
      return Center(
        child: Text(
          'No trend data available',
          style: TextStyle(
            color: themeService.subtextColor,
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Income vs Expenses', themeService),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildMonthlyTrendChart(monthlyTrend, themeService),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Savings Trend', themeService),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildSavingsTrendChart(monthlyTrend, themeService),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Monthly Details', themeService),
          const SizedBox(height: 8),
          ...monthlyTrend.map((month) => _buildMonthlyTrendItem(month, themeService)),
        ],
      ),
    );
  }

  Widget _buildForecastTab(ThemeService themeService) {
    if (_forecastData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: themeService.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Forecast data not available',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Forecasts are generated from the AI Insights screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeService.subtextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Get AI Insights'),
              onPressed: () {
                Navigator.of(context).pushNamed('/ai_insights');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final dailyForecast = _forecastData['daily_forecast'] as List<dynamic>? ?? [];
    final majorExpenses = _forecastData['major_expenses'] as List<dynamic>? ?? [];
    final categoryForecast = _forecastData['category_forecast'] as List<dynamic>? ?? [];
    final totalForecast = _forecastData['total_forecast'] as double? ?? 0.0;
    final comparison = _forecastData['previous_month_comparison'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('30-Day Spending Forecast', themeService),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: themeService.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forecast Total: ${AppConfig.formatCurrency(totalForecast.toInt() * 100)}',
                    style: TextStyle(
                      color: themeService.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        (comparison['percent_change'] as double? ?? 0) > 0 
                            ? Icons.trending_up 
                            : Icons.trending_down,
                        color: (comparison['percent_change'] as double? ?? 0) > 0
                            ? Colors.red
                            : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(comparison['percent_change'] as double? ?? 0).abs().toStringAsFixed(1)}% ${(comparison['percent_change'] as double? ?? 0) > 0 ? 'more than' : 'less than'} last month',
                        style: TextStyle(
                          color: (comparison['percent_change'] as double? ?? 0) > 0
                              ? Colors.red
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildForecastChart(dailyForecast, themeService),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Expected Major Expenses', themeService),
          const SizedBox(height: 8),
          ...majorExpenses.map((expense) => _buildMajorExpenseItem(expense, themeService)),
          const SizedBox(height: 24),
          _buildSectionTitle('Category Forecast', themeService),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildCategoryForecastChart(categoryForecast, themeService),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeService themeService) {
    return Text(
      title,
      style: TextStyle(
        color: themeService.textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWeeklyTrendChart(ThemeService themeService) {
    final weeklyData = _analyticsData['weeklyTrend'] as Map<String, double>? ?? {};
    
    if (weeklyData.isEmpty) {
      return const SizedBox();
    }
    
    final maxValue = weeklyData.values.fold(0.0, (prev, curr) => curr > prev ? curr : prev);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: themeService.isDarkMode 
                        ? Colors.grey[800] 
                        : Colors.grey[300],
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value >= 0 && value < days.length) {
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(
                            color: themeService.subtextColor,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxValue / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      return Text(
                        AppConfig.formatCurrency(value.toInt() * 100)
                            .replaceAll(AppConfig.currencySymbol, '')
                            .trim(),
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: maxValue * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, weeklyData['Mon'] ?? 0),
                    FlSpot(1, weeklyData['Tue'] ?? 0),
                    FlSpot(2, weeklyData['Wed'] ?? 0),
                    FlSpot(3, weeklyData['Thu'] ?? 0),
                    FlSpot(4, weeklyData['Fri'] ?? 0),
                    FlSpot(5, weeklyData['Sat'] ?? 0),
                    FlSpot(6, weeklyData['Sun'] ?? 0),
                  ],
                  isCurved: true,
                  color: themeService.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: themeService.primaryColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: themeService.primaryColor.withOpacity(0.2),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipColor: (touchedSpot) => themeService.isDarkMode 
        ? Colors.grey[800]! 
        : Colors.white,  // Changed to 'getTooltipColor'
    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
      return touchedBarSpots.map((barSpot) {
        final flSpot = barSpot;
        final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][flSpot.x.toInt()];
        return LineTooltipItem(
          '$weekday\n${AppConfig.formatCurrency(flSpot.y.toInt() * 100)}',
          TextStyle(
            color: themeService.isDarkMode 
                ? Colors.white 
                : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList();
    },
  ),
),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantList(ThemeService themeService) {
    final merchantData = _analyticsData['merchantData'] as List<Map<String, dynamic>>? ?? [];
    
    if (merchantData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No merchant data available for the selected period',
            style: TextStyle(
              color: themeService.subtextColor,
            ),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: merchantData.length,
        separatorBuilder: (context, index) => Divider(
          color: themeService.isDarkMode 
              ? Colors.grey[800] 
              : Colors.grey[200],
          height: 1,
        ),
        itemBuilder: (context, index) {
          final merchant = merchantData[index];
          return ListTile(
            title: Text(
              merchant['merchant'],
              style: TextStyle(
                color: themeService.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              AppConfig.formatCurrency((merchant['amount'] as double).toInt() * 100),
              style: TextStyle(
                color: _showExpenses ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyOverview(ThemeService themeService) {
    final monthlyTrend = _analyticsData['monthlyTrend'] as List<Map<String, dynamic>>? ?? [];
    
    if (monthlyTrend.isEmpty) {
      return const SizedBox();
    }
    
    final latestMonth = monthlyTrend.last;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${latestMonth['month']} Overview',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOverviewItem(
              'Income',
              AppConfig.formatCurrency((latestMonth['income'] as double).toInt() * 100),
              Icons.arrow_downward,
              Colors.green,
              themeService,
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              'Expenses',
              AppConfig.formatCurrency((latestMonth['expenses'] as double).toInt() * 100),
              Icons.arrow_upward,
              Colors.red,
              themeService,
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              'Net Savings',
              AppConfig.formatCurrency((latestMonth['savings'] as double).toInt() * 100),
              (latestMonth['savings'] as double) >= 0 ? Icons.savings : Icons.warning,
              (latestMonth['savings'] as double) >= 0 ? Colors.green : Colors.red,
              themeService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    ThemeService themeService,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: themeService.subtextColor,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(List<Map<String, dynamic>> categoryData, ThemeService themeService) {
    if (categoryData.isEmpty) {
      return const SizedBox();
    }
    
    // Calculate total amount
    final totalAmount = categoryData.fold(0.0, (sum, item) => sum + (item['amount'] as double));
    
    // Generate colors for each category
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    
    // Prepare sections
    final sections = <PieChartSectionData>[];
    
    for (var i = 0; i < categoryData.length; i++) {
      final category = categoryData[i];
      final percentage = (category['amount'] as double) / totalAmount * 100;
      
      if (percentage < 1) continue; // Skip very small slices
      
      final color = i < colors.length ? colors[i] : Colors.grey;
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: category['amount'] as double,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Could implement selection logic here
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Categories',
                    style: TextStyle(
                      color: themeService.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: min(5, categoryData.length),
                      itemBuilder: (context, index) {
                        final category = categoryData[index];
                        final percentage = (category['amount'] as double) / totalAmount * 100;
                        final color = index < colors.length ? colors[index] : Colors.grey;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category['category'],
                                  style: TextStyle(
                                    color: themeService.textColor,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: themeService.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildCategoryItem(Map<String, dynamic> category, ThemeService themeService) {
    final amount = category['amount'] as double;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeService.cardColor,
      child: ListTile(
        title: Text(
          category['category'],
          style: TextStyle(
            color: themeService.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          AppConfig.formatCurrency(amount.toInt() * 100),
          style: TextStyle(
            color: _showExpenses ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          // Navigate to category details screen or show dialog
        },
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<Map<String, dynamic>> monthlyData, ThemeService themeService) {
    if (monthlyData.isEmpty) {
      return const SizedBox();
    }
    
    final months = monthlyData.map((m) => m['month'] as String).toList();
    
    final maxValue = monthlyData.fold(0.0, (prev, curr) {
      final income = curr['income'] as double;
      final expenses = curr['expenses'] as double;
      final max = income > expenses ? income : expenses;
      return max > prev ? max : prev;
    });
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
         BarChartData(
  alignment: BarChartAlignment.spaceAround,
  maxY: maxValue * 1.1,
  barTouchData: BarTouchData(
    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (group) => themeService.isDarkMode ? Colors.grey[800]! : Colors.white,
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        final month = months[group.x.toInt()];
        final amount = rod.toY;
        final label = rodIndex == 0 ? 'Income' : 'Expenses';
        return BarTooltipItem(
          '$month - $label\n${AppConfig.formatCurrency(amount.toInt() * 100)}',
          TextStyle(
            color: themeService.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < months.length) {
                      return Text(
                        months[value.toInt()],
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 12,
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxValue / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      AppConfig.formatCurrency(value.toInt() * 100)
                          .replaceAll(AppConfig.currencySymbol, '')
                          .trim(),
                      style: TextStyle(
                        color: themeService.subtextColor,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: themeService.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: List.generate(monthlyData.length, (index) {
              final data = monthlyData[index];
              final income = data['income'] as double;
              final expenses = data['expenses'] as double;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: income,
                    color: Colors.green,
                    width: 12,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: expenses,
                    color: Colors.red,
                    width: 12,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsTrendChart(List<Map<String, dynamic>> monthlyData, ThemeService themeService) {
    if (monthlyData.isEmpty) {
      return const SizedBox();
    }
    
    final months = monthlyData.map((m) => m['month'] as String).toList();
    
    // Calculate min and max values for y-axis
    double minValue = 0;
    double maxValue = 0;
    
    for (final data in monthlyData) {
      final savings = data['savings'] as double;
      if (savings < minValue) minValue = savings;
      if (savings > maxValue) maxValue = savings;
    }
    
    // Ensure we have some margin
    minValue = minValue * 1.1;
    maxValue = maxValue * 1.1;
    
    // If all values are positive, start from 0
    if (minValue > 0) minValue = 0;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxValue - minValue) / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: themeService.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < months.length) {
                      return Text(
                        months[value.toInt()],
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 12,
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (maxValue - minValue) / 4,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      AppConfig.formatCurrency(value.toInt() * 100)
                          .replaceAll(AppConfig.currencySymbol, '')
                          .trim(),
                      style: TextStyle(
                        color: themeService.subtextColor,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            minX: 0,
            maxX: monthlyData.length - 1.0,
            minY: minValue,
            maxY: maxValue,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(monthlyData.length, (index) {
                  final data = monthlyData[index];
                  final savings = data['savings'] as double;
                  return FlSpot(index.toDouble(), savings);
                }),
                isCurved: true,
                color: themeService.primaryColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final savings = monthlyData[index]['savings'] as double;
                    final color = savings >= 0 ? Colors.green : Colors.red;
                    
                    return FlDotCirclePainter(
                      radius: 5,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: themeService.primaryColor.withOpacity(0.2),
                  cutOffY: 0,
                  applyCutOffY: true,
                ),
              ),
            ],
           lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipColor: (touchedSpot) => themeService.isDarkMode ? Colors.grey[800]! : Colors.white,
    // Remove tooltipRoundedRadius if it causes issues
    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
      return touchedBarSpots.map((barSpot) {
        final flSpot = barSpot;
        final month = months[flSpot.x.toInt()];
        final savings = monthlyData[flSpot.x.toInt()]['savings'] as double;
        
        return LineTooltipItem(
          '$month Savings\n${AppConfig.formatCurrency(savings.toInt() * 100)}',
          TextStyle(
            color: themeService.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList();
    },
  ),
),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendItem(Map<String, dynamic> month, ThemeService themeService) {
    final income = month['income'] as double;
    final expenses = month['expenses'] as double;
    final savings = month['savings'] as double;
    final savingsPercent = income > 0 ? (savings / income) * 100 : 0.0;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              month['month'],
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMonthlyTrendMetric(
                  'Income',
                  AppConfig.formatCurrency(income.toInt() * 100),
                  Colors.green,
                  themeService,
                ),
                _buildMonthlyTrendMetric(
                  'Expenses',
                  AppConfig.formatCurrency(expenses.toInt() * 100),
                  Colors.red,
                  themeService,
                ),
                _buildMonthlyTrendMetric(
                  'Savings',
                  '${savingsPercent.toStringAsFixed(1)}%',
                  savings >= 0 ? Colors.green : Colors.red,
                  themeService,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendMetric(
    String label,
    String value,
    Color valueColor,
    ThemeService themeService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeService.subtextColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastChart(List<dynamic> dailyForecast, ThemeService themeService) {
    if (dailyForecast.isEmpty) {
      return const SizedBox();
    }
    
    // Convert to proper data format
    final data = <FlSpot>[];
    final actualData = <FlSpot>[];
    final futureData = <FlSpot>[];
    
    for (var i = 0; i < dailyForecast.length; i++) {
      final forecast = dailyForecast[i] as Map<String, dynamic>;
      final amount = forecast['amount'] as double;
      final isActual = forecast['actual'] as bool? ?? false;
      
      if (isActual) {
        actualData.add(FlSpot(i.toDouble(), amount));
      } else {
        futureData.add(FlSpot(i.toDouble(), amount));
      }
      
      data.add(FlSpot(i.toDouble(), amount));
    }
    
    // Calculate min and max values for better visualization
    double maxValue = data.fold(0.0, (prev, curr) => curr.y > prev ? curr.y : prev);
    
    // Extract date labels
    final dateLabels = dailyForecast.map((f) {
      final forecast = f as Map<String, dynamic>;
      final dateStr = forecast['date'] as String;
      return dateStr.split('-').last; // Just the day part
    }).toList();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: themeService.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < dateLabels.length && index % 5 == 0) {
                      return Text(
                        dateLabels[index],
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 10,
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxValue / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      AppConfig.formatCurrency(value.toInt() * 100)
                          .replaceAll(AppConfig.currencySymbol, '')
                          .trim(),
                      style: TextStyle(
                        color: themeService.subtextColor,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            minX: 0,
            maxX: (dailyForecast.length - 1).toDouble(),
            minY: 0,
            maxY: maxValue * 1.1,
            lineBarsData: [
              // Actual data line
              if (actualData.isNotEmpty)
                LineChartBarData(
                  spots: actualData,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.blue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              // Forecast data line
              if (futureData.isNotEmpty)
                LineChartBarData(
                  spots: futureData,
                  isCurved: true,
                  color: themeService.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dashArray: [5, 5], // Dashed line for forecast
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: themeService.primaryColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: themeService.primaryColor.withOpacity(0.1),
                  ),
                ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: themeService.isDarkMode ? Colors.grey[800]! : Colors.white,
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final flSpot = barSpot;
                    final index = flSpot.x.toInt();
                    final forecast = dailyForecast[index] as Map<String, dynamic>;
                    final date = forecast['date'] as String;
                    final isActual = forecast['actual'] as bool? ?? false;
                    
                    return LineTooltipItem(
                      '${date}\n${isActual ? 'Actual' : 'Forecast'}: ${AppConfig.formatCurrency(flSpot.y.toInt() * 100)}',
                      TextStyle(
                        color: themeService.isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMajorExpenseItem(dynamic expense, ThemeService themeService) {
    final expenseMap = expense as Map<String, dynamic>;
    final category = expenseMap['category'] as String? ?? 'Unknown';
    final estimatedAmount = expenseMap['estimated_amount'] as double? ?? 0.0;
    final confidence = expenseMap['confidence'] as double? ?? 0.0;
    final reason = expenseMap['reason'] as String? ?? '';
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: themeService.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppConfig.formatCurrency(estimatedAmount.toInt() * 100),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(confidence).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(confidence * 100).toStringAsFixed(0)}% confidence',
                    style: TextStyle(
                      color: _getConfidenceColor(confidence),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: TextStyle(
                  color: themeService.subtextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCategoryForecastChart(List<dynamic> categoryForecast, ThemeService themeService) {
    if (categoryForecast.isEmpty) {
      return const SizedBox();
    }
    
    // Convert to proper data format
    final data = categoryForecast.map((c) {
      final category = c as Map<String, dynamic>;
      return {
        'category': category['category'] as String,
        'predicted_amount': category['predicted_amount'] as double,
        'historical_average': category['historical_average'] as double? ?? 0.0,
      };
    }).take(8).toList(); // Limit to top 8 categories
    
    final maxValue = data.fold(0.0, (prev, curr) {
      final predicted = curr['predicted_amount'] as double;
      final historical = curr['historical_average'] as double;
      final max = predicted > historical ? predicted : historical;
      return max > prev ? max : prev;
    });
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Predicted',
                  style: TextStyle(
                    color: themeService.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Historical Average',
                  style: TextStyle(
                    color: themeService.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.1,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: themeService.isDarkMode ? Colors.grey[800]! : Colors.white,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final categoryData = data[group.x.toInt()];
                        final category = categoryData['category'] as String;
                        final amount = rod.toY;
                        final label = rodIndex == 0 ? 'Predicted' : 'Historical';
                        return BarTooltipItem(
                          '$category - $label\n${AppConfig.formatCurrency(amount.toInt() * 100)}',
                          TextStyle(
                            color: themeService.isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < data.length) {
                            final category = data[value.toInt()]['category'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                category.length > 8 ? '${category.substring(0, 8)}...' : category,
                                style: TextStyle(
                                  color: themeService.subtextColor,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxValue / 4,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          return Text(
                            AppConfig.formatCurrency(value.toInt() * 100)
                                .replaceAll(AppConfig.currencySymbol, '')
                                .trim(),
                            style: TextStyle(
                              color: themeService.subtextColor,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: themeService.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: List.generate(data.length, (index) {
                    final categoryData = data[index];
                    final predicted = categoryData['predicted_amount'] as double;
                    final historical = categoryData['historical_average'] as double;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: predicted,
                          color: Colors.blue,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: historical,
                          color: Colors.grey[400]!,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}