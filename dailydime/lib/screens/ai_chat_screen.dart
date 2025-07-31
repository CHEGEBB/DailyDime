// lib/screens/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:intl/intl.dart';
import 'package:flutter_chat_bubble/flutter_chat_bubble.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/services/auth_service.dart';
import 'package:dailydime/widgets/custom_loading_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  
  late final Client _client;
  late final Databases _databases;
  late final GenerativeModel _model;
  late AnimationController _animationController;
  
  final List<ChatMessage> _messages = [];
  models.User? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isTyping = false;
  bool _showScrollToBottom = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _initializeServices();
    _scrollController.addListener(_onScrollChanged);
    
    // Add welcome message with a small delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _addWelcomeMessage();
      }
    });
  }
  
  void _onScrollChanged() {
    if (_scrollController.position.pixels < 
        _scrollController.position.maxScrollExtent - 500 && 
        !_showScrollToBottom) {
      setState(() => _showScrollToBottom = true);
    } else if (_scrollController.position.pixels > 
        _scrollController.position.maxScrollExtent - 100 && 
        _showScrollToBottom) {
      setState(() => _showScrollToBottom = false);
    }
  }

  Future<void> _initializeServices() async {
    // Initialize Appwrite
    _client = Client()
      ..setEndpoint(AppConfig.appwriteEndpoint)
      ..setProject(AppConfig.appwriteProjectId)
      ..setSelfSigned(status: true);
    
    _databases = Databases(_client);
    
    // Initialize Gemini
    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
    );
    
    try {
      // Get current user
      _currentUser = await _authService.getCurrentUser();
      
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }
  
  void _addWelcomeMessage() {
    final greeting = _currentUser != null 
        ? "Hi ${_currentUser!.name.split(' ').first}! I'm your financial assistant powered by Gemini AI. How can I help with your budget today?"
        : "Hello! I'm your financial assistant powered by Gemini AI. How can I help with your budget today?";
    
    setState(() {
      _messages.add(ChatMessage(
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Clear input
    _messageController.clear();
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    
    // Scroll to bottom
    _scrollToBottom();
    
    try {
      // Get financial data from Appwrite
      final context = await _getFinancialContext();
      
      // Create Gemini prompt with context
      final prompt = '''
You are DailyDime's AI financial assistant. You provide concise, helpful responses about personal finance.

USER'S FINANCIAL CONTEXT:
$context

USER'S QUESTION:
$message

Respond in a friendly, conversational tone. Provide specific, actionable advice based on the user's financial data. Keep responses brief and to the point. If you don't have enough information, suggest what information would be helpful.
''';

      // Send to Gemini API
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? "Sorry, I couldn't process that request. Please try again.";
      
      // Add AI response
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        
        // Scroll to bottom again after response
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Sorry, I encountered an error: ${e.toString()}. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
          _isTyping = false;
        });
        
        _scrollToBottom();
      }
    }
  }
  
  Future<String> _getFinancialContext() async {
    try {
      setState(() => _isLoading = true);
      
      // Get transactions
      final transactions = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.transactionsCollection,
        queries: [
          Query.limit(20),
          Query.orderDesc('date'),
        ],
      );
      
      // Get budgets
      final budgets = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.budgetsCollection,
      );
      
      // Get savings goals
      final savingsGoals = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.savingsGoalsCollection,
      );
      
      // Format the context
      String context = "RECENT TRANSACTIONS:\n";
      
      int totalIncome = 0;
      int totalExpenses = 0;
      
      if (transactions.documents.isNotEmpty) {
        for (var doc in transactions.documents) {
          final amount = doc.data['amount'] as int;
          final type = doc.data['type'] as String;
          final category = doc.data['category'] as String;
          final date = doc.data['date'] as String;
          
          if (type == 'income') {
            totalIncome += amount;
          } else {
            totalExpenses += amount;
          }
          
          context += "- ${DateFormat('MMM d').format(DateTime.parse(date))}: ${type.toUpperCase()} of ${AppConfig.formatCurrency(amount)} in category '$category'\n";
        }
      } else {
        context += "No recent transactions found.\n";
      }
      
      // Add summary
      context += "\nSUMMARY:\n";
      context += "- Total Recent Income: ${AppConfig.formatCurrency(totalIncome)}\n";
      context += "- Total Recent Expenses: ${AppConfig.formatCurrency(totalExpenses)}\n";
      context += "- Net Flow: ${AppConfig.formatCurrency(totalIncome - totalExpenses)}\n";
      
      // Add budget information
      context += "\nBUDGETS:\n";
      if (budgets.documents.isNotEmpty) {
        for (var doc in budgets.documents) {
          final category = doc.data['category'] as String;
          final limit = doc.data['limit'] as int;
          final spent = doc.data['spent'] as int;
          
          context += "- $category: Spent ${AppConfig.formatCurrency(spent)} of ${AppConfig.formatCurrency(limit)} budget\n";
        }
      } else {
        context += "No budgets set up yet.\n";
      }
      
      // Add savings goals
      context += "\nSAVINGS GOALS:\n";
      if (savingsGoals.documents.isNotEmpty) {
        for (var doc in savingsGoals.documents) {
          final name = doc.data['name'] as String;
          final target = doc.data['targetAmount'] as int;
          final current = doc.data['currentAmount'] as int;
          
          context += "- $name: ${AppConfig.formatCurrency(current)} saved of ${AppConfig.formatCurrency(target)} goal\n";
        }
      } else {
        context += "No savings goals set up yet.\n";
      }
      
      setState(() => _isLoading = false);
      return context;
    } catch (e) {
      setState(() => _isLoading = false);
      return "Error fetching financial data. Limited context available.";
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return KeyboardVisibilityBuilder(
          builder: (context, isKeyboardVisible) {
            return Scaffold(
              backgroundColor: themeService.scaffoldColor,
              appBar: _buildAppBar(themeService),
              body: _isInitializing
                  ? _buildLoadingView(themeService)
                  : _buildChatView(themeService, isKeyboardVisible),
              floatingActionButton: _showScrollToBottom
                  ? FloatingActionButton(
                      mini: true,
                      backgroundColor: themeService.primaryColor,
                      child: const Icon(Icons.arrow_downward, color: Colors.white),
                      onPressed: _scrollToBottom,
                    )
                  : null,
            );
          }
        );
      },
    );
  }
  
  AppBar _buildAppBar(ThemeService themeService) {
    return AppBar(
      backgroundColor: themeService.isDarkMode
          ? themeService.cardColor
          : themeService.primaryColor,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: themeService.isDarkMode ? themeService.textColor : Colors.white,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? themeService.primaryColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 22,
                height: 22,
                color: themeService.isDarkMode
                    ? themeService.primaryColor
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Financial Assistant',
                style: TextStyle(
                  fontFamily: 'DMsans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeService.isDarkMode ? themeService.textColor : Colors.white,
                ),
              ),
              Text(
                'Powered by Gemini AI',
                style: TextStyle(
                  fontFamily: 'DMsans',
                  fontSize: 12,
                  color: themeService.isDarkMode
                      ? themeService.subtextColor
                      : Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: themeService.isDarkMode ? themeService.textColor : Colors.white,
          ),
          onPressed: () {
            setState(() {
              _messages.clear();
              _addWelcomeMessage();
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildLoadingView(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading.json',
            width: 120,
            height: 120,
            controller: _animationController,
          ),
          const SizedBox(height: 24),
          Text(
            'Initializing AI Assistant...',
            style: TextStyle(
              fontFamily: 'DMsans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: themeService.textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatView(ThemeService themeService, bool isKeyboardVisible) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            themeService.isDarkMode
                ? 'assets/images/pattern11.png'
                : 'assets/images/pattern11.png',
          ),
          opacity: 0.04,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          // Optional greeting header - shows only when no messages
          if (_messages.isEmpty)
            _buildGreetingHeader(themeService),
            
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChatView(themeService)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, themeService, index);
                    },
                  ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: _buildTypingIndicator(themeService),
            ),
            
          // Financial data loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeService.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyzing your financial data...',
                    style: TextStyle(
                      fontFamily: 'DMsans',
                      fontSize: 12,
                      color: themeService.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            
          // Input field
          _buildMessageInput(themeService, isKeyboardVisible),
        ],
      ),
    );
  }
  
  Widget _buildGreetingHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? themeService.primaryColor.withOpacity(0.15)
            : themeService.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: themeService.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser != null
                      ? 'Hi ${_currentUser!.name.split(' ').first}!'
                      : 'Hello!',
                  style: TextStyle(
                    fontFamily: 'DMsans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask me anything about your finances, budgeting tips, or how to reach your financial goals.',
                  style: TextStyle(
                    fontFamily: 'DMsans',
                    fontSize: 14,
                    color: themeService.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 500));
  }
  
  Widget _buildEmptyChatView(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/money_coins.json',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 24),
          Text(
            'Your AI Financial Assistant',
            style: TextStyle(
              fontFamily: 'DMsans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ask me about your spending, budgeting advice, or financial insights',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMsans',
                fontSize: 14,
                color: themeService.subtextColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestedQuestions(themeService),
        ],
      ),
    );
  }
  
  Widget _buildSuggestedQuestions(ThemeService themeService) {
    final questions = [
      "How much did I spend last week?",
      "What's my biggest expense category?",
      "How can I save more money?",
      "Am I on track with my budget?",
    ];
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: questions.map((question) {
        return InkWell(
          onTap: () => _sendMessage(question),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeService.isDarkMode
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
              ),
            ),
            child: Text(
              question,
              style: TextStyle(
                fontFamily: 'DMsans',
                fontSize: 13,
                color: themeService.textColor,
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }
  
  Widget _buildMessageBubble(ChatMessage message, ThemeService themeService, int index) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar for non-user messages
          if (!isUser) _buildAIAvatar(themeService),
          
          // Message content
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 50 : 8,
                right: isUser ? 0 : 50,
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Message bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? themeService.primaryColor
                          : message.isError
                              ? themeService.errorColor.withOpacity(0.1)
                              : themeService.cardColor,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontFamily: 'DMsans',
                        fontSize: 14,
                        height: 1.4,
                        color: isUser
                            ? Colors.white
                            : message.isError
                                ? themeService.errorColor
                                : themeService.textColor,
                      ),
                    ),
                  ),
                  
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(
                        fontFamily: 'DMsans',
                        fontSize: 10,
                        color: themeService.subtextColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 150 * index % 3)),
          
          // User avatar for user messages
          if (isUser) _buildUserAvatar(themeService),
        ],
      ),
    );
  }
  
  Widget _buildAIAvatar(ThemeService themeService) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: themeService.primaryColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 20,
          height: 20,
          color: themeService.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildUserAvatar(ThemeService themeService) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: themeService.primaryColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 18,
          color: themeService.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildTypingIndicator(ThemeService themeService) {
    return Row(
      children: [
        _buildAIAvatar(themeService),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              _buildDot(themeService),
              const SizedBox(width: 4),
              _buildDot(themeService, delay: 300),
              const SizedBox(width: 4),
              _buildDot(themeService, delay: 600),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDot(ThemeService themeService, {int delay = 0}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: themeService.primaryColor.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).fadeOut(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 600),
    ).fadeIn(
      duration: const Duration(milliseconds: 600),
    );
  }
  
  Widget _buildMessageInput(ThemeService themeService, bool isKeyboardVisible) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: isKeyboardVisible ? 8 : 24,
      ),
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? themeService.cardColor
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: themeService.isDarkMode
                      ? themeService.scaffoldColor
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: themeService.isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Ask about your finances...',
                    hintStyle: TextStyle(
                      fontFamily: 'DMsans',
                      color: themeService.subtextColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: TextStyle(
                    fontFamily: 'DMsans',
                    fontSize: 14,
                    color: themeService.textColor,
                  ),
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _sendMessage(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: themeService.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeService.primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () {
                  final message = _messageController.text;
                  if (message.trim().isNotEmpty) {
                    _sendMessage(message);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (date == today) {
      return DateFormat('h:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}