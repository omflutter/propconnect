import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/network/api_service.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isEditing = false;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  final TextEditingController _currentPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  final _passFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final userData = AuthStorageService.getUserData();
    _nameController = TextEditingController(text: (userData?['name'] as String?) ?? 'User');
    _phoneController = TextEditingController(text: (userData?['phone'] as String?) ?? '');
    _emailController = TextEditingController(text: (userData?['email'] as String?) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // Handle Save Profile Details
  Future<void> _handleSaveProfile() async {
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isSavingProfile = true;
    });

    final res = await ApiService.put('/auth/profile', {
      'name': newName,
      'phone': newPhone,
    });

    setState(() {
      _isSavingProfile = false;
    });

    if (res['success'] == true) {
      final updatedUser = (res['data'] as Map<String, dynamic>?) ?? {};
      final token = AuthStorageService.getAuthToken() ?? '';
      final role = AuthStorageService.getUserRole();

      await AuthStorageService.saveSession(
        token: token,
        user: updatedUser,
        role: role,
      );

      setState(() {
        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              Gap(10),
              Text('Profile details updated successfully!'),
            ],
          ),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Handle Change Password
  Future<void> _handleChangePassword() async {
    if (!_passFormKey.currentState!.validate()) return;

    final currentPass = _currentPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    final res = await ApiService.put('/auth/change-password', {
      'currentPassword': currentPass,
      'newPassword': newPass,
    });

    setState(() {
      _isChangingPassword = false;
    });

    if (res['success'] == true) {
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              Gap(10),
              Text('Password changed successfully in PostgreSQL!'),
            ],
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to change password'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final agency = ref.watch(agencyProvider);
    final userData = AuthStorageService.getUserData();
    final name = _nameController.text.trim();
    final userInitials = name.isNotEmpty
        ? name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join('').toUpperCase()
        : 'U';
    final roleTitle = (userData?['adminRoleTitle'] as String?) ??
        ((userData?['role'] as String?) == 'super_admin'
            ? 'Super Admin (Full Access)'
            : (role == UserRole.agencyAdmin ? 'Agency Admin' : 'Broker / Agent'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('My Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (!_isSavingProfile)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  if (_isEditing) {
                    _handleSaveProfile();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
                icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 16, color: AppColors.primaryBlue),
                label: Text(
                  _isEditing ? 'Save' : 'Edit',
                  style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryBlue),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Modern Header Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primaryBlueLight, AppColors.primaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 39,
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: Text(
                              userInitials,
                              style: const TextStyle(fontSize: 28, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                  const Gap(14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const Gap(4),
                  Text(
                    _emailController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const Gap(10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.primaryBlue),
                        const Gap(6),
                        Text(
                          roleTitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // Card 1: Personal Details
            _buildSectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _buildInputField('Full Name', _nameController, Icons.badge_outlined),
                  const Gap(14),
                  _buildInputField('Email Address', _emailController, Icons.email_outlined, readOnly: true),
                  const Gap(14),
                  _buildInputField('Phone Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                ],
              ),
            ),
            const Gap(20),

            // Card 2: Professional Details
            _buildSectionCard(
              title: 'Professional Details',
              icon: Icons.business_center_outlined,
              child: Column(
                children: [
                  _buildDetailRow('Assigned Role', roleTitle, Icons.security_outlined),
                  const Divider(height: 24),
                  _buildDetailRow('Agency Name', agency.name, Icons.storefront_outlined),
                  const Divider(height: 24),
                  _buildDetailRow('Account Status', 'Active & Verified', Icons.check_circle_outline, valueColor: Colors.teal),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.domain_add_rounded, color: AppColors.primaryBlue, size: 22),
                        ),
                        const Gap(12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create / Register Agency',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E3A8A)),
                              ),
                              Gap(2),
                              Text(
                                'Register your brokerage firm to onboard brokers',
                                style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        ElevatedButton(
                          onPressed: () => context.push('/create-agency'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // Card 3: Change Password Form
            _buildSectionCard(
              title: 'Security & Password',
              icon: Icons.lock_outline,
              child: Form(
                key: _passFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentPassCtrl,
                      obscureText: _obscureCurrentPass,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.iconColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrentPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.iconColor, size: 20),
                          onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter current password' : null,
                    ),
                    const Gap(14),
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNewPass,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.key_outlined, color: AppColors.iconColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.iconColor, size: 20),
                          onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                      ),
                      validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 chars' : null,
                    ),
                    const Gap(14),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirmPass,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.iconColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.iconColor, size: 20),
                          onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Confirm your new password' : null,
                    ),
                    const Gap(18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isChangingPassword ? null : _handleChangePassword,
                        child: _isChangingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Update Security Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // Logout Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthStorageService.clearSession();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                label: const Text('Log Out of Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const Gap(10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool readOnly = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const Gap(6),
        TextField(
          controller: controller,
          readOnly: readOnly || !_isEditing,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.iconColor, size: 20),
            filled: true,
            fillColor: (readOnly || !_isEditing) ? const Color(0xFFF8FAFC) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color valueColor = AppColors.textPrimary}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.iconColor),
        const Gap(10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
