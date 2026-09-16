import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = AuthStorageService.getUserData();
    final agencyMap = userData?['agency'] as Map<String, dynamic>?;
    final currentAgencyId = userData?['agencyId']?.toString() ?? agencyMap?['id']?.toString() ?? '1';
    final currentAgencyName = (agencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? 'Sunrise Properties';

    final planTier = (agencyMap?['subscriptionPlan'] as String?) ??
        (userData?['subscriptionPlan'] as String?) ??
        'Pro';

    // Real Plan Configuration
    String planTitle = 'Pro Plan';
    String planFee = '₹7,999 / month';
    int maxBrokers = 15;
    int maxProperties = 200;
    int maxCollabs = 50;

    if (planTier.toLowerCase().contains('enterprise')) {
      planTitle = 'Enterprise Plan';
      planFee = '₹19,999 / month';
      maxBrokers = 50;
      maxProperties = 1000;
      maxCollabs = 200;
    } else if (planTier.toLowerCase().contains('basic')) {
      planTitle = 'Basic Plan';
      planFee = '₹2,999 / month';
      maxBrokers = 5;
      maxProperties = 50;
      maxCollabs = 20;
    }

    // Dynamic Live Usage from Riverpod Providers
    final properties = ref.watch(propertyProvider);
    final deals = ref.watch(dealProvider);

    final agencyProperties = properties.where((p) {
      if (p.agencyId != null && p.agencyId.toString() == currentAgencyId) return true;
      if (currentAgencyName.isNotEmpty && p.agencyName.toLowerCase().trim() == currentAgencyName.toLowerCase().trim()) return true;
      return false;
    }).toList();

    final activeBrokersCount = (agencyMap?['brokerCount'] as num? ?? userData?['activeBrokers'] as num? ?? 3).toInt();
    final propertyCount = agencyProperties.length;
    final collabRequestsCount = deals.where((d) => d.isRequest).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription & SaaS Billing', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActivePlanCard(planTitle, planFee, currentAgencyName),
          const Gap(24),
          const Text('Live Resource Usage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Gap(12),
          _buildUsageMetrics(
            activeBrokersCount: activeBrokersCount,
            maxBrokers: maxBrokers,
            propertyCount: propertyCount,
            maxProperties: maxProperties,
            collabCount: collabRequestsCount,
            maxCollabs: maxCollabs,
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: () => _showUpgradePlanModal(context, planTitle),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Upgrade SaaS Tier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const Gap(16),
          Center(
            child: Text(
              '18% GST (HSN 9983) applied on all SaaS tier billings.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard(String planTitle, String planFee, String agencyName) {
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
              Text(planTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text('Live & Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Gap(4),
          Text(agencyName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Gap(12),
          Text(planFee, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const Gap(16),
          const Divider(color: Colors.white30),
          const Gap(8),
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              Gap(8),
              Text('Renews on: Oct 15, 2026 (Auto-Renewal On)', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMetrics({
    required int activeBrokersCount,
    required int maxBrokers,
    required int propertyCount,
    required int maxProperties,
    required int collabCount,
    required int maxCollabs,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildProgressBar('Active Brokers', activeBrokersCount, maxBrokers),
          const Gap(16),
          _buildProgressBar('Property Listings', propertyCount, maxProperties),
          const Gap(16),
          _buildProgressBar('Active Collaboration Inquiries', collabCount, maxCollabs),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int current, int max) {
    final double percent = (max > 0 ? (current / max) : 0.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('$current / $max quota', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

  void _showUpgradePlanModal(BuildContext context, String currentPlan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select SaaS Tier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Gap(12),
              _buildPlanOption(
                title: 'Basic Plan',
                price: '₹2,999 / mo',
                desc: 'Up to 5 Brokers, 50 Listings, Standard WhatsApp Support',
                isCurrent: currentPlan.contains('Basic'),
                onSelect: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected Basic Tier')));
                },
              ),
              const Gap(12),
              _buildPlanOption(
                title: 'Pro Plan',
                price: '₹7,999 / mo',
                desc: 'Up to 15 Brokers, 200 Listings, Automated WhatsApp + Push Center',
                isCurrent: currentPlan.contains('Pro'),
                onSelect: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected Pro Tier')));
                },
              ),
              const Gap(12),
              _buildPlanOption(
                title: 'Enterprise Plan',
                price: '₹19,999 / mo',
                desc: 'Up to 50 Brokers, Unlimited Listings, Dedicated SLA & Audit Center',
                isCurrent: currentPlan.contains('Enterprise'),
                onSelect: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected Enterprise Tier')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required String desc,
    required bool isCurrent,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: isCurrent ? null : onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCurrent ? AppColors.primaryBlue : AppColors.border, width: isCurrent ? 2 : 1),
          color: isCurrent ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (isCurrent) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Current', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const Gap(4),
                  Text(price, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryBlue, fontSize: 13)),
                  const Gap(4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(isCurrent ? Icons.check_circle : Icons.arrow_forward_ios, size: 16, color: isCurrent ? AppColors.primaryBlue : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

