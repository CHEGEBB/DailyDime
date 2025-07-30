// lib/screens/ai_insights_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/ai_insight_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/config/app_config.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final AIInsightsService _aiService = AIInsightsService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  Map<String, dynamic> _insights = {};
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic> _forecast = {};
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.scaffoldColor,
          body: _isLoading 
            ? _buildLoadingState(themeService)
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: themeService.primaryColor,
                child: CustomScrollView(
                  slivers: [
                    _buildHeader(themeService),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildQuickStats(themeService),
                            _buildChartsSection(themeService),
                            _buildAIRecommendations(themeService),
                            _buildAlertsSection(themeService),
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading.json',
            width: 120,
            height: 120,
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
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: themeService.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeService.primaryColor,
                themeService.secondaryColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/pattern11.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
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
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Powered by Gemini AI',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_insights.isNotEmpty) ...[
                                Text(
                                  '${_insights['keyMetrics']?['transactionCount'] ?? 0} transactions analyzed',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Last updated: ${_formatTime(DateTime.now())}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Lottie.asset(
                          'assets/animations/money_coins.json',
                          width: 80,
                          height: 80,
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

  Widget _buildQuickStats(ThemeService themeService) {
    if (_insights.isEmpty) return const SizedBox.shrink();
    
    final keyMetrics = _insights['keyMetrics'] ?? {};
    final quickStats = _insights['quickStats'] ?? {};
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Net Flow',
                  AppConfig.formatCurrency(
                    ((keyMetrics['netFlow'] ?? 0.0) * 100).toInt(),
                  ),
                  quickStats['spendingTrend'] == 'positive' 
                    ? Icons.trending_up 
                    : Icons.trending_down,
                  quickStats['spendingTrend'] == 'positive'
                    ? themeService.successColor
                    : themeService.errorColor,
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Daily',
                  AppConfig.formatCurrency(
                    ((quickStats['avgDailySpending'] ?? 0.0) * 100).toInt(),
                  ),
                  Icons.calendar_today,
                  themeService.infoColor,
                  themeService,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Top Category',
                  quickStats['topCategory'] ?? 'None',
                  Icons.category,
                  themeService.warningColor,
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Transactions',
                  '${keyMetrics['transactionCount'] ?? 0}',
                  Icons.receipt_long,
                  themeService.primaryColor,
                  themeService,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, 
                       Color color, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                  tabs: const [
                    Tab(text: 'Spending'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Trends'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSpendingChart(themeService),
                      _buildCategoryChart(themeService),
                      _buildTrendChart(themeService),
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
    final spendingData = _chartData.firstWhere(
      (chart) => chart['type'] == 'bar',
      orElse: () => {'data': []},
    )['data'] as List? ?? [];
    
    if (spendingData.isEmpty) {
      return _buildEmptyChart('No spending data available', themeService);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: spendingData.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < spendingData.length) {
                    return Text(
                      spendingData[value.toInt()]['label'],
                      style: TextStyle(
                        color: themeService.subtextColor,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: spendingData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value['value'],
                  color: entry.value['color'] ?? themeService.primaryColor,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
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
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: categoryData.asMap().entries.map((entry) {
            final colors = [
              themeService.primaryColor,
              themeService.secondaryColor,
              themeService.warningColor,
              themeService.infoColor,
              themeService.successColor,
            ];
            
            return PieChartSectionData(
              value: entry.value['value'],
              title: '${(entry.value['value'] / categoryData.fold(0.0, (sum, item) => sum + item['value']) * 100).toStringAsFixed(1)}%',
              color: colors[entry.key % colors.length],
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildTrendChart(ThemeService themeService) {
    final trendData = _chartData.firstWhere(
      (chart) => chart['type'] == 'line',
      orElse: () => {'data': []},
    )['data'] as List? ?? [];
    
    if (trendData.isEmpty) {
      return _buildEmptyChart('No trend data available', themeService);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trendData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['y']);
              }).toList(),
              isCurved: true,
              color: themeService.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: themeService.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
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
            color: themeService.subtextColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: themeService.subtextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendations(ThemeService themeService) {
    if (_recommendations.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: themeService.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
            ],
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
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: themeService.primaryColor, width: 2)),
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
              Icon(
                recommendation['icon'] ?? Icons.info_outline,
                color: priorityColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation['title'] ?? 'Recommendation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation['description'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: themeService.subtextColor,
              height: 1.4,
            ),
          ),
          if (recommendation['action'] != null) ...[
            const SizedBox(height: 12),
            Text(
              recommendation['action'],
              style: TextStyle(
                fontSize: 14,
                color: themeService.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertsSection(ThemeService themeService) {
    if (_alerts.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: themeService.warningColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Alerts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: (alert['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              alert['icon'] ?? Icons.info,
              color: alert['color'] ?? themeService.primaryColor,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.subtextColor,
                  ),
                ),
                if (alert['action'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    alert['action'],
                    style: TextStyle(
                      fontSize: 12,
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}