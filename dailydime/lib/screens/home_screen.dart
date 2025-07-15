// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/widgets/cards/balance_card.dart';
import 'package:dailydime/widgets/cards/budget_card.dart';
import 'package:dailydime/widgets/cards/savings_card.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToTransactions;
  final VoidCallback? onNavigateToBudget;
  final VoidCallback? onNavigateToSavings;
  final VoidCallback? onNavigateToAI;
  final VoidCallback? onNavigateToProfile; // Added profile navigation
  final VoidCallback? onAddTransaction;

  const HomeScreen({
    Key? key,
    this.onNavigateToTransactions,
    this.onNavigateToBudget,
    this.onNavigateToSavings,
    this.onNavigateToAI,
    this.onNavigateToProfile, // Added profile navigation
    this.onAddTransaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: theme.colorScheme.background,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.monetization_on,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DailyDime',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: onNavigateToProfile, // Added profile navigation
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Balance Card
                  const BalanceCard(
                    balance: 12458.75,
                    income: 45000.00,
                    expenses: 32541.25,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // AI Suggestion Card
                  GestureDetector(
                    onTap: onNavigateToAI,
                    child: Container(
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
                                  'Skip eating out today and save KES 350 towards your laptop goal!',
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickAction(
                        context,
                        'Add\nExpense',
                        Icons.arrow_upward,
                        theme.colorScheme.error,
                        () {
                          _showAddTransactionBottomSheet(context);
                        },
                      ),
                      _buildQuickAction(
                        context,
                        'Add\nIncome',
                        Icons.arrow_downward,
                        theme.colorScheme.primary,
                        () {
                          _showAddTransactionBottomSheet(context);
                        },
                      ),
                      _buildQuickAction(
                        context,
                        'New\nBudget',
                        Icons.pie_chart_outline,
                        theme.colorScheme.secondary,
                        onNavigateToBudget ?? () {},
                      ),
                      _buildQuickAction(
                        context,
                        'Create\nGoal',
                        Icons.savings_outlined,
                        Colors.purple,
                        onNavigateToSavings ?? () {},
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Budgets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Budgets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      TextButton(
                        onPressed: onNavigateToBudget,
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    spent: 1500,
                    icon: Icons.movie,
                    color: Colors.purple,
                    isOverBudget: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Savings Goals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Savings Goals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      TextButton(
                        onPressed: onNavigateToSavings,
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SavingsCard(
                          title: 'New Laptop',
                          targetAmount: 80000,
                          savedAmount: 35000,
                          targetDate: DateTime(2026, 1, 15),
                          onTap: () {
                            if (onNavigateToSavings != null) {
                              onNavigateToSavings!();
                            }
                          },
                        ),
                        SavingsCard(
                          title: 'Holiday Trip',
                          targetAmount: 45000,
                          savedAmount: 10000,
                          targetDate: DateTime(2025, 12, 20),
                          onTap: () {
                            if (onNavigateToSavings != null) {
                              onNavigateToSavings!();
                            }
                          },
                        ),
                        SavingsCard(
                          title: 'Emergency Fund',
                          targetAmount: 100000,
                          savedAmount: 40000,
                          targetDate: DateTime(2026, 6, 30),
                          onTap: () {
                            if (onNavigateToSavings != null) {
                              onNavigateToSavings!();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      TextButton(
                        onPressed: onNavigateToTransactions,
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TransactionCard(
                    title: 'Grocery Shopping',
                    category: 'Food',
                    amount: 2350.00,
                    date: DateTime.now().subtract(const Duration(hours: 3)),
                    isExpense: true,
                    icon: Icons.shopping_basket,
                    color: Colors.orange,
                    isSms: true,
                  ),
                  TransactionCard(
                    title: 'Salary Deposit',
                    category: 'Income',
                    amount: 45000.00,
                    date: DateTime.now().subtract(const Duration(days: 1)),
                    isExpense: false,
                    icon: Icons.work,
                    color: theme.colorScheme.primary,
                    isSms: true,
                  ),
                  TransactionCard(
                    title: 'Uber Ride',
                    category: 'Transport',
                    amount: 450.00,
                    date: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
                    isExpense: true,
                    icon: Icons.directions_car,
                    color: Colors.blue,
                    isSms: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomButton(
                    text: 'View All Transactions',
                    onPressed: onNavigateToTransactions ?? () {},
                    isOutlined: true,
                    isSmall: false,
                  ),
                  
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTransactionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Transaction type toggle
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Amount field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'KES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '0.00',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 2,
                          color: Theme.of(context).colorScheme.primary,
                          margin: const EdgeInsets.only(left: 4, bottom: 4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Category dropdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.title,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter title',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date and time field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Today, 3:30 PM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              
              const Spacer(),
              
              CustomButton(
                text: 'Save Transaction',
                onPressed: () {
                  Navigator.pop(context);
                },
                isSmall: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}