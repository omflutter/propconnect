import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/routing/app_router.dart';

class CollaborationDetailsScreen extends ConsumerWidget {
  final String dealId;

  const CollaborationDetailsScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(dealProvider);
    final deal = deals.firstWhere((d) => d.id == dealId, orElse: () => deals.first);

    final properties = ref.watch(propertyProvider);
    final property = properties.firstWhere(
      (p) => p.id == deal.propertyId,
      orElse: () => properties.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collaboration Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradient(deal.status),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: _getStatusGradient(deal.status).first.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Gap(4),
                  Text(
                    deal.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Property Preview Card
            GestureDetector(
              onTap: () {
                context.push(AppRouter.propertyDetails.replaceAll(':id', property.id));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: property.images.isNotEmpty
                          ? Image.asset(property.images.first, fit: BoxFit.cover)
                          : Container(color: AppColors.border, child: const Icon(Icons.image, color: Colors.grey)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(4),
                            Text(
                              property.location,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(8),
                            Text(
                              property.price,
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(32),

            // Deal Overview Card
            _buildSectionCard(
              title: 'Deal Overview',
              icon: Icons.handshake_outlined,
              child: Column(
                children: [
                  _buildDetailRow('Property', deal.propertyName, Icons.home_work_outlined),
                  const Divider(height: 32, color: AppColors.border),
                  _buildDetailRow('Partner', '${deal.partnerBroker} (${deal.partnerAgency})', Icons.person_outline),
                  const Divider(height: 32, color: AppColors.border),
                  _buildDetailRow('Deal Amount', deal.amount, Icons.monetization_on_outlined, isHighlight: true),
                  if (deal.createdAt != null) ...[
                    const Divider(height: 32, color: AppColors.border),
                    _buildDetailRow('Date', DateFormat('MMM dd, yyyy - hh:mm a').format(deal.createdAt!), Icons.calendar_today_outlined),
                  ],
                ],
              ),
            ),
            const Gap(24),

            // Collaboration Request Info Card (if available)
            if (deal.clientRequirement != null || deal.remarks != null)
              _buildSectionCard(
                title: 'Request Details',
                icon: Icons.description_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (deal.clientRequirement != null) ...[
                      const Text('Client Requirement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                      const Gap(8),
                      Text(
                        deal.clientRequirement!,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                      ),
                    ],
                    if (deal.clientRequirement != null && deal.remarks != null) const Divider(height: 32, color: AppColors.border),
                    if (deal.remarks != null) ...[
                      const Text('Remarks / Additional Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                      const Gap(8),
                      Text(
                        deal.remarks!,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ],
                ),
              ),

            // Action Buttons
            if (deal.status == 'Pending' && deal.isIncomingRequest) ...[
              const Gap(40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ref.read(dealProvider.notifier).updateDealStatus(deal.id, 'Rejected');
                        context.pop();
                      },
                      child: const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ref.read(dealProvider.notifier).updateDealStatus(deal.id, 'Approved');
                        context.pop();
                      },
                      child: const Text('Approve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
            const Gap(40),
          ],
        ),
      ),
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'Pending':
        return [Colors.orange.shade400, Colors.deepOrange.shade400];
      case 'Approved':
      case 'Token Generated':
      case 'Agreement Signed':
        return [Colors.green.shade400, Colors.teal.shade500];
      case 'Rejected':
        return [Colors.red.shade400, Colors.red.shade700];
      default:
        return [Colors.blue.shade400, Colors.indigo.shade500];
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 24),
              const Gap(12),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const Gap(24),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.iconColor, size: 20),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const Gap(4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 18 : 16,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? AppColors.primaryBlue : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
