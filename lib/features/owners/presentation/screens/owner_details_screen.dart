import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/owner_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/utils/export_service.dart';
import 'package:propconnect/features/properties/presentation/screens/add_edit_property_screen.dart';

class OwnerDetailsScreen extends ConsumerStatefulWidget {
  final int ownerId;
  final OwnerModel? initialOwner;

  const OwnerDetailsScreen({
    super.key,
    required this.ownerId,
    this.initialOwner,
  });

  @override
  ConsumerState<OwnerDetailsScreen> createState() => _OwnerDetailsScreenState();
}

class _OwnerDetailsScreenState extends ConsumerState<OwnerDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final owners = ref.watch(ownerProvider);
    final OwnerModel? owner = owners.cast<OwnerModel?>().firstWhere(
          (o) => o?.id == widget.ownerId,
          orElse: () => widget.initialOwner,
        );

    if (owner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Owner Details')),
        body: const Center(child: Text('Owner not found.')),
      );
    }

    final allProperties = ref.watch(propertyProvider);
    final ownerProperties = allProperties.where((p) {
      if (p.ownerId == owner.id) return true;
      if (owner.phonePrimary.isNotEmpty && p.ownerPhonePrimary == owner.phonePrimary) return true;
      if (owner.name.isNotEmpty && p.ownerName.toLowerCase().trim() == owner.name.toLowerCase().trim()) return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Owner Profile & Portfolio',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF16A34A)),
            tooltip: 'Export Portfolio to Excel',
            onPressed: () => _exportOwnerPortfolio(owner, ownerProperties),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
            tooltip: 'Edit Owner',
            onPressed: () => _openEditOwnerDialog(owner),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Hero Card
            _buildHeroCard(owner, ownerProperties),
            const Gap(16),

            // 2. Contact & KYC Info Card
            _buildInfoCard(owner),
            const Gap(16),

            // 3. Properties Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.home_work_outlined, color: AppColors.primaryBlue, size: 20),
                    const Gap(8),
                    Text(
                      'Listed Properties (${ownerProperties.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditPropertyScreen(
                          propertyId: 'new',
                          initialOwner: owner,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Add Property', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const Gap(12),

            // 4. Properties List
            if (ownerProperties.isEmpty)
              _buildEmptyPropertiesState(owner)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ownerProperties.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final prop = ownerProperties[index];
                  return _buildPropertyCard(prop);
                },
              ),
            const Gap(30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(OwnerModel owner, List<PropertyModel> properties) {
    final initials = owner.name.trim().isNotEmpty
        ? owner.name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join('')
            .toUpperCase()
        : 'O';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primaryBlue),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Gap(4),
                    if (owner.idNumber.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 16, color: Color(0xFF16A34A)),
                          const Gap(4),
                          Text(
                            '${owner.idType}: ${owner.idNumber}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'KYC Pending',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(18),
          const Divider(height: 1),
          const Gap(16),

          // Quick Action Bar: Call, WhatsApp, Email, Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.phone_forwarded,
                label: 'Call',
                color: AppColors.primaryBlue,
                onTap: () => _launchCall(owner.phonePrimary),
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _launchWhatsApp(owner.phonePrimary, owner.name),
              ),
              if (owner.email.isNotEmpty)
                _buildActionButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: Colors.deepOrange,
                  onTap: () => _launchEmail(owner.email),
                ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.indigo,
                onTap: () => _shareContact(owner),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(6),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(OwnerModel owner) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primaryBlue, size: 18),
              Gap(8),
              Text(
                'Owner Information & KYC',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Gap(14),
          _buildInfoRow('Primary Phone', owner.phonePrimary.isNotEmpty ? owner.phonePrimary : 'Not provided', Icons.phone_outlined),
          if (owner.phoneSecondary.isNotEmpty)
            _buildInfoRow('Secondary Phone', owner.phoneSecondary, Icons.phone_iphone_outlined),
          if (owner.email.isNotEmpty)
            _buildInfoRow('Email Address', owner.email, Icons.email_outlined),
          if (owner.address.isNotEmpty)
            _buildInfoRow('Registered Address', owner.address, Icons.location_on_outlined),
          if (owner.idNumber.isNotEmpty)
            _buildInfoRow('${owner.idType} Number', owner.idNumber, Icons.verified_user_outlined),

          if (owner.notes.isNotEmpty) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: AppColors.primaryBlue),
                      Gap(6),
                      Text(
                        'Agency Confidential Notes (Firewall Protected)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    owner.notes,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.iconColor),
          const Gap(10),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel prop) {
    return InkWell(
      onTap: () => context.push('/property-details/${prop.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prop.images.isNotEmpty)
              Image.network(
                prop.images.first,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 90,
                  color: Colors.grey.shade100,
                  child: const Center(child: Icon(Icons.apartment, size: 36, color: Colors.grey)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          prop.price,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.primaryBlue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(prop.status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    prop.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          prop.location,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  const Divider(height: 1),
                  const Gap(8),
                  Row(
                    children: [
                      _buildMiniBadge(Icons.king_bed_outlined, prop.bhk),
                      const Gap(10),
                      _buildMiniBadge(Icons.bathtub_outlined, '${prop.bathrooms} Baths'),
                      const Gap(10),
                      _buildMiniBadge(Icons.square_foot_outlined, '${prop.areaSqft.toInt()} sqft'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.iconColor),
        const Gap(3),
        Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyPropertiesState(OwnerModel owner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.home_work_outlined, size: 48, color: Colors.grey[400]),
          const Gap(12),
          Text(
            'No properties listed for ${owner.name} yet.',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Gap(4),
          const Text(
            'Add properties owned by this contact to organize listings under their portfolio.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditPropertyScreen(
                    propertyId: 'new',
                    initialOwner: owner,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Add First Property', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  // Action Helpers
  Future<void> _launchCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) return;
    final msg = Uri.encodeComponent('Hello $name, regarding your property listings on PropConnect:');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=PropConnect%20Property%20Portfolio');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _shareContact(OwnerModel owner) async {
    final text = 'Property Owner Contact:\nName: ${owner.name}\nPhone: ${owner.phonePrimary}\nEmail: ${owner.email}\nAddress: ${owner.address}';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Owner Contact: ${owner.name}',
      ),
    );
  }

  Future<void> _exportOwnerPortfolio(OwnerModel owner, List<PropertyModel> ownerProperties) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Owner Portfolio Excel file...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final path = await ExportService.exportOwnerPortfolioToExcel(
      owner: owner,
      ownerProperties: ownerProperties,
    );

    if (!mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Owner portfolio exported to Excel (.csv)!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openEditOwnerDialog(OwnerModel owner) {
    // Open edit modal bottom sheet
    final nameCtrl = TextEditingController(text: owner.name);
    final phoneCtrl = TextEditingController(text: owner.phonePrimary);
    final phoneSecCtrl = TextEditingController(text: owner.phoneSecondary);
    final emailCtrl = TextEditingController(text: owner.email);
    final addressCtrl = TextEditingController(text: owner.address);
    final idNumberCtrl = TextEditingController(text: owner.idNumber);
    final notesCtrl = TextEditingController(text: owner.notes);
    String selectedIdType = owner.idType;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Property Owner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Owner Full Name *', prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Owner name is required' : null,
                        ),
                        const Gap(12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Primary Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Primary phone is required' : null,
                        ),
                        const Gap(12),
                        TextFormField(
                          controller: phoneSecCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Secondary Phone (Optional)', prefixIcon: Icon(Icons.phone_iphone_outlined)),
                        ),
                        const Gap(12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                        ),
                        const Gap(12),
                        TextFormField(
                          controller: addressCtrl,
                          decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedIdType,
                                decoration: const InputDecoration(labelText: 'ID Type'),
                                items: const [
                                  DropdownMenuItem(value: 'Aadhaar', child: Text('Aadhaar')),
                                  DropdownMenuItem(value: 'PAN', child: Text('PAN')),
                                  DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                                  DropdownMenuItem(value: 'Voter ID', child: Text('Voter ID')),
                                ],
                                onChanged: (v) => setModalState(() => selectedIdType = v ?? 'Aadhaar'),
                              ),
                            ),
                            const Gap(10),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: idNumberCtrl,
                                decoration: const InputDecoration(labelText: 'ID Number'),
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        TextFormField(
                          controller: notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Confidential Internal Notes', prefixIcon: Icon(Icons.notes_outlined)),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);
                              final payload = {
                                'name': nameCtrl.text.trim(),
                                'phonePrimary': phoneCtrl.text.trim(),
                                'phoneSecondary': phoneSecCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'address': addressCtrl.text.trim(),
                                'idType': selectedIdType,
                                'idNumber': idNumberCtrl.text.trim(),
                                'notes': notesCtrl.text.trim(),
                              };
                              await ref.read(ownerProvider.notifier).updateOwner(owner.id, payload);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              setState(() {});
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
