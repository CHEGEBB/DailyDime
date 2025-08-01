// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/models/app_notification.dart';
import 'package:dailydime/services/app_notification_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppNotificationService _notificationService;
  GenerativeModel? _geminiModel;
  
  String _selectedFilter = 'All';
  bool _showOnlyUnread = false;
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notificationService = AppNotificationService();
    _initializeServices();
  }

  void _initializeServices() async {
    try {
      await _notificationService.initialize();
      _initializeGemini();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  void _initializeGemini() {
    try {
      if (AppConfig.geminiApiKey.isNotEmpty) {
        _geminiModel = GenerativeModel(
          model: AppConfig.geminiModel,
          apiKey: AppConfig.geminiApiKey,
        );
      }
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppNotification> _filterNotifications(List<AppNotification> notifications) {
    var filtered = notifications;

    if (_showOnlyUnread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    switch (_selectedFilter) {
      case 'Transactions':
        filtered = filtered.where((n) => n.type == NotificationType.transaction).toList();
        break;
      case 'Budget':
        filtered = filtered.where((n) => 
          n.type == NotificationType.budget || 
          n.type == NotificationType.alert
        ).toList();
        break;
      case 'Goals':
        filtered = filtered.where((n) => 
          n.type == NotificationType.goal || 
          n.type == NotificationType.challenge ||
          n.type == NotificationType.achievement
        ).toList();
        break;
      case 'System':
        filtered = filtered.where((n) => 
          n.type == NotificationType.system || 
          n.type == NotificationType.reminder ||
          n.type == NotificationType.balance
        ).toList();
        break;
    }

    return filtered;
  }

  Future<void> _generateAISummary() async {
    if (_geminiModel == null) {
      _showErrorSnackBar('AI insights not available');
      return;
    }

    setState(() {
      _isLoadingAI = true;
    });

    try {
      final notifications = _notificationService.allNotifications.take(10).toList();
      if (notifications.isEmpty) {
        _showErrorSnackBar('No notifications to analyze');
        setState(() {
          _isLoadingAI = false;
        });
        return;
      }

      final prompt = '''
      Based on these recent financial notifications, provide a brief 2-3 sentence insight:
      ${notifications.map((n) => '${n.type.name}: ${n.title} - ${n.body}').join('\n')}
      
      Focus on spending patterns, budget alerts, or goal progress. Keep it concise and actionable.
      ''';

      final content = [Content.text(prompt)];
      final response = await _geminiModel!.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        _showAIInsightDialog(response.text!);
      } else {
        _showErrorSnackBar('Unable to generate insights');
      }
    } catch (e) {
      debugPrint('Error generating AI summary: $e');
      _showErrorSnackBar('Unable to generate insights at the moment');
    } finally {
      setState(() {
        _isLoadingAI = false;
      });
    }
  }

  void _showAIInsightDialog(String insight) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lightbulb,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Insights',
              style: TextStyle(
                color: themeService.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeService.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            insight,
            style: TextStyle(
              color: themeService.textColor,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: themeService.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(themeService),
                _buildNotificationStats(themeService),
                _buildFilterTabs(themeService),
                Expanded(
                  child: _buildNotificationsList(themeService),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ThemeService themeService) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              color: themeService.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          if (_geminiModel != null)
            _isLoadingAI
                ? Container(
                    margin: const EdgeInsets.all(12),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeService.primaryColor,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.lightbulb_outline),
                    onPressed: _generateAISummary,
                    tooltip: 'AI Insights',
                    style: IconButton.styleFrom(
                      backgroundColor: themeService.primaryColor.withOpacity(0.1),
                      foregroundColor: themeService.primaryColor,
                    ),
                  ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: themeService.textColor,
            ),
            color: themeService.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_unread',
                child: Row(
                  children: [
                    Icon(
                      _showOnlyUnread ? Icons.visibility : Icons.visibility_off,
                      color: themeService.textColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _showOnlyUnread ? 'Show All' : 'Show Unread Only',
                      style: TextStyle(color: themeService.textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: themeService.textColor),
                    const SizedBox(width: 12),
                    Text(
                      'Mark All Read',
                      style: TextStyle(color: themeService.textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_old',
                child: Row(
                  children: [
                    Icon(Icons.auto_delete, color: themeService.textColor),
                    const SizedBox(width: 12),
                    Text(
                      'Clear Old',
                      style: TextStyle(color: themeService.textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStats(ThemeService themeService) {
    return Consumer<AppNotificationService>(
      builder: (context, service, child) {
        final total = service.allNotifications.length;
        final unread = service.unreadCount;
        final today = _getTodayCount(service.allNotifications);
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeService.isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', total.toString(), Icons.notifications, themeService),
              _buildVerticalDivider(themeService),
              _buildStatItem('Unread', unread.toString(), Icons.mark_email_unread, themeService),
              _buildVerticalDivider(themeService),
              _buildStatItem('Today', today.toString(), Icons.today, themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String count, IconData icon, ThemeService themeService) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: themeService.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: themeService.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeService.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeService.subtextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(ThemeService themeService) {
    return Container(
      height: 40,
      width: 1,
      color: themeService.subtextColor.withOpacity(0.3),
    );
  }

  int _getTodayCount(List<AppNotification> notifications) {
    final today = DateTime.now();
    return notifications
        .where((n) => 
          n.timestamp.year == today.year &&
          n.timestamp.month == today.month &&
          n.timestamp.day == today.day
        )
        .length;
  }

  Widget _buildFilterTabs(ThemeService themeService) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Transactions', 'Budget', 'Goals', 'System']
              .map((filter) => _buildFilterChip(filter, themeService))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, ThemeService themeService) {
    final isSelected = _selectedFilter == filter;
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        backgroundColor: themeService.surfaceColor,
        selectedColor: themeService.primaryColor,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected 
              ? themeService.primaryColor
              : themeService.subtextColor.withOpacity(0.3),
          width: 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : themeService.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildNotificationsList(ThemeService themeService) {
    return Consumer<AppNotificationService>(
      builder: (context, notificationService, child) {
        if (!notificationService.initialized) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: themeService.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading notifications...',
                  style: TextStyle(
                    color: themeService.textColor,
                  ),
                ),
              ],
            ),
          );
        }

        final notifications = _filterNotifications(notificationService.allNotifications);

        if (notifications.isEmpty) {
          return _buildEmptyState(themeService);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification, themeService);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/animations/notification.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showOnlyUnread ? 'No unread notifications' : 'No notifications yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _showOnlyUnread 
                ? 'All caught up! 🎉\nYou\'re on top of everything'
                : 'We\'ll notify you when something happens\nYour updates will appear here',
            style: TextStyle(
              fontSize: 16,
              color: themeService.subtextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_showOnlyUnread) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showOnlyUnread = false;
                });
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show All Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, ThemeService themeService) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: themeService.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // In a real app, you'd implement undo functionality
                _showErrorSnackBar('Undo functionality not implemented');
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead 
            ? null 
            : Border.all(
                color: themeService.primaryColor.withOpacity(0.3), 
                width: 2
              ),
          boxShadow: [
            BoxShadow(
              color: themeService.isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleNotificationTap(notification),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: notification.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notification.icon,
                      color: notification.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w500 
                                      : FontWeight.bold,
                                  color: themeService.textColor,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: themeService.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: themeService.subtextColor,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: notification.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                notification.type.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: notification.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: themeService.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: themeService.subtextColor,
                      size: 20,
                    ),
                    color: themeService.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) => _handleNotificationAction(value, notification),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: notification.isRead ? 'mark_unread' : 'mark_read',
                        child: Row(
                          children: [
                            Icon(
                              notification.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                              color: themeService.textColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              notification.isRead ? 'Mark Unread' : 'Mark Read',
                              style: TextStyle(color: themeService.textColor),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }
    
    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.transaction:
        // Navigate to transaction details or transactions screen
        break;
      case NotificationType.budget:
        // Navigate to budget screen
        break;
      case NotificationType.goal:
        // Navigate to goals screen
        break;
      case NotificationType.challenge:
        // Navigate to challenges screen
        break;
      default:
        break;
    }
  }

  void _handleNotificationAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        _notificationService.markAsRead(notification.id);
        break;
      case 'mark_unread':
        _notificationService.markAsUnread(notification.id);
        break;
      case 'delete':
        _notificationService.deleteNotification(notification.id);
        _showErrorSnackBar('Notification deleted');
        break;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_unread':
        setState(() {
          _showOnlyUnread = !_showOnlyUnread;
        });
        break;
      case 'mark_all_read':
        _notificationService.markAllAsRead();
        _showErrorSnackBar('All notifications marked as read');
        break;
      case 'clear_old':
        _showClearOldDialog();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  void _showClearOldDialog() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Clear Old Notifications',
          style: TextStyle(color: themeService.textColor),
        ),
        content: Text(
          'This will delete notifications older than 30 days. This action cannot be undone.',
          style: TextStyle(color: themeService.subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.subtextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.deleteOldNotifications();
              _showErrorSnackBar('Old notifications cleared');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear Old'),
          ),
        ],
      ),
    );
  }
  
  void _showClearAllDialog() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Clear All Notifications',
          style: TextStyle(color: themeService.textColor),
        ),
        content: Text(
          'This will delete all notifications. This action cannot be undone.',
          style: TextStyle(color: themeService.subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.subtextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.deleteAllNotifications();
              _showErrorSnackBar('All notifications cleared');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}