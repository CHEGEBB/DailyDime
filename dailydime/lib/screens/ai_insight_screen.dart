// lib/screens/ai_insights_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/models/insight_model.dart';
import 'package:dailydime/services/ai_insight_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/balance_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/screens/analytics_screen.dart';
import 'package:dailydime/widgets/empty_state.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> with SingleTickerProviderStateMixin {
  final AIInsightService _aiService = AIInsightService();
  final AppwriteService _appwriteService = AppwriteService();
  final BalanceService _balanceService = BalanceService.instance;
  
  late TabController _tabController;
  
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  double _currentBalance = 0.0;
  
  List<InsightModel> _insights = [];
  Map<String, dynamic> _forecastData = {};
  List<Map<String, dynamic>> _budgetRecommendations = [];
  
  bool _isLoading = true;
  bool _isGeneratingInsights = false;
  bool _showChat = false;
  String _userQuestion = '';
  String _aiResponse = '';
  bool _isTyping = false;
  
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Try to load transactions from SMS if available
    final smsService = SmsService(); // Fixed: Use correct class name (SmsService, not SMSService)
    
    // Initialize SMS service first
    final isInitialized = await smsService.initialize();
    
    if (isInitialized) {
      // Load historical M-Pesa messages (this method exists in SmsService)
      final smsTransactions = await smsService.loadHistoricalMpesaMessages();
      
      if (smsTransactions.isNotEmpty) {
        _transactions = smsTransactions;
      } else {
        // Fall back to stored transactions if SMS loading fails
        _transactions = await _appwriteService.getTransactions();
      }
    } else {
      // Fall back to stored transactions if SMS initialization fails
      _transactions = await _appwriteService.getTransactions();
    }
    
    // Load budgets and savings goals
    _budgets = await _appwriteService.getBudgets();
    _savingsGoals = await _appwriteService.getSavingsGoals();
    
    // Get current balance
    _currentBalance = await _balanceService.getCurrentBalance();
    
    // Generate insights if we have data
    if (_transactions.isNotEmpty || _budgets.isNotEmpty || _savingsGoals.isNotEmpty || _currentBalance > 0) {
      await _generateInsights();
    } else {
      // Just clear loading state if no data
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Error loading data: $e');
    
    // Try to load from Appwrite as fallback
    try {
      _transactions = await _appwriteService.getTransactions();
      _budgets = await _appwriteService.getBudgets();
      _savingsGoals = await _appwriteService.getSavingsGoals();
      _currentBalance = await _balanceService.getCurrentBalance();
      
      if (_transactions.isNotEmpty || _budgets.isNotEmpty || _savingsGoals.isNotEmpty || _currentBalance > 0) {
        await _generateInsights();
      }
    } catch (fallbackError) {
      debugPrint('Fallback loading also failed: $fallbackError');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
}
  
  Future<void> _generateInsights() async {
    if (_isGeneratingInsights) return;
    
    setState(() {
      _isGeneratingInsights = true;
    });
    
    try {
      // Generate general insights
      final insightsList = await _aiService.generateInsights(
        transactions: _transactions,
        budgets: _budgets,
        savingsGoals: _savingsGoals,
        currentBalance: _currentBalance,
      );
      
      // Generate spending forecast
      if (_transactions.isNotEmpty) {
        _forecastData = await _aiService.generateSpendingForecast(_transactions);
      }
      
      // Generate budget recommendations if we have income data
      final incomeTransactions = _transactions.where((t) => !t.isExpense).toList();
      if (incomeTransactions.isNotEmpty) {
        final monthlyIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
        _budgetRecommendations = await _aiService.generateBudgetRecommendations(
          _transactions, 
          monthlyIncome,
        );
      }
      
      // Convert insights to InsightModel objects
      final List<InsightModel> insights = [];
      
      for (final insight in insightsList) {
        // Determine icon based on type
        IconData icon = _getIconForInsightType(insight['type'] ?? 'spending');
        
        // Determine color based on priority
        Color color = _getColorForPriority(insight['priority'] ?? 'medium');
        
        // Create chart data if needed
        Map<String, dynamic>? chartData;
        bool showChart = false;
        
        if (insight['type'] == 'spending' || insight['type'] == 'income') {
          chartData = _createChartDataForInsight(insight);
          showChart = chartData != null;
        }
        
        insights.add(InsightModel(
          id: 'insight_${DateTime.now().millisecondsSinceEpoch}_${insights.length}',
          title: insight['title'] ?? 'Financial Insight',
          description: insight['description'] ?? 'No description provided',
          icon: insight['icon'] != null 
              ? IconData(int.parse(insight['icon']), fontFamily: 'MaterialIcons')
              : icon,
          color: color,
          isActionable: true,
          actionText: 'Learn More',
          actionRoute: '/insights/details',
          createdAt: DateTime.now(),
          category: insight['type'] ?? 'general',
          isAiGenerated: true,
          chartData: chartData,
          showChart: showChart,
        ));
      }
      
      // Add fallback insight if none were generated
      if (insights.isEmpty && _transactions.isNotEmpty) {
        insights.add(InsightModel(
          id: 'fallback_insight_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Your Financial Overview',
          description: 'You have ${_transactions.length} transactions recorded. Tap to see your spending analytics.',
          icon: Icons.analytics_outlined,
          color: Colors.blue,
          isActionable: true,
          actionText: 'View Analytics',
          actionRoute: '/analytics',
          createdAt: DateTime.now(),
          category: 'general',
          isAiGenerated: true,
        ));
      }
      
      setState(() {
        _insights = insights;
        _isGeneratingInsights = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error generating insights: $e');
      setState(() {
        _isGeneratingInsights = false;
        _isLoading = false;
      });
    }
  }
  
  IconData _getIconForInsightType(String type) {
    switch (type.toLowerCase()) {
      case 'spending':
        return Icons.shopping_cart_outlined;
      case 'saving':
      case 'savings':
        return Icons.savings_outlined;
      case 'budget':
        return Icons.account_balance_wallet_outlined;
      case 'income':
        return Icons.attach_money;
      case 'balance':
        return Icons.account_balance_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }
  
  Color _getColorForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
  
  Map<String, dynamic>? _createChartDataForInsight(Map<String, dynamic> insight) {
    // For spending insights, create a simple trend chart
    if (insight['type'] == 'spending') {
      // Generate some random data for demonstration
      // In a real app, this would come from the actual data
      final random = Random();
      final List<double> values = List.generate(
        7, 
        (_) => 5000 + random.nextDouble() * 10000,
      );
      
      return {
        'type': 'line',
        'data': values,
        'labels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      };
    }
    
    // For income insights, create a bar chart
    if (insight['type'] == 'income') {
      final random = Random();
      final List<double> values = List.generate(
        3, 
        (_) => 25000 + random.nextDouble() * 10000,
      );
      
      return {
        'type': 'bar',
        'data': values,
        'labels': ['Last Month', 'This Month', 'Forecast'],
      };
    }
    
    return null;
  }
  
  Future<void> _askAIQuestion(String question) async {
    if (question.trim().isEmpty) return;
    
    setState(() {
      _isTyping = true;
      _userQuestion = question;
      _questionController.clear();
    });
    
    try {
      final response = await _aiService.answerFinancialQuestion(
        question,
        _transactions,
      );
      
      setState(() {
        _aiResponse = response;
        _isTyping = false;
      });
      
      // Scroll to bottom to show response
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _aiResponse = "I'm sorry, I couldn't process your question at the moment. Please try again later.";
        _isTyping = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    return Scaffold(
      body: _isLoading 
          ? _buildLoadingState(themeService)
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildHeader(themeService),
                  ),
                  SliverToBoxAdapter(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: themeService.primaryColor,
                      unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                      indicatorColor: themeService.primaryColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'Insights'),
                        Tab(text: 'Recommendations'),
                        Tab(text: 'AI Chat'),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildInsightsTab(themeService),
                  _buildRecommendationsTab(themeService),
                  _buildAIChatTab(themeService),
                ],
              ),
            ),
      floatingActionButton: _isLoading || _tabController.index == 2
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (_isGeneratingInsights) return;
                _generateInsights();
              },
              backgroundColor: themeService.primaryColor,
              child: _isGeneratingInsights
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.refresh, color: Colors.white),
            ),
    );
  }
  
  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.isDarkMode 
                ? const Color(0xFF196F3D).withOpacity(0.9)
                : const Color(0xFF2ECC71),
            themeService.isDarkMode
                ? const Color(0xFF0E6655).withOpacity(0.9)
                : const Color(0xFF1ABC9C),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Smart recommendations based on your financial data',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _insights.isEmpty
                        ? 'Add transactions to get personalized AI insights'
                        : 'You have ${_insights.length} new insights',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
  
  Widget _buildLoadingState(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          _buildHeader(themeService),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Column(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Analyzing your financial data...',
                  style: TextStyle(
                    color: themeService.textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsTab(ThemeService themeService) {
    if (_insights.isEmpty) {
      return EmptyState(
        title: 'No Insights Yet',
        message: 'Add transactions to get personalized insights powered by AI.',
        animation: 'assets/animations/empty_insights.json',
        buttonText: 'Add Transaction',
        onButtonPressed: () {
          Navigator.of(context).pushNamed('/transactions/add');
        },
      );
    }
    
    return RefreshIndicator(
      onRefresh: _generateInsights,
      color: themeService.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _insights.length,
        itemBuilder: (context, index) {
          final insight = _insights[index];
          return _buildInsightCard(insight, themeService);
        },
      ),
    );
  }
  
  Widget _buildInsightCard(InsightModel insight, ThemeService themeService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: insight.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    insight.icon,
                    color: insight.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: TextStyle(
                          color: themeService.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.description,
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (insight.showChart && insight.chartData != null)
            _buildInsightChart(insight.chartData!, themeService),
          if (insight.isActionable)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (insight.actionRoute == '/analytics') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AnalyticsScreen(
                              transactions: _transactions,
                              forecastData: _forecastData,
                            ),
                          ),
                        );
                      } else {
                        // For other routes
                        Navigator.of(context).pushNamed(insight.actionRoute!);
                      }
                    },
                    child: Text(
                      insight.actionText ?? 'Learn More',
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.w500,
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
  
  Widget _buildInsightChart(Map<String, dynamic> chartData, ThemeService themeService) {
    final chartType = chartData['type'] as String? ?? 'line';
    final data = chartData['data'] as List<dynamic>? ?? [];
    final labels = chartData['labels'] as List<dynamic>? ?? [];
    
    if (data.isEmpty || labels.isEmpty) return const SizedBox.shrink();
    
    switch (chartType) {
      case 'line':
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
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
                      if (value.toInt() >= 0 && value.toInt() < labels.length) {
                        return Text(
                          labels[value.toInt()].toString(),
                          style: TextStyle(
                            color: themeService.subtextColor,
                            fontSize: 10,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 22,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    data.length,
                    (i) => FlSpot(i.toDouble(), data[i].toDouble()),
                  ),
                  isCurved: true,
                  color: themeService.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: themeService.primaryColor.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        );
        
      case 'bar':
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[value.toInt()].toString(),
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
              barGroups: List.generate(
                data.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].toDouble(),
                      color: themeService.primaryColor,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: data.reduce((a, b) => max(a, b)).toDouble() * 1.1,
                        color: themeService.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildRecommendationsTab(ThemeService themeService) {
    if (_budgetRecommendations.isEmpty) {
      return EmptyState(
        title: 'No Recommendations Yet',
        message: 'We need more transaction data to generate budget recommendations.',
        animation: 'assets/animations/empty_budget.json',
        buttonText: 'Go to Analytics',
        onButtonPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnalyticsScreen(
                transactions: _transactions,
              ),
            ),
          );
        },
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Budget Recommendations',
          style: TextStyle(
            color: themeService.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          _budgetRecommendations.length,
          (index) => _buildBudgetRecommendationCard(
            _budgetRecommendations[index],
            themeService,
          ),
        ),
        const SizedBox(height: 24),
        if (_forecastData.isNotEmpty) ...[
          Text(
            'Spending Forecast',
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildForecastCard(themeService),
        ],
        const SizedBox(height: 24),
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
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: themeService.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Financial Tip',
                      style: TextStyle(
                        color: themeService.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Following the 50/30/20 rule can help you balance needs, wants, and savings. 50% for needs, 30% for wants, and 20% for savings and debt repayment.',
                  style: TextStyle(
                    color: themeService.subtextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _tabController.animateTo(2);
                      },
                      child: Text(
                        'Ask AI for More Tips',
                        style: TextStyle(
                          color: themeService.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBudgetRecommendationCard(
    Map<String, dynamic> recommendation,
    ThemeService themeService,
  ) {
    final category = recommendation['category'] ?? 'Category';
    final recommendedAmount = recommendation['recommended_amount'] ?? 0.0;
    final percentOfIncome = recommendation['percent_of_income'] ?? 0.0;
    final currentSpending = recommendation['current_spending'] ?? 0.0;
    final adjustmentNeeded = recommendation['adjustment_needed'] ?? 0.0;
    final priority = recommendation['priority'] ?? 'essential';
    
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'essential':
        priorityColor = Colors.blue;
        break;
      case 'wants':
        priorityColor = Colors.orange;
        break;
      case 'savings':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended',
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
                      ).format(recommendedAmount),
                      style: TextStyle(
                        color: themeService.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${percentOfIncome.toStringAsFixed(1)}% of income',
                      style: TextStyle(
                        color: themeService.subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Spending',
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
                      ).format(currentSpending),
                      style: TextStyle(
                        color: themeService.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      adjustmentNeeded >= 0
                          ? 'Increase by ${NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(adjustmentNeeded.abs())}'
                          : 'Reduce by ${NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(adjustmentNeeded.abs())}',
                      style: TextStyle(
                        color: adjustmentNeeded >= 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: currentSpending / recommendedAmount,
                backgroundColor: themeService.isDarkMode 
                    ? Colors.grey[800] 
                    : Colors.grey[200],
                color: currentSpending <= recommendedAmount
                    ? Colors.green
                    : Colors.red,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Create a new budget based on recommendation
                    Navigator.of(context).pushNamed('/budgets/add', arguments: {
                      'category': category,
                      'amount': recommendedAmount,
                    });
                  },
                  child: const Text('Create Budget'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildForecastCard(ThemeService themeService) {
    if (_forecastData.isEmpty) return const SizedBox.shrink();
    
    final totalForecast = _forecastData['total_forecast'] as double? ?? 0.0;
    final comparison = _forecastData['previous_month_comparison'] as Map<String, dynamic>? ?? {};
    final percentChange = comparison['percent_change'] as double? ?? 0.0;
    
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
                Icon(
                  Icons.calendar_today,
                  color: themeService.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Next 30 Days Forecast',
                  style: TextStyle(
                    color: themeService.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              NumberFormat.currency(
                symbol: 'KES ',
                decimalDigits: 0,
              ).format(totalForecast),
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  percentChange > 0 ? Icons.trending_up : Icons.trending_down,
                  color: percentChange > 0 ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentChange.abs().toStringAsFixed(1)}% ${percentChange > 0 ? 'more than' : 'less than'} last month',
                  style: TextStyle(
                    color: percentChange > 0 ? Colors.red : Colors.green,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AnalyticsScreen(
                      transactions: _transactions,
                      forecastData: _forecastData,
                    ),
                  ),
                );
              },
              child: Text(
                'See Detailed Forecast',
                style: TextStyle(
                  color: themeService.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAIChatTab(ThemeService themeService) {
    return Column(
      children: [
        Expanded(
          child: _userQuestion.isEmpty && _aiResponse.isEmpty
              ? _buildChatEmptyState(themeService)
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_userQuestion.isNotEmpty)
                      _buildUserMessageBubble(_userQuestion, themeService),
                    if (_isTyping)
                      _buildTypingIndicator(themeService)
                    else if (_aiResponse.isNotEmpty)
                      _buildAIMessageBubble(_aiResponse, themeService),
                  ],
                ),
        ),
        _buildChatInputField(themeService),
      ],
    );
  }
  
  Widget _buildChatEmptyState(ThemeService themeService) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/chat_bot.json',
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Ask me anything about your finances',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'I can help with budget recommendations, savings goals, spending analysis, and financial advice.',
              style: TextStyle(
                color: themeService.subtextColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(
                  'How much did I spend last month?',
                  themeService,
                ),
                _buildSuggestionChip(
                  'What\'s my biggest expense category?',
                  themeService,
                ),
                _buildSuggestionChip(
                  'How can I save more money?',
                  themeService,
                ),
                _buildSuggestionChip(
                  'Am I spending too much on food?',
                  themeService,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestionChip(String text, ThemeService themeService) {
    return InkWell(
      onTap: () => _askAIQuestion(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: themeService.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeService.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: themeService.primaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserMessageBubble(String message, ThemeService themeService) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 50),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeService.primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAIMessageBubble(String message, ThemeService themeService) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 50),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeService.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: themeService.textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypingIndicator(ThemeService themeService) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 50),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeService.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(themeService),
            _buildDot(themeService),
            _buildDot(themeService),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDot(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: themeService.subtextColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
  
  Widget _buildChatInputField(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: themeService.scaffoldColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: themeService.isDarkMode 
                      ? Colors.grey[700]! 
                      : Colors.grey[300]!,
                ),
              ),
              child: TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: 'Ask me about your finances...',
                  hintStyle: TextStyle(color: themeService.subtextColor),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: themeService.textColor),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _askAIQuestion,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: themeService.primaryColor,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => _askAIQuestion(_questionController.text),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}