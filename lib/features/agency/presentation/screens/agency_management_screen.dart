import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/agency_model.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/network/api_service.dart';

class AgencyManagementScreen extends ConsumerStatefulWidget {
  const AgencyManagementScreen({super.key});

  @override
  ConsumerState<AgencyManagementScreen> createState() => _AgencyManagementScreenState();
}

class _AgencyManagementScreenState extends ConsumerState<AgencyManagementScreen> {
  String _selectedFilter = 'Active';
  bool _isLoadingBrokers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveBrokersFromBackend();
    });
  }

  /// Fetches live agency brokers directly for the logged-in user's real agency ID
  Future<void> _fetchLiveBrokersFromBackend() async {
    if (!mounted) return;

    setState(() {
      _isLoadingBrokers = true;
    });

    try {
      await AuthStorageService.init();
      final userData = AuthStorageService.getUserData();
      final userAgency = userData?['agency'] as Map<String, dynamic>?;
      final userAgencyId = userData?['agencyId'] ?? userData?['agency_id'] ?? userAgency?['id'];
      final agencyName = userAgency?['name'] ?? userData?['agencyName'] ?? userData?['agency_name'] ?? 'My Agency';
      final reraNumber = userAgency?['reraNumber'] ?? 'RERA Registered';
      final agencyEmail = userAgency?['email'] ?? userData?['email'] ?? '';
      final agencyAddress = userAgency?['address'] ?? 'Primary Office Location';

      // Update top Agency profile card in state to match user's real agency profile
      ref.read(agencyProvider.notifier).updateAgencyDetails(
            agencyName,
            reraNumber,
            agencyEmail,
            agencyAddress,
          );

      final endpoint = userAgencyId != null ? '/brokers?agencyId=$userAgencyId' : '/brokers';
      final res = await ApiService.get(endpoint);
      if (res['success'] == true && res['data'] != null) {
        final rawList = res['data'] as List<dynamic>;
        final fetchedBrokers = rawList.map((item) {
          final m = item as Map<String, dynamic>;
          final roleStr = m['role'] == 'agency_admin' ? 'Agency Admin' : 'Broker / Agent';
          final isAct = m['status'] == 'Active';

          return BrokerModel(
            id: m['id']?.toString() ?? 'b0',
            name: m['name']?.toString() ?? 'Broker',
            email: m['email']?.toString() ?? '',
            phone: m['phone']?.toString() ?? '',
            role: roleStr,
            isActive: isAct,
          );
        }).toList();

        // Update Riverpod State cleanly with only this agency's real brokers
        ref.read(agencyProvider.notifier).setBrokers(fetchedBrokers);
      } else {
        ref.read(agencyProvider.notifier).setBrokers([]);
      }
    } catch (e) {
      debugPrint('Error fetching backend brokers: $e');
      ref.read(agencyProvider.notifier).setBrokers([]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBrokers = false;
        });
      }
    }
  }

  /// Onboards or Edits a broker in backend PostgreSQL database for the logged-in agency
  void _showBrokerDialog({BrokerModel? broker}) {
    final isEditing = broker != null;
    final nameCtrl = TextEditingController(text: broker?.name ?? '');
    final emailCtrl = TextEditingController(text: broker?.email ?? '');
    final phoneCtrl = TextEditingController(text: broker?.phone ?? '');
    final passwordCtrl = TextEditingController(text: isEditing ? '' : 'broker123');
    bool obscurePassword = true;
    String selectedRole = broker?.role ?? 'Broker / Agent';
    bool isSaving = false;

    final userData = AuthStorageService.getUserData();
    final userAgency = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userData?['agency_id'] ?? userAgency?['id'];

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
                        Text(isEditing ? 'Edit Broker Details' : 'Onboard Agency Broker', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Gap(16),
                    _buildPremiumTextField(nameCtrl, 'Broker Full Name *', Icons.person_outline),
                    const Gap(16),
                    _buildPremiumTextField(emailCtrl, 'Email Address *', Icons.email_outlined),
                    const Gap(16),
                    _buildPremiumTextField(phoneCtrl, 'Phone Number', Icons.phone_outlined),
                    const Gap(16),
                    if (!isEditing) ...[
                      TextField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Login Password *',
                          hintText: 'e.g. broker123',
                          helperText: 'Broker will use this password to sign into the app',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.iconColor,
                            ),
                            onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const Gap(16),
                    ],
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
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const Gap(32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                                setModalState(() {
                                  isSaving = true;
                                });

                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                final backendRole = selectedRole == 'Agency Admin' ? 'agency_admin' : 'broker';
                                
                                if (isEditing) {
                                  // Update existing broker via PUT /brokers/:id
                                  final res = await ApiService.put('/brokers/${broker.id}', {
                                    'name': nameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'role': backendRole,
                                  });

                                  if (res['success'] == true) {
                                    ref.read(agencyProvider.notifier).updateBroker(
                                          broker.id,
                                          nameCtrl.text.trim(),
                                          emailCtrl.text.trim(),
                                          phoneCtrl.text.trim(),
                                          selectedRole,
                                        );

                                    navigator.pop();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Broker ${nameCtrl.text} updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    await _fetchLiveBrokersFromBackend();
                                  } else {
                                    setModalState(() {
                                      isSaving = false;
                                    });
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? 'Failed to update broker'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } else {
                                  // Onboard new broker via POST /brokers
                                  final chosenPassword = passwordCtrl.text.trim().isNotEmpty ? passwordCtrl.text.trim() : 'broker123';
                                  final parsedAgencyId = userAgencyId != null ? int.tryParse(userAgencyId.toString()) : null;

                                  final payload = <String, dynamic>{
                                    'name': nameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'role': backendRole,
                                    'password': chosenPassword,
                                  };
                                  if (parsedAgencyId != null) {
                                    payload['agencyId'] = parsedAgencyId;
                                  }

                                  final res = await ApiService.post('/brokers', payload);

                                  if (res['success'] == true) {
                                    final created = res['data'] as Map<String, dynamic>?;
                                    ref.read(agencyProvider.notifier).addBroker(
                                          nameCtrl.text.trim(),
                                          emailCtrl.text.trim(),
                                          phoneCtrl.text.trim(),
                                          selectedRole,
                                          id: created?['id']?.toString(),
                                        );

                                    navigator.pop();

                                    // Refresh live list immediately from backend
                                    await _fetchLiveBrokersFromBackend();

                                    if (mounted) {
                                      _showCredentialDialog(
                                        name: nameCtrl.text.trim(),
                                        email: emailCtrl.text.trim(),
                                        password: chosenPassword,
                                        role: selectedRole,
                                      );
                                    }
                                  } else {
                                    setModalState(() {
                                      isSaving = false;
                                    });
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? 'Failed to onboard broker'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Onboard Broker to Agency', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  /// Displays broker credentials with copy button so admin can share them
  void _showCredentialDialog({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            Gap(8),
            Text('Broker Onboarded!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share these credentials with $name so they can sign into PropConnect:',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Gap(14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Email:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.copy, size: 16, color: AppColors.primaryBlue),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied!'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Password:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.copy, size: 16, color: AppColors.primaryBlue),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: password));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password copied!'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(password, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Text('Role: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      Text(role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_all, size: 16),
            label: const Text('Copy All'),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'PropConnect Login Credentials:\nEmail: $email\nPassword: $password\nRole: $role',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All credentials copied to clipboard!'), duration: Duration(seconds: 2)),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        title: const Text('Agency & Broker Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.domain_add_rounded, color: AppColors.primaryBlue),
            onPressed: () => context.push('/create-agency'),
            tooltip: 'Register new agency profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _fetchLiveBrokersFromBackend,
            tooltip: 'Refresh live backend brokers',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primaryBlue),
            onPressed: () => _showBrokerDialog(),
            tooltip: 'Onboard new broker',
          ),
        ],
      ),
      body: _isLoadingBrokers
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchLiveBrokersFromBackend,
              color: AppColors.primaryBlue,
              child: ListView(
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
                              child: Text('Active Brokers (${activeBrokers.length})', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFilter == 'Active' ? AppColors.primaryBlue : AppColors.textSecondary)),
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
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
                            const Gap(12),
                            Text('No $_selectedFilter Brokers in ${agency.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const Gap(6),
                            const Text('Onboard a new broker to build your agency team.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const Gap(16),
                            ElevatedButton.icon(
                              onPressed: () => _showBrokerDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                              label: const Text('Onboard First Broker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildBrokerList(displayBrokers),
                ],
              ),
            ),
    );
  }

  Widget _buildAgencyProfile(AgencyModel agency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded, color: AppColors.primaryBlue, size: 28),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            agency.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                      'RERA: ${agency.reraNumber.isNotEmpty ? agency.reraNumber : 'Unregistered'}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (agency.email.isNotEmpty)
                      Text(
                        agency.email,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                onPressed: () => _showEditAgencyDialog(agency),
                tooltip: 'Edit Agency Details',
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/create-agency'),
                  icon: const Icon(Icons.add_business_rounded, size: 16, color: AppColors.primaryBlue),
                  label: const Text(
                    'Register New Agency Profile',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
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
            subtitle: Text('${broker.role} • ${broker.email.isNotEmpty ? broker.email : broker.phone}', style: const TextStyle(fontSize: 12)),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final messenger = ScaffoldMessenger.of(context);
                if (value == 'deactivate') {
                  await ApiService.patch('/brokers/${broker.id}/status', {'status': 'Suspended'});
                  ref.read(agencyProvider.notifier).deactivateBroker(broker.id);
                  messenger.showSnackBar(SnackBar(content: Text('${broker.name} suspended')));
                } else if (value == 'reactivate') {
                  await ApiService.patch('/brokers/${broker.id}/status', {'status': 'Active'});
                  ref.read(agencyProvider.notifier).reactivateBroker(broker.id);
                  messenger.showSnackBar(SnackBar(content: Text('${broker.name} reactivated')));
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
