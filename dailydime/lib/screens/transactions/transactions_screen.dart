// lib/screens/transactions/transactions_screen.dart

import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Transactions'),
            Tab(text: 'SMS Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTransactionsTab(),
          _buildSmsTransactionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAllTransactionsTab() {
    final theme = Theme.of(context);
    
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Transaction Summary
              Container(
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTimeframe,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTransactionSummaryItem(
                          'Income',
                          'KES 45,000',
                          Icons.arrow_downward,
                          theme.colorScheme.primary,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        _buildTransactionSummaryItem(
                          'Expenses',
                          'KES 32,541',
                          Icons.arrow_upward,
                          theme.colorScheme.error,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        _buildTransactionSummaryItem(
                          'Balance',
                          'KES 12,459',
                          Icons.account_balance_wallet,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Filter chips
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
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Today, July 15',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Transactions list
              TransactionCard(
                title: 'Grocery Shopping',
                category: 'Food',
                amount: 2350.00,
                date: DateTime.now().subtract(const Duration(hours: 3)),
                isExpense: true,
                icon: Icons.shopping_basket,
                color: Colors.orange,
                isSms: false, // Add this line
              ),
              TransactionCard(
                title: 'Uber Ride',
                category: 'Transport',
                amount: 450.00,
                date: DateTime.now().subtract(const Duration(hours: 5)),
                isExpense: true,
                icon: Icons.directions_car,
                color: Colors.blue,
                isSms: false, // Add this line
              ),
              
              // Yesterday header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Yesterday, July 14',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
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
                title: 'Internet Bill',
                category: 'Utilities',
                amount: 2500.00,
                date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
                isExpense: true,
                icon: Icons.wifi,
                color: Colors.purple,
                isSms: true,
              ),
              
              // July 13 header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'July 13, 2025',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              
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
              
              const SizedBox(height: 16),
              
              // Load more button
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

  Widget _buildSmsTransactionsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sms,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'SMS Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Automatically detect and categorize transactions from your SMS messages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Grant SMS Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummaryItem(
      String title, String amount, IconData icon, Color color) {
    return Column(
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
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _filters.map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
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
            const Text(
              'Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _timeframes.map((timeframe) {
                return ChoiceChip(
                  label: Text(timeframe),
                  selected: _selectedTimeframe == timeframe,
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
            CustomButton(
              isSmall: false,
              text: 'Apply Filters',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
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
          ],
        ),
      ),
    );
  }

  void _showTimeframeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time Period',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
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