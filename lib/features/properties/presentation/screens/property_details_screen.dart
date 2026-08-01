import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';

class PropertyDetailsScreen extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

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
                    const Text('Request Collaboration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(8),
                Text('Requesting to collaborate on ${property.title} with ${property.agencyName}.', style: const TextStyle(color: AppColors.textSecondary)),
                const Gap(24),
                _buildPremiumTextField(clientReqCtrl, 'Client Requirement', Icons.list_alt_outlined),
                const Gap(16),
                _buildPremiumTextField(budgetCtrl, 'Expected Budget (e.g. ₹3 Cr)', Icons.monetization_on_outlined, isNumber: true),
                const Gap(16),
                _buildPremiumTextField(remarksCtrl, 'Remarks (Optional)', Icons.notes_outlined, maxLines: 3, isRequired: false),
                const Gap(32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newId = 'R-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
                      ref.read(dealProvider.notifier).addDeal(
                        DealModel(
                          id: newId,
                          propertyId: property.id,
                          propertyName: property.title,
                          partnerBroker: property.brokerName,
                          partnerAgency: property.agencyName,
                          status: 'Pending',
                          amount: budgetCtrl.text,
                          isRequest: true,
                          isIncomingRequest: false,
                          clientRequirement: clientReqCtrl.text,
                          remarks: remarksCtrl.text.isNotEmpty ? remarksCtrl.text : null,
                          createdAt: DateTime.now(),
                        )
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
                  child: const Text('Send Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.iconColor) : Padding(padding: const EdgeInsets.only(bottom: 48), child: Icon(icon, color: AppColors.iconColor)),
        filled: true,
        fillColor: Colors.grey.shade100,
        errorStyle: const TextStyle(color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertyProvider);
    final property = properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => properties.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: property.images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: property.images.length,
                          itemBuilder: (context, index) {
                            return Image.asset(
                              property.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: const BoxDecoration(color: AppColors.border),
                                child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                              ),
                            );
                          },
                        ),
                        if (property.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                property.images.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(color: AppColors.border),
                      child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                    ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(property.price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: property.type == 'Sale' ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'For ${property.type}',
                          style: TextStyle(
                            color: property.type == 'Sale' ? Colors.blue : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Text(property.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Gap(8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
                      const Gap(8),
                      Text(property.location, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      _buildBadge(Icons.bed, property.bhk),
                      const Gap(12),
                      _buildBadge(Icons.square_foot, '${property.areaSqft} sqft'),
                      const Gap(12),
                      _buildBadge(Icons.bathtub, '${property.bathrooms} Baths'),
                    ],
                  ),
                  const Gap(32),
                  const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSpecItem('Property Type', property.propertyType),
                      _buildSpecItem('Furnishing', property.furnishedStatus),
                      _buildSpecItem('Parking', '${property.parking} Spots'),
                      _buildSpecItem('Age', '${property.propertyAge} Years'),
                      _buildSpecItem('Maintenance', property.maintenanceCharges),
                      _buildSpecItem('Balconies', '${property.balcony}'),
                    ],
                  ),
                  const Gap(32),
                  const Text('Amenities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: property.amenities.map((amenity) {
                      return Chip(
                        label: Text(amenity, style: const TextStyle(color: AppColors.primaryBlue)),
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const Gap(32),
                  const Text('Listed By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business, color: AppColors.primaryBlue),
                    ),
                    title: Text(property.agencyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Agent: ${property.brokerName}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.primaryBlue),
                      onPressed: () {},
                    ),
                  ),
                  const Gap(32),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  const Text(
                    'This beautiful property is located in the heart of the city. Featuring modern amenities, 24/7 security, and stunning views. Perfect for families looking for a premium lifestyle.',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const Gap(40),
                  SizedBox(
                    width: double.infinity,
                    child: property.agencyName == 'Sunrise Properties'
                        ? ElevatedButton.icon(
                            onPressed: () => context.push('/add-edit-property/${property.id}'),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Property'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.grey.shade800,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _showCollaborationDialog(context, ref, property),
                            icon: const Icon(Icons.handshake),
                            label: const Text('Request Collaboration'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                  ),
                  const Gap(40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Gap(4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const Gap(8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
