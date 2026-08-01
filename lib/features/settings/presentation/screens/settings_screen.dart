import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _darkMode = false;
  bool _twoFactor = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Account Settings'),
          _buildSettingsTile(
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            icon: Icons.person_outline,
            onTap: () {},
          ),
          _buildSettingsTile(
            title: 'Change Password',
            subtitle: 'Update your security credentials',
            icon: Icons.lock_outline,
            onTap: () {},
          ),
          
          const Gap(24),
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive alerts on your device',
            icon: Icons.notifications_active_outlined,
            value: _pushEnabled,
            onChanged: (val) => setState(() => _pushEnabled = val),
          ),
          _buildSwitchTile(
            title: 'Email Alerts',
            subtitle: 'Receive daily summary emails',
            icon: Icons.email_outlined,
            value: _emailEnabled,
            onChanged: (val) => setState(() => _emailEnabled = val),
          ),
          _buildSwitchTile(
            title: 'Dark Mode',
            subtitle: 'Switch to a darker theme',
            icon: Icons.dark_mode_outlined,
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
          ),
          
          const Gap(24),
          _buildSectionHeader('Security'),
          _buildSwitchTile(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            icon: Icons.security_outlined,
            value: _twoFactor,
            onChanged: (val) => setState(() => _twoFactor = val),
          ),
          
          const Gap(24),
          _buildSectionHeader('Agency Settings (Admin)'),
          _buildSettingsTile(
            title: 'Manage Agency Details',
            subtitle: 'Update agency info and branding',
            icon: Icons.business_outlined,
            onTap: () {},
          ),
          _buildSettingsTile(
            title: 'Team Management',
            subtitle: 'Add or remove brokers',
            icon: Icons.group_outlined,
            onTap: () {},
          ),
          const Gap(40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
    );
  }

  Widget _buildSettingsTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required IconData icon, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
        activeThumbColor: AppColors.primaryBlue,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
