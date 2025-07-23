// lib/screens/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:dailydime/screens/transactions/add_transaction_screen.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dailydime/services/transaction_ai_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:dailydime/widgets/cards/insight_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;

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
  bool _isLoadingInsights = false;
  List<String> _insights = [];
  
  // Color scheme
  final accentColor = const Color(0xFF26D07C); // Emerald green accent
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.initialize();
      
      // Load AI insights once data is available
      if (!provider.isLoading) {
        _loadInsights(provider.filteredTransactions);
      }
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
  
  Future<void> _loadInsights(List<dynamic> transactions) async {
    if (transactions.isEmpty) return;
    
    setState(() {
      _isLoadingInsights = true;
    });
    
    try {
      final typedTransactions = transactions.map((tx) => tx as Transaction).toList();
      final result = await TransactionAIService().generateSpendingInsights(
        typedTransactions,
        timeframe: 'week',
      );
      
      if (result['success'] && result['insights'].isNotEmpty) {
        setState(() {
          _insights = List<String>.from(result['insights']);
        });
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
    } finally {
      setState(() {
        _isLoadingInsights = false;
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
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light background for modern feel
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final isLoading = transactionProvider.isLoading;
          
          if (isLoading) {
            return _buildLoadingState();
          }
          
          final transactions = transactionProvider.filteredTransactions;
          final balance = transactionProvider.currentBalance;
          
          // Refresh insights if needed
          if (_insights.isEmpty && !_isLoadingInsights) {
            _loadInsights(transactions);
          }
          
          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 310.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: _isCompactHeader ? accentColor : Colors.white,
                  elevation: 0,
                  title: _isCompactHeader 
                      ? Text(
                          'Transactions',
                          style: const TextStyle(
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
                      onPressed: () {
                        _showSearchSheet(context);
                      },
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
                    background: _buildHeader(accentColor, balance, size, transactions),
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
                          Tab(text: 'All'),
                          Tab(text: 'Income'),
                          Tab(text: 'Expenses'),
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
                _buildTransactionsList(transactions.where((tx) => !tx.isExpense).toList()),
                _buildTransactionsList(transactions.where((tx) => tx.isExpense).toList()),
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

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 310.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(accentColor, 0, MediaQuery.of(context).size, []),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Income'),
                      Tab(text: 'Expenses'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, double balance, Size size, List<dynamic> transactions) {
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
              _buildWeeklySpendingSummary(balance, transactions, size),
              const SizedBox(height: 16),
              _buildAIInsightCard(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWeeklySpendingSummary(double balance, List<dynamic> transactions, Size size) {
    // Calculate weekly budget and remaining amount
    final weeklyBudget = 40000.0; // This would come from your budget settings
    final weeklySpent = _calculateWeeklySpending(transactions);
    final remaining = weeklyBudget - weeklySpent;
    final percentUsed = (weeklySpent / weeklyBudget * 100).clamp(0, 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Spending Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Jul 12-18',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Spent', 'KES ${weeklySpent.toInt()}'),
              _buildSummaryItem('Budget', 'KES ${weeklyBudget.toInt()}'),
              _buildSummaryItem('Remaining', 'KES ${remaining.toInt()}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$percentUsed% of weekly budget used',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                '$percentUsed%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: percentUsed > 90 ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentUsed / 100,
              backgroundColor: Colors.grey.shade200,
              color: percentUsed > 90 ? Colors.red : accentColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAIInsightCard() {
    if (_isLoadingInsights) {
      return Skeletonizer(
        enabled: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insight',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Loading your personalized financial insights...',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: Colors.amber.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insight',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add more transactions to get personalized insights',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Get More Tips',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Display the first insight (main insight)
    final insight = _insights.isNotEmpty ? _insights[0] : 
      'You spent KES 5,300 on food last week, which is 32% higher than your usual average. Consider meal prepping to reduce expenses.';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: Colors.amber.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Insight',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _showAllInsights();
            },
            child: Text(
              'Get More Tips',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
        
        // Refresh insights
        final refreshedTransactions = Provider.of<TransactionProvider>(context, listen: false).filteredTransactions;
        _loadInsights(refreshedTransactions);
      },
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dateTransactions = groupedTransactions[date]!;
          
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            duration: const Duration(milliseconds: 300),
            child: Column(
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
                      if (_shouldShowInsightForTransaction(transaction))
                        _buildInsightForTransaction(transaction),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
  
  bool _shouldShowInsightForTransaction(dynamic transaction) {
    // Only show insights for certain transactions to avoid overloading the UI
    if (transaction.amount > 1000) {
      // Show for larger transactions
      return true;
    }
    
    if (transaction.category == 'Food' || transaction.category == 'Transport') {
      // Show for common categories
      return math.Random().nextBool(); // Only show for 50% of these transactions
    }
    
    return false;
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
          const Spacer(),
          Text(
            _calculateDayTotal(dateString),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  String _calculateDayTotal(String dateString) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = provider.filteredTransactions;
    
    double total = 0;
    for (var tx in transactions) {
      if (DateFormat('yyyy-MM-dd').format(tx.date) == dateString) {
        if (tx.isExpense) {
          total -= tx.amount;
        } else {
          total += tx.amount;
        }
      }
    }
    
    final sign = total >= 0 ? '+' : '';
    return '$sign${currencyFormat.format(total)}';
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
          Image.asset(
            'assets/images/empty_transactions.png',
            height: 180,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add your first transaction or wait for M-Pesa messages to be detected',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
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
                const Text(
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
                        style: const TextStyle(
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
            FutureBuilder<Map<String, dynamic>>(
              future: TransactionAIService().generateTransactionInsight(
                transaction,
                Provider.of<TransactionProvider>(context, listen: false)
                    .filteredTransactions
                    .map((tx) => tx as Transaction)
                    .toList(),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        const Text('Generating insight...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasData && snapshot.data!['success']) {
                  final insight = snapshot.data!['insight'];
                  return Container(
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
                          insight ?? 'No insight available for this transaction.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
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
              style: const TextStyle(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this ${currencyFormat.format(transaction.amount)} ${transaction.title} transaction?'),
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
                  const Text(
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
              const Text(
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
              const Text(
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
              const Text(
                'Categories',
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
                children: [
                  'All Categories',
                  'Food',
                  'Transport',
                  'Shopping',
                  'Utilities',
                  'Health',
                  'Education',
                  'Entertainment',
                ].map((category) {
                  return FilterChip(
                    label: Text(category),
                    selected: provider.selectedCategories.contains(category) || 
                             (category == 'All Categories' && provider.selectedCategories.isEmpty),
                    selectedColor: accentColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: provider.selectedCategories.contains(category) || 
                             (category == 'All Categories' && provider.selectedCategories.isEmpty)
                          ? accentColor
                          : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (category == 'All Categories') {
                          provider.selectedCategories = [];
                        } else {
                          if (selected) {
                            provider.selectedCategories.add(category);
                          } else {
                            provider.selectedCategories.remove(category);
                          }
                        }
                      });
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
                        provider.applyFilters();
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
                          provider.resetFilters();
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
      ),
    );
  }
  
  void _showSearchSheet(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final TextEditingController searchController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      searchController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: searchController.text.isEmpty
                      ? _buildRecentSearches()
                      : _buildSearchResults(searchController.text, provider.filteredTransactions),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Searches',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Food',
            'Transport',
            'Mpesa',
            'Shopping',
          ].map((term) => ActionChip(
            label: Text(term),
            onPressed: () {},
          )).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Popular Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Food & Dining',
            'Transport',
            'Shopping',
            'Utilities',
            'Health',
            'Education',
            'Entertainment',
          ].map((category) => ActionChip(
            avatar: Icon(
              _getCategoryIcon(category),
              size: 16,
              color: _getCategoryColor(category),
            ),
            label: Text(category),
            onPressed: () {},
          )).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSearchResults(String query, List<dynamic> transactions) {
    // Filter transactions based on search query
    final filteredTransactions = transactions.where((tx) {
      final title = tx.title?.toLowerCase() ?? '';
      final category = tx.category?.toLowerCase() ?? '';
      final amount = tx.amount.toString();
      final q = query.toLowerCase();
      
      return title.contains(q) || category.contains(q) || amount.contains(q);
    }).toList();
    
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching transactions found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = filteredTransactions[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tx.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.icon,
              color: tx.color,
              size: 24,
            ),
          ),
          title: Text(
            tx.title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${tx.category} • ${DateFormat('MMM d, yyyy').format(tx.date)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Text(
            currencyFormat.format(tx.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.isExpense ? Colors.red.shade700 : accentColor,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            _showTransactionDetails(tx);
          },
        );
      },
    );
  }
  
  void _showAllInsights() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Insights',
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
            Expanded(
              child: _isLoadingInsights
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing your transactions...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _insights.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 64,
                                color: Colors.amber.shade200,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No insights available yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add more transactions to get personalized insights',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _insights.length,
                          itemBuilder: (context, index) {
                            return InsightCard(
                              title: index == 0 ? 'Summary' : 'Insight ${index}',
                              content: _insights[index],
                              iconData: _getInsightIcon(index),
                              color: _getInsightColor(index),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              isSmall: false,
              text: 'Generate More Insights',
              onPressed: () {
                Navigator.pop(context);
                final transactions = Provider.of<TransactionProvider>(context, listen: false).filteredTransactions;
                _loadInsights(transactions);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  double _calculateWeeklySpending(List<dynamic> transactions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    startOfWeek.subtract(const Duration(hours: 24)); // Start from Sunday
    
    return transactions
        .where((tx) => tx.isExpense && tx.date.isAfter(startOfWeek))
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
  
  IconData _getInsightIcon(int index) {
    switch (index) {
      case 0:
        return Icons.assessment;
      case 1:
        return Icons.trending_up;
      case 2:
        return Icons.category;
      case 3:
        return Icons.schedule;
      case 4:
        return Icons.tips_and_updates;
      default:
        return Icons.lightbulb_outline;
    }
  }
  
  Color _getInsightColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue.shade700;
      case 1:
        return Colors.green.shade700;
      case 2:
        return Colors.purple.shade700;
      case 3:
        return Colors.orange.shade700;
      case 4:
        return Colors.red.shade700;
      default:
        return Colors.amber.shade700;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_bus;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
        return Icons.power;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Colors.green.shade700;
      case 'transport':
        return Colors.blue.shade700;
      case 'shopping':
        return Colors.purple.shade700;
      case 'utilities':
        return Colors.orange.shade700;
      case 'health':
        return Colors.red.shade700;
      case 'education':
        return Colors.indigo.shade700;
      case 'entertainment':
        return Colors.pink.shade400;
      default:
        return Colors.grey.shade700;
    }
  }
}