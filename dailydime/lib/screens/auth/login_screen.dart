import 'package:dailydime/screens/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dailydime/screens/auth/register_screen.dart';
import 'package:dailydime/screens/auth/forgot_password_screen.dart';
import 'package:dailydime/screens/home_screen.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } on PlatformException {
      canCheckBiometrics = false;
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });

    if (_canCheckBiometrics) {
      _getAvailableBiometrics();
    }
  }

  Future<void> _getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      availableBiometrics = <BiometricType>[];
    }

    if (!mounted) return;

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      authenticated = false;
    }

    if (!mounted) return;

    if (authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  Future<void> _loginWithFacebook() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  Future<void> _loginWithApple() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Main background image - pulled up so it's only visible in the green header part
          Positioned(
            top: -50, // Pull image up
            left: 0,
            right: 0,
            height: size.height * 0.45, // Adjust height to cover only green part
            child: Image.asset(
              'assets/images/login.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2E8B57),
                        Color(0xFF20B2AA),
                        Color(0xFF48D1CC),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Green overlay with gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.40, // Only cover the top part
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E8B57).withOpacity(0.8),
                    Color(0xFF20B2AA).withOpacity(0.8),
                    Color(0xFF48D1CC).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Top section with logo and title
                  Container(
                    height: size.height * 0.35, // Increased header height
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        
                        // Logo
                        SlideTransition(
                          position: _slideAnimation,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 140,
                                height: 140,
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 90,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // App name
                        SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            'DailyDime',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins', // Changed to Poppins
                              color: Colors.white,
                              letterSpacing: -1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            'Smart budgeting with AI-powered insights\nfor your M-Pesa and financial goals',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins', // Changed to Poppins
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom white section with login form
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95), // Slightly lighter form background
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative SVG elements in the form background
                            Positioned(
                              top: 20,
                              right: 20,
                              child: _buildCircleSvg(16, Colors.green.withOpacity(0.1)),
                            ),
                            Positioned(
                              top: 100,
                              left: 30,
                              child: _buildCircleSvg(8, Colors.green.withOpacity(0.1)),
                            ),
                            Positioned(
                              bottom: 80,
                              right: 40,
                              child: _buildCircleSvg(12, Colors.green.withOpacity(0.1)),
                            ),
                            Positioned(
                              bottom: 140,
                              left: 20,
                              child: _buildCircleSvg(20, Colors.green.withOpacity(0.1)),
                            ),
                          
                            // Main form content
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    
                                    // Login header
                                    Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Welcome Back',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins', // Changed to Poppins
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Sign in to continue your financial journey',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Poppins', // Changed to Poppins
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Email field
                                    _buildModernTextField(
                                      controller: _emailController,
                                      hintText: 'Email address',
                                      prefixIcon: Icons.email_outlined,
                                      validator: _validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Password field
                                    _buildModernTextField(
                                      controller: _passwordController,
                                      hintText: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      validator: _validatePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword 
                                              ? Icons.visibility_off_outlined 
                                              : Icons.visibility_outlined,
                                          color: Colors.grey.shade600,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Remember me and forgot password
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                              activeColor: const Color(0xFF2E8B57),
                                            ),
                                            Text(
                                              'Remember me',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins', // Changed to Poppins
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context, 
                                              MaterialPageRoute(
                                                builder: (context) => const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins', // Changed to Poppins
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2E8B57),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Login button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2E8B57),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.0,
                                                ),
                                              )
                                            : Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Poppins', // Changed to Poppins
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Biometric login (if available)
                                    if (_canCheckBiometrics && _availableBiometrics.isNotEmpty)
                                      Center(
                                        child: Column(
                                          children: [
                                            TextButton.icon(
                                              onPressed: _authenticateWithBiometrics,
                                              icon: Icon(
                                                _availableBiometrics.contains(BiometricType.fingerprint)
                                                    ? Icons.fingerprint
                                                    : Icons.face,
                                                color: const Color(0xFF2E8B57),
                                              ),
                                              label: Text(
                                                'Use ${_availableBiometrics.contains(BiometricType.fingerprint) ? 'Fingerprint' : 'Face ID'}',
                                                style: TextStyle(
                                                  color: const Color(0xFF2E8B57),
                                                  fontFamily: 'Poppins', // Changed to Poppins
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      ),
                                    
                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'or continue with',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                              fontFamily: 'Poppins', // Changed to Poppins
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Social login buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildSocialButton(
                                          onPressed: _loginWithGoogle,
                                          icon: Icons.email,
                                          label: 'Google',
                                          color: const Color(0xFF4285F4),
                                        ),
                                        _buildSocialButton(
                                          onPressed: _loginWithFacebook,
                                          icon: Icons.facebook,
                                          label: 'Facebook',
                                          color: const Color(0xFF1877F2),
                                        ),
                                        _buildSocialButton(
                                          onPressed: _loginWithApple,
                                          icon: Icons.apple,
                                          label: 'Apple',
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Don't have account
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Don\'t have an account?',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 15,
                                            fontFamily: 'Poppins', // Changed to Poppins
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const RegisterScreen(),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Sign up',
                                            style: TextStyle(
                                              color: const Color(0xFF2E8B57),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              fontFamily: 'Poppins', // Changed to Poppins
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create circle SVG decorations
  Widget _buildCircleSvg(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'Poppins', // Changed to Poppins
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
            fontFamily: 'Poppins', // Changed to Poppins
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.grey.shade600,
            size: 22,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onPressed,
          icon: Icon(icon, color: color, size: 20),
          label: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontFamily: 'Poppins', // Changed to Poppins
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}