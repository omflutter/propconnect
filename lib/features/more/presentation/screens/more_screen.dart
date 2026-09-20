import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await AuthStorageService.clearSession(); // clear persistent session
              if (context.mounted) {
                context.go('/login'); // navigate to login
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = AuthStorageService.getUserData();
    final name = (userData?['name'] as String?) ?? 'Agency Admin';
    final email = (userData?['email'] as String?) ?? 'om@propconnect.in';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Gap(16),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(email, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const Gap(32),
          _buildMenuItem(Icons.person_outline, 'Profile Settings', onTap: () => context.push('/profile')),
          _buildMenuItem(Icons.domain_add_outlined, 'Register Agency Profile', onTap: () => context.push('/create-agency')),
          _buildMenuItem(Icons.business_outlined, 'Agency Management', onTap: () => context.push('/agency-management')),
          _buildMenuItem(Icons.people_alt_outlined, 'Property Owners & Settings', onTap: () => context.push('/owners')),
          _buildMenuItem(Icons.subscriptions_outlined, 'Subscription & Billing', onTap: () => context.push('/subscription')),
          _buildMenuItem(Icons.analytics_outlined, 'Reports & Analytics', onTap: () => context.push('/analytics')),
          const Divider(height: 32),
          _buildMenuItem(Icons.help_outline, 'Help & Support', onTap: () => context.push('/support')),
          _buildMenuItem(Icons.logout, 'Logout', color: Colors.red, onTap: () => _showLogoutDialog(context)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = AppColors.textPrimary, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
