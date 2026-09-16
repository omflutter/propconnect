import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:intl/intl.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  String _selectedStatus = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _dealStages = [
    'All',
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: initialDateRange,
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
    final deals = ref.watch(dealProvider);
    
    // Only show deals that are not pending requests
    var activeDeals = deals.where((d) => !d.isRequest).toList();
    
    // Status Filter
    if (_selectedStatus != 'All') {
      activeDeals = activeDeals.where((d) => d.status == _selectedStatus).toList();
    }

    // Search Filter
    if (_searchQuery.isNotEmpty) {
      activeDeals = activeDeals.where((d) => 
        d.propertyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.partnerBroker.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.id.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Date Range Filter
    if (_startDate != null && _endDate != null) {
      activeDeals = activeDeals.where((d) {
        if (d.createdAt == null) return false;
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        return d.createdAt!.isAfter(start) && d.createdAt!.isBefore(end);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deals Pipeline', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Date Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by Property, Broker, or ID...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    (_startDate != null && _endDate != null) ? Icons.close : Icons.calendar_month_outlined,
                    color: (_startDate != null && _endDate != null) ? AppColors.primaryBlue : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    if (_startDate != null && _endDate != null) {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    } else {
                      _selectDateRange(context);
                    }
                  },
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Filter Chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _dealStages.length,
              itemBuilder: (context, index) {
                final status = _dealStages[index];
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(status, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryBlue,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.border),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: activeDeals.isEmpty
              ? const Center(child: Text('No deals found matching criteria.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeDeals.length,
                  itemBuilder: (context, index) {
                    final deal = activeDeals[index];
                    return _buildDealCard(deal);
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add-deal');
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDealCard(DealModel deal) {
    return GestureDetector(
      onTap: () {
        context.push('/deal-details/${deal.id}');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(deal.id, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Text(deal.amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Gap(12),
              Text(deal.propertyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                  const Gap(4),
                  Text('${deal.partnerBroker} (${deal.partnerAgency})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  if (deal.createdAt != null) ...[
                    const Spacer(),
                    const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                    const Gap(4),
                    Text(DateFormat('MMM dd').format(deal.createdAt!), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]
                ],
              ),
              const Gap(12),
              const Divider(color: AppColors.border),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(deal.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(deal.status).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      deal.status,
                      style: TextStyle(color: _getStatusColor(deal.status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Deal Closed' || status == 'Registry Completed') return Colors.green;
    if (status == 'Deal Lost') return Colors.red;
    if (status.contains('Token') || status.contains('Agreement')) return Colors.teal;
    return Colors.orange;
  }
}
