// lib/screens/ai_insight_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/providers/insight_provider.dart';
import 'package:dailydime/widgets/financial_score_card.dart';
import 'package:dailydime/widgets/charts_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/ai_notification_service.dart';
import 'package:dailydime/screens/analytics_screen.dart';

class AIInsightScreen extends StatefulWidget {
  const AIInsightScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightScreen> createState() => _AIInsightScreenState();
}

class _AIInsightScreenState extends State<AIInsightScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final AiNotificationService _aiNotificationService = AiNotificationService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize AI insights
    Future.microtask(() {
      final insightProvider = Provider.of<InsightProvider>(context, listen: false);
      insightProvider.fetchInsights();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<InsightProvider>(
          builder: (context, insightProvider, child) {
            return Column(
              children: [
                _buildFloatingHeader(insightProvider),
                const SizedBox(height: 10),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSavingsGoalsTab(insightProvider),
                      _buildChallengesTab(insightProvider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(InsightProvider insightProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF32CD32),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Savings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {
                        // Show notifications
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        // Show more options
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Savings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${AppConfig.currencySymbol} ${insightProvider.totalSavings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${insightProvider.savingsGrowthPercentage.toStringAsFixed(1)}%',
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  icon: Icons.calendar_today_outlined,
                  title: 'This Month',
                  value: '${AppConfig.currencySymbol} ${insightProvider.monthlySavings.toStringAsFixed(0)}',
                ),
                _buildInfoColumn(
                  icon: Icons.flag_outlined,
                  title: 'Total Goals',
                  value: '${insightProvider.activeGoalsCount} Active',
                ),
                _buildInfoColumn(
                  icon: Icons.trending_up_outlined,
                  title: 'Average',
                  value: '${AppConfig.currencySymbol} ${insightProvider.dailyAverage.toStringAsFixed(0)}/day',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF32CD32),
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        tabs: const [
          Tab(text: 'Savings Goals'),
          Tab(text: 'Challenges'),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalsTab(InsightProvider insightProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAiSmartSavingCard(insightProvider),
        const SizedBox(height: 20),
        _buildSavingsGoalFilters(),
        const SizedBox(height: 20),
        ...insightProvider.aiInsights.map((insight) => _buildInsightCard(insight)),
        const SizedBox(height: 20),
        _buildFinancialHealthScoreCard(insightProvider),
        const SizedBox(height: 20),
        _buildSpendingTrendsCard(insightProvider),
        const SizedBox(height: 20),
        _buildGoalTimelineCard(insightProvider),
        const SizedBox(height: 20),
        _buildTopCategoriesCard(insightProvider),
        const SizedBox(height: 70), // Bottom padding for navigation bar
      ],
    );
  }

  Widget _buildChallengesTab(InsightProvider insightProvider) {
    return AnalyticsScreen(insightProvider: insightProvider);
  }

  Widget _buildAiSmartSavingCard(InsightProvider insightProvider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF32CD32),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AI Smart Saving',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  // Close this card
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'You can save Ksh 65 today! Reduce dining out expenses this week. By cooking at home 2 out of 4 times instead of eating out, you can save roughly \$65 based on your previous spending.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  label: 'Skip',
                  backgroundColor: Colors.white.withOpacity(0.3),
                  textColor: Colors.white,
                  onPressed: () {
                    // Skip this suggestion
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildButton(
                  label: 'Save Ksh 65',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF32CD32),
                  onPressed: () {
                    // Add to a new goal
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildSavingsGoalFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Savings Goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', true),
              _buildFilterChip('Active', false),
              _buildFilterChip('Completed', false),
              _buildFilterChip('Upcoming', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        backgroundColor: Colors.grey.shade200,
        selectedColor: const Color(0xFF32CD32).withOpacity(0.2),
        checkmarkColor: const Color(0xFF32CD32),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF32CD32) : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isSelected ? const Color(0xFF32CD32) : Colors.transparent,
            width: 1,
          ),
        ),
        onSelected: (bool selected) {
          // Handle filter selection
        },
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
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
                  color: insight['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  insight['icon'],
                  color: insight['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight['description'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (insight['showChart'] == true) ...[
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: SpendingLineChart(data: insight['chartData']),
            ),
          ],
          if (insight['actionable'] == true) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    insight['actionText'],
                    style: TextStyle(
                      color: insight['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialHealthScoreCard(InsightProvider insightProvider) {
    return FinancialScoreCard(score: insightProvider.financialHealthScore);
  }

  Widget _buildSpendingTrendsCard(InsightProvider insightProvider) {
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
            'Spending Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: SpendingAreaChart(
              weeklySpending: insightProvider.weeklySpending,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            insightProvider.spendingTrendInsight,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTimelineCard(InsightProvider insightProvider) {
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
            'Goal Timeline Prediction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: GoalTimelineChart(goals: insightProvider.activeGoals),
          ),
          const SizedBox(height: 10),
          Text(
            insightProvider.goalTimelineInsight,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesCard(InsightProvider insightProvider) {
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
                'Top Expense Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'This Month',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CategoryPieChart(categories: insightProvider.topCategories),
          ),
          const SizedBox(height: 20),
          _buildCategoryList(insightProvider.topCategories),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> categories) {
    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category['name'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '${AppConfig.currencySymbol} ${category['amount'].toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}