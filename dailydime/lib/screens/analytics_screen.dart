// lib/screens/analytics_screen.dart
import 'dart:math' as Math;

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

  const AnalyticsScreen({Key? key, this.transactions, this.forecastData})
    : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
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
    final filteredTransactions = _filterTransactionsByPeriod(
      _transactions,
      _selectedPeriod,
    );

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
      _analyticsData['savingsRate'] = totalIncome > 0
          ? (totalIncome - totalExpenses) / totalIncome * 100
          : 0;
      _analyticsData['categoryData'] = categoryData;
      _analyticsData['weeklyTrend'] = weeklyTrend;
      _analyticsData['monthlyTrend'] = monthlyTrend;
      _analyticsData['merchantData'] = merchantData;
    });
  }

  List<Transaction> _filterTransactionsByPeriod(
    List<Transaction> transactions,
    String period,
  ) {
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

    return transactions
        .where(
          (t) =>
              t.date.isAfter(startDate) ||
              (t.date.year == startDate.year &&
                  t.date.month == startDate.month &&
                  t.date.day == startDate.day),
        )
        .toList();
  }

  List<Map<String, dynamic>> _prepareCategoryData(
    List<Transaction> transactions,
  ) {
    final Map<String, double> categoryTotals = {};

    // Filter by expense/income based on toggle
    final filteredTransactions = transactions
        .where((t) => t.isExpense == _showExpenses)
        .toList();

    for (final transaction in filteredTransactions) {
      final category = transaction.category;
      if (!categoryTotals.containsKey(category)) {
        categoryTotals[category] = 0;
      }
      categoryTotals[category] = categoryTotals[category]! + transaction.amount;
    }

    // Convert to list of maps and sort by amount
    final result = categoryTotals.entries.map((entry) {
      return {'category': entry.key, 'amount': entry.value};
    }).toList();

    // Sort in descending order of amount
    result.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );

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
    final filteredTransactions = transactions
        .where((t) => t.isExpense == _showExpenses)
        .toList();

    for (final transaction in filteredTransactions) {
      final dayOfWeek = _getDayAbbreviation(transaction.date.weekday);
      dailyTotals[dayOfWeek] = dailyTotals[dayOfWeek]! + transaction.amount;
    }

    return dailyTotals;
  }

  List<Map<String, dynamic>> _prepareMonthlyTrend(
    List<Transaction> transactions,
  ) {
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
          monthlyTotals[monthKey]![key] =
              monthlyTotals[monthKey]![key]! + transaction.amount;
        }
      }
    }

    // Convert to list of maps and reverse to show oldest first
    return monthlyTotals.entries
        .map((entry) {
          return {
            'month': entry.key,
            'income': entry.value['income'],
            'expenses': entry.value['expenses'],
            'savings': entry.value['income']! - entry.value['expenses']!,
          };
        })
        .toList()
        .reversed
        .toList();
  }

  List<Map<String, dynamic>> _prepareMerchantData(
    List<Transaction> transactions,
  ) {
    final Map<String, double> merchantTotals = {};

    // Filter by expense/income based on toggle
    final filteredTransactions = transactions
        .where((t) => t.isExpense == _showExpenses)
        .toList();

    for (final transaction in filteredTransactions) {
      final merchant =
          transaction.business ??
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
      return {'merchant': entry.key, 'amount': entry.value};
    }).toList();

    // Sort in descending order of amount
    result.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );

    // Return top 5 merchants
    return result.take(5).toList();
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
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
              message:
                  'Start adding transactions to see analytics and insights.',
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
                SliverToBoxAdapter(child: _buildSummaryCard(themeService)),
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: themeService.primaryColor,
                    unselectedLabelColor: themeService.isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                    indicatorColor: themeService.primaryColor,
                    indicatorSize: TabBarIndicatorSize.label,
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
      margin: const EdgeInsets.only(top: 48), // Safe area
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
            items:
                <String>[
                  'This Week',
                  'This Month',
                  'Last 3 Months',
                  'This Year',
                ].map<DropdownMenuItem<String>>((String value) {
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
                  backgroundColor: (_showExpenses ? Colors.red : Colors.green)
                      .withOpacity(0.1),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              NumberFormat.currency(
                symbol: 'KES ',
                decimalDigits: 0,
              ).format(totalAmount),
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
                  NumberFormat.currency(
                    symbol: 'KES ',
                    decimalDigits: 0,
                  ).format(_analyticsData['netSavings'] ?? 0.0),
                  _analyticsData['netSavings'] != null &&
                          (_analyticsData['netSavings'] as double) >= 0
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
          style: TextStyle(color: themeService.subtextColor, fontSize: 12),
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
  
  Widget _buildWeeklyTrendChart(ThemeService themeService) {
    final weeklyTrend = _analyticsData['weeklyTrend'] as Map<String, double>? ?? {};
    
    if (weeklyTrend.isEmpty) {
      return _buildEmptyChart(
        'No weekly trend data available',
        themeService,
      );
    }
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        days[value.toInt()],
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, weeklyTrend['Mon'] ?? 0),
                FlSpot(1, weeklyTrend['Tue'] ?? 0),
                FlSpot(2, weeklyTrend['Wed'] ?? 0),
                FlSpot(3, weeklyTrend['Thu'] ?? 0),
                FlSpot(4, weeklyTrend['Fri'] ?? 0),
                FlSpot(5, weeklyTrend['Sat'] ?? 0),
                FlSpot(6, weeklyTrend['Sun'] ?? 0),
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
                    strokeColor: themeService.isDarkMode 
                        ? Colors.black 
                        : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: themeService.primaryColor.withOpacity(0.15),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    // Use getTooltipColor instead of tooltipBgColor
    getTooltipColor: (touchedSpot) => themeService.isDarkMode 
        ? Colors.grey[800]! 
        : Colors.white,
    // Alternative: you can also use tooltipRoundedRadius for styling
    // tooltipRoundedRadius: 8,
    tooltipPadding: const EdgeInsets.all(8),
    tooltipMargin: 8,
    getTooltipItems: (touchedSpots) {
      return touchedSpots.map((spot) {
        return LineTooltipItem(
          NumberFormat.currency(
            symbol: 'KES ',
            decimalDigits: 0,
          ).format(spot.y),
          TextStyle(
            color: themeService.textColor,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList();
    },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMerchantList(ThemeService themeService) {
    final merchantData = _analyticsData['merchantData'] as List<Map<String, dynamic>>? ?? [];
    
    if (merchantData.isEmpty) {
      return _buildEmptyChart(
        'No merchant data available',
        themeService,
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: merchantData.map((merchant) {
          final merchantName = merchant['merchant'] as String;
          final amount = merchant['amount'] as double;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeService.isDarkMode 
                        ? Colors.grey[800] 
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      merchantName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: themeService.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchantName,
                        style: TextStyle(
                          color: themeService.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _showExpenses ? 'Expense' : 'Income',
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: 'KES ',
                    decimalDigits: 0,
                  ).format(amount),
                  style: TextStyle(
                    color: themeService.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildMonthlyOverview(ThemeService themeService) {
    final monthlyTrend = _analyticsData['monthlyTrend'] as List<Map<String, dynamic>>? ?? [];
    
    if (monthlyTrend.isEmpty) {
      return _buildEmptyChart(
        'No monthly data available',
        themeService,
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: monthlyTrend.take(3).map((month) {
          final monthName = month['month'] as String;
          final income = month['income'] as double;
          final expenses = month['expenses'] as double;
          final savings = month['savings'] as double;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthName,
                      style: TextStyle(
                        color: themeService.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Net: ${NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(savings)}',
                      style: TextStyle(
                        color: savings >= 0 ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income',
                            style: TextStyle(
                              color: themeService.subtextColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(
                              symbol: 'KES ',
                              decimalDigits: 0,
                            ).format(income),
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: TextStyle(
                              color: themeService.subtextColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(
                              symbol: 'KES ',
                              decimalDigits: 0,
                            ).format(expenses),
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: income > 0 ? expenses / income : 0,
                    backgroundColor: Colors.green.withOpacity(0.3),
                    color: Colors.red,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(ThemeService themeService) {
    final categoryData =
        _analyticsData['categoryData'] as List<Map<String, dynamic>>? ?? [];

    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'No category data available for the selected period',
          style: TextStyle(color: themeService.subtextColor),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: categoryData.map(
                (category) => _buildCategoryItem(category, themeService),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryPieChart(
    List<Map<String, dynamic>> categoryData,
    ThemeService themeService,
  ) {
    // Calculate total amount for percentage
    final totalAmount = categoryData.fold(
      0.0,
      (sum, category) => sum + (category['amount'] as double),
    );
    
    // Generate colors for each section
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
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(
          sections: List.generate(
            categoryData.length,
            (index) {
              final category = categoryData[index];
              final amount = category['amount'] as double;
              final percentage = totalAmount > 0 
                  ? amount / totalAmount * 100 
                  : 0.0;
              
              return PieChartSectionData(
                color: colors[index % colors.length],
                value: amount,
                title: '${percentage.toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                badgeWidget: _Badge(
                  category['category'] as String,
                  colors[index % colors.length],
                  size: 40,
                ),
                badgePositionPercentageOffset: 1.4,
              );
            },
          ),
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          startDegreeOffset: -90,
        ),
      ),
    );
  }
  
  Widget _buildCategoryItem(
    Map<String, dynamic> category,
    ThemeService themeService,
  ) {
    final categoryName = category['category'] as String;
    final amount = category['amount'] as double;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getCategoryColor(categoryName),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              categoryName,
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            NumberFormat.currency(
              symbol: 'KES ',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.green,
      'Transport': Colors.blue,
      'Housing': Colors.purple,
      'Entertainment': Colors.orange,
      'Shopping': Colors.pink,
      'Utilities': Colors.teal,
      'Health': Colors.red,
      'Education': Colors.indigo,
      'Travel': Colors.amber,
      'Personal': Colors.cyan,
    };
    
    return colors[category] ?? Colors.grey;
  }

  Widget _buildTrendTab(ThemeService themeService) {
    final monthlyTrend =
        _analyticsData['monthlyTrend'] as List<Map<String, dynamic>>? ?? [];

    if (monthlyTrend.isEmpty) {
      return Center(
        child: Text(
          'No trend data available',
          style: TextStyle(color: themeService.subtextColor),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: monthlyTrend.map(
                (month) => _buildMonthlyTrendItem(month, themeService),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlyTrendChart(
    List<Map<String, dynamic>> monthlyTrend,
    ThemeService themeService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: monthlyTrend.fold(
            0.0,
            (max, month) => Math.max(
              max,
              Math.max(
                month['income'] as double,
                month['expenses'] as double,
              ),
            ),
          ) * 1.2,
         barTouchData: BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    // Use getTooltipColor instead of tooltipBgColor
    getTooltipColor: (group) => themeService.isDarkMode
        ? Colors.grey[800]!
        : Colors.white,
    // Additional styling options
    // tooltipRoundedRadius: 8,
    tooltipPadding: const EdgeInsets.all(8),
    tooltipMargin: 8,
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      final month = monthlyTrend[groupIndex]['month'] as String;
      final value = NumberFormat.currency(
        symbol: 'KES ',
        decimalDigits: 0,
      ).format(rod.toY);
      final type = rodIndex == 0 ? 'Income' : 'Expenses';
      
      return BarTooltipItem(
        '$month\n$type: $value',
        TextStyle(
          color: themeService.textColor,
          fontWeight: FontWeight.bold,
        ),
      );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < monthlyTrend.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        monthlyTrend[value.toInt()]['month'] as String,
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: List.generate(
            monthlyTrend.length,
            (index) => BarChartGroupData(
              x: index,
              groupVertically: true,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: monthlyTrend[index]['income'] as double,
                  color: Colors.green,
                  width: 12,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: monthlyTrend[index]['expenses'] as double,
                  color: Colors.red,
                  width: 12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSavingsTrendChart(
    List<Map<String, dynamic>> monthlyTrend,
    ThemeService themeService,
  ) {
    final savingsData = monthlyTrend
        .map((month) => FlSpot(
          monthlyTrend.indexOf(month).toDouble(),
          month['savings'] as double,
        ))
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < monthlyTrend.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        monthlyTrend[value.toInt()]['month'] as String,
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: savingsData,
              isCurved: true,
              color: themeService.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  Color dotColor = spot.y >= 0 ? Colors.green : Colors.red;
                  return FlDotCirclePainter(
                    radius: 5,
                    color: dotColor,
                    strokeWidth: 2,
                    strokeColor: themeService.isDarkMode 
                        ? Colors.black 
                        : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: themeService.primaryColor.withOpacity(0.15),
                applyCutOffY: true,
                cutOffY: 0,
                spotsLine: BarAreaSpotsLine(
                  show: true,
                  flLineStyle: FlLine(
                    color: themeService.isDarkMode 
                        ? Colors.white.withOpacity(0.2) 
                        : Colors.black.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
              ),
            ),
          ],
        lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    // Use getTooltipColor instead of tooltipBgColor
    getTooltipColor: (touchedSpot) => themeService.isDarkMode 
        ? Colors.grey[800]! 
        : Colors.white,
    // Additional styling options
    // tooltipRoundedRadius: 8,
    tooltipPadding: const EdgeInsets.all(8),
    tooltipMargin: 8,
    getTooltipItems: (touchedSpots) {
      return touchedSpots.map((spot) {
        final month = monthlyTrend[spot.x.toInt()]['month'] as String;
        return LineTooltipItem(
          '$month\n${NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(spot.y)}',
          TextStyle(
            color: themeService.textColor,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: spot.y >= 0 ? ' saved' : ' deficit',
              style: TextStyle(
                color: spot.y >= 0 ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList();
    },
            ),
          ),
          minX: 0,
          maxX: monthlyTrend.length - 1.0,
        ),
      ),
    );
  }
  
  Widget _buildMonthlyTrendItem(
    Map<String, dynamic> month,
    ThemeService themeService,
  ) {
    final monthName = month['month'] as String;
    final income = month['income'] as double;
    final expenses = month['expenses'] as double;
    final savings = month['savings'] as double;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthName,
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income',
                    style: TextStyle(
                      color: themeService.subtextColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: 'KES ',
                      decimalDigits: 0,
                    ).format(income),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses',
                    style: TextStyle(
                      color: themeService.subtextColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: 'KES ',
                      decimalDigits: 0,
                    ).format(expenses),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Savings',
                    style: TextStyle(
                      color: themeService.subtextColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: 'KES ',
                      decimalDigits: 0,
                    ).format(savings),
                    style: TextStyle(
                      color: savings >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          savings >= 0
              ? LinearProgressIndicator(
                  value: income > 0 ? expenses / income : 0,
                  backgroundColor: Colors.green,
                  color: Colors.red,
                  minHeight: 4,
                )
              : LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.red.withOpacity(0.3),
                  color: Colors.red,
                  minHeight: 4,
                ),
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
              style: TextStyle(color: themeService.subtextColor, fontSize: 14),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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

    final dailyForecast =
        _forecastData['daily_forecast'] as List<dynamic>? ?? [];
    final majorExpenses =
        _forecastData['major_expenses'] as List<dynamic>? ?? [];
    final categoryForecast =
        _forecastData['category_forecast'] as List<dynamic>? ?? [];
    final totalForecast = _forecastData['total_forecast'] as double? ?? 0.0;
    final comparison =
        _forecastData['previous_month_comparison'] as Map<String, dynamic>? ??
        {};

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
                    'Forecast Total: ${NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(totalForecast)}',
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
                        color:
                            (comparison['percent_change'] as double? ?? 0) > 0
                            ? Colors.red
                            : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(comparison['percent_change'] as double? ?? 0).abs().toStringAsFixed(1)}% ${(comparison['percent_change'] as double? ?? 0) > 0 ? 'more than' : 'less than'} last month',
                        style: TextStyle(
                          color:
                              (comparison['percent_change'] as double? ?? 0) > 0
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: majorExpenses.isEmpty
                  ? [
                      Center(
                        child: Text(
                          'No major expenses predicted',
                          style: TextStyle(color: themeService.subtextColor),
                        ),
                      ),
                    ]
                  : majorExpenses.map(
                      (expense) => _buildMajorExpenseItem(expense, themeService),
                    ).toList(),
            ),
          ),
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
  
  Widget _buildForecastChart(
    List<dynamic> dailyForecast,
    ThemeService themeService,
  ) {
    if (dailyForecast.isEmpty) {
      return _buildEmptyChart(
        'No forecast data available',
        themeService,
      );
    }
    
    // Extract data for chart
    final spots = List<FlSpot>.generate(
      dailyForecast.length,
      (index) => FlSpot(
        index.toDouble(),
        (dailyForecast[index]['amount'] as double?) ?? 0.0,
      ),
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Show every 5th day
                  if (value.toInt() % 5 == 0 && value.toInt() < dailyForecast.length) {
                    final date = DateTime.parse(dailyForecast[value.toInt()]['date'] as String);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('d MMM').format(date),
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: themeService.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: themeService.primaryColor.withOpacity(0.15),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    // Use getTooltipColor instead of tooltipBgColor
    getTooltipColor: (touchedSpot) => themeService.isDarkMode
        ? Colors.grey[800]!
        : Colors.white,
    // Additional styling options
    // tooltipRoundedRadius: 8,
    tooltipPadding: const EdgeInsets.all(8),
    tooltipMargin: 8,
    getTooltipItems: (touchedSpots) {
      return touchedSpots.map((spot) {
        final index = spot.x.toInt();
        if (index < dailyForecast.length) {
          final date = DateTime.parse(dailyForecast[index]['date'] as String);
          return LineTooltipItem(
            '${DateFormat('MMM d').format(date)}\n${NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(spot.y)}',
            TextStyle(
              color: themeService.textColor,
              fontWeight: FontWeight.bold,
            ),
          );
        }
        return null;
      }).whereType<LineTooltipItem>().toList();
    },
  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMajorExpenseItem(
    dynamic expense,
    ThemeService themeService,
  ) {
    final category = expense['category'] as String?;
    final amount = expense['amount'] as double?;
    final likelihood = expense['likelihood'] as double?;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(category ?? 'Unknown').withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(category ?? 'Unknown'),
              color: _getCategoryColor(category ?? 'Unknown'),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category ?? 'Unknown',
                  style: TextStyle(
                    color: themeService.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Likelihood: ${(likelihood ?? 0.0) * 100}%',
                  style: TextStyle(
                    color: themeService.subtextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(
              symbol: 'KES ',
              decimalDigits: 0,
            ).format(amount ?? 0),
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    final icons = {
      'Food': Icons.restaurant,
      'Transport': Icons.directions_car,
      'Housing': Icons.home,
      'Entertainment': Icons.movie,
      'Shopping': Icons.shopping_bag,
      'Utilities': Icons.bolt,
      'Health': Icons.medical_services,
      'Education': Icons.school,
      'Travel': Icons.flight,
      'Personal': Icons.person,
    };
    
    return icons[category] ?? Icons.category;
  }
  
  Widget _buildCategoryForecastChart(
    List<dynamic> categoryForecast,
    ThemeService themeService,
  ) {
    if (categoryForecast.isEmpty) {
      return _buildEmptyChart(
        'No category forecast data available',
        themeService,
      );
    }
    
    // Sort categories by amount
    categoryForecast.sort((a, b) => 
      (b['amount'] as double).compareTo(a['amount'] as double)
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: categoryForecast.fold(
            0.0,
            (max, category) => Math.max(
              max,
              category['amount'] as double,
            ),
          ) * 1.2,
         barTouchData: BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    // Use getTooltipColor instead of tooltipBgColor
    getTooltipColor: (group) => themeService.isDarkMode
        ? Colors.grey[800]!
        : Colors.white,
    // Additional styling options
    // tooltipRoundedRadius: 8,
    tooltipPadding: const EdgeInsets.all(8),
    tooltipMargin: 8,
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      final category = categoryForecast[groupIndex]['category'] as String;
      final value = NumberFormat.currency(
        symbol: 'KES ',
        decimalDigits: 0,
      ).format(rod.toY);
      final percent = categoryForecast[groupIndex]['percent'] as double;
      
      return BarTooltipItem(
        '$category\n$value (${percent.toStringAsFixed(1)}%)',
        TextStyle(
          color: themeService.textColor,
          fontWeight: FontWeight.bold,
        ),
      );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < categoryForecast.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        (categoryForecast[value.toInt()]['category'] as String)
                            .substring(0, Math.min(3, (categoryForecast[value.toInt()]['category'] as String).length)),
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: List.generate(
            categoryForecast.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: categoryForecast[index]['amount'] as double,
                  color: _getCategoryColor(categoryForecast[index]['category'] as String),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
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
  
  Widget _buildEmptyChart(String message, ThemeService themeService) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: themeService.subtextColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Helper class for PieChart badges
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final double size;

  const _Badge(this.text, this.color, {required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 2,
            color: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text.substring(0, Math.min(1, text.length)),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}