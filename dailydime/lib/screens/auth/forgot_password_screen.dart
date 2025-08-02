import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/theme_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
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

  void _sendResetLink() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailSent = true;
          });
        }
      });
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
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: themeService.scaffoldColor,
          ),
          
          // Floating design elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          
          Positioned(
            bottom: 150,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeService.secondaryColor.withOpacity(0.1),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Back button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: themeService.textColor,
                        ),
                      ),
                    ),
                    
                    // Animation
                    Center(
                      child: Container(
                        height: size.height * 0.3,
                        width: size.width * 0.8,
                        margin: const EdgeInsets.only(top: 20),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Lottie.asset(
                            _emailSent 
                              ? 'animations/email_sent.json'
                              : 'animations/forgot_password.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    
                    // Page content based on state
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _emailSent 
                          ? _buildSuccessView(themeService)
                          : _buildInputView(themeService),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputView(ThemeService themeService) {
    final isDark = themeService.isDarkMode;
    final primaryColor = themeService.primaryColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main heading
        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeService.textColor,
            fontFamily: 'DMsans',
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Enter your email and we\'ll send you a link to reset your password',
          style: TextStyle(
            fontSize: 14,
            color: themeService.subtextColor,
            fontFamily: 'DMsans',
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Email form
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email field
              Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeService.textColor,
                  fontFamily: 'DMsans',
                ),
              ),
              
              const SizedBox(height: 8),
              
              Container(
                decoration: BoxDecoration(
                  color: isDark ? themeService.surfaceColor : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  style: TextStyle(
                    color: themeService.textColor,
                    fontFamily: 'DMsans',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: TextStyle(
                      color: themeService.subtextColor.withOpacity(0.7),
                      fontFamily: 'DMsans',
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withOpacity(0.6),
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
                            color: isDark ? Colors.black : Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DMsans',
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Back to login
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: TextStyle(
                        color: themeService.subtextColor,
                        fontFamily: 'DMsans',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DMsans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(ThemeService themeService) {
    final isDark = themeService.isDarkMode;
    final primaryColor = themeService.primaryColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main heading
        Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeService.textColor,
            fontFamily: 'DMsans',
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Description
        Text(
          'We\'ve sent a password reset link to:',
          style: TextStyle(
            fontSize: 14,
            color: themeService.subtextColor,
            fontFamily: 'DMsans',
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Email address
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _emailController.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              fontFamily: 'DMsans',
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Further instructions
        Text(
          'Please check your inbox and follow the instructions to reset your password.',
          style: TextStyle(
            fontSize: 14,
            color: themeService.subtextColor,
            fontFamily: 'DMsans',
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Open email app button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Would typically open the email app
              // For demo purposes, go back to login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Open Email App',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'DMsans',
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Back to login text button
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: Text(
            'Back to Login',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMsans',
              fontSize: 16,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Didn't receive email
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the email? ',
              style: TextStyle(
                color: themeService.subtextColor,
                fontFamily: 'DMsans',
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _emailSent = false;
                });
              },
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMsans',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}