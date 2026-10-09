import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/broker_directory_service.dart';

class DealsScreen extends ConsumerStatefulWidget {
  final String? initialStage;
  const DealsScreen({super.key, this.initialStage});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  String _selectedStageFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _chipScrollCtrl = ScrollController();
  final ScrollController _kanbanScrollCtrl = ScrollController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isKanbanView = false;

  final List<String> _filterStages = [
    'All',
    ...DealModel.prdMilestones,
  ];

  @override
  void initState() {
    super.initState();
    final String targetStage = (widget.initialStage != null && widget.initialStage!.isNotEmpty)
        ? widget.initialStage!
        : ref.read(selectedDealStageProvider);
    if (_filterStages.contains(targetStage)) {
      _selectedStageFilter = targetStage;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedStage();
    });
  }

  @override
  void didUpdateWidget(covariant DealsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStage != null && widget.initialStage != oldWidget.initialStage) {
      if (_filterStages.contains(widget.initialStage)) {
        setState(() {
          _selectedStageFilter = widget.initialStage!;
        });
        ref.read(selectedDealStageProvider.notifier).setStage(widget.initialStage!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedStage();
        });
      }
    }
  }

  void _scrollToSelectedStage() {
    if (!mounted) return;
    if (_selectedStageFilter == 'All') {
      if (_chipScrollCtrl.hasClients) {
        _chipScrollCtrl.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      if (_kanbanScrollCtrl.hasClients) {
        _kanbanScrollCtrl.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      return;
    }

    // Scroll filter chip
    final chipIdx = _filterStages.indexOf(_selectedStageFilter);
    if (chipIdx > 0 && _chipScrollCtrl.hasClients) {
      final targetOffset = (chipIdx * 110.0) - 20.0;
      _chipScrollCtrl.animateTo(
        targetOffset.clamp(0.0, _chipScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    // Scroll Kanban column
    final kIdx = DealModel.prdMilestones.indexOf(_selectedStageFilter);
    if (kIdx >= 0 && _kanbanScrollCtrl.hasClients) {
      final targetOffset = kIdx * 294.0;
      _kanbanScrollCtrl.animateTo(
        targetOffset.clamp(0.0, _kanbanScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _chipScrollCtrl.dispose();
    _kanbanScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
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

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedDealStageProvider, (prev, next) {
      if (next != _selectedStageFilter && _filterStages.contains(next)) {
        setState(() {
          _selectedStageFilter = next;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedStage();
        });
      }
    });
    final allDeals = ref.watch(accessibleDealsProvider);
    // Exclude pending collaboration requests (they reside in Collaborations Hub)
    final pipelineDeals = allDeals.where((d) => !d.isRequest).toList();

    // 1. Calculate Pipeline KPIs (PRD Section 7.1)
    double totalPipelineValue = 0.0;
    int activeCount = 0;
    double closedValue = 0.0;
    int closedCount = 0;

    for (final deal in pipelineDeals) {
      final stage = deal.normalizedStage;
      if (stage == 'Deal Closed') {
        closedValue += deal.dealValue;
        closedCount++;
      } else if (stage != 'Deal Lost') {
        totalPipelineValue += deal.dealValue;
        activeCount++;
      }
    }

    // 2. Filter Deals
    List<DealModel> filteredDeals = List.from(pipelineDeals);

    if (_selectedStageFilter != 'All') {
      filteredDeals = filteredDeals.where((d) {
        if (_selectedStageFilter == 'Deal Lost') {
          return d.normalizedStage == 'Deal Lost';
        }
        return d.normalizedStage == _selectedStageFilter;
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredDeals = filteredDeals.where((d) {
        return d.propertyName.toLowerCase().contains(q) ||
            d.partnerBroker.toLowerCase().contains(q) ||
            d.partnerAgency.toLowerCase().contains(q) ||
            d.dealCode.toLowerCase().contains(q) ||
            d.id.toLowerCase().contains(q) ||
            (d.clientName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_startDate != null && _endDate != null) {
      filteredDeals = filteredDeals.where((d) {
        if (d.createdAt == null) return false;
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        return d.createdAt!.isAfter(start) && d.createdAt!.isBefore(end);
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deals Pipeline',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Transaction Milestones & Revenue Funnel',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          // View Toggle Button (Kanban vs List)
          IconButton(
            icon: Icon(
              _isKanbanView ? Icons.view_list_rounded : Icons.view_kanban_rounded,
              color: AppColors.primaryBlue,
            ),
            tooltip: _isKanbanView ? 'Switch to List View' : 'Switch to Kanban View',
            onPressed: () {
              setState(() {
                _isKanbanView = !_isKanbanView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            tooltip: 'Refresh Pipeline',
            onPressed: () {
              ref.read(dealProvider.notifier).fetchDeals();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Pipeline Value KPI Summary Bar (PRD Sec 7.1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _buildKpiCard(
                  label: 'Active Pipeline',
                  value: _formatCurrency(totalPipelineValue),
                  subText: '$activeCount active deals',
                  color: AppColors.primaryBlue,
                  bgColor: const Color(0xFFEFF6FF),
                  icon: Icons.trending_up,
                ),
                const Gap(10),
                _buildKpiCard(
                  label: 'Closed Deals',
                  value: _formatCurrency(closedValue),
                  subText: '$closedCount deals completed',
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                  icon: Icons.check_circle_outline,
                ),
                const Gap(10),
                _buildKpiCard(
                  label: 'Est. Commission',
                  value: _formatCurrency((totalPipelineValue + closedValue) * 0.02),
                  subText: '2% standard pool',
                  color: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                  icon: Icons.currency_rupee,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Search & Date Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search property, client, broker, or DL code...',
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
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const Gap(8),
                InkWell(
                  onTap: () {
                    if (_startDate != null) {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    } else {
                      _selectDateRange(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _startDate != null ? AppColors.primaryBlue.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _startDate != null ? AppColors.primaryBlue : Colors.transparent),
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

          // Date Filter Banner (if active)
          if (_startDate != null && _endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'Filtering: ${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    child: const Text('Reset', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Milestone Stage Filter Chips
          if (!_isKanbanView)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
              alignment: Alignment.centerLeft,
              child: ListView.separated(
                controller: _chipScrollCtrl,
                scrollDirection: Axis.horizontal,
                itemCount: _filterStages.length,
                separatorBuilder: (context, index) => const Gap(8),
                itemBuilder: (context, index) {
                  final stage = _filterStages[index];
                  final isSelected = _selectedStageFilter == stage;

                  // Count deals in this stage
                  int count;
                  if (stage == 'All') {
                    count = pipelineDeals.length;
                  } else {
                    count = pipelineDeals.where((d) => d.normalizedStage == stage).length;
                  }

                  return FilterChip(
                    label: Text('$stage ($count)'),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedStageFilter = stage);
                      ref.read(selectedDealStageProvider.notifier).setStage(stage);
                      _scrollToSelectedStage();
                    },
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

          // Body: Kanban View vs. List View
          Expanded(
            child: _isKanbanView
                ? _buildKanbanBoard(pipelineDeals)
                : _buildListView(filteredDeals),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-deal');
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Deal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subText,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const Gap(4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Gap(3),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subText,
              style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<DealModel> deals) {
    if (deals.isEmpty) {
      final isFiltered = _selectedStageFilter != 'All';
      return RefreshIndicator(
        onRefresh: () => ref.read(dealProvider.notifier).fetchDeals(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: SizedBox(
            height: 380,
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
                  child: Icon(
                    isFiltered ? Icons.filter_alt_off_outlined : Icons.assignment_outlined,
                    size: 40,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const Gap(16),
                Text(
                  isFiltered ? 'No Deals in "$_selectedStageFilter"' : 'No Deals Found',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                const Gap(6),
                Text(
                  isFiltered
                      ? 'There are currently no deals progressing in the "$_selectedStageFilter" stage.'
                      : 'Deals created from approved co-brokerage requests or added manually will appear in this pipeline.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                if (isFiltered) ...[
                  const Gap(16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedStageFilter = 'All');
                      ref.read(selectedDealStageProvider.notifier).setStage('All');
                      _scrollToSelectedStage();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('View All Deals'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dealProvider.notifier).fetchDeals(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: deals.length + (_selectedStageFilter != 'All' ? 1 : 0),
        itemBuilder: (context, index) {
          if (_selectedStageFilter != 'All' && index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: AppColors.primaryBlue),
                  const Gap(8),
                  Text(
                    'Milestone: $_selectedStageFilter (${deals.length} deals)',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() => _selectedStageFilter = 'All');
                      ref.read(selectedDealStageProvider.notifier).setStage('All');
                      _scrollToSelectedStage();
                    },
                    child: const Text('Show All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            );
          }
          final deal = deals[_selectedStageFilter != 'All' ? index - 1 : index];
          return _DealCard(deal: deal);
        },
      ),
    );
  }

  Widget _buildKanbanBoard(List<DealModel> allDeals) {
    return ListView.builder(
      controller: _kanbanScrollCtrl,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: DealModel.prdMilestones.length,
      itemBuilder: (context, index) {
        final stage = DealModel.prdMilestones[index];
        final isStageActive = _selectedStageFilter == stage;
        final stageDeals = allDeals.where((d) => d.normalizedStage == stage).toList();
        final stageValue = stageDeals.fold<double>(0.0, (sum, d) => sum + d.dealValue);

        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isStageActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isStageActive ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
              width: isStageActive ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (stageValue > 0)
                            Text(
                              _formatCurrency(stageValue),
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        stageDeals.length.toString(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Deals in this column
              Expanded(
                child: stageDeals.isEmpty
                    ? Center(
                        child: Text(
                          'No deals in $stage',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: stageDeals.length,
                        itemBuilder: (context, dIndex) {
                          return _DealCard(deal: stageDeals[dIndex], isCompact: true);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
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

class _DealCard extends ConsumerWidget {
  final DealModel deal;
  final bool isCompact;
  const _DealCard({required this.deal, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';

    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final userAgency = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';

    final isClientOwner = (userAgencyId != null && deal.agencyBId != null && deal.agencyBId.toString() == userAgencyId.toString()) ||
        (userAgency.isNotEmpty && deal.agencyBName.toLowerCase().trim() == userAgency.toLowerCase().trim()) ||
        deal.isRequest;

    final progress = deal.progressPercentage;
    final milestoneIdx = deal.milestoneIndex;

    final properties = ref.watch(propertyProvider);
    final allDeals = ref.watch(dealProvider);
    final linkedProperty = properties.cast<PropertyModel?>().firstWhere(
      (p) => p?.id.toString() == deal.propertyId.toString(),
      orElse: () => null,
    );
    final isPropertySold = (linkedProperty != null && (linkedProperty.status.toLowerCase() == 'sold' || linkedProperty.status.toLowerCase() == 'rented')) ||
        allDeals.any((d) => d.propertyId == deal.propertyId && d.id != deal.id && (d.normalizedStage == 'Deal Closed' || d.status.toLowerCase().contains('sold')));
    final isThisDealClosed = deal.normalizedStage == 'Deal Closed' || deal.status.toLowerCase().contains('sold');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/deal-details/${deal.id}');
        },
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Code + Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          deal.dealCode.isNotEmpty ? deal.dealCode : deal.id,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.primaryBlue),
                        ),
                      ),
                      if (isPropertySold && !isThisDealClosed) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFFCA5A5), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_clock, size: 10.5, color: Color(0xFFDC2626)),
                              Gap(3),
                              Text(
                                'Property Sold',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    deal.amount.isNotEmpty ? deal.amount : '₹0',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 14 : 16,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const Gap(8),

              // Property Title
              Text(
                deal.propertyName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 13.5 : 15.5,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(4),

              // Counterparty Broker Info
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      '${deal.partnerBroker} (${deal.partnerAgency})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Client Info with Privacy Shield (PRD Section 4.5.2 & 10)
              if (!isCompact) ...[
                const Gap(6),
                Row(
                  children: [
                    Icon(
                      isClientOwner ? Icons.badge_outlined : Icons.shield_outlined,
                      size: 13,
                      color: isClientOwner ? AppColors.textSecondary : const Color(0xFF2563EB),
                    ),
                    const Gap(4),
                    Text(
                      isClientOwner
                          ? 'Client: ${deal.clientName ?? 'Direct Lead'}'
                          : 'Client: Verified Protected Lead',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isClientOwner ? AppColors.textSecondary : const Color(0xFF1D4ED8),
                        fontWeight: isClientOwner ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              const Gap(10),
              // 9-Stage Milestone Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          deal.normalizedStage,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _getStageColor(deal.normalizedStage),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        'Step ${milestoneIdx + 1}/9',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Gap(5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(_getStageColor(deal.normalizedStage)),
                    ),
                  ),
                ],
              ),

              if (!isCompact) ...[
                const Gap(12),
                const Divider(height: 1),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Chat Button
                    OutlinedButton.icon(
                      onPressed: () => _openChat(context, deal, currentUserId),
                      icon: const Icon(Icons.chat_bubble_outline, size: 13),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Gap(8),
                    // Advance Milestone
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () => context.push('/deal-details/${deal.id}'),
                        icon: const Text(
                          'Manage Milestones',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        label: const Icon(Icons.chevron_right, size: 16, color: AppColors.primaryBlue),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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

  void _openChat(BuildContext context, DealModel deal, String currentUserId) {
    final partnerId = BrokerDirectoryService.resolvePartnerForCollaboration(deal, currentUserId);
    final sorted = [currentUserId, partnerId]..sort();
    final hasProp = deal.propertyId.isNotEmpty;
    final convId = hasProp
        ? 'conv_${sorted[0]}_${sorted[1]}_${deal.propertyId}'
        : 'conv_${sorted[0]}_${sorted[1]}';

    context.push(
      '/chat/$convId',
      extra: {
        'partnerId': partnerId,
        'partnerName': deal.partnerBroker,
        'agencyName': deal.partnerAgency,
        'chatType': hasProp ? 'property' : 'direct',
        'contextTitle': deal.propertyName.isNotEmpty
            ? deal.propertyName
            : 'Deal #${deal.dealCode.isNotEmpty ? deal.dealCode : deal.id}',
        'propertyId': deal.propertyId,
        'dealId': deal.id,
      },
    );
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'Deal Closed':
        return Colors.green.shade700;
      case 'Possession':
      case 'Registry':
        return Colors.teal.shade700;
      case 'Agreement to Sell':
      case 'Token / Booking':
        return Colors.indigo.shade700;
      case 'Negotiation':
      case 'Site Visit':
        return Colors.blue.shade700;
      case 'Deal Lost':
        return Colors.red.shade700;
      case 'Inquiry':
      default:
        return Colors.orange.shade800;
    }
  }
}
