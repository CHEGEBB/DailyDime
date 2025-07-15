// lib/screens/budget/budget_screen.dart

import 'package:dailydime/screens/budget/create_budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:dailydime/widgets/cards/budget_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String _selectedTimeframe = 'This Month';
  final List<String> _timeframes = ['This Month', 'Last Month', 'Custom'];
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Budget overview card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.pie_chart,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedTimeframe,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const Text(
                                      'Budget Overview',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
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
                        const SizedBox(height: 24),
                        const LinearProgressIndicator(
                          value: 0.65,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KES 32,541 spent',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'KES 50,000 budget',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBudgetMetric(
                              'Remaining',
                              'KES 17,459',
                              Icons.account_balance_wallet,
                            ),
                            _buildBudgetMetric(
                              'Daily Budget',
                              'KES 563/day',
                              Icons.calendar_today,
                            ),
                            _buildBudgetMetric(
                              'Budget Status',
                              '65% Used',
                              Icons.trending_up,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // AI Suggestion for Budget
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💡 AI Suggestion',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'You\'re spending 30% more on Entertainment than last month. Consider reducing to stay on track.',
                                style: TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category Budgets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category budgets
                  const BudgetCard(
                    title: 'Food & Groceries',
                    amount: 15000,
                    spent: 12300,
                    icon: Icons.restaurant,
                    color: Colors.orange,
                    isOverBudget: true,
                  ),
                  
                  const BudgetCard(
                    title: 'Transportation',
                    amount: 5000,
                    spent: 3200,
                    icon: Icons.directions_bus,
                    color: Colors.blue,
                    isOverBudget: true,
                  ),
                  
                  const BudgetCard(
                    title: 'Entertainment',
                    amount: 3000,
                    spent: 3600,
                    icon: Icons.movie,
                    color: Colors.purple,
                    isOverBudget: true, // Add this line if not already present
                  ),
                  
                  const BudgetCard(
                    title: 'Utilities',
                    amount: 7000,
                    spent: 6500,
                    icon: Icons.power,
                    color: Colors.teal,
                    isOverBudget: true,
                  ),
                  
                  const BudgetCard(
                    title: 'Shopping',
                    amount: 8000,
                    spent: 3200,
                    icon: Icons.shopping_bag,
                    color: Colors.pink,
                    isOverBudget: true,
                  ),
                  
                  const BudgetCard(
                    title: 'Health',
                    amount: 4000,
                    spent: 1200,
                    icon: Icons.favorite,
                    color: Colors.red,
                    isOverBudget: true,
                  ),
                  
                  const BudgetCard(
                    title: 'Education',
                    amount: 8000,
                    spent: 5500,
                    icon: Icons.school,
                    color: Colors.indigo,
                    isOverBudget: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Monthly Trends section
                  const Text(
                    'Monthly Budget Trends',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Budget Trend Chart Would Go Here',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Budget Actions
                  CustomButton(
                    isSmall: false, // Add this line with the appropriate value
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
        backgroundColor: theme.colorScheme.primary,
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}