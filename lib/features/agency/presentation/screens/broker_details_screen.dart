import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/data_providers.dart';

class BrokerDetailsScreen extends ConsumerWidget {
  final String brokerId;
  final bool isInternal;

  const BrokerDetailsScreen({super.key, required this.brokerId, this.isInternal = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agency = ref.watch(agencyProvider);
    final broker = agency.brokers.firstWhere(
      (b) => b.id == brokerId, 
      orElse: () => agency.brokers.first,
    );

    // Filter deals specifically assigned to or collaborated by this broker
    final allDeals = ref.watch(dealProvider);
    final brokerDeals = allDeals.where((d) => d.partnerBroker == broker.name).toList();
    
    final activeDeals = brokerDeals.where((d) => !d.isRequest && !d.status.contains('Closed')).length;
    final closedDeals = brokerDeals.where((d) => d.status.contains('Closed')).length;
    final collabRequests = brokerDeals.where((d) => d.isRequest).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Broker Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, broker),
            const Gap(24),
            _buildActionButtons(),
            const Gap(24),
            _buildPerformanceMetrics(activeDeals, closedDeals, collabRequests),
            const Gap(24),
            if (isInternal) _buildActivityLog(),
            if (!isInternal) const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Detailed activity logs are private for this broker.',
                style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, broker) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: broker.isActive ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                child: Text(
                  broker.name.substring(0, 1).toUpperCase(), 
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: broker.isActive ? AppColors.primaryBlue : Colors.grey),
                ),
              ),
              if (broker.isActive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const Gap(16),
          Text(broker.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Gap(4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(broker.role, style: const TextStyle(fontSize: 16, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isInternal ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isInternal ? 'Internal' : 'External',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isInternal ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
              const Gap(8),
              Text(broker.email, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
              const Gap(8),
              Text(broker.phone, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          if (!broker.isActive) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Account Deactivated', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.email),
              label: const Text('Email'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(int activeDeals, int closedDeals, int collabRequests) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance (Last 30 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(16),
          Row(
            children: [
              _buildStatCard('Active Deals', activeDeals.toString(), Icons.handshake, Colors.orange),
              const Gap(16),
              _buildStatCard('Closed Deals', closedDeals.toString(), Icons.check_circle, Colors.green),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              _buildStatCard('Collabs', collabRequests.toString(), Icons.people, Colors.blue),
              const Gap(16),
              _buildStatCard('Commission', '₹${(closedDeals * 1.5).toStringAsFixed(1)}L', Icons.currency_rupee, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Gap(4),
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    final activities = [
      {'action': 'Logged in to the portal', 'time': '2 hours ago', 'icon': Icons.login},
      {'action': 'Updated Deal Status to "Site Visit Scheduled"', 'time': '4 hours ago', 'icon': Icons.update},
      {'action': 'Requested Collaboration on "Skyline Villa"', 'time': '1 day ago', 'icon': Icons.handshake},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final act = activities[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(act['icon'] as IconData, size: 16, color: AppColors.textSecondary),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(act['action'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(act['time'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const Gap(40),
        ],
      ),
    );
  }
}
