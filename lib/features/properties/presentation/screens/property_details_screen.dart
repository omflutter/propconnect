import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/agency_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:flutter/services.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/broker_directory_service.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  late PageController _pageController;
  int _currentPhotoIndex = 0;
  bool _isFavorite = false;

  // Fallback high-resolution architectural photos if listing has 0 images
  static const List<String> _fallbackImages = [
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=1200',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1200',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=1200',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1200',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final props = ref.read(propertyProvider);
      if (props.isEmpty) {
        ref.read(propertyProvider.notifier).fetchProperties();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Robust image widget supporting Network URLs, Assets, and gracefully handling errors
  Widget _buildPropertyImage(String url, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFE2E8F0),
          width: width,
          height: height,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, size: 36, color: Color(0xFF94A3B8)),
                Gap(4),
                Text('Image Unavailable', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ),
      );
    } else if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFE2E8F0),
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.apartment, size: 40, color: AppColors.primaryBlue)),
        ),
      );
    } else {
      return Image.network(
        _fallbackImages.first,
        fit: fit,
        width: width,
        height: height,
      );
    }
  }

  /// Opens full-screen photo viewer dialog with pinch & zoom support
  void _openFullScreenGallery(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        int activeIdx = initialIndex;
        final dialogPageCtrl = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setGalleryState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  '${activeIdx + 1} of ${images.length} Photos',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                centerTitle: true,
              ),
              body: PageView.builder(
                controller: dialogPageCtrl,
                itemCount: images.length,
                onPageChanged: (idx) => setGalleryState(() => activeIdx = idx),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 3.5,
                    child: Center(
                      child: _buildPropertyImage(images[index], fit: BoxFit.contain),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showCollaborationDialog(BuildContext context, WidgetRef ref, PropertyModel property) {
    final formKey = GlobalKey<FormState>();
    final budgetCtrl = TextEditingController(text: property.price);
    final customSplitCtrl = TextEditingController();
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

    String clientProfile = 'End-User';
    String purpose = 'Outright Purchase';
    String financingStatus = 'Pre-Approved Loan';
    String timeline = 'Immediate (<15 Days)';
    String commissionSplit = '50 / 50 (Standard)';
    DateTime? visitDate;
    String visitSlot = 'Morning (10 AM - 1 PM)';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.handshake_outlined, color: AppColors.primaryBlue, size: 22),
                              ),
                              const Gap(10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Co-Brokerage Request',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    'Inter-Agency Collaboration Module',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                            onPressed: () => Navigator.pop(bottomSheetCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Scrollable Form Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Target Property Context Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: property.images.isNotEmpty
                                            ? (property.images.first.startsWith('http')
                                                ? Image.network(property.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.apartment, size: 24, color: AppColors.primaryBlue)))
                                                : Image.asset(property.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.apartment, size: 24, color: AppColors.primaryBlue))))
                                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.apartment, size: 24, color: AppColors.primaryBlue)),
                                      ),
                                    ),
                                    const Gap(12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            property.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Gap(2),
                                          Text(
                                            '${property.agencyName} • ${property.brokerName}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Gap(2),
                                          Text(
                                            'Asking Price: ${property.price}',
                                            style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(16),

                              // PRD 4.5.2 Privacy Firewall Banner
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                                    Gap(10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Privacy Firewall Protected (PRD 4.5.2)',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E40AF)),
                                          ),
                                          Gap(3),
                                          Text(
                                            'Your client\'s name, phone, and direct contact details stay 100% confidential. The listing agency will only receive structured deal terms and requirements.',
                                            style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.35),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(20),

                              // Section: Broker Assignment (Agency Admin)
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
                                        'Optionally delegate this collaboration and deal to a broker from your agency. You will retain full admin visibility.',
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

                              // Section: Client Profile
                              const Text('1. Client Profile *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              const Gap(8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ['End-User', 'Investor', 'Corporate'].map((opt) {
                                  final isSel = clientProfile == opt;
                                  return ChoiceChip(
                                    label: Text(opt),
                                    selected: isSel,
                                    selectedColor: AppColors.primaryBlue,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.white : AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) => setModalState(() => clientProfile = opt),
                                  );
                                }).toList(),
                              ),
                              const Gap(16),

                              // Section: Transaction Purpose
                              const Text('2. Transaction Purpose *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              const Gap(8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ['Outright Purchase', 'Long-Term Lease', 'Corporate Rental'].map((opt) {
                                  final isSel = purpose == opt;
                                  return ChoiceChip(
                                    label: Text(opt),
                                    selected: isSel,
                                    selectedColor: AppColors.primaryBlue,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.white : AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) => setModalState(() => purpose = opt),
                                  );
                                }).toList(),
                              ),
                              const Gap(16),

                              // Section: Financing Readiness
                              const Text('3. Financing & Payment Readiness *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              const Gap(8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  'Pre-Approved Loan',
                                  'Ready Cash / Self-Funded',
                                  'Loan In-Process',
                                  'Mortgage Help Needed',
                                ].map((opt) {
                                  final isSel = financingStatus == opt;
                                  return ChoiceChip(
                                    label: Text(opt),
                                    selected: isSel,
                                    selectedColor: AppColors.primaryBlue,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.white : AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) => setModalState(() => financingStatus = opt),
                                  );
                                }).toList(),
                              ),
                              const Gap(16),

                              // Section: Budget / Expected Offer
                              const Text('4. Buyer Budget / Offer Price *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              const Gap(8),
                              TextFormField(
                                controller: budgetCtrl,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Please specify expected budget' : null,
                                decoration: InputDecoration(
                                  hintText: 'e.g. ₹3.5 Cr',
                                  prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primaryBlue, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                                ),
                              ),
                              const Gap(16),

                              // Section: Closing Timeline
                              const Text('5. Purchase / Move-in Timeline *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              const Gap(8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  'Immediate (<15 Days)',
                                  '30–45 Days',
                                  '60+ Days',
                                  'Flexible',
                                ].map((opt) {
                                  final isSel = timeline == opt;
                                  return ChoiceChip(
                                    label: Text(opt),
                                    selected: isSel,
                                    selectedColor: AppColors.primaryBlue,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.white : AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) => setModalState(() => timeline = opt),
                                  );
                                }).toList(),
                              ),
                              const Gap(16),

                              // Section: Proposed Commission Split
                              Row(
                                children: [
                                  const Text('6. Proposed Commission Split *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                  const Gap(6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade200)),
                                    child: const Text('PRD Standard: 50/50', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  '50 / 50 (Standard)',
                                  '60 / 40 (Listing / Buyer)',
                                  '40 / 60 (Listing / Buyer)',
                                  'Custom',
                                ].map((opt) {
                                  final isSel = commissionSplit == opt;
                                  return ChoiceChip(
                                    label: Text(opt),
                                    selected: isSel,
                                    selectedColor: AppColors.primaryBlue,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.white : AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) => setModalState(() => commissionSplit = opt),
                                  );
                                }).toList(),
                              ),
                              if (commissionSplit == 'Custom') ...[
                                const Gap(8),
                                TextFormField(
                                  controller: customSplitCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Enter custom split terms (e.g. 70/30 or ₹1.5L Fixed)',
                                    prefixIcon: const Icon(Icons.percent, color: AppColors.primaryBlue, size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                                  ),
                                ),
                              ],
                              const Gap(16),

                              // Section: Proposed Site Visit (Optional)
                              const Text('7. Proposed Site Visit (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              const Gap(8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: visitDate ?? DateTime.now().add(const Duration(days: 1)),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 90)),
                                        );
                                        if (picked != null) {
                                          setModalState(() => visitDate = picked);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_month, size: 18, color: AppColors.primaryBlue),
                                      label: Text(
                                        visitDate != null ? DateFormat('EEE, dd MMM yyyy').format(visitDate!) : 'Select Preferred Date',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: visitDate != null ? AppColors.primaryBlue : AppColors.textSecondary,
                                          fontWeight: visitDate != null ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        side: BorderSide(color: visitDate != null ? AppColors.primaryBlue : AppColors.border),
                                      ),
                                    ),
                                  ),
                                  if (visitDate != null) ...[
                                    const Gap(8),
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 20, color: Colors.red),
                                      onPressed: () => setModalState(() => visitDate = null),
                                    ),
                                  ],
                                ],
                              ),
                              if (visitDate != null) ...[
                                const Gap(8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    'Morning (10 AM - 1 PM)',
                                    'Afternoon (1 PM - 4 PM)',
                                    'Evening (4 PM - 7 PM)',
                                  ].map((slot) {
                                    final isSel = visitSlot == slot;
                                    return ChoiceChip(
                                      label: Text(slot),
                                      selected: isSel,
                                      selectedColor: AppColors.primaryBlue,
                                      labelStyle: TextStyle(
                                        color: isSel ? Colors.white : AppColors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      onSelected: (_) => setModalState(() => visitSlot = slot),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const Gap(16),

                              // Section: Specific Requirements / Notes
                              const Text('8. Specific Buyer Preferences & Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              const Gap(8),
                              TextFormField(
                                controller: remarksCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'e.g. High floor preference, Vastu compliant, east entrance, 2 covered car parks, pet friendly...',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                                ),
                              ),
                              const Gap(24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          if (formKey.currentState!.validate()) {
                                            setModalState(() => isSubmitting = true);

                                            final splitFinal = commissionSplit == 'Custom' && customSplitCtrl.text.trim().isNotEmpty
                                                ? customSplitCtrl.text.trim()
                                                : commissionSplit;

                                            // Construct structured requirement text
                                            final reqBuffer = StringBuffer();
                                            reqBuffer.writeln('• Profile: $clientProfile ($purpose)');
                                            reqBuffer.writeln('• Financing: $financingStatus');
                                            reqBuffer.writeln('• Timeline: $timeline');
                                            reqBuffer.writeln('• Proposed Split: $splitFinal');
                                            if (visitDate != null) {
                                              reqBuffer.writeln('• Site Visit: ${DateFormat('dd MMM yyyy').format(visitDate!)} ($visitSlot)');
                                            }
                                            if (remarksCtrl.text.trim().isNotEmpty) {
                                              reqBuffer.writeln('• Preferences: ${remarksCtrl.text.trim()}');
                                            }

                                            final structuredReq = reqBuffer.toString().trim();
                                            final remarksSummary = 'Split: $splitFinal${visitDate != null ? ' | Visit: ${DateFormat('dd MMM yyyy').format(visitDate!)}' : ''}${remarksCtrl.text.trim().isNotEmpty ? ' | ${remarksCtrl.text.trim()}' : ''}';

                                            final newId = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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

                                            final rawBudgetNum = double.tryParse(budgetCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                            final resolvedPartnerId = BrokerDirectoryService.resolvePartnerForProperty(property);
                                            final targetBrokerId = property.brokerId ?? int.tryParse(resolvedPartnerId);

                                            await ref.read(dealProvider.notifier).addDeal(
                                                  DealModel(
                                                    id: newId,
                                                    dealCode: newId,
                                                    propertyId: property.id,
                                                    propertyName: property.title,
                                                    agencyAId: property.agencyId,
                                                    agencyAName: property.agencyName,
                                                    brokerAId: targetBrokerId,
                                                    brokerAName: property.brokerName.isNotEmpty ? property.brokerName : 'Partner Broker',
                                                    agencyBId: userAgencyId != null ? int.tryParse(userAgencyId.toString()) : null,
                                                    agencyBName: userAgencyName,
                                                    brokerBId: resolvedBrokerId,
                                                    brokerBName: resolvedBrokerName,
                                                    partnerBroker: property.brokerName,
                                                    partnerAgency: property.agencyName,
                                                    status: 'Pending',
                                                    amount: budgetCtrl.text.trim(),
                                                    expectedBudget: budgetCtrl.text.trim(),
                                                    dealValue: rawBudgetNum,
                                                    isRequest: true,
                                                    isIncomingRequest: false,
                                                    clientRequirement: structuredReq,
                                                    remarks: remarksSummary,
                                                    createdAt: DateTime.now(),
                                                  ),
                                                );

                                            if (context.mounted) {
                                              Navigator.pop(bottomSheetCtx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                                      const Gap(10),
                                                      Expanded(
                                                        child: Text(
                                                          'Co-Brokerage Request $newId sent to ${property.agencyName}!',
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green.shade700,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: isSubmitting
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    isSubmitting ? 'Submitting Request...' : 'Send Co-Brokerage Request',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  void _showWhatsAppShareModal(BuildContext context, PropertyModel property) {
    final clientPhoneCtrl = TextEditingController(text: '+91 ');
    final clientNameCtrl = TextEditingController();
    bool isDispatching = false;

    final formattedShareText = '''
🏡 *${property.title}*
📍 Location: ${property.location}
💰 Price: ${property.price}
📐 Carpet Area: ${property.carpetArea.toInt()} sqft (Built-up: ${property.areaSqft.toInt()} sqft)
🛋️ Configuration: ${property.bhk} - ${property.purpose}

✨ Highlights: ${property.amenities.take(4).join(', ')}
📄 View full details & brochure:
https://propconnect-b89bd.web.app/properties/${property.id}
'''.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        const Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                            Gap(8),
                            Text(
                              'Share on WhatsApp',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const Gap(6),
                    const Text(
                      'PRD Sec 16: Share property details or dispatch official brochure via Interakt WhatsApp API.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Gap(18),

                    // Section 1: Copy WhatsApp Formatted Message
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.message_outlined, size: 16, color: Color(0xFF16A34A)),
                              Gap(6),
                              Text(
                                'Direct WhatsApp Message Card',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            formattedShareText,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                          ),
                          const Gap(10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF16A34A),
                              side: const BorderSide(color: Color(0xFF16A34A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Formatted WhatsApp Message'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: formattedShareText));
                              Navigator.pop(modalContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF16A34A),
                                  content: Text('WhatsApp message copied! Ready to paste to your client.'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const Gap(20),

                    // Section 2: Send Official Brochure via Interakt
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.send_to_mobile, size: 16, color: AppColors.primaryBlue),
                              Gap(6),
                              Text(
                                'Send Official Brochure via Interakt API',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const Gap(12),
                          TextField(
                            controller: clientPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Client WhatsApp Number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const Gap(10),
                          TextField(
                            controller: clientNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Client Name (Optional)',
                              prefixIcon: const Icon(Icons.person_outline, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const Gap(14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: isDispatching
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send_rounded, size: 16),
                            label: Text(isDispatching ? 'Dispatching via Interakt...' : 'Dispatch Brochure to WhatsApp'),
                            onPressed: isDispatching ? null : () async {
                              final phone = clientPhoneCtrl.text.trim();
                              if (phone.length < 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid 10-digit WhatsApp number')),
                                );
                                return;
                              }

                              setModalState(() => isDispatching = true);
                              final res = await ApiService.sendWhatsAppBrochure(
                                recipientPhone: phone,
                                propertyName: property.title,
                                clientName: clientNameCtrl.text.trim().isNotEmpty ? clientNameCtrl.text.trim() : null,
                                propertyPrice: property.price,
                                propertyLocation: property.location,
                                bhk: property.bhk,
                                carpetArea: '${property.carpetArea.toInt()} sqft',
                                brochureUrl: 'https://propconnect-b89bd.web.app/brochure/${property.id}',
                              );
                              setModalState(() => isDispatching = false);

                              if (context.mounted) {
                                Navigator.pop(modalContext);
                                if (res['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF16A34A),
                                      content: Text('Official brochure dispatched to $phone via Interakt!'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? 'Failed to send WhatsApp brochure'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertyProvider);
    final isLoading = ref.watch(isPropertiesLoadingProvider);

    if (isLoading && properties.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Text('Property Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Center(
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
              const Gap(20),
              const Text(
                'Loading Property Details...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Gap(6),
              const Text(
                'Retrieving live listing from Aiven PostgreSQL...',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final property = properties.firstWhere(
      (p) => p.id == widget.propertyId,
      orElse: () => properties.isNotEmpty ? properties.first : PropertyModel(
        id: widget.propertyId,
        title: 'Premium Property',
        location: 'Mumbai, Maharashtra',
        price: '₹3.5 Cr',
        bhk: '3 BHK',
        type: 'Sale',
        isPublic: true,
        agencyName: 'Sunrise Properties',
        propertyType: 'Apartment',
        status: 'Available',
        brokerName: 'Om Shivam',
        bathrooms: 2,
        balcony: 1,
        parking: 1,
        furnishedStatus: 'Semi-Furnished',
        propertyAge: 1,
        areaSqft: 1250,
        maintenanceCharges: '₹5,000/mo',
        amenities: ['Gym', 'Swimming Pool', 'Security'],
        images: _fallbackImages,
      ),
    );

    // Resolve images: if list is empty, use fallback high-res photos
    final List<String> displayImages = property.images.isNotEmpty ? property.images : _fallbackImages;

    final userData = AuthStorageService.getUserData();
    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final userAgency = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';
    final isOwnAgencyProperty = (userAgencyId != null && property.agencyId != null && property.agencyId == userAgencyId) ||
        (userAgency.isNotEmpty && property.agencyName.toLowerCase().trim() == userAgency.toLowerCase().trim());

    // Check if collaboration or active deal already exists for this property
    final deals = ref.watch(accessibleDealsProvider);
    final currentAgencyIdStr = userAgencyId?.toString();
    final currentUserIdStr = userData?['id']?.toString() ?? '';
    final currentAgencyName = userAgency.trim().toLowerCase();
    final isSuperAdmin = (userData?['role'] as String?)?.toLowerCase() == 'super_admin';

    bool involvesMe(DealModel d) {
      if (isSuperAdmin) return true;
      if (currentAgencyIdStr != null && (d.agencyAId?.toString() == currentAgencyIdStr || d.agencyBId?.toString() == currentAgencyIdStr)) return true;
      if (currentAgencyName.isNotEmpty && (d.agencyAName.trim().toLowerCase() == currentAgencyName || d.agencyBName.trim().toLowerCase() == currentAgencyName)) return true;
      if (currentUserIdStr.isNotEmpty && (d.brokerAId?.toString() == currentUserIdStr || d.brokerBId?.toString() == currentUserIdStr)) return true;
      return false;
    }

    final matchingDeals = deals.where((d) =>
      (d.propertyId.trim() == property.id.trim() ||
       (d.propertyName.isNotEmpty && property.title.isNotEmpty && d.propertyName.trim().toLowerCase() == property.title.trim().toLowerCase())) &&
      involvesMe(d)
    ).toList();

    final activeDeal = matchingDeals.cast<DealModel?>().firstWhere(
      (d) => d != null && (!d.isRequest || d.status.toLowerCase() == 'approved'),
      orElse: () => null,
    );

    final pendingCollab = matchingDeals.cast<DealModel?>().firstWhere(
      (d) => d != null && d.isRequest && d.status.toLowerCase() == 'pending',
      orElse: () => null,
    );

    // Compute if property is sold (either explicitly marked Sold/Rented or closed in any deal)
    final allDeals = ref.watch(dealProvider);
    final statusLower = property.status.toLowerCase().trim();
    final isSold = statusLower == 'sold' ||
        statusLower == 'rented' ||
        allDeals.any((d) =>
            (d.propertyId.trim() == property.id.trim() ||
                (d.propertyName.isNotEmpty &&
                    property.title.isNotEmpty &&
                    d.propertyName.trim().toLowerCase() == property.title.trim().toLowerCase())) &&
            (d.normalizedStage == 'Deal Closed' || d.status.toLowerCase().contains('sold')));

    final parkingText = property.parking <= 0
        ? 'No Reserved Bay'
        : '${property.parking} Covered Bay${property.parking > 1 ? 's' : ''}';
    final ageText = property.displayPropertyAge;
    final maintenanceText = (property.maintenanceCharges.isEmpty || property.maintenanceCharges == '₹0')
        ? 'Included / Zero'
        : property.maintenanceCharges;
    final balconyText = property.balcony <= 0
        ? 'No Balcony'
        : '${property.balcony} Attached Balcon${property.balcony > 1 ? 'ies' : 'y'}';
    final visibilityText = property.isPublic ? 'Public Broker Pool' : 'Agency Exclusive';

    final specItems = [
      _PropertySpecItem(
        label: 'Property Type',
        value: property.propertyType,
        icon: Icons.apartment_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF5F3FF),
      ),
      _PropertySpecItem(
        label: 'Purpose',
        value: 'For ${property.purpose.isNotEmpty ? property.purpose : property.type}',
        icon: Icons.sell_outlined,
        iconColor: const Color(0xFF2563EB),
        iconBg: const Color(0xFFEFF6FF),
      ),
      _PropertySpecItem(
        label: 'Carpet Area',
        value: '${property.carpetArea > 0 ? property.carpetArea.toInt() : (property.areaSqft * 0.8).toInt()} sqft',
        icon: Icons.crop_free,
        iconColor: const Color(0xFF0D9488),
        iconBg: const Color(0xFFF0FDFA),
      ),
      _PropertySpecItem(
        label: 'Furnishing',
        value: property.furnishedStatus.isNotEmpty ? property.furnishedStatus : 'Unfurnished',
        icon: Icons.chair_outlined,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFFFBEB),
      ),
      _PropertySpecItem(
        label: 'Reserved Parking',
        value: parkingText,
        icon: Icons.directions_car_filled_outlined,
        iconColor: const Color(0xFF2563EB),
        iconBg: const Color(0xFFEFF6FF),
      ),
      _PropertySpecItem(
        label: 'Property Age',
        value: ageText,
        icon: Icons.schedule_rounded,
        iconColor: const Color(0xFF0891B2),
        iconBg: const Color(0xFFECFEFF),
      ),
      _PropertySpecItem(
        label: 'Maintenance',
        value: maintenanceText,
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFFEA580C),
        iconBg: const Color(0xFFFFF7ED),
      ),
      _PropertySpecItem(
        label: 'Availability',
        value: isSold ? (property.type == 'Rent' ? 'Rented' : 'Sold') : property.status,
        icon: isSold ? Icons.do_not_disturb_on : Icons.check_circle_rounded,
        iconColor: isSold ? const Color(0xFFDC2626) : const Color(0xFF059669),
        iconBg: isSold ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        isStatus: true,
      ),
      _PropertySpecItem(
        label: 'Balconies',
        value: balconyText,
        icon: Icons.balcony_rounded,
        iconColor: const Color(0xFF4F46E5),
        iconBg: const Color(0xFFEEF2FF),
      ),
      _PropertySpecItem(
        label: 'Visibility',
        value: visibilityText,
        icon: Icons.public_rounded,
        iconColor: const Color(0xFF0284C7),
        iconBg: const Color(0xFFF0F9FF),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Premium Hero Image Slider SliverAppBar
          SliverAppBar(
            expandedHeight: 330.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.redAccent : Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorite ? 'Property saved to favorites!' : 'Removed from favorites'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                    onPressed: () => _showWhatsAppShareModal(context, property),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // PageView for multiple images
                  PageView.builder(
                    controller: _pageController,
                    itemCount: displayImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openFullScreenGallery(displayImages, index),
                        child: Hero(
                          tag: 'property_image_${property.id}_$index',
                          child: _buildPropertyImage(displayImages[index]),
                        ),
                      );
                    },
                  ),

                  // Top gradient overlay for action button contrast
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-left tags (For Sale/Rent, Verified)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Row(
                      children: [
                        if (isSold) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.do_not_disturb_on, color: Colors.white, size: 12),
                                const Gap(4),
                                Text(
                                  property.type == 'Rent' ? 'RENTED' : 'SOLD',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: property.type == 'Rent' ? const Color(0xFF10B981) : AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            'For ${property.type}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.lightBlueAccent, size: 13),
                              Gap(4),
                              Text('Verified Listing', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom-right Photo Counter Badge with Expand Icon
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _openFullScreenGallery(displayImages, _currentPhotoIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.white, size: 14),
                            const Gap(5),
                            Text(
                              '${_currentPhotoIndex + 1} / ${displayImages.length}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-center Page Indicator Dots
                  if (displayImages.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          displayImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPhotoIndex == index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPhotoIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Thumbnail Carousel Strip if multiple images exist
                if (displayImages.length > 1)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayImages.length,
                        separatorBuilder: (context, index) => const Gap(10),
                        itemBuilder: (context, index) {
                          final isSelected = _currentPhotoIndex == index;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 68,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildPropertyImage(displayImages[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Sold Notice Banner
                if (isSold)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.do_not_disturb_on_outlined, color: Color(0xFFDC2626), size: 22),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.type == 'Rent' ? 'Property Marked as Rented' : 'Property Marked as Sold',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF991B1B)),
                              ),
                              const Gap(2),
                              const Text(
                                'This listing is concluded. It has been sold and is no longer accepting new collaboration requests.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            property.type == 'Rent' ? 'RENTED' : 'SOLD',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Info Card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    property.price,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryBlue,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  _formatRatePerSqft(property),
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Gap(10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              property.propertyType,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // Title
                      Text(
                        property.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3),
                      ),
                      const Gap(8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: AppColors.primaryBlue),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              property.pincode.isNotEmpty && !property.location.contains(property.pincode)
                                  ? '${property.location} - ${property.pincode}'
                                  : property.location,
                              style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),

                      // Key Features Highlight Grid
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHighlightItem(Icons.bed_outlined, property.bhk, 'Bedrooms'),
                            _buildHighlightDivider(),
                            _buildHighlightItem(Icons.bathtub_outlined, '${property.bathrooms} Baths', 'Washrooms'),
                            _buildHighlightDivider(),
                            _buildHighlightItem(Icons.aspect_ratio, '${property.areaSqft.toInt()} sqft', 'Super Area'),
                            _buildHighlightDivider(),
                            _buildHighlightItem(Icons.balcony_outlined, '${property.balcony}', 'Balcony'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),

                // Specifications Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.tune_rounded, color: AppColors.primaryBlue, size: 18),
                                ),
                                const Gap(10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Property Specifications',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Verified physical & listing parameters',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '${specItems.length} Specs',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const Gap(18),
                      Column(
                        children: [
                          for (int i = 0; i < specItems.length; i += 2) ...[
                            if (i > 0) const Gap(10),
                            Row(
                              children: [
                                Expanded(child: _buildSpecCard(specItems[i])),
                                const Gap(10),
                                if (i + 1 < specItems.length)
                                  Expanded(child: _buildSpecCard(specItems[i + 1]))
                                else
                                  const Expanded(child: SizedBox.shrink()),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(12),

                // Amenities Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.pool_rounded, color: AppColors.primaryBlue, size: 18),
                                ),
                                const Gap(10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Amenities & Features',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Lifestyle & building facilities',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '${property.amenities.length} Features',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      property.amenities.isEmpty
                          ? const Text('Standard residential amenities included.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: property.amenities.map((amenity) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getAmenityIcon(amenity), size: 16, color: AppColors.primaryBlue),
                                      const Gap(6),
                                      Text(
                                        amenity,
                                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
                // PRD Sec 4.1.1: Video Walkthrough, Floor Plans & Documents
                if (property.videos.isNotEmpty || property.floorPlans.isNotEmpty || property.documents.isNotEmpty) ...[
                  const Gap(12),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.perm_media_outlined, color: AppColors.primaryBlue, size: 18),
                            ),
                            const Gap(10),
                            const Text(
                              'Media & Blueprints (PRD Sec 4.1.1)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        if (property.videos.isNotEmpty) ...[
                          const Gap(16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Video Walkthrough Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                      const Gap(2),
                                      Text(property.videos.first, style: const TextStyle(fontSize: 11.5, color: AppColors.primaryBlue), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (property.floorPlans.isNotEmpty) ...[
                          const Gap(16),
                          const Text('Floor Plans & Layouts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const Gap(8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: property.floorPlans.map((plan) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.architecture, size: 16, color: AppColors.primaryBlue),
                                    const Gap(6),
                                    Text(
                                      plan.split('/').last.isNotEmpty ? plan.split('/').last : 'Floor Plan',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (property.documents.isNotEmpty) ...[
                          const Gap(16),
                          const Text('Verified Documents & Clearances', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const Gap(8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: property.documents.map((doc) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF059669)),
                                    const Gap(6),
                                    Text(
                                      doc.split('/').last.isNotEmpty ? doc.split('/').last : 'Document',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (activeDeal != null) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Co-Brokerage Collaboration Active',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF065F46)),
                                ),
                                const Gap(2),
                                Text(
                                  'Stage: ${activeDeal.status} • Deal Code: ${activeDeal.dealCode.isNotEmpty ? activeDeal.dealCode : activeDeal.id}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final targetId = activeDeal.id.isNotEmpty ? activeDeal.id : activeDeal.dealCode;
                              context.push('/deal-details/$targetId');
                            },
                            child: const Text('View Deal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(12),
                ] else if (pendingCollab != null) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Collaboration Request Pending',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF92400E)),
                                ),
                                const Gap(2),
                                Text(
                                  'Request ${pendingCollab.dealCode.isNotEmpty ? pendingCollab.dealCode : pendingCollab.id} submitted • Awaiting approval',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () => context.push('/collaborations'),
                            child: const Text('Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(12),
                ],

                // Listed By Agency / Broker Card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.badge_rounded, color: AppColors.primaryBlue, size: 18),
                          ),
                          const Gap(10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Listing Broker & Agency',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Direct contact & agency verification',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                              child: Text(
                                property.brokerName.isNotEmpty ? property.brokerName[0].toUpperCase() : 'B',
                                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          property.brokerName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Gap(4),
                                      const Icon(Icons.verified, color: AppColors.primaryBlue, size: 16),
                                    ],
                                  ),
                                  const Gap(2),
                                  Text(
                                    property.agencyName,
                                    style: const TextStyle(fontSize: 13, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                                  ),
                                  const Gap(2),
                                  const Text(
                                    'Verified Partner Agency',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (!isOwnAgencyProperty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  final currentUserId = userData?['id']?.toString() ?? '1';
                                  final partnerId = BrokerDirectoryService.resolvePartnerForProperty(property);
                                  final partnerName = property.brokerName.isNotEmpty ? property.brokerName : property.agencyName;
                                  final sorted = [currentUserId, partnerId]..sort();
                                  final convId = 'conv_${sorted[0]}_${sorted[1]}_${property.id}';

                                  context.push(
                                    '/chat/$convId',
                                    extra: {
                                      'partnerId': partnerId,
                                      'partnerName': partnerName,
                                      'agencyName': property.agencyName,
                                      'property': property,
                                      'chatType': 'property',
                                      'contextTitle': property.title,
                                      'propertyId': property.id,
                                    },
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                                label: const Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),

                // Description
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.article_rounded, color: AppColors.primaryBlue, size: 18),
                          ),
                          const Gap(10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About This Property',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Overview & broker notes',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      Text(
                        property.description.isNotEmpty
                            ? property.description
                            : 'Magnificent ${property.bhk} ${property.propertyType} situated at prime ${property.location}. Features expansive living rooms, premium fittings, high ceilings, and ample ventilation. Verified and authorized for immediate broker co-broking through PropConnect Network.',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const Gap(12),

                // Owner Info & Lead Privacy Firewall Section (PRD Sec 4, 8, 10)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isOwnAgencyProperty ? const Color(0xFF059669).withValues(alpha: 0.1) : AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isOwnAgencyProperty ? Icons.verified_user_rounded : Icons.shield_outlined,
                                    color: isOwnAgencyProperty ? const Color(0xFF059669) : AppColors.primaryBlue,
                                    size: 18,
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isOwnAgencyProperty ? 'Owner Details & Confidential' : 'Owner Privacy Firewall',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        isOwnAgencyProperty ? 'Exclusive internal agency records' : 'Protected under broker privacy matrix',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOwnAgencyProperty ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isOwnAgencyProperty ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              isOwnAgencyProperty ? 'Agency Access' : 'Protected',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isOwnAgencyProperty ? const Color(0xFF065F46) : const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      if (isOwnAgencyProperty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow('Owner Name', property.ownerName.isNotEmpty ? property.ownerName : 'Private Owner on File', Icons.person_outline),
                              const Divider(height: 24, color: AppColors.border),
                              _buildDetailRow('Primary Phone', property.ownerPhonePrimary.isNotEmpty ? property.ownerPhonePrimary : '+91 98200 00000', Icons.phone_outlined),
                              if (property.ownerPhoneSecondary.isNotEmpty) ...[
                                const Divider(height: 24, color: AppColors.border),
                                _buildDetailRow('Secondary Phone', property.ownerPhoneSecondary, Icons.phone_iphone_outlined),
                              ],
                              if (property.ownerEmail.isNotEmpty) ...[
                                const Divider(height: 24, color: AppColors.border),
                                _buildDetailRow('Owner Email', property.ownerEmail, Icons.email_outlined),
                              ],
                              if (property.ownerAddress.isNotEmpty) ...[
                                const Divider(height: 24, color: AppColors.border),
                                _buildDetailRow('Owner Address', property.ownerAddress, Icons.home_work_outlined),
                              ],
                              if (property.negotiablePrice.isNotEmpty) ...[
                                const Divider(height: 24, color: AppColors.border),
                                _buildDetailRow('Min. Target Price', property.negotiablePrice, Icons.lock_outline, isHighlight: true),
                              ],
                              if (property.internalNotes.isNotEmpty) ...[
                                const Divider(height: 24, color: AppColors.border),
                                _buildDetailRow('Internal Notes', property.internalNotes, Icons.notes_outlined),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Owner contact details and private negotiable floor are strictly protected under PropConnect Lead Privacy Firewall. All communication and deal inquiries must be routed through the listing broker.',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.5),
                              ),
                              const Gap(14),
                              _buildDetailRow('Owner Contact', '+91 98*** *****', Icons.phone_locked_outlined),
                              const Divider(height: 24, color: AppColors.border),
                              _buildDetailRow('Negotiable Price', 'Confidential to Listing Agency', Icons.lock_outlined),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(100), // Bottom padding for sticky action bar
              ],
            ),
          ),
        ],
      ),

      // Sticky Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (isOwnAgencyProperty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/add-edit-property/${property.id}'),
                    icon: const Icon(Icons.edit_note, color: Colors.white, size: 22),
                    label: const Text('Edit Listing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else if (activeDeal != null) ...[
                // Chat button
                OutlinedButton.icon(
                  onPressed: () {
                    final currentUserId = userData?['id']?.toString() ?? '1';
                    final partnerId = BrokerDirectoryService.resolvePartnerForProperty(property);
                    final partnerName = property.brokerName.isNotEmpty ? property.brokerName : property.agencyName;
                    final sorted = [currentUserId, partnerId]..sort();
                    final convId = 'conv_${sorted[0]}_${sorted[1]}_${property.id}';

                    context.push(
                      '/chat/$convId',
                      extra: {
                        'partnerId': partnerId,
                        'partnerName': partnerName,
                        'agencyName': property.agencyName,
                        'property': property,
                        'chatType': 'property',
                        'contextTitle': property.title,
                        'propertyId': property.id,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 18),
                  label: const Text('Message', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Gap(12),

                // View Active Deal button (collaboration already done)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final targetId = activeDeal.id.isNotEmpty ? activeDeal.id : activeDeal.dealCode;
                      context.push('/deal-details/$targetId');
                    },
                    icon: const Icon(Icons.handshake_rounded, color: Colors.white, size: 18),
                    label: const Text('View Active Deal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF059669),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else if (isSold) ...[
                // Sold state for other agencies/brokers:
                OutlinedButton.icon(
                  onPressed: () {
                    final currentUserId = userData?['id']?.toString() ?? '1';
                    final partnerId = BrokerDirectoryService.resolvePartnerForProperty(property);
                    final partnerName = property.brokerName.isNotEmpty ? property.brokerName : property.agencyName;
                    final sorted = [currentUserId, partnerId]..sort();
                    final convId = 'conv_${sorted[0]}_${sorted[1]}_${property.id}';

                    context.push(
                      '/chat/$convId',
                      extra: {
                        'partnerId': partnerId,
                        'partnerName': partnerName,
                        'agencyName': property.agencyName,
                        'property': property,
                        'chatType': 'property',
                        'contextTitle': property.title,
                        'propertyId': property.id,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 18),
                  label: const Text('Message', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.do_not_disturb_on, color: Colors.white, size: 18),
                    label: Text(
                      property.type == 'Rent' ? 'Property Rented' : 'Property Sold',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF94A3B8),
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else if (pendingCollab != null) ...[
                // Chat button
                OutlinedButton.icon(
                  onPressed: () {
                    final currentUserId = userData?['id']?.toString() ?? '1';
                    final partnerId = BrokerDirectoryService.resolvePartnerForProperty(property);
                    final partnerName = property.brokerName.isNotEmpty ? property.brokerName : property.agencyName;
                    final sorted = [currentUserId, partnerId]..sort();
                    final convId = 'conv_${sorted[0]}_${sorted[1]}_${property.id}';

                    context.push(
                      '/chat/$convId',
                      extra: {
                        'partnerId': partnerId,
                        'partnerName': partnerName,
                        'agencyName': property.agencyName,
                        'property': property,
                        'chatType': 'property',
                        'contextTitle': property.title,
                        'propertyId': property.id,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 18),
                  label: const Text('Message', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Gap(12),

                // Request Pending button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/collaborations');
                    },
                    icon: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 18),
                    label: const Text('Request Pending', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFD97706),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                // Chat button
                OutlinedButton.icon(
                  onPressed: () {
                    final currentUserId = userData?['id']?.toString() ?? '1';
                    final partnerId = BrokerDirectoryService.resolvePartnerForProperty(property);
                    final partnerName = property.brokerName.isNotEmpty ? property.brokerName : property.agencyName;
                    final sorted = [currentUserId, partnerId]..sort();
                    final convId = 'conv_${sorted[0]}_${sorted[1]}_${property.id}';

                    context.push(
                      '/chat/$convId',
                      extra: {
                        'partnerId': partnerId,
                        'partnerName': partnerName,
                        'agencyName': property.agencyName,
                        'property': property,
                        'chatType': 'property',
                        'contextTitle': property.title,
                        'propertyId': property.id,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 18),
                  label: const Text('Message', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Gap(12),

                // Request Collaboration button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCollaborationDialog(context, ref, property),
                    icon: const Icon(Icons.handshake, color: Colors.white, size: 18),
                    label: const Text('Request Collaboration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 19),
        ),
        const Gap(6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
        ),
        const Gap(2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHighlightDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSpecCard(_PropertySpecItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: item.iconColor),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(3),
                if (item.isStatus)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.value.toLowerCase().contains('avail')
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                      const Gap(5),
                      Flexible(
                        child: Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRatePerSqft(PropertyModel property) {
    if (property.areaSqft <= 0) return 'Price On Request';
    final raw = property.price.replaceAll(RegExp(r'[^0-9.]'), '');
    final numVal = double.tryParse(raw);
    if (numVal == null || numVal <= 0) return 'Price On Request';

    final pLower = property.price.toLowerCase();
    double totalRupees = numVal;
    if (pLower.contains('cr')) {
      totalRupees = numVal * 10000000;
    } else if (pLower.contains('l') || pLower.contains('lac') || pLower.contains('lakh')) {
      totalRupees = numVal * 100000;
    } else if (pLower.contains('k')) {
      totalRupees = numVal * 1000;
    }

    final isRent = property.type.toLowerCase().contains('rent') || property.purpose.toLowerCase().contains('rent');
    if (isRent) {
      final perSqftMonth = (totalRupees / property.areaSqft).round();
      if (perSqftMonth <= 0) return 'Price On Request';
      final formatted = perSqftMonth.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '₹$formatted / sq.ft / mo';
    } else {
      final perSqft = (totalRupees / property.areaSqft).round();
      if (perSqft <= 0) return 'Price On Request';
      final formatted = perSqft.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '₹$formatted / sq.ft';
    }
  }

  IconData _getAmenityIcon(String amenity) {
    final a = amenity.toLowerCase();
    if (a.contains('pool')) return Icons.pool;
    if (a.contains('gym')) return Icons.fitness_center;
    if (a.contains('security')) return Icons.security;
    if (a.contains('park') || a.contains('play')) return Icons.park;
    if (a.contains('sea') || a.contains('view')) return Icons.water;
    if (a.contains('club')) return Icons.nightlife;
    if (a.contains('lift') || a.contains('elevator')) return Icons.elevator;
    if (a.contains('power') || a.contains('backup')) return Icons.bolt;
    return Icons.check_circle_outline;
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isHighlight = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: isHighlight ? AppColors.primaryBlue : AppColors.iconColor, size: 18),
            const Gap(10),
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(8),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const Gap(4),
              const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _PropertySpecItem {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isStatus;

  const _PropertySpecItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isStatus = false,
  });
}
