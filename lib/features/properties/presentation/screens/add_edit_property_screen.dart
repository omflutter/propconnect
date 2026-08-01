import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';

class AddEditPropertyScreen extends ConsumerStatefulWidget {
  final String propertyId; // 'new' for adding, otherwise editing

  const AddEditPropertyScreen({super.key, required this.propertyId});

  @override
  ConsumerState<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends ConsumerState<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Details
  late TextEditingController _titleCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _areaCtrl;

  // Categorization
  String _type = 'Sale'; // Sale/Rent
  String _propertyType = 'Apartment'; // Apartment, Villa, Office, etc.
  late TextEditingController _bhkCtrl;

  // Visibility
  bool _isPublic = false;

  // Specifications
  late TextEditingController _bathroomsCtrl;
  late TextEditingController _balconyCtrl;
  late TextEditingController _parkingCtrl;
  late TextEditingController _ageCtrl;
  String _furnishedStatus = 'Unfurnished'; // Unfurnished, Semi-Furnished, Fully Furnished

  // Financials
  late TextEditingController _maintenanceCtrl;

  // Amenities
  final List<String> _availableAmenities = [
    'Gym', 'Swimming Pool', '24/7 Security', 'Play Area', 'Club House',
    'Power Backup', 'Lift', 'Parking', 'Garden', 'Sea View'
  ];
  List<String> _selectedAmenities = [];

  bool get isEditing => widget.propertyId != 'new';
  PropertyModel? existingProp;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    if (isEditing) {
      final properties = ref.read(propertyProvider);
      existingProp = properties.firstWhere((p) => p.id == widget.propertyId, orElse: () => properties.first);
    }

    _titleCtrl = TextEditingController(text: existingProp?.title ?? '');
    _locationCtrl = TextEditingController(text: existingProp?.location ?? '');
    _priceCtrl = TextEditingController(text: existingProp?.price ?? '');
    _areaCtrl = TextEditingController(text: existingProp?.areaSqft.toString() ?? '1000.0');

    _type = existingProp?.type ?? 'Sale';
    _propertyType = existingProp?.propertyType ?? 'Apartment';
    _bhkCtrl = TextEditingController(text: existingProp?.bhk ?? '2 BHK');

    _isPublic = existingProp?.isPublic ?? false;

    _bathroomsCtrl = TextEditingController(text: existingProp?.bathrooms.toString() ?? '2');
    _balconyCtrl = TextEditingController(text: existingProp?.balcony.toString() ?? '1');
    _parkingCtrl = TextEditingController(text: existingProp?.parking.toString() ?? '1');
    _ageCtrl = TextEditingController(text: existingProp?.propertyAge.toString() ?? '0');
    _furnishedStatus = existingProp?.furnishedStatus ?? 'Unfurnished';

    _maintenanceCtrl = TextEditingController(text: existingProp?.maintenanceCharges ?? '₹0');
    _selectedAmenities = List.from(existingProp?.amenities ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _bhkCtrl.dispose();
    _bathroomsCtrl.dispose();
    _balconyCtrl.dispose();
    _parkingCtrl.dispose();
    _ageCtrl.dispose();
    _maintenanceCtrl.dispose();
    super.dispose();
  }

