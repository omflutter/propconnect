import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Today'),
          _buildNotificationTile(
            title: 'Collaboration Request Approved!',
            subtitle: 'Rahul Singh approved your request for the 3 BHK Apartment in Bandra.',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            time: '2m ago',
            isUnread: true,
            actionText: 'View Deal',
          ),
          _buildNotificationTile(
            title: 'New Collaboration Request',
            subtitle: 'Neha Gupta wants to collaborate on your Office Space listing.',
            icon: Icons.handshake,
            iconColor: Colors.orange,
            time: '1h ago',
            isUnread: true,
            actionText: 'Review',
          ),
          _buildNotificationTile(
            title: 'Property Match Alert',
            subtitle: 'A new 4 BHK Villa in Worli matches your client requirement.',
            icon: Icons.home,
            iconColor: AppColors.primaryBlue,
            time: '3h ago',
            isUnread: false,
          ),
          _buildSectionHeader('Yesterday'),
          _buildNotificationTile(
            title: 'Deal Moved to Negotiation',
            subtitle: 'The deal for 2 BHK in Malad is now in the Negotiation stage.',
            icon: Icons.trending_up,
            iconColor: Colors.purple,
            time: '1d ago',
            isUnread: false,
          ),
          _buildNotificationTile(
            title: 'System Update',
            subtitle: 'PropConnect v2.0 is now live. Check out the new features!',
            icon: Icons.info,
            iconColor: Colors.grey,
            time: '1d ago',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String time,
    required bool isUnread,
    String? actionText,
  }) {
    return Container(
      color: isUnread ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
                      ),
                      Text(time, style: TextStyle(color: isUnread ? AppColors.primaryBlue : AppColors.textSecondary, fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const Gap(4),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.3)),
                  if (actionText != null) ...[
                    const Gap(8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        side: const BorderSide(color: AppColors.border),
                        elevation: 0,
                      ),
                      child: Text(actionText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
}
