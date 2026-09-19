import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/network/api_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isUpgrading = false;
  String? _overriddenTier;

  @override
  Widget build(BuildContext context) {
    final userData = AuthStorageService.getUserData();
    final agencyMap = userData?['agency'] as Map<String, dynamic>?;
    final currentAgencyId = userData?['agencyId']?.toString() ?? agencyMap?['id']?.toString() ?? '1';
    final currentAgencyName = (agencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? 'Sunrise Properties';

    final rawTier = _overriddenTier ??
        (agencyMap?['subscriptionTier'] as String?) ??
        (agencyMap?['subscriptionPlan'] as String?) ??
        (userData?['subscriptionPlan'] as String?) ??
        'Professional';

    // PRD Section 14 Specifications
    String planTitle = 'Professional';
    String planFee = '₹7,999 / month';
    int maxBrokers = 20;
    int maxProperties = 300;
    int maxCollabs = 100;
    String storageQuota = '25 GB';
    String waQuota = '2,500 Alerts';

    final tierLower = rawTier.toLowerCase();
    if (tierLower.contains('enterprise')) {
      planTitle = 'Enterprise';
      planFee = '₹19,999 / month';
      maxBrokers = 200;
      maxProperties = 2000;
      maxCollabs = 500;
      storageQuota = '250 GB';
      waQuota = '10,000 Alerts';
    } else if (tierLower.contains('basic')) {
      planTitle = 'Basic';
      planFee = '₹2,999 / month';
      maxBrokers = 5;
      maxProperties = 50;
      maxCollabs = 25;
      storageQuota = '5 GB';
      waQuota = '500 Alerts';
    } else if (tierLower.contains('trial') || tierLower.contains('free')) {
      planTitle = 'Free Trial';
      planFee = '₹0 (14-Day Free)';
      maxBrokers = 2;
      maxProperties = 10;
      maxCollabs = 10;
      storageQuota = '500 MB';
      waQuota = '50 Alerts';
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
          _buildActivePlanCard(planTitle, planFee, currentAgencyName, storageQuota, waQuota),
          const Gap(24),
          const Text('Live Resource Quota Usage (PRD Sec 14)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
            onPressed: _isUpgrading ? null : () => _showUpgradePlanModal(context, planTitle, currentAgencyId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isUpgrading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Change / Upgrade SaaS Tier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const Gap(16),
          const Center(
            child: Text(
              '18% GST (HSN 9983) applied on all SaaS tier billings. Instant automated tax invoice dispatch.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard(String planTitle, String planFee, String agencyName, String storage, String waAlerts) {
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
              Text('$planTitle Plan', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_outlined, color: Colors.white70, size: 14),
                  const Gap(6),
                  Text('Storage: $storage', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 14),
                  const Gap(6),
                  Text('WhatsApp: $waAlerts', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
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

  void _showUpgradePlanModal(BuildContext context, String currentPlan, String agencyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                  const Text('Select SaaS Tier (PRD Sec 14)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Gap(12),
              _buildPlanOption(
                title: 'Free Trial',
                price: '₹0 / 14 Days',
                desc: '2 Brokers, 10 Listings, 500 MB Cloud Storage, 50 WhatsApp Alerts',
                isCurrent: currentPlan.contains('Trial') || currentPlan.contains('Free'),
                onSelect: () => _handleSelectTier(ctx, agencyId, 'Free Trial'),
              ),
              const Gap(12),
              _buildPlanOption(
                title: 'Basic Plan',
                price: '₹2,999 / mo',
                desc: '5 Brokers, 50 Listings, 5 GB Cloud Storage, 500 WhatsApp Alerts',
                isCurrent: currentPlan.contains('Basic'),
                onSelect: () => _handleSelectTier(ctx, agencyId, 'Basic'),
              ),
              const Gap(12),
              _buildPlanOption(
                title: 'Professional Plan',
                price: '₹7,999 / mo',
                desc: '20 Brokers, 300 Listings, 25 GB Cloud Storage, 2,500 WhatsApp Alerts',
                isCurrent: currentPlan.contains('Pro'),
                onSelect: () => _handleSelectTier(ctx, agencyId, 'Professional'),
              ),
              const Gap(12),
              _buildPlanOption(
                title: 'Enterprise Plan',
                price: '₹19,999 / mo',
                desc: 'Unlimited Brokers & Listings, 250 GB Dedicated Storage, 10,000 Alerts, SLA Support',
                isCurrent: currentPlan.contains('Enterprise'),
                onSelect: () => _handleSelectTier(ctx, agencyId, 'Enterprise'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSelectTier(BuildContext modalContext, String agencyId, String targetTier) async {
    Navigator.pop(modalContext);
    setState(() => _isUpgrading = true);

    try {
      final res = await ApiService.put('/agencies/$agencyId', {
        'subscriptionTier': targetTier,
      });

      if (res['success'] == true) {
        // Update local session
        final userData = AuthStorageService.getUserData() ?? {};
        final agencyMap = Map<String, dynamic>.from(userData['agency'] as Map? ?? {});
        agencyMap['subscriptionTier'] = targetTier;
        userData['agency'] = agencyMap;
        userData['subscriptionPlan'] = targetTier;
        await AuthStorageService.updateUserData(userData);

        if (mounted) {
          setState(() {
            _overriddenTier = targetTier;
            _isUpgrading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully upgraded SaaS tier to $targetTier!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isUpgrading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message']?.toString() ?? 'Failed to upgrade subscription tier')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpgrading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error upgrading subscription: $e')),
        );
      }
    }
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
        padding: const EdgeInsets.all(14),
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
