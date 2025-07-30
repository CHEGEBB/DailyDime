// lib/screens/ai_insights_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/models/insight_model.dart';
import 'package:dailydime/services/ai_insight_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/balance_service.dart';
import 'package:dailydime/screens/analytics_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> with TickerProviderStateMixin {
  final AIInsightService _aiService = AIInsightService();
  final AppwriteService _appwriteService = AppwriteService();
  
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  double _currentBalance = 0;
  
  List<Map<String, dynamic>> _insights = [];
  Map<String, dynamic> _forecastData = {};
  List<Map<String, dynamic>> _budgetRecommendations = [];
  List<Map<String, dynamic>> _anomalies = [];
  Map<String, dynamic> _savingsRecommendations = {};
  
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Chat feature
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isAskingQuestion = false;
  final ScrollController _chatScrollController = ScrollController();
  
  // Animation controllers
  late AnimationController _pulseAnimationController;
  
  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _loadData();
  }
  
  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _questionController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
    _hasError = false;
  });
  
  try {
    // Load user data
    final transactionsFuture = _appwriteService.getTransactions();
    final budgetsFuture = _appwriteService.getBudgets();
    final savingsGoalsFuture = _appwriteService.getSavingsGoals();
    final balanceFuture = BalanceService.instance.getCurrentBalance();
    
    // Wait for all data to load - Fixed the casting issue
    final results = await Future.wait([
      transactionsFuture,
      budgetsFuture,
      savingsGoalsFuture,
      balanceFuture,
    ] as Iterable<Future>);
    
    _transactions = results[0] as List<Transaction>;
    _budgets = results[1] as List<Budget>;
    _savingsGoals = results[2] as List<SavingsGoal>;
    _currentBalance = results[3] as double;
    
    // Generate insights if we have transaction data
    if (_transactions.isNotEmpty) {
      await _generateInsights();
    }
    
    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Failed to load data: ${e.toString()}';
    });
  }
}
  Future<void> _generateInsights() async {
    if (_transactions.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Get all AI insights in parallel
      final insightsFuture = _aiService.generateInsights(
        transactions: _transactions,
        budgets: _budgets,
        savingsGoals: _savingsGoals,
        currentBalance: _currentBalance,
      );
      
      final forecastFuture = _aiService.generateSpendingForecast(_transactions);
      
      // Calculate monthly income
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      final monthlyIncome = _transactions
          .where((t) => !t.isExpense && t.date.isAfter(oneMonthAgo))
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final budgetRecommendationsFuture = _aiService.generateBudgetRecommendations(
        _transactions, 
        monthlyIncome,
      );
      
      final anomaliesFuture = _aiService.detectSpendingAnomalies(_transactions);
      
      final savingsRecommendationsFuture = _aiService.generateSavingsRecommendations(
        _transactions,
        monthlyIncome,
        _savingsGoals,
      );
      
      // Wait for all AI requests to complete
      final results = await Future.wait([
        insightsFuture,
        forecastFuture,
        budgetRecommendationsFuture,
        anomaliesFuture,
        savingsRecommendationsFuture,
      ]);
      
      setState(() {
        _insights = results[0] as List<Map<String, dynamic>>;
        _forecastData = results[1] as Map<String, dynamic>;
        _budgetRecommendations = results[2] as List<Map<String, dynamic>>;
        _anomalies = results[3] as List<Map<String, dynamic>>;
        _savingsRecommendations = results[4] as Map<String, dynamic>;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = 'Failed to generate insights: ${e.toString()}';
      });
    }
  }
  
  Future<void> _askQuestion(String question) async {
    if (question.trim().isEmpty) return;
    
    // Add user question to chat
    setState(() {
      _chatHistory.add({
        'isUser': true,
        'message': question,
        'timestamp': DateTime.now(),
      });
      _isAskingQuestion = true;
    });
    
    // Clear input field
    _questionController.clear();
    
    // Scroll to bottom of chat
    _scrollChatToBottom();
    
    try {
      // Get AI response
      final response = await _aiService.answerFinancialQuestion(
        question,
        _transactions,
      );
      
      setState(() {
        _chatHistory.add({
          'isUser': false,
          'message': response,
          'timestamp': DateTime.now(),
        });
        _isAskingQuestion = false;
      });
      
      // Scroll to show the new message
      _scrollChatToBottom();
    } catch (e) {
      setState(() {
        _chatHistory.add({
          'isUser': false,
          'message': "Sorry, I couldn't process your question right now. Please try again later.",
          'timestamp': DateTime.now(),
        });
        _isAskingQuestion = false;
      });
      
      _scrollChatToBottom();
    }
  }
  
  void _scrollChatToBottom() {
    // Wait for UI to update before scrolling
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: _isLoading 
          ? _buildLoadingState(themeService)
          : _hasError
              ? _buildErrorState(themeService)
              : _transactions.isEmpty
                  ? _buildEmptyState(themeService)
                  : _buildInsightsContent(themeService, screenHeight, screenWidth),
    );
  }
  
  Widget _buildLoadingState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset(
              'assets/animations/finance_loading.json',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your financial insights...',
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset(
              'assets/animations/error.json',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeService.subtextColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
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
  
  Widget _buildEmptyState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/animations/empty_chart.json',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add some transactions to get personalized AI insights about your finances',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeService.subtextColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/transactions');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
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
  
  Widget _buildInsightsContent(
    ThemeService themeService,
    double screenHeight,
    double screenWidth,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(themeService),
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: themeService.isDarkMode 
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: themeService.primaryColor,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: themeService.subtextColor,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Insights'),
                          Tab(text: 'Budget'),
                          Tab(text: 'Forecast'),
                          Tab(text: 'Ask AI'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildInsightsTab(themeService),
                          _buildBudgetRecommendationsTab(themeService),
                          _buildForecastTab(themeService),
                          _buildAskAITab(themeService),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: themeService.backgroundColor.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Lottie.asset(
                        'assets/animations/ai_thinking.json',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI is analyzing your finances...',
                      style: TextStyle(
                        color: themeService.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildHeader(ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeService.primaryColor,
            themeService.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Budget Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isProcessing ? null : _generateInsights,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Smart recommendations based on your spending',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsTab(ThemeService themeService) {
    if (_insights.isEmpty) {
      return _buildNoInsightsState(themeService);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_anomalies.isNotEmpty) ...[
            _buildSectionHeader('Attention Needed', themeService),
            const SizedBox(height: 8),
            ..._anomalies.map((anomaly) => _buildAnomalyCard(anomaly, themeService)),
            const SizedBox(height: 24),
          ],
          
          _buildSectionHeader('Smart Insights', themeService),
          const SizedBox(height: 8),
          ..._insights.map((insight) => _buildInsightCard(insight, themeService)),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Recent Analysis', themeService),
          const SizedBox(height: 8),
          _buildAnalyticsPreviewCard(themeService),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildNoInsightsState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Lottie.asset(
              'assets/animations/lightbulb.json',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No insights yet',
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap the refresh button to generate new insights based on your transaction data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeService.subtextColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateInsights,
            icon: const Icon(Icons.autorenew),
            label: const Text('Generate Insights'),
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
  
  Widget _buildBudgetRecommendationsTab(ThemeService themeService) {
    if (_budgetRecommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/animations/budget_setup.json',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No budget recommendations yet',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Tap the refresh button to generate personalized budget recommendations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeService.subtextColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recommended Budget', themeService),
          const SizedBox(height: 16),
          
          // Pie chart for budget allocation
          SizedBox(
            height: 250,
            child: _buildBudgetAllocationChart(themeService),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Budget Categories', themeService),
          const SizedBox(height: 8),
          
          ..._budgetRecommendations.map(
            (budget) => _buildBudgetRecommendationCard(budget, themeService),
          ),
          
          const SizedBox(height: 24),
          if (_savingsRecommendations.isNotEmpty) ...[
            _buildSavingsRecommendationCard(themeService),
            const SizedBox(height: 32),
          ],
          
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to budget creation screen with recommendations
                Navigator.of(context).pushNamed('/budget/create', arguments: _budgetRecommendations);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create Budget Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
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
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/animations/forecast.json',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No forecast data yet',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Tap the refresh button to generate spending forecasts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeService.subtextColor,
                  fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('30-Day Spending Forecast', themeService),
          const SizedBox(height: 8),
          
          // Summary card
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
                    'Forecast Total',
                    style: TextStyle(
                      color: themeService.subtextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConfig.formatCurrency(totalForecast.toInt() * 100),
                    style: TextStyle(
                      color: themeService.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
          
          const SizedBox(height: 24),
          _buildSectionHeader('Daily Spending Projection', themeService),
          const SizedBox(height: 16),
          
          // Daily forecast chart
          SizedBox(
            height: 250,
            child: _buildForecastChart(dailyForecast, themeService),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Expected Major Expenses', themeService),
          const SizedBox(height: 8),
          
          if (majorExpenses.isNotEmpty)
            ...majorExpenses.map(
              (expense) => _buildMajorExpenseCard(expense, themeService),
            )
          else
            Card(
              elevation: 0,
              color: themeService.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No major expenses predicted',
                    style: TextStyle(color: themeService.subtextColor),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Category Forecast', themeService),
          const SizedBox(height: 16),
          
          // Category forecast chart
          SizedBox(
            height: 300,
            child: _buildCategoryForecastChart(categoryForecast, themeService),
          ),
          
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to Analytics with forecast data
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AnalyticsScreen(
                      transactions: _transactions,
                      forecastData: _forecastData,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('View Detailed Analytics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildAskAITab(ThemeService themeService) {
    return Column(
      children: [
        Expanded(
          child: _chatHistory.isEmpty
              ? _buildChatEmptyState(themeService)
              : _buildChatMessages(themeService),
        ),
        _buildChatInput(themeService),
      ],
    );
  }
  
  Widget _buildChatEmptyState(ThemeService themeService) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/animations/finance_chat.json',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ask me anything about your finances',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Examples:',
              style: TextStyle(
                color: themeService.subtextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildSuggestedQuestion(
              'How much did I spend on food last month?',
              themeService,
            ),
            _buildSuggestedQuestion(
              'What category am I spending the most on?',
              themeService,
            ),
            _buildSuggestedQuestion(
              'How can I improve my savings?',
              themeService,
            ),
            _buildSuggestedQuestion(
              'When will I reach my savings goal at my current rate?',
              themeService,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestedQuestion(String question, ThemeService themeService) {
    return GestureDetector(
      onTap: () => _askQuestion(question),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: themeService.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeService.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          question,
          style: TextStyle(
            color: themeService.primaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildChatMessages(ThemeService themeService) {
    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final message = _chatHistory[index];
        final isUser = message['isUser'] as bool;
        
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser 
                  ? themeService.primaryColor
                  : themeService.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['message'] as String,
                  style: TextStyle(
                    color: isUser ? Colors.white : themeService.textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message['timestamp'] as DateTime),
                  style: TextStyle(
                    color: isUser 
                        ? Colors.white.withOpacity(0.7)
                        : themeService.subtextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildChatInput(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.isDarkMode ? Colors.grey[900] : Colors.white,
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
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask about your finances...',
                hintStyle: TextStyle(color: themeService.subtextColor),
                filled: true,
                fillColor: themeService.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              style: TextStyle(color: themeService.textColor),
              onSubmitted: _isAskingQuestion ? null : _askQuestion,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: themeService.primaryColor,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isAskingQuestion
                  ? null
                  : () => _askQuestion(_questionController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: _isAskingQuestion
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, ThemeService themeService) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: themeService.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + 0.1 * _pulseAnimationController.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: themeService.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          'AI Powered',
          style: TextStyle(
            color: themeService.subtextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInsightCard(Map<String, dynamic> insight, ThemeService themeService) {
    final title = insight['title'] as String;
    final description = insight['description'] as String;
    final recommendation = insight['recommendation'] as String;
    final iconName = insight['icon'] as String;
    final priority = insight['priority'] as String;
    final type = insight['type'] as String;
    
    // Map string icon name to IconData
    IconData iconData = Icons.lightbulb_outline;
    try {
      iconData = IconData(
        int.parse(iconName.split('0x')[1], radix: 16),
        fontFamily: 'MaterialIcons',
      );
    } catch (e) {
      // Fallback icons based on insight type
      switch (type) {
        case 'spending':
          iconData = Icons.shopping_cart_outlined;
          break;
        case 'saving':
          iconData = Icons.savings_outlined;
          break;
        case 'budget':
          iconData = Icons.account_balance_wallet_outlined;
          break;
        case 'income':
          iconData = Icons.attach_money;
          break;
        case 'balance':
          iconData = Icons.account_balance_outlined;
          break;
      }
    }
    
    // Color based on priority
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: themeService.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeService.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                color: themeService.subtextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: themeService.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeService.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: themeService.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
  
  Widget _buildAnomalyCard(Map<String, dynamic> anomaly, ThemeService themeService) {
    final title = anomaly['title'] as String;
    final category = anomaly['category'] as String;
    final amount = anomaly['amount'] as double;
    final date = anomaly['date'] as String;
    final severity = anomaly['severity'] as String;
    final explanation = anomaly['explanation'] as String;
    final recommendation = anomaly['recommendation'] as String;
    final iconName = anomaly['icon'] as String;
    
    // Map string icon name to IconData
    IconData iconData = Icons.warning_amber_rounded;
    try {
      iconData = IconData(
        int.parse(iconName.split('0x')[1], radix: 16),
        fontFamily: 'MaterialIcons',
      );
    } catch (e) {
      // Fallback icon
    }
    
    // Color based on severity
    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'high':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: severityColor.withOpacity(0.1),
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
                    color: severityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: severityColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: severityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            AppConfig.formatCurrency(amount.toInt() * 100),
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          color: themeService.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$category • $date',
                        style: TextStyle(
                          color: themeService.subtextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: severityColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: severityColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: themeService.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
  
  Widget _buildBudgetRecommendationCard(
    Map<String, dynamic> budget,
    ThemeService themeService,
  ) {
    final category = budget['category'] as String;
    final recommendedAmount = budget['recommended_amount'] as double;
    final percentOfIncome = budget['percent_of_income'] as double;
    final currentSpending = budget['current_spending'] as double;
    final adjustmentNeeded = budget['adjustment_needed'] as double;
    final iconName = budget['icon'] as String;
    final priority = budget['priority'] as String;
    
    // Map string icon name to IconData
    IconData iconData = Icons.category;
    try {
      iconData = IconData(
        int.parse(iconName.split('0x')[1], radix: 16),
        fontFamily: 'MaterialIcons',
      );
    } catch (e) {
      // Fallback icon based on category
      switch (category.toLowerCase()) {
        case 'food':
          iconData = Icons.restaurant;
          break;
        case 'transport':
        case 'transportation':
          iconData = Icons.directions_car;
          break;
        case 'housing':
        case 'rent':
          iconData = Icons.home;
          break;
        case 'utilities':
          iconData = Icons.water_damage;
          break;
        case 'entertainment':
          iconData = Icons.movie;
          break;
        case 'health':
          iconData = Icons.health_and_safety;
          break;
        case 'education':
          iconData = Icons.school;
          break;
        case 'shopping':
          iconData = Icons.shopping_bag;
          break;
        case 'savings':
          iconData = Icons.savings;
          break;
      }
    }
    
    // Color based on priority
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'essential':
        priorityColor = Colors.red;
        break;
      case 'wants':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }
    
    final isOverBudget = adjustmentNeeded < 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: priorityColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                          const Spacer(),
                          Text(
                            '${percentOfIncome.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: themeService.subtextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: themeService.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetAmountItem(
                  'Recommended',
                  AppConfig.formatCurrency(recommendedAmount.toInt() * 100),
                  themeService,
                ),
                _buildBudgetAmountItem(
                  'Current Spending',
                  AppConfig.formatCurrency(currentSpending.toInt() * 100),
                  themeService,
                  textColor: isOverBudget ? Colors.red : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: currentSpending / recommendedAmount,
              backgroundColor: themeService.isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
              borderRadius: BorderRadius.circular(10),
              minHeight: 10,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isOverBudget ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isOverBudget ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isOverBudget
                      ? 'Reduce by ${AppConfig.formatCurrency(adjustmentNeeded.abs().toInt() * 100)}'
                      : 'Within budget by ${AppConfig.formatCurrency(adjustmentNeeded.toInt() * 100)}',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetAmountItem(
    String label,
    String amount,
    ThemeService themeService, {
    Color? textColor,
  }) {
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
          amount,
          style: TextStyle(
            color: textColor ?? themeService.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMajorExpenseCard(
    Map<String, dynamic> expense,
    ThemeService themeService,
  ) {
    final category = expense['category'] as String;
    final amount = expense['amount'] as double;
    final likelihood = expense['likelihood'] as double;
    
    // Icon based on category
    IconData iconData = Icons.category;
    switch (category.toLowerCase()) {
      case 'food':
        iconData = Icons.restaurant;
        break;
      case 'transport':
      case 'transportation':
        iconData = Icons.directions_car;
        break;
      case 'housing':
      case 'rent':
        iconData = Icons.home;
        break;
      case 'utilities':
        iconData = Icons.water_damage;
        break;
      case 'entertainment':
        iconData = Icons.movie;
        break;
      case 'health':
        iconData = Icons.health_and_safety;
        break;
      case 'education':
        iconData = Icons.school;
        break;
      case 'shopping':
        iconData = Icons.shopping_bag;
        break;
      case 'savings':
        iconData = Icons.savings;
        break;
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Likelihood: ${(likelihood * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: themeService.subtextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              AppConfig.formatCurrency(amount.toInt() * 100),
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSavingsRecommendationCard(ThemeService themeService) {
    if (_savingsRecommendations.isEmpty) return const SizedBox.shrink();
    
    final recommendedSaving = _savingsRecommendations['recommended_monthly_saving'] as double? ?? 0.0;
    final percentOfIncome = _savingsRecommendations['percent_of_income'] as double? ?? 0.0;
    final strategies = _savingsRecommendations['strategies'] as List<dynamic>? ?? [];
    final emergencyFund = _savingsRecommendations['emergency_fund'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.green.withOpacity(0.1),
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
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings Recommendation',
                        style: TextStyle(
                          color: themeService.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                ),
                Text(
                  AppConfig.formatCurrency(recommendedSaving.toInt() * 100),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Savings Strategies',
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...strategies.take(3).map((strategy) => _buildStrategyItem(strategy as String, themeService)),
            
            if (emergencyFund.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Emergency Fund',
                          style: TextStyle(
                            color: themeService.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEmergencyFundItem(
                          'Current',
                          AppConfig.formatCurrency((emergencyFund['current'] as double? ?? 0.0).toInt() * 100),
                          themeService,
                        ),
                        _buildEmergencyFundItem(
                          'Target',
                          AppConfig.formatCurrency((emergencyFund['target'] as double? ?? 0.0).toInt() * 100),
                          themeService,
                        ),
                        _buildEmergencyFundItem(
                          'Time to Goal',
                          '${emergencyFund['months_to_complete'] as int? ?? 0} months',
                          themeService,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStrategyItem(String strategy, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strategy,
              style: TextStyle(
                color: themeService.textColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmergencyFundItem(
    String label,
    String value,
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
            color: themeService.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnalyticsPreviewCard(ThemeService themeService) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: themeService.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnalyticsScreen(
                transactions: _transactions,
                forecastData: _forecastData,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Spending Trend',
                    style: TextStyle(
                      color: themeService.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: themeService.subtextColor,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _buildWeeklyTrendMiniChart(themeService),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'View detailed analytics →',
                  style: TextStyle(
                    color: themeService.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWeeklyTrendMiniChart(ThemeService themeService) {
    // Create sample data if no transactions
    final Map<String, double> weeklyData = {'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0};
    
    if (_transactions.isNotEmpty) {
      // Filter transactions for this week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekTransactions = _transactions.where(
        (t) => t.date.isAfter(startOfWeek) || 
               (t.date.year == startOfWeek.year && 
                t.date.month == startOfWeek.month && 
                t.date.day == startOfWeek.day)
      ).toList();
      
      // Group by day of week
      for (final transaction in thisWeekTransactions) {
        if (transaction.isExpense) {
          final dayOfWeek = _getDayAbbreviation(transaction.date.weekday);
          weeklyData[dayOfWeek] = (weeklyData[dayOfWeek] ?? 0) + transaction.amount;
        }
      }
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() < 0 || value.toInt() >= days.length) {
                  return const Text('');
                }
                return Text(
                  days[value.toInt()],
                  style: TextStyle(
                    color: themeService.subtextColor,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
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
        minX: 0,
        maxX: 6,
        minY: 0,
      ),
    );
  }
  
  Widget _buildBudgetAllocationChart(ThemeService themeService) {
    if (_budgetRecommendations.isEmpty) {
      return Center(
        child: Text(
          'No budget data available',
          style: TextStyle(color: themeService.subtextColor),
        ),
      );
    }
    
    // Prepare data for pie chart
    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    
    for (int i = 0; i < _budgetRecommendations.length; i++) {
      final budget = _budgetRecommendations[i];
      final category = budget['category'] as String;
      final amount = budget['recommended_amount'] as double;
      final percent = budget['percent_of_income'] as double;
      
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: amount,
          title: '${percent.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
  
  Widget _buildForecastChart(List<dynamic> dailyForecast, ThemeService themeService) {
    if (dailyForecast.isEmpty) {
      return Center(
        child: Text(
          'No forecast data available',
          style: TextStyle(color: themeService.subtextColor),
        ),
      );
    }
    
    // Convert forecast data to spots for line chart
    final List<FlSpot> spots = [];
    
    for (int i = 0; i < dailyForecast.length; i++) {
      final day = dailyForecast[i];
      final amount = day['amount'] as double;
      spots.add(FlSpot(i.toDouble(), amount));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: themeService.isDarkMode
                  ? Colors.grey[800]!
                  : Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppConfig.formatCurrency(value.toInt() * 100).split('.')[0],
                  style: TextStyle(
                    color: themeService.subtextColor,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 7,
              getTitlesWidget: (value, meta) {
                if (value % 7 != 0) return const Text('');
                final week = (value / 7).toInt() + 1;
                return Text(
                  'Week $week',
                  style: TextStyle(
                    color: themeService.subtextColor,
                    fontSize: 10,
                  ),
                );
              },
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
              color: themeService.primaryColor.withOpacity(0.2),
            ),
          ),
        ],
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: 0,
      ),
    );
  }
  
  Widget _buildCategoryForecastChart(List<dynamic> categoryForecast, ThemeService themeService) {
    if (categoryForecast.isEmpty) {
      return Center(
        child: Text(
          'No category forecast data available',
          style: TextStyle(color: themeService.subtextColor),
        ),
      );
    }
    
    // Prepare data for bar chart
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < categoryForecast.length; i++) {
      final category = categoryForecast[i];
      final amount = category['amount'] as double;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: themeService.primaryColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: categoryForecast.fold<double>(
          0,
          (prev, element) => math.max(prev, element['amount'] as double),
        ) * 1.2,
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppConfig.formatCurrency(value.toInt() * 100).split('.')[0],
                  style: TextStyle(
                    color: themeService.subtextColor,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= categoryForecast.length) {
                  return const Text('');
                }
                final category = categoryForecast[value.toInt()];
                final categoryName = category['category'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    categoryName.length > 8
                        ? '${categoryName.substring(0, 8)}...'
                        : categoryName,
                    style: TextStyle(
                      color: themeService.subtextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: themeService.isDarkMode
                  ? Colors.grey[800]!
                  : Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: barGroups,
      ),
    );
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
}

