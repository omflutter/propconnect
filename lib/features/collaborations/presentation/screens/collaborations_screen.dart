import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/broker_directory_service.dart';

class CollaborationsScreen extends ConsumerWidget {
  const CollaborationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(accessibleDealsProvider);
    final collabRequests = deals.where((d) => d.isRequest).toList();

    final incomingRequests = collabRequests.where((d) => d.isIncomingRequest).toList();
    final sentRequests = collabRequests.where((d) => !d.isIncomingRequest).toList();

    // Summary counts
    final incomingPending = incomingRequests.where((d) => d.status == 'Pending').length;
    final sentPending = sentRequests.where((d) => d.status == 'Pending').length;
    final approvedDeals = collabRequests.where((d) => d.status == 'Approved').length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collaborations Hub',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
              Text(
                'Inter-Agency Co-Broking Network',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
              tooltip: 'Refresh Collaborations',
              onPressed: () {
                ref.read(dealProvider.notifier).fetchDeals();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(108),
            child: Column(
              children: [
                // Top KPI Summary Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildMetricPill(
                        label: 'Action Needed',
                        count: incomingPending,
                        color: incomingPending > 0 ? Colors.orange.shade700 : AppColors.textSecondary,
                        bgColor: incomingPending > 0 ? Colors.orange.shade50 : Colors.grey.shade100,
                        icon: Icons.inbox_outlined,
                      ),
                      const Gap(8),
                      _buildMetricPill(
                        label: 'Awaiting Partner',
                        count: sentPending,
                        color: sentPending > 0 ? AppColors.primaryBlue : AppColors.textSecondary,
                        bgColor: sentPending > 0 ? const Color(0xFFEFF6FF) : Colors.grey.shade100,
                        icon: Icons.outbox_outlined,
                      ),
                      const Gap(8),
                      _buildMetricPill(
                        label: 'Active Co-Broke',
                        count: approvedDeals,
                        color: Colors.green.shade700,
                        bgColor: Colors.green.shade50,
                        icon: Icons.handshake_outlined,
                      ),
                    ],
                  ),
                ),
                // 2 Distinct Tabs: Received Collaborations vs. Sent Collaborations
                TabBar(
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryBlue,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 16),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              'Received (${incomingRequests.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.outbox_outlined, size: 16),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              'Sent (${sentRequests.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _CollaborationTabContent(isIncoming: true),
            _CollaborationTabContent(isIncoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const Gap(6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollaborationTabContent extends ConsumerStatefulWidget {
  final bool isIncoming;
  const _CollaborationTabContent({required this.isIncoming});

  @override
  ConsumerState<_CollaborationTabContent> createState() => _CollaborationTabContentState();
}

class _CollaborationTabContentState extends ConsumerState<_CollaborationTabContent> {
  String _selectedStatusFilter = 'All';
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
    final deals = ref.watch(accessibleDealsProvider);
    final allRequests = deals.where((d) => d.isRequest).toList();

    // 1. Scoping by Direction (Incoming vs. Sent)
    final tabRequests = allRequests.where((d) => d.isIncomingRequest == widget.isIncoming).toList();

    // 2. Dynamic Filter Options tailored to Direction
    final List<String> statusFilterOptions;
    if (widget.isIncoming) {
      statusFilterOptions = [
        'All',
        'Action Required',
        'Approved by Us',
        'Declined by Us',
      ];
    } else {
      statusFilterOptions = [
        'All',
        'Awaiting Partner',
        'Accepted by Partner',
        'Declined by Partner',
      ];
    }

    // 3. Filter by Search Query
    List<DealModel> filteredList = tabRequests;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredList = filteredList.where((d) {
        return d.propertyName.toLowerCase().contains(q) ||
            d.partnerBroker.toLowerCase().contains(q) ||
            d.partnerAgency.toLowerCase().contains(q) ||
            d.id.toLowerCase().contains(q) ||
            d.dealCode.toLowerCase().contains(q) ||
            (d.clientRequirement?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 4. Filter by Date Range
    if (_startDate != null && _endDate != null) {
      filteredList = filteredList.where((d) {
        final date = d.createdAt ?? d.respondedAt;
        if (date == null) return false;
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        return date.isAfter(start) && date.isBefore(end);
      }).toList();
    }

    // 5. Filter by Lifecycle Status
    if (_selectedStatusFilter == 'All') {
      // no-op
    } else if (_selectedStatusFilter == 'Action Required' || _selectedStatusFilter == 'Awaiting Partner') {
      filteredList = filteredList.where((d) => d.status == 'Pending').toList();
    } else if (_selectedStatusFilter == 'Approved by Us' || _selectedStatusFilter == 'Accepted by Partner') {
      filteredList = filteredList.where((d) => d.status == 'Approved').toList();
    } else if (_selectedStatusFilter == 'Declined by Us' || _selectedStatusFilter == 'Declined by Partner') {
      filteredList = filteredList.where((d) => d.status == 'Rejected').toList();
    }

    return Column(
      children: [
        // Search & Date Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: widget.isIncoming
                        ? 'Search listing, broker, or agency...'
                        : 'Search sent request, broker, property...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                  ),
                ),
              ),
              const Gap(8),
              // Date Range Button
              InkWell(
                onTap: () async {
                  if (_startDate != null) {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  } else {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: _startDate != null ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _startDate != null ? AppColors.primaryBlue : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    _startDate != null ? Icons.filter_alt_off : Icons.calendar_month_outlined,
                    color: _startDate != null ? AppColors.primaryBlue : AppColors.iconColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Date Active Banner
        if (_startDate != null && _endDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Filtering: ${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                  child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        // Filter Pills
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: statusFilterOptions.length,
            separatorBuilder: (context, index) => const Gap(8),
            itemBuilder: (context, index) {
              final option = statusFilterOptions[index];
              final isSelected = _selectedStatusFilter == option;

              // Compute count for this option
              int count;
              if (option == 'All') {
                count = tabRequests.length;
              } else if (option == 'Action Required' || option == 'Awaiting Partner') {
                count = tabRequests.where((d) => d.status == 'Pending').length;
              } else if (option == 'Approved by Us' || option == 'Accepted by Partner') {
                count = tabRequests.where((d) => d.status == 'Approved').length;
              } else {
                count = tabRequests.where((d) => d.status == 'Rejected').length;
              }

              return FilterChip(
                label: Text('$option ($count)'),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedStatusFilter = option),
                backgroundColor: Colors.white,
                selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            },
          ),
        ),
        const Gap(6),

        // Request Cards List
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref.read(dealProvider.notifier).fetchDeals(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final deal = filteredList[index];
                      return _CollaborationCard(deal: deal);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    IconData icon;
    String title;
    String subtitle;

    if (widget.isIncoming) {
      if (_selectedStatusFilter == 'Action Required') {
        icon = Icons.done_all_outlined;
        title = 'All Caught Up!';
        subtitle = 'There are no pending collaboration requests from other agencies awaiting your approval.';
      } else if (_selectedStatusFilter == 'Approved by Us') {
        icon = Icons.handshake_outlined;
        title = 'No Approved Requests Yet';
        subtitle = 'When you approve collaboration requests on your listings, they will show up here as active deals.';
      } else if (_selectedStatusFilter == 'Declined by Us') {
        icon = Icons.block_outlined;
        title = 'No Declined Requests';
        subtitle = 'Requests that you decline will be recorded here for compliance and tracking.';
      } else {
        icon = Icons.inbox_outlined;
        title = 'No Received Requests Found';
        subtitle = 'When other licensed brokers find your listings on the marketplace and request co-brokerage, they appear here.';
      }
    } else {
      if (_selectedStatusFilter == 'Awaiting Partner') {
        icon = Icons.hourglass_empty_outlined;
        title = 'No Requests Awaiting Decision';
        subtitle = 'You currently have no outgoing collaboration requests waiting for partner broker response.';
      } else if (_selectedStatusFilter == 'Accepted by Partner') {
        icon = Icons.check_circle_outline;
        title = 'No Partner Approvals Yet';
        subtitle = 'When external agencies accept your co-broking requests, they will show up here as active pipeline deals.';
      } else if (_selectedStatusFilter == 'Declined by Partner') {
        icon = Icons.cancel_outlined;
        title = 'No Declined Sent Requests';
        subtitle = 'Requests that partner agencies declined will be displayed here.';
      } else {
        icon = Icons.outbox_outlined;
        title = 'No Sent Requests Found';
        subtitle = 'Browse marketplace properties and tap "Request Collaboration" to initiate co-broking deals with partner agencies.';
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dealProvider.notifier).fetchDeals(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: SizedBox(
          height: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
              ),
              const Gap(16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollaborationCard extends ConsumerWidget {
  final DealModel deal;
  const _CollaborationCard({required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncoming = deal.isIncomingRequest;
    final isPending = deal.status == 'Pending';
    final isApproved = deal.status == 'Approved';
    final isRejected = deal.status == 'Rejected';

    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';

    // Extract structured pills if available
    final structuredChips = _extractRequirementBadges(deal.clientRequirement);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPending && isIncoming
              ? Colors.orange.shade300
              : const Color(0xFFE2E8F0),
          width: isPending && isIncoming ? 1.5 : 1.0,
        ),
      ),
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
              // Top Row: Direction Tag + Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Direction Pill
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isIncoming ? const Color(0xFFEFF6FF) : const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isIncoming ? const Color(0xFFBFDBFE) : const Color(0xFFE9D5FF),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 11,
                            color: isIncoming ? const Color(0xFF1D4ED8) : const Color(0xFF7E22CE),
                          ),
                          const Gap(4),
                          Flexible(
                            child: Text(
                              isIncoming
                                  ? 'Received from ${deal.partnerAgency}'
                                  : 'Sent to ${deal.partnerAgency}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isIncoming ? const Color(0xFF1D4ED8) : const Color(0xFF7E22CE),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(8),
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(deal.status, isIncoming),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(deal.status, isIncoming),
                          size: 12,
                          color: _getStatusTextColor(deal.status, isIncoming),
                        ),
                        const Gap(4),
                        Text(
                          _getStatusLabel(deal.status, isIncoming),
                          style: TextStyle(
                            color: _getStatusTextColor(deal.status, isIncoming),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(10),

              // Request Code & Partner Broker
              Row(
                children: [
                  Text(
                    deal.id,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      isIncoming
                          ? 'Requested by: ${deal.partnerBroker} (${deal.partnerAgency})'
                          : 'Target: ${deal.partnerBroker} (${deal.partnerAgency})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Gap(8),

              // Property Title
              Text(
                deal.propertyName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(8),

              // Budget & Offer Price Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee, size: 13, color: AppColors.primaryBlue),
                        const Gap(2),
                        Text(
                          deal.expectedBudget?.isNotEmpty == true
                              ? deal.expectedBudget!
                              : (deal.amount.isNotEmpty ? deal.amount : 'Budget on request'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  if (deal.createdAt != null) ...[
                    const Icon(Icons.access_time, size: 13, color: Color(0xFF94A3B8)),
                    const Gap(4),
                    Flexible(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(deal.createdAt!),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),

              // Structured Parameter Badges (if available)
              if (structuredChips.isNotEmpty) ...[
                const Gap(10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: structuredChips.map((badge) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Remarks (if available and not just split summary)
              if (deal.remarks != null && deal.remarks!.isNotEmpty) ...[
                const Gap(8),
                Text(
                  deal.remarks!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Quick Action Bar
              const Gap(14),
              const Divider(height: 1),
              const Gap(10),

              // Responsive Action Bar that NEVER overflows
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Chat Button (Direct message to partner broker)
                  OutlinedButton.icon(
                    onPressed: () => _openChatWithPartner(context, deal, currentUserId),
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  // Actions based on Direction & Status
                  if (isIncoming && isPending) ...[
                    // INCOMING & PENDING: Needs Your Approval
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showRejectDialog(context, ref, deal),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const Gap(8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(dealProvider.notifier).respondRequest(deal.id, 'approve');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Collaboration ${deal.id} Approved! Co-broker deal active.'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Approve Deal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ] else if (isApproved) ...[
                    // APPROVED: Active Deal
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                              const Gap(4),
                              Text(
                                isIncoming ? 'You Approved Deal' : 'Partner Accepted',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                        const Gap(6),
                        TextButton(
                          onPressed: () => context.push(AppRouter.deals),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View Deal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                              Icon(Icons.chevron_right, size: 14, color: AppColors.primaryBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (isRejected) ...[
                    // REJECTED / DECLINED
                    Text(
                      isIncoming ? 'You Declined this Request' : 'Partner Declined Request',
                      style: TextStyle(fontSize: 11.5, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ] else if (deal.status == 'Cancelled') ...[
                    // CANCELLED
                    Text(
                      'Request Cancelled',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    // SENT & PENDING: Waiting on Partner + Cancel Button (PRD Sec 6)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 13, color: Colors.amber.shade900),
                            const Gap(4),
                            Text(
                              'Awaiting Partner',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Gap(8),
                        OutlinedButton(
                          onPressed: () => _showCancelDialog(context, ref, deal),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel Request', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatWithPartner(BuildContext context, DealModel deal, String currentUserId) {
    final partnerId = BrokerDirectoryService.resolvePartnerForCollaboration(deal, currentUserId);
    final partnerName = deal.partnerBroker;
    final agencyName = deal.partnerAgency;

    final sorted = [currentUserId, partnerId]..sort();
    final hasProp = deal.propertyId.isNotEmpty;
    final convId = hasProp
        ? 'conv_${sorted[0]}_${sorted[1]}_${deal.propertyId}'
        : 'conv_${sorted[0]}_${sorted[1]}';

    context.push(
      '/chat/$convId',
      extra: {
        'partnerId': partnerId,
        'partnerName': partnerName,
        'agencyName': agencyName,
        'chatType': hasProp ? 'property' : 'direct',
        'contextTitle': deal.propertyName.isNotEmpty
            ? deal.propertyName
            : 'Deal #${deal.dealCode.isNotEmpty ? deal.dealCode : deal.id}',
        'propertyId': deal.propertyId,
        'dealId': deal.id,
      },
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, DealModel deal) {
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
                'Are you sure you want to decline this collaboration request for ${deal.propertyName}?',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Gap(12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  hintText: 'e.g. Property already under token, client budget mismatch...',
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
              },
              child: const Text('Decline Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, DealModel deal) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel Collaboration Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            'Are you sure you want to cancel your sent collaboration request for ${deal.propertyName} (${deal.id})?',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(dealProvider.notifier).respondRequest(
                      deal.id,
                      'cancel',
                      'Cancelled by requester',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Collaboration request ${deal.id} cancelled.'),
                    backgroundColor: Colors.grey.shade800,
                  ),
                );
              },
              child: const Text('Cancel Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  List<String> _extractRequirementBadges(String? requirement) {
    if (requirement == null || requirement.isEmpty) return [];
    final List<String> badges = [];
    final lines = requirement.split('\n');
    for (final line in lines) {
      final clean = line.replaceAll('•', '').trim();
      if (clean.contains(':')) {
        final parts = clean.split(':');
        if (parts.length >= 2) {
          final val = parts[1].trim();
          if (val.isNotEmpty && !val.toLowerCase().contains('preferences')) {
            badges.add(val);
          }
        }
      }
    }
    return badges.take(4).toList();
  }

  String _getStatusLabel(String status, bool isIncoming) {
    switch (status) {
      case 'Approved':
        return isIncoming ? 'Approved by You' : 'Accepted by Partner';
      case 'Rejected':
        return isIncoming ? 'Declined by You' : 'Declined by Partner';
      case 'Pending':
      default:
        return isIncoming ? 'Action Required' : 'Awaiting Partner';
    }
  }

  Color _getStatusBgColor(String status, bool isIncoming) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade50;
      case 'Rejected':
        return Colors.red.shade50;
      case 'Pending':
      default:
        return isIncoming ? Colors.orange.shade50 : const Color(0xFFFFFBEB);
    }
  }

  Color _getStatusTextColor(String status, bool isIncoming) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade700;
      case 'Rejected':
        return Colors.red.shade700;
      case 'Pending':
      default:
        return isIncoming ? Colors.orange.shade800 : Colors.amber.shade900;
    }
  }

  IconData _getStatusIcon(String status, bool isIncoming) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle_outline;
      case 'Rejected':
        return Icons.cancel_outlined;
      case 'Pending':
      default:
        return isIncoming ? Icons.pending_actions : Icons.schedule;
    }
  }
}
