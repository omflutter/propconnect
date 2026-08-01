import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Sale', 'Rent', 'Apartment', 'Villa', 'Commercial'];

  void _showCollaborationDialog(PropertyModel prop) {
    final clientReqCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Request Collaboration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(8),
                Text('Requesting to collaborate on ${prop.title} with ${prop.agencyName}.', style: const TextStyle(color: AppColors.textSecondary)),
                const Gap(24),
                _buildPremiumTextField(clientReqCtrl, 'Client Requirement', Icons.list_alt_outlined),
                const Gap(16),
                _buildPremiumTextField(budgetCtrl, 'Expected Budget', Icons.monetization_on_outlined),
                const Gap(16),
                _buildPremiumTextField(remarksCtrl, 'Remarks (Optional)', Icons.notes_outlined, maxLines: 3),
                const Gap(32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (clientReqCtrl.text.isNotEmpty && budgetCtrl.text.isNotEmpty) {
                      // Generate dummy ID
                      final newId = 'R-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
                      ref.read(dealProvider.notifier).addDeal(
                        DealModel(
                          id: newId,
                          propertyId: prop.id,
                          propertyName: prop.title,
                          partnerBroker: prop.brokerName,
                          partnerAgency: prop.agencyName,
                          status: 'Pending',
                          amount: budgetCtrl.text,
                          isRequest: true,
                        )
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Collaboration Request sent to ${prop.agencyName}!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Send Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const Gap(32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.iconColor) : Padding(padding: const EdgeInsets.only(bottom: 48), child: Icon(icon, color: AppColors.iconColor)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertyProvider);
    
    // Filter logic
    var filteredProps = properties.where((p) {
      if (_selectedFilter != 'All' && _selectedFilter != p.type && !p.title.contains(_selectedFilter)) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !p.title.toLowerCase().contains(_searchQuery.toLowerCase()) && !p.location.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return p.isPublic && p.agencyName != 'Sunrise Properties'; // Only show others' properties
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Properties'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by location, project, or broker...',
                prefixIcon: const Icon(Icons.search, color: AppColors.iconColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const Gap(8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = selected ? filter : 'All');
                  },
                  selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          const Gap(16),
          Expanded(
            child: filteredProps.isEmpty
                ? const Center(child: Text('No matching properties found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProps.length,
                    itemBuilder: (context, index) {
                      final prop = filteredProps[index];
                      return GestureDetector(
                        onTap: () => context.push('/property-details/${prop.id}'),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: prop.images.isNotEmpty
                                    ? Image.asset(prop.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)))
                                    : const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(prop.price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: prop.type == 'Sale' ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'For ${prop.type}',
                                            style: TextStyle(
                                              color: prop.type == 'Sale' ? Colors.blue : Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(8),
                                    Text(prop.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Gap(4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                                        const Gap(4),
                                        Text(prop.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                    const Gap(16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showCollaborationDialog(prop),
                                        icon: const Icon(Icons.handshake),
                                        label: const Text('Request Collaboration'),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
