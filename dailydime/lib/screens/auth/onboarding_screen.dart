// lib/screens/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/screens/auth/login_screen.dart';
import 'package:dailydime/screens/auth/register_screen.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isReturningUser = false;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _buttonAnimationController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  // Define the onboarding items with modern financial Lottie animations
  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Track Your Expenses',
      description: 'Monitor your spending habits and get insights into where your money goes with powerful analytics',
      lottieAsset: 'animations/lottie/money_coins.json',
      backgroundColor: const Color(0xFFF0FDF4),
      primaryColor: const Color(0xFF10B981),
      secondaryColor: const Color(0xFF059669),
      iconData: Icons.bar_chart_rounded,
      featureTexts: [
        'Smart expense categorization',
        'Real-time transaction monitoring',
        'Spending pattern analysis'
      ],
    ),
    OnboardingItem(
      title: 'Smart Budgeting',
      description: 'Set personalized budgets with AI-powered recommendations based on your spending habits',
      lottieAsset: 'assets/animations/lottie/budget_planning.json',
      backgroundColor: const Color(0xFFEFF6FF),
      primaryColor: const Color(0xFF1E3A8A),
      secondaryColor: const Color(0xFF3B82F6),
      iconData: Icons.account_balance_wallet_rounded,
      featureTexts: [
        'Customizable budget categories',
        'AI-powered spending recommendations',
        'Budget alert notifications'
      ],
    ),
    OnboardingItem(
      title: 'Achieve Your Goals',
      description: 'Set savings goals and track your progress with visual indicators and milestone celebrations',
      lottieAsset: 'assets/animations/lottie/goals_achievement.json',
      backgroundColor: const Color(0xFFF5F3FF),
      primaryColor: const Color(0xFF7C3AED),
      secondaryColor: const Color(0xFFA855F7),
      iconData: Icons.emoji_events_rounded,
      featureTexts: [
        'Visual progress trackers',
        'Milestone celebrations',
        'Smart saving recommendations'
      ],
    ),
    OnboardingItem(
      title: 'Seamless Payments',
      description: 'Connect with M-Pesa and other payment platforms for automatic transaction tracking',
      lottieAsset: 'assets/animations/lottie/payment_sync.json',
      backgroundColor: const Color(0xFFFEF2F2),
      primaryColor: const Color(0xFFEF4444),
      secondaryColor: const Color(0xFFF97316),
      iconData: Icons.sync_rounded,
      featureTexts: [
        'M-Pesa integration',
        'Automated transaction syncing',
        'Receipt scanning capabilities'
      ],
    ),
  ];
  
  // For returning users - more elaborate welcome back screen
  final ReturningUserContent _returningUserContent = ReturningUserContent(
    mainLottieAsset: 'assets/animations/lottie/welcome_back.json',
    secondaryLottieAssets: [
      'assets/animations/lottie/financial_growth.json',
      'assets/animations/lottie/money_management.json',
      'assets/animations/lottie/savings.json',
    ],
    welcomeText: 'Welcome Back!',
    subtitle: 'Continue your journey to financial freedom',
    description: 'Your financial insights and budgets are ready for you. Sign in to access your DailyDime dashboard.',
    primaryColor: const Color(0xFF0EA5E9),
    secondaryColor: const Color(0xFF0284C7),
    backgroundColor: const Color(0xFFE0F2FE),
    recentUpdates: [
      'New AI-powered insights',
      'Enhanced budget tracking',
      'Improved M-Pesa integration'
    ],
  );
  
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _checkUserStatus();
  }
  
  Future<void> _checkUserStatus() async {
    try {
      final isAuthenticated = await AuthService().isAuthenticated();
      setState(() {
        _isReturningUser = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isReturningUser = false;
        _isLoading = false;
      });
    }
    
    // Start animations after checking user status
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Reset and restart animations on page change
    _slideController.reset();
    _fadeController.reset();
    _scaleController.reset();
    
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }
  
  void _nextPage() {
    if (_isReturningUser) {
      _navigateToLogin();
    } else if (_currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToSignup();
    }
  }
  
  void _navigateToLogin() {
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
  
  void _navigateToSignup() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Handle loading state with a nice animation
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/animations/lottie/loading.json',
            width: 120,
            height: 120,
          ),
        ),
      );
    }
    
    final screenSize = MediaQuery.of(context).size;
    final currentItem = _isReturningUser 
        ? null 
        : _onboardingItems[_currentPage];
    final primaryColor = _isReturningUser 
        ? _returningUserContent.primaryColor 
        : currentItem!.primaryColor;
    final secondaryColor = _isReturningUser 
        ? _returningUserContent.secondaryColor 
        : currentItem!.secondaryColor;
    final backgroundColor = _isReturningUser 
        ? _returningUserContent.backgroundColor 
        : currentItem!.backgroundColor;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top right decorative element
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Bottom left decorative element
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Main content
              Column(
                children: [
                  // Header with app logo and skip button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App logo/name with subtle animation
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.5, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _fadeController,
                            curve: Curves.easeOut,
                          )),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'DailyDime',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    fontFamily: 'DMsans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Skip button (only for new users)
                        if (!_isReturningUser)
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.5, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _fadeController,
                              curve: Curves.easeOut,
                            )),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: TextButton(
                                onPressed: _navigateToSignup,
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, 
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Main content area
                  Expanded(
                    child: _isReturningUser
                        ? _buildReturningUserContent(screenSize)
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _onboardingItems.length,
                            onPageChanged: _onPageChanged,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return _buildOnboardingPage(
                                _onboardingItems[index], 
                                screenSize
                              );
                            },
                          ),
                  ),
                  
                  // Bottom navigation area
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Page indicators (only for new users)
                        if (!_isReturningUser)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _onboardingItems.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentPage == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index
                                        ? primaryColor
                                        : primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Action button
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: GestureDetector(
                              onTapDown: (_) => _buttonAnimationController.forward(),
                              onTapUp: (_) {
                                _buttonAnimationController.reverse();
                                _nextPage();
                              },
                              onTapCancel: () => _buttonAnimationController.reverse(),
                              child: AnimatedBuilder(
                                animation: _buttonAnimationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _buttonScaleAnimation.value,
                                    child: Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryColor,
                                            secondaryColor,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _isReturningUser
                                                ? 'Continue to Login'
                                                : (_currentPage < _onboardingItems.length - 1
                                                    ? 'Next'
                                                    : 'Get Started'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _isReturningUser
                                                ? Icons.login_rounded
                                                : (_currentPage < _onboardingItems.length - 1
                                                    ? Icons.arrow_forward_rounded
                                                    : Icons.check_circle_outline_rounded),
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // Login/Signup option (only for new users on last page)
                        if (!_isReturningUser && _currentPage == _onboardingItems.length - 1)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _navigateToLogin,
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Sign up option (only for returning users)
                        if (_isReturningUser)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Need a new account? ',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _navigateToSignup,
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
  
  Widget _buildOnboardingPage(OnboardingItem item, Size screenSize) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Lottie animation
                  SizedBox(
                    height: screenSize.height * 0.35,
                    child: Lottie.asset(
                      item.lottieAsset,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      frameRate: FrameRate.max,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Feature icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      item.iconData,
                      color: item.primaryColor,
                      size: 28,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Feature bullets
                  if (item.featureTexts != null && item.featureTexts!.isNotEmpty)
                    Column(
                      children: item.featureTexts!.map((feature) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: item.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: item.primaryColor,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildReturningUserContent(Size screenSize) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Main Lottie animation
                  SizedBox(
                    height: screenSize.height * 0.3,
                    child: Lottie.asset(
                      _returningUserContent.mainLottieAsset,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      frameRate: FrameRate.max,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Welcome back text with animation
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        _returningUserContent.primaryColor,
                        _returningUserContent.secondaryColor,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      _returningUserContent.welcomeText,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    _returningUserContent.subtitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    _returningUserContent.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Card with what's new
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _returningUserContent.primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.new_releases_outlined,
                              color: _returningUserContent.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "What's New",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _returningUserContent.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: _returningUserContent.recentUpdates.map((update) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _returningUserContent.secondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      update,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Secondary animations in horizontal cards
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _returningUserContent.secondaryLottieAssets.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _returningUserContent.primaryColor.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Lottie.asset(
                              _returningUserContent.secondaryLottieAssets[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String lottieAsset;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData iconData;
  final List<String>? featureTexts;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.lottieAsset,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.iconData,
    this.featureTexts,
  });
}

class ReturningUserContent {
  final String mainLottieAsset;
  final List<String> secondaryLottieAssets;
  final String welcomeText;
  final String subtitle;
  final String description;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> recentUpdates;

  ReturningUserContent({
    required this.mainLottieAsset,
    required this.secondaryLottieAssets,
    required this.welcomeText,
    required this.subtitle,
    required this.description,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.recentUpdates,
  });
}