// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/theme_service.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? animation;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final double? iconSize;
  final bool showAnimation;
  final Widget? customWidget;
  final EdgeInsetsGeometry? padding;

  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    this.animation,
    this.icon,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.iconSize = 80.0,
    this.showAnimation = true,
    this.customWidget,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final size = MediaQuery.of(context).size;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding ?? EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animation, Icon, or Custom Widget
          if (customWidget != null)
            customWidget!
          else if (animation != null && showAnimation)
            _buildAnimationWidget(themeService, size)
          else if (icon != null)
            _buildIconWidget(themeService),
          
          SizedBox(height: 24.0),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12.0),
          
          // Message
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16.0,
                color: themeService.subtextColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: 32.0),
          
          // Action Button
          if (buttonText != null && onButtonPressed != null)
            _buildActionButton(themeService),
        ],
      ),
    );
  }

  Widget _buildAnimationWidget(ThemeService themeService, Size size) {
    return Container(
      width: size.width * 0.6,
      height: size.width * 0.6,
      constraints: BoxConstraints(
        maxWidth: 300.0,
        maxHeight: 300.0,
        minWidth: 150.0,
        minHeight: 150.0,
      ),
      child: Lottie.asset(
        animation!,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if animation fails to load
          return _buildFallbackIcon(themeService);
        },
      ),
    );
  }

  Widget _buildIconWidget(ThemeService themeService) {
    return Container(
      width: iconSize! + 40,
      height: iconSize! + 40,
      decoration: BoxDecoration(
        color: (iconColor ?? themeService.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular((iconSize! + 40) / 2),
      ),
      child: Icon(
        icon!,
        size: iconSize,
        color: iconColor ?? themeService.primaryColor,
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeService themeService) {
    // Default icon based on animation file name or use a generic icon
    IconData fallbackIcon = Icons.inbox_outlined;
    
    if (animation != null) {
      final animationName = animation!.toLowerCase();
      if (animationName.contains('chart')) {
        fallbackIcon = Icons.analytics_outlined;
      } else if (animationName.contains('empty')) {
        fallbackIcon = Icons.inbox_outlined;
      } else if (animationName.contains('search')) {
        fallbackIcon = Icons.search_off_outlined;
      } else if (animationName.contains('transaction')) {
        fallbackIcon = Icons.receipt_long_outlined;
      } else if (animationName.contains('money')) {
        fallbackIcon = Icons.account_balance_wallet_outlined;
      }
    }
    
    return Container(
      width: iconSize! + 40,
      height: iconSize! + 40,
      decoration: BoxDecoration(
        color: themeService.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular((iconSize! + 40) / 2),
      ),
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: themeService.primaryColor,
      ),
    );
  }

  Widget _buildActionButton(ThemeService themeService) {
    return ElevatedButton.icon(
      onPressed: onButtonPressed,
      icon: _getButtonIcon(),
      label: Text(
        buttonText!,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeService.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  Widget _getButtonIcon() {
    // Return appropriate icon based on button text
    if (buttonText == null) return Icon(Icons.arrow_forward);
    
    final text = buttonText!.toLowerCase();
    if (text.contains('transaction')) {
      return Icon(Icons.add_card);
    } else if (text.contains('add')) {
      return Icon(Icons.add);
    } else if (text.contains('go to')) {
      return Icon(Icons.arrow_forward);
    } else if (text.contains('retry') || text.contains('try')) {
      return Icon(Icons.refresh);
    } else if (text.contains('explore')) {
      return Icon(Icons.explore);
    } else if (text.contains('insight')) {
      return Icon(Icons.lightbulb_outline);
    } else {
      return Icon(Icons.arrow_forward);
    }
  }
}

// Predefined empty state configurations for common scenarios
class EmptyStates {
  static Widget noTransactions({
    VoidCallback? onAddTransaction,
  }) {
    return EmptyState(
      title: 'No Transactions Yet',
      message: 'Start tracking your finances by adding your first transaction. It only takes a few seconds!',
      animation: 'assets/animations/empty_transactions.json',
      buttonText: 'Add Transaction',
      onButtonPressed: onAddTransaction,
    );
  }

  static Widget noAnalytics({
    VoidCallback? onGoToTransactions,
  }) {
    return EmptyState(
      title: 'No Analytics Available',
      message: 'Start adding transactions to see detailed analytics and insights about your spending patterns.',
      animation: 'assets/animations/empty_chart.json',
      buttonText: 'Go to Transactions',
      onButtonPressed: onGoToTransactions,
    );
  }

  static Widget noSearchResults({
    String? searchQuery,
    VoidCallback? onClearSearch,
  }) {
    return EmptyState(
      title: 'No Results Found',
      message: searchQuery != null 
          ? 'No transactions found for "$searchQuery". Try adjusting your search terms.'
          : 'No transactions match your current filters. Try adjusting your search criteria.',
      icon: Icons.search_off_outlined,
      buttonText: 'Clear Search',
      onButtonPressed: onClearSearch,
    );
  }

  static Widget noCategories({
    VoidCallback? onAddCategory,
  }) {
    return EmptyState(
      title: 'No Categories',
      message: 'Create custom categories to better organize and track your transactions.',
      icon: Icons.category_outlined,
      buttonText: 'Add Category',
      onButtonPressed: onAddCategory,
    );
  }

  static Widget networkError({
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      title: 'Connection Error',
      message: 'Unable to load data. Please check your internet connection and try again.',
      icon: Icons.wifi_off_outlined,
      iconColor: Colors.red,
      buttonText: 'Retry',
      onButtonPressed: onRetry,
    );
  }

  static Widget genericError({
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      title: 'Something Went Wrong',
      message: errorMessage ?? 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      buttonText: 'Try Again',
      onButtonPressed: onRetry,
    );
  }

  static Widget comingSoon({
    String? featureName,
  }) {
    return EmptyState(
      title: 'Coming Soon',
      message: featureName != null 
          ? '$featureName is coming soon! We\'re working hard to bring you this feature.'
          : 'This feature is coming soon! Stay tuned for updates.',
      icon: Icons.schedule_outlined,
      iconColor: Colors.orange,
      showAnimation: false,
    );
  }

  static Widget maintenance() {
    return EmptyState(
      title: 'Under Maintenance',
      message: 'This feature is temporarily unavailable while we make improvements. Please try again later.',
      icon: Icons.build_outlined,
      iconColor: Colors.orange,
      showAnimation: false,
    );
  }

  static Widget noForecastData({
    VoidCallback? onGetInsights,
  }) {
    return EmptyState(
      title: 'No Forecast Available',
      message: 'Generate AI-powered forecasts and insights based on your transaction history.',
      icon: Icons.trending_up_outlined,
      buttonText: 'Get AI Insights',
      onButtonPressed: onGetInsights,
    );
  }

  static Widget noNotifications() {
    return EmptyState(
      title: 'No Notifications',
      message: 'You\'re all caught up! New notifications will appear here.',
      icon: Icons.notifications_none_outlined,
      showAnimation: false,
    );
  }

  static Widget emptyBudget({
    VoidCallback? onCreateBudget,
  }) {
    return EmptyState(
      title: 'No Budget Set',
      message: 'Create a budget to track your spending and reach your financial goals.',
      icon: Icons.pie_chart_outline,
      buttonText: 'Create Budget',
      onButtonPressed: onCreateBudget,
    );
  }

  static Widget noGoals({
    VoidCallback? onAddGoal,
  }) {
    return EmptyState(
      title: 'No Financial Goals',
      message: 'Set financial goals to stay motivated and track your progress towards financial freedom.',
      icon: Icons.flag_outlined,
      buttonText: 'Add Goal',
      onButtonPressed: onAddGoal,
    );
  }
}