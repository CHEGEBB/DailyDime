import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/screens/main_navigation.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isVerifying = false;
  String? _userId;
  String? _userEmail;
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Initialize auth service
  final AuthService _authService = AuthService();
  
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
    6, 
    (index) => TextEditingController(),
  );
  
  // Focus nodes for OTP fields
  final List<FocusNode> _otpFocusNodes = List.generate(
    6, 
    (index) => FocusNode(),
  );
  
  // Animation files for each step
  final List<String> _animationFiles = [
    'animations/register_step1.json',
    'animations/register_step2.json',
    'animations/verification.json',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _animationController.forward();
    _slideController.forward();
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
    _slideController.dispose();
    
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
        _slideController.reset();
        _slideController.forward();
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState!.validate()) {
        if (!_agreeToTerms) {
          _showSnackBar('Please agree to the Terms and Privacy Policy', Colors.red);
          return;
        }
        _registerUser();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _slideController.reset();
      _slideController.forward();
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Create the user account
      final user = await _authService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: "${_nameController.text.trim()} ${_lastNameController.text.trim()}",
        phone: _phoneController.text.trim(),
      );
      
      // Create email token for verification (6-digit code)
      final token = await _authService.createEmailToken(
        email: _emailController.text.trim()
      );
      
      setState(() {
        _isLoading = false;
        _currentStep++;
        _userId = token.userId;
        _userEmail = _emailController.text.trim();
      });
      
      _slideController.reset();
      _slideController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _authService.handleAuthError(e);
      });
      _showSnackBar(_errorMessage, Colors.red);
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final token = await _authService.createEmailToken(
        email: _userEmail ?? _emailController.text.trim()
      );
      
      setState(() {
        _isLoading = false;
        _userId = token.userId;
      });
      
      _showSnackBar('Verification code resent to your email', Colors.green);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _authService.handleAuthError(e);
      });
      _showSnackBar(_errorMessage, Colors.red);
    }
  }

  // Social login methods remain the same
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await _authService.createOAuthSession('google');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _authService.handleAuthError(e);
      });
      _showSnackBar(_errorMessage, Colors.red);
    }
  }

  Future<void> _signUpWithFacebook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await _authService.createOAuthSession('facebook');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _authService.handleAuthError(e);
      });
      _showSnackBar(_errorMessage, Colors.red);
    }
  }

  Future<void> _signUpWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await _authService.createOAuthSession('apple');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _authService.handleAuthError(e);
      });
      _showSnackBar(_errorMessage, Colors.red);
    }
  }

  Future<void> _verifyEmail() async {
    final otp = _otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      _showSnackBar('Please enter the 6-digit verification code', Colors.red);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authService.verifyEmailToken(
        userId: _userId ?? '',
        secret: otp,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _authService.handleAuthError(e);
      });
      _showSnackBar(_errorMessage, Colors.red);
    }
  }

  // Validators remain the same
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
    String cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleanedValue)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFF4CAF50),
                    const Color(0xFF45A049),
                    const Color(0xFF2E7D32),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            _buildDecorativeElements(size, isDarkMode),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header with back button and progress
                  _buildHeader(context),
                  
                  // Main content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(context),
                        _buildStep2(context),
                        _buildStep3(context),
                      ],
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

  Widget _buildDecorativeElements(Size size, bool isDarkMode) {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -size.height * 0.1,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.1),
            ),
          ),
        ),
        
        // Bottom left circle
        Positioned(
          bottom: -size.height * 0.15,
          left: -size.width * 0.25,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isDarkMode ? 0.03 : 0.08),
            ),
          ),
        ),
        
        // Small floating circles
        Positioned(
          top: size.height * 0.2,
          left: size.width * 0.1,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        
        Positioned(
          top: size.height * 0.6,
          right: size.width * 0.15,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              GestureDetector(
                onTap: _previousStep,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              
              // DailyDime title
              Text(
                'DailyDime',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Pacifico',
                  letterSpacing: 0.5,
                ),
              ),
              
              // Skip button
              if (_currentStep < 2)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 60),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress indicator
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= _currentStep 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _step1FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Start your financial journey with us',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Lottie animation - bigger size
                    Center(
                      child: SizedBox(
                        height: size.height * 0.28,
                        child: Lottie.asset(
                          _animationFiles[0],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(
                              height: size.height * 0.25,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.account_circle_outlined,
                                size: 120,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Email field
                    _buildEnhancedTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      hintText: 'Enter your email address',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Password field
                    _buildEnhancedTextField(
                      label: 'Password',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      hintText: 'Create a strong password',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password strength indicator
                    _buildPasswordStrength(),
                    
                    const SizedBox(height: 40),
                    
                    // Continue button
                    _buildEnhancedButton(
                      text: 'Continue',
                      onPressed: _nextStep,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Divider
                    _buildDivider('Or sign up with'),
                    
                    const SizedBox(height: 30),
                    
                    // Social login buttons
                    _buildSocialButtons(),
                    
                    const SizedBox(height: 30),
                    
                    // Login link
                    _buildLoginLink(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _step2FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Tell us more about yourself',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Lottie animation
                    Center(
                      child: SizedBox(
                        height: size.height * 0.25,
                        child: Lottie.asset(
                          _animationFiles[1],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(
                              height: size.height * 0.22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 120,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Name fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedTextField(
                            label: 'First Name',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            validator: _validateName,
                            hintText: 'First name',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildEnhancedTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            prefixIcon: Icons.person_outline,
                            validator: _validateName,
                            hintText: 'Last name',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Phone number
                    _buildEnhancedTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      hintText: '+1 (555) 123-4567',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Business name (optional)
                    _buildEnhancedTextField(
                      label: 'Business Name (Optional)',
                      controller: _businessNameController,
                      prefixIcon: Icons.business_outlined,
                      hintText: 'Your business name',
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Terms and conditions
                    _buildTermsCheckbox(),
                    
                    const SizedBox(height: 40),
                    
                    // Register button
                    _buildEnhancedButton(
                      text: 'Create Account',
                      onPressed: _nextStep,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep3(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Enter the 6-digit code sent to your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Lottie animation
                  SizedBox(
                    height: size.height * 0.25,
                    child: Lottie.asset(
                      _animationFiles[2],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          height: size.height * 0.22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            size: 120,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Email info
                  Text(
                    'Code sent to:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  Text(
                    _userEmail ?? _emailController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // OTP input fields
                  _buildOtpFields(),
                  
                  const SizedBox(height: 40),
                  
                  // Verify button
                  _buildEnhancedButton(
                    text: 'Verify Email',
                    onPressed: _verifyEmail,
                    isLoading: _isLoading,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Resend code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      GestureDetector(
                        onTap: _resendVerificationCode,
                        child: const Text(
                          'Resend',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Skip verification
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MainNavigation()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Skip verification for now',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
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
    );
  }

  Widget _buildEnhancedTextField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    required String hintText,
  }) {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[300] : const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  prefixIcon,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF2A2D3A) : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF4CAF50),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    final password = _passwordController.text;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2D3A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStrengthIndicator(
                password.length >= 8,
                'Min. 8 characters',
                isDarkMode,
              ),
              const SizedBox(width: 16),
              _buildStrengthIndicator(
                RegExp(r'[0-9]').hasMatch(password),
                'Numbers',
                isDarkMode,
              ),
              const SizedBox(width: 16),
              _buildStrengthIndicator(
                RegExp(r'[A-Z]').hasMatch(password),
                'Uppercase',
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthIndicator(bool isValid, String text, bool isDarkMode) {
    return Expanded(
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isValid ? const Color(0xFF4CAF50) : Colors.transparent,
              border: Border.all(
                color: isValid ? const Color(0xFF4CAF50) : Colors.grey[400]!,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isValid 
                ? const Icon(Icons.check, color: Colors.white, size: 12) 
                : null,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: isValid 
                    ? (isDarkMode ? Colors.white : Colors.grey[800])
                    : Colors.grey[500],
                fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton(
          icon: Icons.g_mobiledata_rounded,
          color: Colors.red,
          onTap: _signUpWithGoogle,
          isDarkMode: isDarkMode,
        ),
        _buildSocialButton(
          icon: Icons.facebook_rounded,
          color: const Color(0xFF1877F2),
          onTap: _signUpWithFacebook,
          isDarkMode: isDarkMode,
        ),
        _buildSocialButton(
          icon: Icons.apple_rounded,
          color: isDarkMode ? Colors.white : Colors.black,
          onTap: _signUpWithApple,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2D3A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 15,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2D3A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
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
              activeColor: const Color(0xFF4CAF50),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
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
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                children: [
                  const TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  const TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
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

  Widget _buildOtpFields() {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2A2D3A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.isNotEmpty && index < 5) {
                  _otpFocusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _otpFocusNodes[index - 1].requestFocus();
                }
              },
            ),
          );
        }),
      ),
    );
  }
}