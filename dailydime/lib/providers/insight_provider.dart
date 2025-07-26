// lib/providers/insight_provider.dart

import 'package:flutter/material.dart';
import 'package:dailydime/services/appwrite_service.dart';
import 'package:dailydime/models/savings_goal.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/services/storage_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/ai_notification_service.dart';
import 'package:dailydime/models/insight_model.dart';

class InsightProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();
  final AiNotificationService _aiNotificationService = AiNotificationService();
  
  // Financial overview data
  double _totalSavings = 0.0;
  double _monthlySavings = 0.0;
  double _dailyAverage = 0.0;
  double _savingsGrowthPercentage = 0.0;
  int _activeGoalsCount = 0;
  int _financialHealthScore = 75;
  
  // Insights and analytics data
  List<Map<String, dynamic>> _aiInsights = [];
  List<Map<String, dynamic>> _topCategories = [];
  List<Map<String, dynamic>> _weeklySpending = [];
  List<Map<String, dynamic>> _activeGoals = [];
  String _spendingTrendInsight = '';
  String _goalTimelineInsight = '';
  
  // Income vs Expense data
  List<Map<String, dynamic>> _incomeVsExpense = [];
  String _incomeExpenseInsight = '';
  
  // Spending patterns
  List<Map<String, dynamic>> _spendingPatterns = [];
  
  // Spending heatmap
  List<Map<String, dynamic>> _spendingHeatmap = [];
  String _spendingHeatmapInsight = '';
  
  // Weekly trend
  Map<String, dynamic> _weeklyTrend = {};
  
  // Predicted spending
  List<Map<String, dynamic>> _predictedSpending = [];
  String _predictedSpendingInsight = '';
  
  // Getters
  double get totalSavings => _totalSavings;
  double get monthlySavings => _monthlySavings;
  double get dailyAverage => _dailyAverage;
  double get savingsGrowthPercentage => _savingsGrowthPercentage;
  int get activeGoalsCount => _activeGoalsCount;
  int get financialHealthScore => _financialHealthScore;
  List<Map<String, dynamic>> get aiInsights => _aiInsights;
  List<Map<String, dynamic>> get topCategories => _topCategories;
  List<Map<String, dynamic>> get weeklySpending => _weeklySpending;
  List<Map<String, dynamic>> get activeGoals => _activeGoals;
  String get spendingTrendInsight => _spendingTrendInsight;
  String get goalTimelineInsight => _goalTimelineInsight;
  List<Map<String, dynamic>> get incomeVsExpense => _incomeVsExpense;
  String get incomeExpenseInsight => _incomeExpenseInsight;
  List<Map<String, dynamic>> get spendingPatterns => _spendingPatterns;
  List<Map<String, dynamic>> get spendingHeatmap => _spendingHeatmap;
  String get spendingHeatmapInsight => _spendingHeatmapInsight;
  Map<String, dynamic> get weeklyTrend => _weeklyTrend;
  List<Map<String, dynamic>> get predictedSpending => _predictedSpending;
  String get predictedSpendingInsight => _predictedSpendingInsight;
  
  // Initialize and fetch all insights and analytics data
  Future<void> fetchInsights() async {
    try {
      await _loadTransactions();
      await _loadSavingsGoals();
      await _calculateFinancialOverview();
      await _generateAiInsights();
      await _calculateTopCategories();
      await _calculateWeeklySpending();
      await _prepareIncomeVsExpense();
      await _prepareSpendingPatterns();
      await _prepareSpendingHeatmap();
      await _prepareWeeklyTrend();
      await _preparePredictedSpending();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching insights: $e');
    }
  }
  
  // Update data based on selected period
  Future<void> updatePeriod(String period) async {
    try {
      // Update relevant data based on period
      await _prepareIncomeVsExpense(period: period);
      await _prepareSpendingPatterns(period: period);
      await _preparePredictedSpending(period: period);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating period: $e');
    }
  }
  
  // Load transactions from local storage and Appwrite
  Future<void> _loadTransactions() async {
    try {
      // Load from local storage first for faster display
      await StorageService.instance.initialize();
      final localTransactions = await StorageService.instance.getTransactions();
      
      // Then try to load from Appwrite and merge
      try {
        final appwriteTransactions = await _appwriteService.getTransactions();
        
        // Merge and deduplicate transactions
        final allTransactions = [...localTransactions, ...appwriteTransactions];
        final uniqueTransactions = <String, Transaction>{};
        
        for (var transaction in allTransactions) {
          uniqueTransactions[transaction.id] = transaction;
        }
        
        // Update local storage with merged transactions
        await StorageService.instance.saveTransactions(uniqueTransactions.values.toList());
      } catch (e) {
        debugPrint('Error loading transactions from Appwrite: $e');
        // Continue with local transactions
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }
  
  // Load savings goals
  Future<void> _loadSavingsGoals() async {
    try {
      final goals = await _appwriteService.fetchSavingsGoals();
      
      // Count active goals
      _activeGoalsCount = goals.where((g) => g.status == SavingsGoalStatus.active).length;
      
      // Prepare active goals data for timeline chart
      _activeGoals = goals
          .where((g) => g.status == SavingsGoalStatus.active)
          .map((goal) {
            final progress = goal.currentAmount / goal.targetAmount;
            final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
            
            return {
              'id': goal.id,
              'title': goal.title,
              'progress': progress,
              'daysLeft': daysLeft,
              'currentAmount': goal.currentAmount,
              'targetAmount': goal.targetAmount,
              'color': goal.color,
              'targetDate': goal.targetDate,
              'dailyTarget': goal.dailyTarget ?? 0.0,
            };
          })
          .toList();
    } catch (e) {
      debugPrint('Error loading savings goals: $e');
    }
  }
  
  // Calculate financial overview metrics
  Future<void> _calculateFinancialOverview() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      // Calculate total savings
      final savingsTransactions = transactions
          .where((t) => !t.isExpense)
          .toList();
          
      _totalSavings = savingsTransactions
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      // Calculate monthly savings
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      final monthlySavingsTransactions = savingsTransactions
          .where((t) => t.date.isAfter(monthStart))
          .toList();
          
      _monthlySavings = monthlySavingsTransactions
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      // Calculate daily average
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      _dailyAverage = _monthlySavings / daysInMonth;
      
      // Calculate savings growth percentage
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      
      final lastMonthSavings = savingsTransactions
          .where((t) => t.date.isAfter(lastMonth) && t.date.isBefore(lastMonthEnd))
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      if (lastMonthSavings > 0) {
        _savingsGrowthPercentage = ((_monthlySavings - lastMonthSavings) / lastMonthSavings) * 100;
      } else {
        _savingsGrowthPercentage = _monthlySavings > 0 ? 100 : 0;
      }
      
      // Calculate financial health score
      await _calculateFinancialHealthScore(transactions);
    } catch (e) {
      debugPrint('Error calculating financial overview: $e');
    }
  }
  
  // Calculate financial health score based on various factors
  Future<void> _calculateFinancialHealthScore(List<Transaction> transactions) async {
    try {
      int score = 50; // Base score
      
      // Factor 1: Savings rate
      final totalIncome = transactions
          .where((t) => !t.isExpense)
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
          
      final totalExpense = transactions
          .where((t) => t.isExpense)
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      if (totalIncome > 0) {
        final savingsRate = (totalIncome - totalExpense) / totalIncome;
        
        // Adjust score based on savings rate
        if (savingsRate > 0.3) score += 20;
        else if (savingsRate > 0.2) score += 15;
        else if (savingsRate > 0.1) score += 10;
        else if (savingsRate > 0) score += 5;
        else score -= 10;
      }
      
      // Factor 2: Budget adherence
      final budgets = await _appwriteService.getBudgets();
      
      int budgetsWithinLimit = 0;
      for (var budget in budgets) {
        if (budget.spent <= budget.amount) {
          budgetsWithinLimit++;
        }
      }
      
      if (budgets.isNotEmpty) {
        final adherenceRate = budgetsWithinLimit / budgets.length;
        
        // Adjust score based on budget adherence
        if (adherenceRate > 0.9) score += 20;
        else if (adherenceRate > 0.7) score += 15;
        else if (adherenceRate > 0.5) score += 5;
        else score -= 10;
      }
      
      // Factor 3: Savings goals progress
      final goals = await _appwriteService.fetchSavingsGoals();
      
      int goalsOnTrack = 0;
      for (var goal in goals.where((g) => g.status == SavingsGoalStatus.active)) {
        final progress = goal.currentAmount / goal.targetAmount;
        final timeProgress = DateTime.now().difference(goal.startDate ?? DateTime.now()).inDays / 
                          goal.targetDate.difference(goal.startDate ?? DateTime.now()).inDays;
        
        if (progress >= timeProgress) {
          goalsOnTrack++;
        }
      }
      
      if (goals.isNotEmpty) {
        final goalProgressRate = goalsOnTrack / goals.length;
        
        // Adjust score based on goals progress
        if (goalProgressRate > 0.8) score += 15;
        else if (goalProgressRate > 0.6) score += 10;
        else if (goalProgressRate > 0.4) score += 5;
        else score -= 5;
      }
      
      // Ensure score is within 0-100 range
      _financialHealthScore = score.clamp(0, 100);
    } catch (e) {
      debugPrint('Error calculating financial health score: $e');
    }
  }
  
  // Generate AI insights
  Future<void> _generateAiInsights() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      // Example AI insights (in a real app, these would come from Gemini AI)
      _aiInsights = [
        {
          'title': 'Spending Pattern Detected',
          'description': 'You spend 23% more on weekends than weekdays.',
          'icon': Icons.insights,
          'color': Colors.blue,
          'showChart': true,
          'actionable': false,
          'chartData': _generateDummyChartData(),
        },
        {
          'title': 'Subscription Alert',
          'description': 'Netflix subscription (Ksh 1,100) will be charged in 2 days.',
          'icon': Icons.notifications_active,
          'color': Colors.orange,
          'showChart': false,
          'actionable': true,
          'actionText': 'Review Subscription',
        },
        {
          'title': 'Saving Opportunity',
          'description': 'Reduce dining out by 2 meals/week to save Ksh 2,400 this month.',
          'icon': Icons.savings,
          'color': Colors.green,
          'showChart': false,
          'actionable': true,
          'actionText': 'Create Saving Goal',
        },
        {
          'title': 'Budget Warning',
          'description': 'You\'ve used 85% of your Transport budget with 12 days left.',
          'icon': Icons.warning_amber,
          'color': Colors.red,
          'showChart': false,
          'actionable': true,
          'actionText': 'Adjust Budget',
        },
      ];
      
      // Generate spending trend insight
      _spendingTrendInsight = 'Your spending increased by 12% compared to last month, mainly in the Food category.';
      
      // Generate goal timeline insight
      _goalTimelineInsight = 'At your current saving rate, you\'ll reach your "New Laptop" goal 24 days ahead of schedule.';
    } catch (e) {
      debugPrint('Error generating AI insights: $e');
    }
  }
  
  // Calculate top expense categories
  Future<void> _calculateTopCategories() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      // Filter to expenses in current month
      final expenses = transactions
          .where((t) => t.isExpense && t.date.isAfter(monthStart))
          .toList();
      
      // Group by category
      final categoryMap = <String, double>{};
      
      for (var expense in expenses) {
        if (categoryMap.containsKey(expense.category)) {
          categoryMap[expense.category] = categoryMap[expense.category]! + expense.amount;
        } else {
          categoryMap[expense.category] = expense.amount;
        }
      }
      
      // Convert to list and sort by amount (descending)
      final categoryList = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Take top 5 categories
      final topCategories = categoryList.take(5).toList();
      
      // Assign colors to categories
      final colors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.purple,
        Colors.orange,
      ];
      
      _topCategories = List.generate(
        topCategories.length,
        (index) => {
          'name': topCategories[index].key,
          'amount': topCategories[index].value,
          'color': colors[index % colors.length],
        },
      );
    } catch (e) {
      debugPrint('Error calculating top categories: $e');
    }
  }
  
  // Calculate weekly spending data
  Future<void> _calculateWeeklySpending() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      final now = DateTime.now();
      
      // Get transactions for last 7 weeks
      final List<Map<String, dynamic>> weeklyData = [];
      
      for (int i = 6; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: now.weekday + (i * 7)));
        final weekEnd = weekStart.add(const Duration(days: 7));
        
        final weekExpenses = transactions
            .where((t) => t.isExpense && t.date.isAfter(weekStart) && t.date.isBefore(weekEnd))
            .map((t) => t.amount)
            .fold(0.0, (prev, amount) => prev + amount);
        
        weeklyData.add({
          'week': 'W${7-i}',
          'amount': weekExpenses,
        });
      }
      
      _weeklySpending = weeklyData;
    } catch (e) {
      debugPrint('Error calculating weekly spending: $e');
    }
  }
  
  // Prepare income vs expense data
  Future<void> _prepareIncomeVsExpense({String period = 'Month'}) async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      final now = DateTime.now();
      
      DateTime periodStart;
      final periodLabels = <String>[];
      
      // Determine period start date and labels based on selected period
      switch (period) {
        case 'Week':
          periodStart = now.subtract(Duration(days: now.weekday + 6));
          for (int i = 0; i < 7; i++) {
            final day = periodStart.add(Duration(days: i));
            periodLabels.add(day.day.toString());
          }
          break;
        case 'Month':
          periodStart = DateTime(now.year, now.month - 5, 1);
          for (int i = 0; i < 6; i++) {
            final month = DateTime(periodStart.year, periodStart.month + i, 1);
            periodLabels.add('${month.month}/${month.year.toString().substring(2)}');
          }
          break;
        case 'Quarter':
          periodStart = DateTime(now.year, now.month - 9, 1);
          for (int i = 0; i < 3; i++) {
            final quarter = DateTime(periodStart.year, periodStart.month + (i * 3), 1);
            periodLabels.add('Q${i+1}');
          }
          break;
        case 'Year':
          periodStart = DateTime(now.year - 3, 1, 1);
          for (int i = 0; i < 4; i++) {
            final year = periodStart.year + i;
            periodLabels.add(year.toString());
          }
          break;
        default:
          periodStart = DateTime(now.year, now.month - 5, 1);
          for (int i = 0; i < 6; i++) {
            final month = DateTime(periodStart.year, periodStart.month + i, 1);
            periodLabels.add('${month.month}/${month.year.toString().substring(2)}');
          }
      }
      
      // Generate income vs expense data
      final List<Map<String, dynamic>> data = [];
      
      for (int i = 0; i < periodLabels.length; i++) {
        DateTime start;
        DateTime end;
        
        switch (period) {
          case 'Week':
            start = periodStart.add(Duration(days: i));
            end = start.add(const Duration(days: 1));
            break;
          case 'Month':
            start = DateTime(periodStart.year, periodStart.month + i, 1);
            end = DateTime(periodStart.year, periodStart.month + i + 1, 0);
            break;
          case 'Quarter':
            start = DateTime(periodStart.year, periodStart.month + (i * 3), 1);
            end = DateTime(periodStart.year, periodStart.month + (i * 3) + 3, 0);
            break;
          case 'Year':
            start = DateTime(periodStart.year + i, 1, 1);
            end = DateTime(periodStart.year + i + 1, 1, 0);
            break;
          default:
            start = DateTime(periodStart.year, periodStart.month + i, 1);
            end = DateTime(periodStart.year, periodStart.month + i + 1, 0);
        }
        
        final periodIncome = transactions
            .where((t) => !t.isExpense && t.date.isAfter(start) && t.date.isBefore(end))
            .map((t) => t.amount)
            .fold(0.0, (prev, amount) => prev + amount);
            
        final periodExpense = transactions
            .where((t) => t.isExpense && t.date.isAfter(start) && t.date.isBefore(end))
            .map((t) => t.amount)
            .fold(0.0, (prev, amount) => prev + amount);
        
        data.add({
          'period': periodLabels[i],
          'income': periodIncome,
          'expense': periodExpense,
        });
      }
      
      _incomeVsExpense = data;
      
      // Generate income vs expense insight
      final totalIncome = data.map((d) => d['income'] as double).fold(0.0, (prev, amount) => prev + amount);
      final totalExpense = data.map((d) => d['expense'] as double).fold(0.0, (prev, amount) => prev + amount);
      
      if (totalIncome > totalExpense) {
        final savingsRate = ((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1);
        _incomeExpenseInsight = 'Great job! You saved ${savingsRate}% of your income during this period.';
      } else {
        final deficit = totalExpense - totalIncome;
        _incomeExpenseInsight = 'Warning: Your expenses exceed your income by ${AppConfig.currencySymbol} ${deficit.toStringAsFixed(0)} in this period.';
      }
    } catch (e) {
      debugPrint('Error preparing income vs expense data: $e');
    }
  }
  
  // Prepare spending patterns data
  Future<void> _prepareSpendingPatterns({String period = 'Month'}) async {
    try {
      // AI classified spending patterns
      _spendingPatterns = [
        {
          'name': 'Essentials',
          'percentage': 45,
          'color': Colors.blue,
        },
        {
          'name': 'Lifestyle',
          'percentage': 30,
          'color': Colors.green,
        },
        {
          'name': 'Impulse',
          'percentage': 15,
          'color': Colors.orange,
        },
        {
          'name': 'Investment',
          'percentage': 10,
          'color': Colors.purple,
        },
      ];
    } catch (e) {
      debugPrint('Error preparing spending patterns: $e');
    }
  }
  
  // Prepare spending heatmap data
  Future<void> _prepareSpendingHeatmap() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      
      // Generate spending heatmap data (days of week by hours)
      final List<Map<String, dynamic>> heatmapData = [];
      
      for (int day = 0; day < 7; day++) {
        for (int hour = 0; hour < 24; hour += 3) { // Group by 3-hour blocks
          final dayTransactions = transactions.where((t) => 
            t.isExpense && 
            t.date.weekday == day + 1 && 
            t.date.hour >= hour && 
            t.date.hour < hour + 3
          ).toList();
          
          final totalAmount = dayTransactions.fold(0.0, (prev, t) => prev + t.amount);
          
          heatmapData.add({
            'day': day,
            'hour': hour,
            'value': totalAmount,
          });
        }
      }
      
      _spendingHeatmap = heatmapData;
      
      // Find highest spending time
      heatmapData.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
      
      if (heatmapData.isNotEmpty && heatmapData[0]['value'] > 0) {
        final highestDay = heatmapData[0]['day'] as int;
        final highestHour = heatmapData[0]['hour'] as int;
        
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final dayName = days[highestDay];
        
        _spendingHeatmapInsight = 'You spend the most on $dayName between ${highestHour}:00 and ${highestHour + 3}:00.';
      } else {
        _spendingHeatmapInsight = 'Not enough spending data to identify patterns yet.';
      }
    } catch (e) {
      debugPrint('Error preparing spending heatmap: $e');
    }
  }
  
  // Prepare weekly trend data
  Future<void> _prepareWeeklyTrend() async {
    try {
      final transactions = await StorageService.instance.getTransactions();
      final now = DateTime.now();
      
      // Calculate current week spending
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekSpending = transactions
          .where((t) => t.isExpense && t.date.isAfter(currentWeekStart))
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      // Calculate previous week spending
      final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      final previousWeekEnd = currentWeekStart.subtract(const Duration(days: 1));
      
      final previousWeekSpending = transactions
          .where((t) => t.isExpense && t.date.isAfter(previousWeekStart) && t.date.isBefore(previousWeekEnd))
          .map((t) => t.amount)
          .fold(0.0, (prev, amount) => prev + amount);
      
      // Calculate percentage change
      double percentageChange = 0;
      if (previousWeekSpending > 0) {
        percentageChange = ((currentWeekSpending - previousWeekSpending) / previousWeekSpending) * 100;
      }
      
      final isPositive = percentageChange <= 0; // Negative change in spending is positive for savings
      
      // Generate trend insight
      String title;
      String description;
      
      if (isPositive) {
        title = 'Spending Down This Week';
        description = 'You\'ve spent ${percentageChange.abs().toStringAsFixed(0)}% less than last week. Great work!';
      } else {
        title = 'Spending Up This Week';
        description = 'You\'ve spent ${percentageChange.toStringAsFixed(0)}% more than last week. Try to cut back to stay on budget.';
      }
      
      _weeklyTrend = {
        'title': title,
        'description': description,
        'isPositive': isPositive,
        'percentageChange': percentageChange,
      };
    } catch (e) {
      debugPrint('Error preparing weekly trend: $e');
    }
  }
  
  // Prepare predicted spending data
  Future<void> _preparePredictedSpending({String period = 'Month'}) async {
    try {
      // Simulated AI-predicted spending for upcoming periods
      final List<Map<String, dynamic>> predictedData = [];
      
      // Current month as reference point
      final now = DateTime.now();
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      // Generate predictions for next 6 months
      for (int i = 0; i < 6; i++) {
        final futureMonth = DateTime(now.year, now.month + i, 1);
        final monthName = monthNames[futureMonth.month - 1];
        
        // Base amount with some randomness to simulate prediction
        final baseAmount = 25000.0;
        final variationFactor = 0.8 + (i * 0.05) + (i % 2 == 0 ? 0.1 : -0.1);
        final predictedAmount = baseAmount * variationFactor;
        
        predictedData.add({
          'month': '$monthName ${futureMonth.year}',
          'predicted': predictedAmount,
          'actual': i == 0 ? predictedAmount * 0.8 : null, // Only current month has partial actual data
        });
      }
      
      _predictedSpending = predictedData;
      
      // Generate predicted spending insight
      _predictedSpendingInsight = 'Based on your spending patterns, you\'ll likely spend ${AppConfig.currencySymbol} ${predictedData[1]['predicted'].toStringAsFixed(0)} next month, with increased expenses in ${predictedData[2]['month']}.';
    } catch (e) {
      debugPrint('Error preparing predicted spending: $e');
    }
  }
  
  // Helper method to generate dummy chart data
  List<Map<String, dynamic>> _generateDummyChartData() {
    return List.generate(
      7,
      (index) => {
        'day': index,
        'amount': 1000.0 + (index * 200) + (index % 2 == 0 ? 300 : -200),
      },
    );
  }
}