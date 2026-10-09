import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/broker_directory_service.dart';

class DealDetailsScreen extends ConsumerStatefulWidget {
  final String dealId;
  const DealDetailsScreen({super.key, required this.dealId});

  @override
  ConsumerState<DealDetailsScreen> createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends ConsumerState<DealDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(dealProvider);
    final deal = deals.cast<DealModel?>().firstWhere(
      (d) => d?.id == widget.dealId || d?.dealCode == widget.dealId,
      orElse: () => deals.isNotEmpty ? deals.first : null,
    );

    if (deal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            widget.dealId,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    final userData = AuthStorageService.getUserData();
    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final userAgency = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';
    final currentUserId = userData?['id']?.toString() ?? '1';

    final parsedAgencyId = userAgencyId is int ? userAgencyId : int.tryParse(userAgencyId?.toString() ?? '');
    final partner = BrokerDirectoryService.resolvePartnerDetailsForDeal(
      deal,
      currentUserId,
      currentAgencyId: parsedAgencyId,
    );

    // Deal participants: Broker A / Agency A (Listing owner who added property) and Broker B / Agency B (Buyer's broker)
    final isPartyA = (userAgencyId != null && deal.agencyAId != null && deal.agencyAId.toString() == userAgencyId.toString()) ||
        (userAgency.isNotEmpty && deal.agencyAName.toLowerCase().trim() == userAgency.toLowerCase().trim()) ||
        (deal.brokerAId != null && deal.brokerAId.toString() == currentUserId);

    final isPartyB = (userAgencyId != null && deal.agencyBId != null && deal.agencyBId.toString() == userAgencyId.toString()) ||
        (userAgency.isNotEmpty && deal.agencyBName.toLowerCase().trim() == userAgency.toLowerCase().trim()) ||
        (deal.brokerBId != null && deal.brokerBId.toString() == currentUserId) ||
        deal.isRequest;

    final isCollaboration = deal.agencyAId != null && deal.agencyBId != null && deal.agencyAId != deal.agencyBId;

    // PRD Section 10 Lead Ownership Model:
    // In cross-agency collaboration deals, Broker B owns the client.
    // Broker A (listing owner) CANNOT access client phone, email, or personal info.
    final canViewClientDetails = isCollaboration ? isPartyB : (isPartyA || isPartyB);

    final currentIdx = deal.milestoneIndex;
    final isClosed = deal.normalizedStage == 'Deal Closed';
    final isLost = deal.normalizedStage == 'Deal Lost';

    final properties = ref.watch(propertyProvider);
    final linkedProperty = properties.cast<PropertyModel?>().firstWhere(
      (p) => p != null && (p.id.trim() == deal.propertyId.trim() ||
             (p.title.isNotEmpty && deal.propertyName.isNotEmpty && p.title.trim().toLowerCase() == deal.propertyName.trim().toLowerCase())),
      orElse: () => null,
    );
    final isPropertySold = (linkedProperty != null && (linkedProperty.status.toLowerCase() == 'sold' || linkedProperty.status.toLowerCase() == 'rented')) ||
      deals.any((d) => d.propertyId == deal.propertyId && d.id != deal.id && (d.normalizedStage == 'Deal Closed' || d.status.toLowerCase().contains('sold')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          deal.dealCode.isNotEmpty ? deal.dealCode : deal.id,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue),
            tooltip: 'Deal Chat',
            onPressed: () => _openChat(context, deal, currentUserId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Property Sold Warning for Counterparties/Other Collaborators
            if (isPropertySold && !isClosed)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.do_not_disturb_on_outlined, color: Color(0xFFDC2626), size: 22),
                    const Gap(12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listing Status: Property Sold',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF991B1B)),
                          ),
                          Gap(2),
                          Text(
                            'This property has been marked as sold. This collaboration deal is now closed and no further stage updates can be made.',
                            style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Stage Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradient(deal.normalizedStage),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusGradient(deal.normalizedStage).first.withValues(alpha: 0.25),
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
                        'CURRENT TRANSACTION STAGE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        deal.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        isLost
                            ? 'Negotiation Terminated'
                            : (isClosed ? 'Transaction Successfully Completed' : 'Step ${currentIdx + 1} of 9 in Milestone Pipeline'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
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
                      isClosed
                          ? Icons.verified
                          : (isLost ? Icons.cancel_outlined : Icons.timeline),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // PRD Section 4.4: 9 Transaction Milestones Stepper
            _buildSectionCard(
              title: 'Transaction Milestones (PRD Section 4.4)',
              icon: Icons.alt_route_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Track verified milestones from Inquiry to Final Registry & Possession.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Gap(16),
                  _buildMilestoneTimeline(deal, currentIdx, isLost),
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isPropertySold && !isClosed) || isClosed || isLost
                            ? const Color(0xFF94A3B8)
                            : AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: ((isPropertySold && !isClosed) || isClosed || isLost)
                          ? null
                          : () => _showAdvanceMilestoneModal(context, deal),
                      icon: Icon(
                        (isPropertySold && !isClosed)
                            ? Icons.lock_outline
                            : (isClosed ? Icons.verified : Icons.fast_forward_rounded),
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        (isPropertySold && !isClosed)
                            ? 'Listing Sold (Deal Closed)'
                            : (isClosed ? 'Deal Completed' : (isLost ? 'Deal Closed (Lost)' : 'Advance Deal Milestone')),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Deal Overview Card
            _buildSectionCard(
              title: 'Deal Overview',
              icon: Icons.handshake_outlined,
              child: Column(
                children: [
                  _buildDetailRow(
                    'Property',
                    deal.propertyName,
                    Icons.home_work_outlined,
                    onTap: () {
                      if (deal.propertyId.isNotEmpty) {
                        context.push('/property-details/${deal.propertyId}');
                      }
                    },
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(
                    'Partner Broker',
                    '${partner.name} (${partner.agencyName})',
                    Icons.person_outline,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(
                    'Deal Value',
                    deal.amount,
                    Icons.currency_rupee,
                    isHighlight: true,
                  ),
                  if (deal.agreementDate != null && deal.agreementDate!.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Agreement / Signing Date',
                      deal.agreementDate!,
                      Icons.event_available_rounded,
                      isHighlight: true,
                    ),
                  ],
                  if (deal.tokenDate != null && deal.tokenDate!.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Token Booking Date',
                      deal.tokenDate!,
                      Icons.calendar_month_outlined,
                    ),
                  ],
                  if (deal.tokenAmount != null && deal.tokenAmount!.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Token Amount',
                      deal.tokenAmount!,
                      Icons.currency_rupee,
                    ),
                  ],
                  if (deal.registryDate != null && deal.registryDate!.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Registry Date',
                      deal.registryDate!,
                      Icons.verified_outlined,
                    ),
                  ],
                  if (deal.registrationNumber != null && deal.registrationNumber!.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Registration No',
                      deal.registrationNumber!,
                      Icons.receipt_long_outlined,
                    ),
                  ],
                  if (deal.possessionDate != null && deal.possessionDate!.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Possession Date',
                      deal.possessionDate!,
                      Icons.key_outlined,
                    ),
                  ],
                  if (deal.bankName != null && deal.bankName!.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Lender / Bank',
                      deal.bankName!,
                      Icons.account_balance_outlined,
                    ),
                  ],
                  if (deal.createdAt != null) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Initiated On',
                      DateFormat('dd MMM yyyy • hh:mm a').format(deal.createdAt!),
                      Icons.calendar_today_outlined,
                    ),
                  ],
                ],
              ),
            ),
            const Gap(16),

            // PRD Section 7.5 & 12: Commission & Financial Overview
            _buildSectionCard(
              title: 'Commission & Financials (PRD Sec 7.5)',
              icon: Icons.monetization_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFinancialPill('Est. Total Commission', _formatCurrency(deal.dealValue * 0.02), Colors.purple.shade700, Colors.purple.shade50),
                      const Gap(10),
                      _buildFinancialPill('Co-Broke Split', '50 / 50 Standard', Colors.green.shade700, Colors.green.shade50),
                    ],
                  ),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                        const Gap(8),
                        const Expanded(
                          child: Text(
                            'Each agency earns equal 50% commission upon deal closure per PropConnect guidelines.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRouter.commissions),
                          child: const Text('View Ledger', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // PRD Section 13: Payment Settlement Tracking Ledger
            _buildSectionCard(
              title: 'Payment Settlement Ledger (PRD Sec 13)',
              icon: Icons.account_balance_wallet_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Settlement Status', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            const Gap(2),
                            Text(
                              deal.normalizedStage == 'Deal Closed' ? 'Settled / Paid' : 'Pending Settlement',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: deal.normalizedStage == 'Deal Closed' ? Colors.green.shade700 : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: deal.normalizedStage == 'Deal Closed' ? Colors.green.shade100 : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deal.normalizedStage == 'Deal Closed' ? '100% RECEIVED' : 'AWAITING REGISTRY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: deal.normalizedStage == 'Deal Closed' ? Colors.green.shade800 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.shade200),
                    ),
                    children: [
                      _buildLedgerRow('Due Date', deal.registryDate?.isNotEmpty == true ? '${deal.registryDate} (+15 days)' : 'Within 15 days of deal closure'),
                      _buildLedgerRow('Amount Received', deal.normalizedStage == 'Deal Closed' ? _formatCurrency(deal.dealValue * 0.02) : '₹0'),
                      _buildLedgerRow('Amount Pending', deal.normalizedStage == 'Deal Closed' ? '₹0' : _formatCurrency(deal.dealValue * 0.02)),
                      _buildLedgerRow('Payment Method', 'RTGS / Bank Transfer / NEFT'),
                      _buildLedgerRow('Reference Number', deal.registrationNumber?.isNotEmpty == true ? 'REG-${deal.registrationNumber}' : 'UTR-PENDING'),
                      _buildLedgerRow('Settlement Date', deal.normalizedStage == 'Deal Closed' ? (deal.possessionDate ?? 'Completed') : 'Pending'),
                      _buildLedgerRow('Remarks', deal.remarks?.isNotEmpty == true ? deal.remarks! : 'Standard 50/50 Co-Broke Commission Split'),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(16),

            // PRD Section 11: Deal Chat Action Card
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
                        const Text('Contextual Deal Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                        const Gap(2),
                        Text('Chat in real-time with ${partner.name}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _openChat(context, deal, currentUserId),
                    child: const Text('Open Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // PRD Section 10: Client Info & Lead Privacy Firewall Card
            _buildSectionCard(
              title: canViewClientDetails ? 'Client Information' : 'Client Privacy Firewall (PRD Sec 10)',
              icon: canViewClientDetails ? Icons.person_outline : Icons.shield_outlined,
              trailing: canViewClientDetails
                  ? TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showEditClientDialog(context, deal),
                      icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryBlue),
                      label: const Text('Edit Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!canViewClientDetails) ...[
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
                    const Gap(14),
                    _buildDetailRow('Client Name', deal.clientName ?? 'Verified Buyer Lead', Icons.badge_outlined),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow('Client Phone', '+91 98*** *****', Icons.phone_locked_outlined),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow('Client Email', 'c***@***.com', Icons.mail_lock_outlined),
                  ] else ...[
                    _buildDetailRow('Client Name', deal.clientName?.isNotEmpty == true ? deal.clientName! : 'Buyer Client', Icons.badge_outlined),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Client Phone',
                      deal.clientPhone?.isNotEmpty == true ? deal.clientPhone! : 'Not provided (tap Edit to add)',
                      Icons.phone_outlined,
                      onTap: deal.clientPhone?.isNotEmpty == true ? () => _launchCaller(deal.clientPhone!) : () => _showEditClientDialog(context, deal),
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Client Email',
                      deal.clientEmail?.isNotEmpty == true ? deal.clientEmail! : 'Not provided (tap Edit to add)',
                      Icons.email_outlined,
                      onTap: deal.clientEmail?.isNotEmpty == true ? () => _launchEmail(deal.clientEmail!) : () => _showEditClientDialog(context, deal),
                    ),
                  ],
                  if (deal.clientRequirement != null && deal.clientRequirement!.isNotEmpty) ...[
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow('Requirement', deal.clientRequirement!, Icons.notes_outlined),
                  ],
                ],
              ),
            ),
            const Gap(16),

            // PRD Section 7.3: Deal Document Management
            _buildSectionCard(
              title: 'Deal Documents (PRD Sec 7.3)',
              icon: Icons.folder_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Attached Legal & Transaction Files',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showAddDocumentDialog(context, deal),
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Upload Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Gap(8),
                  if (deal.documents.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_outlined, size: 36, color: Colors.grey.shade400),
                          const Gap(8),
                          const Text(
                            'No documents attached yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const Gap(4),
                          const Text(
                            'Upload token receipts, agreements, KYC, or registry copies for this transaction.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          const Gap(10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _showAddDocumentDialog(context, deal),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(deal.documents.length, (idx) {
                      final doc = deal.documents[idx];
                      final docTitle = doc['title']?.toString() ?? 'Deal Document';
                      final docType = doc['documentType']?.toString() ?? 'Official File';
                      final docUrl = doc['fileUrl']?.toString() ?? '';
                      final uploadedBy = doc['uploadedBy']?.toString() ?? '';
                      final docId = doc['id']?.toString() ?? '';

                      return Column(
                        children: [
                          if (idx > 0) const Divider(height: 16),
                          _buildRealDocumentItem(
                            context: context,
                            deal: deal,
                            docId: docId,
                            title: docTitle,
                            subtitle: '$docType • Uploaded by ${uploadedBy.isNotEmpty ? uploadedBy : "Broker"}',
                            url: docUrl,
                          ),
                        ],
                      );
                    }),
                ],
              ),
            ),
            const Gap(16),

            // PRD Section 4.3.3: Activity & Audit Trail
            _buildSectionCard(
              title: 'Activity Timeline & Audit Trail',
              icon: Icons.history_rounded,
              child: deal.auditHistory.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(12.0), child: Text('No audit events logged yet.', style: TextStyle(color: AppColors.textSecondary))))
                  : ListView.builder(
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
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isFirst ? AppColors.primaryBlue : const Color(0xFFCBD5E1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                              ],
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.status,
                                    style: TextStyle(
                                      fontWeight: isFirst ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isFirst ? Colors.black87 : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('dd MMM yyyy • hh:mm a').format(log.timestamp)} • ${log.updatedBy ?? 'System'}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                                    const Gap(2),
                                    Text(
                                      log.notes!,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                                    const Gap(4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: log.metadata!.entries.map((entry) {
                                        final keyName = entry.key
                                            .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
                                            .trim();
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            '${keyName[0].toUpperCase()}${keyName.substring(1)}: ${entry.value}',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  if (!isLast) const Gap(14),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneTimeline(DealModel deal, int currentIdx, bool isLost) {
    final stages = DealModel.prdMilestones.where((s) => s != 'Deal Lost').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLost) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 20),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deal Closed as Lost', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                      const Gap(2),
                      Text('This transaction was marked as Deal Lost and discontinued.', style: TextStyle(color: Colors.red.shade700, fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        ...List.generate(stages.length, (index) {
          final stage = stages[index];
          final isCompleted = !isLost && index < currentIdx;
          final isCurrent = !isLost && index == currentIdx;

          Color dotColor;
          IconData dotIcon;
          if (isCompleted) {
            dotColor = Colors.green.shade600;
            dotIcon = Icons.check;
          } else if (isCurrent) {
            dotColor = AppColors.primaryBlue;
            dotIcon = Icons.radio_button_checked;
          } else if (isLost) {
            dotColor = Colors.grey.shade400;
            dotIcon = Icons.remove;
          } else {
            dotColor = const Color(0xFFCBD5E1);
            dotIcon = Icons.circle_outlined;
          }

          final isLast = index == stages.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade50 : (isCurrent ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                  child: Icon(dotIcon, size: 14, color: dotColor),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 24,
                    color: isCompleted ? Colors.green.shade400 : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const Gap(12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.bold : (isCompleted ? FontWeight.w600 : FontWeight.normal),
                        color: isCurrent ? AppColors.primaryBlue : (isCompleted ? Colors.black87 : const Color(0xFF94A3B8)),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('CURRENT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    ],
  );
  }

  Widget _buildDatePickerInput({
    required BuildContext context,
    required String label,
    required String? currentDateString,
    required ValueChanged<String> onDateSelected,
    String hintText = 'Tap to select date from calendar',
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12.5)),
          ],
        ),
        const Gap(6),
        InkWell(
          onTap: () async {
            DateTime initial = DateTime.now();
            if (currentDateString != null && currentDateString.isNotEmpty) {
              try {
                initial = DateFormat('dd MMM yyyy').parse(currentDateString);
              } catch (_) {
                try {
                  initial = DateTime.parse(currentDateString);
                } catch (_) {}
              }
            }
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (pickerCtx, child) {
                return Theme(
                  data: Theme.of(pickerCtx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryBlue,
                      onPrimary: Colors.white,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formatted = DateFormat('dd MMM yyyy').format(picked);
              onDateSelected(formatted);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    currentDateString != null && currentDateString.isNotEmpty
                        ? currentDateString
                        : hintText,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: currentDateString != null && currentDateString.isNotEmpty
                          ? AppColors.textPrimary
                          : const Color(0xFF94A3B8),
                      fontWeight: currentDateString != null && currentDateString.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        const Gap(12),
      ],
    );
  }

  void _showAdvanceMilestoneModal(BuildContext context, DealModel deal) {
    String selectedStage = deal.normalizedStage;
    final notesCtrl = TextEditingController();

    // Agreement to Sell
    String? agreementDate = deal.agreementDate ?? DateFormat('dd MMM yyyy').format(DateTime.now());
    String agreementDraftStatus = 'Signed by Both Parties';
    final advanceAmountCtrl = TextEditingController();

    // Token / Booking
    String? tokenDate = deal.tokenDate ?? DateFormat('dd MMM yyyy').format(DateTime.now());
    final tokenAmountCtrl = TextEditingController(text: deal.tokenAmount ?? '');
    String tokenPaymentMode = 'RTGS / NEFT';

    // Site Visit
    String? visitDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    String visitSlot = 'Morning (10:00 AM - 12:00 PM)';
    final visitFeedbackCtrl = TextEditingController();

    // Negotiation
    final offerAmountCtrl = TextEditingController(text: deal.amount);
    String? targetCloseDate;

    // Loan Processing
    final bankNameCtrl = TextEditingController(text: deal.bankName ?? 'HDFC Home Loans');
    final loanAmountCtrl = TextEditingController(text: deal.loanAmount ?? '');
    String? sanctionDate;

    // Registry
    String? registryDate = deal.registryDate ?? DateFormat('dd MMM yyyy').format(DateTime.now());
    final regNumberCtrl = TextEditingController(text: deal.registrationNumber ?? '');
    final subRegistrarOfficeCtrl = TextEditingController();

    // Possession
    String? possessionDate = deal.possessionDate ?? DateFormat('dd MMM yyyy').format(DateTime.now());
    final possessionNotesCtrl = TextEditingController();

    // Deal Closed
    String? settlementDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Deal Lost
    String lostReason = 'Client Budget Issue';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isSiteVisit = selectedStage.contains('Site Visit');
            final isNegotiation = selectedStage.contains('Negotiation') || selectedStage.contains('Offer');
            final isToken = selectedStage.contains('Token');
            final isAgreement = selectedStage.contains('Agreement');
            final isLoan = selectedStage.contains('Loan');
            final isRegistry = selectedStage.contains('Registry');
            final isPossession = selectedStage.contains('Possession');
            final isClosed = selectedStage == 'Deal Closed';
            final isLost = selectedStage == 'Deal Lost';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Update Transaction Milestone & Dates',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    const Gap(10),
                    const Text('Select Target Milestone *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStage,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: DealModel.prdMilestones.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedStage = val);
                        }
                      },
                    ),
                    const Gap(14),

                    // Milestone Specific Fields with Interactive Calendar Pickers (PRD Sec 4.4)
                    if (isAgreement) ...[
                      _buildDatePickerInput(
                        context: context,
                        label: 'Agreement Draft / Signing Date',
                        isRequired: true,
                        currentDateString: agreementDate,
                        onDateSelected: (newDate) => setModalState(() => agreementDate = newDate),
                      ),
                      const Text('Agreement Legal Status *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      DropdownButtonFormField<String>(
                        initialValue: agreementDraftStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          'Draft Prepared & Circulated',
                          'Under Legal Review',
                          'Signed by Both Parties',
                          'Registered Agreement Copy Issued',
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => agreementDraftStatus = val);
                        },
                      ),
                      const Gap(12),
                      const Text('Advance / Part Payment (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: advanceAmountCtrl,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'e.g. ₹25,00,000',
                          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                    ] else if (isToken) ...[
                      const Text('Token Booking Amount (INR) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: tokenAmountCtrl,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'e.g. ₹5,00,000',
                          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                      _buildDatePickerInput(
                        context: context,
                        label: 'Token Payment Date',
                        isRequired: true,
                        currentDateString: tokenDate,
                        onDateSelected: (newDate) => setModalState(() => tokenDate = newDate),
                      ),
                      const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      DropdownButtonFormField<String>(
                        initialValue: tokenPaymentMode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          'RTGS / NEFT',
                          'Cheque',
                          'UPI',
                          'Bank Demand Draft',
                          'Cash Deposit',
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => tokenPaymentMode = val);
                        },
                      ),
                      const Gap(12),
                    ] else if (isSiteVisit) ...[
                      _buildDatePickerInput(
                        context: context,
                        label: 'Site Visit Date',
                        isRequired: true,
                        currentDateString: visitDate,
                        onDateSelected: (newDate) => setModalState(() => visitDate = newDate),
                      ),
                      const Text('Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      DropdownButtonFormField<String>(
                        initialValue: visitSlot,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          'Morning (10:00 AM - 12:00 PM)',
                          'Afternoon (1:00 PM - 3:00 PM)',
                          'Evening (4:00 PM - 6:00 PM)',
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => visitSlot = val);
                        },
                      ),
                      const Gap(12),
                      const Text('Visitor Feedback / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: visitFeedbackCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Client liked 3 BHK layout, requested second visit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                    ] else if (isNegotiation) ...[
                      const Text('Offer / Proposed Amount *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: offerAmountCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. ₹4,15,00,000',
                          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                      _buildDatePickerInput(
                        context: context,
                        label: 'Target Closing Date',
                        currentDateString: targetCloseDate,
                        onDateSelected: (newDate) => setModalState(() => targetCloseDate = newDate),
                      ),
                    ] else if (isLoan) ...[
                      const Text('Bank / Institution Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: bankNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. HDFC Home Loans / SBI',
                          prefixIcon: const Icon(Icons.account_balance, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                      _buildDatePickerInput(
                        context: context,
                        label: 'Sanction / Filing Date',
                        currentDateString: sanctionDate,
                        onDateSelected: (newDate) => setModalState(() => sanctionDate = newDate),
                      ),
                      const Text('Sanctioned Loan Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: loanAmountCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. ₹2,50,00,000',
                          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                    ] else if (isRegistry) ...[
                      _buildDatePickerInput(
                        context: context,
                        label: 'Registration & Stamp Duty Date',
                        isRequired: true,
                        currentDateString: registryDate,
                        onDateSelected: (newDate) => setModalState(() => registryDate = newDate),
                      ),
                      const Text('Registration Number / Deed Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: regNumberCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. REG-MH-2026-8941',
                          prefixIcon: const Icon(Icons.verified, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                      const Text('Sub-Registrar Office', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: subRegistrarOfficeCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Bandra Sub-Registrar Office II',
                          prefixIcon: const Icon(Icons.location_city, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                    ] else if (isPossession) ...[
                      _buildDatePickerInput(
                        context: context,
                        label: 'Key Handover & Possession Date',
                        isRequired: true,
                        currentDateString: possessionDate,
                        onDateSelected: (newDate) => setModalState(() => possessionDate = newDate),
                      ),
                      const Text('Key Handover Confirmation & Notes *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      TextField(
                        controller: possessionNotesCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Physical keys handed over and inventory verified in person',
                          prefixIcon: const Icon(Icons.key, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const Gap(12),
                    ] else if (isClosed) ...[
                      _buildDatePickerInput(
                        context: context,
                        label: 'Final Deal Settlement Date',
                        isRequired: true,
                        currentDateString: settlementDate,
                        onDateSelected: (newDate) => setModalState(() => settlementDate = newDate),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            const Gap(10),
                            const Expanded(
                              child: Text(
                                'Marking Deal Closed will calculate commission, trigger WhatsApp notifications, and close the deal pipeline.',
                                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                    ] else if (isLost) ...[
                      const Text('Reason for Lost Deal *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const Gap(6),
                      DropdownButtonFormField<String>(
                        initialValue: lostReason,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          'Client Budget Issue',
                          'Property Price Negotiation Failed',
                          'Loan Rejected',
                          'Bought Competitor Property',
                          'Client Postponed Purchase',
                          'Other',
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => lostReason = val);
                        },
                      ),
                      const Gap(12),
                    ],

                    const Text('Milestone Remarks & Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const Gap(6),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add notes for the audit trail...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const Gap(20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedStage == 'Deal Lost' ? Colors.red.shade700 : AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final Map<String, dynamic> metadata = {};
                          if (isAgreement) {
                            if (agreementDate != null && agreementDate!.isNotEmpty) metadata['agreementDate'] = agreementDate;
                            metadata['draftStatus'] = agreementDraftStatus;
                            if (advanceAmountCtrl.text.trim().isNotEmpty) metadata['advanceAmount'] = advanceAmountCtrl.text.trim();
                          } else if (isToken) {
                            if (tokenAmountCtrl.text.trim().isNotEmpty) metadata['tokenAmount'] = tokenAmountCtrl.text.trim();
                            if (tokenDate != null && tokenDate!.isNotEmpty) metadata['tokenDate'] = tokenDate;
                            metadata['paymentMode'] = tokenPaymentMode;
                          } else if (isSiteVisit) {
                            if (visitDate != null && visitDate!.isNotEmpty) metadata['visitDate'] = visitDate;
                            metadata['visitSlot'] = visitSlot;
                            if (visitFeedbackCtrl.text.trim().isNotEmpty) metadata['feedback'] = visitFeedbackCtrl.text.trim();
                          } else if (isNegotiation) {
                            if (offerAmountCtrl.text.trim().isNotEmpty) metadata['offerAmount'] = offerAmountCtrl.text.trim();
                            if (targetCloseDate != null && targetCloseDate!.isNotEmpty) metadata['targetCloseDate'] = targetCloseDate;
                          } else if (isLoan) {
                            if (bankNameCtrl.text.trim().isNotEmpty) metadata['bankName'] = bankNameCtrl.text.trim();
                            if (loanAmountCtrl.text.trim().isNotEmpty) metadata['loanAmount'] = loanAmountCtrl.text.trim();
                            if (sanctionDate != null && sanctionDate!.isNotEmpty) metadata['sanctionDate'] = sanctionDate;
                          } else if (isRegistry) {
                            if (registryDate != null && registryDate!.isNotEmpty) metadata['registryDate'] = registryDate;
                            if (regNumberCtrl.text.trim().isNotEmpty) metadata['registrationNumber'] = regNumberCtrl.text.trim();
                            if (subRegistrarOfficeCtrl.text.trim().isNotEmpty) metadata['subRegistrarOffice'] = subRegistrarOfficeCtrl.text.trim();
                          } else if (isPossession) {
                            if (possessionDate != null && possessionDate!.isNotEmpty) metadata['possessionDate'] = possessionDate;
                            if (possessionNotesCtrl.text.trim().isNotEmpty) metadata['possessionNotes'] = possessionNotesCtrl.text.trim();
                          } else if (isClosed) {
                            if (settlementDate != null && settlementDate!.isNotEmpty) metadata['settlementDate'] = settlementDate;
                          } else if (isLost) {
                            metadata['lostReason'] = lostReason;
                          }

                          ref.read(dealProvider.notifier).updateDealStatus(
                                deal.id,
                                selectedStage,
                                notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Updated milestone to $selectedStage',
                                metadata,
                              );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deal ${deal.id} updated at "$selectedStage"!'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        },
                        child: const Text(
                          'Confirm Milestone Update',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                    const Gap(24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDocumentDialog(BuildContext context, DealModel deal) {
    final titleCtrl = TextEditingController(text: 'Token Booking Receipt');
    final notesCtrl = TextEditingController();
    String selectedType = 'Token Booking Receipt';
    bool isUploading = false;
    String uploadStatusText = '';

    Uint8List? selectedFileBytes;
    String selectedFileName = '';
    String selectedFileExt = '';
    String selectedFileSizeStr = '';

    final userData = AuthStorageService.getUserData();
    final currentUserName = userData?['name'] as String? ?? 'Broker';

    String formatBytes(int bytes) {
      if (bytes <= 0) return '0 B';
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    Future<void> pickWithFilePicker(void Function(void Function()) setDialogState) async {
      try {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp', 'txt'],
        );

        if (file != null) {
          final bytes = await file.readAsBytes();
          final fileName = file.name;
          final ext = (file.extension ?? (fileName.contains('.') ? fileName.split('.').last : '')).toLowerCase();
          final size = file.lengthSync() ?? bytes.length;
          final sizeStr = formatBytes(size);

          setDialogState(() {
            selectedFileBytes = bytes;
            selectedFileName = fileName;
            selectedFileExt = ext;
            selectedFileSizeStr = sizeStr;

            if (titleCtrl.text.isEmpty || titleCtrl.text == 'Token Booking Receipt') {
              final base = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
              titleCtrl.text = base.replaceAll('_', ' ').replaceAll('-', ' ');
            }
          });
        }
      } catch (err) {
        debugPrint('File picker error: $err');
      }
    }

    Future<void> pickWithImagePicker(void Function(void Function()) setDialogState, {required bool fromCamera}) async {
      try {
        final picker = ImagePicker();
        final xfile = await picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (xfile != null) {
          final bytes = await xfile.readAsBytes();
          final fileName = xfile.name;
          final ext = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
          final sizeStr = formatBytes(bytes.length);

          setDialogState(() {
            selectedFileBytes = bytes;
            selectedFileName = fileName;
            selectedFileExt = ext;
            selectedFileSizeStr = sizeStr;

            if (titleCtrl.text.isEmpty || titleCtrl.text == 'Token Booking Receipt') {
              titleCtrl.text = '$selectedType - Photo';
            }
          });
        }
      } catch (err) {
        debugPrint('Image picker error: $err');
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_file, color: AppColors.primaryBlue, size: 20),
                  ),
                  const Gap(10),
                  const Text('Upload Deal Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attach an official document (PDF, Scan, Agreement, or KYC) to this deal folder.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const Gap(14),

                    // File Selector Container
                    const Text('Document File *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Gap(6),
                    if (selectedFileBytes == null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.35), width: 1.2),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryBlue, size: 32),
                            const Gap(8),
                            const Text(
                              'Choose Document or Take Photo',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const Gap(4),
                            const Text(
                              'Supported: PDF, DOC, DOCX, JPG, PNG up to 25MB',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const Gap(12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => pickWithFilePicker(setDialogState),
                                  icon: const Icon(Icons.folder_open, size: 16),
                                  label: const Text('Browse PDF / File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const Gap(8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    side: const BorderSide(color: AppColors.primaryBlue),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => pickWithImagePicker(setDialogState, fromCamera: false),
                                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                                  label: const Text('Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                selectedFileExt == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : (['jpg', 'jpeg', 'png', 'webp'].contains(selectedFileExt)
                                        ? Icons.image
                                        : Icons.description),
                                color: selectedFileExt == 'pdf'
                                    ? Colors.red.shade700
                                    : (['jpg', 'jpeg', 'png', 'webp'].contains(selectedFileExt)
                                        ? Colors.blue.shade700
                                        : Colors.orange.shade700),
                                size: 24,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Gap(2),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                                      const Gap(4),
                                      Text(
                                        '$selectedFileSizeStr • Ready to upload',
                                        style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                              tooltip: 'Remove',
                              onPressed: () {
                                setDialogState(() {
                                  selectedFileBytes = null;
                                  selectedFileName = '';
                                  selectedFileExt = '';
                                  selectedFileSizeStr = '';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    const Gap(14),

                    const Text('Document Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Gap(6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        'Token Booking Receipt',
                        'Agreement to Sell',
                        'Loan Sanction Letter',
                        'Registry Copy',
                        'Buyer KYC Documents',
                        'NOC & Tax Clearance',
                        'Possession Handover Letter',
                        'Payment Cheque / Slip',
                        'Other Legal Document',
                      ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedType = val;
                            if (titleCtrl.text.isEmpty || titleCtrl.text == 'Token Booking Receipt') {
                              titleCtrl.text = val;
                            }
                          });
                        }
                      },
                    ),
                    const Gap(14),

                    const Text('Document Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Gap(6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Executed Agreement Copy',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const Gap(14),

                    const Text('Notes / Remarks (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Gap(6),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Signed by buyer and seller on 23 Sep',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    if (isUploading && uploadStatusText.isNotEmpty) ...[
                      const Gap(12),
                      Row(
                        children: [
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              uploadStatusText,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (selectedFileBytes == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please choose a document file or photo first.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a document title')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                            uploadStatusText = 'Uploading document to cloud storage...';
                          });

                          try {
                            // 1. Build Base64 data URI
                            final b64 = base64Encode(selectedFileBytes!);
                            String mimeType = 'application/pdf';
                            if (selectedFileExt == 'png') {
                              mimeType = 'image/png';
                            } else if (selectedFileExt == 'jpg' || selectedFileExt == 'jpeg') {
                              mimeType = 'image/jpeg';
                            } else if (selectedFileExt == 'webp') {
                              mimeType = 'image/webp';
                            } else if (selectedFileExt == 'doc' || selectedFileExt == 'docx') {
                              mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
                            } else if (selectedFileExt == 'txt') {
                              mimeType = 'text/plain';
                            }

                            final dataUri = 'data:$mimeType;base64,$b64';

                            // 2. Upload file to server /upload/base64 endpoint
                            final uploadRes = await ApiService.uploadFileBase64(
                              base64Data: dataUri,
                              fileName: selectedFileName.isNotEmpty ? selectedFileName : '${title.replaceAll(' ', '_')}.$selectedFileExt',
                            );

                            String? hostedUrl;
                            if (uploadRes['success'] == true && uploadRes['data'] != null) {
                              hostedUrl = uploadRes['data']['url']?.toString();
                            }

                            setDialogState(() {
                              uploadStatusText = 'Attaching document to deal record...';
                            });

                            // 3. Attach document to the deal
                            final res = await ApiService.uploadDealDocument(
                              deal.id,
                              title: title,
                              documentType: selectedType,
                              fileUrl: hostedUrl,
                              uploadedBy: currentUserName,
                              notes: notesCtrl.text.trim(),
                            );

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              if (res['success'] == true) {
                                ref.read(dealProvider.notifier).fetchDeals();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                        const Gap(8),
                                        Expanded(child: Text('Document "$title" successfully uploaded & attached.')),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'Failed to upload document')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Upload error: $e')),
                              );
                            }
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Upload Document'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRealDocumentItem({
    required BuildContext context,
    required DealModel deal,
    required String docId,
    required String title,
    required String subtitle,
    required String url,
  }) {
    IconData icon;
    Color color;

    final lower = title.toLowerCase() + subtitle.toLowerCase() + url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red.shade700;
    } else if (lower.contains('receipt') || lower.contains('token')) {
      icon = Icons.receipt_long_outlined;
      color = Colors.green.shade700;
    } else if (lower.contains('agree') || lower.contains('sale')) {
      icon = Icons.description_outlined;
      color = Colors.blue.shade700;
    } else if (lower.contains('regist') || lower.contains('sub-reg')) {
      icon = Icons.assignment_turned_in_outlined;
      color = Colors.orange.shade700;
    } else if (lower.contains('loan') || lower.contains('bank')) {
      icon = Icons.account_balance_outlined;
      color = Colors.indigo.shade700;
    } else if (lower.contains('.jpg') || lower.contains('.png') || lower.contains('.webp') || lower.contains('photo')) {
      icon = Icons.image_outlined;
      color = Colors.teal.shade700;
    } else {
      icon = Icons.insert_drive_file_outlined;
      color = AppColors.primaryBlue;
    }

    String resolvedUrl = url;
    if (resolvedUrl.isNotEmpty && resolvedUrl.startsWith('/uploads/')) {
      resolvedUrl = 'http://72.61.229.6:5000$resolvedUrl';
    }

    void openDocument() async {
      if (resolvedUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file URL available for this document.')),
        );
        return;
      }

      final isImage = resolvedUrl.toLowerCase().contains('.jpg') ||
          resolvedUrl.toLowerCase().contains('.jpeg') ||
          resolvedUrl.toLowerCase().contains('.png') ||
          resolvedUrl.toLowerCase().contains('.webp');

      if (isImage) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      resolvedUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (_, _, _) => Container(
                        padding: const EdgeInsets.all(24),
                        color: Colors.white,
                        child: const Text('Failed to load image preview.'),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }

      try {
        final uri = Uri.parse(resolvedUrl);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open document: $err')),
          );
        }
      }
    }

    return InkWell(
      onTap: openDocument,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryBlue),
              tooltip: 'View Document',
              onPressed: openDocument,
            ),
            IconButton(
              icon: const Icon(Icons.file_download_outlined, size: 18, color: AppColors.primaryBlue),
              tooltip: 'Open / Download Document',
              onPressed: openDocument,
            ),
            if (docId.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Delete Document',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Document?'),
                      content: Text('Are you sure you want to delete "$title"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ApiService.deleteDealDocument(deal.id, docId);
                    ref.read(dealProvider.notifier).fetchDeals();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document removed')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, DealModel deal) {
    final nameCtrl = TextEditingController(text: deal.clientName ?? '');
    final phoneCtrl = TextEditingController(text: deal.clientPhone ?? '');
    final emailCtrl = TextEditingController(text: deal.clientEmail ?? '');
    final reqCtrl = TextEditingController(text: deal.clientRequirement ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Client Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Text(
                      'Client contact info is visible to both deal collaborators.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Gap(16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Client Name',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const Gap(12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        hintText: '+91 98765 43210',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const Gap(12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        hintText: 'client@example.com',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const Gap(12),
                    TextField(
                      controller: reqCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Specific Preferences / Requirement',
                        prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const Gap(20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                await ref.read(dealProvider.notifier).updateClientInfo(
                                      deal.id,
                                      clientName: nameCtrl.text.trim(),
                                      clientPhone: phoneCtrl.text.trim(),
                                      clientEmail: emailCtrl.text.trim(),
                                      clientRequirement: reqCtrl.text.trim(),
                                    );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Client details updated successfully')),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchCaller(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final clean = email.trim();
    final uri = Uri.parse('mailto:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildFinancialPill(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
            const Gap(2),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  TableRow _buildLedgerRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const Gap(8),
                trailing,
              ],
            ],
          ),
          const Gap(14),
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
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: isHighlight ? Colors.green : AppColors.iconColor, size: 16),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                const Gap(2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isHighlight ? 16 : 13.5,
                    color: isHighlight ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
        ],
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

  List<Color> _getStatusGradient(String stage) {
    switch (stage) {
      case 'Deal Closed':
        return [Colors.green.shade600, Colors.teal.shade700];
      case 'Possession':
      case 'Registry':
        return [Colors.teal.shade600, Colors.cyan.shade800];
      case 'Agreement to Sell':
      case 'Token / Booking':
        return [Colors.indigo.shade600, Colors.blue.shade800];
      case 'Negotiation':
      case 'Site Visit':
        return [Colors.blue.shade600, Colors.indigo.shade700];
      case 'Deal Lost':
        return [Colors.red.shade600, Colors.red.shade900];
      case 'Inquiry':
      default:
        return [Colors.orange.shade600, Colors.deepOrange.shade700];
    }
  }

  String _formatCurrency(double amount) {
    if (amount <= 0) return '₹0';
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}
