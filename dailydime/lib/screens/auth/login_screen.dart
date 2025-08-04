import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/screens/auth/register_screen.dart';
import 'package:dailydime/screens/auth/forgot_password_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/screens/main_navigation.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/theme_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _errorMessage = '';
  
  // Initialize auth service
  final AuthService _authService = AuthService();
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    _slideController.forward();
    _checkBiometrics();
    _checkLoggedInUser();
  }

  Future<void> _checkLoggedInUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      // Error checking user, continue to login screen
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheckBiometrics;
        });
        
        if (_canCheckBiometrics) {
          _getAvailableBiometrics();
        }
      }
    } catch (e) {
      // Handle exception
    }
  }

  Future<void> _getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (mounted) {
        setState(() {
          _availableBiometrics = availableBiometrics;
        });
      }
    } catch (e) {
      // Handle exception
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      // Handle exception
    }
  }

  Future<void> _loginWithSocial(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await _authService.createOAuthSession(provider);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _authService.handleAuthError(e);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = _authService.handleAuthError(e);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final primaryColor = themeService.primaryColor;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [
                      themeService.scaffoldColor,
                      primaryColor.withOpacity(0.05),
                      themeService.scaffoldColor,
                    ]
                  : [
                      primaryColor.withOpacity(0.02),
                      Colors.white,
                      primaryColor.withOpacity(0.08),
                    ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Curved Top Section with Animation
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: CustomPaint(
                  size: Size(size.width, size.height * 0.45),
                  painter: CurvedBackgroundPainter(
                    color: primaryColor.withOpacity(isDark ? 0.15 : 0.1),
                  ),
                ),
              );
            },
          ),
          
          // Floating Elements
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final delay = index * 0.2;
                final progress = (_animationController.value - delay).clamp(0.0, 1.0);
                return Positioned(
                  top: 50 + (index * 80.0) - (progress * 20),
                  left: (index.isEven ? -30 : size.width - 50) + (progress * (index.isEven ? 50 : -50)),
                  child: Opacity(
                    opacity: progress * 0.3,
                    child: Transform.rotate(
                      angle: progress * 0.5,
                      child: Container(
                        width: 40 + (index * 5.0),
                        height: 40 + (index * 5.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Section with Lottie
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Back button
                        Positioned(
                          top: 20,
                          left: 24,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: themeService.textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Lottie Animation - Much Larger
                        Center(
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              height: size.height * 0.35,
                              width: size.width * 0.9,
                              margin: const EdgeInsets.only(top: 40),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Lottie.asset(
                                  'assets/animations/Login.json',
                                  fit: BoxFit.contain,
                                  repeat: true,
                                  animate: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Form Section with Curved Container
                Expanded(
                  flex: 3,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? themeService.scaffoldColor.withOpacity(0.95)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag Handle
                            Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Welcome Text with Animation
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back! 👋',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: themeService.textColor,
                                      fontFamily: 'DMsans',
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to continue your financial journey and manage your expenses effortlessly',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: themeService.subtextColor,
                                      fontFamily: 'DMsans',
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Error message with better styling
                            if (_errorMessage.isNotEmpty)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.1),
                                      Colors.red.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontFamily: 'DMsans',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Login Form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Email Field
                                  _buildEnhancedTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hintText: 'Enter your email address',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Password Field
                                  _buildEnhancedTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    validator: _validatePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                            ? Icons.visibility_outlined 
                                            : Icons.visibility_off_outlined,
                                        color: themeService.subtextColor,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Remember me & Forgot password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Remember me with custom design
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _rememberMe = !_rememberMe;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: _rememberMe 
                                                    ? primaryColor 
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: _rememberMe 
                                                      ? primaryColor 
                                                      : themeService.subtextColor.withOpacity(0.5),
                                                  width: 2,
                                                ),
                                              ),
                                              child: _rememberMe
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Remember me',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: themeService.subtextColor,
                                                fontFamily: 'DMsans',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Forgot password
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ForgotPasswordScreen(),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                            fontFamily: 'DMsans',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Enhanced Login Button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: _isLoading 
                                            ? [
                                                primaryColor.withOpacity(0.6),
                                                primaryColor.withOpacity(0.4),
                                              ]
                                            : [
                                                primaryColor,
                                                primaryColor.withOpacity(0.8),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'DMsans',
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  
                                  // Biometric login if available
                                  if (_canCheckBiometrics && _availableBiometrics.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      child: Center(
                                        child: TextButton.icon(
                                          onPressed: _isLoading ? null : _authenticateWithBiometrics,
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _availableBiometrics.contains(BiometricType.fingerprint)
                                                  ? Icons.fingerprint
                                                  : Icons.face,
                                              color: primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                          label: Text(
                                            'Use ${_availableBiometrics.contains(BiometricType.fingerprint) ? 'Fingerprint' : 'Face ID'}',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontFamily: 'DMsans',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Enhanced Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    'Or continue with',
                                    style: TextStyle(
                                      color: themeService.subtextColor,
                                      fontSize: 14,
                                      fontFamily: 'DMsans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Enhanced Social Login Options
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildEnhancedSocialButton(
                                  icon: 'assets/icons/google.png',
                                  label: 'Google',
                                  color: Colors.red,
                                  fallbackIcon: Icons.g_mobiledata,
                                  onTap: () => _loginWithSocial('google'),
                                ),
                                _buildEnhancedSocialButton(
                                  icon: 'assets/icons/facebook.png',
                                  label: 'Facebook',
                                  color: Colors.blue,
                                  fallbackIcon: Icons.facebook,
                                  onTap: () => _loginWithSocial('facebook'),
                                ),
                                _buildEnhancedSocialButton(
                                  icon: 'assets/icons/apple.png',
                                  label: 'Apple',
                                  color: isDark ? Colors.white : Colors.black,
                                  fallbackIcon: Icons.apple,
                                  onTap: () => _loginWithSocial('apple'),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Enhanced Sign up link
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Don\'t have an account? ',
                                      style: TextStyle(
                                        color: themeService.subtextColor,
                                        fontFamily: 'DMsans',
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Sign up',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'DMsans',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
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
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.textColor,
              fontFamily: 'DMsans',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? themeService.surfaceColor.withOpacity(0.6)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? Colors.grey.shade600.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              color: themeService.textColor,
              fontFamily: 'DMsans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: themeService.subtextColor.withOpacity(0.6),
                fontFamily: 'DMsans',
                fontSize: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  prefixIcon,
                  color: themeService.primaryColor,
                  size: 20,
                ),
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSocialButton({
    required String icon,
    required String label,
    required Color color,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    return Column(
      children: [
        InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? themeService.surfaceColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark 
                    ? Colors.grey.shade600.withOpacity(0.2)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: AssetImage(icon),
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      fallbackIcon,
                      size: 28,
                      color: color,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeService.subtextColor,
            fontFamily: 'DMsans',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Curved Background
class CurvedBackgroundPainter extends CustomPainter {
  final Color color;

  CurvedBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.7);
    
    // Create multiple curves for more dynamic effect
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.9,
      size.width * 0.5, size.height * 0.8,
    );
    
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.85,
    );
    
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
    
    // Add secondary curve with different opacity
    final secondPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;
      
    final secondPath = Path();
    secondPath.lineTo(0, size.height * 0.6);
    secondPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.8,
      size.width * 0.6, size.height * 0.7,
    );
    secondPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.6,
      size.width, size.height * 0.75,
    );
    secondPath.lineTo(size.width, 0);
    secondPath.close();

    canvas.drawPath(secondPath, secondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Placeholder for transparent image
final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);