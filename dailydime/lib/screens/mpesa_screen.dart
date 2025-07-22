// lib/screens/mpesa_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../services/mpesa_handling_service.dart';

class MpesaScreen extends StatefulWidget {
  const MpesaScreen({Key? key}) : super(key: key);

  @override
  State<MpesaScreen> createState() => _MpesaScreenState();
}

class _MpesaScreenState extends State<MpesaScreen> with SingleTickerProviderStateMixin {
  final MpesaHandlingService _mpesaService = MpesaHandlingService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController(text: 'DailyDime');
  
  late TabController _tabController;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
  
  Future<void> _initiateStkPush() async {
    if (_phoneController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields'))
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _isSuccess = false;
    });
    
    try {
      double amount = double.parse(_amountController.text);
      
      Map<String, dynamic> result = await _mpesaService.initiateSTKPush(
        phoneNumber: _phoneController.text,
        amount: amount,
        accountReference: _referenceController.text,
      );
      
      setState(() {
        _isProcessing = false;
        
        if (result.containsKey('ResponseCode') && result['ResponseCode'] == '0') {
          _isSuccess = true;
          _statusMessage = 'Request sent! Please check your phone to complete the transaction.';
        } else {
          _isSuccess = false;
          _statusMessage = 'Error: ${result['errorMessage'] ?? 'Unknown error occurred'}';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Error: $e';
      });
    }
  }
  
  Future<void> _sendMoney() async {
    if (_phoneController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields'))
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _isSuccess = false;
    });
    
    try {
      double amount = double.parse(_amountController.text);
      
      Map<String, dynamic> result = await _mpesaService.sendMoneyToCustomer(
        phoneNumber: _phoneController.text,
        amount: amount,
        remarks: _referenceController.text,
      );
      
      setState(() {
        _isProcessing = false;
        
        if (result['success'] == true) {
          _isSuccess = true;
          _statusMessage = 'Money sent successfully! Transaction ID: ${result['transactionId']}';
        } else {
          _isSuccess = false;
          _statusMessage = 'Error: ${result['message'] ?? 'Unknown error occurred'}';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Error: $e';
      });
    }
  }
  
