// lib/screens/mpesa_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
  final TextEditingController _referenceController = TextEditingController();
  
  late TabController _tabController;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;
  bool _showContactSearch = false;
  
  // For balance display
  double _balance = 0;
  bool _loadingBalance = true;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _referenceController.text = 'DailyDime';
    _loadBalance();
    
    // Set up periodic balance refresh
    _refreshTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _loadBalance();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadBalance() async {
    if (mounted) {
      setState(() {
        _loadingBalance = true;
      });
    }
    
    try {
      final result = await _mpesaService.checkAccountBalance();
      if (mounted) {
        setState(() {
          _balance = result['balance'];
          _loadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingBalance = false;
        });
      }
    }
  }
  
  Future<void> _initiateStkPush() async {
    if (_phoneController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter phone number and amount'))
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _isSuccess = false;
    });
    
    try {
      final amount = double.parse(_amountController.text);
      final result = await _mpesaService.initiateSTKPush(
        phoneNumber: _phoneController.text,
        amount: amount,
        accountReference: _referenceController.text,
      );
      
      setState(() {
        _isProcessing = false;
        
        if (result.containsKey('ResponseCode') && result['ResponseCode'] == '0') {
          _isSuccess = true;
          _statusMessage = 'Please check your phone to complete the transaction';
          
          // Start checking status after 10 seconds
          Timer(Duration(seconds: 10), () {
            _checkTransactionStatus(result['CheckoutRequestID']);
          });
        } else {
          _isSuccess = false;
          _statusMessage = result['errorMessage'] ?? 'Transaction failed to initialize';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _checkTransactionStatus(String checkoutRequestId) async {
    try {
      final result = await _mpesaService.checkSTKStatus(
        checkoutRequestID: checkoutRequestId,
      );
      
      if (mounted) {
        setState(() {
          if (result.containsKey('ResultCode') && result['ResultCode'] == '0') {
            _isSuccess = true;
            _statusMessage = 'Transaction completed successfully!';
            _loadBalance(); // Refresh balance
          } else {
            _isSuccess = false;
            _statusMessage = result['ResultDesc'] ?? 'Transaction failed or is still processing';
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking transaction status: $e');
    }
  }
  
  Future<void> _sendMoney() async {
    if (_phoneController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter phone number and amount'))
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _isSuccess = false;
    });
    
    try {
      final amount = double.parse(_amountController.text);
      final remarks = _referenceController.text.isEmpty ? 'Sent via DailyDime' : _referenceController.text;
      
      final result = await _mpesaService.sendMoneyToCustomer(
        phoneNumber: _phoneController.text,
        amount: amount,
        remarks: remarks,
      );
      
      setState(() {
        _isProcessing = false;
        
        if (result['success'] == true) {
          _isSuccess = true;
          _statusMessage = 'KES ${amount.toStringAsFixed(2)} sent successfully';
          _loadBalance(); // Refresh balance
        } else {
          _isSuccess = false;
          _statusMessage = result['message'] ?? 'Failed to send money';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            
            // Tab bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Color(0xFF26D07C),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                tabs: [
                  Tab(text: 'Pay'),
                  Tab(text: 'Send'),
                  Tab(text: 'Services'),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPayTab(),
                  _buildSendTab(),
                  _buildServicesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar with back button
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
              SizedBox(width: 16),
              Text(
                'M-PESA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              _buildBalanceRefreshButton(),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Balance card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26D07C), Color(0xFF1EA66D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF26D07C).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                _loadingBalance
                    ? Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        'KES ${_balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildBalanceRefreshButton() {
    return GestureDetector(
      onTap: _loadBalance,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.refresh, size: 20),
      ),
    );
  }
  
  Widget _buildPayTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
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
          
          SizedBox(height: 20),
          
          // Quick pay options
          _buildQuickPayOptions(),
          
          SizedBox(height: 30),
          
          // Phone number input
          _buildPhoneInput(),
          
          SizedBox(height: 20),
          
          // Amount input
          _buildAmountInput(hint: 'Enter amount to pay'),
          
          SizedBox(height: 20),
          
          // Reference input
          _buildReferenceInput(hint: 'Business name or reference'),
          
          SizedBox(height: 30),
          
          // Pay button
          _buildActionButton(
            text: 'Pay Now',
            isProcessing: _isProcessing,
            onPressed: _initiateStkPush,
          ),
          
          // Status message
          if (_statusMessage != null) _buildStatusMessage(),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSendTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Send Money',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showContactSearch = !_showContactSearch;
                  });
                },
                icon: Icon(
                  _showContactSearch ? Icons.close : Icons.contacts, 
                  size: 16, 
                  color: Color(0xFF26D07C),
                ),
                label: Text(
                  _showContactSearch ? 'Close' : 'Contacts',
                  style: TextStyle(
                    color: Color(0xFF26D07C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Color(0xFF26D07C).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Contacts search
          if (_showContactSearch) _buildContactSearch(),
          
          // Frequent contacts
          if (!_showContactSearch) _buildFrequentContacts(),
          
          SizedBox(height: 20),
          
          // Phone number input
          _buildPhoneInput(),
          
          SizedBox(height: 20),
          
          // Amount input
          _buildAmountInput(hint: 'Enter amount to send'),
          
          SizedBox(height: 20),
          
          // Reference input
          _buildReferenceInput(hint: 'Add a message (optional)'),
          
          SizedBox(height: 30),
          
          // Send button
          _buildActionButton(
            text: 'Send Money',
            isProcessing: _isProcessing,
            onPressed: _sendMoney,
          ),
          
          // Status message
          if (_statusMessage != null) _buildStatusMessage(),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildServicesTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
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
          
          SizedBox(height: 20),
          
          // Services grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildServiceCard(
                icon: Icons.account_balance,
                title: 'Check Balance',
                description: 'View M-PESA balance',
                color: Color(0xFF26D07C),
                onTap: _loadBalance,
              ),
              _buildServiceCard(
                icon: Icons.history,
                title: 'Statements',
                description: 'View your transactions',
                color: Colors.blue,
                onTap: () {},
              ),
              _buildServiceCard(
                icon: Icons.point_of_sale,
                title: 'Lipa na M-PESA',
                description: 'Pay for goods & services',
                color: Colors.orange,
                onTap: () {
                  _tabController.animateTo(0);
                },
              ),
              _buildServiceCard(
                icon: Icons.credit_card,
                title: 'Withdraw Cash',
                description: 'From ATM or agent',
                color: Colors.purple,
                onTap: () {},
              ),
              _buildServiceCard(
                icon: Icons.account_balance_wallet,
                title: 'M-Shwari',
                description: 'Save and get loans',
                color: Colors.teal,
                onTap: () {},
              ),
              _buildServiceCard(
                icon: Icons.receipt_long,
                title: 'Pay Bills',
                description: 'Utilities & subscriptions',
                color: Colors.red,
                onTap: () {},
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Recent transactions
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 15),
          
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _mpesaService.getRecentTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26D07C)),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No recent transactions',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.map((transaction) {
                  return _buildTransactionItem(
                    type: transaction['type'],
                    amount: transaction['amount'],
                    description: transaction['description'],
                    date: transaction['timestamp'],
                    recipient: transaction['recipient'],
                  );
                }).toList(),
              );
            },
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.phone, color: Color(0xFF26D07C)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAmountInput({required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.payments, color: Color(0xFF26D07C)),
              prefixText: 'KES ',
              prefixStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildReferenceInput({required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reference',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.description, color: Color(0xFF26D07C)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required String text,
    required bool isProcessing,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF26D07C),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isProcessing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
  
  Widget _buildStatusMessage() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : Icons.error,
            color: _isSuccess ? Colors.green : Colors.red,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickPayOptions() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Pay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickPayItem(
                icon: Icons.shopping_bag,
                label: 'Buy Goods',
                onTap: () {},
              ),
              _buildQuickPayItem(
                icon: Icons.receipt_long,
                label: 'Pay Bill',
                onTap: () {},
              ),
              _buildQuickPayItem(
                icon: Icons.lightbulb_outline,
                label: 'KPLC',
                onTap: () {},
              ),
              _buildQuickPayItem(
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
  
  Widget _buildQuickPayItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFF26D07C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Color(0xFF26D07C),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactSearch() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search input
          TextField(
            decoration: InputDecoration(
              hintText: 'Search contacts',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          
          SizedBox(height: 15),
          
          // Contact list
          ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildContactItem('John Doe', '0712345678'),
              _buildContactItem('Jane Smith', '0723456789'),
              _buildContactItem('David Kimani', '0734567890'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactItem(String name, String phone) {
    return InkWell(
      onTap: () {
        setState(() {
          _phoneController.text = phone;
          _showContactSearch = false;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF26D07C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFF26D07C),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFrequentContacts() {
    final contacts = [
      {'name': 'John', 'phone': '0712345678'},
      {'name': 'Jane', 'phone': '0723456789'},
      {'name': 'David', 'phone': '0734567890'},
      {'name': 'Mary', 'phone': '0745678901'},
    ];
    
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _phoneController.text = contact['phone']!;
              });
            },
            child: Container(
              width: 75,
              margin: EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF26D07C).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        contact['name']!.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFF26D07C),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    contact['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    contact['phone']!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 3),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionItem({
    required String type,
    required double amount,
    required String description,
    required String date,
    required String recipient,
  }) {
    final bool isOutgoing = type == MpesaHandlingService.SEND || type == MpesaHandlingService.PAY;
    final DateTime transactionDate = DateTime.parse(date);
    final String formattedDate = '${transactionDate.day}/${transactionDate.month}/${transactionDate.year} ${transactionDate.hour}:${transactionDate.minute.toString().padLeft(2, '0')}';
    
    IconData icon;
    if (type == MpesaHandlingService.SEND) {
      icon = Icons.arrow_upward;
    } else if (type == MpesaHandlingService.PAY) {
      icon = Icons.shopping_cart;
    } else {
      icon = Icons.arrow_downward;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOutgoing 
                  ? Colors.red.withOpacity(0.1) 
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isOutgoing ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  isOutgoing ? 'To: $recipient' : 'From: $recipient',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isOutgoing ? '-' : '+'} KES ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOutgoing ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}