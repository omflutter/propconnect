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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Agency Details
  final _agencyNameCtrl = TextEditingController();
  final _reraNumberCtrl = TextEditingController();
  String _operatingLocation = 'Mumbai (MMR), Maharashtra';
  String _corporateAddress = '';

  // Admin Details
  final _adminNameCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Platform Configuration
  String _subscriptionTier = 'Pro (₹5,999/mo)';
  final _userQuotaCtrl = TextEditingController(text: '10');

  final List<String> _tiers = [
    'Basic (₹2,999/mo)',
    'Pro (₹5,999/mo)',
    'Enterprise (₹14,999/mo)',
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _agencyNameCtrl.dispose();
    _reraNumberCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _adminEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _userQuotaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_operatingLocation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an Operating City / Location'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
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
        'subscriptionTier': _subscriptionTier,
        'userQuota': quota,
      };

      final response = await ApiService.post('/auth/register', payload);

      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final token = (data['token'] as String?) ?? '';
        final user = Map<String, dynamic>.from(data['user'] as Map? ?? {});
        final agency = Map<String, dynamic>.from(data['agency'] as Map? ?? {});

        if (user['agency'] == null && agency.isNotEmpty) {
          user['agency'] = agency;
        }
        if (user['agencyId'] == null && agency['id'] != null) {
          user['agencyId'] = agency['id'];
        }

        // Persist session
        if (token.isNotEmpty) {
          ApiService.setAuthToken(token);
        }

        await AuthStorageService.saveSession(
          token: token,
          user: user,
          role: UserRole.agencyAdmin,
        );

        if (!mounted) return;

        // Update Riverpod states
        ref.read(userRoleProvider.notifier).setRole(UserRole.agencyAdmin);
        ref.read(agencyProvider.notifier).updateAgencyDetails(
              agency['name'] ?? _agencyNameCtrl.text.trim(),
              agency['reraNumber'] ?? _reraNumberCtrl.text.trim(),
              agency['adminEmail'] ?? _adminEmailCtrl.text.trim(),
              agency['address'] ?? _corporateAddress.trim(),
            );

        AgencyCelebrationDialog.show(
          context: context,
          agencyName: agency['name'] ?? _agencyNameCtrl.text.trim(),
          agencyCode: agency['agencyCode'] ?? 'AG-00X',
          adminName: user['name'] ?? _adminNameCtrl.text.trim(),
          adminEmail: agency['adminEmail'] ?? _adminEmailCtrl.text.trim(),
          location: agency['location'] ?? _operatingLocation,
          subscriptionTier: _subscriptionTier,
          userQuota: quota,
          reraNumber: agency['reraNumber'] ?? _reraNumberCtrl.text.trim(),
          targetRoute: AppRouter.home,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registration failed. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering agency: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.login);
            }
          },
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
                            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                          ),
                          const Gap(14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agency Brokerage Onboarding',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Gap(3),
                                Text(
                                  'Provision your agency tenant, co-broking team and multi-portal sync in seconds.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),

                    // Section 1: Agency Details Card
                    _buildSectionCard(
                      title: 'Agency Details',
                      icon: Icons.business_center_rounded,
                      children: [
                        // Agency Name *
                        _buildInputField(
                          controller: _agencyNameCtrl,
                          label: 'Agency Name',
                          hint: 'e.g. Skyline Realty',
                          icon: Icons.apartment_rounded,
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
                          hint: 'e.g. PRM/KA/RERA/... (Optional)',
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

                    // Section 2: Admin Details Card
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
                            const Row(
                              children: [
                                Text(
                                  'Admin Password',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Gap(6),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: 'Minimum 6 characters',
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please set a secure password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const Gap(14),

                        // Confirm Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Confirm Password',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Gap(6),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: 'Repeat password',
                                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textSecondary, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordCtrl.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Section 3: Platform Configuration Card
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
                              initialValue: _subscriptionTier,
                              items: _tiers.map((tier) {
                                return DropdownMenuItem(value: tier, child: Text(tier));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _subscriptionTier = val);
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
                          label: 'Initial User Quota (Broker Seats)',
                          hint: '10',
                          icon: Icons.groups_rounded,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter initial user quota';
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

                    // High-Conversion Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
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
                    const Gap(16),

                    // Already have an account row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRouter.login);
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
