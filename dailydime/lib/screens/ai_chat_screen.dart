// lib/screens/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:dailydime/config/theme.dart';
import 'package:dailydime/widgets/charts/spending_chart.dart';
import 'package:dailydime/widgets/charts/progress_chart.dart';
import 'package:dailydime/widgets/common/custom_text_field.dart';
import 'package:flutter/services.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _showAnalytics = false;
  late TabController _tabController;

  // Sample data for charts
  final List<SpendingCategory> _spendingCategories = [
    SpendingCategory(name: 'Food', amount: 5600, color: AppTheme.primaryEmerald),
    SpendingCategory(name: 'Transport', amount: 2400, color: AppTheme.primaryBlue),
    SpendingCategory(name: 'Entertainment', amount: 1200, color: AppTheme.accentIndigo),
    SpendingCategory(name: 'Shopping', amount: 3200, color: AppTheme.accentPurple),
    SpendingCategory(name: 'Bills', amount: 4800, color: AppTheme.info),
  ];

  final List<double> _savingsData = [300, 400, 250, 500, 600, 450, 700];
  final List<double> _spendingData = [700, 500, 900, 400, 600, 800, 300];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add initial AI message
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your DailyDime AI assistant. I can help you with budgeting, savings goals, and financial insights. How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = ChatMessage(
      text: _messageController.text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
    });
    
    _scrollToBottom();
    
    // Clear input field
    _messageController.clear();
    
    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 800), () {
      final String question = userMessage.text.toLowerCase();
      String aiResponse = "";
      
      if (question.contains('budget') || question.contains('spend')) {
        aiResponse = "Based on your spending patterns, I recommend allocating KES 8,000 for food, KES 4,000 for transport, and KES 3,000 for entertainment this month. You've been spending about 20% more on food compared to last month.";
      } else if (question.contains('save') || question.contains('goal')) {
        aiResponse = "You're making great progress on your savings! If you save KES 500 daily, you'll reach your goal of KES 15,000 for the new headphones in 30 days. Would you like me to set up automated savings for this?";
      } else if (question.contains('analyze') || question.contains('insight')) {
        aiResponse = "I've analyzed your spending for the last 30 days. Your biggest expense is food (33%), followed by rent (25%) and transport (15%). You could save approximately KES 2,000 by reducing takeout meals to twice a week.";
      } else if (question.contains('tip') || question.contains('advice')) {
        aiResponse = "Here's a financial tip: Try the 50/30/20 rule - spend 50% on needs, 30% on wants, and save 20%. Based on your income of KES 45,000, that's KES 22,500 for needs, KES 13,500 for wants, and KES 9,000 for savings.";
      } else {
        aiResponse = "I'm here to help with your finances! You can ask me about budgeting, savings goals, spending analysis, or financial tips. What would you like to know?";
      }
      
      setState(() {
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      
      _scrollToBottom();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showAnalytics ? "AI Financial Insights" : "AI Financial Assistant",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showAnalytics ? Icons.chat_bubble : Icons.bar_chart,
              color: AppTheme.primaryEmerald,
            ),
            onPressed: () {
              setState(() {
                _showAnalytics = !_showAnalytics;
              });
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
      body: _showAnalytics ? _buildAnalyticsView() : _buildChatView(),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatarBubble(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppTheme.primaryEmerald
                    : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.textDark,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white.withOpacity(0.7) : AppTheme.textMedium,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildUserAvatarBubble(),
        ],
      ),
    );
  }

  Widget _buildAvatarBubble() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(
          Icons.assistant,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildUserAvatarBubble() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.accentPurple,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Ask for financial advice...",
                    hintStyle: TextStyle(color: AppTheme.textMedium),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(
                      Icons.monetization_on,
                      color: AppTheme.primaryEmerald.withOpacity(0.7),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsView() {
    final totalSpending = _spendingCategories.fold(
      0.0, (sum, category) => sum + category.amount);

    return Column(
      children: [
        // Tab Bar for Analytics
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryEmerald,
            unselectedLabelColor: AppTheme.textMedium,
            indicatorColor: AppTheme.primaryEmerald,
            tabs: const [
              Tab(text: "Overview", icon: Icon(Icons.dashboard_rounded)),
              Tab(text: "Spending", icon: Icon(Icons.money_off_rounded)),
              Tab(text: "Savings", icon: Icon(Icons.savings_rounded)),
            ],
          ),
        ),
        
        // Tab Bar View for Analytics Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsightCard(
                      title: "Monthly Overview",
                      description: "You've spent KES 17,200 this month, which is 12% less than last month. Great job on reducing your spending!",
                      icon: Icons.trending_down,
                      iconColor: AppTheme.success,
                    ),
                    const SizedBox(height: 16),
                    SpendingChart(
                      categories: _spendingCategories,
                      totalSpending: totalSpending,
                    ),
                    const SizedBox(height: 16),
                    ProgressChart(
                      weeklyData: _savingsData,
                      title: "Savings Progress",
                    ),
                    const SizedBox(height: 16),
                    _buildInsightCard(
                      title: "AI Recommendation",
                      description: "Based on your spending patterns, you could save up to KES 2,000 by reducing food delivery expenses. Try cooking at home 2 more days per week.",
                      icon: Icons.lightbulb_outline,
                      iconColor: AppTheme.warning,
                    ),
                    const SizedBox(height: 16),
                    _buildGoalProgressCard(),
                  ],
                ),
              ),
              
              // Spending Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SpendingChart(
                      categories: _spendingCategories,
                      totalSpending: totalSpending,
                    ),
                    const SizedBox(height: 16),
                    ProgressChart(
                      weeklyData: _spendingData,
                      title: "Weekly Spending",
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryListCard(),
                    const SizedBox(height: 16),
                    _buildInsightCard(
                      title: "Spending Insight",
                      description: "Your highest spending day is Friday, with an average of KES 900 spent. Consider planning cheaper weekend activities.",
                      icon: Icons.calendar_today,
                      iconColor: AppTheme.info,
                    ),
                  ],
                ),
              ),
              
              // Savings Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressChart(
                      weeklyData: _savingsData,
                      title: "Weekly Savings",
                    ),
                    const SizedBox(height: 16),
                    _buildGoalProgressCard(),
                    const SizedBox(height: 16),
                    _buildInsightCard(
                      title: "Savings Opportunity",
                      description: "If you save KES 200 more per day, you'll reach your KES 15,000 goal in just 20 days instead of 30.",
                      icon: Icons.speed,
                      iconColor: AppTheme.accentPurple,
                    ),
                    const SizedBox(height: 16),
                    _buildSavingsMethodsCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Button to return to chat
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAnalytics = false;
              });
              HapticFeedback.mediumImpact();
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Return to AI Chat"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildGoalProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Savings Goals",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalProgressItem(
              title: "New Headphones",
              current: 9500,
              target: 15000,
              color: AppTheme.primaryEmerald,
              icon: Icons.headphones,
            ),
            const SizedBox(height: 12),
            _buildGoalProgressItem(
              title: "Weekend Trip",
              current: 12000,
              target: 30000,
              color: AppTheme.primaryBlue,
              icon: Icons.flight,
            ),
            const SizedBox(height: 12),
            _buildGoalProgressItem(
              title: "Emergency Fund",
              current: 25000,
              target: 100000,
              color: AppTheme.accentIndigo,
              icon: Icons.health_and_safety,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressItem({
    required String title,
    required double current,
    required double target,
    required Color color,
    required IconData icon,
  }) {
    final progress = current / target;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: MediaQuery.of(context).size.width * 0.6 * progress, // Adjust width based on progress
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "KES ${current.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "KES ${target.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryListCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Top Spending Categories",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ..._spendingCategories
              .sorted((a, b) => b.amount.compareTo(a.amount))
              .take(3)
              .map((category) => _buildCategoryItem(
                title: category.name,
                amount: category.amount,
                color: category.color,
                previousAmount: category.amount * 1.1, // Simulated previous amount
              ))
              .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    required double amount,
    required Color color,
    required double previousAmount,
  }) {
    final percentChange = ((amount - previousAmount) / previousAmount) * 100;
    final isIncrease = percentChange > 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "KES ${amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncrease ? AppTheme.error : AppTheme.success,
                    size: 12,
                  ),
                  Text(
                    "${percentChange.abs().toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 12,
                      color: isIncrease ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsMethodsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recommended Savings Methods",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildSavingsMethodItem(
              title: "Round-Up Savings",
              description: "Round up every transaction to the nearest 50 KES and save the difference.",
              icon: Icons.attach_money,
              color: AppTheme.primaryEmerald,
            ),
            const SizedBox(height: 12),
            _buildSavingsMethodItem(
              title: "50/30/20 Rule",
              description: "Allocate 50% to needs, 30% to wants, and 20% to savings from your income.",
              icon: Icons.pie_chart,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 12),
            _buildSavingsMethodItem(
              title: "M-Pesa Lock Savings",
              description: "Set up automatic transfers to M-Pesa Lock Savings every payday.",
              icon: Icons.lock_outline,
              color: AppTheme.accentIndigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsMethodItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

extension ListExtension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final List<T> copied = List.from(this);
    copied.sort(compare);
    return copied;
  }
}