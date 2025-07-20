import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dailydime/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  
  // Form keys for validation
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  
  // Password visibility
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  
  // OTP controllers
  final List<TextEditingController> _otpControllers = List.generate(
    4, 
    (index) => TextEditingController(),
  );
  
  // Focus nodes for OTP fields
  final List<FocusNode> _otpFocusNodes = List.generate(
    4, 
    (index) => FocusNode(),
  );
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _animationController.dispose();
    
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState!.validate()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState!.validate()) {
        if (!_agreeToTerms) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please agree to the Terms and Privacy Policy'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _verifyAndCreateAccount() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate verification process
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      
      // Navigate to home screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    });
  }

  // Validators
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
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\d{9,10}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5F5F5),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          // Top curved header with image background
          ClipPath(
            clipper: CustomClipPath(),
            child: Container(
              height: size.height * 0.45,
              width: size.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.asset(
                    'assets/images/sign.jpg',
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
                  
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E8B57).withOpacity(0.85),
                          Color(0xFF20B2AA).withOpacity(0.85),
                          Color(0xFF48D1CC).withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // App bar with back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _previousStep,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back, 
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Header section with progress
                  Container(
                    height: size.height * 0.17,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStep == 0 ? 'Create Account' : _currentStep == 1 ? 'Complete Profile' : 'Verification',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DMsans',
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Color.fromRGBO(0, 0, 0, 0.2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Step ${_currentStep + 1} of 3',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'DMsans',
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Enhanced progress bar
                        Stack(
                          children: [
                            // Background track
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            
                            // Progress indicator
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0.0,
                                end: (_currentStep + 1) / 3,
                              ),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Main form container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(theme),
                          _buildStep2(theme),
                          _buildStep3(theme),
                        ],
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

  // Step 1: Create your account (Email & Password)
  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Let\'s Register Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DMsans',
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hello user, you have a greatful journey',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'DMsans',
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 100,
                    child: SvgPicture.asset(
                      'assets/images/illustration.svg',
                      placeholderBuilder: (BuildContext context) => Icon(
                        Icons.person_add_alt_1,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Email field with animation
            _buildAnimatedTextField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            
            const SizedBox(height: 20),
            
            // Password field with animation
            _buildAnimatedTextField(
              label: 'Password',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline,
              hintText: 'Create a password',
              obscureText: _obscurePassword,
              validator: _validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword 
                      ? Icons.visibility_off_outlined 
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Enhanced password requirements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordRequirement(
                    theme,
                    'At least 8 characters',
                    _passwordController.text.length >= 8,
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordRequirement(
                    theme,
                    'Include an alphabet (Aa-Zz)',
                    RegExp(r'[a-zA-Z]').hasMatch(_passwordController.text),
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordRequirement(
                    theme,
                    'Include a number (0-9)',
                    RegExp(r'[0-9]').hasMatch(_passwordController.text),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Continue button with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DMsans',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Or continue with
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or register with',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'DMsans',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            
            // Social login buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google login
                _buildSocialLoginButton(
                  assetName: 'assets/images/google.svg',
                  fallbackIcon: Icons.g_mobiledata,
                  fallbackColor: Colors.red,
                  onTap: () {
                    // Google login logic
                  },
                ),
                
                const SizedBox(width: 20),
                
                // Facebook login
                _buildSocialLoginButton(
                  assetName: 'assets/images/facebook.svg',
                  fallbackIcon: Icons.facebook,
                  fallbackColor: Colors.blue.shade700,
                  onTap: () {
                    // Facebook login logic
                  },
                ),
                
                const SizedBox(width: 20),
                
                // Apple login
                _buildSocialLoginButton(
                  assetName: 'assets/images/apple.svg',
                  fallbackIcon: Icons.apple,
                  fallbackColor: Colors.black,
                  onTap: () {
                    // Apple login logic
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Already have an account
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontFamily: 'DMsans',
                      fontSize: 15,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DMsans',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Add personal information
  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'DMsans',
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please fill in your details',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'DMsans',
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            
            // Name field with animation
            _buildAnimatedTextField(
              label: 'Name',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              hintText: 'Enter your name',
              validator: _validateName,
            ),
            
            const SizedBox(height: 20),
            
            // Business name field with animation
            _buildAnimatedTextField(
              label: 'Business name',
              controller: _businessNameController,
              prefixIcon: Icons.business,
              hintText: 'Enter your business name',
              validator: _validateName,
            ),
            
            const SizedBox(height: 20),
            
            // Phone field with animation
            _buildAnimatedTextField(
              label: 'Phone',
              controller: _phoneController,
              prefixIcon: Icons.phone_android,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            
            const SizedBox(height: 24),
            
            // Enhanced Terms and Conditions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeToTerms,
                      activeColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'DMsans',
                          color: Colors.grey.shade700,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: ' and ',
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Sign up button with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DMsans',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Verification
  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          // Enhanced verification icon with animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Verify your account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'DMsans',
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'We\'ve sent a 4-digit verification code to your email ${_emailController.text}',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'DMsans',
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Enhanced OTP fields with animation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (index) => TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DMsans',
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && index < 3) {
                            _otpFocusNodes[index + 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Verify button with animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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
                        : const Text(
                            'Verify & Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'DMsans',
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Skip verification button
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Text(
              'Skip verification for now',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'DMsans',
                color: Colors.grey.shade600,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Resend code
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Didn\'t receive the code? ',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontFamily: 'DMsans',
                ),
              ),
              TextButton(
                onPressed: () {
                  // Resend code logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification code resent!'),
                    ),
                  );
                },
                child: Text(
                  'Resend',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DMsans',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced animated text field
  Widget _buildAnimatedTextField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    required String hintText,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'DMsans',
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
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
                    keyboardType: keyboardType,
                    validator: validator,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'DMsans',
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                        fontFamily: 'DMsans',
                      ),
                      prefixIcon: Icon(
                        prefixIcon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      suffixIcon: suffixIcon,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

  // Enhanced password requirement
  Widget _buildPasswordRequirement(ThemeData theme, String text, bool isMet) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? theme.colorScheme.primary : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'DMsans',
            color: isMet 
                ? Colors.grey.shade800 
                : Colors.grey.shade600,
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Enhanced social login button
  Widget _buildSocialLoginButton({
    required String assetName,
    required IconData fallbackIcon,
    required Color fallbackColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                assetName,
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    size: fallbackIcon == Icons.g_mobiledata ? 36 : 28,
                    color: fallbackColor,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            assetName.contains('google') ? 'Google' :
            assetName.contains('facebook') ? 'Facebook' : 'Apple',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'DMsans',
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper for curved top container
class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    
    // First curve point
    path.quadraticBezierTo(
      size.width / 4, 
      size.height - 10, 
      size.width / 2, 
      size.height - 30
    );
    
    // Second curve point
    path.quadraticBezierTo(
      size.width - (size.width / 4), 
      size.height - 50, 
      size.width, 
      size.height - 20
    );
    
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}