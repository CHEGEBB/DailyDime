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
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _logoScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startSequence() async {
    _pulseController.repeat(reverse: true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _fadeController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation, 
                  curve: Curves.easeOut
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildStaticBackground(ThemeService themeService) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: themeService.isDarkMode ? [
            // Dark mode - sophisticated dark gradient
            const Color(0xFF0F172A), // Deep navy
            Color.lerp(const Color(0xFF0F172A), themeService.primaryColor.withOpacity(0.08), 0.3)!,
            Color.lerp(const Color(0xFF1E293B), themeService.secondaryColor.withOpacity(0.05), 0.4)!,
            const Color(0xFF1E293B), // Slate
          ] : [
            // Light mode - clean premium gradient
            Colors.white,
            Color.lerp(Colors.white, themeService.primaryColor.withOpacity(0.04), 0.5)!,
            Color.lerp(const Color(0xFFF8FAFC), themeService.secondaryColor.withOpacity(0.03), 0.6)!,
            const Color(0xFFF1F5F9), // Very light slate
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildSubtleAccents(ThemeService themeService) {
    return Stack(
      children: [
        // Top accent
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  themeService.primaryColor.withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Bottom accent
        Positioned(
          bottom: -80,
          left: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  themeService.secondaryColor.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumLogo(ThemeService themeService) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _pulseController]),
      builder: (context, child) {
        final fadeValue = _fadeAnimation.value.clamp(0.0, 1.0);
        final scaleValue = _scaleAnimation.value.clamp(0.5, 1.2);
        final pulseValue = _logoScale.value.clamp(0.9, 1.1);
        
        return Transform.scale(
          scale: scaleValue * pulseValue,
          child: Opacity(
            opacity: fadeValue,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer subtle glow
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themeService.primaryColor.withOpacity(0.1),
                        themeService.secondaryColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                
                // Main logo container
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeService.surfaceColor,
                        Color.lerp(themeService.surfaceColor, themeService.primaryColor.withOpacity(0.08), 0.4)!,
                      ],
                    ),
                    border: Border.all(
                      width: 2.5,
                      color: themeService.primaryColor.withOpacity(0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.15),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(themeService.isDarkMode ? 0.3 : 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeService.primaryColor,
                          themeService.secondaryColor,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 38,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Subtle inner highlight
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.4),
                      colors: [
                        Colors.white.withOpacity(themeService.isDarkMode ? 0.1 : 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
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

  Widget _buildElegantBrandText(ThemeService themeService) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final textFadeValue = _textFade.value.clamp(0.0, 1.0);
        
        return Opacity(
          opacity: textFadeValue,
          child: Column(
            children: [
              // App name
              Text(
                'DailyDime',
                style: TextStyle(
                  fontSize: 46,
                  color: themeService.textColor,
                  fontFamily: 'Pacifico',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: themeService.primaryColor.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Elegant tagline
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: themeService.surfaceColor.withOpacity(0.7),
                  border: Border.all(
                    color: themeService.primaryColor.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(themeService.isDarkMode ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'smart money, daily wins',
                  style: TextStyle(
                    fontSize: 13,
                    color: themeService.subtextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMinimalLoader(ThemeService themeService) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final fadeValue = _fadeAnimation.value.clamp(0.0, 1.0);
        
        return Opacity(
          opacity: fadeValue * 0.7,
          child: Column(
            children: [
              // Simple elegant progress indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeService.primaryColor.withOpacity(0.6),
                  ),
                  backgroundColor: themeService.primaryColor.withOpacity(0.1),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.subtextColor.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: themeService.isDarkMode 
                ? Brightness.light 
                : Brightness.dark,
            systemNavigationBarColor: themeService.isDarkMode 
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            systemNavigationBarIconBrightness: themeService.isDarkMode 
                ? Brightness.light 
                : Brightness.dark,
          ),
        );

        return Scaffold(
          body: Stack(
            children: [
              // Static elegant background
              _buildStaticBackground(themeService),
              
              // Subtle accent elements
              _buildSubtleAccents(themeService),
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium logo (no rotation)
                    _buildPremiumLogo(themeService),
                    
                    const SizedBox(height: 65),
                    
                    // Elegant brand text
                    _buildElegantBrandText(themeService),
                    
                    const SizedBox(height: 85),
                    
                    // Minimal loader
                    _buildMinimalLoader(themeService),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}