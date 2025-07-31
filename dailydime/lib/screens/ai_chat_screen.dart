// lib/screens/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:intl/intl.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _isTyping = false;
  String _userName = 'User';
  
  // Gemini AI
  late GenerativeModel _model;
  
  // Appwrite
  late Client _client;
  late Databases _databases;
  
  // User financial context
  Map<String, dynamic> _userFinancialContext = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    // Load user context first, then add welcome message
    _loadUserContext().then((_) {
      _addWelcomeMessage();
    });
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  void _initializeServices() {
    // Initialize Gemini AI
    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
    );
    
    // Initialize Appwrite
    _client = Client()
      ..setEndpoint(AppConfig.appwriteEndpoint)
      ..setProject(AppConfig.appwriteProjectId);
    
    _databases = Databases(_client);
  }

  Future<void> _loadUserContext() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        setState(() {
          // Fix: Properly extract first name from the user's name
          final fullName = user.name.trim();
          if (fullName.isNotEmpty) {
            // Split by space and take first part, or use full name if no spaces
            final nameParts = fullName.split(' ');
            _userName = nameParts.first;
          } else {
            // Fallback to email username if name is empty
            final emailParts = user.email.split('@');
            _userName = emailParts.first.isNotEmpty ? emailParts.first : 'User';
          }
        });
        
        // Load financial data from Appwrite collections
        await _loadFinancialData(user.$id);
      } else {
        // Handle case where user is not logged in
        setState(() {
          _userName = 'User';
        });
      }
    } catch (e) {
      print('Error loading user context: $e');
      // Fallback to generic name on error
      setState(() {
        _userName = 'User';
      });
    }
  }

  Future<void> _loadFinancialData(String userId) async {
    try {
      setState(() => _isLoading = true);
      
      // Parallel loading of financial data
      final results = await Future.wait([
        _databases.listDocuments(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.transactionsCollection,
          queries: [
            Query.equal('userId', userId),
            Query.orderDesc('\$createdAt'),
            Query.limit(50),
          ],
        ),
        _databases.listDocuments(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.budgetsCollection,
          queries: [Query.equal('userId', userId)],
        ),
        _databases.listDocuments(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.savingsGoalsCollection,
          queries: [Query.equal('userId', userId)],
        ),
        _databases.listDocuments(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.categoriesCollection,
          queries: [Query.equal('userId', userId)],
        ),
      ]);
      
      _userFinancialContext = {
        'transactions': results[0].documents,
        'budgets': results[1].documents,
        'savingsGoals': results[2].documents,
        'categories': results[3].documents,
        'totalTransactions': results[0].total,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading financial data: $e');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Hi $_userName! 👋\n\nI'm your AI financial assistant powered by Gemini. I can help you understand your spending patterns, create budgets, set savings goals, and provide personalized financial insights.\n\nWhat would you like to know about your finances today?",
      isUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.welcome,
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
    
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Generate AI response
    try {
      final response = await _generateAIResponse(text);
      
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "I apologize, but I'm having trouble processing your request right now. Please try again in a moment.",
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.error,
      );
      
      setState(() {
        _messages.add(errorMessage);
        _isTyping = false;
      });
      
      _scrollToBottom();
    }
  }

  Future<String> _generateAIResponse(String userMessage) async {
    try {
      // Create context-aware prompt
      final contextPrompt = _buildContextualPrompt(userMessage);
      
      final content = [Content.text(contextPrompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? "I'm sorry, I couldn't generate a response. Please try again.";
    } catch (e) {
      throw Exception('Failed to generate AI response: $e');
    }
  }

  String _buildContextualPrompt(String userMessage) {
    final context = StringBuffer();
    
    context.writeln("You are a helpful AI financial assistant for DailyDime, a personal budget management app.");
    context.writeln("User's name: $_userName");
    context.writeln("Current date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}");
    context.writeln();
    
    // Add financial context if available
    if (_userFinancialContext.isNotEmpty) {
      context.writeln("User's Financial Context:");
      
      final transactions = _userFinancialContext['transactions'] as List? ?? [];
      if (transactions.isNotEmpty) {
        context.writeln("- Total transactions: ${_userFinancialContext['totalTransactions']}");
        
        // Calculate recent spending
        final recentTransactions = transactions.take(10);
        double totalSpent = 0;
        final categories = <String, double>{};
        
        for (final transaction in recentTransactions) {
          final amount = (transaction.data['amount'] ?? 0.0) as double;
          final category = transaction.data['category'] as String? ?? 'Other';
          final type = transaction.data['type'] as String? ?? 'expense';
          
          if (type == 'expense') {
            totalSpent += amount;
            categories[category] = (categories[category] ?? 0) + amount;
          }
        }
        
        context.writeln("- Recent spending: ${AppConfig.formatCurrency((totalSpent * 100).toInt())}");
        if (categories.isNotEmpty) {
          context.writeln("- Top spending categories: ${categories.entries.take(3).map((e) => "${e.key}: ${AppConfig.formatCurrency((e.value * 100).toInt())}").join(", ")}");
        }
      }
      
      final budgets = _userFinancialContext['budgets'] as List? ?? [];
      if (budgets.isNotEmpty) {
        context.writeln("- Active budgets: ${budgets.length}");
      }
      
      final savingsGoals = _userFinancialContext['savingsGoals'] as List? ?? [];
      if (savingsGoals.isNotEmpty) {
        context.writeln("- Savings goals: ${savingsGoals.length}");
      }
    }
    
    context.writeln();
    context.writeln("Instructions:");
    context.writeln("- Provide helpful, personalized financial advice");
    context.writeln("- Use the user's actual financial data when available");
    context.writeln("- Be encouraging and supportive");
    context.writeln("- Format currency amounts using KES (Kenyan Shillings)");
    context.writeln("- Keep responses conversational and easy to understand");
    context.writeln("- If asked about specific transactions or data not provided, explain what information you need");
    context.writeln();
    context.writeln("User's message: $userMessage");
    
    return context.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _getQuickActions() {
    return [
      "Show my spending summary",
      "How can I save more money?",
      "Analyze my budget",
      "Investment advice",
      "Set a savings goal",
      "Track my expenses",
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.scaffoldColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeService.primaryColor.withOpacity(0.05),
                  themeService.scaffoldColor,
                ],
              ),
            ),
            child: Column(
              children: [
                _buildHeader(themeService),
                Expanded(
                  child: _buildChatArea(themeService),
                ),
                _buildInputArea(themeService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor,
            themeService.primaryColor.withOpacity(0.8),
            themeService.secondaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/images/gemini.png',
                          width: 35,
                          height: 35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini Assistant',
                          style: TextStyle(
                            fontFamily: 'DMsans',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isTyping ? 'Typing...' : 'Online',
                          style: TextStyle(
                            fontFamily: 'DMsans',
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_isLoading) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                onPressed: _loadUserContext,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatArea(ThemeService themeService) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bgpattern4.png'),
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          child: Column(
            children: [
              if (_messages.isEmpty && !_isLoading) ...[
                _buildWelcomeArea(themeService),
              ],
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator(themeService);
                    }
                    
                    final message = _messages[index];
                    return _buildMessageBubble(message, themeService);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeArea(ThemeService themeService) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/loading3.json',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'Hi $_userName! 👋',
                style: TextStyle(
                  fontFamily: 'DMsans',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'I\'m your AI financial assistant. I can help you with budgeting, expense tracking, savings goals, and personalized financial insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMsans',
                  fontSize: 16,
                  color: themeService.subtextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildQuickActionsGrid(themeService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(ThemeService themeService) {
    final actions = _getQuickActions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'DMsans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeService.textColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _buildQuickActionButton(actions[index], themeService);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String action, ThemeService themeService) {
    return InkWell(
      onTap: () {
        _messageController.text = action;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeService.primaryColor.withOpacity(0.1),
              themeService.secondaryColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeService.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            action,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMsans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: themeService.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: themeService.primaryColor,
              child: Image.asset(
                'assets/images/gemini.png',
                width: 20,
                height: 20,
                // color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [themeService.primaryColor, themeService.secondaryColor],
                      )
                    : null,
                color: message.isUser ? null : themeService.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == MessageType.welcome) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: themeService.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Welcome',
                          style: TextStyle(
                            fontFamily: 'DMsans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: themeService.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'DMsans',
                      fontSize: 15,
                      color: message.isUser ? Colors.white : themeService.textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontFamily: 'DMsans',
                      fontSize: 11,
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7)
                          : themeService.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: themeService.primaryColor.withOpacity(0.2),
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontFamily: 'DMsans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeService.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: themeService.primaryColor,
            child: Image.asset(
              'assets/images/gemini.png',
              width: 30,
              height: 30,
              // color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(themeService, 0),
                const SizedBox(width: 4),
                _buildTypingDot(themeService, 1),
                const SizedBox(width: 4),
                _buildTypingDot(themeService, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(ThemeService themeService, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimationController,
      builder: (context, child) {
        final animationValue = (_fadeAnimationController.value + index * 0.2) % 1.0;
        return Opacity(
          opacity: 0.4 + (0.6 * (1 - (animationValue - 0.5).abs() * 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: themeService.subtextColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ThemeService themeService) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: themeService.scaffoldColor,
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: themeService.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me about your finances...',
                  hintStyle: TextStyle(
                    fontFamily: 'DMsans',
                    color: themeService.subtextColor,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: TextStyle(
                  fontFamily: 'DMsans',
                  color: themeService.textColor,
                  fontSize: 15,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to update send icon
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeService.primaryColor, themeService.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: themeService.primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: _isTyping ? null : _sendMessage,
                child: Container(
                  width: 50,
                  height: 50,
                  child: Icon(
                    _messageController.text.trim().isEmpty 
                        ? Icons.send 
                        : Icons.send,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum MessageType {
  normal,
  welcome,
  error,
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = MessageType.normal,
  });
}