  void _saveProperty() {
    if (_formKey.currentState!.validate()) {
      final newProp = PropertyModel(
        id: isEditing ? existingProp!.id : 'P-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        title: _titleCtrl.text,
        location: _locationCtrl.text,
        price: _priceCtrl.text,
        bhk: _bhkCtrl.text,
        type: _type,
        isPublic: _isPublic,
        agencyName: existingProp?.agencyName ?? 'Sunrise Properties',
        propertyType: _propertyType,
        status: existingProp?.status ?? 'Available',
        brokerName: existingProp?.brokerName ?? 'Amit Patel',
        bathrooms: int.tryParse(_bathroomsCtrl.text) ?? 2,
        balcony: int.tryParse(_balconyCtrl.text) ?? 1,
        parking: int.tryParse(_parkingCtrl.text) ?? 1,
        furnishedStatus: _furnishedStatus,
        propertyAge: int.tryParse(_ageCtrl.text) ?? 0,
        areaSqft: double.tryParse(_areaCtrl.text) ?? 1000.0,
        maintenanceCharges: _maintenanceCtrl.text,
        amenities: _selectedAmenities,
        images: existingProp?.images ?? [],
      );

      if (isEditing) {
        ref.read(propertyProvider.notifier).updateProperty(newProp);
      } else {
        ref.read(propertyProvider.notifier).addProperty(newProp);
      }

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Property Updated Successfully!' : 'Property Added Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Property' : 'Add Property'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionCard(
              title: 'Basic Details',
              icon: Icons.info_outline,
              child: Column(
                children: [
                  _buildTextField(_titleCtrl, 'Property Title', 'e.g. 3 BHK Luxury Apartment', Icons.title),
                  const Gap(16),
                  _buildTextField(_locationCtrl, 'Location', 'e.g. Bandra West, Mumbai', Icons.location_on_outlined),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_priceCtrl, 'Price', 'e.g. ₹3.5 Cr', Icons.currency_rupee)),
                      const Gap(16),
                      Expanded(child: _buildTextField(_areaCtrl, 'Area (sqft)', 'e.g. 1500', Icons.square_foot, isNumber: true)),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(24),

            _buildSectionCard(
              title: 'Categorization',
              icon: Icons.category_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown('Listing Type', _type, ['Sale', 'Rent'], Icons.real_estate_agent_outlined, (v) => setState(() => _type = v!)),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _buildDropdown('Property Type', _propertyType, ['Apartment', 'Villa', 'Office', 'Plot'], Icons.apartment_outlined, (v) => setState(() => _propertyType = v!)),
                      ),
                    ],
                  ),
                  const Gap(16),
                  _buildTextField(_bhkCtrl, 'BHK Configuration', 'e.g. 3 BHK', Icons.bed_outlined),
                ],
              ),
            ),
            const Gap(24),

            _buildSectionCard(
              title: 'Visibility',
              icon: Icons.visibility_outlined,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Make Property ${_isPublic ? 'Public' : 'Private'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Gap(4),
                          Text(
                            _isPublic ? 'Visible to other agencies for collaboration.' : 'Only visible to brokers within your agency.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.primaryBlue,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            _buildSectionCard(
              title: 'Specifications',
              icon: Icons.list_alt_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_bathroomsCtrl, 'Bathrooms', 'e.g. 2', Icons.bathtub_outlined, isNumber: true)),
                      const Gap(16),
                      Expanded(child: _buildTextField(_balconyCtrl, 'Balconies', 'e.g. 1', Icons.balcony_outlined, isNumber: true)),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_parkingCtrl, 'Parking Spots', 'e.g. 1', Icons.local_parking_outlined, isNumber: true)),
                      const Gap(16),
                      Expanded(child: _buildTextField(_ageCtrl, 'Age (Years)', 'e.g. 5', Icons.hourglass_bottom_outlined, isNumber: true)),
                    ],
                  ),
                  const Gap(16),
                  _buildDropdown('Furnished Status', _furnishedStatus, ['Unfurnished', 'Semi-Furnished', 'Fully Furnished'], Icons.chair_outlined, (v) => setState(() => _furnishedStatus = v!)),
                ],
              ),
            ),
            const Gap(24),

            _buildSectionCard(
              title: 'Financials',
              icon: Icons.account_balance_wallet_outlined,
              child: _buildTextField(_maintenanceCtrl, 'Maintenance Charges', 'e.g. ₹5,000/mo', Icons.build_circle_outlined),
            ),
            const Gap(24),

            _buildSectionCard(
              title: 'Amenities',
              icon: Icons.star_outline,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryBlue,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.border),
                  );
                }).toList(),
              ),
            ),
            const Gap(48),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: _saveProperty,
                child: Text(isEditing ? 'Save Changes' : 'Add Property', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const Gap(8),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const Gap(20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (isNumber) {
          final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
          if (parsed == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.iconColor, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        errorStyle: const TextStyle(color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.iconColor, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      ),
    );
  }
}
