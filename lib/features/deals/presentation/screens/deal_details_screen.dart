import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class DealDetailsScreen extends ConsumerStatefulWidget {
  final String dealId;
  const DealDetailsScreen({super.key, required this.dealId});

  @override
  ConsumerState<DealDetailsScreen> createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends ConsumerState<DealDetailsScreen> {
  final List<String> _stages = [
    'Enquiry',
    'Requirement Matching',
    'Proposal Sent',
    'Site Visit Scheduled',
    'Site Visit Completed',
    'Negotiation',
    'Token Done',
    'Agreement Signed',
    'Registration Done',
    'Payment Received',
    'Commission Settled',
    'Closed',
  ];

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(dealProvider);
    final deal = deals.firstWhere(
      (d) => d.id == widget.dealId || d.dealCode == widget.dealId,
      orElse: () => deals.first,
    );

    final userData = AuthStorageService.getUserData();
    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final userAgency = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';
    
    // PRD Sec 10 Lead Privacy Firewall: Broker B owns the client; Broker A owns the property
    final isClientOwner = (userAgencyId != null && deal.agencyBId != null && deal.agencyBId == userAgencyId) ||
        (userAgency.isNotEmpty && deal.agencyBName.toLowerCase().trim() == userAgency.toLowerCase().trim()) ||
        deal.isRequest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Deal ${deal.dealCode.isNotEmpty ? deal.dealCode : deal.id}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                    if (deal.propertyId.isNotEmpty) {
                      context.push('/property-details/${deal.propertyId}');
                    }
                  }),
                  const Divider(height: 28, color: AppColors.border),
                  _buildDetailRow('Partner Broker', '${deal.partnerBroker} (${deal.partnerAgency})', Icons.person_outline),
                  const Divider(height: 28, color: AppColors.border),
                  _buildDetailRow('Deal Amount / Value', deal.amount, Icons.monetization_on_outlined, isHighlight: true),
                ],
              ),
            ),
            const Gap(16),

            // PRD Sec 11: Contextual Deal Chat Action Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 22),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deal Communication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Gap(2),
                        Text('Discuss terms directly with ${deal.partnerBroker}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      final currentUserId = userData?['id']?.toString() ?? '1';
                      final partnerId = (deal.brokerBId ?? deal.brokerAId ?? '2').toString();
                      final sorted = [currentUserId, partnerId]..sort();
                      final convId = 'conv_${sorted[0]}_${sorted[1]}';

                      context.push(
                        '/chat/$convId',
                        extra: {
                          'partnerId': partnerId,
                          'partnerName': deal.partnerBroker,
                          'agencyName': deal.partnerAgency,
                        },
                      );
                    },
                    child: const Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // PRD Sec 10: Client Info & Lead Privacy Firewall Card
            _buildSectionCard(
              title: isClientOwner ? 'Client Information' : 'Client Privacy Firewall',
              icon: isClientOwner ? Icons.person_search_outlined : Icons.shield_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isClientOwner) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_rounded, color: AppColors.primaryBlue, size: 18),
                          Gap(10),
                          Expanded(
                            child: Text(
                              'PRD Lead Privacy Firewall: Client direct phone and email are protected by the platform. Please coordinate all updates and site visits through Deal Chat with the buyer\'s broker.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    _buildDetailRow('Client Name', deal.clientName ?? 'Verified Buyer Lead', Icons.badge_outlined),
                    const Divider(height: 24, color: AppColors.border),
                    _buildDetailRow('Client Phone', '+91 98*** *****', Icons.phone_locked_outlined),
                    const Divider(height: 24, color: AppColors.border),
                    _buildDetailRow('Client Email', 'c***@***.com', Icons.mail_lock_outlined),
                    if (deal.clientRequirement != null && deal.clientRequirement!.isNotEmpty) ...[
                      const Divider(height: 24, color: AppColors.border),
                      _buildDetailRow('Requirement', deal.clientRequirement!, Icons.notes_outlined),
                    ],
                  ] else ...[
                    _buildDetailRow('Client Name', deal.clientName ?? 'Buyer Client', Icons.badge_outlined),
                    const Divider(height: 24, color: AppColors.border),
                    _buildDetailRow('Client Phone', deal.clientPhone ?? '+91 98200 12345', Icons.phone_outlined),
                    const Divider(height: 24, color: AppColors.border),
                    _buildDetailRow('Client Email', deal.clientEmail ?? 'client@example.com', Icons.email_outlined),
                    if (deal.clientRequirement != null && deal.clientRequirement!.isNotEmpty) ...[
                      const Divider(height: 24, color: AppColors.border),
                      _buildDetailRow('Requirement', deal.clientRequirement!, Icons.notes_outlined),
                    ],
                    if (deal.expectedBudget != null && deal.expectedBudget!.isNotEmpty) ...[
                      const Divider(height: 24, color: AppColors.border),
                      _buildDetailRow('Budget', deal.expectedBudget!, Icons.account_balance_wallet_outlined),
                    ],
                  ],
                ],
              ),
            ),
            const Gap(16),

            // Status Update Section (PRD Sec 9: 12 stages)
            _buildSectionCard(
              title: 'Current Stage & Progress',
              icon: Icons.track_changes_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  const Text('Advance Deal Lifecycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const Gap(8),
                  DropdownButtonFormField<String>(
                    initialValue: _stages.contains(deal.status) ? deal.status : _stages.first,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            const Gap(20),

            // Audit Timeline
            const Text('Audit History & Database Trail', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Gap(14),
            if (deal.auditHistory.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No audit events logged yet.', style: TextStyle(color: AppColors.textSecondary))))
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
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isFirst ? AppColors.primaryBlue : AppColors.border,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 48,
                              color: AppColors.border,
                            ),
                        ],
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.status, style: TextStyle(fontWeight: isFirst ? FontWeight.bold : FontWeight.w600, fontSize: 14.5, color: isFirst ? Colors.black87 : AppColors.textSecondary)),
                            const Gap(2),
                            Text(
                              '${DateFormat('MMM dd, yyyy • hh:mm a').format(log.timestamp)} • Updated by ${log.updatedBy ?? 'System'}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                            ),
                            if (log.notes != null && log.notes!.isNotEmpty) ...[
                              const Gap(3),
                              Text('Notes: ${log.notes}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontStyle: FontStyle.italic)),
                            ],
                            if (!isLast) const Gap(18),
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
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move Deal to "$newStage"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This milestone will update the linked property status and write an audit event into PostgreSQL.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Gap(16),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Milestone Notes (Optional)',
                hintText: 'e.g. Agreement draft approved by buyer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref.read(dealProvider.notifier).updateDealStatus(dealId, newStage, notesCtrl.text.isNotEmpty ? notesCtrl.text : null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deal progressed to $newStage')));
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(icon, color: AppColors.primaryBlue, size: 22),
              const Gap(10),
              Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const Gap(18),
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
            child: Icon(icon, color: isHighlight ? Colors.green : AppColors.textSecondary, size: 18),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Gap(2),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isHighlight ? 16 : 14.5, color: isHighlight ? Colors.green : Colors.black87)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}
