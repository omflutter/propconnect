import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/agency_model.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/broker_directory_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Sale', 'Rent', 'Apartment', 'Villa', 'Commercial', 'Plot'];

  // PRD Sec 5 Multi-Attribute Filters
  String _purposeFilter = 'All'; // 'All', 'Sale', 'Rent', 'Lease'
  String _bhkFilter = 'All'; // 'All', '1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'
  String _propTypeFilter = 'All'; // 'All', 'Apartment', 'Villa', 'Penthouse', 'Office Space', 'Retail Shop', 'Plot'
  String _furnishingFilter = 'All'; // 'All', 'Unfurnished', 'Semi-Furnished', 'Fully Furnished'
  String _statusFilter = 'All'; // 'All', 'Available', 'Under Negotiation', 'Token Done'

  // Extended PRD Sec 5 Filters
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();
  final TextEditingController _minAreaCtrl = TextEditingController();
  final TextEditingController _maxAreaCtrl = TextEditingController();
  final TextEditingController _agencyFilterCtrl = TextEditingController();
  final TextEditingController _brokerFilterCtrl = TextEditingController();
  String _selectedCity = 'All';
  String _selectedArea = 'All';

  int get activeFilterCount {
    int count = 0;
    if (_purposeFilter != 'All') count++;
    if (_bhkFilter != 'All') count++;
    if (_propTypeFilter != 'All') count++;
    if (_furnishingFilter != 'All') count++;
    if (_statusFilter != 'All') count++;
    if (_selectedCity != 'All') count++;
    if (_selectedArea != 'All') count++;
    if (_minPriceCtrl.text.trim().isNotEmpty) count++;
    if (_maxPriceCtrl.text.trim().isNotEmpty) count++;
    if (_minAreaCtrl.text.trim().isNotEmpty) count++;
    if (_maxAreaCtrl.text.trim().isNotEmpty) count++;
    if (_agencyFilterCtrl.text.trim().isNotEmpty) count++;
    if (_brokerFilterCtrl.text.trim().isNotEmpty) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _purposeFilter = 'All';
      _bhkFilter = 'All';
      _propTypeFilter = 'All';
      _furnishingFilter = 'All';
      _statusFilter = 'All';
      _selectedFilter = 'All';
      _selectedCity = 'All';
      _selectedArea = 'All';
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _minAreaCtrl.clear();
      _maxAreaCtrl.clear();
      _agencyFilterCtrl.clear();
      _brokerFilterCtrl.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final props = ref.read(propertyProvider);
      if (props.isEmpty) {
        ref.read(propertyProvider.notifier).fetchProperties();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    _agencyFilterCtrl.dispose();
    _brokerFilterCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const Gap(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, color: AppColors.primaryBlue),
                              Gap(8),
                              Text('Filter Engine (PRD Sec 5)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _purposeFilter = 'All';
                                _bhkFilter = 'All';
                                _propTypeFilter = 'All';
                                _furnishingFilter = 'All';
                                _statusFilter = 'All';
                              });
                              setState(() => _resetFilters());
                            },
                            child: const Text('Reset All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // Purpose Filter
                      const Text('Listing Purpose', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Sale', 'Rent', 'Lease'].map((p) {
                          final isSel = _purposeFilter == p;
                          return ChoiceChip(
                            label: Text(p),
                            selected: isSel,
                            onSelected: (sel) {
                              setModalState(() => _purposeFilter = p);
                              setState(() => _purposeFilter = p);
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                      const Gap(20),

                      // BHK Filter
                      const Text('BHK Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        children: ['All', '1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'].map((b) {
                          final isSel = _bhkFilter == b;
                          return ChoiceChip(
                            label: Text(b),
                            selected: isSel,
                            onSelected: (sel) {
                              setModalState(() => _bhkFilter = b);
                              setState(() => _bhkFilter = b);
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                      const Gap(20),

                      // Furnishing Filter
                      const Text('Furnished Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Unfurnished', 'Semi-Furnished', 'Fully Furnished'].map((f) {
                          final isSel = _furnishingFilter == f;
                          return ChoiceChip(
                            label: Text(f),
                            selected: isSel,
                            onSelected: (sel) {
                              setModalState(() => _furnishingFilter = f);
                              setState(() => _furnishingFilter = f);
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                      const Gap(20),

                      // Availability Status
                      const Text('Availability Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Available', 'Under Negotiation', 'Token Done'].map((s) {
                          final isSel = _statusFilter == s;
                          return ChoiceChip(
                            label: Text(s),
                            selected: isSel,
                            onSelected: (sel) {
                              setModalState(() => _statusFilter = s);
                              setState(() => _statusFilter = s);
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                      const Gap(20),

                      // City Filter Chips
                      const Text('City (PRD Sec 5)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      Builder(builder: (context) {
                        final properties = ref.read(propertyProvider);
                        final availableCities = ['All', ...properties.map((p) => p.city.trim()).where((c) => c.isNotEmpty).toSet()];
                        return Wrap(
                          spacing: 8,
                          children: availableCities.map((city) {
                            final isSel = _selectedCity == city;
                            return ChoiceChip(
                              label: Text(city),
                              selected: isSel,
                              onSelected: (sel) {
                                setModalState(() {
                                  _selectedCity = city;
                                  _selectedArea = 'All';
                                });
                                setState(() {
                                  _selectedCity = city;
                                  _selectedArea = 'All';
                                });
                              },
                              selectedColor: AppColors.primaryBlue,
                              backgroundColor: const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        );
                      }),
                      const Gap(20),

                      // Area Chips (dynamically filtered)
                      Builder(builder: (context) {
                        final properties = ref.read(propertyProvider);
                        final availableAreas = ['All', ...properties.where((p) => _selectedCity == 'All' || p.city.trim().toLowerCase() == _selectedCity.trim().toLowerCase()).map((p) => p.area.trim()).where((a) => a.isNotEmpty).toSet()];
                        if (availableAreas.length <= 1) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Area / Locality', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const Gap(8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableAreas.take(12).map((area) {
                                final isSel = _selectedArea == area;
                                return ChoiceChip(
                                  label: Text(area),
                                  selected: isSel,
                                  onSelected: (sel) {
                                    setModalState(() => _selectedArea = area);
                                    setState(() => _selectedArea = area);
                                  },
                                  selectedColor: AppColors.primaryBlue,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                                );
                              }).toList(),
                            ),
                            const Gap(20),
                          ],
                        );
                      }),

                      // Budget Range
                      const Text('Budget Range (PRD Sec 5)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceCtrl,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'Min Price',
                                hintText: 'e.g. 50L or 1 Cr',
                                prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceCtrl,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'Max Price',
                                hintText: 'e.g. 5 Cr',
                                prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),

                      // Area Size in sqft
                      const Text('Area Size in Sqft', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minAreaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Min Sqft',
                                hintText: 'e.g. 600',
                                prefixIcon: const Icon(Icons.square_foot, size: 16),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: TextField(
                              controller: _maxAreaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Max Sqft',
                                hintText: 'e.g. 2500',
                                prefixIcon: const Icon(Icons.square_foot, size: 16),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),

                      // Agency & Broker Name Filters
                      const Text('Agency & Broker Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const Gap(8),
                      TextField(
                        controller: _agencyFilterCtrl,
                        decoration: InputDecoration(
                          labelText: 'Partner Agency Name',
                          hintText: 'e.g. West Coast Estates',
                          prefixIcon: const Icon(Icons.business_outlined, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const Gap(10),
                      TextField(
                        controller: _brokerFilterCtrl,
                        decoration: InputDecoration(
                          labelText: 'Broker / Agent Name',
                          hintText: 'e.g. Vikram',
                          prefixIcon: const Icon(Icons.person_outline, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const Gap(28),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCollaborationDialog(PropertyModel prop) {
    final clientReqCtrl = TextEditingController();
    final budgetCtrl = TextEditingController(text: prop.price);
    final remarksCtrl = TextEditingController();

    final userRole = AuthStorageService.getUserRole();
    final isAgencyAdmin = userRole == UserRole.agencyAdmin;
    final userData = AuthStorageService.getUserData();
    final userAgency = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgency?['id'];

    String? selectedBrokerId;
    if (isAgencyAdmin) {
      final currentBrokers = ref.read(agencyProvider).brokers;
      if (currentBrokers.isEmpty) {
        ref.read(agencyProvider.notifier).fetchBrokers(agencyId: userAgencyId);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    Text(
                      'Requesting to collaborate on ${prop.title} with ${prop.agencyName.isNotEmpty ? prop.agencyName : "Listing Agency"}.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const Gap(20),

                    // Broker Attachment (Agency Admin Only)
                    if (isAgencyAdmin) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_pin_outlined, size: 18, color: Color(0xFF166534)),
                                const Gap(6),
                                const Text(
                                  'Attach Broker to Collaboration',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Admin Only', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                ),
                              ],
                            ),
                            const Gap(4),
                            const Text(
                              'Optionally assign this request and deal to a broker from your agency. You will retain full visibility.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF14532D)),
                            ),
                            const Gap(10),
                            Consumer(
                              builder: (context, ref, _) {
                                final agency = ref.watch(agencyProvider);
                                final activeBrokers = agency.brokers.where((b) => b.isActive).toList();

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      isExpanded: true,
                                      value: selectedBrokerId,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF15803D)),
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Row(
                                            children: [
                                              Icon(Icons.admin_panel_settings_outlined, size: 17, color: Color(0xFF15803D)),
                                              Gap(8),
                                              Text(
                                                'Assign to Myself (Agency Admin)',
                                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...activeBrokers.map((b) => DropdownMenuItem<String?>(
                                              value: b.id,
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.person_outline, size: 17, color: AppColors.textPrimary),
                                                  const Gap(8),
                                                  Expanded(
                                                    child: Text(
                                                      '${b.name}${b.phone.isNotEmpty ? " (${b.phone})" : (b.email.isNotEmpty ? " (${b.email})" : "")}',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ],
                                      onChanged: (val) {
                                        setModalState(() {
                                          selectedBrokerId = val;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                    ],

                    _buildPremiumTextField(clientReqCtrl, 'Client Requirement', Icons.list_alt_outlined),
                    const Gap(16),
                    _buildPremiumTextField(budgetCtrl, 'Expected Budget', Icons.monetization_on_outlined),
                    const Gap(16),
                    _buildPremiumTextField(remarksCtrl, 'Remarks (Optional)', Icons.notes_outlined, maxLines: 3),
                    const Gap(28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (clientReqCtrl.text.isNotEmpty || budgetCtrl.text.isNotEmpty) {
                          final newId = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                          final userData = AuthStorageService.getUserData();
                          final userAgency = userData?['agency'] as Map<String, dynamic>?;
                          final userAgencyId = userData?['agencyId'] ?? userAgency?['id'];
                          final userAgencyName = (userAgency?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? 'Partner Agency';
                          final currentUserId = userData?['id'];
                          final currentUserName = (userData?['name'] as String?) ?? 'Broker';

                          final agency = ref.read(agencyProvider);
                          final BrokerModel? assignedBroker = (isAgencyAdmin && selectedBrokerId != null)
                              ? agency.brokers.where((b) => b.id == selectedBrokerId).firstOrNull
                              : null;

                          final resolvedBrokerId = assignedBroker != null
                              ? int.tryParse(assignedBroker.id)
                              : (currentUserId != null ? int.tryParse(currentUserId.toString()) : null);

                          final resolvedBrokerName = assignedBroker != null
                              ? assignedBroker.name
                              : currentUserName;

                          final resolvedPartnerId = BrokerDirectoryService.resolvePartnerForProperty(prop);
                          final targetBrokerId = prop.brokerId ?? int.tryParse(resolvedPartnerId);
                          final targetBrokerName = prop.brokerName.isNotEmpty ? prop.brokerName : 'Partner Broker';

                          await ref.read(dealProvider.notifier).addDeal(
                            DealModel(
                              id: newId,
                              dealCode: newId,
                              propertyId: prop.id,
                              propertyName: prop.title,
                              agencyAId: prop.agencyId,
                              agencyAName: prop.agencyName,
                              brokerAId: targetBrokerId,
                              brokerAName: targetBrokerName,
                              agencyBId: userAgencyId != null ? int.tryParse(userAgencyId.toString()) : null,
                              agencyBName: userAgencyName,
                              brokerBId: resolvedBrokerId,
                              brokerBName: resolvedBrokerName,
                              partnerBroker: targetBrokerName,
                              partnerAgency: prop.agencyName.isNotEmpty ? prop.agencyName : 'Partner Agency',
                              status: 'Pending',
                              amount: budgetCtrl.text.isNotEmpty ? budgetCtrl.text : prop.price,
                              expectedBudget: budgetCtrl.text.isNotEmpty ? budgetCtrl.text : prop.price,
                              dealValue: DealModel.parsePriceToNumeric(budgetCtrl.text.isNotEmpty ? budgetCtrl.text : prop.price),
                              isRequest: true,
                              clientRequirement: clientReqCtrl.text,
                              remarks: remarksCtrl.text,
                              createdAt: DateTime.now(),
                            ),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const Gap(10),
                                    Text('Collaboration Request sent for ${prop.title}!'),
                                  ],
                                ),
                                backgroundColor: Colors.teal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter client requirements or budget'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      child: const Text('Send Collaboration Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildPremiumTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: AppColors.iconColor, size: 20)
            : Padding(padding: const EdgeInsets.only(bottom: 48), child: Icon(icon, color: AppColors.iconColor, size: 20)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertyProvider);
    final deals = ref.watch(accessibleDealsProvider);
    final isLoading = ref.watch(isPropertiesLoadingProvider);
    final userData = AuthStorageService.getUserData();
    final userAgency = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgency?['id'];
    final userAgencyName = (userAgency?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';
    final userName = (userData?['name'] as String?) ?? '';

    // Filter out user's own agency/account properties (only show public partner properties for collaboration)
    final filteredProps = properties.where((p) {
      // Only show public network listings for collaboration
      if (!p.isPublic) {
        return false;
      }

      // CRITICAL: When a property is sold, it should NOT appear in search!
      final statusLower = p.status.toLowerCase().trim();
      final isPropSold = statusLower == 'sold' ||
          statusLower == 'rented' ||
          deals.any((d) =>
              d.propertyId == p.id &&
              (d.normalizedStage == 'Deal Closed' || d.status.toLowerCase().contains('sold')));
      if (isPropSold) {
        return false;
      }

      // Exclude own agency by agencyId if available
      if (userAgencyId != null && p.agencyId != null && p.agencyId.toString() == userAgencyId.toString()) {
        return false;
      }

      final isOwnAgency = userAgencyName.isNotEmpty && p.agencyName.toLowerCase().trim() == userAgencyName.toLowerCase().trim();
      final isOwnBroker = userName.isNotEmpty && p.brokerName.toLowerCase().trim() == userName.toLowerCase().trim();
      if (isOwnAgency || isOwnBroker) {
        return false;
      }

      final query = _searchQuery.trim().toLowerCase();

      // Purpose Multi-Filter
      if (_purposeFilter != 'All') {
        final pFilter = _purposeFilter.toLowerCase();
        final matchesPurpose = p.purpose.toLowerCase() == pFilter || p.type.toLowerCase() == pFilter;
        if (!matchesPurpose) return false;
      }

      // BHK Multi-Filter
      if (_bhkFilter != 'All') {
        if (!p.bhk.toLowerCase().contains(_bhkFilter.toLowerCase())) {
          return false;
        }
      }

      // Property Type Multi-Filter
      if (_propTypeFilter != 'All') {
        if (!p.propertyType.toLowerCase().contains(_propTypeFilter.toLowerCase())) {
          return false;
        }
      }

      // Furnishing Multi-Filter
      if (_furnishingFilter != 'All') {
        if (!p.furnishedStatus.toLowerCase().contains(_furnishingFilter.toLowerCase())) {
          return false;
        }
      }

      // Status Multi-Filter
      if (_statusFilter != 'All') {
        if (!p.status.toLowerCase().contains(_statusFilter.toLowerCase())) {
          return false;
        }
      }

      // City Filter
      if (_selectedCity != 'All') {
        if (!p.city.toLowerCase().trim().contains(_selectedCity.toLowerCase().trim()) &&
            !p.location.toLowerCase().trim().contains(_selectedCity.toLowerCase().trim())) {
          return false;
        }
      }

      // Area Filter
      if (_selectedArea != 'All') {
        if (!p.area.toLowerCase().trim().contains(_selectedArea.toLowerCase().trim()) &&
            !p.location.toLowerCase().trim().contains(_selectedArea.toLowerCase().trim())) {
          return false;
        }
      }

      // Budget Range Filter (PRD Sec 5)
      final minPriceText = _minPriceCtrl.text.trim();
      if (minPriceText.isNotEmpty) {
        final minVal = DealModel.parsePriceToNumeric(minPriceText);
        if (minVal > 0 && p.numericPrice < minVal) {
          return false;
        }
      }
      final maxPriceText = _maxPriceCtrl.text.trim();
      if (maxPriceText.isNotEmpty) {
        final maxVal = DealModel.parsePriceToNumeric(maxPriceText);
        if (maxVal > 0 && p.numericPrice > maxVal) {
          return false;
        }
      }

      // Area Size Range Filter (sqft)
      final minAreaText = _minAreaCtrl.text.trim();
      if (minAreaText.isNotEmpty) {
        final minArea = double.tryParse(minAreaText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        if (minArea > 0 && p.areaSqft < minArea) {
          return false;
        }
      }
      final maxAreaText = _maxAreaCtrl.text.trim();
      if (maxAreaText.isNotEmpty) {
        final maxArea = double.tryParse(maxAreaText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        if (maxArea > 0 && p.areaSqft > maxArea) {
          return false;
        }
      }

      // Agency Name Filter
      final agencyFilterText = _agencyFilterCtrl.text.trim().toLowerCase();
      if (agencyFilterText.isNotEmpty) {
        if (!p.agencyName.toLowerCase().contains(agencyFilterText)) {
          return false;
        }
      }

      // Broker Name Filter
      final brokerFilterText = _brokerFilterCtrl.text.trim().toLowerCase();
      if (brokerFilterText.isNotEmpty) {
        if (!p.brokerName.toLowerCase().contains(brokerFilterText)) {
          return false;
        }
      }

      // Category Chip Filter
      if (_selectedFilter != 'All') {
        final filterLower = _selectedFilter.toLowerCase();
        final matchesType = p.type.toLowerCase() == filterLower;
        final matchesPropType = p.propertyType.toLowerCase() == filterLower;
        final matchesTitle = p.title.toLowerCase().contains(filterLower);
        if (!matchesType && !matchesPropType && !matchesTitle) {
          return false;
        }
      }

      // Search Query Filter
      if (query.isNotEmpty) {
        final matchesTitle = p.title.toLowerCase().contains(query);
        final matchesLocation = p.location.toLowerCase().contains(query);
        final matchesBhk = p.bhk.toLowerCase().contains(query);
        final matchesPrice = p.price.toLowerCase().contains(query);
        final matchesType = p.type.toLowerCase().contains(query);
        final matchesPropType = p.propertyType.toLowerCase().contains(query);
        final matchesAgency = p.agencyName.toLowerCase().contains(query);
        final matchesBroker = p.brokerName.toLowerCase().contains(query);

        if (!matchesTitle &&
            !matchesLocation &&
            !matchesBhk &&
            !matchesPrice &&
            !matchesType &&
            !matchesPropType &&
            !matchesAgency &&
            !matchesBroker) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Search Properties', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Search Bar Section with PRD Filter Engine Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search by city, project, BHK, or broker...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                    ),
                  ),
                ),
                const Gap(10),
                Badge(
                  isLabelVisible: activeFilterCount > 0,
                  label: Text('$activeFilterCount'),
                  backgroundColor: AppColors.primaryBlue,
                  child: InkWell(
                    onTap: _showFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: activeFilterCount > 0 ? AppColors.primaryBlue.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activeFilterCount > 0 ? AppColors.primaryBlue : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: activeFilterCount > 0 ? AppColors.primaryBlue : const Color(0xFF475569),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Filter Chips Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 38,
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
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),

          // Property Results List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(propertyProvider.notifier).fetchProperties(),
              color: AppColors.primaryBlue,
              child: isLoading && properties.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const Gap(18),
                            const Text(
                              'Searching Cloud Inventory...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Gap(6),
                            const Text(
                              'Retrieving partner listings from Aiven PostgreSQL...',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredProps.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                  child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.primaryBlue),
                                ),
                                const Gap(16),
                                const Text(
                                  'No Matching Properties Found',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const Gap(6),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedFilter != 'All'
                                      ? 'Try adjusting your search query or clear filters.'
                                      : 'No properties are currently available in the database.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
                                  const Gap(20),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedFilter = 'All';
                                      });
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Reset All Filters'),
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProps.length,
                          itemBuilder: (context, index) {
                            final prop = filteredProps[index];
                            return GestureDetector(
                              onTap: () => context.push('/property-details/${prop.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Image Header with Type Badge
                              Stack(
                                children: [
                                  Container(
                                    height: 140,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: prop.images.isNotEmpty
                                        ? (prop.images.first.startsWith('http')
                                            ? Image.network(prop.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.apartment, size: 48, color: AppColors.primaryBlue)))
                                            : Image.asset(prop.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.apartment, size: 48, color: AppColors.primaryBlue))))
                                        : const Center(child: Icon(Icons.apartment, size: 48, color: AppColors.primaryBlue)),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: prop.type == 'Sale' ? AppColors.primaryBlue : Colors.teal,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'For ${prop.type}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  if (prop.bhk.isNotEmpty)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          prop.bhk,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // Details Section
                              Builder(
                                builder: (context) {
                                  final matchingDeals = deals.where((d) =>
                                    (d.propertyId.trim() == prop.id.trim() ||
                                     (d.propertyName.isNotEmpty && prop.title.isNotEmpty && d.propertyName.trim().toLowerCase() == prop.title.trim().toLowerCase()))
                                  ).toList();

                                  final activeDeal = matchingDeals.cast<DealModel?>().firstWhere(
                                    (d) => d != null && (!d.isRequest || d.status.toLowerCase() == 'approved'),
                                    orElse: () => null,
                                  );

                                  final pendingCollab = matchingDeals.cast<DealModel?>().firstWhere(
                                    (d) => d != null && d.isRequest && d.status.toLowerCase() == 'pending',
                                    orElse: () => null,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              prop.price,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primaryBlue),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (activeDeal != null) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFECFDF5),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                                        Gap(4),
                                                        Text('Active Deal', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 11)),
                                                      ],
                                                    ),
                                                  ),
                                                  const Gap(6),
                                                ] else if (pendingCollab != null) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFFBEB),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFD97706)),
                                                        Gap(4),
                                                        Text('Pending', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 11)),
                                                      ],
                                                    ),
                                                  ),
                                                  const Gap(6),
                                                ],
                                                if (prop.propertyType.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      prop.propertyType,
                                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Gap(6),
                                        Text(
                                          prop.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                        ),
                                        const Gap(4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                                            const Gap(4),
                                            Expanded(
                                              child: Text(
                                                prop.location,
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (prop.agencyName.isNotEmpty) ...[
                                          const Gap(10),
                                          Row(
                                            children: [
                                              const Icon(Icons.business_outlined, size: 14, color: AppColors.primaryBlue),
                                              const Gap(6),
                                              Text(
                                                prop.agencyName,
                                                style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const Gap(16),
                                        if (activeDeal != null)
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                final targetId = activeDeal.id.isNotEmpty ? activeDeal.id : activeDeal.dealCode;
                                                context.push('/deal-details/$targetId');
                                              },
                                              icon: const Icon(Icons.handshake_rounded, size: 18, color: Colors.white),
                                              label: const Text('View Active Deal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF059669),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          )
                                        else if (pendingCollab != null)
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: () => context.push('/collaborations'),
                                              icon: const Icon(Icons.hourglass_top_rounded, size: 18, color: Colors.white),
                                              label: const Text('Request Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFD97706),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showCollaborationDialog(prop),
                                              icon: const Icon(Icons.handshake_outlined, size: 18, color: Colors.white),
                                              label: const Text('Request Collaboration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primaryBlue,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
