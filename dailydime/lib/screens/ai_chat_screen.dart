// lib/screens/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailydime/config/theme.dart';
import 'package:dailydime/screens/analytics_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late TabController _tabController;
  bool _showAIChat = false;
  final ScrollController _scrollController = ScrollController();
  final List<AIMessage> _messages = [];
  final List<SavingGoal> _savingGoals = [];
  final List<AIInsight> _aiInsights = [];

  @override
  void initState() {
    super.initState();
    // Start with Analytics tab (index 1) by default
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _loadSampleData();
  }

  void _loadSampleData() {
    // Sample AI insights
    _aiInsights.addAll([
      AIInsight(
        title: "Spending Pattern Detected",
        description: "You've spent 20% more on food this week compared to your average. Consider meal prepping to reduce costs.",
        iconData: Icons.restaurant,
        color: AppTheme.accentIndigo,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        actionText: "Get meal prep tips",
      ),
      AIInsight(
        title: "Savings Opportunity",
        description: "Based on your M-Pesa transactions, you could save KES 200 today towards your 'New Headphones' goal.",
        iconData: Icons.savings_outlined,
        color: AppTheme.primaryEmerald,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        actionText: "Save KES 200 now",
      ),
      AIInsight(
        title: "Bill Reminder",
        description: "Your electricity bill of approximately KES 1,200 is due in 3 days. Ensure you have enough funds.",
        iconData: Icons.bolt,
        color: AppTheme.warning,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        actionText: "Set reminder",
      ),
      AIInsight(
        title: "Budget Alert",
        description: "You've reached 85% of your entertainment budget for this month. Consider limiting spending in this category.",
        iconData: Icons.warning_amber_rounded,
        color: AppTheme.error,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        actionText: "Review budget",
      ),
    ]);

    // Sample saving goals
    _savingGoals.addAll([
      SavingGoal(
        id: "1",
        title: "New Headphones",
        targetAmount: 15000,
        currentAmount: 9500,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        iconData: Icons.headphones,
        color: AppTheme.primaryEmerald,
      ),
      SavingGoal(
        id: "2",
        title: "Weekend Trip",
        targetAmount: 30000,
        currentAmount: 12000,
        targetDate: DateTime.now().add(const Duration(days: 60)),
        iconData: Icons.flight,
        color: AppTheme.primaryBlue,
      ),
      SavingGoal(
        id: "3",
        title: "Emergency Fund",
        targetAmount: 100000,
        currentAmount: 25000,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        iconData: Icons.health_and_safety,
        color: AppTheme.accentIndigo,
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = AIMessage(
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
        aiResponse = "I'm here to help with your finances. You can ask me about budgeting, savings goals, spending analysis, or financial tips. What would you like to know?";
      }
      
      setState(() {
        _messages.add(AIMessage(
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

  void _toggleAIChat() {
    setState(() {
      _showAIChat = !_showAIChat;
    });
    HapticFeedback.mediumImpact();
  }

  void _handleQuickAction(String action) {
    setState(() {
      _messageController.text = action;
    });
    _sendMessage();
  }

  void _handleGoalAction(SavingGoal goal) {
    // Show dialog to save toward goal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSaveToGoalBottomSheet(goal),
    );
  }

  Widget _buildSaveToGoalBottomSheet(SavingGoal goal) {
    final TextEditingController amountController = TextEditingController(text: '100');
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    goal.iconData,
                    color: goal.color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Save towards ${goal.title}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "KES ${NumberFormat("#,##0").format(goal.currentAmount)} of KES ${NumberFormat("#,##0").format(goal.targetAmount)}",
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount to save (KES)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Quick amount buttons
                  for (final amount in [50, 100, 200, 500])
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          amountController.text = amount.toString();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.backgroundLight,
                          foregroundColor: AppTheme.textDark,
                        ),
                        child: Text("${amount}"),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Here we would actually process the saving
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount > 0) {
                        setState(() {
                          final updatedGoal = goal.copyWith(
                            currentAmount: goal.currentAmount + amount,
                          );
                          
                          final index = _savingGoals.indexWhere((g) => g.id == goal.id);
                          if (index >= 0) {
                            _savingGoals[index] = updatedGoal;
                          }
                        });
                      }
                      Navigator.pop(context);
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "KES ${amountController.text} saved towards ${goal.title}!",
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Save Now"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Improved Header with fixed positioning
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // App header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "DailyDime",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        // Chat toggle button
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: _showAIChat
                              ? IconButton(
                                  key: const ValueKey('close_chat'),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: AppTheme.error,
                                      size: 18,
                                    ),
                                  ),
                                  onPressed: _toggleAIChat,
                                )
                              : IconButton(
                                  key: const ValueKey('open_chat'),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryEmerald.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline,
                                      color: AppTheme.primaryEmerald,
                                      size: 18,
                                    ),
                                  ),
                                  onPressed: _toggleAIChat,
                                ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab Bar with improved styling
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: AppTheme.primaryEmerald,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textMedium,
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics_outlined, size: 18),
                                SizedBox(width: 6),
                                Text("Analytics"),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.smart_toy_outlined, size: 18),
                                SizedBox(width: 6),
                                Text("AI Insights"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: Stack(
                children: [
                  // Tab content
                  TabBarView(
                    controller: _tabController,
                    children: [
                      // Analytics Tab (first, as requested)
                      const AnalyticsScreen(),
                      
                      // AI Insights Tab
                      _buildAIInsightsTab(),
                    ],
                  ),
                  
                  // Chat overlay
                  if (_showAIChat) _buildChatOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Assistant card with improved spacing
          _buildAIAssistantCard(),
          const SizedBox(height: 24),
          
          // Quick Actions with responsive layout
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          
          // AI Insights with proper text wrapping
          _buildAIInsightsSection(),
          const SizedBox(height: 24),
          
          // Saving Goals with overflow handling
          _buildSavingGoalsSection(),
          const SizedBox(height: 24),
          
          // Smart Budget Recommendations
          _buildSmartBudgetSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryEmerald,
            AppTheme.primaryTeal,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryEmerald.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Finance Assistant",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You can save KES 300 today based on your spending patterns.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Show saving options
                    _toggleAIChat();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryEmerald,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Ask AI for Details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final List<Map<String, dynamic>> quickActions = [
      {
        'title': 'Budget Help',
        'icon': Icons.account_balance_wallet,
        'color': AppTheme.primaryBlue,
        'action': 'Help me create a budget',
      },
      {
        'title': 'Save Money',
        'icon': Icons.savings,
        'color': AppTheme.primaryEmerald,
        'action': 'How can I save more money?',
      },
      {
        'title': 'Analyze Spending',
        'icon': Icons.insights,
        'color': AppTheme.accentIndigo,
        'action': 'Analyze my recent spending',
      },
      {
        'title': 'Financial Tips',
        'icon': Icons.lightbulb_outline,
        'color': AppTheme.warning,
        'action': 'Give me financial tips',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Make it responsive using Wrap instead of fixed ListView
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: quickActions.map((action) {
            return InkWell(
              onTap: () {
                _toggleAIChat();
                _handleQuickAction(action['action']);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: (MediaQuery.of(context).size.width - 44) / 2, // Responsive width
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: action['color'].withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        action['icon'],
                        color: action['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAIInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AI Insights",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _aiInsights.length,
          itemBuilder: (context, index) {
            final insight = _aiInsights[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: insight.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          insight.iconData,
                          color: insight.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    insight.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatTime(insight.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              insight.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDark.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                _toggleAIChat();
                                _handleQuickAction("Tell me more about ${insight.title.toLowerCase()}");
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: insight.color,
                                side: BorderSide(color: insight.color),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(insight.actionText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSavingGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Saving Goals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all goals
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryEmerald,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text("See All"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Make savings goals responsive
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _savingGoals.length,
          itemBuilder: (context, index) {
            final goal = _savingGoals[index];
            final progress = goal.currentAmount / goal.targetAmount;
            final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: goal.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            goal.iconData,
                            color: goal.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "KES ${NumberFormat("#,##0").format(goal.currentAmount)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "of KES ${NumberFormat("#,##0").format(goal.targetAmount)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppTheme.backgroundLight,
                              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: goal.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${(progress * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: goal.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$daysLeft days left",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _handleGoalAction(goal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goal.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(double.infinity, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Save Now"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSmartBudgetSection() {
    // Sample budget categories
    final List<Map<String, dynamic>> budgetCategories = [
      {
        'name': 'Food',
        'spent': 8500,
        'budget': 10000,
        'color': AppTheme.primaryEmerald,
        'icon': Icons.restaurant,
      },
      {
        'name': 'Transport',
        'spent': 4200,
        'budget': 5000,
        'color': AppTheme.primaryBlue,
        'icon': Icons.directions_car,
      },
      {
        'name': 'Entertainment',
        'spent': 2800,
        'budget': 3000,
        'color': AppTheme.accentIndigo,
        'icon': Icons.movie,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Smart Budget",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "July 2025",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total Budget Overview
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Budget",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "KES 25,000 / 30,000",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 25000 / 30000,
                  backgroundColor: AppTheme.backgroundLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),
              // Category breakdown with improved layout
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: budgetCategories.length,
                itemBuilder: (context, index) {
                  final category = budgetCategories[index];
                  final progress = category['spent'] / category['budget'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: category['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            category['icon'],
                            color: category['color'],
                            size: 18,
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
                                    category['name'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: progress > 0.9 ? AppTheme.error : AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                children: [
                                  // Background track
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundLight,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  // Progress indicator
                                  Container(
                                    height: 6,
                                    width: (MediaQuery.of(context).size.width - 104) * progress,
                                    decoration: BoxDecoration(
                                      color: progress > 0.9 ? AppTheme.error : category['color'],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${NumberFormat("#,##0").format(category['spent'])} / ${NumberFormat("#,##0").format(category['budget'])}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // AI budget suggestion
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "AI Suggestion",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "You could save KES 500 in food by cooking at home more often this week.",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark.withOpacity(0.8),
                            ),
                          ),
                        ],
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

  Widget _buildChatOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleAIChat,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Chat header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.smart_toy_outlined,
                          color: AppTheme.primaryEmerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Financial Assistant",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleAIChat,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.isEmpty ? 1 : _messages.length,
                    itemBuilder: (context, index) {
                      // Show welcome message if no messages yet
                      if (_messages.isEmpty) {
                        return _buildWelcomeMessage();
                      }
                      
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                
                // Chat input
                _buildChatInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "I'm your financial assistant.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "I can help you with budgeting, savings goals, and financial insights. How can I assist you today?",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textDark.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip("Create a budget"),
              _buildSuggestionChip("Analyze my spending"),
              _buildSuggestionChip("How to save more?"),
              _buildSuggestionChip("Financial tips"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _handleQuickAction(text);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryEmerald.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryEmerald,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
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
                      fontSize: 14,
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.smart_toy_outlined,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildUserAvatarBubble() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.accentPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 18,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}

// Improved Analytics Screen with proper charts
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Sample data for charts
  final List<SpendingCategory> _spendingCategories = [
    SpendingCategory(name: 'Food', amount: 5600, color: AppTheme.primaryEmerald),
    SpendingCategory(name: 'Transport', amount: 2400, color: AppTheme.primaryBlue),
    SpendingCategory(name: 'Entertainment', amount: 1200, color: AppTheme.accentIndigo),
    SpendingCategory(name: 'Shopping', amount: 3200, color: AppTheme.accentPurple),
    SpendingCategory(name: 'Bills', amount: 4800, color: AppTheme.info),
  ];

  final List<double> _weeklySavings = [300, 400, 250, 500, 600, 450, 700];
  final List<double> _weeklySpending = [700, 500, 900, 400, 600, 800, 300];
  
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _selectedPeriod = 'Week';
  int _selectedChartIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Card
          _buildFinancialSummaryCard(),
          const SizedBox(height: 24),
          
          // Spending Trends with Improved Charts
          _buildSpendingTrendsCard(),
          const SizedBox(height: 24),
          
          // Category Breakdown with Donut Chart
          _buildCategoryBreakdownCard(),
          const SizedBox(height: 24),
          
          // Transaction History
          _buildTransactionHistoryCard(),
          const SizedBox(height: 24),
          
          // Financial Health Score
          _buildFinancialHealthCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.accentIndigo,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "July 2025",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Text(
                "Monthly Summary",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                title: "Income",
                amount: "45,000",
                iconData: Icons.arrow_upward,
                color: Colors.green,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              _buildSummaryItem(
                title: "Expenses",
                amount: "25,000",
                iconData: Icons.arrow_downward,
                color: Colors.redAccent,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              _buildSummaryItem(
                title: "Savings",
                amount: "20,000",
                iconData: Icons.savings_outlined,
                color: Colors.amberAccent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Progress indicator for monthly budget
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Monthly Budget",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: 0.5,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "KES 25,000 of KES 50,000 (50%)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // Open budget details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  "Details",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String amount,
    required IconData iconData,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              iconData,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "KES $amount",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingTrendsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Spending Trends",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Period selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                underline: const SizedBox(),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'Week', child: Text('Weekly')),
                  DropdownMenuItem(value: 'Month', child: Text('Monthly')),
                  DropdownMenuItem(value: 'Year', child: Text('Yearly')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Chart selector
              Row(
                children: [
                  _buildChartSelector(
                    index: 0, 
                    title: "Spending",
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 16),
                  _buildChartSelector(
                    index: 1, 
                    title: "Savings",
                    color: AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Chart visualization - improved
              SizedBox(
                height: 200,
                child: _selectedChartIndex == 0 
                    ? _buildSpendingChart() 
                    : _buildSavingsChart(),
              ),
              const SizedBox(height: 16),
              // Stats summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildChartStat(
                    title: "Total",
                    value: _selectedChartIndex == 0 ? "KES 25,000" : "KES 20,000",
                    iconData: _selectedChartIndex == 0 ? Icons.money_off : Icons.savings,
                    color: _selectedChartIndex == 0 ? AppTheme.error : AppTheme.success,
                  ),
                  _buildChartStat(
                    title: "Average",
                    value: _selectedChartIndex == 0 ? "KES 3,571/day" : "KES 2,857/day",
                    iconData: Icons.trending_up,
                    color: AppTheme.info,
                  ),
                  _buildChartStat(
                    title: _selectedChartIndex == 0 ? "Highest" : "Best",
                    value: _selectedChartIndex == 0 ? "Friday" : "Saturday",
                    iconData: Icons.star,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartSelector({
    required int index,
    required String title,
    required Color color,
  }) {
    final isSelected = _selectedChartIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedChartIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                index == 0 ? Icons.show_chart : Icons.savings_outlined,
                color: isSelected ? color : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingChart() {
    // Improved chart implementation
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: BarChartPainter(
        values: _weeklySpending,
        labels: _weekDays,
        barColor: AppTheme.error,
        showValues: true,
      ),
    );
  }

  Widget _buildSavingsChart() {
    // Improved chart implementation
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: BarChartPainter(
        values: _weeklySavings,
        labels: _weekDays,
        barColor: AppTheme.success,
        showValues: true,
      ),
    );
  }

  Widget _buildChartStat({
    required String title,
    required String value,
    required IconData iconData,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final totalSpending = _spendingCategories.fold(
      0.0, (sum, category) => sum + category.amount);
      
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category Breakdown",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Donut chart - improved implementation
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          categories: _spendingCategories,
                          totalAmount: totalSpending,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        Text(
                          "KES ${NumberFormat("#,##0").format(totalSpending)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Responsive Legend using GridView
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _spendingCategories.length,
                itemBuilder: (context, index) {
                  final category = _spendingCategories[index];
                  final percentage = (category.amount / totalSpending) * 100;
                  
                  return Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "KES ${NumberFormat("#,##0").format(category.amount)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                                Text(
                                  "${percentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: category.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistoryCard() {
    // Sample transactions
    final List<Map<String, dynamic>> transactions = [
      {
        'title': 'Grocery Shopping',
        'amount': -2300,
        'date': 'Today, 10:30 AM',
        'category': 'Food',
        'icon': Icons.shopping_basket,
        'color': AppTheme.primaryEmerald,
      },
      {
        'title': 'Uber Ride',
        'amount': -450,
        'date': 'Yesterday, 6:15 PM',
        'category': 'Transport',
        'icon': Icons.directions_car,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Salary Deposit',
        'amount': 45000,
        'date': 'Jul 15, 9:00 AM',
        'category': 'Income',
        'icon': Icons.account_balance,
        'color': AppTheme.success,
      },
      {
        'title': 'Netflix Subscription',
        'amount': -1100,
        'date': 'Jul 14, 3:22 PM',
        'category': 'Entertainment',
        'icon': Icons.movie,
        'color': AppTheme.accentIndigo,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all transactions
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryEmerald,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text("See All"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isIncome = transaction['amount'] > 0;
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transaction['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    transaction['icon'],
                    color: transaction['color'],
                    size: 24,
                  ),
                ),
                title: Text(
                  transaction['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "${transaction['category']} • ${transaction['date']}",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  "${isIncome ? '+' : ''}KES ${NumberFormat("#,##0").format(transaction['amount'].abs())}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppTheme.success : AppTheme.textDark,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHealthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Financial Health Score",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "78/100",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.78,
              backgroundColor: AppTheme.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.success),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 24),
          // Make health score items responsive
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final items = [
                {
                  'title': 'Savings Rate',
                  'score': 'Good',
                  'percentage': 85,
                  'color': AppTheme.success,
                },
                {
                  'title': 'Spending Habits',
                  'score': 'Fair',
                  'percentage': 65,
                  'color': AppTheme.warning,
                },
                {
                  'title': 'Budget Adherence',
                  'score': 'Great',
                  'percentage': 90,
                  'color': AppTheme.success,
                },
              ];
              
              final item = items[index];
              
              return Column(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: (item['percentage'] as int).toDouble() / 100,
                            strokeWidth: 6,
                            backgroundColor: AppTheme.backgroundLight,
                            valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                          ),
                        ),
                        Text(
                          "${item['percentage']}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['score'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: item['color'] as Color,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // AI recommendation with improved layout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: AppTheme.info,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI Recommendation",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Increase your emergency fund savings to improve your financial health score. Aim for at least 3 months of expenses.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textDark.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Improved Chart Painters
class BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final bool showValues;

  BarChartPainter({
    required this.values,
    required this.labels,
    required this.barColor,
    this.showValues = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = size.width / values.length - 12;
    final double maxValue = values.reduce((curr, next) => curr > next ? curr : next);
    final double heightRatio = size.height / (maxValue * 1.2);
    
    // Draw horizontal grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 5; i++) {
      final double y = size.height - (size.height / 5 * i);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    for (int i = 0; i < values.length; i++) {
      final double barHeight = values[i] * heightRatio;
      final double x = i * (barWidth + 12) + 6;
      final double y = size.height - barHeight;
      
      // Draw bar with gradient
      final Paint barPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            barColor.withOpacity(0.7),
            barColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));
      
      final RRect barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );
      
      canvas.drawRRect(barRect, barPaint);
      
      // Draw value on top of bar if showValues is true
      if (showValues) {
        final TextPainter valueTextPainter = TextPainter(
          text: TextSpan(
            text: values[i].toStringAsFixed(0),
            style: TextStyle(
              color: barColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        
        valueTextPainter.layout();
        valueTextPainter.paint(
          canvas, 
          Offset(
            x + (barWidth - valueTextPainter.width) / 2,
            y - valueTextPainter.height - 4,
          ),
        );
      }
      
      // Draw x-axis label
      final TextPainter labelTextPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: AppTheme.textMedium,
            fontSize: 10,
          ),
        ),
      );
      
      labelTextPainter.layout();
      labelTextPainter.paint(
        canvas, 
        Offset(
          x + (barWidth - labelTextPainter.width) / 2,
          size.height + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DonutChartPainter extends CustomPainter {
  final List<SpendingCategory> categories;
  final double totalAmount;

  DonutChartPainter({
    required this.categories,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    double startAngle = -math.pi / 2; // Start from top (12 o'clock position)
    
    // Add animation effect with shadows
    for (var category in categories) {
      final double sweepAngle = 2 * math.pi * (category.amount / totalAmount);
      
      final Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..color = category.color;
      
      // Draw segment with anti-aliasing
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Add subtle shadow for 3D effect
      final Paint shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = category.color.withOpacity(0.3)
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Draw hole in center to make it a donut chart
    final Paint holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    
    // Draw shadow for inner hole
    final Paint holeShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius * 0.6, holePaint);
    canvas.drawCircle(center, radius * 0.6, holeShadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Data Models
class SpendingCategory {
  final String name;
  final double amount;
  final Color color;

  SpendingCategory({
    required this.name,
    required this.amount,
    required this.color,
  });
}

class AIMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIInsight {
  final String title;
  final String description;
  final IconData iconData;
  final Color color;
  final DateTime timestamp;
  final String actionText;

  AIInsight({
    required this.title,
    required this.description,
    required this.iconData,
    required this.color,
    required this.timestamp,
    required this.actionText,
  });
}

class SavingGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final IconData iconData;
  final Color color;

  SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.iconData,
    required this.color,
  });

  SavingGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    IconData? iconData,
    Color? color,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      iconData: iconData ?? this.iconData,
      color: color ?? this.color,
    );
  }
}