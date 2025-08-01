// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late GenerativeModel _geminiModel;
  
  String _selectedFilter = 'All';
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notificationService = AppNotificationService();
    _initializeGemini();
  }

  void _initializeGemini() {
    _geminiModel = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
    );
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
    final notifications = _notificationService.allNotifications.take(10).toList();
    if (notifications.isEmpty) return;

    try {
      final prompt = '''
      Based on these recent financial notifications, provide a brief 2-3 sentence insight:
      ${notifications.map((n) => '${n.type.name}: ${n.title} - ${n.body}').join('\n')}
      
      Focus on spending patterns, budget alerts, or goal progress. Keep it concise and actionable.
      ''';

      final content = [Content.text(prompt)];
      final response = await _geminiModel.generateContent(content);
      
      if (response.text != null) {
        _showAIInsightDialog(response.text!);
      }
    } catch (e) {
      debugPrint('Error generating AI summary: $e');
      _showErrorDialog('Unable to generate insights at the moment.');
    }
  }

  void _showAIInsightDialog(String insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('AI Insights'),
          ],
        ),
        content: Text(insight),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: themeService.surfaceColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildNotificationStats(),
              _buildFilterTabs(themeService),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _generateAISummary,
            tooltip: 'AI Insights',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_unread',
                child: Row(
                  children: [
                    Icon(_showOnlyUnread ? Icons.visibility : Icons.visibility_off),
                    const SizedBox(width: 8),
                    Text(_showOnlyUnread ? 'Show All' : 'Show Unread Only'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Mark All Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_old',
                child: Row(
                  children: [
                    Icon(Icons.auto_delete),
                    SizedBox(width: 8),
                    Text('Clear Old'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppNotificationService>(
        builder: (context, notificationService, child) {
          return StreamBuilder<List<AppNotification>>(
            stream: notificationService.notificationsStream,
            initialData: notificationService.allNotifications,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = _filterNotifications(snapshot.data ?? []);

              if (notifications.isEmpty) {
                return _buildEmptyState(themeService);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: _buildNotificationsList(notifications, themeService),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationStats() {
    return Consumer<AppNotificationService>(
      builder: (context, service, child) {
        final total = service.allNotifications.length;
        final unread = service.unreadCount;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', total.toString(), Icons.notifications),
              _buildStatItem('Unread', unread.toString(), Icons.mark_email_unread),
              _buildStatItem('Today', _getTodayCount().toString(), Icons.today),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String count, IconData icon) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Column(
      children: [
        Icon(icon, color: themeService.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeService.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: themeService.subtextColor,
          ),
        ),
      ],
    );
  }

  int _getTodayCount() {
    final today = DateTime.now();
    return _notificationService.allNotifications
        .where((n) => 
          n.timestamp.year == today.year &&
          n.timestamp.month == today.month &&
          n.timestamp.day == today.day
        )
        .length;
  }

  Widget _buildFilterTabs(ThemeService themeService) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Transactions', 'Budget', 'Goals', 'System']
                    .map((filter) => _buildFilterChip(filter, themeService))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, ThemeService themeService) {
    final isSelected = _selectedFilter == filter;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        backgroundColor: themeService.surfaceColor,
        selectedColor: themeService.primaryColor.withOpacity(0.2),
        checkmarkColor: themeService.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? themeService.primaryColor : themeService.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: themeService.subtextColor,
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnread ? 'No unread notifications' : 'No notifications yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeService.subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyUnread 
              ? 'All caught up! 🎉'
              : 'We\'ll notify you when something happens',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeService.subtextColor,
            ),
          ),
          if (_showOnlyUnread) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _showOnlyUnread = false;
                });
              },
              child: const Text('Show All Notifications'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications, ThemeService themeService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, themeService);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification, ThemeService themeService) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // In a real app, you'd implement undo functionality
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead 
            ? null 
            : Border.all(color: themeService.primaryColor.withOpacity(0.3), width: 2),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead 
                                    ? FontWeight.normal 
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeService.subtextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
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
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: notification.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              notification.timeAgo,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                    onSelected: (value) => _handleNotificationAction(value, notification),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: notification.isRead ? 'mark_unread' : 'mark_read',
                        child: Row(
                          children: [
                            Icon(notification.isRead ? Icons.mark_email_unread : Icons.mark_email_read),
                            const SizedBox(width: 8),
                            Text(notification.isRead ? 'Mark Unread' : 'Mark Read'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
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
        notification.isRead = false;
        notification.save();
        setState(() {});
        break;
      case 'delete':
        _notificationService.deleteNotification(notification.id);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Notifications'),
        content: const Text('This will delete notifications older than 30 days. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.deleteOldNotifications();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('This will delete all notifications. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.deleteAllNotifications();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}