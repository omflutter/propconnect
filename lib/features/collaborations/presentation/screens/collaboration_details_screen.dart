import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/broker_directory_service.dart';

class CollaborationDetailsScreen extends ConsumerWidget {
  final String dealId;

  const CollaborationDetailsScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(dealProvider);
    if (deals.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final deal = deals.cast<DealModel?>().firstWhere(
      (d) => d != null && (d.id == dealId || d.dealCode == dealId),
      orElse: () => null,
    );
    if (deal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collaboration Details')),
        body: const Center(child: Text('Collaboration request not found or loading...')),
      );
    }

    final properties = ref.watch(propertyProvider);
    final property = properties.cast<PropertyModel?>().firstWhere(
      (p) => p != null && p.id == deal.propertyId,
      orElse: () => null,
    );

    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          deal.id.isNotEmpty ? deal.id : 'Collaboration Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue),
            tooltip: 'Chat with Partner Broker',
            onPressed: () => _openChat(context, deal, currentUserId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradient(deal.status),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusGradient(deal.status).first.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.isIncomingRequest ? 'INCOMING REQUEST' : 'SENT REQUEST',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        deal.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      deal.status == 'Approved'
                          ? Icons.check
                          : (deal.status == 'Rejected' ? Icons.close : Icons.hourglass_top),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // PRD 4.5.2 Privacy Notice Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                  Gap(10),
                  Expanded(
                    child: Text(
                      'PRD 4.5.2 Privacy Firewall: Buyer identity is strictly protected. Cross-agency collaboration is conducted via structured requirement parameters.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Property Card Preview
            GestureDetector(
              onTap: () {
                final targetPropId = property?.id ?? deal.propertyId;
                if (targetPropId.isNotEmpty) {
                  context.push(AppRouter.propertyDetails.replaceAll(':id', targetPropId));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: (property != null && property.images.isNotEmpty)
                          ? (property.images.first.startsWith('http')
                              ? Image.network(property.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.apartment, color: AppColors.primaryBlue)))
                              : Image.asset(property.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.apartment, color: AppColors.primaryBlue))))
                          : Container(color: Colors.grey.shade200, child: const Icon(Icons.apartment, color: AppColors.primaryBlue)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property?.title ?? deal.propertyName,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(3),
                            Text(
                              property?.location ?? 'Prime Location',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(4),
                            Text(
                              property?.price ?? deal.amount,
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(20),

            // Deal Overview Card
            _buildSectionCard(
              title: 'Deal Overview',
              icon: Icons.handshake_outlined,
              child: Column(
                children: [
                  _buildDetailRow('Property', deal.propertyName, Icons.home_work_outlined),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow('Counterparty Broker', '${deal.partnerBroker} (${deal.partnerAgency})', Icons.person_outline),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(
                    'Budget / Expected Value',
                    deal.expectedBudget?.isNotEmpty == true ? deal.expectedBudget! : deal.amount,
                    Icons.currency_rupee,
                    isHighlight: true,
                  ),
                  if (deal.createdAt != null) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow('Submitted On', DateFormat('dd MMM yyyy • hh:mm a').format(deal.createdAt!), Icons.calendar_today_outlined),
                  ],
                  if (deal.respondedAt != null) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow('Responded On', DateFormat('dd MMM yyyy • hh:mm a').format(deal.respondedAt!), Icons.done_all_outlined),
                  ],
                ],
              ),
            ),
            const Gap(16),

            // Structured Client Requirement Card
            if (deal.clientRequirement != null && deal.clientRequirement!.isNotEmpty)
              _buildSectionCard(
                title: 'Structured Requirement',
                icon: Icons.assignment_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        deal.clientRequirement!,
                        style: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
            const Gap(16),

            // Remarks / Notes
            if (deal.remarks != null && deal.remarks!.isNotEmpty)
              _buildSectionCard(
                title: 'Remarks & Terms',
                icon: Icons.notes_outlined,
                child: Text(
                  deal.remarks!,
                  style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
                ),
              ),

            // Direct Chat CTA
            const Gap(16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openChat(context, deal, currentUserId),
              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue),
              label: Text(
                'Open Chat with ${deal.partnerBroker}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ),

            // Action Buttons for Incoming Pending Requests
            if (deal.status == 'Pending' && deal.isIncomingRequest) ...[
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _showRejectModal(context, ref, deal);
                      },
                      child: const Text('Decline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await ref.read(dealProvider.notifier).respondRequest(deal.id, 'approve');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Collaboration ${deal.id} Approved! Co-broker deal active.'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                          context.pop();
                        }
                      },
                      child: const Text('Approve Deal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],

            // If already Approved, button to jump to Deals pipeline
            if (deal.status == 'Approved') ...[
              const Gap(16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.push(AppRouter.deals),
                icon: const Icon(Icons.trending_up, color: Colors.white),
                label: const Text(
                  'View Deal in Deals Pipeline',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],

            const Gap(32),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, DealModel deal, String currentUserId) {
    final userData = AuthStorageService.getUserData();
    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final parsedAgencyId = userAgencyId is int ? userAgencyId : int.tryParse(userAgencyId?.toString() ?? '');

    final partner = BrokerDirectoryService.resolvePartnerDetailsForDeal(
      deal,
      currentUserId,
      currentAgencyId: parsedAgencyId,
    );

    final sorted = [currentUserId, partner.id]..sort();
    final hasProp = deal.propertyId.isNotEmpty;
    final convId = hasProp
        ? 'conv_${sorted[0]}_${sorted[1]}_${deal.propertyId}'
        : 'conv_${sorted[0]}_${sorted[1]}';

    context.push(
      '/chat/$convId',
      extra: {
        'partnerId': partner.id,
        'partnerName': partner.name,
        'agencyName': partner.agencyName,
        'chatType': hasProp ? 'property' : 'direct',
        'contextTitle': deal.propertyName.isNotEmpty
            ? deal.propertyName
            : 'Deal #${deal.dealCode.isNotEmpty ? deal.dealCode : deal.id}',
        'propertyId': deal.propertyId,
        'dealId': deal.id,
      },
    );
  }

  void _showRejectModal(BuildContext context, WidgetRef ref, DealModel deal) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Decline Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to decline this request for ${deal.propertyName}?',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Gap(12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  hintText: 'e.g. Price mismatch, property under token...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(dealProvider.notifier).respondRequest(
                      deal.id,
                      'reject',
                      reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Declined by listing agency',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Collaboration ${deal.id} declined.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
                context.pop();
              },
              child: const Text('Decline Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'Pending':
        return [Colors.orange.shade500, Colors.deepOrange.shade500];
      case 'Approved':
        return [Colors.green.shade600, Colors.teal.shade700];
      case 'Rejected':
        return [Colors.red.shade600, Colors.red.shade900];
      default:
        return [Colors.blue.shade600, Colors.indigo.shade700];
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const Gap(8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Gap(14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: AppColors.iconColor, size: 16),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500)),
              const Gap(2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 16 : 13.5,
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
