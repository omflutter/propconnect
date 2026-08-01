import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Subscription & Billing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActivePlanCard(),
          const Gap(24),
          const Text('Usage Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Gap(12),
          _buildUsageMetrics(),
          const Gap(24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upgrade Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlueLight, AppColors.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Professional Plan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Gap(8),
          const Text('₹2,499 / month', style: TextStyle(color: Colors.white, fontSize: 16)),
          const Gap(16),
          const Divider(color: Colors.white30),
          const Gap(8),
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              Gap(8),
              Text('Renews on: Oct 15, 2026', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMetrics() {
    return Column(
      children: [
        _buildProgressBar('Active Brokers', 5, 10),
        const Gap(16),
        _buildProgressBar('Property Listings', 42, 100),
        const Gap(16),
        _buildProgressBar('Collaboration Requests', 12, 50),
      ],
    );
  }

  Widget _buildProgressBar(String label, int current, int max) {
    final double percent = current / max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('$current / $max', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const Gap(8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: AppColors.border,
          color: percent > 0.8 ? Colors.orange : AppColors.primaryBlue,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
