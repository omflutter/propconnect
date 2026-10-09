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
  bool _isCoBrokered = true;
  String _dealType = 'Outright Sale';
  String _initialStage = 'Lead Assigned';

  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _brokerCtrl = TextEditingController();
  final _agencyCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _clientReqCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientEmailCtrl.dispose();
    _brokerCtrl.dispose();
    _agencyCtrl.dispose();
    _amountCtrl.dispose();
    _clientReqCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _submitDeal() async {
    if (_formKey.currentState!.validate() && _selectedProperty != null) {
      setState(() => _isSubmitting = true);

      final newId = 'DL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final userData = AuthStorageService.getUserData();
      final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
      final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
      final userAgencyName = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? 'Prime Properties';
      final currentUserId = userData?['id'];
      final currentUserName = (userData?['name'] as String?) ?? 'Agent';

      final cleanAmount = _amountCtrl.text.trim();
      final rawValue = double.tryParse(cleanAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      final deal = DealModel(
        id: newId,
        dealCode: newId,
        propertyId: _selectedProperty!.id,
        propertyName: _selectedProperty!.title,
        agencyAId: _selectedProperty!.agencyId ?? (userAgencyId != null ? int.tryParse(userAgencyId.toString()) : 1),
        agencyAName: _selectedProperty!.agencyName.isNotEmpty ? _selectedProperty!.agencyName : userAgencyName,
        brokerAId: _selectedProperty!.brokerId,
        brokerAName: _selectedProperty!.brokerName.isNotEmpty ? _selectedProperty!.brokerName : currentUserName,
        agencyBId: _isCoBrokered ? null : (userAgencyId != null ? int.tryParse(userAgencyId.toString()) : 1),
        agencyBName: _isCoBrokered ? _agencyCtrl.text.trim() : userAgencyName,
        brokerBId: _isCoBrokered ? null : (currentUserId != null ? int.tryParse(currentUserId.toString()) : 2),
        brokerBName: _isCoBrokered ? _brokerCtrl.text.trim() : currentUserName,
        partnerBroker: _isCoBrokered ? _brokerCtrl.text.trim() : currentUserName,
        partnerAgency: _isCoBrokered ? _agencyCtrl.text.trim() : userAgencyName,
        status: _initialStage,
        amount: cleanAmount,
        dealValue: rawValue,
        clientName: _clientNameCtrl.text.trim().isNotEmpty ? _clientNameCtrl.text.trim() : 'Direct Buyer Lead',
        clientPhone: _clientPhoneCtrl.text.trim().isNotEmpty ? _clientPhoneCtrl.text.trim() : null,
        clientEmail: _clientEmailCtrl.text.trim().isNotEmpty ? _clientEmailCtrl.text.trim() : null,
        clientRequirement: _clientReqCtrl.text.trim().isNotEmpty ? _clientReqCtrl.text.trim() : null,
        expectedBudget: cleanAmount,
        remarks: _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : 'Deal initiated at $_initialStage stage',
        createdAt: DateTime.now(),
        auditHistory: [
          DealAuditLog(
            status: _initialStage,
            timestamp: DateTime.now(),
            updatedBy: currentUserName,
            notes: 'Deal created in pipeline (${_isCoBrokered ? 'Co-Brokered Deal' : 'In-House Deal'})',
          ),
        ],
      );

      await ref.read(dealProvider.notifier).addDeal(deal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deal $newId created successfully at "$_initialStage" stage!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        context.pop();
      }
    } else if (_selectedProperty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available property first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = AuthStorageService.getUserData();
    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final userAgency = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';

    // Filter available accessible inventory
    final properties = ref.watch(accessiblePropertiesProvider).where((p) {
      if (p.status != 'Available') return false;
      if (userAgencyId != null && p.agencyId != null && p.agencyId.toString() == userAgencyId.toString()) return true;
      if (userAgency.isNotEmpty && p.agencyName.toLowerCase().trim() == userAgency.toLowerCase().trim()) return true;
      return true; // fallback to allow creating deals on available inventory
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add New Deal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Deal Classification Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Deal Structure & Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Gap(10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Co-Brokered Deal')),
                            selected: _isCoBrokered,
                            selectedColor: AppColors.primaryBlue,
                            labelStyle: TextStyle(
                              color: _isCoBrokered ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _isCoBrokered = true),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('In-House Deal')),
                            selected: !_isCoBrokered,
                            selectedColor: AppColors.primaryBlue,
                            labelStyle: TextStyle(
                              color: !_isCoBrokered ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _isCoBrokered = false),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      children: ['Outright Sale', 'Commercial Lease', 'Residential Rental'].map((opt) {
                        final isSel = _dealType == opt;
                        return ChoiceChip(
                          label: Text(opt),
                          selected: isSel,
                          selectedColor: AppColors.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontSize: 11.5,
                          ),
                          onSelected: (_) => setState(() => _dealType = opt),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Property Selector Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Target Property *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Gap(10),
                    DropdownButtonFormField<PropertyModel>(
                      decoration: InputDecoration(
                        labelText: 'Select Inventory Property',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      initialValue: _selectedProperty,
                      items: properties.map((prop) {
                        return DropdownMenuItem(
                          value: prop,
                          child: Text('${prop.title} (${prop.price})', style: const TextStyle(fontSize: 13.5)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedProperty = val;
                          if (val != null && _amountCtrl.text.isEmpty) {
                            _amountCtrl.text = val.price;
                          }
                        });
                      },
                      validator: (val) => val == null ? 'Please select a property' : null,
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Partner Broker (if Co-Brokered)
              if (_isCoBrokered) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Partner Broker & Agency *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Gap(10),
                      TextFormField(
                        controller: _brokerCtrl,
                        decoration: InputDecoration(
                          labelText: 'Partner Broker Name',
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryBlue, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        validator: (v) => _isCoBrokered && (v == null || v.trim().isEmpty) ? 'Broker name is required' : null,
                      ),
                      const Gap(12),
                      TextFormField(
                        controller: _agencyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Partner Agency Name',
                          prefixIcon: const Icon(Icons.business_outlined, color: AppColors.primaryBlue, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        validator: (v) => _isCoBrokered && (v == null || v.trim().isEmpty) ? 'Agency name is required' : null,
                      ),
                    ],
                  ),
                ),
                const Gap(16),
              ],

              // Client Details Card (with Privacy Notice)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('4. Client Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                          child: const Text('🔒 Privacy Protected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        ),
                      ],
                    ),
                    const Gap(10),
                    TextFormField(
                      controller: _clientNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Client / Buyer Name',
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primaryBlue, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: _clientPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Client Phone (Confidential)',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryBlue, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: _clientEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Client Email (Confidential)',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryBlue, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Deal Financials & Initial Milestone Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('5. Deal Financials & Initial Milestone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Gap(10),
                    TextFormField(
                      controller: _amountCtrl,
                      decoration: InputDecoration(
                        labelText: 'Negotiated Deal Value *',
                        hintText: 'e.g. ₹2.5 Cr',
                        prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primaryBlue, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Deal value is required' : null,
                    ),
                    const Gap(12),
                    DropdownButtonFormField<String>(
                      initialValue: _initialStage,
                      decoration: InputDecoration(
                        labelText: 'Initial Transaction Milestone (PRD Sec 4.4)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: DealModel.prdMilestones.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13.5)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _initialStage = val);
                      },
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Notes & Requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('6. Client Requirements & Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Gap(10),
                    TextFormField(
                      controller: _clientReqCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Client Requirements / Terms',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: _remarksCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Internal Deal Notes',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : _submitDeal,
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_task_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Creating Deal...' : 'Create Deal in Pipeline',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}
