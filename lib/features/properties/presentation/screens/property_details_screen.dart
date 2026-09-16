import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:flutter/services.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.handshake_outlined, color: AppColors.primaryBlue),
                          Gap(8),
                          Text('Request Collaboration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    'Collaborate on ${property.title} with ${property.agencyName}.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const Gap(20),
                  _buildPremiumTextField(clientReqCtrl, 'Client Requirement', Icons.list_alt_outlined),
                  const Gap(16),
                  _buildPremiumTextField(budgetCtrl, 'Expected Budget (e.g. ₹3.5 Cr)', Icons.monetization_on_outlined, isNumber: true),
                  const Gap(16),
                  _buildPremiumTextField(remarksCtrl, 'Remarks / Commission Split terms (Optional)', Icons.notes_outlined, maxLines: 3, isRequired: false),
                  const Gap(28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final newId = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                        final userData = AuthStorageService.getUserData();
                        final userAgency = userData?['agency'] as Map<String, dynamic>?;
                        final userAgencyId = userData?['agencyId'] ?? userAgency?['id'];
                        final userAgencyName = (userAgency?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? 'Partner Agency';
                        final currentUserId = userData?['id'];
                        final currentUserName = (userData?['name'] as String?) ?? 'Broker';

                        ref.read(dealProvider.notifier).addDeal(
                          DealModel(
                            id: newId,
                            dealCode: newId,
                            propertyId: property.id,
                            propertyName: property.title,
                            agencyAId: property.agencyId,
                            agencyAName: property.agencyName,
                            brokerAName: property.brokerName,
                            agencyBId: userAgencyId != null ? int.tryParse(userAgencyId.toString()) : null,
                            agencyBName: userAgencyName,
                            brokerBId: currentUserId != null ? int.tryParse(currentUserId.toString()) : null,
                            brokerBName: currentUserName,
                            partnerBroker: property.brokerName,
                            partnerAgency: property.agencyName,
                            status: 'Pending',
                            amount: budgetCtrl.text,
                            expectedBudget: budgetCtrl.text,
                            dealValue: double.tryParse(budgetCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                            isRequest: true,
                            isIncomingRequest: false,
                            clientRequirement: clientReqCtrl.text,
                            remarks: remarksCtrl.text.isNotEmpty ? remarksCtrl.text : null,
                            createdAt: DateTime.now(),
                          ),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Collaboration Request sent to ${property.agencyName}!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Send Collaboration Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const Gap(32),
                ],
              ),
            ),
          ),
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

  Widget _buildPremiumTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool isRequired = true, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.primaryBlue, size: 20) : Padding(padding: const EdgeInsets.only(bottom: 48), child: Icon(icon, color: AppColors.primaryBlue)),
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

    final parkingText = property.parking <= 0
        ? 'No Reserved Bay'
        : '${property.parking} Covered Bay${property.parking > 1 ? 's' : ''}';
    final ageText = property.propertyAge <= 0
        ? 'Brand New / Ready'
        : '${property.propertyAge} Year${property.propertyAge > 1 ? 's' : ''} Old';
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
        value: property.status,
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF059669),
        iconBg: const Color(0xFFECFDF5),
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.price,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                _formatRatePerSqft(property),
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
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
                              property.location,
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
                          Row(
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
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Property Specifications',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    'Verified physical & listing parameters',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                          Row(
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
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amenities & Features',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    'Lifestyle & building facilities',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                const Gap(12),

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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Listing Broker & Agency',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Direct contact & agency verification',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
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
                                  final partnerId = '2'; // Partner broker ID
                                  final sorted = [currentUserId, partnerId]..sort();
                                  final convId = 'conv_${sorted[0]}_${sorted[1]}';

                                  context.push(
                                    '/chat/$convId',
                                    extra: {
                                      'partnerId': partnerId,
                                      'partnerName': property.brokerName,
                                      'agencyName': property.agencyName,
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About This Property',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Overview & broker notes',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
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
                          Row(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOwnAgencyProperty ? 'Owner Details & Confidential Data' : 'Owner Privacy Firewall',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    isOwnAgencyProperty ? 'Exclusive internal agency records' : 'Protected under broker privacy matrix',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
              else ...[
                // Chat button
                OutlinedButton.icon(
                  onPressed: () {
                    final currentUserId = userData?['id']?.toString() ?? '1';
                    final partnerId = '2';
                    final sorted = [currentUserId, partnerId]..sort();
                    final convId = 'conv_${sorted[0]}_${sorted[1]}';

                    context.push(
                      '/chat/$convId',
                      extra: {
                        'partnerId': partnerId,
                        'partnerName': property.brokerName,
                        'agencyName': property.agencyName,
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
    if (numVal == null) return 'Price On Request';

    if (property.type.toLowerCase() == 'rent') {
      final perSqftMonth = (numVal / property.areaSqft).round();
      return '₹$perSqftMonth / sq.ft / mo';
    } else {
      final pLower = property.price.toLowerCase();
      double totalRupees = numVal;
      if (pLower.contains('cr')) {
        totalRupees = numVal * 10000000;
      } else if (pLower.contains('l') || pLower.contains('lac') || pLower.contains('lakh')) {
        totalRupees = numVal * 100000;
      }
      final perSqft = (totalRupees / property.areaSqft).round();
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
            Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
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
