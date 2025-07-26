// lib/screens/ai_insight_screen.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dailydime/services/ai_insight_service.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/sms_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/screens/chat_screen.dart';
import 'package:dailydime/screens/savings/savings_screen.dart';
import 'package:dailydime/widgets/financial_score_card.dart';
import 'package:dailydime/widgets/charts/charts_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AIInsightScreen extends StatefulWidget {
  const AIInsightScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightScreen> createState() => _AIInsightScreenState();
}

class _AIInsightScreenState extends State<AIInsightScreen> with SingleTickerProviderStateMixin {
  AIInsightService? _aiService;
  SmsService? _smsService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _insightData = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _initializeServices();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Initialize services
      final appwriteService = AppwriteService();
      _aiService = AIInsightService(appwriteService);
      _smsService = SmsService();
      
      // Initialize SMS service to get real-time transaction data
      if (_smsService != null) {
        await _smsService!.initialize();
        
        // Subscribe to transaction stream for real-time updates
        _smsService!.transactionStream.listen((transaction) {
          // When new transaction detected, refresh insights
          _loadInsights();
        });
      }
      
      await _loadInsights();
    } catch (e) {
      print('Error initializing services: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInsights() async {
    if (_aiService == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'AI Service not initialized';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final data = await _aiService!.fetchFinancialData();
      
      // Ensure proper type conversion for transactions
      if (data['transactions'] != null) {
        final List<dynamic> rawTransactions = data['transactions'] as List<dynamic>;
        final List<Transaction> transactions = rawTransactions
            .map((item) => item is Transaction ? item : Transaction.fromJson(item as Map<String, dynamic>))
            .toList();
        data['transactions'] = transactions;
      }
      
      // Generate smart savings opportunities and other AI insights
      if (_aiService != null && data['transactions'] != null) {
        data['smartSavings'] = _generateSmartSavings(data['transactions'] as List<Transaction>);
        data['financialTips'] = _generateFinancialTips(data);
        data['anomalies'] = _detectAnomalies(data['transactions'] as List<Transaction>);
      }
      
      setState(() {
        _insightData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading insights: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateSmartSavings(List<Transaction> transactions) {
    // Generate multiple smart saving opportunities
    final opportunities = <Map<String, dynamic>>[];
    
    // Example: Dining out reduction suggestion
    if (transactions.any((t) => t.category?.toLowerCase().contains('food') == true || 
                        t.category?.toLowerCase().contains('restaurant') == true)) {
      opportunities.add({
        'title': 'Reduce dining expenses',
        'description': 'You can save ${AppConfig.currencySymbol} 65 this week. By cooking at home 2 out of 4 times instead of eating out, you can save roughly $65 based on your previous spending.',
        'amount': 65,
        'icon': Icons.restaurant,
        'color': Colors.orange,
        'actionText': 'Save ${AppConfig.currencySymbol} 65',
      });
    }
    
    // Example: Subscription optimization
    if (transactions.any((t) => t.category?.toLowerCase().contains('subscription') == true || 
                        t.title.toLowerCase().contains('subscription') == true)) {
      opportunities.add({
        'title': 'Optimize subscriptions',
        'description': 'You can save ${AppConfig.currencySymbol} 30 monthly by consolidating your streaming services. Consider rotating services instead of having multiple active at once.',
        'amount': 30,
        'icon': Icons.subscriptions,
        'color': Colors.purple,
        'actionText': 'Review Subscriptions',
      });
    }
    
    // Example: Transport savings
    if (transactions.any((t) => t.category?.toLowerCase().contains('transport') == true || 
                        t.category?.toLowerCase().contains('fuel') == true)) {
      opportunities.add({
        'title': 'Transport savings',
        'description': 'You can save ${AppConfig.currencySymbol} 45 weekly by carpooling or using public transport twice a week based on your regular commute patterns.',
        'amount': 45,
        'icon': Icons.directions_car,
        'color': Colors.blue,
        'actionText': 'Save ${AppConfig.currencySymbol} 45',
      });
    }
    
    // If no specific opportunities found, provide a generic one
    if (opportunities.isEmpty) {
      opportunities.add({
        'title': 'Start a savings challenge',
        'description': 'Try the 50/30/20 rule: 50% on needs, 30% on wants, and 20% on savings. This could help you save up to ${AppConfig.currencySymbol} 100 monthly.',
        'amount': 100,
        'icon': Icons.savings,
        'color': Colors.green,
        'actionText': 'Start Challenge',
      });
    }
    
    return opportunities;
  }

  List<Map<String, dynamic>> _generateFinancialTips(Map<String, dynamic> data) {
    final tips = <Map<String, dynamic>>[];
    final stats = data['stats'] ?? {};
    
    // Add financial health tips based on the data
    if ((stats['financialHealthScore'] as int? ?? 0) < 70) {
      tips.add({
        'title': 'Improve Your Financial Health',
        'description': 'Setting up an emergency fund covering 3-6 months of expenses can significantly improve your financial security.',
        'icon': Icons.health_and_safety,
        'color': Colors.red,
        'actionable': true,
        'actionText': 'Create Emergency Fund',
      });
    }
    
    // Add budget tip
    if ((stats['totalExpenses'] as double? ?? 0) > (stats['totalIncome'] as double? ?? 0) * 0.8) {
      tips.add({
        'title': 'Budget Adjustment Needed',
        'description': 'Your expenses are approaching your income level. Consider creating a stricter budget to increase your savings rate.',
        'icon': Icons.account_balance_wallet,
        'color': Colors.amber,
        'actionable': true,
        'actionText': 'Adjust Budget',
        'showChart': true,
        'chartData': [
          {'label': 'Income', 'value': stats['totalIncome'] ?? 0},
          {'label': 'Expenses', 'value': stats['totalExpenses'] ?? 0},
        ],
      });
    }
    
    // Add investment tip
    tips.add({
      'title': 'Investment Opportunity',
      'description': 'Based on your savings pattern, you could invest ${AppConfig.currencySymbol} ${((stats['totalSavings'] as double? ?? 0) * 0.3).round()} without affecting your liquidity needs.',
      'icon': Icons.trending_up,
      'color': Colors.blue,
      'actionable': true,
      'actionText': 'Explore Investments',
    });
    
    // Add savings tip
    tips.add({
      'title': 'Savings Goal Potential',
      'description': 'At your current rate, you could save an additional ${AppConfig.currencySymbol} ${((stats['totalIncome'] as double? ?? 0) * 0.1).round()} monthly by optimizing your spending patterns.',
      'icon': Icons.savings,
      'color': Colors.green,
      'actionable': true,
      'actionText': 'Set Savings Goal',
    });
    
    return tips;
  }

  List<Map<String, dynamic>> _detectAnomalies(List<Transaction> transactions) {
    final anomalies = <Map<String, dynamic>>[];
    
    if (transactions.isEmpty) return anomalies;
    
    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Look for unusually large transactions (in the top 10% of transaction amounts)
    final amounts = transactions.map((t) => t.amount).toList()..sort();
    final threshold = amounts.isEmpty ? 0 : amounts[(amounts.length * 0.9).floor()];
    
    // Find recent large transactions
    final recentLargeTransactions = transactions
        .where((t) => t.amount > threshold && t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .take(3)
        .toList();
    
    for (final transaction in recentLargeTransactions) {
      anomalies.add({
        'title': 'Unusual Transaction',
        'description': '${transaction.title} (${AppConfig.formatCurrency(transaction.amount)}) on ${_formatDate(transaction.date)} is larger than 90% of your transactions.',
        'icon': Icons.warning_amber,
        'color': Colors.orange,
        'date': transaction.date,
        'amount': transaction.amount,
        'actionable': true,
        'actionText': 'Review Transaction',
      });
    }
    
    // Detect duplicated transactions (similar amount and description within 48 hours)
    final potentialDuplicates = <Transaction>[];
    for (int i = 0; i < transactions.length - 1; i++) {
      for (int j = i + 1; j < transactions.length; j++) {
        final t1 = transactions[i];
        final t2 = transactions[j];
        
        if (t1.amount == t2.amount && 
            t1.title.toLowerCase().contains(t2.title.toLowerCase()) &&
            t1.date.difference(t2.date).inHours.abs() < 48) {
          potentialDuplicates.add(t2);
        }
      }
    }
    
    for (final duplicate in potentialDuplicates.take(2)) {
      anomalies.add({
        'title': 'Potential Duplicate',
        'description': 'Transaction ${duplicate.title} (${AppConfig.formatCurrency(duplicate.amount)}) on ${_formatDate(duplicate.date)} may be a duplicate payment.',
        'icon': Icons.copy,
        'color': Colors.red,
        'date': duplicate.date,
        'amount': duplicate.amount,
        'actionable': true,
        'actionText': 'Check Transaction',
      });
    }
    
    return anomalies;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _insightData.isEmpty
                  ? _buildEmptyState()
                  : _buildInsightDashboard(),
      floatingActionButton: _aiService != null && !_isLoading && !_hasError
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(aiService: _aiService!),
                  ),
                );
              },
              backgroundColor: const Color(0xFF32CD32),
              child: const Icon(Icons.chat_outlined, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/ai_loading.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Analyzing your finances...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Gemini AI is working its magic',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/error_state.json',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _initializeServices,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF32CD32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_state.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 20),
          const Text(
            'No financial data yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add some transactions to get personalized AI insights about your finances',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back to add transactions
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF32CD32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Add Your First Transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightDashboard() {
    final stats = _insightData['stats'] ?? {};
    final smartSavings = _insightData['smartSavings'] ?? [];
    final financialTips = _insightData['financialTips'] ?? [];
    final anomalies = _insightData['anomalies'] ?? [];
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: _buildBackgroundPattern(),
          ),
          
          // Main scrollable content
          RefreshIndicator(
            onRefresh: _loadInsights,
            color: const Color(0xFF32CD32),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Floating app bar with pattern background
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF32CD32),
                            const Color(0xFF32CD32).withOpacity(0.8),
                            const Color(0xFF1E88E5).withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Pattern overlay
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.2,
                              child: CustomPaint(
                                painter: PatternPainter(),
                              ),
                            ),
                          ),
                          
                          // Content
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.auto_graph,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Savings',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Powered by Gemini AI',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Text(
                                      'Ksh ${(stats['totalSavings'] as double? ?? 0).toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            (stats['savingsChange'] as double? ?? 0) >= 0 
                                                ? Icons.arrow_upward 
                                                : Icons.arrow_downward,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${(stats['savingsChange'] as double? ?? 0).abs().toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
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
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Main content cards
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildQuickStatsRow(stats),
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildSmartSavingSuggestionCard(
                      smartSavings.isNotEmpty ? smartSavings[0] : null
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24, left: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader('Savings Goals', 'This Month'),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 170,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildSavingsGoalCard('Vacation', 3500, 1200, 0.34, Colors.blue),
                          _buildSavingsGoalCard('New Phone', 2500, 2000, 0.8, Colors.purple),
                          _buildSavingsGoalCard('Emergency', 10000, 5000, 0.5, Colors.orange),
                          _buildNewGoalCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24, left: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader('AI Smart Saving', 'Opportunities'),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: smartSavings.length,
                        itemBuilder: (context, index) {
                          return _buildSmartSavingCard(smartSavings[index]);
                        },
                      ),
                    ),
                  ),
                ),
                
                if (anomalies.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 24, left: 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader('Attention Needed', 'Potential Issues'),
                    ),
                  ),
                  
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildAttentionCard(anomalies.first),
                    ),
                  ),
                ],
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24, left: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader('Financial Insights', 'Personalized for You'),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: _buildInsightCard(financialTips[index]),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: financialTips.length,
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24, left: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader('Spending Analysis', 'AI-Powered'),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSpendingTrendsCard(stats),
                        const SizedBox(height: 20),
                        _buildCategoryAnalysisCard(stats),
                        const SizedBox(height: 20),
                        _buildFinancialHealthCard(stats),
                        const SizedBox(height: 20),
                        _buildFuturePredictionCard(),
                        const SizedBox(height: 100), // Bottom padding for FAB
                      ],
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

  Widget _buildBackgroundPattern() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Opacity(
        opacity: 0.3,
        child: CustomPaint(
          painter: BackgroundPainter(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildQuickStatCard(
          'This Month',
          'Ksh ${(stats['monthlySpending'] as double? ?? 0).toInt()}',
          Icons.calendar_today,
          Colors.blue.withOpacity(0.8),
        ),
        const SizedBox(width: 16),
        _buildQuickStatCard(
          'Total Goals',
          '${(stats['activeGoalsCount'] as int? ?? 0)} Active',
          Icons.flag,
          Colors.orange.withOpacity(0.8),
        ),
        const SizedBox(width: 16),
        _buildQuickStatCard(
          'Average',
          'Ksh ${(stats['dailyAverage'] as double? ?? 0).toInt()}/day',
          Icons.trending_up,
          Colors.green.withOpacity(0.8),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSavingSuggestionCard(Map<String, dynamic>? suggestion) {
    if (suggestion == null) {
      return Container(); // Return empty container if no suggestion
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Smart Saving',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gemini-powered suggestion',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  // Close suggestion
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'You can save Ksh ${suggestion['amount']} today! ${suggestion['description']}',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Skip this suggestion
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to savings screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavingsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32CD32),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Save Ksh ${suggestion['amount']}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalCard(String name, double target, double current, double progress, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4, left: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: color,
                    size: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: progress > 0.5 ? Colors.green : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ksh ${target.toInt()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(10),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ksh ${current.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'of ${target.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewGoalCard() {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4, left: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'New Goal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a savings goal',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSavingCard(Map<String, dynamic> saving) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4, left: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background plant decoration
          Positioned(
            right: -10,
            top: 30,
            bottom: 0,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/plant_decoration.png',
                width: 80,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (saving['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    saving['icon'] as IconData,
                    color: saving['color'] as Color,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  saving['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  saving['description'] as String,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to savings screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavingsScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: saving['color'] as Color,
                      side: BorderSide(color: (saving['color'] as Color).withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(saving['actionText'] as String),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(Map<String, dynamic> anomaly) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber,
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
                      anomaly['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detected by Gemini AI',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            anomaly['description'] as String,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Dismiss
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Check transaction
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(anomaly['actionText'] as String),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: (insight['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  insight['icon'] as IconData,
                  color: insight['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            insight['description'] as String,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (insight['showChart'] == true && insight['chartData'] != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: _buildSimpleChart(insight['chartData']),
            ),
          ],
          if (insight['actionable'] == true) ...[
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  // Action based on insight
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: insight['color'] as Color,
                  side: BorderSide(color: (insight['color'] as Color).withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(insight['actionText'] as String),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<dynamic>? data) {
    if (data == null || data.isEmpty) return const SizedBox.shrink();
    
    // Simple bar chart visualization for demo
    return Row(
      children: List.generate(data.length, (index) {
        final item = data[index] as Map<String, dynamic>;
        final double maxValue = data
            .map<double>((e) => (e['value'] as num).toDouble())
            .reduce((value, element) => value > element ? value : element);
        
        final double normalizedValue = (item['value'] as num).toDouble() / maxValue;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 90 * normalizedValue,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSpendingTrendsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                'Weekly Spending Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last 4 weeks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending by Week',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(4, (index) {
                        final weekValues = [0.7, 0.9, 0.6, 0.8];
                        final labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
                        
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 700 + (index * 100)),
                                  height: 100 * weekValues[index],
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.blue[300]!,
                                        Colors.blue[600]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  labels[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ksh ${(weekValues[index] * 1000).toInt()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
            ),
          ),
          const SizedBox(height: 15),
          if (_aiService != null && _insightData['transactions'] != null)
            _buildWeeklyTrendInfo(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendInfo() {
    try {
      final List<Transaction> transactions;
      final List<dynamic> rawTransactions = _insightData['transactions'] as List<dynamic>;
      transactions = rawTransactions
          .where((item) => item is Transaction || item is Map<String, dynamic>)
          .map((item) => item is Transaction ? item : Transaction.fromJson(item as Map<String, dynamic>))
          .toList();
      
      final weeklyTrend = _aiService!.getWeeklyTrend(transactions);
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: weeklyTrend['isPositive'] 
              ? Colors.green.withOpacity(0.1) 
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                weeklyTrend['isPositive'] 
                    ? Icons.trending_down 
                    : Icons.trending_up,
                color: weeklyTrend['isPositive'] 
                    ? Colors.green 
                    : Colors.red,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                weeklyTrend['description'] ?? 'No trend data available',
                style: TextStyle(
                  fontSize: 13,
                  color: weeklyTrend['isPositive'] 
                      ? Colors.green[800] 
                      : Colors.red[800],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building weekly trend info: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildCategoryAnalysisCard(Map<String, dynamic> stats) {
    final categories = [
      {'name': 'Food & Dining', 'amount': 520, 'color': Colors.orange},
      {'name': 'Transport', 'amount': 350, 'color': Colors.blue},
      {'name': 'Shopping', 'amount': 280, 'color': Colors.purple},
      {'name': 'Entertainment', 'amount': 170, 'color': Colors.red},
      {'name': 'Others', 'amount': 210, 'color': Colors.grey},
    ];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Expense Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomPaint(
                      size: const Size(150, 150),
                      painter: PieChartPainter(
                        categories: categories,
                        animationValue: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: category['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category['name'] as String,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              'Ksh ${(category['amount'] as int).toString()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[700],
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your highest spending category is Food & Dining. Consider meal planning to reduce expenses in this area.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
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

  Widget _buildFinancialHealthCard(Map<String, dynamic> stats) {
    final score = (stats['financialHealthScore'] as int? ?? 50);
    
    Color scoreColor;
    String healthStatus;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      healthStatus = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.amber;
      healthStatus = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      healthStatus = 'Fair';
    } else {
      scoreColor = Colors.red;
      healthStatus = 'Needs Attention';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scoreColor.withOpacity(0.8), scoreColor.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
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
                'Financial Health Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  healthStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(value * 100).toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreIndicator(
                      'Savings', 
                      (stats['totalSavings'] != null && (stats['totalSavings'] as double) > 0) ? 
                        min((stats['totalSavings'] as double) / 5000, 1.0).toDouble() : 0.1,
                    ),
                    const SizedBox(height: 10),
                    _buildScoreIndicator(
                      'Expenses', 
                      (stats['totalIncome'] != null && (stats['totalIncome'] as double) > 0) ? 
                        min(1 - ((stats['totalExpenses'] as double? ?? 0) / (stats['totalIncome'] as double)), 1.0).toDouble() : 0.5,
                    ),
                    const SizedBox(height: 10),
                    _buildScoreIndicator(
                      'Goals', 
                      min((stats['activeGoalsCount'] as int? ?? 0) / 3, 1.0).toDouble(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Increasing your savings rate by 5% could improve your score by 10 points in the next 3 months.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
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

  Widget _buildScoreIndicator(String label, double value) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFuturePredictionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A5AE0), Color(0xFF9C42F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Goal Timeline Prediction',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Timeline visualization with animation
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Laptop goal marker
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  left: 120,
                  top: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.computer,
                          color: Colors.purple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Laptop Goal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        '3 months',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // House goal marker
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOut,
                  right: 20,
                  top: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.purple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'House Down Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        '2 years',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Based on your current saving rate, Gemini predicts you\'ll reach your laptop goal in 3 months and house down payment in 2 years.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // View goals
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to savings screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavingsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Optimize Goals'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Background pattern painter
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw grid pattern
    final double spacing = 20;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Draw some circles for decoration
    final circlePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 30, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 50, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.9), 40, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Header pattern painter
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw curved lines
    for (int i = 0; i < 10; i++) {
      final path = Path();
      path.moveTo(0, size.height - (i * 20));
      path.quadraticBezierTo(
        size.width * 0.5, 
        size.height - (i * 20) - 100 + (i * 10), 
        size.width, 
        size.height - (i * 20)
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pie chart painter
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double animationValue;
  
  PieChartPainter({
    required this.categories,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    double total = 0;
    for (var category in categories) {
      total += (category['amount'] as int).toDouble();
    }
    
    double startAngle = -pi / 2;
    
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final sweepAngle = (2 * pi * (category['amount'] as int) / total) * animationValue;
      
      final paint = Paint()
        ..color = category['color'] as Color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Draw white circle in the middle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.categories != categories;
  }
}