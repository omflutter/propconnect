import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';

class DealDetailsScreen extends ConsumerStatefulWidget {
  final String dealId;
  const DealDetailsScreen({super.key, required this.dealId});

  @override
  ConsumerState<DealDetailsScreen> createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends ConsumerState<DealDetailsScreen> {
  final List<String> _stages = [
    'Lead Assigned',
    'Property Shared',
    'Site Visit Scheduled',
    'Site Visit Completed',
    'Negotiation Started',
    'Offer Submitted',
    'Token Generated',
    'Agreement Signed',
    'Registry Scheduled',
    'Registry Completed',
    'Deal Closed',
    'Deal Lost'
  ];

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(dealProvider);
    final deal = deals.firstWhere(
      (d) => d.id == widget.dealId,
      orElse: () => deals.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Deal ${deal.id}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Deal Overview Card
            _buildSectionCard(
              title: 'Deal Overview',
              icon: Icons.handshake_outlined,
              child: Column(
                children: [
                  _buildDetailRow('Property', deal.propertyName, Icons.home_work_outlined, onTap: () {
                    context.push('/property-details/${deal.propertyId}');
                  }),
                  const Divider(height: 32, color: AppColors.border),
                  _buildDetailRow('Partner Broker', '${deal.partnerBroker} (${deal.partnerAgency})', Icons.person_outline),
                  const Divider(height: 32, color: AppColors.border),
                  _buildDetailRow('Deal Amount', deal.amount, Icons.monetization_on_outlined, isHighlight: true),
                ],
              ),
            ),
            const Gap(24),

            // Status Update Section
            _buildSectionCard(
              title: 'Current Stage',
              icon: Icons.track_changes_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                        ),
                        child: Text(deal.status, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Gap(16),
                  const Text('Update Stage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                  const Gap(8),
                  DropdownButtonFormField<String>(
                    initialValue: _stages.contains(deal.status) ? deal.status : _stages.first,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _stages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                    onChanged: (newStage) {
                      if (newStage != null && newStage != deal.status) {
                        _showUpdateConfirmDialog(context, deal.id, newStage);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Audit Timeline
            const Text('Audit History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Gap(16),
            if (deal.auditHistory.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No history found for this deal.', style: TextStyle(color: AppColors.textSecondary))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deal.auditHistory.length,
                itemBuilder: (context, index) {
                  final log = deal.auditHistory.reversed.toList()[index];
                  final isFirst = index == 0;
                  final isLast = index == deal.auditHistory.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isFirst ? AppColors.primaryBlue : AppColors.border,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 50,
                              color: AppColors.border,
                            ),
                        ],
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.status, style: TextStyle(fontWeight: isFirst ? FontWeight.bold : FontWeight.w500, fontSize: 16, color: isFirst ? Colors.black : AppColors.textSecondary)),
                            const Gap(4),
                            Text(
                              '${DateFormat('MMM dd, yyyy - hh:mm a').format(log.timestamp)} • Updated by ${log.updatedBy ?? 'System'}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (!isLast) const Gap(24),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showUpdateConfirmDialog(BuildContext context, String dealId, String newStage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Stage Update'),
        content: Text('Are you sure you want to move this deal to "$newStage"?\n\nThis will be permanently recorded in the audit history.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref.read(dealProvider.notifier).updateDealStatus(dealId, newStage);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deal updated to $newStage')));
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 24),
              const Gap(12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Gap(24),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isHighlight = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isHighlight ? Colors.green.withValues(alpha: 0.1) : AppColors.background, shape: BoxShape.circle),
            child: Icon(icon, color: isHighlight ? Colors.green : AppColors.textSecondary, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Gap(2),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isHighlight ? 18 : 16, color: isHighlight ? Colors.green : Colors.black87)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
