import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dailydime/services/mpesa_handling_service.dart';

class MpesaScreen extends StatefulWidget {
  const MpesaScreen({Key? key}) : super(key: key);

  @override
  State<MpesaScreen> createState() => _MpesaScreenState();
}

class _MpesaScreenState extends State<MpesaScreen> with SingleTickerProviderStateMixin {
  final MpesaHandlingService _mpesaService = MpesaHandlingService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  
  // Payment tracking
  String? _currentCheckoutId;
  PaymentStatus _paymentStatus = PaymentStatus.unknown;
  Timer? _statusCheckTimer;
  
  // Animation controller for payment process
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Focus node for form fields
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  
  // Form validation
  final _formKey = GlobalKey<FormState>();
  String? _amountError;
  String? _phoneError;
  
  // Quick amount options
  final List<int> _quickAmounts = [50, 100, 200, 500, 1000];
  
  // Banner images for carousel
  final List<String> _bannerImages = [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
    'assets/images/banner3.png',
    'assets/images/banner4.png',
    'assets/images/banner5.png',
  ];
  
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start banner auto-scroll
    _startBannerAutoScroll();
  }
  
  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentBannerIndex = (_currentBannerIndex + 1) % _bannerImages.length;
      });
    });
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _amountFocusNode.dispose();
    _phoneFocusNode.dispose();
    _animationController.dispose();
    _statusCheckTimer?.cancel();
    _bannerTimer?.cancel();
    _mpesaService.dispose();
    super.dispose();
  }
  
  /// Initiates a payment with STK Push
  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Clear previous errors
    setState(() {
      _amountError = null;
      _phoneError = null;
    });
    
    // Start payment process
    setState(() {
      _isProcessingPayment = true;
      _paymentStatus = PaymentStatus.pending;
    });
    
    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      // Start animation
      _animationController.forward();
      
      final paymentRequest = PaymentRequest(
        phone: _phoneController.text,
        amount: _amountController.text,
      );
      
      final response = await _mpesaService.initiateSTKPush(paymentRequest);
      
      if (!response.success) {
        // Handle error
        setState(() {
          _isProcessingPayment = false;
          if (response.errorMessage?.contains('phone') ?? false) {
            _phoneError = response.errorMessage;
          } else if (response.errorMessage?.contains('amount') ?? false) {
            _amountError = response.errorMessage;
          }
        });
        
        _showErrorSnackbar(response.errorMessage ?? 'Payment initiation failed');
        _animationController.reverse();
        return;
      }
      
      // Store checkout ID for status tracking
      _currentCheckoutId = response.checkoutRequestID;
      
      // Start checking payment status
      _startStatusChecking();
      
      // Show customer message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.customerMessage ?? 'Check your phone to complete the payment'),
          backgroundColor: const Color(0xFF00A884),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      
      _showErrorSnackbar('Payment failed: ${e.toString()}');
      _animationController.reverse();
    }
  }
  
  /// Starts periodic checking of payment status
  void _startStatusChecking() {
    // Cancel any existing timer
    _statusCheckTimer?.cancel();
    
    // Check status every 3 seconds
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _checkPaymentStatus(),
    );
  }
  
  /// Checks the current payment status
  Future<void> _checkPaymentStatus() async {
    if (_currentCheckoutId == null) {
      _statusCheckTimer?.cancel();
      return;
    }
    
    try {
      final statusResponse = await _mpesaService.queryPaymentStatus(_currentCheckoutId!);
      
      setState(() {
        _paymentStatus = statusResponse.status;
      });
      
      // If payment is complete or failed, stop checking
      if (_paymentStatus == PaymentStatus.completed || 
          _paymentStatus == PaymentStatus.failed ||
          _paymentStatus == PaymentStatus.cancelled) {
        _statusCheckTimer?.cancel();
        
        // Finish the payment process
        _finishPaymentProcess();
      }
    } catch (e) {
      debugPrint('Error checking payment status: ${e.toString()}');
    }
  }
  
  /// Finishes the payment process and updates UI
  void _finishPaymentProcess() async {
    setState(() {
      _isProcessingPayment = false;
    });
    
    // Show appropriate message based on status
    if (_paymentStatus == PaymentStatus.completed) {
      // Reverse animation
      _animationController.reverse();
      
      // Show success message
      _showSuccessDialog();
    } else if (_paymentStatus == PaymentStatus.failed || _paymentStatus == PaymentStatus.cancelled) {
      // Reverse animation
      _animationController.reverse();
      
      // Show error message
      _showErrorSnackbar(_paymentStatus == PaymentStatus.cancelled 
          ? 'Payment was cancelled' 
          : 'Payment failed. Please try again.');
    }
    
    // Reset checkout ID
    _currentCheckoutId = null;
  }
  
  /// Shows a success dialog
  void _showSuccessDialog() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00D13A), size: 28),
            const SizedBox(width: 8),
            const Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KES ${amount.toStringAsFixed(2)} has been sent successfully.'),
            const SizedBox(height: 16),
            const Text('Your transaction has been processed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset form
              _amountController.clear();
              _phoneController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D13A),
            ),
            child: const Text('New Payment'),
          ),
        ],
      ),
    );
  }
  
  /// Shows an error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildMainContent(),
    );
  }
  
  Widget _buildMainContent() {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00A884),
                Color(0xFF00D13A),
                Colors.white,
              ],
              stops: [0.0, 0.3, 0.6],
            ),
          ),
        ),
        
        // Main content
        SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading 
                    ? _buildLoadingState()
                    : _buildBodyContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        image: DecorationImage(
          image: const AssetImage('assets/images/pattern.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.1),
            BlendMode.dstATop,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Navigate back
                  Navigator.of(context).pop();
                },
              ),
              const Text(
                'M-Pesa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  _showInfoDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('M-Pesa Integration'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This is a DailyDime M-Pesa integration using the Safaricom Daraja API.'),
            SizedBox(height: 12),
            Text('Features:'),
            SizedBox(height: 8),
            Text('• STK Push for mobile payments'),
            Text('• Real-time transaction tracking'),
            Text('• Smart budget awareness'),
            SizedBox(height: 12),
            Text('Currently running in sandbox mode with test credentials.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF00D13A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading M-Pesa services...',
            style: TextStyle(
              color: Color(0xFF00A884),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBodyContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildPromoBanner(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildPaymentForm(),
              const SizedBox(height: 20),
              if (_isProcessingPayment) _buildPaymentStatus(),
              const SizedBox(height: 30),
              _buildEmptyTransactionState(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromoBanner() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: _bannerImages.length,
        controller: PageController(initialPage: _currentBannerIndex),
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(_bannerImages[index]),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                
                // Banner content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _getBannerTitle(index),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getBannerDescription(index),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _getBannerTitle(int index) {
    switch (index) {
      case 0:
        return 'Send Money Instantly';
      case 1:
        return 'Budget-Aware Payments';
      case 2:
        return 'Track Your Spending';
      case 3:
        return 'Secure Transactions';
      case 4:
        return 'Save While You Spend';
      default:
        return 'DailyDime M-Pesa';
    }
  }
  
  String _getBannerDescription(int index) {
    switch (index) {
      case 0:
        return 'Quick and easy M-Pesa transfers with DailyDime';
      case 1:
        return 'Smart alerts when payments affect your budget';
      case 2:
        return 'Real-time transaction monitoring and history';
      case 3:
        return 'Industry-standard security for all payments';
      case 4:
        return 'Automatic savings recommendations after each transaction';
      default:
        return 'The smart way to manage your finances';
    }
  }
  
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionItem(
                icon: Icons.send,
                title: 'Send Money',
                onTap: () {
                  // Focus on the phone field
                  _phoneFocusNode.requestFocus();
                },
              ),
              _buildQuickActionItem(
                icon: Icons.payment,
                title: 'Pay Bill',
                onTap: () => _showFeatureComingSoon('Pay Bill'),
              ),
              _buildQuickActionItem(
                icon: Icons.phone_android,
                title: 'Buy Airtime',
                onTap: () => _showFeatureComingSoon('Buy Airtime'),
              ),
              _buildQuickActionItem(
                icon: Icons.account_balance_wallet,
                title: 'Request',
                onTap: () => _showFeatureComingSoon('Request Money'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 75,
        padding: const EdgeInsets.all(12),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00D13A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00D13A),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: const Color(0xFF00A884),
      ),
    );
  }
  
  Widget _buildPaymentForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send Money via M-Pesa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '254XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _phoneError,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  final formattedNumber = _mpesaService.formatPhoneNumber(value);
                  if (formattedNumber == null) {
                    return 'Invalid phone format. Use 254XXXXXXXXX';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_phoneError != null) {
                    setState(() {
                      _phoneError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                decoration: InputDecoration(
                  labelText: 'Amount (KES)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _amountError,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Invalid amount';
                  }
                  if (!_mpesaService.validatePaymentAmount(amount)) {
                    return 'Amount must be between KES 1 and KES 150,000';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_amountError != null) {
                    setState(() {
                      _amountError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Amounts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickAmounts
                      .map((amount) => _buildQuickAmountButton(amount))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessingPayment ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D13A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessingPayment
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Processing...'),
                          ],
                        )
                      : const Text('Send Money'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickAmountButton(int amount) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _amountController.text = amount.toString();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00D13A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00D13A).withOpacity(0.3),
          ),
        ),
        child: Text(
          'KES $amount',
          style: const TextStyle(
            color: Color(0xFF00A884),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPaymentStatus() {
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    switch (_paymentStatus) {
      case PaymentStatus.pending:
        statusText = 'Payment Pending';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case PaymentStatus.completed:
        statusText = 'Payment Completed';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
        statusText = 'Payment Failed';
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case PaymentStatus.cancelled:
        statusText = 'Payment Cancelled';
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = 'Checking Payment Status';
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _paymentStatus == PaymentStatus.pending ? null : 1.0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 16),
            if (_paymentStatus == PaymentStatus.pending)
              const Text(
                'Please check your phone and enter your M-Pesa PIN when prompted.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            if (_paymentStatus == PaymentStatus.completed)
              Text(
                'Payment of KES ${_amountController.text} completed successfully.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            if (_paymentStatus == PaymentStatus.failed)
              const Text(
                'Payment could not be processed. Please try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            if (_paymentStatus == PaymentStatus.cancelled)
              const Text(
                'Payment was cancelled by the user or timed out.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyTransactionState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Transaction History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Transactions Yet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your M-Pesa transaction history will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // In a future implementation, this would integrate with the
                      // SMS fetching functionality
                      _showFeatureComingSoon('Transaction sync');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Transactions'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}