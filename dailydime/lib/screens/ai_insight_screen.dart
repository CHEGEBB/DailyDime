// lib/screens/ai_insights_screen.dart
import 'package:dailydime/screens/ai_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/ai_insight_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _forecastTabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late ScrollController _scrollController;
  
  final AIInsightsService _aiService = AIInsightsService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showHeaderTitle = false;
  
  Map<String, dynamic> _insights = {};
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic> _forecast = {};
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _forecastTabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController()..addListener(_onScroll);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _forecastTabController.dispose();
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Update header visibility when scrolling
    if (_scrollController.offset > 180 && !_showHeaderTitle) {
      setState(() => _showHeaderTitle = true);
    } else if (_scrollController.offset <= 180 && _showHeaderTitle) {
      setState(() => _showHeaderTitle = false);
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final results = await Future.wait([
        _aiService.getSmartInsights(),
        _aiService.getPredictiveAlerts(),
        _aiService.getCashflowForecast(),
        _aiService.getSmartRecommendations(),
        _aiService.getChartData(),
      ]);
      
      setState(() {
        _insights = results[0] as Map<String, dynamic>;
        _alerts = results[1] as List<Map<String, dynamic>>;
        _forecast = results[2] as Map<String, dynamic>;
        _recommendations = results[3] as List<Map<String, dynamic>>;
        _chartData = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load AI insights');
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    await _aiService.refreshAllInsights();
    await _loadData();
    setState(() => _isRefreshing = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.scaffoldColor,
          floatingActionButton: _buildGeminiChatButton(themeService),
          body: _isLoading 
            ? _buildLoadingState(themeService)
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: themeService.primaryColor,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(themeService),
                    SliverToBoxAdapter(
                      child: _buildContent(themeService),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildContent(ThemeService themeService) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAIInsightCard(themeService),
                _buildQuickStats(themeService),
                _buildChartsSection(themeService),
                _buildForecastSection(themeService),
                _buildAIRecommendations(themeService),
                if (_alerts.isNotEmpty) _buildAlertsSection(themeService),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/animations/loading3.json',
          width: 140,
          height: 140,
        ),
        const SizedBox(height: 24),
        Text(
          'AI is analyzing your finances...',
         style: TextStyle(
    fontFamily: 'DMsans',
            color: themeService.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Text(
            'We\'re crunching your financial data to provide personalized insights',
            textAlign: TextAlign.center,
            style: TextStyle(
    fontFamily: 'DMsans',
              color: themeService.subtextColor,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 48),
        _buildLoadingShimmer(themeService),
      ],
    );
  }

  Widget _buildLoadingShimmer(ThemeService themeService) {
    return Shimmer.fromColors(
      baseColor: themeService.isDarkMode 
          ? Colors.grey[800]! 
          : Colors.grey[300]!,
      highlightColor: themeService.isDarkMode 
          ? Colors.grey[700]! 
          : Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: themeService.primaryColor,
      elevation: 0,
      title: AnimatedOpacity(
        opacity: _showHeaderTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Text(
          'AI Insights',
          style: TextStyle(
    fontFamily: 'DMsans',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeService.primaryColor,
                themeService.primaryColor.withOpacity(0.8),
                themeService.secondaryColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    'assets/images/pattern11.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Insights',
                                style: TextStyle(
    fontFamily: 'DMsans',
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/gemini.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Powered by Gemini AI',
                                    style: TextStyle(
    fontFamily: 'DMsans',
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_insights.isNotEmpty && !_isLoading) ...[
                                Text(
                                  '${_insights['keyMetrics']?['transactionCount'] ?? 0} transactions analyzed',
                                  style: TextStyle(
    fontFamily: 'DMsans',
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Last updated: ${_formatTime(DateTime.now())}',
                                  style: TextStyle(
    fontFamily: 'DMsans',
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Lottie.asset(
                          'assets/animations/financeai.json',
                          width: 180,
                          height: 130,
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
    );
  }

  Widget _buildAIInsightCard(ThemeService themeService) {
    if (_insights.isEmpty || _insights['aiInsight'] == null) {
      return const SizedBox.shrink();
    }
    
    final aiInsight = _insights['aiInsight'] as String;
    // Take just the first paragraph for the card
    final firstParagraph = aiInsight.split('\n\n').first;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: themeService.isDarkMode 
                ? Colors.grey[800]! 
                : Colors.grey[200]!,
            width: 1,
          ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeService.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/gemini.png',
                      width: 60,
                      height: 60,
                      // color: themeService.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gemini Summary',
                    style: TextStyle(
    fontFamily: 'DMsans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                firstParagraph,
                style: TextStyle(
    fontFamily: 'DMsans',
                  fontSize: 14,
                  color: themeService.subtextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showFullInsightsDialog(themeService, aiInsight),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read full analysis',
                      style: TextStyle(
    fontFamily: 'DMsans',
                        fontSize: 14,
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: themeService.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullInsightsDialog(ThemeService themeService, String insights) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/gemini.png',
                    width: 35,
                    height: 35,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gemini AI Financial Analysis',
                    style: TextStyle(
    fontFamily: 'DMsans',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeService.textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Text(
                  insights,
                  style: TextStyle(
    fontFamily: 'DMsans',
                    fontSize: 15,
                    color: themeService.textColor,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeService themeService) {
    if (_insights.isEmpty) return const SizedBox.shrink();
    
    final keyMetrics = _insights['keyMetrics'] ?? {};
    final quickStats = _insights['quickStats'] ?? {};
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Financial Snapshot',
              style: TextStyle(
    fontFamily: 'DMsans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.textColor,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Net Flow',
                AppConfig.formatCurrency(
                  ((keyMetrics['netFlow'] ?? 0.0) * 100),
                ),
                quickStats['spendingTrend'] == 'positive' 
                  ? Icons.trending_up 
                  : Icons.trending_down,
                quickStats['spendingTrend'] == 'positive'
                  ? themeService.successColor
                  : themeService.errorColor,
                themeService,
              ),
              _buildStatCard(
                'Daily Average',
                AppConfig.formatCurrency(
                  ((quickStats['avgDailySpending'] ?? 0.0) * 100),
                ),
                Icons.calendar_today,
                themeService.infoColor,
                themeService,
              ),
              _buildStatCard(
                'Top Category',
                quickStats['topCategory'] ?? 'None',
                Icons.category,
                themeService.warningColor,
                themeService,
              ),
              _buildStatCard(
                'Budget Status',
                _getBudgetStatusText(quickStats['budgetStatus']),
                _getBudgetStatusIcon(quickStats['budgetStatus']),
                _getBudgetStatusColor(quickStats['budgetStatus'], themeService),
                themeService,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getBudgetStatusText(String? status) {
    switch (status) {
      case 'on_track':
        return 'On Track';
      case 'over_budget':
        return 'Over Budget';
      case 'no_budget':
        return 'No Budget';
      default:
        return 'Unknown';
    }
  }

  IconData _getBudgetStatusIcon(String? status) {
    switch (status) {
      case 'on_track':
        return Icons.check_circle_outline;
      case 'over_budget':
        return Icons.warning_amber_outlined;
      case 'no_budget':
        return Icons.add_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getBudgetStatusColor(String? status, ThemeService themeService) {
    switch (status) {
      case 'on_track':
        return themeService.successColor;
      case 'over_budget':
        return themeService.errorColor;
      case 'no_budget':
        return themeService.infoColor;
      default:
        return themeService.subtextColor;
    }
  }

  Widget _buildStatCard(
    String title, 
    String value, 
    IconData icon, 
    Color color, 
    ThemeService themeService
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
    fontFamily: 'DMsans',
                    fontSize: 13,
                    color: themeService.subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
    fontFamily: 'DMsans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(ThemeService themeService) {
    if (_chartData.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Financial Analytics',
              style: TextStyle(
    fontFamily: 'DMsans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeService.isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: themeService.primaryColor,
                  unselectedLabelColor: themeService.subtextColor,
                  indicatorColor: themeService.primaryColor,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(
    fontFamily: 'DMsans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
    fontFamily: 'DMsans',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Spending'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Budget'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSpendingChart(themeService),
                      _buildCategoryChart(themeService),
                      _buildBudgetChart(themeService),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(ThemeService themeService) {
    // Get weekly spending trend
    final spendingData = _chartData.firstWhere(
      (chart) => chart['type'] == 'line',
      orElse: () => {'data': []},
    )['data'] as List? ?? [];
    
    if (spendingData.isEmpty) {
      return _buildEmptyChart('No spending data available', themeService);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Spending Trend',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How your spending changes over the week',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontSize: 13,
              color: themeService.subtextColor,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: themeService.isDarkMode 
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}k',
                            style: TextStyle(
    fontFamily: 'DMsans',
                              color: themeService.subtextColor,
                              fontSize: 11,
                            ),
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
                        if (value.toInt() >= 0 && value.toInt() < spendingData.length) {
                          return SideTitleWidget(
                            meta:meta,
                            child: Text(
                              spendingData[value.toInt()]['x'] as String,
                              style: TextStyle(
    fontFamily: 'DMsans',
                                color: themeService.subtextColor,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spendingData.length - 1.0,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: spendingData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['y'] as double) / 1000, // Convert to thousands for better visualization
                      );
                    }).toList(),
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
                      color: themeService.primaryColor.withOpacity(0.15),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          themeService.primaryColor.withOpacity(0.25),
                          themeService.primaryColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
      return touchedBarSpots.map((barSpot) {
        final index = barSpot.x.toInt();
        final value = spendingData[index]['y'] as double;
        return LineTooltipItem(
          '${spendingData[index]['x']}\n',
          TextStyle(
            fontFamily: 'DMsans',
            color: themeService.textColor,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(
              text: AppConfig.formatCurrency((value * 100)),
              style: TextStyle(
                fontFamily: 'DMsans',
                color: themeService.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList();
    },
  ),
),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(ThemeService themeService) {
    final categoryData = _chartData.firstWhere(
      (chart) => chart['type'] == 'pie',
      orElse: () => {'data': []},
    )['data'] as List? ?? [];
    
    if (categoryData.isEmpty) {
      return _buildEmptyChart('No category data available', themeService);
    }
    
    final totalSpending = categoryData.fold(
      0.0, 
      (sum, item) => sum + (item['value'] as double)
    );
    
    // Generate colors for pie chart segments
    final colors = [
      themeService.primaryColor,
      themeService.secondaryColor,
      const Color(0xFF8E44AD), // Purple
      const Color(0xFFF39C12), // Orange
      const Color(0xFF16A085), // Teal
      const Color(0xFF2980B9), // Blue
      const Color(0xFFE74C3C), // Red
      const Color(0xFF1ABC9C), // Turquoise
    ];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where your money goes',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontSize: 13,
              color: themeService.subtextColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: categoryData.asMap().entries.map((entry) {
                        final percentage = (entry.value['value'] as double) / totalSpending;
                        return PieChartSectionData(
                          value: entry.value['value'] as double,
                          title: '${(percentage * 100).toStringAsFixed(0)}%',
                          radius: 80,
                          titleStyle: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: colors[entry.key % colors.length],
                          badgeWidget: percentage < 0.05 ? null : Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: colors[entry.key % colors.length],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
    fontFamily: 'DMsans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          badgePositionPercentageOffset: 0.9,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      centerSpaceColor: Colors.transparent,
                    ),
                  ),
                ),
                // Legend
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryData.length,
                    itemBuilder: (context, index) {
                      final item = categoryData[index];
                      final percentage = (item['value'] as double) / totalSpending;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
    fontFamily: 'DMsans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: themeService.textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
    fontFamily: 'DMsans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: themeService.subtextColor,
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
    );
  }

  Widget _buildBudgetChart(ThemeService themeService) {
    final budgetData = _chartData.firstWhere(
      (chart) => chart['type'] == 'horizontalBar',
      orElse: () => {'data': []},
    )['data'] as List? ?? [];
    
    if (budgetData.isEmpty) {
      return _buildEmptyChart('No budget data available', themeService);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Progress',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How you\'re tracking against your budgets',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontSize: 13,
              color: themeService.subtextColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: budgetData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final budget = budgetData[index];
                final percentage = budget['percentage'] as double;
                final spent = budget['spent'] as double;
                final total = budget['budget'] as double;
                
                Color progressColor = themeService.successColor;
                if (percentage > 0.9) {
                  progressColor = themeService.warningColor;
                }
                if (percentage > 1.0) {
                  progressColor = themeService.errorColor;
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budget['category'] as String,
                          style: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: themeService.textColor,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        // Background
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode 
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Progress
                        Container(
                          width: MediaQuery.of(context).size.width * 
                              0.75 * // Accounting for padding and such
                              min(1.0, percentage), // Cap at 100%
                          height: 12,
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                progressColor.withOpacity(0.7),
                                progressColor,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppConfig.formatCurrency((spent * 100)),
                          style: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 12,
                            color: themeService.subtextColor,
                          ),
                        ),
                        Text(
                          AppConfig.formatCurrency((total * 100)),
                          style: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 12,
                            color: themeService.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message, ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: themeService.subtextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
    fontFamily: 'DMsans',
              color: themeService.subtextColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _refreshData,
            child: Text(
              'Refresh Data',
              style: TextStyle(
    fontFamily: 'DMsans',
                color: themeService.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(ThemeService themeService) {
    if (_forecast.isEmpty) return const SizedBox.shrink();
    
    final forecastData = _forecast['forecast'] as List? ?? [];
    
    if (forecastData.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: themeService.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cash Flow Forecast',
                  style: TextStyle(
    fontFamily: 'DMsans',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeService.isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _forecastTabController,
                  labelColor: themeService.primaryColor,
                  unselectedLabelColor: themeService.subtextColor,
                  indicatorColor: themeService.primaryColor,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(
    fontFamily: 'DMsans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
    fontFamily: 'DMsans',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Balance Forecast'),
                    Tab(text: 'Cash Flow'),
                  ],
                ),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _forecastTabController,
                    children: [
                      _buildBalanceForecastChart(themeService, forecastData),
                      _buildCashFlowDetail(themeService, forecastData),
                    ],
                  ),
                ),
                // Forecast summary
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getForecastTrendColor(themeService).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getForecastTrendIcon(),
                              color: _getForecastTrendColor(themeService),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '30-Day Projection',
                                style: TextStyle(
    fontFamily: 'DMsans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: themeService.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getForecastSummary(),
                                style: TextStyle(
    fontFamily: 'DMsans',
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
        ],
      ),
    );
  }

  Widget _buildBalanceForecastChart(ThemeService themeService, List forecastData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1000,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: themeService.isDarkMode 
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Ksh ${value.toInt()}',
                      style: TextStyle(
    fontFamily: 'DMsans',
                        color: themeService.subtextColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                interval: 2000,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index % 5 == 0 && index < forecastData.length) {
                    final date = forecastData[index]['date'] as DateTime?;
                    return SideTitleWidget(
                      // axisSide: meta.axisSide,
                      meta:meta,
                      child: Text(
                        date != null ? DateFormat('MM/dd').format(date) : '',
                        style: TextStyle(
    fontFamily: 'DMsans',
                          color: themeService.subtextColor,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: forecastData.length - 1.0,
          lineBarsData: [
            LineChartBarData(
              spots: forecastData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  (entry.value['balance'] as double),
                );
              }).toList(),
              isCurved: true,
              color: _getForecastTrendColor(themeService),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: _getForecastTrendColor(themeService),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _getForecastTrendColor(themeService).withOpacity(0.15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getForecastTrendColor(themeService).withOpacity(0.25),
                    _getForecastTrendColor(themeService).withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
         lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
      return touchedBarSpots.map((barSpot) {
        final index = barSpot.x.toInt();
        if (index < forecastData.length) {
          final date = forecastData[index]['date'] as DateTime?;
          final balance = forecastData[index]['balance'] as double;
          return LineTooltipItem(
            date != null ? '${DateFormat('MMM dd').format(date)}\n' : '',
            TextStyle(
              fontFamily: 'DMsans',
              color: themeService.textColor,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: AppConfig.formatCurrency((balance * 100)),
                style: TextStyle(
                  fontFamily: 'DMsans',
                  color: _getForecastTrendColor(themeService),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

  Widget _buildCashFlowDetail(ThemeService themeService, List forecastData) {
    // Calculate average daily income and expense
    final avgDailyIncome = _forecast['dailyIncomeAvg'] as double? ?? 0.0;
    final avgDailyExpense = _forecast['dailyExpenseAvg'] as double? ?? 0.0;
    final netDaily = avgDailyIncome - avgDailyExpense;
    
    // Identify low balance days
    final lowBalanceDates = _forecast['lowBalanceDates'] as List? ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily averages
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeService.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Income',
                        style: TextStyle(
    fontFamily: 'DMsans',
                          fontSize: 12,
                          color: themeService.subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConfig.formatCurrency((avgDailyIncome * 100).toInt().toDouble()),
                        style: TextStyle(
    fontFamily: 'DMsans',
                          fontSize: 16,
                          color: themeService.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeService.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Expense',
                        style: TextStyle(
    fontFamily: 'DMsans',
                          fontSize: 12,
                          color: themeService.subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConfig.formatCurrency((avgDailyExpense * 100).toInt().toDouble()),
                        style: TextStyle(
    fontFamily: 'DMsans',
                          fontSize: 16,
                          color: themeService.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Net daily flow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (netDaily >= 0 ? themeService.successColor : themeService.errorColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Daily Flow',
                  style: TextStyle(
    fontFamily: 'DMsans',
                    fontSize: 12,
                    color: themeService.subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      netDaily >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: netDaily >= 0 ? themeService.successColor : themeService.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConfig.formatCurrency((netDaily * 100).toInt().toDouble()),
                      style: TextStyle(
    fontFamily: 'DMsans',
                        fontSize: 18,
                        color: netDaily >= 0 ? themeService.successColor : themeService.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'per day',
                      style: TextStyle(
    fontFamily: 'DMsans',
                        fontSize: 12,
                        color: themeService.subtextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Low balance alerts
          if (lowBalanceDates.isNotEmpty) ...[
            Text(
              'Potential Low Balance Days',
              style: TextStyle(
    fontFamily: 'DMsans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeService.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeService.warningColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: themeService.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance may be low on:',
                          style: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lowBalanceDates.take(3).map((date) => 
                            DateFormat('MMM dd').format(date as DateTime)
                          ).join(', ') + (lowBalanceDates.length > 3 ? '...' : ''),
                          style: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 12,
                            color: themeService.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getForecastTrendColor(ThemeService themeService) {
    final trend = _forecast['trend'] as String? ?? 'stable';
    
    switch (trend) {
      case 'growing':
        return themeService.successColor;
      case 'declining':
        return themeService.errorColor;
      case 'stable':
      default:
        return themeService.infoColor;
    }
  }

  IconData _getForecastTrendIcon() {
    final trend = _forecast['trend'] as String? ?? 'stable';
    
    switch (trend) {
      case 'growing':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      case 'stable':
      default:
        return Icons.trending_flat;
    }
  }

  String _getForecastSummary() {
    final trend = _forecast['trend'] as String? ?? 'stable';
    final projectedBalance = _forecast['projectedBalance30Days'] as double? ?? 0.0;
    
    switch (trend) {
      case 'growing':
        return 'Your balance is projected to grow to ${AppConfig.formatCurrency((projectedBalance * 100).toInt().toDouble())}';
      case 'declining':
        return 'Your balance is projected to decline to ${AppConfig.formatCurrency((projectedBalance * 100).toInt().toDouble())}';
      case 'stable':
      default:
        return 'Your balance is projected to remain stable at ${AppConfig.formatCurrency((projectedBalance * 100).toInt().toDouble())}';
    }
  }

  Widget _buildAIRecommendations(ThemeService themeService) {
    if (_recommendations.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/gemini.png',
                  width: 35,
                  height: 35,
                  filterQuality: FilterQuality.high,
                  // color: themeService.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Recommendations',
                  style: TextStyle(
    fontFamily: 'DMsans',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final recommendation = _recommendations[index];
              return _buildRecommendationCard(recommendation, themeService);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation, 
                                 ThemeService themeService) {
    final priority = recommendation['priority'] ?? 'medium';
    Color priorityColor = themeService.primaryColor;
    
    switch (priority) {
      case 'high':
        priorityColor = themeService.errorColor;
        break;
      case 'medium':
        priorityColor = themeService.warningColor;
        break;
      case 'low':
        priorityColor = themeService.successColor;
        break;
    }
    
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              // Implement action like creating a budget or setting up a goal
              _showActionDialog(themeService, recommendation);
            },
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            icon: Icons.check_circle_outline,
            label: 'Take Action',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: priorityColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: themeService.isDarkMode 
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
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
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    recommendation['icon'] ?? Icons.lightbulb_outline,
                    color: priorityColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['title'] ?? 'Recommendation',
                        style: TextStyle(
    fontFamily: 'DMsans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeService.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getPriorityText(priority),
                        style: TextStyle(
    fontFamily: 'DMsans',
                          fontSize: 12,
                          color: priorityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation['description'] ?? '',
              style: TextStyle(
    fontFamily: 'DMsans',
                fontSize: 14,
                color: themeService.subtextColor,
                height: 1.4,
              ),
            ),
            if (recommendation['action'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: themeService.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    recommendation['action'],
                    style: TextStyle(
    fontFamily: 'DMsans',
                      fontSize: 14,
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Priority';
    }
  }

  void _showActionDialog(ThemeService themeService, Map<String, dynamic> recommendation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Icon(
                    recommendation['icon'] ?? Icons.lightbulb_outline,
                    color: themeService.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation['title'] ?? 'Take Action',
                      style: TextStyle(
    fontFamily: 'DMsans',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: themeService.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      recommendation['description'] ?? '',
                      style: TextStyle(
    fontFamily: 'DMsans',
                        fontSize: 15,
                        color: themeService.textColor,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons based on recommendation type
                    _buildActionButtons(themeService, recommendation),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeService themeService, Map<String, dynamic> recommendation) {
    final type = recommendation['type'] as String? ?? '';
    
    switch (type) {
      case 'budget':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a Budget',
              style: TextStyle(
    fontFamily: 'DMsans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 16),
            // Budget form would go here
            _buildBudgetForm(themeService),
          ],
        );
      case 'savings':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Up a Savings Goal',
              style: TextStyle(
    fontFamily: 'DMsans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 16),
            // Savings goal form would go here
            _buildSavingsGoalForm(themeService),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like to do?',
              style: TextStyle(
    fontFamily: 'DMsans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to appropriate screen
                Navigator.of(context).pop();
              },
              icon: Icon(
                recommendation['icon'] ?? Icons.check_circle_outline,
                size: 18,
              ),
              label: Text(
                recommendation['action'] ?? 'Take Action',
                style: TextStyle(
    fontFamily: 'DMsans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBudgetForm(ThemeService themeService) {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.category),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
  decoration: InputDecoration(
    labelText: 'Budget Amount',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    prefixIcon: const Icon(Icons.attach_money),
  ),
  keyboardType: TextInputType.number,
),
const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Create budget logic would go here
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Budget created successfully!'),
                backgroundColor: themeService.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Create Budget',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsGoalForm(ThemeService themeService) {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Goal Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.flag),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Target Amount',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.savings),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Target Date',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            // Handle date selection
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Create savings goal logic would go here
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Savings goal created successfully!'),
                backgroundColor: themeService.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeService.successColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Create Goal',
            style: TextStyle(
    fontFamily: 'DMsans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection(ThemeService themeService) {
    if (_alerts.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: themeService.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: themeService.warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Smart Alerts',
                  style: TextStyle(
    fontFamily: 'DMsans',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _alerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              return _buildAlertCard(alert, themeService);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, ThemeService themeService) {
    final severity = alert['severity'] as String? ?? 'medium';
    Color alertColor = themeService.infoColor;
    
    switch (severity) {
      case 'high':
        alertColor = themeService.errorColor;
        break;
      case 'medium':
        alertColor = themeService.warningColor;
        break;
      case 'low':
        alertColor = themeService.successColor;
        break;
    }
    
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              // Mark as read or dismiss
              setState(() {
                _alerts.removeAt(_alerts.indexOf(alert));
              });
            },
            backgroundColor: Colors.grey[600]!,
            foregroundColor: Colors.white,
            icon: Icons.done,
            label: 'Dismiss',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: alertColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: themeService.isDarkMode 
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                alert['icon'] ?? Icons.info_outline,
                color: alertColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['title'] ?? 'Alert',
                    style: TextStyle(
    fontFamily: 'DMsans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert['message'] ?? '',
                    style: TextStyle(
    fontFamily: 'DMsans',
                      fontSize: 14,
                      color: themeService.subtextColor,
                      height: 1.4,
                    ),
                  ),
                  if (alert['action'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: alertColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alert['action'],
                          style: TextStyle(
    fontFamily: 'DMsans',
                            fontSize: 13,
                            color: alertColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.swipe_left,
              color: themeService.subtextColor.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiChatButton(ThemeService themeService) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AIChatScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      label: Container(  // Changed from 'child' to 'label'
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeService.primaryColor,
              themeService.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: themeService.primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/images/gemini.png',
                width: 20,
                height: 20,
                filterQuality: FilterQuality.high,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ask Gemini',
              style: TextStyle(
                fontFamily: 'DMsans',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showGeminiChatDialog(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/gemini.png',
                    width: 35,
                    height: 35,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Chat with Gemini AI',
                    style: TextStyle(
    fontFamily: 'DMsans',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeService.textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Chat content placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/money_coins.json',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chat feature coming soon!',
                      style: TextStyle(
    fontFamily: 'DMsans',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: themeService.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask Gemini AI about your finances',
                      style: TextStyle(
    fontFamily: 'DMsans',
                        fontSize: 14,
                        color: themeService.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Additional helper methods for math calculations
extension MathHelpers on _AIInsightsScreenState {
  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
}