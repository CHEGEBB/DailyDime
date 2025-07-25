// lib/screens/budget/budget_screen.dart
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/providers/budget_provider.dart';
import 'package:dailydime/screens/budget/create_budget_screen.dart';
import 'package:dailydime/services/budget_ai_service.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with SingleTickerProviderStateMixin {
  String _selectedTimeframe = 'This Month';
  final List<String> _timeframes = ['This Month', 'Last Month', 'This Week', 'Custom'];
  
  late TabController _tabController;
  final List<String> _tabTitles = ['Overview', 'Categories', 'Insights'];
  
  List<String> _aiInsights = [];
  bool _loadingInsights = true;
  
  // Weekly spending data
  final List<FlSpot> _weeklySpendingData = [
    const FlSpot(1, 15000),
    const FlSpot(2, 10200),
    const FlSpot(3, 8700),
    const FlSpot(4, 12500),
    const FlSpot(5, 9300),
    const FlSpot(6, 14200),
    const FlSpot(7, 11800),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    
    // Initialize budget provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      budgetProvider.initialize().then((_) {
        _loadAIInsights();
      });
    });
  }
  
  Future<void> _loadAIInsights() async {
    setState(() {
      _loadingInsights = true;
    });
    
    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final insights = await budgetProvider.getBudgetInsights();
      
      setState(() {
        _aiInsights = insights;
        _loadingInsights = false;
      });
    } catch (e) {
      setState(() {
        _aiInsights = [
          'Try to keep your daily spending consistent to stay within budget.',
          'Consider setting up automatic savings to reach your goals faster.',
          'Reviewing your budget weekly helps you stay on track.',
        ];
        _loadingInsights = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF26D07C); // Emerald green
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          final isLoading = budgetProvider.isLoading;
          final budgets = budgetProvider.budgets;
          final totalBudget = budgetProvider.totalBudgetAmount;
          final totalSpent = budgetProvider.totalSpent;
          final percentageUsed = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
          final highestCategory = budgetProvider.highestSpendingCategory;
          
          return SafeArea(
            child: Column(
              children: [
                // Budget Overview Card - Responsive and No Overflow
                Container(
                  height: MediaQuery.of(context).size.height * 0.28,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildBudgetOverviewCard(
                    isLoading: isLoading,
                    totalBudget: totalBudget,
                    totalSpent: totalSpent,
                    percentageUsed: percentageUsed,
                    accentColor: accentColor,
                    highestCategory: highestCategory,
                  ),
                ),
                
                // Tab Bar - No line divider
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: _tabTitles.map((title) => Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(title),
                      ),
                    )).toList(),
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(isLoading, budgets, accentColor),
                      _buildCategoriesTab(isLoading, budgets, accentColor),
                      _buildInsightsTab(isLoading, accentColor),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBudgetScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF26D07C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Budget', style: TextStyle(color: Colors.white)),
      ),
    );
  }
  
  Widget _buildBudgetOverviewCard({
    required bool isLoading,
    required double totalBudget,
    required double totalSpent,
    required double percentageUsed,
    required Color accentColor,
    required String highestCategory,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            accentColor.withOpacity(0.8),
            accentColor.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/pattern5.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Budget Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedTimeframe,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                            offset: const Offset(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (String value) {
                              setState(() {
                                _selectedTimeframe = value;
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              return _timeframes.map((String timeframe) {
                                return PopupMenuItem<String>(
                                  value: timeframe,
                                  child: Text(timeframe),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Spending amount
                if (isLoading)
                  Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white.withOpacity(0.9),
                    child: Container(
                      height: 32,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'KES ${totalSpent.toInt()}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'spent of KES ${totalBudget.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 12),
                
                // Progress bar
                if (isLoading)
                  Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white.withOpacity(0.9),
                    child: Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 
                                  (percentageUsed > 1.0 ? 0.85 : percentageUsed * 0.85),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: percentageUsed > 0.9
                                      ? [Colors.red.shade300, Colors.red.shade500]
                                      : [Colors.white, Colors.white.withOpacity(0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(percentageUsed * 100).toInt()}% used',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'KES ${(totalBudget - totalSpent).toInt()} left',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                const SizedBox(height: 16),
                
                // Budget metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricColumn(
                      'KES ${totalBudget > 0 ? ((totalBudget - totalSpent) / 30).toInt() : 0}/day',
                      'Personal',
                      Icons.person_outline,
                      Colors.white,
                    ),
                    Container(
                      height: 30,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              percentageUsed > 0.9 ? Icons.warning : Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              percentageUsed > 0.9 
                                  ? 'Budget warning!' 
                                  : 'On Track',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
    );
  }
  
  Widget _buildMetricColumn(String value, String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewTab(bool isLoading, List<Budget> budgets, Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly spending chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
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
              const Text(
                'Weekly Spending Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'See how your spending changes over time',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              String text;
                              switch (value.toInt()) {
                                case 1:
                                  text = 'Mon';
                                  break;
                                case 3:
                                  text = 'Wed';
                                  break;
                                case 5:
                                  text = 'Fri';
                                  break;
                                case 7:
                                  text = 'Sun';
                                  break;
                                default:
                                  return Container();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(text, style: style),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5000,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return Container();
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  '${(value / 1000).toInt()}K',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 1,
                      maxX: 7,
                      minY: 0,
                      maxY: 20000,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _weeklySpendingData,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.5),
                              accentColor,
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: accentColor,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withOpacity(0.3),
                                accentColor.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // AI Insights Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Budget Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart recommendations based on your spending',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_loadingInsights)
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 12,
                                    width: MediaQuery.of(context).size.width * 0.6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                ..._aiInsights.take(3).map((insight) {
                  final color = _getInsightColor(insight);
                  final icon = _getInsightIcon(insight);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInsightItem(
                      insight,
                      color,
                      icon,
                    ),
                  );
                }).toList(),
              
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    _tabController.animateTo(2); // Switch to Insights tab
                  },
                  icon: Icon(
                    Icons.smart_toy,
                    size: 16,
                    color: accentColor,
                  ),
                  label: Text(
                    'View All Insights',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Recent active budgets
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBudgetScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Budget'),
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (isLoading)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (budgets.isEmpty)
          _buildEmptyBudgetsCard(accentColor)
        else
          Column(
            children: budgets.take(3).map((budget) {
              return _buildBudgetListItem(context, budget, accentColor);
            }).toList(),
          ),
        
        const SizedBox(height: 16),
        
        if (budgets.length > 3)
          TextButton(
            onPressed: () {
              _tabController.animateTo(1); // Switch to Categories tab
            },
            child: Text(
              'View All Budgets',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildCategoriesTab(bool isLoading, List<Budget> budgets, Color accentColor) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    
    if (budgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _buildEmptyBudgetsCard(accentColor),
      );
    }
    
    // Group budgets by period
    final dailyBudgets = budgets.where((b) => b.period == BudgetPeriod.daily).toList();
    final weeklyBudgets = budgets.where((b) => b.period == BudgetPeriod.weekly).toList();
    final monthlyBudgets = budgets.where((b) => b.period == BudgetPeriod.monthly).toList();
    final yearlyBudgets = budgets.where((b) => b.period == BudgetPeriod.yearly).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Monthly budgets section
        if (monthlyBudgets.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Monthly Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...monthlyBudgets.map((budget) => 
            _buildBudgetListItem(context, budget, accentColor)
          ),
          const SizedBox(height: 16),
        ],
        
        // Weekly budgets section
        if (weeklyBudgets.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Weekly Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...weeklyBudgets.map((budget) => 
            _buildBudgetListItem(context, budget, accentColor)
          ),
          const SizedBox(height: 16),
        ],
        
        // Daily budgets section
        if (dailyBudgets.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Daily Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...dailyBudgets.map((budget) => 
            _buildBudgetListItem(context, budget, accentColor)
          ),
          const SizedBox(height: 16),
        ],
        
        // Yearly budgets section
        if (yearlyBudgets.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Yearly Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...yearlyBudgets.map((budget) => 
            _buildBudgetListItem(context, budget, accentColor)
          ),
          const SizedBox(height: 16),
        ],
        
        // Create budget button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CustomButton(
            isSmall: false,
            text: 'Create New Budget',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateBudgetScreen(),
                ),
              );
            },
            icon: Icons.add,
            buttonColor: Colors.blue,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInsightsTab(bool isLoading, Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Insights header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Budget Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-powered insights to help you manage your finances',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Insights content
        if (_loadingInsights)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (_aiInsights.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
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
              children: [
                Lottie.asset(
                  'assets/animations/empty.json',
                  height: 120,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No insights available yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create more budgets and add transactions to get personalized insights',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _aiInsights.map((insight) {
              final color = _getInsightColor(insight);
              final icon = _getInsightIcon(insight);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getInsightTitle(insight),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            insight,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        
        const SizedBox(height: 24),
        
        // Refresh insights button
        CustomButton(
          isSmall: false,
          text: 'Refresh Insights',
          onPressed: _loadAIInsights,
          icon: Icons.refresh,
          buttonColor: Colors.blue,
        ),
      ],
    );
  }
  
  Widget _buildInsightItem(String text, Color color, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBudgetListItem(BuildContext context, Budget budget, Color accentColor) {
    final percentageUsed = budget.percentageUsed;
    final isOverBudget = budget.isOverBudget;
    final Color progressColor = isOverBudget 
        ? Colors.red
        : percentageUsed > 0.8 
            ? Colors.orange
            : budget.color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: Key(budget.id),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete Budget"),
                content: Text("Are you sure you want to delete ${budget.title} budget?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
          budgetProvider.deleteBudget(budget.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${budget.title} budget deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  budgetProvider.createBudget(budget);
                },
              ),
            ),
          );
        },
        child: InkWell(
          onTap: () => _showBudgetDetails(context, budget, accentColor),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: budget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        budget.icon,
                        color: budget.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getPeriodText(budget.period),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (isOverBudget)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Over',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            _handleBudgetAction(context, value, budget);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Budget'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, size: 18),
                                  SizedBox(width: 8),
                                  Text('Reset Spent'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    budget.isActive ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(budget.isActive ? 'Deactivate' : 'Activate'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KES ${budget.spent.toInt()}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isOverBudget ? Colors.red : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'of KES ${budget.amount.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isOverBudget 
                              ? '-KES ${(budget.spent - budget.amount).toInt()}'
                              : 'KES ${budget.remaining.toInt()} left',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isOverBudget ? Colors.red : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(percentageUsed * 100).toInt()}% used',
                          style: TextStyle(
                            fontSize: 12,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentageUsed > 1.0 ? 1.0 : percentageUsed,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _handleBudgetAction(BuildContext context, String action, Budget budget) {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateBudgetScreen(budgetToEdit: budget),
          ),
        );
        break;
      case 'reset':
        // Reset spent amount
        budgetProvider.resetBudgetSpent(budget.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${budget.title} spending reset to 0')),
        );
        break;
      case 'toggle':
        // Toggle active status
        budgetProvider.toggleBudgetStatus(budget.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              budget.isActive
                  ? '${budget.title} budget deactivated'
                  : '${budget.title} budget activated'
            ),
          ),
        );
        break;
      case 'delete':
        // Show confirmation dialog and delete
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete Budget"),
              content: Text("Are you sure you want to delete ${budget.title} budget?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    budgetProvider.deleteBudget(budget.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${budget.title} budget deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            budgetProvider.createBudget(budget);
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
        break;
    }
  }
  
  void _showBudgetDetails(BuildContext context, Budget budget, Color accentColor) {
    final percentageUsed = budget.percentageUsed;
    final isOverBudget = budget.isOverBudget;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: budget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      budget.icon,
                      color: budget.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPeriodText(budget.period),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: budget.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Budget',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${budget.amount.toInt()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Spent So Far',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${budget.spent.toInt()}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isOverBudget ? Colors.red : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentageUsed > 1.0 ? 1.0 : percentageUsed,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget 
                              ? Colors.red
                              : percentageUsed > 0.8 
                                  ? Colors.orange
                                  : budget.color,
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(percentageUsed * 100).toInt()}% used',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOverBudget ? Colors.red : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          isOverBudget 
                              ? 'Overspent by KES ${(budget.spent - budget.amount).toInt()}'
                              : 'KES ${budget.remaining.toInt()} remaining',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOverBudget ? Colors.red : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Budget Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Category', budget.category),
              _buildDetailRow('Period', _getPeriodText(budget.period)),
              _buildDetailRow('Created', DateFormat('MMM dd, yyyy').format(budget.createdAt ?? DateTime.now())),
              if (budget.tags.isNotEmpty)
                _buildDetailRow('Tags', budget.tags.join(', ')),
              if (budget.notes.isNotEmpty)
                _buildDetailRow('Notes', budget.notes),
              const SizedBox(height: 24),
              const Text(
                'Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateBudgetScreen(budgetToEdit: budget),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Budget'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
                        budgetProvider.resetBudgetSpent(budget.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${budget.title} spending reset to 0')),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Spent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
                  
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Delete Budget"),
                        content: Text("Are you sure you want to delete ${budget.title} budget?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              budgetProvider.deleteBudget(budget.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${budget.title} budget deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      budgetProvider.createBudget(budget);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete Budget', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyBudgetsCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Lottie.asset(
            'assets/animations/empty.json',
            height: 150,
          ),
          const SizedBox(height: 16),
          const Text(
            'No budgets created yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first budget to track your spending and save money',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateBudgetScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create Your First Budget'),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  String _getPeriodText(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Daily Budget';
      case BudgetPeriod.weekly:
        return 'Weekly Budget';
      case BudgetPeriod.monthly:
        return 'Monthly Budget';
      case BudgetPeriod.yearly:
        return 'Yearly Budget';
    }
  }
  
  Color _getInsightColor(String insight) {
    final insightLower = insight.toLowerCase();
    
    if (insightLower.contains('over budget') || 
        insightLower.contains('exceeded') ||
        insightLower.contains('reduce') ||
        insightLower.contains('too much') ||
        insightLower.contains('high spending')) {
      return Colors.orange;
    } else if (insightLower.contains('save') || 
               insightLower.contains('opportunity') ||
               insightLower.contains('could') ||
               insightLower.contains('potential')) {
      return Colors.green;
    } else if (insightLower.contains('recurring') || 
               insightLower.contains('subscription') ||
               insightLower.contains('regular')) {
      return Colors.purple;
    } else if (insightLower.contains('trend') || 
               insightLower.contains('pattern') ||
               insightLower.contains('history')) {
      return Colors.blue;
    } else {
      return Colors.blueGrey;
    }
  }
  
  IconData _getInsightIcon(String insight) {
    final insightLower = insight.toLowerCase();
    
    if (insightLower.contains('over budget') || 
        insightLower.contains('exceeded') ||
        insightLower.contains('reduce') ||
        insightLower.contains('too much') ||
        insightLower.contains('high spending')) {
      return Icons.warning;
    } else if (insightLower.contains('save') || 
               insightLower.contains('opportunity') ||
               insightLower.contains('could') ||
               insightLower.contains('potential')) {
      return Icons.savings;
    } else if (insightLower.contains('recurring') || 
               insightLower.contains('subscription') ||
               insightLower.contains('regular')) {
      return Icons.repeat;
    } else if (insightLower.contains('trend') || 
               insightLower.contains('pattern') ||
               insightLower.contains('history')) {
      return Icons.trending_up;
    } else {
      return Icons.lightbulb;
    }
  }
  
  String _getInsightTitle(String insight) {
    final insightLower = insight.toLowerCase();
    
    if (insightLower.contains('over budget') || 
        insightLower.contains('exceeded') ||
        insightLower.contains('reduce') ||
        insightLower.contains('too much') ||
        insightLower.contains('high spending')) {
      return 'Spending Alert';
    } else if (insightLower.contains('save') || 
               insightLower.contains('opportunity') ||
               insightLower.contains('could') ||
               insightLower.contains('potential')) {
      return 'Saving Opportunity';
    } else if (insightLower.contains('recurring') || 
               insightLower.contains('subscription') ||
               insightLower.contains('regular')) {
      return 'Recurring Expense';
    } else if (insightLower.contains('trend') || 
               insightLower.contains('pattern') ||
               insightLower.contains('history')) {
      return 'Spending Pattern';
    } else {
      return 'Smart Insight';
    }
  }
}