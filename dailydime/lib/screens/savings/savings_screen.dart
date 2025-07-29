import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/providers/savings_provider.dart';
import 'package:dailydime/screens/savings/create_goal_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/widgets/charts/circular_percent_indicator.dart';
import 'package:dailydime/widgets/charts/linear_percent_indicator.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/services/storage_service.dart';
import 'dart:math' as math;

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({Key? key}) : super(key: key);

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final accentColor = const Color(0xFF26D07C); // Emerald green

  String _selectedCategory = 'All';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes
    _tabController.addListener(() {
      setState(() {});
    });

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final savingsProvider = Provider.of<SavingsProvider>(
      context,
      listen: false,
    );

    // First try to fetch from local storage for immediate display
    // await savingsProvider.fetchSavingsGoalsFromLocal();

    // Then fetch from remote to ensure data is up-to-date
    await savingsProvider.fetchSavingsGoals();

    // Save the fetched goals to local storage for offline access
    // await savingsProvider.syncGoalsToLocalStorage();

    // Fetch other data
    await savingsProvider.getAISavingSuggestion();
    await savingsProvider.fetchSavingsChallenges();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await _fetchData();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, child) {
        final isLoading = savingsProvider.isLoading;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: accentColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Floating Header with Total Savings
                  SliverToBoxAdapter(child: _buildHeader(savingsProvider)),

                  // Main content
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          // AI Smart Save Suggestion
                          if (savingsProvider.aiSavingSuggestion != null)
                            _buildAISuggestion(context, savingsProvider),

                          // Tab Bar with no divider
                          Container(
                            margin: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: accentColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              dividerColor:
                                  Colors.transparent, // Remove divider
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[700],
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                                fontFamily: 'Dmsans'
                              ),
                              tabs: const [
                                Tab(text: 'Savings Goals', height: 50),
                                Tab(text: 'Challenges', height: 50),
                              ],
                            ),
                          ),

                          // Tab Bar View
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Savings Goals Tab
                                _buildSavingsGoalsTab(savingsProvider),

                                // Challenges Tab
                                _buildChallengesTab(savingsProvider),
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
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGoalScreen(),
                ),
              ).then((_) => _fetchData()); // Refresh after returning
            },
            backgroundColor: accentColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'New Goal',
              style: TextStyle(color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SavingsProvider savingsProvider) {
    final totalSavings = savingsProvider.totalSavingsAmount;
    final mtdSavings = savingsProvider.mtdSavingsAmount;
    final avgDailySavings = savingsProvider.averageDailySavings;
    final activeGoals = savingsProvider.activeGoals.length;

    return Container(
      height: 280,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Stack(
        children: [
          // Background card with pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: AssetImage('assets/images/patter12.png'),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor,
                    accentColor.withOpacity(0.8),
                    accentColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Savings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            // Toggle notifications
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifications toggled'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                          iconSize: 24,
                        ),
                        IconButton(
                          onPressed: () {
                            // Show options menu
                            _showOptionsMenu(context);
                          },
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Total savings amount with visual element
                Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 40.0,
                      lineWidth: 8.0,
                      animation: true,
                      percent: _calculateGrowthPercentage(totalSavings),
                      center: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.savings_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Savings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(totalSavings)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.trending_up,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '12.5%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Savings metrics row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSavingsMetric(
                      'This Month',
                      '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(mtdSavings)}',
                      Icons.calendar_today,
                    ),
                    _buildSavingsMetric(
                      'Total Goals',
                      '$activeGoals Active',
                      Icons.flag,
                    ),
                    _buildSavingsMetric(
                      'Average',
                      '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(avgDailySavings)}/day',
                      Icons.trending_up,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestion(
    BuildContext context,
    SavingsProvider savingsProvider,
  ) {
    final suggestion = savingsProvider.aiSavingSuggestion;
    if (suggestion == null) return const SizedBox();

    // Safe data extraction with proper type checking
    final dynamic recommendedGoalData = suggestion['recommendedGoal'];
    final String targetGoalName = recommendedGoalData is String
        ? recommendedGoalData
        : (recommendedGoalData is List && recommendedGoalData.isNotEmpty
              ? recommendedGoalData.first.toString()
              : 'emergency');

    final dynamic savingAmountData = suggestion['savingAmount'];
    final double savingAmount = savingAmountData is double
        ? savingAmountData
        : (savingAmountData is int
              ? savingAmountData.toDouble()
              : (savingAmountData is String
                    ? double.tryParse(savingAmountData) ?? 0.0
                    : 0.0));

    final dynamic reasonData = suggestion['reason'];
    final String reason = reasonData is String
        ? reasonData
        : (reasonData is List && reasonData.isNotEmpty
              ? reasonData.first.toString()
              : 'You have extra funds available.');

    // Find target goal with proper null checking
    final targetGoal = savingsProvider.savingsGoals.firstWhere(
      (g) =>
          g.title.toLowerCase() == targetGoalName.toLowerCase() ||
          (targetGoalName == 'emergency' &&
              g.category == SavingsGoalCategory.emergency),
      orElse: () => savingsProvider.savingsGoals.isNotEmpty
          ? savingsProvider.savingsGoals.first
          : SavingsGoal(
              title: 'New Goal',
              targetAmount: 10000,
              targetDate: DateTime.now().add(const Duration(days: 90)),
              category: SavingsGoalCategory.other,
              iconAsset: 'savings',
              color: accentColor,
              dailyTarget: null,
              weeklyTarget: null,
              priority: 'medium',
              isRecurring: false,
              reminderFrequency: 'weekly', icon: null,
            ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF20B2AA), // Celestial teal
            accentColor, // Your emerald green (0xFF26D07C)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF20B2AA,
            ).withOpacity(0.3), // Celestial teal shadow
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background animation - made larger
          Positioned(
            right: 10,
            top: -20,
            child: Opacity(
              opacity: 0.4,
              child: Lottie.asset(
                'assets/animations/money_coins.json',
                width: 200,
                height: 200,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI Smart Saving',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'You can save ${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(savingAmount)} today! $reason',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Add to: ${targetGoal.title}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          savingsProvider.dismissAISuggestion();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          savingsProvider.applyAISavingSuggestion(
                            targetGoal.id,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'Save ${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(savingAmount)}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () {
                savingsProvider.dismissAISuggestion();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalsTab(SavingsProvider savingsProvider) {
    final List<String> categories = ['All', 'Active', 'Completed', 'Upcoming'];

    List<SavingsGoal> filteredGoals;
    switch (_selectedCategory) {
      case 'Active':
        filteredGoals = savingsProvider.activeGoals;
        break;
      case 'Completed':
        filteredGoals = savingsProvider.completedGoals;
        break;
      case 'Upcoming':
        filteredGoals = savingsProvider.upcomingGoals;
        break;
      case 'All':
      default:
        filteredGoals = savingsProvider.savingsGoals;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category selection
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: !isSelected
                          ? Border.all(color: Colors.grey[300]!)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Goals list
          Expanded(
            child: savingsProvider.isLoading
                ? Center(child: _buildLoadingAnimation())
                : filteredGoals.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      return _buildGoalCard(goal);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab(SavingsProvider savingsProvider) {
    final challenges = savingsProvider.savingsChallenges;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenges introduction
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Savings Challenges',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Join fun savings challenges to boost your savings with a structured approach!',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Popular challenges section
          const Text(
            'Popular Challenges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Challenges list
          Expanded(
            child: savingsProvider.isLoading
                ? Center(child: _buildLoadingAnimation())
                : challenges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/empty_challenges.json',
                          height: 150,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No challenges available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      // Safe extraction for all challenge data
                      final dynamic titleData = challenge['title'];
                      String title = titleData is String
                          ? titleData
                          : (titleData is List && titleData.isNotEmpty
                                ? titleData.first.toString()
                                : 'Challenge');

                      final dynamic descData = challenge['description'];
                      String description = descData is String
                          ? descData
                          : (descData is List && descData.isNotEmpty
                                ? descData.first.toString()
                                : 'Join this savings challenge');

                      final dynamic iconData = challenge['icon'];
                      String iconName = iconData is String
                          ? iconData
                          : (iconData is List && iconData.isNotEmpty
                                ? iconData.first.toString()
                                : 'emoji_events');

                      final dynamic colorData = challenge['color'];
                      int colorValue = colorData is int
                          ? colorData
                          : (colorData is String
                                ? int.tryParse(colorData) ?? 0xFF26D07C
                                : 0xFF26D07C);

                      final dynamic participantsData =
                          challenge['participants'];
                      int participants = participantsData is int
                          ? participantsData
                          : (participantsData is String
                                ? int.tryParse(participantsData) ?? 0
                                : 0);

                      final dynamic popularData = challenge['isPopular'];
                      bool isPopular = popularData is bool
                          ? popularData
                          : (popularData is String
                                ? (popularData.toLowerCase() == 'true' ||
                                      popularData.toLowerCase() == 'yes')
                                : false);

                      final dynamic aiData = challenge['isAiGenerated'];
                      bool isAiGenerated = aiData is bool
                          ? aiData
                          : (aiData is String
                                ? (aiData.toLowerCase() == 'true' ||
                                      aiData.toLowerCase() == 'yes')
                                : false);

                      return _buildChallengeCard(
                        title: title,
                        description: description,
                        icon: _getIconData(iconName),
                        color: Color(colorValue),
                        participants: participants,
                        isPopular: isPopular,
                        isAiGenerated: isAiGenerated,
                      );
                    },
                  ),
          ),

          // Custom challenge button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomButton(
              text: 'Create Custom Challenge',
              onPressed: () {
                // Show challenge creation modal
                _showCreateChallengeModal(context);
              },
              isSmall: false,
              isOutlined: true,
              icon: Icons.add_circle_outline,
              buttonColor: Colors.blue, // or any other MaterialColor
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    // Calculate percentage and days left
    final percentage = goal.progressPercentage;
    final daysLeft = goal.daysLeft;

    // Determine status color
    Color statusColor;
    if (goal.status == SavingsGoalStatus.completed) {
      statusColor = Colors.green;
    } else if (!goal.isOnTrack) {
      statusColor = Colors.red;
    } else {
      statusColor = accentColor;
    }

    return GestureDetector(
      onTap: () => _showSavingsDetails(context, goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with icon and title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Goal icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: goal.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getIconData(goal.iconAsset),
                      color: goal.color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Goal info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal.isCompleted
                              ? 'Completed on ${DateFormat('d MMM y').format(goal.targetDate)}'
                              : 'Target date: ${DateFormat('d MMM y').format(goal.targetDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick add button
                  if (goal.status != SavingsGoalStatus.completed)
                    Container(
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: accentColor),
                        onPressed: () =>
                            _showAddContributionModal(context, goal),
                      ),
                    ),

                  // Options menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateGoalScreen(existingGoal: goal),
                          ),
                        ).then((_) => _fetchData()); // Refresh after editing
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, goal);
                      } else if (value == 'insights') {
                        _showGoalInsights(context, goal);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Goal'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'insights',
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 18),
                            SizedBox(width: 8),
                            Text('AI Insights'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(goal.currentAmount)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(goal.targetAmount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress bar
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: percentage.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    progressColor: statusColor,
                    barRadius: const Radius.circular(8),
                    padding: EdgeInsets.zero,
                    animation: true,
                    animationDuration: 1000,
                  ),

                  const SizedBox(height: 12),

                  // Status footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(percentage * 100).toInt()}% ${goal.isOnTrack ? 'On Track' : 'Behind'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (goal.isAiSuggested)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI Suggested',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (!goal.isCompleted)
                        Row(
                          children: [
                            Icon(
                              Icons.timelapse,
                              size: 14,
                              color: daysLeft < 7
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              daysLeft <= 0
                                  ? 'Overdue!'
                                  : '$daysLeft days left',
                              style: TextStyle(
                                fontSize: 13,
                                color: daysLeft < 7
                                    ? Colors.red
                                    : Colors.grey[600],
                                fontWeight: daysLeft < 7
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int participants,
    required bool isPopular,
    bool isAiGenerated = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isAiGenerated)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.purple,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Text(
                          'Popular',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$participants participants',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _showJoinChallengeModal(
                      context,
                      title,
                      description,
                      color,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Join Challenge',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_goals.json',
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'No savings goals yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first savings goal to start tracking your progress',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Create Goal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGoalScreen(),
                ),
              ).then((_) => _fetchData()); // Refresh after creating
            },
            isSmall: true,
            buttonColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Lottie.asset(
      'assets/animations/loading.json',
      height: 120,
      width: 120,
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'laptop':
        return Icons.laptop;
      case 'beach_access':
        return Icons.beach_access;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'phone_android':
        return Icons.phone_android;
      case 'school':
        return Icons.school;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'attach_money':
        return Icons.attach_money;
      case 'account_balance':
        return Icons.account_balance;
      case 'trending_up':
        return Icons.trending_up;
      case 'calendar_month':
        return Icons.calendar_month;
      case 'timer':
        return Icons.timer;
      case 'percent':
        return Icons.percent;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'money_off':
        return Icons.money_off;
      default:
        return Icons.savings;
    }
  }

  void _showSavingsDetails(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSavingsDetailsSheet(context, goal),
    );
  }

  Widget _buildSavingsDetailsSheet(BuildContext context, SavingsGoal goal) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [goal.color, goal.color.withOpacity(0.8)],
              ),
            ),
            child: Column(
              children: [
                // Pull handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 16),

                // Goal info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getIconData(goal.iconAsset),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (goal.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              goal.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress indicator
                Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 40.0,
                      lineWidth: 8.0,
                      animation: true,
                      percent: goal.progressPercentage.clamp(0.0, 1.0),
                      center: Text(
                        '${(goal.progressPercentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const Text(
                                'Target',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(goal.currentAmount)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(goal.targetAmount)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  goal.isCompleted
                                      ? 'Completed!'
                                      : (goal.daysLeft <= 0
                                            ? 'Overdue!'
                                            : '${goal.daysLeft} days left'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (goal.recommendedWeeklySaving != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(goal.recommendedWeeklySaving)}/week',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs and content
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Transactions'),
                      Tab(text: 'AI Insights'),
                    ],
                    labelColor: goal.color,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: goal.color,
                    dividerHeight: 0, // Remove divider line
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Transactions tab
                        _buildTransactionsTab(goal),

                        // AI Insights tab
                        _buildInsightsTab(goal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          if (!goal.isCompleted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateGoalScreen(existingGoal: goal),
                          ),
                        ).then((_) => _fetchData()); // Refresh after editing
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddContributionModal(context, goal);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Money'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goal.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  Widget _buildTransactionsTab(SavingsGoal goal) {
    final transactions = goal.transactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty_transactions.json',
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first contribution to start tracking',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction =
            transactions[transactions.length - 1 - index]; // Reverse order
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: goal.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward, color: goal.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.note.isNotEmpty
                          ? transaction.note
                          : 'Contribution',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM y, h:mm a').format(transaction.date),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                '+ ${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: goal.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab(SavingsGoal goal) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<SavingsProvider>(
        context,
        listen: false,
      ).getGoalInsights(goal.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset('assets/animations/loading.json', height: 100),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Could not load insights',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final insights = snapshot.data!;

        // Safe extraction for insights data
        final dynamic motivationalData = insights['motivationalMessage'];
        final motivationalMessage = motivationalData is String
            ? motivationalData
            : (motivationalData is List && motivationalData.isNotEmpty
                  ? motivationalData.first.toString()
                  : 'Keep going!');

        final dynamic adviceData = insights['practicalAdvice'];
        final practicalAdvice = adviceData is String
            ? adviceData
            : (adviceData is List && adviceData.isNotEmpty
                  ? adviceData.first.toString()
                  : 'Save consistently to reach your goal.');

        final dynamic adjustmentData = insights['needsAdjustment'];
        final needsAdjustment = adjustmentData is bool
            ? adjustmentData
            : (adjustmentData is String
                  ? (adjustmentData.toLowerCase() == 'true' ||
                        adjustmentData.toLowerCase() == 'yes')
                  : false);

        final dynamic forecastData = insights['forecast'];
        final forecast = forecastData is String
            ? forecastData
            : (forecastData is List && forecastData.isNotEmpty
                  ? forecastData.first.toString()
                  : 'on track');

        final dynamic weeklyData = insights['weeklySavingsNeeded'];
        final weeklySavingsNeeded = weeklyData is double
            ? weeklyData
            : (weeklyData is int
                  ? weeklyData.toDouble()
                  : (weeklyData is String
                        ? double.tryParse(weeklyData) ??
                              (goal.dailySavingNeeded * 7)
                        : (goal.dailySavingNeeded * 7)));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInsightCard(
                title: 'AI Forecast',
                content:
                    'Based on your current savings pattern, you are $forecast to reach your goal.',
                icon: Icons.trending_up,
                color: forecast.contains('track')
                    ? Colors.green
                    : Colors.orange,
                animation: 'assets/animations/forecast.json',
              ),

              _buildInsightCard(
                title: 'Weekly Target',
                content:
                    'You should save ${AppConfig.currencySymbol} ${NumberFormat("#,##0").format(weeklySavingsNeeded)} per week to reach your goal on time.',
                icon: Icons.calendar_today,
                color: const Color.fromARGB(255, 47, 245, 202),
              ),

              _buildInsightCard(
                title: 'Motivation',
                content: motivationalMessage,
                icon: Icons.emoji_emotions,
                color: Colors.amber,
                animation: 'assets/animations/motivation.json',
              ),

              _buildInsightCard(
                title: 'Smart Advice',
                content: practicalAdvice,
                icon: Icons.lightbulb,
                color: Colors.purple,
              ),

              if (needsAdjustment)
                _buildInsightCard(
                  title: 'Goal Adjustment Needed',
                  content:
                      'Your goal may need adjustment. Consider extending the deadline or adjusting the target amount.',
                  icon: Icons.build,
                  color: Colors.red,
                  isWarning: true,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    String? animation,
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red[50] : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? Colors.red[200]! : color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          animation != null
              ? SizedBox(
                  width: 50,
                  height: 50,
                  child: Lottie.asset(animation, fit: BoxFit.cover),
                )
              : Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
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
                    color: isWarning ? Colors.red : color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContributionModal(BuildContext context, SavingsGoal goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: goal.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getIconData(goal.iconAsset),
                      color: goal.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Contribution',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.title,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: AppConfig.currencySymbol + ' ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: goal.color, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      final savingsProvider = Provider.of<SavingsProvider>(
                        context,
                        listen: false,
                      );
                      savingsProvider
                          .addContribution(goal.id, amount, noteController.text)
                          .then((_) {
                            // After adding contribution, fetch the updated data
                            _fetchData();
                          });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goal.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Contribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal?'),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              final savingsProvider = Provider.of<SavingsProvider>(
                context,
                listen: false,
              );
              savingsProvider.deleteSavingsGoal(goal.id).then((_) {
                // After deleting, fetch the updated data
                _fetchData();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGoalInsights(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Expanded(child: _buildInsightsTab(goal)),
          ],
        ),
      ),
    );
  }

  void _showCreateChallengeModal(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    bool useAI = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Challenge',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Challenge Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Challenge Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Use AI to enhance challenge',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const Spacer(),
                    Switch(
                      value: useAI,
                      onChanged: (value) {
                        setModalState(() {
                          useAI = value;
                        });
                      },
                      activeColor: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final savingsProvider = Provider.of<SavingsProvider>(
                        context,
                        listen: false,
                      );
                      savingsProvider
                          .createSavingsChallenge(
                            title: titleController.text,
                            description: descriptionController.text,
                            useAI: useAI,
                          )
                          .then((_) {
                            // After creating, fetch the updated data
                            _fetchData();
                          });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Create Challenge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJoinChallengeModal(
    BuildContext context,
    String title,
    String description,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.emoji_events, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Join Challenge',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Lottie.asset('assets/animations/challenge.json', height: 120),
            const SizedBox(height: 20),
            const Text(
              'Challenge Rules:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Save the specified amount consistently\n• Track your progress in the app\n• Complete within the timeframe\n• Share your success with the community',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final savingsProvider = Provider.of<SavingsProvider>(
                        context,
                        listen: false,
                      );
                      savingsProvider.joinSavingsChallenge(title).then((_) {
                        // After joining, fetch the updated data
                        _fetchData();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Join Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Icon(Icons.refresh, color: accentColor),
            title: const Text('Refresh Data'),
            onTap: () {
              Navigator.pop(context);
              _refreshData();
            },
          ),
          ListTile(
            leading: Icon(Icons.sync, color: accentColor),
            title: const Text('Sync with Cloud'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing with cloud...')),
              );
              _fetchData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  double _calculateGrowthPercentage(double amount) {
    // This is a placeholder calculation
    // In a real app, you would calculate based on previous data
    return math.min(amount / 20000, 1.0);
  }
}
