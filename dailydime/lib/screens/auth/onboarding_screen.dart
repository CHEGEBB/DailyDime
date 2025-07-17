// lib/screens/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:dailydime/screens/auth/login_screen.dart';  // Changed from HomeScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Track Your Expenses',
      description: 'Monitor your spending habits and categorize transactions automatically for better financial insights',
      imagePath: 'images/onboarding_1.jpg', // Analytics/chart image
      primaryColor: const Color(0xFF10B981),
      secondaryColor: const Color(0xFF059669),
    ),
    OnboardingItem(
      title: 'Smart Budgeting',
      description: 'Create personalized budgets with AI-powered recommendations based on your spending patterns',
      imagePath: 'images/onboarding_2.jpg', // Budget/money management image
      primaryColor: const Color(0xFF1E3A8A),
      secondaryColor: const Color(0xFF3B82F6),
    ),
    OnboardingItem(
      title: 'Achieve Your Goals',
      description: 'Set savings goals and track your progress with visual indicators and milestone celebrations',
      imagePath: 'images/onboarding_3.jpg', // Goal/target image
      primaryColor: const Color(0xFF7C3AED),
      secondaryColor: const Color(0xFFA855F7),
    ),
    OnboardingItem(
      title: 'Stay Connected',
      description: 'Sync with M-Pesa and other payment platforms for seamless transaction tracking',
      imagePath: 'images/onboarding_4.jpg', // Mobile payment/sync image
      primaryColor: const Color(0xFFEF4444),
      secondaryColor: const Color(0xFFF97316),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to LoginScreen instead of HomeScreen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _onboardingItems[_currentPage];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentItem.primaryColor.withOpacity(0.1),
              currentItem.secondaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo or app name
                    Text(
                      'DailyDime',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentItem.primaryColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    // Skip button
                    TextButton(
                      onPressed: () {
                        // Navigate to LoginScreen instead of HomeScreen
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 500),
                          ),
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: currentItem.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _onboardingItems.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_onboardingItems[index]);
                  },
                ),
              ),

              // Bottom section with indicators and button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingItems.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? currentItem.primaryColor
                                : currentItem.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            currentItem.primaryColor,
                            currentItem.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: currentItem.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _nextPage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage < _onboardingItems.length - 1 
                                      ? 'Next' 
                                      : 'Get Started',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage < _onboardingItems.length - 1 
                                      ? Icons.arrow_forward_rounded 
                                      : Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildOnboardingPage(OnboardingItem item) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern multi-image layout
                  SizedBox(
                    width: 320,
                    height: 280,
                    child: _buildImageStack(item, _currentPage),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageStack(OnboardingItem item, int pageIndex) {
    switch (pageIndex) {
      case 0: // Expense tracking page
        return Stack(
          children: [
            // Main center image
            Positioned(
              top: 20,
              left: 60,
              child: _buildImageCard(
                'images/onboard1.png',
                200,
                160,
                item.primaryColor,
                0.0,
                Icons.analytics_outlined,
              ),
            ),
            // Small floating card top right
            Positioned(
              top: 0,
              right: 20,
              child: _buildImageCard(
                'images/onboard2.png',
                100,
                80,
                item.secondaryColor,
                0.1,
                Icons.credit_card_outlined,
              ),
            ),
            // Small floating card bottom left
            Positioned(
              bottom: 0,
              left: 20,
              child: _buildImageCard(
                'images/onboard3.png',
                120,
                90,
                item.primaryColor,
                -0.05,
                Icons.category_outlined,
              ),
            ),
          ],
        );
      
      case 1: // Budget page
        return Stack(
          children: [
            // Main budget interface
            Positioned(
              top: 10,
              left: 40,
              child: _buildImageCard(
                'images/onboard4.png',
                240,
                180,
                item.primaryColor,
                0.0,
                Icons.account_balance_wallet_outlined,
              ),
            ),
            // Calculator floating
            Positioned(
              top: 40,
              right: 10,
              child: _buildImageCard(
                'images/onboard5',
                80,
                100,
                item.secondaryColor,
                0.1,
                Icons.calculate_outlined,
              ),
            ),
            // Budget progress bottom
            Positioned(
              bottom: 10,
              left: 80,
              child: _buildImageCard(
                'images/onboard9.png',
                160,
                60,
                item.primaryColor.withOpacity(0.8),
                -0.05,
                Icons.trending_up_outlined,
              ),
            ),
          ],
        );
      
      case 2: // Goals page
        return Stack(
          children: [
            // Main goal tracker
            Positioned(
              top: 30,
              left: 50,
              child: _buildImageCard(
                'images/onboard6.png',
                220,
                160,
                item.primaryColor,
                0.0,
                Icons.savings_outlined,
              ),
            ),
            // Achievement badge
            Positioned(
              top: 0,
              right: 30,
              child: _buildImageCard(
                'images/onboard7.png',
                90,
                90,
                item.secondaryColor,
                0.1,
                Icons.emoji_events_outlined,
              ),
            ),
            // Progress circle
            Positioned(
              bottom: 20,
              left: 10,
              child: _buildImageCard(
                'assets/images/onboard8.png',
                100,
                100,
                item.primaryColor.withOpacity(0.8),
                -0.05,
                Icons.donut_small_outlined,
              ),
            ),
          ],
        );
      
      case 3: // Sync page
        return Stack(
          children: [
            // Main phone interface
            Positioned(
              top: 20,
              left: 80,
              child: _buildImageCard(
                'images/onboard10.png',
                160,
                200,
                item.primaryColor,
                0.0,
                Icons.smartphone_outlined,
              ),
            ),
            // M-Pesa logo/card
            Positioned(
              top: 0,
              left: 20,
              child: _buildImageCard(
                'images/onboard11.png',
                100,
                80,
                item.secondaryColor,
                0.1,
                Icons.payment_outlined,
              ),
            ),
            // Sync indicator
            Positioned(
              top: 60,
              right: 20,
              child: _buildImageCard(
                'images/onboard12.png',
                80,
                80,
                item.primaryColor.withOpacity(0.8),
                -0.05,
                Icons.sync_outlined,
              ),
            ),
            // Transaction list
            Positioned(
              bottom: 0,
              left: 60,
              child: _buildImageCard(
                'images/onboard13.png',
                200,
                70,
                item.secondaryColor.withOpacity(0.7),
                0.05,
                Icons.receipt_long_outlined,
              ),
            ),
          ],
        );
      
      default:
        return _buildImageCard(
          'images/onboard14.png',
          280,
          280,
          item.primaryColor,
          0.0,
          Icons.analytics_outlined,
        );
    }
  }

  Widget _buildImageCard(String imagePath, double width, double height, Color color, double rotation, IconData fallbackIcon) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  fallbackIcon,
                  size: width * 0.3,
                  color: color,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;
  final Color primaryColor;
  final Color secondaryColor;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.primaryColor,
    required this.secondaryColor,
  });
}