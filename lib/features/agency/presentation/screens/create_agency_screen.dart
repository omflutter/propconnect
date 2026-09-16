import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/widgets/live_location_select.dart';
import 'package:propconnect/core/widgets/agency_celebration_dialog.dart';

class CreateAgencyScreen extends ConsumerStatefulWidget {
  const CreateAgencyScreen({super.key});

  @override
  ConsumerState<CreateAgencyScreen> createState() => _CreateAgencyScreenState();
}

class _CreateAgencyScreenState extends ConsumerState<CreateAgencyScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _agencyNameCtrl;
  late TextEditingController _reraNumberCtrl;
  String _operatingLocation = 'Mumbai (MMR), Maharashtra';
  String _corporateAddress = '';

  late TextEditingController _adminNameCtrl;
  late TextEditingController _adminEmailCtrl;
  late TextEditingController _adminPhoneCtrl;
  final _passwordCtrl = TextEditingController(text: 'agency123');

  String _selectedTier = 'Pro (₹5,999/mo)';
  late TextEditingController _userQuotaCtrl;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  final List<String> _tiers = [
    'Basic (₹2,999/mo)',
    'Pro (₹5,999/mo)',
    'Enterprise (₹14,999/mo)',
  ];

  @override
  void initState() {
    super.initState();
    final userData = AuthStorageService.getUserData();
    final userAgency = userData?['agency'] as Map<String, dynamic>?;

    final existingName = (userAgency?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';
    final existingRera = (userAgency?['reraNumber'] as String?) ?? '';
    final existingLoc = (userAgency?['location'] as String?) ?? 'Mumbai (MMR), Maharashtra';
    final existingAddr = (userAgency?['address'] as String?) ?? '';
    final userName = (userData?['name'] as String?) ?? '';
    final userEmail = (userData?['email'] as String?) ?? '';
    final userPhone = (userData?['phone'] as String?) ?? '';

    _agencyNameCtrl = TextEditingController(text: existingName.isNotEmpty && existingName != 'Sunrise Properties' ? existingName : '');
    _reraNumberCtrl = TextEditingController(text: existingRera);
    _operatingLocation = existingLoc.isNotEmpty ? existingLoc : 'Mumbai (MMR), Maharashtra';
    _corporateAddress = existingAddr;
    _adminNameCtrl = TextEditingController(text: userName);
    _adminEmailCtrl = TextEditingController(text: userEmail);
    _adminPhoneCtrl = TextEditingController(text: userPhone);
    _userQuotaCtrl = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _agencyNameCtrl.dispose();
    _reraNumberCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    _userQuotaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegisterAgency() async {
    if (!_formKey.currentState!.validate()) return;

    if (_operatingLocation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an Operating City / Location'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final quota = int.tryParse(_userQuotaCtrl.text.trim()) ?? 10;

      final payload = {
        'name': _agencyNameCtrl.text.trim(),
        'reraNumber': _reraNumberCtrl.text.trim(),
        'location': _operatingLocation.trim(),
        'address': _corporateAddress.trim(),
        'adminName': _adminNameCtrl.text.trim(),
        'adminEmail': _adminEmailCtrl.text.trim(),
        'adminPhone': _adminPhoneCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'subscriptionTier': _selectedTier,
        'userQuota': quota,
      };

      final res = await ApiService.post('/agencies/create-profile', payload);

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        final agencyData = res['data']['agency'] as Map<String, dynamic>? ?? {};
        final userData = res['data']['user'] as Map<String, dynamic>? ?? {};
        final token = (res['data']['token'] as String?) ?? AuthStorageService.getAuthToken() ?? '';

        // Update local session
        await AuthStorageService.saveSession(
          token: token,
          user: userData,
          role: UserRole.agencyAdmin,
        );

        if (!mounted) return;

        // Update Riverpod state
        ref.read(userRoleProvider.notifier).setRole(UserRole.agencyAdmin);
        ref.read(agencyProvider.notifier).updateAgencyDetails(
              agencyData['name'] ?? _agencyNameCtrl.text.trim(),
              agencyData['reraNumber'] ?? _reraNumberCtrl.text.trim(),
              agencyData['adminEmail'] ?? _adminEmailCtrl.text.trim(),
              agencyData['address'] ?? _corporateAddress.trim(),
            );

        // Show Success Celebration Dialog
        AgencyCelebrationDialog.show(
          context: context,
          agencyName: agencyData['name'] ?? _agencyNameCtrl.text.trim(),
          agencyCode: agencyData['agencyCode'] ?? 'AG-00X',
          adminName: userData['name'] ?? _adminNameCtrl.text.trim(),
          adminEmail: agencyData['adminEmail'] ?? _adminEmailCtrl.text.trim(),
          location: agencyData['location'] ?? _operatingLocation,
          subscriptionTier: _selectedTier,
          userQuota: quota,
          reraNumber: agencyData['reraNumber'] ?? _reraNumberCtrl.text.trim(),
          targetRoute: AppRouter.agencyManagement,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to register agency profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering agency: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Register New Agency (India)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Hero Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_rounded, color: Colors.white, size: 28),
                          ),
                          const Gap(14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agency Profile & Brokerage Hub',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Gap(3),
                                Text(
                                  'Manage team brokers, centralize property inventory, and verify your brokerage.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),

                    // Section 1: Agency Details
                    _buildSectionCard(
                      title: 'Agency Details',
                      icon: Icons.apartment_rounded,
                      children: [
                        // Agency Name *
                        _buildInputField(
                          controller: _agencyNameCtrl,
                          label: 'Agency Name',
                          hint: 'e.g. Skyline Realty',
                          icon: Icons.domain_rounded,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Agency Name is required';
                            }
                            return null;
                          },
                        ),
                        const Gap(14),

                        // RERA Registration Number
                        _buildInputField(
                          controller: _reraNumberCtrl,
                          label: 'RERA Registration Number',
                          hint: 'e.g. PRM/KA/RERA/...',
                          icon: Icons.verified_user_outlined,
                        ),
                        const Gap(14),

                        // Operating Cities / Location * (Searchable Live Location)
                        LiveLocationSelect(
                          value: _operatingLocation,
                          isRequired: true,
                          label: 'Operating Cities / Location',
                          placeholder: 'Search live real-world city or locality...',
                          searchPlaceholder: 'Type city, locality, district or PIN code...',
                          onChanged: (val) {
                            setState(() {
                              _operatingLocation = val;
                            });
                          },
                        ),
                        const Gap(14),

                        // Corporate Address (Searchable Live Location / Street)
                        LiveLocationSelect(
                          value: _corporateAddress,
                          isRequired: false,
                          label: 'Corporate Address',
                          placeholder: 'Search live street, area, building or PIN code...',
                          searchPlaceholder: 'Search street address, area, landmark or PIN...',
                          onChanged: (val) {
                            setState(() {
                              _corporateAddress = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Section 2: Admin Details
                    _buildSectionCard(
                      title: 'Admin Details',
                      icon: Icons.admin_panel_settings_rounded,
                      children: [
                        // Admin Full Name *
                        _buildInputField(
                          controller: _adminNameCtrl,
                          label: 'Admin Full Name',
                          hint: 'First Last',
                          icon: Icons.badge_outlined,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Admin Full Name is required';
                            }
                            return null;
                          },
                        ),
                        const Gap(14),

                        // Phone Number
                        _buildInputField(
                          controller: _adminPhoneCtrl,
                          label: 'Phone Number',
                          hint: '+91 98765 43210',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          isRequired: false,
                        ),
                        const Gap(14),

                        // Admin Email Address *
                        _buildInputField(
                          controller: _adminEmailCtrl,
                          label: 'Admin Email Address',
                          hint: 'admin@agency.in',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Admin Email Address is required';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const Gap(14),

                        // Admin Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Password (Default: agency123)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const Gap(6),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: 'agency123',
                                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Section 3: Platform Configuration
                    _buildSectionCard(
                      title: 'Platform Configuration',
                      icon: Icons.tune_rounded,
                      children: [
                        // Subscription Tier
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Subscription Tier',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const Gap(6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTier,
                              items: _tiers.map((tier) {
                                return DropdownMenuItem(value: tier, child: Text(tier));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedTier = val);
                                }
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                prefixIcon: const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryBlue, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),

                        // Initial User Quota
                        _buildInputField(
                          controller: _userQuotaCtrl,
                          label: 'Initial User Quota',
                          hint: '10',
                          icon: Icons.groups_rounded,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter user quota';
                            }
                            final num = int.tryParse(value.trim());
                            if (num == null || num <= 0) {
                              return 'Quota must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const Gap(28),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _handleRegisterAgency,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Register Agency',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const Gap(24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryBlue),
              ),
              const Gap(10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const Gap(16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
        const Gap(6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
