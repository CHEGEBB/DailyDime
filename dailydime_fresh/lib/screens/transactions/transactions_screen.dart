// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Income', 'Expense', 'Transfers'];
  String _selectedTimeframe = 'This Month';
  final List<String> _timeframes = ['Today', 'This Week', 'This Month', 'Last Month', 'Custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Removed SMS tab as requested
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF26D07C); // Using your emerald green accent
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light background for modern feel
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Transactions',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: _buildAllTransactionsTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAllTransactionsTab() {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF26D07C);
    
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Weekly Spending Summary Card - NEW FEATURE
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weekly Spending Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Jul 12-18',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryStatItem('Total Spent', 'KES 28,450'),
                        _buildSummaryStatItem('Budget', 'KES 40,000'),
                        _buildSummaryStatItem('Remaining', 'KES 11,550'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Simple spending progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '71% of weekly budget used',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              '71%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Container(
                              height: 8,
                              width: MediaQuery.of(context).size.width * 0.65, // 71% of width
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // AI Insight Card - NEW FEATURE
              Container(
                margin: const EdgeInsets.only(bottom: 24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Insight',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You spent KES 5,300 on food last week, which is 32% higher than your usual average. Consider meal prepping to reduce expenses.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Get More Tips',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Transaction Summary Card - REDESIGNED
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTimeframe,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showTimeframeBottomSheet(context);
                          },
                          child: Row(
                            children: [
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: accentColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTransactionSummaryItem(
                          'Income',
                          'KES 45,000',
                          Icons.arrow_downward,
                          accentColor,
                        ),
                        _buildTransactionSummaryItem(
                          'Expenses',
                          'KES 32,541',
                          Icons.arrow_upward,
                          Colors.redAccent,
                        ),
                        _buildTransactionSummaryItem(
                          'Balance',
                          'KES 12,459',
                          Icons.account_balance_wallet,
                          Colors.blueAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Filter chips - REDESIGNED
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected 
                              ? null 
                              : Border.all(color: Colors.grey.withOpacity(0.3)),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Transactions header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Today, July 18',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions list with AI insights
              _buildTransactionWithInsight(
                TransactionCard(
                  title: 'Grocery Shopping',
                  category: 'Food',
                  amount: 2350.00,
                  date: DateTime.now().subtract(const Duration(hours: 3)),
                  isExpense: true,
                  icon: Icons.shopping_basket,
                  color: Colors.orange,
                  isSms: false,
                ),
                'You spend about 15% more at this store compared to local markets.',
              ),
              
              _buildTransactionWithInsight(
                TransactionCard(
                  title: 'Uber Ride',
                  category: 'Transport',
                  amount: 450.00,
                  date: DateTime.now().subtract(const Duration(hours: 5)),
                  isExpense: true,
                  icon: Icons.directions_car,
                  color: Colors.blue,
                  isSms: false,
                ),
                'Try using bus routes during off-peak hours to save up to KES 300/week.',
              ),
              
              // Yesterday header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Yesterday, July 17',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              TransactionCard(
                title: 'Salary Deposit',
                category: 'Income',
                amount: 45000.00,
                date: DateTime.now().subtract(const Duration(days: 1)),
                isExpense: false,
                icon: Icons.work,
                color: accentColor,
                isSms: true,
              ),
              
              _buildTransactionWithInsight(
                TransactionCard(
                  title: 'Internet Bill',
                  category: 'Utilities',
                  amount: 2500.00,
                  date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
                  isExpense: true,
                  icon: Icons.wifi,
                  color: Colors.purple,
                  isSms: true,
                ),
                'Consider the new Safaricom Home Fiber plan to save KES 500 monthly.',
              ),
              
              // July 16 header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'July 16, 2025',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildTransactionWithInsight(
                TransactionCard(
                  title: 'Restaurant Dinner',
                  category: 'Food',
                  amount: 1800.00,
                  date: DateTime.now().subtract(const Duration(days: 2)),
                  isExpense: true,
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  isSms: true,
                ),
                'You\'ve spent KES 5,200 on dining out this month, 30% over your budget.',
              ),
              
              TransactionCard(
                title: 'Savings Transfer',
                category: 'Transfers',
                amount: 5000.00,
                date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
                isExpense: true,
                icon: Icons.savings,
                color: Colors.green,
                isSms: true,
              ),
              
              const SizedBox(height: 24),
              
              // Load more button - REDESIGNED
              CustomButton(
                isSmall: false,
                text: 'Load More Transactions',
                onPressed: () {},
                isOutlined: true,
              ),
              
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionWithInsight(Widget transactionCard, String insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        transactionCard,
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSummaryItem(
      String title, String amount, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final accentColor = const Color(0xFF26D07C);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filters.map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  selectedColor: accentColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter ? accentColor : Colors.black87,
                    fontWeight: _selectedFilter == filter ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        Navigator.pop(context);
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeframes.map((timeframe) {
                return ChoiceChip(
                  label: Text(timeframe),
                  selected: _selectedTimeframe == timeframe,
                  selectedColor: accentColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedTimeframe == timeframe ? accentColor : Colors.black87,
                    fontWeight: _selectedTimeframe == timeframe ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTimeframe = timeframe;
                        Navigator.pop(context);
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    isSmall: false,
                    text: 'Apply Filters',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    isSmall: false,
                    text: 'Reset Filters',
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _selectedTimeframe = 'This Month';
                        Navigator.pop(context);
                      });
                    },
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeframeBottomSheet(BuildContext context) {
    final accentColor = const Color(0xFF26D07C);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Time Period',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _timeframes.length,
              itemBuilder: (context, index) {
                final timeframe = _timeframes[index];
                final isSelected = timeframe == _selectedTimeframe;
                
                return ListTile(
                  title: Text(
                    timeframe,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? accentColor : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: accentColor,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedTimeframe = timeframe;
                      Navigator.pop(context);
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}