  Future<void> _checkBalance() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _isSuccess = false;
    });
    
    try {
      Map<String, dynamic> result = await _mpesaService.checkAccountBalance();
      
      setState(() {
        _isProcessing = false;
        
        if (result['success'] == true) {
          _isSuccess = true;
          _statusMessage = 'Balance: KES ${result['balance'].toStringAsFixed(2)}';
        } else {
          _isSuccess = false;
          _statusMessage = 'Error: ${result['message'] ?? 'Unknown error occurred'}';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final accentColor = Color(0xFF26D07C); // Emerald green
    
    // Set status bar to match theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient background
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with back button and title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'M-PESA Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Balance card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage('assets/images/pattern2.png'),
                        fit: BoxFit.cover,
                        opacity: 0.1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'M-PESA Balance',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Refresh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'KES 24,550.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated: Just now',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tab bar for different functions
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[800],
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(text: 'Pay'),
                        Tab(text: 'Send'),
                        Tab(text: 'Services'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pay Tab
                  _buildPayTab(accentColor),
                  
                  // Send Tab
                  _buildSendTab(accentColor),
                  
                  // Services Tab
                  _buildServicesTab(accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Pay Tab Content
  Widget _buildPayTab(Color accentColor) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pay via M-PESA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Input fields
          _buildInputField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '07XXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
          ),
          
          const SizedBox(height: 16),
          
          _buildInputField(
            controller: _amountController,
            label: 'Amount (KES)',
            hint: 'e.g. 1000',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.monetization_on,
          ),
          
          const SizedBox(height: 16),
          
          _buildInputField(
            controller: _referenceController,
            label: 'Reference (Optional)',
            hint: 'e.g. Grocery',
            prefixIcon: Icons.description,
          ),
          
          const SizedBox(height: 30),
          
          // Pay button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _initiateStkPush,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: _isProcessing
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          // Status message
          if (_statusMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 30),
          
          // Quick pay options
          Text(
            'Quick Pay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickPayOption(
                icon: Icons.shopping_cart,
                label: 'Buy Goods',
                onTap: () {},
              ),
              _buildQuickPayOption(
                icon: Icons.receipt_long,
                label: 'Pay Bill',
                onTap: () {},
              ),
              _buildQuickPayOption(
                icon: Icons.lightbulb_outline,
                label: 'KPLC',
                onTap: () {},
              ),
              _buildQuickPayOption(
                icon: Icons.water_drop_outlined,
                label: 'Water',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Send Tab Content
  Widget _buildSendTab(Color accentColor) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Money',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Input fields
          _buildInputField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '07XXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
          ),
          
          const SizedBox(height: 16),
          
          _buildInputField(
            controller: _amountController,
            label: 'Amount (KES)',
            hint: 'e.g. 1000',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.monetization_on,
          ),
          
          const SizedBox(height: 16),
          
          _buildInputField(
            controller: _referenceController,
            label: 'Remarks (Optional)',
            hint: 'e.g. Lunch',
            prefixIcon: Icons.description,
          ),
          
          const SizedBox(height: 30),
          
          // Send button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _sendMoney,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: _isProcessing
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      'Send Money',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          // Status message
          if (_statusMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 30),
          
          // Recent contacts
          Text(
            'Recent Contacts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildContactItem(
                  name: 'John Doe',
                  phone: '0712345678',
                  onTap: () {
                    setState(() {
                      _phoneController.text = '0712345678';
                    });
                  },
                ),
                _buildContactItem(
                  name: 'Jane Smith',
                  phone: '0723456789',
                  onTap: () {
                    setState(() {
                      _phoneController.text = '0723456789';
                    });
                  },
                ),
                _buildContactItem(
                  name: 'Bob Johnson',
                  phone: '0734567890',
                  onTap: () {
                    setState(() {
                      _phoneController.text = '0734567890';
                    });
                  },
                ),
                _buildContactItem(
                  name: 'Alice Brown',
                  phone: '0745678901',
                  onTap: () {
                    setState(() {
                      _phoneController.text = '0745678901';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Services Tab Content
  Widget _buildServicesTab(Color accentColor) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'M-PESA Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Services grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildServiceCard(
                icon: Icons.account_balance,
                label: 'Check Balance',
                description: 'View your M-PESA balance',
                color: accentColor,
                onTap: _checkBalance,
              ),
              _buildServiceCard(
                icon: Icons.receipt_long,
                label: 'Mini Statement',
                description: 'View recent transactions',
                color: Colors.orange,
                onTap: () {},
              ),
              _buildServiceCard(
                icon: Icons.swap_horiz,
                label: 'Withdraw Cash',
                description: 'At agent or ATM',
                color: Colors.purple,
                onTap: () {},
              ),
              _buildServiceCard(
                icon: Icons.credit_card,
                label: 'Lipa na M-PESA',
                description: 'Pay for goods and services',
                color: Colors.blue,
                onTap: () {},
              ),
              _buildServiceCard(
                icon: Icons.savings,
                label: 'M-Shwari',
                description: 'Save and get loans',
                color: Colors.teal,
                onTap: () {},
              ),
              _buildServiceCard(
                icon: Icons.groups,
                label: 'Chama',
                description: 'Group savings',
                color: Colors.red,
                onTap: () {},
              ),
            ],
          ),
          
          // Status message
          if (_statusMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 30),
          
          // Transaction history section
          Text(
            'Recent M-PESA Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildTransactionItem(
            icon: Icons.arrow_upward,
            title: 'Sent to John Doe',
            subtitle: '18 Jul 2025, 10:30 AM',
            amount: '-KES 1,000.00',
            isDebit: true,
          ),
          
          const SizedBox(height: 12),
          
          _buildTransactionItem(
            icon: Icons.arrow_downward,
            title: 'Received from Jane Smith',
            subtitle: '17 Jul 2025, 02:15 PM',
            amount: '+KES 2,500.00',
            isDebit: false,
          ),
          
          const SizedBox(height: 12),
          
          _buildTransactionItem(
            icon: Icons.shopping_cart,
            title: 'Paid to Supermarket',
            subtitle: '16 Jul 2025, 04:45 PM',
            amount: '-KES 3,200.00',
            isDebit: true,
          ),
        ],
      ),
    );
  }
  
  // Helper Widgets
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600]) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickPayOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Color(0xFF26D07C),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactItem({
    required String name,
    required String phone,
    required VoidCallback onTap,
  }) {
    final initials = name.split(' ').map((part) => part.isNotEmpty ? part[0] : '').join('');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFF26D07C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials.toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26D07C),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              phone,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isDebit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDebit 
                  ? Colors.red.withOpacity(0.1) 
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDebit ? Colors.red : Colors.green,
              size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDebit ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}