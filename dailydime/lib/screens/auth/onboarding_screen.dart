// lib/screens/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/screens/auth/login_screen.dart';
import 'package:dailydime/screens/auth/register_screen.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  
  // Define the onboarding items with their specific color schemes
  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Track Your Expenses',
      description: 'Monitor your spending habits and get insights into where your money goes with powerful analytics',
      lottieAsset: 'assets/animations/money_coins.json',
      iconData: Icons.bar_chart_rounded,
      primaryColor: const Color(0xFF3B82F6), // Blue
      secondaryColor: const Color(0xFF1D4ED8), // Blue variant
      featureTexts: [
        'Smart expense categorization',
        'Real-time transaction monitoring',
        'Spending pattern analysis'
      ],
    ),
    OnboardingItem(
      title: 'Smart Budgeting',
      description: 'Set personalized budgets with AI-powered recommendations based on your spending habits',
      lottieAsset: 'assets/animations/budgeting.json',
      iconData: Icons.account_balance_wallet_rounded,
      primaryColor: const Color(0xFF8B5CF6), // Purple
      secondaryColor: const Color(0xFF7C3AED), // Purple variant
      featureTexts: [
        'Customizable budget categories',
        'AI-powered spending recommendations',
        'Budget alert notifications'
      ],
    ),
    OnboardingItem(
      title: 'Achieve Your Goals',
      description: 'Set savings goals and track your progress with visual indicators and milestone celebrations',
      lottieAsset: 'assets/animations/goals.json',
      iconData: Icons.emoji_events_rounded,
      primaryColor: const Color(0xFFF59E0B), // Amber/Gold
      secondaryColor: const Color(0xFFD97706), // Amber variant
      featureTexts: [
        'Visual progress trackers',
        'Milestone celebrations',
        'Smart saving recommendations'
      ],
    ),
    OnboardingItem(
      title: 'Seamless Payments',
      description: 'Connect with M-Pesa and other payment platforms for automatic transaction tracking',
      lottieAsset: 'assets/animations/payment.json',
      iconData: Icons.sync_rounded,
      primaryColor: const Color(0xFFEF4444), // Red/Orange
      secondaryColor: const Color(0xFFDC2626), // Red variant
      featureTexts: [
        'M-Pesa integration',
        'Automated transaction syncing',
        'Receipt scanning capabilities'
      ],
    ),
  ];
  
  // For returning users - teal/emerald colors only
  final ReturningUserContent _returningUserContent = ReturningUserContent(
    mainLottieAsset: 'assets/animations/Welcome.json',
    welcomeText: 'Welcome Back!',
    subtitle: 'Continue your journey to financial freedom',
    description: 'Your financial insights and budgets are ready for you. Sign in to access your DailyDime dashboard.',
    recentUpdates: [
      'New AI-powered insights',
      'Enhanced budget tracking',
      'Improved M-Pesa integration'
    ],
  );
  
  @override
  void initState() {
    super.initState();
    
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
      // Always navigate to login instead of register
      _navigateToLogin();
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
  
  Color _getBackgroundColor(int index, ThemeService themeService) {
    if (_isReturningUser) {
      return themeService.isDarkMode 
          ? const Color(0xFF0D1B2A) // Dark teal background
          : const Color(0xFFE6FFFA); // Light teal background
    }
    
    if (themeService.isDarkMode) {
      // Use consistent dark theme background for all pages
      return const Color(0xFF0D1B2A); // Same dark background as returning user
    } else {
      final backgrounds = [
        const Color(0xFFDBEAFE), // Light blue
        const Color(0xFFEDE9FE), // Light purple
        const Color(0xFFFEF3C7), // Light amber
        const Color(0xFFFEE2E2), // Light red
      ];
      return backgrounds[index % backgrounds.length];
    }
  }
  
  // Helper method to get colors based on theme mode
  Color _getPrimaryColor(OnboardingItem item, ThemeService themeService) {
    if (themeService.isDarkMode) {
      // Use consistent theme colors in dark mode
      return themeService.primaryColor; // Teal/Emerald
    } else {
      // Use item-specific colors in light mode
      return item.primaryColor;
    }
  }
  
  Color _getSecondaryColor(OnboardingItem item, ThemeService themeService) {
    if (themeService.isDarkMode) {
      // Use consistent theme colors in dark mode
      return themeService.secondaryColor;
    } else {
      // Use item-specific colors in light mode
      return item.secondaryColor;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Update system UI based on theme
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: themeService.isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );
        
        // Handle loading state with a nice animation
        if (_isLoading) {
          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            body: Center(
              child: Lottie.asset(
                'assets/animations/loading2.json',
                width: 120,
                height: 120,
              ),
            ),
          );
        }
        
        final screenSize = MediaQuery.of(context).size;
        
        // Get colors for current page/state
        Color primaryColor;
        Color secondaryColor;
        Color backgroundColor;
        
        if (_isReturningUser) {
          primaryColor = themeService.primaryColor; // Teal/Emerald
          secondaryColor = themeService.secondaryColor;
          backgroundColor = _getBackgroundColor(0, themeService);
        } else {
          final currentItem = _onboardingItems[_currentPage];
          primaryColor = _getPrimaryColor(currentItem, themeService);
          secondaryColor = _getSecondaryColor(currentItem, themeService);
          backgroundColor = _getBackgroundColor(_currentPage, themeService);
        }
        
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
                  
                  // Bottom left decorative element (only for new users)
                  if (!_isReturningUser)
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
                                    onPressed: _navigateToLogin,
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
                                        fontFamily: 'DMsans',
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
                            ? _buildReturningUserContent(screenSize, themeService, primaryColor, secondaryColor)
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: _onboardingItems.length,
                                onPageChanged: _onPageChanged,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return _buildOnboardingPage(
                                    _onboardingItems[index], 
                                    screenSize,
                                    themeService,
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
                                                  fontFamily: 'DMsans',
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
                            
                            // Login/Signup option (modified for new users on last page)
                            if (!_isReturningUser && _currentPage == _onboardingItems.length - 1)
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          color: themeService.subtextColor,
                                          fontSize: 14,
                                          fontFamily: 'DMsans',
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
                                            fontFamily: 'DMsans',
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
                                      Text(
                                        'Need a new account? ',
                                        style: TextStyle(
                                          color: themeService.subtextColor,
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
                                            fontFamily: 'DMsans',
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
      },
    );
  }
  
  Widget _buildOnboardingPage(
    OnboardingItem item, 
    Size screenSize, 
    ThemeService themeService,
  ) {
    // Get theme-appropriate colors
    final primaryColor = _getPrimaryColor(item, themeService);
    final secondaryColor = _getSecondaryColor(item, themeService);
    
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
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      item.iconData,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DMsans',
                      color: themeService.textColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: themeService.subtextColor,
                      fontFamily: 'DMsans',
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
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: primaryColor,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'DMsans',
                                    color: themeService.subtextColor,
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
  
  Widget _buildReturningUserContent(Size screenSize, ThemeService themeService, Color primaryColor, Color secondaryColor) {
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
                    height: screenSize.height * 0.35,
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
                        primaryColor,
                        secondaryColor,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      _returningUserContent.welcomeText,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DMsans',
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DMsans',
                      color: themeService.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    _returningUserContent.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: themeService.subtextColor,
                      fontFamily: 'DMsans',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Card with what's new - removed white background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.new_releases_outlined,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "What's New",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DMsans',
                                color: primaryColor,
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
                                      color: secondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      update,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'DMsans',
                                        color: themeService.subtextColor,
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
                  
                  const SizedBox(height: 40),
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
  final IconData iconData;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String>? featureTexts;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.lottieAsset,
    required this.iconData,
    required this.primaryColor,
    required this.secondaryColor,
    this.featureTexts,
  });
}

class ReturningUserContent {
  final String mainLottieAsset;
  final String welcomeText;
  final String subtitle;
  final String description;
  final List<String> recentUpdates;

  ReturningUserContent({
    required this.mainLottieAsset,
    required this.welcomeText,
    required this.subtitle,
    required this.description,
    required this.recentUpdates,
  });
}