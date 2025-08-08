// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailydime/screens/auth/onboarding_screen.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _backgroundAnimController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _shapeAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    
    // Pulse animation for subtle elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Background animation controller
    _backgroundAnimController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );
    
    // Fade animation for most elements
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Scale animation for logo
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.5),
      ),
    );
    
    // Slide animation for text
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    // Continuous background animation
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimController,
        curve: Curves.linear,
      ),
    );
    
    // Shape animation for decorative elements
    _shapeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimations() {
    _mainController.forward();
    _pulseController.repeat(reverse: true);
    _backgroundAnimController.repeat();
    
    // Navigate to next screen after a delay
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _backgroundAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(themeService),
              
              // Decorative shapes
              _buildDecorativeShapes(themeService),
              
              // Content container
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        
                        // Logo & brand section
                        _buildLogoSection(themeService),
                        
                        const SizedBox(height: 30),
                        
                        // Animated text section
                        _buildTextSection(themeService),
                        
                        const Spacer(flex: 3),
                        
                        // Loading indicator
                        _buildLoadingIndicator(themeService),
                        
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedBackground(ThemeService themeService) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeService.isDarkMode
                  ? [
                      const Color(0xFF0F172A),
                      Color.lerp(const Color(0xFF0F172A), themeService.primaryColor.withOpacity(0.12), 
                        0.3 + (0.05 * math.sin(_backgroundAnimation.value * 2 * math.pi)))!,
                      Color.lerp(const Color(0xFF1E293B), themeService.secondaryColor.withOpacity(0.08),
                        0.3 + (0.05 * math.cos(_backgroundAnimation.value * 2 * math.pi)))!,
                    ]
                  : [
                      Colors.white,
                      Color.lerp(Colors.white, themeService.primaryColor.withOpacity(0.06),
                        0.3 + (0.05 * math.sin(_backgroundAnimation.value * 2 * math.pi)))!,
                      Color.lerp(const Color(0xFFF8FAFC), themeService.secondaryColor.withOpacity(0.05),
                        0.3 + (0.05 * math.cos(_backgroundAnimation.value * 2 * math.pi)))!,
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorativeShapes(ThemeService themeService) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shapeAnimation, _pulseController]),
      builder: (context, child) {
        final pulseValue = 0.98 + (0.04 * math.sin(_pulseController.value * math.pi));
        
        return Stack(
          children: [
            // Top right shape
            Positioned(
              top: -60,
              right: -30,
              child: Transform.scale(
                scale: _shapeAnimation.value * pulseValue,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Opacity(
                    opacity: _shapeAnimation.value * 0.85,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeService.primaryColor.withOpacity(0.5),
                            themeService.primaryColor.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom left shape
            Positioned(
              bottom: -70,
              left: -40,
              child: Transform.scale(
                scale: _shapeAnimation.value * pulseValue,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Opacity(
                    opacity: _shapeAnimation.value * 0.7,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            themeService.secondaryColor.withOpacity(0.5),
                            themeService.secondaryColor.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Center-left accent
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -25,
              child: Opacity(
                opacity: _shapeAnimation.value * 0.6,
                child: Container(
                  width: 70,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    color: themeService.accentColor.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            
            // Center-right small accent
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              right: -15,
              child: Opacity(
                opacity: _shapeAnimation.value * 0.5,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeService.primaryColor.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoSection(ThemeService themeService) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoScaleAnimation, _fadeAnimation, _pulseController]),
      builder: (context, child) {
        final pulseValue = 0.98 + (0.04 * math.sin(_pulseController.value * math.pi));
        
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _logoScaleAnimation.value,
            child: Column(
              children: [
                // Logo container
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeService.primaryColor,
                        themeService.secondaryColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: themeService.secondaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: pulseValue,
                      child: Text(
                        '\$',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: const Offset(0, 2),
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
        );
      },
    );
  }

  Widget _buildTextSection(ThemeService themeService) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _textSlideAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _textSlideAnimation.value),
            child: Column(
              children: [
                // App name with Pacifico font
                Text(
                  'DailyDime',
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 44,
                    color: themeService.textColor,
                    shadows: [
                      Shadow(
                        color: themeService.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Tagline in container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: themeService.isDarkMode
                        ? themeService.surfaceColor.withOpacity(0.5)
                        : themeService.primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: themeService.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Your finances, simplified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeService.isDarkMode
                          ? Colors.white
                          : themeService.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(ThemeService themeService) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Modern loading indicator
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeService.primaryColor,
                  ),
                  backgroundColor: themeService.surfaceColor,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Loading text
              Text(
                'Loading your financial future...',
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.subtextColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}