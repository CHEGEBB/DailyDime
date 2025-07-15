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
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('SMS Transactions'),
      ),
      body: SafeArea(
        child: _hasPermission ? _buildTransactionsList() : _buildPermissionRequest(),
      ),
    );
  }
  
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/sms_permission.png',
              height: 180,
            ),
            const SizedBox(height: 24),
            const Text(
              'SMS Transaction Detection',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'DailyDime can automatically detect transactions from your M-Pesa, Airtel Money, and T-Kash SMS messages to help you track your spending without manual entry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 12),
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
                  const SizedBox(height: 8),
                  const Text(
                    'DailyDime only reads SMS messages from financial services and processes them locally on your device. Your messages are never uploaded to our servers.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
               isSmall: false,
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
              child: const Text('Not Now'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsList() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // SMS provider summary
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected SMS Providers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSmsProviderItem(
                          'M-Pesa',
                          true,
                          'assets/images/mpesa_logo.png',
                        ),
                        _buildSmsProviderItem(
                          'Airtel Money',
                          true,
                          'assets/images/airtel_logo.png',
                        ),
                        _buildSmsProviderItem(
                          'T-Kash',
                          false,
                          'assets/images/tkash_logo.png',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Settings section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SMS Analysis Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Last sync
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Last synchronized: Today, 2:45 PM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Detected Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Today header
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
              
              // Transactions from SMS
              TransactionCard(
                title: 'MPESA Payment to Naivas',
                category: 'Shopping',
                amount: 3450.00,
                date: DateTime.now().subtract(const Duration(hours: 2)),
                isExpense: true,
                icon: Icons.shopping_cart,
                color: Colors.pink,
                isSms: true,
              ),
              
              TransactionCard(
                title: 'MPESA Payment to John Doe',
                category: 'Transfers',
                amount: 1000.00,
                date: DateTime.now().subtract(const Duration(hours: 5)),
                isExpense: true,
                icon: Icons.send,
                color: Colors.blue,
                isSms: true,
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
                title: 'MPESA Received from ABC Ltd',
                category: 'Income',
                amount: 45000.00,
                date: DateTime.now().subtract(const Duration(days: 1)),
                isExpense: false,
                icon: Icons.work,
                color: Colors.green,
                isSms: true,
              ),
              
              TransactionCard(
                title: 'MPESA Payment to Kenya Power',
                category: 'Utilities',
                amount: 2500.00,
                date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
                isExpense: true,
                icon: Icons.power,
                color: Colors.teal,
                isSms: true,
              ),
              
              const SizedBox(height: 24),
              
              CustomButton(
                 isSmall: false,
                text: 'Sync New SMS Transactions',
                onPressed: () {},
                icon: Icons.sync,
              ),
              
              const SizedBox(height: 16),
              
              CustomButton(
                 isSmall: false,
                text: 'Import Historical SMS',
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
  
  Widget _buildSmsProviderItem(String provider, bool isConnected, String logoAsset) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: isConnected ? Colors.green : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          provider,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isConnected ? Colors.black87 : Colors.grey,
          ),
        ),
        Text(
          isConnected ? 'Connected' : 'Not Connected',
          style: TextStyle(
            fontSize: 10,
            color: isConnected ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}