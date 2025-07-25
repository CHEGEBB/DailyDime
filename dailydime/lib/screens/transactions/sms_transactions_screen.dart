// lib/screens/transactions/sms_transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/widgets/cards/transaction_card.dart';
import 'package:dailydime/widgets/common/custom_button.dart';

class SmsTransactionsScreen extends StatefulWidget {
  const SmsTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<SmsTransactionsScreen> createState() => _SmsTransactionsScreenState();
}

class _SmsTransactionsScreenState extends State<SmsTransactionsScreen> {
  bool _hasPermission = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF26D07C);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'SMS Transactions',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _hasPermission ? _buildTransactionsList() : _buildPermissionRequest(),
      ),
    );
  }
  
  Widget _buildPermissionRequest() {
    final accentColor = const Color(0xFF26D07C);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image placeholder (you'll need to add actual assets)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sms,
                size: 80,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Automatic Transaction Detection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'DailyDime can automatically detect and categorize transactions from your M-Pesa, Airtel Money, and T-Kash SMS messages.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your Privacy is Protected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DailyDime only reads SMS messages from financial services and processes them locally on your device. Your messages are never uploaded to our servers.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              isSmall: false,buttonColor: Colors.blue,
              text: 'Grant SMS Permission',
              onPressed: () {
                // This would request SMS permission
                setState(() {
                  _hasPermission = true;
                });
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Not Now',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsList() {
    final accentColor = const Color(0xFF26D07C);
    
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // SMS Transactions Insights Card - NEW FEATURE
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
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
                          'SMS Insights',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
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
                            'Last 30 Days',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'We detected 42 financial SMS messages',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSmsInsightItem('M-Pesa', '32', Icons.phone_android),
                        _buildSmsInsightItem('Airtel Money', '8', Icons.phone_android),
                        _buildSmsInsightItem('T-Kash', '2', Icons.phone_android),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI has categorized your transactions with 97% accuracy',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // SMS provider summary
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
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
                    Text(
                      'Connected SMS Providers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSmsProviderItem(
                          'M-Pesa',
                          true,
                          Colors.green,
                        ),
                        _buildSmsProviderItem(
                          'Airtel Money',
                          true,
                          Colors.red,
                        ),
                        _buildSmsProviderItem(
                          'T-Kash',
                          false,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Last sync info
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last synchronized: Today, 2:45 PM',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Auto-sync is enabled',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.settings, color: accentColor),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              
              // Detected Transactions header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detected Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '42 Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Today header
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
              
              // Transactions from SMS with AI enhancements
              _buildTransactionWithAI(
                TransactionCard(
                  title: 'MPESA Payment to Naivas',
                  category: 'Shopping',
                  amount: 3450.00,
                  date: DateTime.now().subtract(const Duration(hours: 2)),
                  isExpense: true,
                  icon: Icons.shopping_cart,
                  color: Colors.pink,
                  isSms: true, onTap: () {  },
                ),
                'You might find better deals at Carrefour for similar items.',
              ),
              
              _buildTransactionWithAI(
                TransactionCard(
                  title: 'MPESA Payment to John Doe',
                  category: 'Transfers',
                  amount: 1000.00,
                  date: DateTime.now().subtract(const Duration(hours: 5)),
                  isExpense: true,
                  icon: Icons.send,
                  color: Colors.blue,
                  isSms: true, onTap: () {  },
                ),
                'You send an average of KES 900 monthly to this recipient.',
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
                title: 'MPESA Received from ABC Ltd',
                category: 'Income',
                amount: 45000.00,
                date: DateTime.now().subtract(const Duration(days: 1)),
                isExpense: false,
                icon: Icons.work,
                color: accentColor,
                isSms: true, onTap: () {  },
              ),
              
              _buildTransactionWithAI(
                TransactionCard(
                  title: 'MPESA Payment to Kenya Power',
                  category: 'Utilities',
                  amount: 2500.00,
                  date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
                  isExpense: true,
                  icon: Icons.power,
                  color: Colors.teal,
                  isSms: true, onTap: () {  },
                ),
                'Your power bill is 12% higher than last month. Check for appliances that might be consuming more power.',
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      isSmall: false,buttonColor: Colors.blue,
                      text: 'Sync New SMS',
                      onPressed: () {},
                      icon: Icons.sync,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      isSmall: false,buttonColor: Colors.blue,
                      text: 'Import Historical SMS',
                      onPressed: () {},
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSmsInsightItem(String provider, String count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          provider,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSmsProviderItem(String provider, bool isConnected, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: isConnected ? color : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          provider,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isConnected ? Colors.black87 : Colors.grey,
          ),
        ),
        Text(
          isConnected ? 'Connected' : 'Not Connected',
          style: TextStyle(
            fontSize: 12,
            color: isConnected ? color : Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionWithAI(Widget transactionCard, String insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        transactionCard,
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.1),
                width: 1,
              ),
            ),
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
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}