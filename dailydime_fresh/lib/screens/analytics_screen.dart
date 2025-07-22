// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/config/theme.dart';
import 'package:dailydime/widgets/charts/spending_chart.dart';
import 'package:dailydime/widgets/charts/progress_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  
  // Sample data for charts
  final List<SpendingCategory> _spendingCategories = [
    SpendingCategory(name: 'Food', amount: 5600, color: AppTheme.primaryEmerald),
    SpendingCategory(name: 'Transport', amount: 2400, color: AppTheme.primaryBlue),
    SpendingCategory(name: 'Entertainment', amount: 1200, color: AppTheme.accentIndigo),
    SpendingCategory(name: 'Shopping', amount: 3200, color: AppTheme.accentPurple),
    SpendingCategory(name: 'Bills', amount: 4800, color: AppTheme.info),
  ];

  final List<double> _savingsData = [300, 400, 250, 500, 600, 450, 700];
  final List<double> _spendingData = [700, 500, 900, 400, 600, 800, 300];
  final List<double> _incomeData = [1000, 1000, 1500, 1000, 1000, 1200, 1000];
  
  // Transaction history
  final List<Transaction> _transactions = [
    Transaction(
      title: 'Groceries',
      amount: 1850,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Food',
      isExpense: true,
    ),
    Transaction(
      title: 'Salary',
      amount: 45000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: 'Income',
      isExpense: false,
    ),
    Transaction(
      title: 'Uber',
      amount: 350,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Transport',
      isExpense: true,
    ),
    Transaction(
      title: 'Movie Tickets',
      amount: 800,
      date: DateTime.now().subtract(const Duration(days: 4)),
      category: 'Entertainment',
      isExpense: true,
    ),
    Transaction(
      title: 'Coffee',
      amount: 180,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Food',
      isExpense: true,
    ),
  ];
  
  // Financial insights
  final List<FinancialInsight> _financialInsights = [
    FinancialInsight(
      title: 'Top Expense',
      value: 'Food',
      changePercentage: 12,
      isIncreasing: true,
      details: 'Your spending on food increased by 12% compared to last month.',
    ),
    FinancialInsight(
      title: 'Money Saved',
      value: 'KES 3,200',
      changePercentage: 18,
      isIncreasing: true,
      details: 'You saved 18% more this month compared to your average.',
    ),
    FinancialInsight(
      title: 'Daily Average',
      value: 'KES 850',
      changePercentage: 8,
      isIncreasing: false,
      details: 'Your daily spending decreased by 8% compared to last month.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSpending = _spendingCategories.fold(
      0.0, (sum, category) => sum + category.amount);
      
    final totalIncome = _incomeData.fold(0.0, (sum, amount) => sum + amount);
    final totalExpense = _spendingData.fold(0.0, (sum, amount) => sum + amount);
    final savingsRate = ((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1);

    return Column(
      children: [
        // Period selection
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                "Period:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 12),
              _buildPeriodDropdown(),
            ],
          ),
        ),
        
        // Analytics summary
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryEmerald,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    'Income',
                    'KES ${totalIncome.toStringAsFixed(0)}',
                    Icons.arrow_upward,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildSummaryItem(
                    'Expenses',
                    'KES ${totalExpense.toStringAsFixed(0)}',
                    Icons.arrow_downward,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildSummaryItem(
                    'Savings Rate',
                    '$savingsRate%',
                    Icons.savings,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tab Bar for Analytics
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryEmerald,
            unselectedLabelColor: AppTheme.textMedium,
            indicatorColor: AppTheme.primaryEmerald,
            tabs: const [
              Tab(text: "Overview", icon: Icon(Icons.dashboard_rounded)),
              Tab(text: "Transactions", icon: Icon(Icons.receipt_long)),
              Tab(text: "Insights", icon: Icon(Icons.lightbulb_outline)),
            ],
          ),
        ),
        
        // Tab Bar View for Analytics Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(totalSpending),
              _buildTransactionsTab(),
              _buildInsightsTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          isDense: true,
          items: <String>['This Week', 'This Month', 'Last Month', 'Last 3 Months', 'This Year']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPeriod = newValue;
              });
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewTab(double totalSpending) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spending chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending by Category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: SpendingChart(
                      categories: _spendingCategories,
                      totalSpending: totalSpending,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Weekly spending chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weekly Spending",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart(
                      weeklyData: _spendingData,
                      title: "",
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Income vs Expenses
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Income vs Expenses",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildIncomeExpenseChart(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Saving Progress
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Savings Progress",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGoalProgressItem(
                    title: "New Headphones",
                    current: 9500,
                    target: 15000,
                    color: AppTheme.primaryEmerald,
                    icon: Icons.headphones,
                  ),
                  const SizedBox(height: 12),
                  _buildGoalProgressItem(
                    title: "Weekend Trip",
                    current: 12000,
                    target: 30000,
                    color: AppTheme.primaryBlue,
                    icon: Icons.flight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Transactions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction list
          ..._transactions.map((transaction) => _buildTransactionItem(transaction)),
          
          const SizedBox(height: 24),
          
          // Transaction Analytics
          Text(
            "Transaction Analytics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction count by day
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Transaction Frequency",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTransactionFrequencyChart(),
                  const SizedBox(height: 16),
                  Text(
                    "You make the most transactions on Fridays and Saturdays.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Average transaction amount
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Average Transaction Amount",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAverageAmountItem(
                        "Income",
                        "KES 12,500",
                        Icons.arrow_upward,
                        AppTheme.success,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppTheme.textLight,
                      ),
                      _buildAverageAmountItem(
                        "Expense",
                        "KES 650",
                        Icons.arrow_downward,
                        AppTheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Financial Insights",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "AI-powered analysis of your financial behavior",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          
          // Financial insight cards
          ..._financialInsights.map((insight) => _buildFinancialInsightCard(insight)),
          
          const SizedBox(height: 20),
          
          // Spending pattern
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending Pattern Analysis",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSpendingPatternChart(),
                  const SizedBox(height: 16),
                  Text(
                    "AI Insight: Your spending peaks during weekends and at the beginning of the month. Consider setting aside a specific budget for weekend activities.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Budget efficiency
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Budget Efficiency",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBudgetEfficiencyChart(),
                  const SizedBox(height: 16),
                  Text(
                    "AI Insight: Your food budget is consistently overspent while your entertainment budget is underutilized. Consider reallocating KES 1,000 from entertainment to food.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIncomeExpenseChart() {
    // Sample data
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: _incomeData[index] / 15,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: _spendingData[index] / 15,
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) => Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMedium,
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Income",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Expenses",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionItem(Transaction transaction) {
    final bool isExpense = transaction.isExpense;
    final String formattedDate = DateFormat('MMM d, yyyy').format(transaction.date);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpense ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: isExpense ? AppTheme.error : AppTheme.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              "${isExpense ? '-' : '+'} KES ${transaction.amount.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isExpense ? AppTheme.error : AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionFrequencyChart() {
    // Sample data
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<int> transactionCounts = [3, 5, 2, 4, 8, 7, 3];
    final int maxCount = transactionCounts.reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final double barHeight = (transactionCounts[index] / maxCount) * 120;
          
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald,
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryEmerald,
                        AppTheme.primaryBlue,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${transactionCounts[index]}",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildAverageAmountItem(String title, String amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFinancialInsightCard(FinancialInsight insight) {
    final isPositive = insight.isIncreasing == (insight.title == 'Money Saved');
    final changeColor = isPositive ? AppTheme.success : AppTheme.error;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        changeIcon,
                        size: 12,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        "${insight.changePercentage}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              insight.details,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpendingPatternChart() {
    // Sample data for spending pattern over time of month
    final List<String> periods = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    final List<double> weeklyAmounts = [12500, 8900, 6500, 15000];
    final double maxAmount = weeklyAmounts.reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                final double barHeight = (weeklyAmounts[index] / maxAmount) * 150;
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primaryEmerald,
                                AppTheme.primaryBlue.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          periods[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "KES ${weeklyAmounts[index].toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetEfficiencyChart() {
    // Sample data for budget vs actual spending
    final List<BudgetItem> budgetItems = [
      BudgetItem(category: 'Food', budgeted: 5000, actual: 5600),
      BudgetItem(category: 'Transport', budgeted: 3000, actual: 2400),
      BudgetItem(category: 'Entertainment', budgeted: 2000, actual: 1200),
      BudgetItem(category: 'Shopping', budgeted: 2500, actual: 3200),
      BudgetItem(category: 'Bills', budgeted: 4500, actual: 4800),
    ];
    
    return Column(
      children: [
        ...budgetItems.map((item) => _buildBudgetEfficiencyItem(item)),
      ],
    );
  }
  
  Widget _buildBudgetEfficiencyItem(BudgetItem item) {
    final efficiency = (item.actual / item.budgeted) * 100;
    final isOverBudget = item.actual > item.budgeted;
    final color = isOverBudget ? AppTheme.error : AppTheme.success;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                "${efficiency.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              // Budget line (100%)
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Actual spending
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.7 * (item.actual / item.budgeted),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "KES ${item.actual.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
              Text(
                "KES ${item.budgeted.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalProgressItem({
    required String title,
    required double current,
    required double target,
    required Color color,
    required IconData icon,
  }) {
    final progress = current / target;
    
    return Row(
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
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: MediaQuery.of(context).size.width * 0.6 * progress, // Adjust width based on progress
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "KES ${current.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "KES ${target.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Transaction {
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isExpense;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
  });
}

class FinancialInsight {
  final String title;
  final String value;
  final double changePercentage;
  final bool isIncreasing;
  final String details;

  FinancialInsight({
    required this.title,
    required this.value,
    required this.changePercentage,
    required this.isIncreasing,
    required this.details,
  });
}

class BudgetItem {
  final String category;
  final double budgeted;
  final double actual;

  BudgetItem({
    required this.category,
    required this.budgeted,
    required this.actual,
  });
}