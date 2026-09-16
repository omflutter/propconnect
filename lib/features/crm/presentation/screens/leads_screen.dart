import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  String _selectedStage = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _stages = [
    'All',
    'Lead Assigned',
    'Site Visit',
    'Negotiation',
    'Token Done',
    'Closed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(dealProvider);
    final properties = ref.watch(propertyProvider);
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';
    final currentAgencyId = userData?['agencyId']?.toString() ?? userData?['agency']?['id']?.toString() ?? '1';

    // Filter deals that represent client leads / deal pipelines
    final filteredLeads = deals.where((deal) {
      if (_selectedStage != 'All') {
        if (_selectedStage == 'Site Visit' && !deal.status.toLowerCase().contains('visit')) {
          return false;
        } else if (_selectedStage != 'Site Visit' && !deal.status.toLowerCase().contains(_selectedStage.toLowerCase())) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchProperty = deal.propertyName.toLowerCase().contains(query);
        final matchCode = deal.dealCode.toLowerCase().contains(query);
        final matchPartner = deal.partnerBroker.toLowerCase().contains(query);
        final matchClient = (deal.clientName ?? '').toLowerCase().contains(query);
        final matchReq = (deal.clientRequirement ?? '').toLowerCase().contains(query);
        return matchProperty || matchCode || matchPartner || matchClient || matchReq;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Client Leads CRM',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            tooltip: 'Refresh Leads',
            onPressed: () => ref.read(dealProvider.notifier).fetchDeals(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () => _showAddLeadDialog(context, properties),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('New Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by client, property, or requirement...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const Gap(10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _stages.map((stage) {
                      final isSelected = _selectedStage == stage;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            stage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: Colors.grey.shade100,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (_) => setState(() => _selectedStage = stage),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Leads List
          Expanded(
            child: filteredLeads.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async => ref.read(dealProvider.notifier).fetchDeals(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLeads.length,
                      separatorBuilder: (_, _) => const Gap(12),
                      itemBuilder: (context, index) {
                        final lead = filteredLeads[index];
                        final isLeadOwner = lead.brokerAId?.toString() == currentUserId ||
                            lead.agencyAId?.toString() == currentAgencyId;
                        return _buildLeadCard(lead, isLeadOwner);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_outlined, size: 48, color: AppColors.primaryBlue),
            ),
            const Gap(16),
            const Text(
              'No Client Leads Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Gap(8),
            const Text(
              'All client inquiries, deal registrations, and buyer requirements will be managed here with strict broker privacy firewalls.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadCard(DealModel lead, bool isLeadOwner) {
    Color stageColor;
    switch (lead.status.toLowerCase()) {
      case 'closed':
      case 'won':
        stageColor = Colors.green;
        break;
      case 'token':
      case 'token done':
      case 'agreement signed':
        stageColor = Colors.teal;
        break;
      case 'negotiation':
        stageColor = Colors.orange;
        break;
      case 'site visit':
      case 'site visit scheduled':
        stageColor = Colors.indigo;
        break;
      case 'dropped':
      case 'rejected':
        stageColor = Colors.red;
        break;
      default:
        stageColor = AppColors.primaryBlue;
    }

    final rawPhone = lead.clientPhone ?? '+91 98765 43210';
    final maskedPhone = isLeadOwner
        ? rawPhone
        : rawPhone.length > 7
            ? '${rawPhone.substring(0, 7)}***${rawPhone.substring(rawPhone.length - 2)}'
            : '+91 98***10';

    final clientDisplayName = lead.clientName ?? 'Direct Client (${lead.dealCode})';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Stage Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  clientDisplayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Gap(2),
                    Row(
                      children: [
                        Icon(
                          isLeadOwner ? Icons.lock_open : Icons.shield_outlined,
                          size: 13,
                          color: isLeadOwner ? Colors.green : AppColors.textSecondary,
                        ),
                        const Gap(4),
                        Text(
                          isLeadOwner ? 'Owner Access' : 'Privacy Protected (PRD Sec 10)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isLeadOwner ? Colors.green : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  lead.status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stageColor),
                ),
              ),
            ],
          ),

          const Gap(12),
          const Divider(height: 1),
          const Gap(12),

          // Property Requirement & Budget
          Row(
            children: [
              const Icon(Icons.home_work_outlined, size: 16, color: AppColors.textSecondary),
              const Gap(8),
              Expanded(
                child: Text(
                  lead.propertyName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                lead.amount.isNotEmpty ? lead.amount : '₹${(lead.dealValue / 100000).toStringAsFixed(1)} L',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ],
          ),

          if (lead.clientRequirement != null && lead.clientRequirement!.isNotEmpty) ...[
            const Gap(6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined, size: 16, color: AppColors.textSecondary),
                const Gap(8),
                Expanded(
                  child: Text(
                    lead.clientRequirement!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const Gap(8),
          // Contact row
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
              const Gap(8),
              Text(
                maskedPhone,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'Deal #${lead.dealCode}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),

          const Gap(14),

          // Action Buttons
          Row(
            children: [
              if (isLeadOwner) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.green),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () async {
                      final cleanNumber = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
                      final url = Uri.parse('https://wa.me/$cleanNumber?text=Hello%20$clientDisplayName,%20regarding%20your%20interest%20in%20${Uri.encodeComponent(lead.propertyName)}:');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
                const Gap(8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                  label: const Text('Update Stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _showUpdateStageSheet(context, lead),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStageSheet(BuildContext context, DealModel lead) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final stages = [
          'Lead Assigned',
          'Site Visit Scheduled',
          'Negotiation',
          'Token Done',
          'Agreement Signed',
          'Closed',
          'Dropped',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Stage: ${lead.dealCode}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Gap(12),
                ...stages.map((stage) {
                  final isCurrent = lead.status.toLowerCase() == stage.toLowerCase();
                  return ListTile(
                    dense: true,
                    title: Text(
                      stage,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primaryBlue : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isCurrent ? const Icon(Icons.check_circle, color: AppColors.primaryBlue) : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref.read(dealProvider.notifier).updateDealStatus(lead.id, stage, 'Stage changed to $stage via CRM Leads');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lead stage updated to $stage')),
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddLeadDialog(BuildContext context, List<PropertyModel> properties) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final reqCtrl = TextEditingController();
    String? selectedPropertyId = properties.isNotEmpty ? properties.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Client Lead', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Client Name *', isDense: true),
                ),
                const Gap(8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Client Phone *', isDense: true),
                ),
                const Gap(8),
                TextField(
                  controller: budgetCtrl,
                  decoration: const InputDecoration(labelText: 'Budget (e.g. ₹1.5 Cr)', isDense: true),
                ),
                const Gap(8),
                if (properties.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedPropertyId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Interested Property', isDense: true),
                    items: properties.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedPropertyId = val),
                  ),
                  const Gap(8),
                ],
                TextField(
                  controller: reqCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Client Requirement Notes', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  return;
                }
                
                final selectedProp = properties.isNotEmpty
                    ? properties.firstWhere(
                        (p) => p.id == selectedPropertyId,
                        orElse: () => properties.first,
                      )
                    : null;

                final userData = AuthStorageService.getUserData();
                final currentUserId = int.tryParse(userData?['id']?.toString() ?? '1') ?? 1;
                final currentAgencyId = int.tryParse(userData?['agencyId']?.toString() ?? '1') ?? 1;
                final userName = userData?['name']?.toString() ?? 'Broker Agent';
                final agencyName = userData?['agencyName']?.toString() ?? 'Sunrise Properties';

                double parsedDealVal = 10000000.0;
                if (selectedProp != null) {
                  parsedDealVal = double.tryParse(selectedProp.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 10000000.0;
                }

                final newDeal = DealModel(
                  id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                  dealCode: 'LD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  propertyId: selectedProp?.id ?? '0',
                  propertyName: selectedProp?.title ?? 'General Requirement',
                  agencyAId: currentAgencyId,
                  agencyAName: agencyName,
                  brokerAId: currentUserId,
                  brokerAName: userName,
                  partnerBroker: userName,
                  partnerAgency: agencyName,
                  status: 'Lead Assigned',
                  amount: budgetCtrl.text.trim().isNotEmpty ? budgetCtrl.text.trim() : '₹1.00 Cr',
                  dealValue: parsedDealVal,
                  clientName: nameCtrl.text.trim(),
                  clientPhone: phoneCtrl.text.trim(),
                  clientRequirement: reqCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );

                Navigator.pop(ctx);
                await ref.read(dealProvider.notifier).addDeal(newDeal);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client lead created successfully!')),
                  );
                }
              },
              child: const Text('Create Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

