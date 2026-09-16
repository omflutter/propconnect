import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/push_notification_service.dart';
import 'package:propconnect/features/notifications/domain/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AppNotification> _notifications = [];
  String _selectedFilter = 'all'; // 'all', 'unread', 'deal', 'collaboration', 'system'
  StreamSubscription? _pushSubscription;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    // Auto-refresh when a push notification arrives while on this screen
    _pushSubscription = PushNotificationService.onMessageReceivedStream.stream.listen((_) {
      _fetchNotifications(silent: true);
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  int? get _currentUserId {
    final userData = AuthStorageService.getUserData();
    final rawId = userData?['id'];
    return rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
  }

  int? get _currentAgencyId {
    final userData = AuthStorageService.getUserData();
    final rawId = userData?['agencyId'] ?? userData?['agency']?['id'];
    return rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _fetchNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.getNotifications(
        userId: _currentUserId,
        agencyId: _currentAgencyId,
      );

      if (response['success'] == true && response['data'] is List) {
        final list = (response['data'] as List)
            .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _notifications = list;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (_notifications.isEmpty) {
              _errorMessage = response['message'] ?? 'Could not load notifications';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_notifications.isEmpty) {
            _errorMessage = 'Network connection error: $e';
          }
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadList = _notifications.where((n) => !n.isRead).toList();
    if (unreadList.isEmpty) return;

    // Optimistic UI update
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    try {
      await ApiService.markAllNotificationsAsRead(
        userId: _currentUserId,
        agencyId: _currentAgencyId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _markAsRead(AppNotification notif) async {
    if (notif.isRead) return;

    setState(() {
      _notifications = _notifications
          .map((n) => n.id == notif.id ? n.copyWith(isRead: true) : n)
          .toList();
    });

    try {
      await ApiService.markNotificationAsRead(notif.id);
    } catch (_) {}
  }

  Future<void> _deleteNotification(AppNotification notif) async {
    final previousList = [..._notifications];
    setState(() {
      _notifications.removeWhere((n) => n.id == notif.id);
    });

    try {
      await ApiService.deleteNotification(notif.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.primaryBlue,
              onPressed: () {
                setState(() {
                  _notifications = previousList;
                });
              },
            ),
          ),
        );
      }
    } catch (_) {
      setState(() {
        _notifications = previousList;
      });
    }
  }

  void _onNotificationTapped(AppNotification notif) {
    _markAsRead(notif);
    if (notif.actionRoute != null && notif.actionRoute!.isNotEmpty) {
      try {
        context.push(notif.actionRoute!);
      } catch (e) {
        debugPrint('[Notification Nav Error] Cannot navigate to ${notif.actionRoute}: $e');
      }
    }
  }

  List<AppNotification> get _filteredNotifications {
    if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'deal') {
      return _notifications.where((n) => n.type == 'deal').toList();
    } else if (_selectedFilter == 'collaboration') {
      return _notifications.where((n) => n.type == 'collaboration').toList();
    } else if (_selectedFilter == 'system') {
      return _notifications.where((n) => n.type == 'system' || n.type == 'subscription').toList();
    }
    return _notifications;
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'collaboration':
        return Icons.handshake_outlined;
      case 'deal':
        return Icons.trending_up;
      case 'commission':
        return Icons.account_balance_wallet_outlined;
      case 'subscription':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'collaboration':
        return const Color(0xFFF97316); // Orange
      case 'deal':
        return const Color(0xFF8B5CF6); // Purple
      case 'commission':
        return const Color(0xFF10B981); // Green
      case 'subscription':
        return AppColors.primaryBlue;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_unreadCount > 0) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterBar(),
          const Divider(height: 1, color: AppColors.border),

          // Notification Content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'unread', 'label': 'Unread ($_unreadCount)'},
      {'id': 'collaboration', 'label': 'Collabs'},
      {'id': 'deal', 'label': 'Deals'},
      {'id': 'system', 'label': 'System'},
    ];

    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const Gap(8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelected = _selectedFilter == item['id'];

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _selectedFilter = item['id']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                item['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const Gap(12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Gap(16),
              ElevatedButton.icon(
                onPressed: () => _fetchNotifications(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredNotifications;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, size: 42, color: AppColors.textSecondary),
            ),
            const Gap(14),
            Text(
              _selectedFilter == 'unread'
                  ? 'You\'re all caught up!'
                  : 'No notifications found',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const Gap(6),
            Text(
              _selectedFilter == 'unread'
                  ? 'There are no unread notifications right now.'
                  : 'New activity, deal progress, and collab alerts will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: () => _fetchNotifications(silent: true),
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final notif = filtered[index];
          return Dismissible(
            key: Key('notif_${notif.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: AppColors.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
            ),
            onDismissed: (_) => _deleteNotification(notif),
            child: _buildNotificationItem(notif),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notif) {
    final iconColor = _getTypeColor(notif.type);
    final icon = _getTypeIcon(notif.type);
    final relativeTime = _formatRelativeTime(notif.createdAt);

    return InkWell(
      onTap: () => _onNotificationTapped(notif),
      child: Container(
        color: notif.isRead
            ? Colors.transparent
            : AppColors.primaryBlue.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (!notif.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
                          color: notif.isRead ? AppColors.textSecondary : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (notif.actionRoute != null && notif.actionRoute!.isNotEmpty) ...[
                    const Gap(8),
                    InkWell(
                      onTap: () => _onNotificationTapped(notif),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getActionLabel(notif),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const Gap(4),
                            const Icon(Icons.arrow_forward, size: 12, color: AppColors.primaryBlue),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionLabel(AppNotification notif) {
    if (notif.actionRoute?.contains('collaboration') == true) {
      return 'View Collaboration';
    }
    if (notif.actionRoute?.contains('deals') == true) {
      return 'View Deal';
    }
    if (notif.actionRoute?.contains('commission') == true) {
      return 'View Commission';
    }
    return 'View Details';
  }
}
