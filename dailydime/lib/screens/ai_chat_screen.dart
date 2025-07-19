// lib/screens/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailydime/config/theme.dart';
import 'package:dailydime/screens/analytics_screen.dart';
import 'package:dailydime/widgets/charts/spending_chart.dart';
import 'package:dailydime/widgets/charts/progress_chart.dart';
import 'package:dailydime/widgets/common/custom_text_field.dart';
import 'package:intl/intl.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  // Selected AI feature
  String _selectedAIFeature = 'assistant';
  
  // Tab controller for AI features
  late TabController _tabController;
  
  // Controllers for saving suggestion amount
  final TextEditingController _savingAmountController = TextEditingController(text: '30');
  final TextEditingController _savingReasonController = TextEditingController();
  
  // Smart suggestions
  final List<String> _smartSuggestions = [
    'How much can I save this month?',
    'Analyze my spending habits',
    'Create a budget for weekend trip',
    'How can I reduce my food expenses?',
    'Tips to save for emergency fund',
  ];
  
  // AI insights
  final List<AIInsight> _aiInsights = [
    AIInsight(
      title: 'Spending Pattern',
      description: 'You spend 35% more on weekends. Consider planning your weekend activities to reduce impulse spending.',
      icon: Icons.insights,
      iconColor: AppTheme.primaryEmerald,
    ),
    AIInsight(
      title: 'Saving Opportunity',
      description: 'Based on your coffee purchases, switching to homemade coffee could save you KES 3,600 monthly.',
      icon: Icons.savings,
      iconColor: AppTheme.primaryBlue,
    ),
    AIInsight(
      title: 'Budget Alert',
      description: 'You\'ve reached 85% of your entertainment budget with 10 days remaining. Consider adjusting your spending.',
      icon: Icons.warning_amber,
      iconColor: AppTheme.warning,
    ),
  ];
  
  // Smart saving suggestions
  final List<SmartSaving> _smartSavings = [
    SmartSaving(
      title: 'Skip takeout lunch',
      amount: 350,
      savingsGoal: 'Weekend Trip',
      icon: Icons.fastfood,
      color: AppTheme.primaryEmerald,
    ),
    SmartSaving(
      title: 'Use public transport today',
      amount: 200,
      savingsGoal: 'Emergency Fund',
      icon: Icons.directions_bus,
      color: AppTheme.primaryBlue,
    ),
    SmartSaving(
      title: 'Make coffee at home',
      amount: 120,
      savingsGoal: 'New Headphones',
      icon: Icons.coffee,
      color: AppTheme.accentIndigo,
    ),
  ];
  
  // Bill reminders
  final List<BillReminder> _billReminders = [
    BillReminder(
      title: 'Electricity Bill',
      amount: 1200,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      icon: Icons.electric_bolt,
      color: AppTheme.warning,
    ),
    BillReminder(
      title: 'Internet Subscription',
      amount: 2500,
      dueDate: DateTime.now().add(const Duration(days: 8)),
      icon: Icons.wifi,
      color: AppTheme.primaryBlue,
    ),
    BillReminder(
      title: 'Netflix Subscription',
      amount: 900,
      dueDate: DateTime.now().add(const Duration(days: 12)),
      icon: Icons.tv,
      color: AppTheme.error,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
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
    _savingAmountController.dispose();
    _savingReasonController.dispose();
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
  
  void _handleAcceptSaving(SmartSaving saving) {
    // In a real app, this would save the transaction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved KES ${saving.amount} toward ${saving.savingsGoal}!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _handleSavingSuggestion() {
    if (_savingAmountController.text.isEmpty || _savingReasonController.text.isEmpty) {
      return;
    }
    
    final amount = int.tryParse(_savingAmountController.text) ?? 0;
    if (amount <= 0) return;
    
    // In a real app, this would save the suggestion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custom saving of KES $amount added for ${_savingReasonController.text}'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Clear fields
    _savingAmountController.text = '30';
    _savingReasonController.clear();
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DailyDime AI",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryEmerald,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primaryEmerald,
          tabs: const [
            Tab(text: "AI Features", icon: Icon(Icons.smart_toy)),
            Tab(text: "Analytics", icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAIFeaturesView(),
          AnalyticsScreen(),
        ],
      ),
    );
  }

  Widget _buildAIFeaturesView() {
    return Column(
      children: [
        // AI Features Selection
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildFeatureButton(
                  'assistant',
                  'AI Assistant',
                  Icons.smart_toy,
                ),
                _buildFeatureButton(
                  'insights', 
                  'Insights',
                  Icons.insights,
                ),
                _buildFeatureButton(
                  'savings', 
                  'Smart Savings',
                  Icons.savings,
                ),
                _buildFeatureButton(
                  'bills', 
                  'Bill Reminders',
                  Icons.receipt_long,
                ),
                _buildFeatureButton(
                  'custom', 
                  'Custom Saving',
                  Icons.add_circle_outline,
                ),
              ],
            ),
          ),
        ),
        
        // Main Content Area
        Expanded(
          child: _getSelectedFeatureWidget(),
        ),
      ],
    );
  }
  
  Widget _buildFeatureButton(String feature, String label, IconData icon) {
    final isSelected = _selectedAIFeature == feature;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAIFeature = feature;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryEmerald : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryEmerald.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textMedium,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getSelectedFeatureWidget() {
    switch (_selectedAIFeature) {
      case 'assistant':
        return _buildAssistantView();
      case 'insights':
        return _buildInsightsView();
      case 'savings':
        return _buildSmartSavingsView();
      case 'bills':
        return _buildBillRemindersView();
      case 'custom':
        return _buildCustomSavingView();
      default:
        return _buildAssistantView();
    }
  }
  
  Widget _buildAssistantView() {
    return Column(
      children: [
        // Smart suggestions
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ask me anything about your finances",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _smartSuggestions.map((suggestion) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _messageController.text = suggestion;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3)),
                        ),
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textDark.withOpacity(0.8),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        // Chat messages
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
        
        // Chat input
        _buildChatInput(),
      ],
    );
  }
  
  Widget _buildInsightsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "AI Financial Insights",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Personalized insights based on your financial behavior",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          
          // AI Insights
          ..._aiInsights.map((insight) => _buildInsightCard(insight)),
          const SizedBox(height: 20),
          
          // Weekly spending report
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Weekly Spending Report",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "12% ↓",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart(
                      weeklyData: [8500, 6300, 9200, 5600, 7800, 4500, 6200],
                      title: "",
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "AI Analysis: Your spending is trending downward! You've spent less this week compared to your weekly average. Your biggest expense category was food at 32% of total spending.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Budget allocation recommendation
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recommended Budget Allocation",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildBudgetAllocationItem(
                        "Needs",
                        50,
                        AppTheme.primaryEmerald,
                      ),
                      _buildBudgetAllocationItem(
                        "Wants",
                        30,
                        AppTheme.primaryBlue,
                      ),
                      _buildBudgetAllocationItem(
                        "Savings",
                        20,
                        AppTheme.accentIndigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Based on the 50/30/20 rule and your monthly income of KES 45,000",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
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
  
  Widget _buildSmartSavingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Smart Saving Suggestions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "AI-powered suggestions to help you save more",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          
          // Smart savings suggestions
          ..._smartSavings.map((saving) => _buildSmartSavingCard(saving)),
          
          const SizedBox(height: 20),
          
          // Daily saving challenge
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryEmerald,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "7-Day Saving Challenge",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Save KES 100 each day for 7 days",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 3/7,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Day 3 of 7",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        "KES 300 saved",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Handle saving for the day
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('KES 100 saved for Day 3!'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Save Today's Amount"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillRemindersView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upcoming Bills & Payments",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "AI-organized reminders to help you avoid late fees",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          
          // Bill reminders
          ..._billReminders.map((bill) => _buildBillReminderCard(bill)),
          
          const SizedBox(height: 20),
          
          // Monthly bill summary
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monthly Bill Summary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Bills",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "KES 8,900",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Paid Bills",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "KES 3,400",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 3400/8900,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.success),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "AI Tip: Set aside KES 5,500 for remaining bills this month.",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMedium,
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
  
  Widget _buildCustomSavingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Create Custom Saving",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let AI help you find the perfect amount to save",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          
          // Custom saving form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Recommended Saving",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _savingAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "KES",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _savingReasonController,
                          decoration: InputDecoration(
                            labelText: "What are you saving for?",
                            hintText: "e.g., Coffee, Lunch, Transport",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleSavingSuggestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Save This Amount"),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            "AI Saving Insights",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          
          // Saving insights
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.primaryEmerald,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "If you save KES 30 daily",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                      children: [
                        const TextSpan(
                          text: "You'll save ",
                        ),
                        TextSpan(
                          text: "KES 900",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        const TextSpan(
                          text: " monthly and ",
                        ),
                        TextSpan(
                          text: "KES 10,950",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        const TextSpan(
                          text: " yearly. This is enough for a weekend trip to Mombasa in just 3 months!",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tips_and_updates,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Ways to save KES 30 daily",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSavingTipItem("Skip one soda or juice", "KES 40-80"),
                  _buildSavingTipItem("Make coffee at home instead of buying", "KES 100-150"),
                  _buildSavingTipItem("Walk short distances instead of taking a boda", "KES 50-100"),
                  _buildSavingTipItem("Bring lunch from home once a week", "KES 150-250"),
                ],
              ),
            ),
          ),
        ],
      ),
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
  
  Widget _buildInsightCard(AIInsight insight) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: insight.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                insight.icon,
                color: insight.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
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
  
  Widget _buildSmartSavingCard(SmartSaving saving) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: saving.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                saving.icon,
                color: saving.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saving.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                      children: [
                        const TextSpan(
                          text: "Save ",
                        ),
                        TextSpan(
                          text: "KES ${saving.amount}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        const TextSpan(
                          text: " toward ",
                        ),
                        TextSpan(
                          text: saving.savingsGoal,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _handleAcceptSaving(saving),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBillReminderCard(BillReminder bill) {
    final daysLeft = bill.dueDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bill.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                bill.icon,
                color: bill.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "KES ${bill.amount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUrgent ? AppTheme.error.withOpacity(0.1) : AppTheme.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Due in $daysLeft days",
                          style: TextStyle(
                            fontSize: 12,
                            color: isUrgent ? AppTheme.error : AppTheme.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Handle bill payment
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bill payment initiated for ${bill.title}'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Pay"),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetAllocationItem(String title, int percentage, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 8,
              ),
            ),
            child: Center(
              child: Text(
                "$percentage%",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "KES ${percentage * 450}",
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSavingTipItem(String tip, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.primaryEmerald,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryEmerald,
            ),
          ),
        ],
      ),
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

class AIInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  AIInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

class SmartSaving {
  final String title;
  final double amount;
  final String savingsGoal;
  final IconData icon;
  final Color color;

  SmartSaving({
    required this.title,
    required this.amount,
    required this.savingsGoal,
    required this.icon,
    required this.color,
  });
}

class BillReminder {
  final String title;
  final double amount;
  final DateTime dueDate;
  final IconData icon;
  final Color color;

  BillReminder({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.icon,
    required this.color,
  });
}