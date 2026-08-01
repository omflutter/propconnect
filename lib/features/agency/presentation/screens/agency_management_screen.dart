import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/agency_model.dart';
import 'package:propconnect/core/providers/agency_provider.dart';

class AgencyManagementScreen extends ConsumerStatefulWidget {
  const AgencyManagementScreen({super.key});

  @override
  ConsumerState<AgencyManagementScreen> createState() => _AgencyManagementScreenState();
}

class _AgencyManagementScreenState extends ConsumerState<AgencyManagementScreen> {
  String _selectedFilter = 'Active'; // 'Active' or 'Deactivated'

  void _showBrokerDialog({BrokerModel? broker}) {
    final isEditing = broker != null;
    final nameCtrl = TextEditingController(text: broker?.name ?? '');
    final emailCtrl = TextEditingController(text: broker?.email ?? '');
    final phoneCtrl = TextEditingController(text: broker?.phone ?? '');
    String selectedRole = broker?.role ?? 'Broker / Agent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        Text(isEditing ? 'Edit Broker Details' : 'Add New Broker', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Gap(16),
                    _buildPremiumTextField(nameCtrl, 'Full Name', Icons.person_outline),
                    const Gap(16),
                    _buildPremiumTextField(emailCtrl, 'Email Address', Icons.email_outlined),
                    const Gap(16),
                    _buildPremiumTextField(phoneCtrl, 'Phone Number', Icons.phone_outlined),
                    const Gap(16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.iconColor),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['Agency Admin', 'Broker / Agent'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedRole = val);
                      },
                    ),
                    const Gap(32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                          if (isEditing) {
                            ref.read(agencyProvider.notifier).updateBroker(
                                  broker.id,
                                  nameCtrl.text,
                                  emailCtrl.text,
                                  phoneCtrl.text,
                                  selectedRole,
                                );
                          } else {
                            ref.read(agencyProvider.notifier).addBroker(
                                  nameCtrl.text,
                                  emailCtrl.text,
                                  phoneCtrl.text,
                                  selectedRole,
                                );
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Send Invite', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const Gap(32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditAgencyDialog(AgencyModel agency) {
    final nameCtrl = TextEditingController(text: agency.name);
    final reraCtrl = TextEditingController(text: agency.reraNumber);
    final emailCtrl = TextEditingController(text: agency.email);
    final addressCtrl = TextEditingController(text: agency.address);

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
                    const Text('Edit Agency Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(16),
                _buildPremiumTextField(nameCtrl, 'Agency Name', Icons.business),
                const Gap(16),
                _buildPremiumTextField(reraCtrl, 'RERA Number', Icons.verified_user_outlined),
                const Gap(16),
                _buildPremiumTextField(emailCtrl, 'Contact Email', Icons.email_outlined),
                const Gap(16),
                _buildPremiumTextField(addressCtrl, 'Address', Icons.location_on_outlined),
                const Gap(32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(agencyProvider.notifier).updateAgencyDetails(
                          nameCtrl.text,
                          reraCtrl.text,
                          emailCtrl.text,
                          addressCtrl.text,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const Gap(32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.iconColor),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agency = ref.watch(agencyProvider);
    final activeBrokers = agency.brokers.where((b) => b.isActive).toList();
    final deactivatedBrokers = agency.brokers.where((b) => !b.isActive).toList();
    
    final displayBrokers = _selectedFilter == 'Active' ? activeBrokers : deactivatedBrokers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agency & Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primaryBlue),
            onPressed: () => _showBrokerDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAgencyProfile(agency),
          const Gap(24),
          
          // Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = 'Active'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 'Active' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedFilter == 'Active' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                      ),
                      child: Text('Active (${activeBrokers.length})', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFilter == 'Active' ? AppColors.primaryBlue : AppColors.textSecondary)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = 'Deactivated'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 'Deactivated' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedFilter == 'Deactivated' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                      ),
                      child: Text('Deactivated (${deactivatedBrokers.length})', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFilter == 'Deactivated' ? Colors.red : AppColors.textSecondary)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Gap(16),
          if (displayBrokers.isEmpty)
             Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('No $_selectedFilter Brokers', style: const TextStyle(color: AppColors.textSecondary))),
            )
          else
            _buildBrokerList(displayBrokers),
        ],
      ),
    );
  }

  Widget _buildAgencyProfile(AgencyModel agency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, color: AppColors.primaryBlue, size: 30),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agency.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('RERA: ${agency.reraNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
            onPressed: () => _showEditAgencyDialog(agency),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerList(List<BrokerModel> brokers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brokers.length,
      separatorBuilder: (context, index) => const Gap(8),
      itemBuilder: (context, index) {
        final broker = brokers[index];
        final isAdmin = broker.role == 'Agency Admin';
        
        return Opacity(
          opacity: broker.isActive ? 1.0 : 0.6,
          child: ListTile(
            onTap: () {
              context.push('/broker-details/${broker.id}');
            },
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            leading: CircleAvatar(
              backgroundColor: isAdmin ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              child: Text(broker.name.isNotEmpty ? broker.name.substring(0, 1).toUpperCase() : 'U', style: TextStyle(color: isAdmin ? AppColors.primaryBlue : AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ),
            title: Text(broker.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${broker.role} • ${broker.phone}', style: const TextStyle(fontSize: 12)),
            trailing: isAdmin 
              ? null 
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'deactivate') {
                      ref.read(agencyProvider.notifier).deactivateBroker(broker.id);
                    } else if (value == 'reactivate') {
                      ref.read(agencyProvider.notifier).reactivateBroker(broker.id);
                    } else if (value == 'edit') {
                      _showBrokerDialog(broker: broker);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 18), Gap(8), Text('Edit Details')]),
                      ),
                      if (broker.isActive)
                        const PopupMenuItem<String>(
                          value: 'deactivate',
                          child: Row(children: [Icon(Icons.person_off, size: 18, color: Colors.red), Gap(8), Text('Deactivate', style: TextStyle(color: Colors.red))]),
                        )
                      else
                        const PopupMenuItem<String>(
                          value: 'reactivate',
                          child: Row(children: [Icon(Icons.person_add, size: 18, color: Colors.green), Gap(8), Text('Reactivate', style: TextStyle(color: Colors.green))]),
                        ),
                    ];
                  },
                ),
          ),
        );
      },
    );
  }
}
