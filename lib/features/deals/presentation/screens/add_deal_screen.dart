import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class AddDealScreen extends ConsumerStatefulWidget {
  const AddDealScreen({super.key});

  @override
  ConsumerState<AddDealScreen> createState() => _AddDealScreenState();
}

class _AddDealScreenState extends ConsumerState<AddDealScreen> {
  final _formKey = GlobalKey<FormState>();
  
  PropertyModel? _selectedProperty;
  final _brokerCtrl = TextEditingController();
  final _agencyCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _clientReqCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void dispose() {
    _brokerCtrl.dispose();
    _agencyCtrl.dispose();
    _amountCtrl.dispose();
    _clientReqCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _submitDeal() {
    if (_formKey.currentState!.validate() && _selectedProperty != null) {
      final newId = 'D-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      final deal = DealModel(
        id: newId,
        propertyId: _selectedProperty!.id,
        propertyName: _selectedProperty!.title,
        partnerBroker: _brokerCtrl.text.trim(),
        partnerAgency: _agencyCtrl.text.trim(),
        status: 'Lead Assigned',
        amount: _amountCtrl.text.trim(),
        isRequest: false,
        clientRequirement: _clientReqCtrl.text.trim().isEmpty ? null : _clientReqCtrl.text.trim(),
        remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      ref.read(dealProvider.notifier).addDeal(deal);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deal added successfully at "Lead Assigned" stage')),
      );
      context.pop();
    } else if (_selectedProperty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a property first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = AuthStorageService.getUserData();
    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final userAgency = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';

    // Only show available properties that the agency owns
    final properties = ref.watch(propertyProvider).where((p) {
      if (p.status != 'Available') return false;
      if (userAgencyId != null && p.agencyId != null && p.agencyId.toString() == userAgencyId.toString()) return true;
      if (userAgency.isNotEmpty && p.agencyName.toLowerCase().trim() == userAgency.toLowerCase().trim()) return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add New Deal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Property Details'),
              const Gap(16),
              DropdownButtonFormField<PropertyModel>(
                decoration: InputDecoration(
                  labelText: 'Select Property',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                initialValue: _selectedProperty,
                items: properties.map((prop) => DropdownMenuItem(
                  value: prop,
                  child: Text('${prop.title} (${prop.id})'),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProperty = val;
                  });
                },
                validator: (val) => val == null ? 'Property is required' : null,
              ),
              const Gap(32),
              
              _buildSectionTitle('Partner Broker Info'),
              const Gap(16),
              _buildTextField(
                controller: _brokerCtrl,
                label: 'Partner Broker Name',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              _buildTextField(
                controller: _agencyCtrl,
                label: 'Partner Agency Name',
                icon: Icons.business_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const Gap(32),

              _buildSectionTitle('Deal Financials'),
              const Gap(16),
              _buildTextField(
                controller: _amountCtrl,
                label: 'Negotiated Amount (e.g. ₹1.2 Cr)',
                icon: Icons.monetization_on_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const Gap(32),

              _buildSectionTitle('Additional Info (Optional)'),
              const Gap(16),
              _buildTextField(
                controller: _clientReqCtrl,
                label: 'Client Requirements',
                icon: Icons.list_alt_outlined,
                maxLines: 3,
              ),
              const Gap(16),
              _buildTextField(
                controller: _remarksCtrl,
                label: 'Remarks',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
              const Gap(40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitDeal,
                child: const Text('Create Deal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.iconColor) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
      ),
      validator: validator,
    );
  }
}
