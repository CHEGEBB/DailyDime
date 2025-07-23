// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
  bool _isCompactHeader = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).initialize();
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 140 && !_isCompactHeader) {
      setState(() {
        _isCompactHeader = true;
      });
    } else if (_scrollController.offset <= 140 && _isCompactHeader) {
      setState(() {
        _isCompactHeader = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF26D07C); // Emerald green accent
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light background for modern feel
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final isLoading = transactionProvider.isLoading;
          
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF26D07C)),
              ),
            );
          }
          
          final transactions = transactionProvider.filteredTransactions;
          final balance = transactionProvider.currentBalance;
          
          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 260.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: _isCompactHeader ? accentColor : Colors.white,
                  elevation: 0,
                  title: _isCompactHeader 
                      ? Text(
                          'Transactions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.search, 
                        color: _isCompactHeader ? Colors.white : Colors.black87,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.filter_list, 
                        color: _isCompactHeader ? Colors.white : Colors.black87,
                      ),
                      onPressed: () {
                        _showFilterBottomSheet(context);
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(accentColor, balance, size),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: accentColor,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: accentColor,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'All Transactions'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsList(transactions),
              ],
            ),
          );
        },
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
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, double balance, Size size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor,
            accentColor.withOpacity(0.8),
          ],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Track your financial activity',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(balance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<TransactionProvider>(
                      builder: (context, provider, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickStat(
                              'Income',
                              Icons.arrow_downward,
                              Colors.green.shade300,
                              _calculateIncome(provider.filteredTransactions),
                              size,
                            ),
                            _buildQuickStat(
                              'Expenses',
                              Icons.arrow_upward,
                              Colors.red.shade300,
                              _calculateExpenses(provider.filteredTransactions),
                              size,
                            ),
                            _buildQuickStat(
                              'Savings',
                              Icons.savings,
                              Colors.amber.shade300,
                              balance * 0.1, // Just a placeholder for savings
                              size,
                            ),
                          ],
                        );
                      },
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

  Widget _buildQuickStat(String title, IconData icon, Color iconColor, double amount, Size size) {
    return Container(
      width: (size.width - 80) / 3,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: iconColor,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount).split('.').first,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateIncome(List<dynamic> transactions) {
    return transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double _calculateExpenses(List<dynamic> transactions) {
    return transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  Widget _buildTransactionsList(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    // Group transactions by date
    final Map<String, List<dynamic>> groupedTransactions = {};
    for (var transaction in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // Sort dates (newest first)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<TransactionProvider>(context, listen: false).refreshTransactions();
      },
      color: const Color(0xFF26D07C),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dateTransactions = groupedTransactions[date]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(date),
              ...dateTransactions.map((transaction) {
                return Column(
                  children: [
                    TransactionCard(
                      title: transaction.title,
                      category: transaction.category,
                      amount: transaction.amount,
                      date: transaction.date,
                      isExpense: transaction.isExpense,
                      icon: transaction.icon,
                      color: transaction.color,
                      isSms: transaction.isSms,
                      onTap: () => _showTransactionDetails(transaction),
                    ),
                    // Show AI insight for some transactions
                    if (transaction.category == 'Food' || transaction.amount > 1000)
                      _buildInsightForTransaction(transaction),
                  ],
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    String formattedDate;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      formattedDate = 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      formattedDate = 'Yesterday';
    } else {
      formattedDate = DateFormat('MMMM d, yyyy').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              formattedDate,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightForTransaction(dynamic transaction) {
    String insight;
    if (transaction.category == 'Food') {
      insight = 'You spend about 20% more at this place compared to similar restaurants.';
    } else if (transaction.amount > 5000) {
      insight = 'This is a large transaction. Consider saving 10% of this amount.';
    } else if (transaction.category == 'Transport') {
      insight = 'Try using public transport on weekdays to save up to KES 300/week.';
    } else {
      insight = 'This transaction is higher than your usual spending in this category.';
    }

    return Padding(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction or wait for M-Pesa messages',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            isSmall: true,
            text: 'Add Transaction',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(dynamic transaction) {
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
                  'Transaction Details',
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: transaction.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    transaction.icon,
                    color: transaction.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(transaction.amount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: transaction.isExpense ? Colors.red.shade700 : accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailItem('Date & Time', DateFormat('MMM d, yyyy • h:mm a').format(transaction.date)),
            if (transaction.mpesaCode != null)
              _buildDetailItem('M-Pesa Code', transaction.mpesaCode!),
            if (transaction.sender != null)
              _buildDetailItem('Sender', transaction.sender!),
            if (transaction.recipient != null)
              _buildDetailItem('Recipient', transaction.recipient!),
            if (transaction.agent != null)
              _buildDetailItem('Agent', transaction.agent!),
            if (transaction.business != null)
              _buildDetailItem('Business', transaction.business!),
            if (transaction.balance != null)
              _buildDetailItem('Balance After', currencyFormat.format(transaction.balance!)),
            if (transaction.isSms)
              _buildDetailItem('Source', 'SMS Message'),
            
            const SizedBox(height: 24),
            if (transaction.category == 'Food' || transaction.amount > 1000)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Insight',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transaction.category == 'Food'
                          ? 'Your food spending is 15% higher than last month. Consider meal prepping on weekends to reduce expenses by up to KES 4,000 monthly.'
                          : 'This transaction represents 8% of your monthly income. Setting aside 10% of large purchases for your savings could help you reach your goals faster.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    isSmall: false,
                    text: 'Edit',
                    onPressed: () {
                      // Edit transaction logic
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    isSmall: false,
                    text: 'Delete',
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(transaction);
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(dynamic transaction) {
    final accentColor = const Color(0xFF26D07C);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this ${transaction.amount} ${transaction.title} transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<TransactionProvider>(context, listen: false)
                  .deleteTransaction(transaction.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final accentColor = const Color(0xFF26D07C);
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
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
                children: ['All', 'Income', 'Expense', 'Transfers'].map((filter) {
                  return ChoiceChip(
                    label: Text(filter),
                    selected: provider.filter == filter,
                    selectedColor: accentColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: provider.filter == filter ? accentColor : Colors.black87,
                      fontWeight: provider.filter == filter ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          provider.setFilter(filter);
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
                children: ['Today', 'This Week', 'This Month', 'Last Month', 'Custom'].map((timeframe) {
                  return ChoiceChip(
                    label: Text(timeframe),
                    selected: provider.timeframe == timeframe,
                    selectedColor: accentColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: provider.timeframe == timeframe ? accentColor : Colors.black87,
                      fontWeight: provider.timeframe == timeframe ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          provider.setTimeframe(timeframe);
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
                          provider.setFilter('All');
                          provider.setTimeframe('This Month');
                        });
                        Navigator.pop(context);
                      },
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}