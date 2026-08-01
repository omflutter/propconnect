import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/routing/app_router.dart';

class CollaborationsScreen extends ConsumerWidget {
  const CollaborationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Collaborations Hub'),
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryBlue,
            tabs: [
              Tab(text: 'Sent'),
              Tab(text: 'Incoming'),
              Tab(text: 'Responded'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CollaborationListTab(type: CollaborationTabType.sent),
            _CollaborationListTab(type: CollaborationTabType.incoming),
            _CollaborationListTab(type: CollaborationTabType.responded),
          ],
        ),
      ),
    );
  }
}

enum CollaborationTabType { sent, incoming, responded }

class _CollaborationListTab extends ConsumerStatefulWidget {
  final CollaborationTabType type;
  const _CollaborationListTab({required this.type});

  @override
  ConsumerState<_CollaborationListTab> createState() => _CollaborationListTabState();
}

class _CollaborationListTabState extends ConsumerState<_CollaborationListTab> {
  String _selectedStatus = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(dealProvider);
    
    // 1. Filter by Tab Type
    List<DealModel> baseRequests;
    List<String> availableStatuses = ['All'];
    
    switch (widget.type) {
      case CollaborationTabType.sent:
        baseRequests = deals.where((d) => d.isRequest && !d.isIncomingRequest).toList();
        availableStatuses.addAll(['Pending', 'Approved', 'Rejected']);
        break;
      case CollaborationTabType.incoming:
        baseRequests = deals.where((d) => d.isRequest && d.isIncomingRequest).toList();
        availableStatuses.addAll(['Pending']); // Usually only pending in this tab
        break;
      case CollaborationTabType.responded:
        baseRequests = deals.where((d) => !d.isRequest && (d.status == 'Approved' || d.status == 'Rejected')).toList();
        availableStatuses.addAll(['Approved', 'Rejected']);
        break;
    }

    // 2. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      baseRequests = baseRequests.where((d) => 
        d.propertyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.partnerBroker.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.id.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // 3. Filter by Date Range
    if (_startDate != null && _endDate != null) {
      baseRequests = baseRequests.where((d) {
        if (d.createdAt == null) return false;
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        return d.createdAt!.isAfter(start) && d.createdAt!.isBefore(end);
      }).toList();
    }

    // 4. Filter by Selected Status
    final filteredRequests = _selectedStatus == 'All' 
        ? baseRequests 
        : baseRequests.where((d) => d.status == _selectedStatus).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by property, broker or ID',
              prefixIcon: const Icon(Icons.search, color: AppColors.iconColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _startDate != null ? Icons.clear : Icons.calendar_month,
                  color: _startDate != null ? AppColors.primaryBlue : AppColors.iconColor,
                ),
                onPressed: () async {
                  if (_startDate != null) {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  } else {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primaryBlue,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    }
                  }
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            ),
          ),
        ),
        // Filter Chips
        if (availableStatuses.length > 1)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableStatuses.length,
              separatorBuilder: (context, index) => const Gap(8),
              itemBuilder: (context, index) {
                final status = availableStatuses[index];
                final isSelected = _selectedStatus == status;
                return FilterChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryBlue : AppColors.border,
                    ),
                  ),
                );
              },
            ),
          ),
          
        // List
        Expanded(
          child: filteredRequests.isEmpty
              ? Center(child: Text('No requests found.', style: const TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final deal = filteredRequests[index];
                    return _buildRequestCard(
                      context, 
                      deal, 
                      isIncoming: widget.type == CollaborationTabType.incoming, 
                      isResponded: widget.type == CollaborationTabType.responded,
                      ref: ref,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Widget _buildRequestCard(BuildContext context, DealModel deal, {required bool isIncoming, WidgetRef? ref, bool isResponded = false}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () {
        context.push(AppRouter.collaborationDetails.replaceAll(':id', deal.id));
      },
      child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(deal.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isResponded 
                      ? (deal.status == 'Approved' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1))
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  deal.status,
                  style: TextStyle(
                    color: isResponded 
                        ? (deal.status == 'Approved' ? Colors.green : Colors.red)
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          // Direction Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  deal.isIncomingRequest ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 12,
                  color: Colors.blueGrey,
                ),
                const Gap(4),
                Text(
                  deal.isIncomingRequest 
                      ? '${deal.partnerBroker} (${deal.partnerAgency}) Requested' 
                      : 'You Requested ${deal.partnerBroker} (${deal.partnerAgency})',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          const Gap(8),
          Text(deal.propertyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Gap(8),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
              const Gap(4),
              Text(deal.partnerBroker, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              const Icon(Icons.monetization_on, size: 14, color: AppColors.textSecondary),
              const Gap(4),
              Text('Budget: ${deal.amount}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
          if (deal.createdAt != null) ...[
            const Gap(8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const Gap(4),
                Text('Requested: ${DateFormat('MMM dd, yyyy').format(deal.createdAt!)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
          if (isResponded && deal.respondedAt != null) ...[
            const Gap(4),
            Row(
              children: [
                const Icon(Icons.done_all, size: 14, color: AppColors.textSecondary),
                const Gap(4),
                Text('Responded: ${DateFormat('MMM dd, yyyy').format(deal.respondedAt!)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
          
          if (isIncoming && ref != null) ...[
            const Gap(16),
            const Divider(),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(dealProvider.notifier).updateDealStatus(deal.id, 'Rejected');
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(dealProvider.notifier).updateDealStatus(deal.id, 'Approved');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    ),
  );
}
