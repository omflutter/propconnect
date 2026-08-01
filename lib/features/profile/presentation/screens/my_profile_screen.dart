import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController(text: 'Amit Verma');
  final TextEditingController _phoneController = TextEditingController(text: '+91 9876543210');
  final TextEditingController _emailController = TextEditingController(text: 'amit@sunriseproperties.in');

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final agency = ref.watch(agencyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            child: Text(_isEditing ? 'Save' : 'Edit', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: Text(_nameController.text.isNotEmpty ? _nameController.text.substring(0, 1) : 'A', style: const TextStyle(fontSize: 40, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(32),
            _buildTextField('Full Name', _nameController, Icons.person_outline),
            const Gap(16),
            _buildTextField('Email Address', _emailController, Icons.email_outlined, readOnly: true),
            const Gap(16),
            _buildTextField('Phone Number', _phoneController, Icons.phone_outlined),
            const Gap(32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Professional Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Role', style: TextStyle(color: AppColors.textSecondary)),
                      Text(role == UserRole.agencyAdmin ? 'Agency Admin' : 'Broker / Agent', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Gap(12),
                  const Divider(),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Agency', style: TextStyle(color: AppColors.textSecondary)),
                      Text(agency.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Change Password'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const Gap(8),
        TextField(
          controller: controller,
          readOnly: readOnly || !_isEditing,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.iconColor),
            filled: true,
            fillColor: (readOnly || !_isEditing) ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}
