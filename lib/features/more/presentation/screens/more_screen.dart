import 'package:flutter/material.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:gap/gap.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryBlue,
            child: Text('AV', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const Gap(16),
          const Text('Amit Verma', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Agency Admin - Sunrise Properties', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const Gap(32),
          _buildMenuItem(Icons.person_outline, 'Profile Settings'),
          _buildMenuItem(Icons.business_outlined, 'Agency Settings'),
          _buildMenuItem(Icons.subscriptions_outlined, 'Subscription & Billing'),
          _buildMenuItem(Icons.analytics_outlined, 'Reports & Analytics'),
          const Divider(height: 32),
          _buildMenuItem(Icons.help_outline, 'Help & Support'),
          _buildMenuItem(Icons.logout, 'Logout', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = AppColors.textPrimary}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
