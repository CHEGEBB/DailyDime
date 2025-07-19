// lib/screens/budget/budget_screen.dart

import 'package:dailydime/screens/budget/create_budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:dailydime/widgets/cards/budget_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String _selectedTimeframe = 'This Month';
  final List<String> _timeframes = ['This Month', 'Last Month', 'Custom'];
  
  final List<FlSpot> _weeklySpendingData = [
    FlSpot(1, 15000),
    FlSpot(2, 10200),
    FlSpot(3, 8700),
    FlSpot(4, 12500),
    FlSpot(5, 9300),
    FlSpot(6, 14200),
    FlSpot(7, 11800),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF26D07C); // Emerald green
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern floating header with budget overview
            SliverToBoxAdapter(
              child: Container(
                height: 340,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Stack(
                  children: [
                    // Background card with image and gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/pattern5.png'),
                            fit: BoxFit.cover,
                            opacity: 0.4,
                          ),
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
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with title and dropdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Budget Overview',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _selectedTimeframe,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                                          offset: const Offset(0, 30),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
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
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.more_horiz, color: Colors.white),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Spending amount row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'KES 32,541',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'spent of KES 50,000',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Modern progress indicator
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: 0.65, // 65% of budget used
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '65% of monthly budget used',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                'KES 17,459 left',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Budget metrics row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBudgetMetric(
                                'Daily Budget',
                                'KES 563/day',
                                Icons.calendar_today,
                              ),
                              _buildBudgetMetric(
                                'Most Spent On',
                                'Food & Groceries',
                                Icons.restaurant,
                              ),
                              _buildBudgetMetric(
                                'Budget Status',
                                'On Track',
                                Icons.trending_up,
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
            
            // Main content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Smart insights card
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
                                  Text(
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
                        // First insight
                        _buildInsightItem(
                          'You\'re spending 30% more on Entertainment than last month. Try reducing to stay on track.',
                          Colors.orange,
                          Icons.movie,
                        ),
                        const SizedBox(height: 12),
                        // Second insight
                        _buildInsightItem(
                          'Recurring expense detected: Java House (KES 450 x 3 times this week). Consider making coffee at home to save KES 1,000/week.',
                          Colors.purple,
                          Icons.coffee,
                        ),
                        const SizedBox(height: 12),
                        // Third insight
                        _buildInsightItem(
                          'You could save KES 3,200 this month by reducing your Shopping category by 15%.',
                          Colors.green,
                          Icons.savings,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: Icon(
                              Icons.smart_toy,
                              size: 16,
                              color: accentColor,
                            ),
                            label: Text(
                              'Get More Budget Tips',
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
                  
                  // Weekly spending chart
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Text(
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
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
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
                                        axisSide: meta.axisSide,
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
                                        axisSide: meta.axisSide,
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
                  
                  // Category budget header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Budgets',
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
                  
                  // Category budgets grid
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildCategoryBudgetCard(
                        'Food & Groceries',
                        15000,
                        12300,
                        0.82,
                        Colors.orange,
                        Icons.restaurant,
                      ),
                      _buildCategoryBudgetCard(
                        'Transportation',
                        5000,
                        3200,
                        0.64,
                        Colors.blue,
                        Icons.directions_bus,
                      ),
                      _buildCategoryBudgetCard(
                        'Entertainment',
                        3000,
                        3600,
                        1.2, // Over budget
                        Colors.purple,
                        Icons.movie,
                      ),
                      _buildCategoryBudgetCard(
                        'Utilities',
                        7000,
                        6500,
                        0.93,
                        Colors.teal,
                        Icons.power,
                      ),
                      _buildCategoryBudgetCard(
                        'Shopping',
                        8000,
                        3200,
                        0.4,
                        Colors.pink,
                        Icons.shopping_bag,
                      ),
                      _buildCategoryBudgetCard(
                        'Health',
                        4000,
                        1200,
                        0.3,
                        Colors.red,
                        Icons.favorite,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // View all button
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All Categories',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Saving Goals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saving Goals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Goal'),
                        style: TextButton.styleFrom(
                          foregroundColor: accentColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Saving goals card
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
                      children: [
                        _buildSavingGoalItem(
                          'Vacation',
                          'KES 50,000',
                          'KES 25,000',
                          0.5,
                          Colors.blue,
                          Icons.beach_access,
                        ),
                        const Divider(height: 24),
                        _buildSavingGoalItem(
                          'New Laptop',
                          'KES 80,000',
                          'KES 12,000',
                          0.15,
                          Colors.amber,
                          Icons.laptop_mac,
                        ),
                        const Divider(height: 24),
                        _buildSavingGoalItem(
                          'Emergency Fund',
                          'KES 100,000',
                          'KES 65,000',
                          0.65,
                          Colors.red,
                          Icons.health_and_safety,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  CustomButton(
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
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomButton(
                    isSmall: false,
                    text: 'Get AI Budget Recommendations',
                    onPressed: () {},
                    isOutlined: true,
                    icon: Icons.smart_toy,
                  ),
                  
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
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
        backgroundColor: accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Budget', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBudgetMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryBudgetCard(String title, double amount, double spent, double percentage, Color color, IconData icon) {
    final isOverBudget = percentage > 1.0;
    final progressColor = isOverBudget ? Colors.red : color;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'KES ${spent.toInt()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOverBudget ? Colors.red : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of KES ${amount.toInt()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                height: 4,
                width: MediaQuery.of(context).size.width * 0.4 * (percentage > 1 ? 1 : percentage),
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverBudget ? 'Over budget' : '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isOverBudget ? Colors.red : Colors.grey.shade600,
                ),
              ),
              if (isOverBudget)
                Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 12,
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSavingGoalItem(String title, String target, String current, double percentage, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
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
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$current of $target goal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: MediaQuery.of(context).size.width * 0.6 * percentage,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(percentage * 100).toInt()}% Complete',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}