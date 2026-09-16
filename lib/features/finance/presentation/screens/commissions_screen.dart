import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/commission_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';

class CommissionsScreen extends ConsumerStatefulWidget {
  const CommissionsScreen({super.key});

  @override
  ConsumerState<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends ConsumerState<CommissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _commissionStatusFilter = 'All';
  String _settlementStatusFilter = 'All';

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commissions = ref.watch(commissionProvider);
    final settlements = ref.watch(settlementProvider);

    // Calculate KPI metrics
    double totalInvoiced = 0;
    double totalReceived = 0;
    for (final c in commissions) {
      totalInvoiced += c.totalCommission;
    }
    for (final s in settlements) {
      totalReceived += s.amountReceived;
    }
    final totalPending = (totalInvoiced - totalReceived).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Commission & Earnings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(commissionProvider.notifier).fetchCommissions();
              ref.read(settlementProvider.notifier).fetchSettlements();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Financial data refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: 'Commissions (${commissions.length})'),
            Tab(text: 'Settlements (${settlements.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecordSettlementSheet(context, commissions),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_card, color: Colors.white),
        label: const Text(
          'Record Settlement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildKpiHeader(totalInvoiced, totalReceived, totalPending),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommissionsTab(commissions),
                _buildSettlementsTab(settlements),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiHeader(double totalInvoiced, double totalReceived, double totalPending) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Total Invoiced',
              amount: totalInvoiced,
              color: AppColors.primaryBlue,
              icon: Icons.receipt_long,
            ),
          ),
          const Gap(10),
          Expanded(
            child: _buildMetricCard(
              title: 'Total Received',
              amount: totalReceived,
              color: AppColors.success,
              icon: Icons.check_circle_outline,
            ),
          ),
          const Gap(10),
          Expanded(
            child: _buildMetricCard(
              title: 'Pending Payout',
              amount: totalPending,
              color: AppColors.warning,
              icon: Icons.pending_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Gap(4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            _formatCompactCurrency(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return _currencyFormat.format(amount);
    }
  }

  // ==========================================
  // TAB 1: COMMISSIONS BREAKDOWN (PRD Sec 12)
  // ==========================================
  Widget _buildCommissionsTab(List<CommissionModel> commissions) {
    final filtered = commissions.where((c) {
      final matchesStatus = _commissionStatusFilter == 'All' ||
          c.status.toLowerCase() == _commissionStatusFilter.toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          c.commissionCode.toLowerCase().contains(q) ||
          c.dealId.toLowerCase().contains(q) ||
          (c.propertyName != null && c.propertyName!.toLowerCase().contains(q)) ||
          (c.brokerAName != null && c.brokerAName!.toLowerCase().contains(q)) ||
          (c.brokerBName != null && c.brokerBName!.toLowerCase().contains(q));
      return matchesStatus && matchesSearch;
    }).toList();

    return Column(
      children: [
        _buildFilterBar(
          searchHint: 'Search deal, commission, property...',
          filterOptions: const ['All', 'Settled', 'Partial', 'Pending'],
          selectedFilter: _commissionStatusFilter,
          onFilterChanged: (val) => setState(() => _commissionStatusFilter = val),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyView('No commission records found')
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(commissionProvider.notifier).fetchCommissions(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Gap(12),
                    itemBuilder: (context, index) {
                      return _buildCommissionCard(filtered[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCommissionCard(CommissionModel item) {
    final statusColor = _getStatusColor(item.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showCommissionDetailsModal(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.commissionCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      '•  ${item.dealId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                if (item.propertyName != null && item.propertyName!.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    item.propertyName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],

                const Gap(12),

                // Financial values row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deal Value',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Gap(2),
                          Text(
                            _currencyFormat.format(item.dealValue),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Commission (${item.commissionRate}% ${item.commissionType})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Gap(2),
                          Text(
                            _currencyFormat.format(item.totalCommission),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Gap(12),

                // 50/50 Split Distribution Matrix (PRD Sec 12)
                const Text(
                  'Split Distribution (50/50)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(6),

                // Split progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: item.brokerASharePct.toInt(),
                        child: Container(
                          height: 6,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Expanded(
                        flex: item.brokerBSharePct.toInt(),
                        child: Container(
                          height: 6,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(8),

                Row(
                  children: [
                    // Broker A (Listing)
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Broker A (${item.brokerASharePct.toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(item.brokerAAmount),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Broker B (Client)
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Broker B (${item.brokerBSharePct.toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(item.brokerBAAmount),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  // ==========================================
  // TAB 2: PAYMENT SETTLEMENTS (PRD Sec 13)
  // ==========================================
  Widget _buildSettlementsTab(List<SettlementModel> settlements) {
    final filtered = settlements.where((s) {
      final matchesStatus = _settlementStatusFilter == 'All' ||
          s.status.toLowerCase() == _settlementStatusFilter.toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          s.settlementCode.toLowerCase().contains(q) ||
          s.dealId.toLowerCase().contains(q) ||
          s.referenceNumber.toLowerCase().contains(q) ||
          (s.propertyName != null && s.propertyName!.toLowerCase().contains(q)) ||
          (s.agencyName != null && s.agencyName!.toLowerCase().contains(q));
      return matchesStatus && matchesSearch;
    }).toList();

    return Column(
      children: [
        _buildFilterBar(
          searchHint: 'Search settlement, deal, ref number...',
          filterOptions: const ['All', 'Received', 'Settled', 'Pending'],
          selectedFilter: _settlementStatusFilter,
          onFilterChanged: (val) => setState(() => _settlementStatusFilter = val),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyView('No settlement records found')
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(settlementProvider.notifier).fetchSettlements(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Gap(12),
                    itemBuilder: (context, index) {
                      return _buildSettlementCard(filtered[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard(SettlementModel item) {
    final statusColor = _getStatusColor(item.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.settlementCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  '•  ${item.dealId}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            if (item.propertyName != null && item.propertyName!.isNotEmpty) ...[
              const Gap(8),
              Text(
                item.propertyName!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],

            const Gap(12),

            // Amounts Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount Received',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const Gap(2),
                        Text(
                          _currencyFormat.format(item.amountReceived),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (item.amountPending > 0 ? AppColors.warning : AppColors.textSecondary)
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (item.amountPending > 0 ? AppColors.warning : AppColors.border)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount Pending',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const Gap(2),
                        Text(
                          _currencyFormat.format(item.amountPending),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.amountPending > 0 ? AppColors.warning : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const Gap(12),

            // Details: Payment Method & Reference Number
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payment, size: 13, color: AppColors.textSecondary),
                      const Gap(4),
                      Text(
                        item.paymentMethod,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Ref: ${item.referenceNumber}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (item.settlementDate != null || item.dueDate != null) ...[
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.settlementDate != null)
                    Text(
                      'Settled: ${DateFormat('dd MMM yyyy').format(item.settlementDate!)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  if (item.dueDate != null)
                    Text(
                      'Due: ${DateFormat('dd MMM yyyy').format(item.dueDate!)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SHARED SEARCH & FILTER BAR
  // ==========================================
  Widget _buildFilterBar({
    required String searchHint,
    required List<String> filterOptions,
    required String selectedFilter,
    required ValueChanged<String> onFilterChanged,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: searchHint,
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const Gap(10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((opt) {
                final isSelected = selectedFilter.toLowerCase() == opt.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (_) => onFilterChanged(opt),
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryBlue : AppColors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 56, color: AppColors.border),
          const Gap(12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('paid') || lower.contains('settled') || lower.contains('received')) {
      return AppColors.success;
    } else if (lower.contains('partial')) {
      return AppColors.warning;
    } else if (lower.contains('overdue') || lower.contains('dispute')) {
      return AppColors.error;
    }
    return AppColors.primaryBlue;
  }

  // ==========================================
  // COMMISSION DETAILS BOTTOM SHEET
  // ==========================================
  void _showCommissionDetailsModal(CommissionModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.commissionCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Linked Deal: ${item.dealId}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
              const Divider(),
              const Gap(12),
              _buildDetailRow('Deal Transaction Value', _currencyFormat.format(item.dealValue)),
              _buildDetailRow('Commission Structure', '${item.commissionRate}% (${item.commissionType})'),
              _buildDetailRow('Gross Commission', _currencyFormat.format(item.totalCommission)),
              const Gap(16),
              const Text(
                'Distribution Ledger (50/50 Split)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.brokerAName ?? 'Listing Broker (Broker A)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          _currencyFormat.format(item.brokerAAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    const Divider(),
                    const Gap(8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.brokerBName ?? 'Client Broker (Broker B)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          _currencyFormat.format(item.brokerBAAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openRecordSettlementSheet(context, [item], preselectedDeal: item.dealId);
                  },
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text('Record Settlement For This Deal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // ==========================================
  // RECORD SETTLEMENT BOTTOM SHEET (PRD Sec 13)
  // ==========================================
  void _openRecordSettlementSheet(
    BuildContext context,
    List<CommissionModel> commissions, {
    String? preselectedDeal,
  }) {
    String selectedDeal = preselectedDeal ?? (commissions.isNotEmpty ? commissions.first.dealId : 'DL-501');
    final amountRecCtrl = TextEditingController(text: '125000');
    final amountPendCtrl = TextEditingController(text: '0');
    final refNoCtrl = TextEditingController(
      text: 'NEFT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
    );
    final remarksCtrl = TextEditingController(text: 'Settled via net banking');
    String paymentMethod = 'NEFT / Bank Transfer';
    DateTime settlementDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(16),
                    const Text(
                      'Record Payment Settlement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      'Log transaction details, UTR reference, and update commission balance.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Gap(16),

                    // Deal Selector
                    const Text(
                      'Linked Deal',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Gap(6),
                    DropdownButtonFormField<String>(
                      initialValue: commissions.any((c) => c.dealId == selectedDeal)
                          ? selectedDeal
                          : (commissions.isNotEmpty ? commissions.first.dealId : null),
                      items: commissions.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.dealId,
                          child: Text('${c.dealId} - ${c.commissionCode} (${_currencyFormat.format(c.totalCommission)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedDeal = val);
                          final matched = commissions.firstWhere(
                            (c) => c.dealId == val,
                            orElse: () => commissions.first,
                          );
                          amountRecCtrl.text = matched.brokerAAmount.toStringAsFixed(0);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const Gap(12),

                    // Amount Received & Pending
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Amount Received (₹)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const Gap(6),
                              TextField(
                                controller: amountRecCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Amount Pending (₹)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const Gap(6),
                              TextField(
                                controller: amountPendCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),

                    // Payment Method Dropdown
                    const Text(
                      'Payment Method',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Gap(6),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'NEFT / Bank Transfer', child: Text('NEFT / Bank Transfer')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI (Instant)')),
                        DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                        DropdownMenuItem(value: 'RTGS', child: Text('RTGS')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => paymentMethod = val);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const Gap(12),

                    // Reference Number / UTR
                    const Text(
                      'Transaction Reference / UTR Number',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Gap(6),
                    TextField(
                      controller: refNoCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const Gap(12),

                    // Remarks
                    const Text(
                      'Remarks',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Gap(6),
                    TextField(
                      controller: remarksCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const Gap(20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final rec = double.tryParse(amountRecCtrl.text) ?? 0.0;
                          final pend = double.tryParse(amountPendCtrl.text) ?? 0.0;

                          final payload = {
                            'dealId': selectedDeal,
                            'amountReceived': rec,
                            'amountPending': pend,
                            'paymentMethod': paymentMethod,
                            'referenceNumber': refNoCtrl.text.trim(),
                            'remarks': remarksCtrl.text.trim(),
                            'settlementDate': settlementDate.toIso8601String(),
                          };

                          final success = await ref
                              .read(settlementProvider.notifier)
                              .recordSettlement(payload);

                          if (modalCtx.mounted) {
                            Navigator.pop(modalCtx);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Settlement recorded successfully!'
                                      : 'Settlement logged locally',
                                ),
                                backgroundColor: success ? AppColors.success : null,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Submit Settlement Payment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
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
}
