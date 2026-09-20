import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/owner_model.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../../../core/utils/export_service.dart';

class OwnersScreen extends ConsumerStatefulWidget {
  const OwnersScreen({super.key});

  @override
  ConsumerState<OwnersScreen> createState() => _OwnersScreenState();
}

class _OwnersScreenState extends ConsumerState<OwnersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddEditOwnerDialog([OwnerModel? ownerToEdit]) {
    final isEditing = ownerToEdit != null;
    final nameCtrl = TextEditingController(text: ownerToEdit?.name ?? '');
    final phonePrimaryCtrl = TextEditingController(text: ownerToEdit?.phonePrimary ?? '');
    final phoneSecondaryCtrl = TextEditingController(text: ownerToEdit?.phoneSecondary ?? '');
    final emailCtrl = TextEditingController(text: ownerToEdit?.email ?? '');
    final addressCtrl = TextEditingController(text: ownerToEdit?.address ?? '');
    final idNumberCtrl = TextEditingController(text: ownerToEdit?.idNumber ?? '');
    final notesCtrl = TextEditingController(text: ownerToEdit?.notes ?? '');
    String selectedIdType = ownerToEdit?.idType.isNotEmpty == true ? ownerToEdit!.idType : 'Aadhaar';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Property Owner' : 'Register New Owner',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Text(
                      'Confidential owner directory protected under PRD Lead Privacy Firewall.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Gap(16),

                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Owner Full Name *',
                        hintText: 'e.g. Ramesh Sharma',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter owner name' : null,
                    ),
                    const Gap(12),

                    // Primary Phone
                    TextFormField(
                      controller: phonePrimaryCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Primary Phone *',
                        hintText: '+91 98200 12345',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Primary phone is required' : null,
                    ),
                    const Gap(12),

                    // Secondary Phone
                    TextFormField(
                      controller: phoneSecondaryCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Secondary / Alternate Phone',
                        hintText: '+91 98200 54321',
                        prefixIcon: const Icon(Icons.phone_iphone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const Gap(12),

                    // Email
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Owner Email Address',
                        hintText: 'ramesh.sharma@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const Gap(12),

                    // Address
                    TextFormField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Owner Residential Address',
                        hintText: 'Flat, Building, Street, City',
                        prefixIcon: const Icon(Icons.home_work_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const Gap(12),

                    // KYC Document Type & Number
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedIdType,
                            decoration: InputDecoration(
                              labelText: 'ID Type',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Aadhaar', child: Text('Aadhaar')),
                              DropdownMenuItem(value: 'PAN', child: Text('PAN')),
                              DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                              DropdownMenuItem(value: 'Voter ID', child: Text('Voter ID')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedIdType = val);
                            },
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: idNumberCtrl,
                            decoration: InputDecoration(
                              labelText: 'ID / Document Number',
                              hintText: 'e.g. XXXX-XXXX-1234',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),

                    // Notes
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Private Agency Notes',
                        hintText: 'Owner availability, expectations, key contact...',
                        prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const Gap(20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);

                                final userData = AuthStorageService.getUserData();
                                final agencyId = userData?['agencyId'] ?? (userData?['agency'] is Map ? userData!['agency']['id'] : 1);

                                final payload = {
                                  'agencyId': agencyId,
                                  'name': nameCtrl.text.trim(),
                                  'phonePrimary': phonePrimaryCtrl.text.trim(),
                                  'phoneSecondary': phoneSecondaryCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'address': addressCtrl.text.trim(),
                                  'idType': selectedIdType,
                                  'idNumber': idNumberCtrl.text.trim(),
                                  'notes': notesCtrl.text.trim(),
                                };

                                if (isEditing) {
                                  await ref.read(ownerProvider.notifier).updateOwner(ownerToEdit.id, payload);
                                } else {
                                  await ref.read(ownerProvider.notifier).addOwner(payload);
                                }

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing ? 'Owner updated successfully' : 'Owner registered successfully'),
                                    backgroundColor: const Color(0xFF059669),
                                  ),
                                );
                              },
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Save Changes' : 'Register Owner',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteOwner(OwnerModel owner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Owner Record?'),
        content: Text('Are you sure you want to remove ${owner.name} from your agency directory? Linked properties will retain records but become unlinked.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(ownerProvider.notifier).deleteOwner(owner.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Owner deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _launchCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _launchEmail(String email) async {
    if (email.trim().isEmpty) return;
    final uri = Uri.parse('mailto:${email.trim()}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final allOwners = ref.watch(ownerProvider);
    final filteredOwners = allOwners.where((o) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return o.name.toLowerCase().contains(q) ||
          o.phonePrimary.toLowerCase().contains(q) ||
          o.email.toLowerCase().contains(q) ||
          o.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Property Owners & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF16A34A)),
            tooltip: 'Export Owners to Excel',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating Owners Directory Excel file...'), behavior: SnackBarBehavior.floating),
              );
              final allProperties = ref.read(propertyProvider);
              final path = await ExportService.exportOwnersDirectoryToExcel(owners: allOwners, allProperties: allProperties);
              if (!context.mounted) return;
              if (path != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported ${allOwners.length} owners to Excel (.csv)!'),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ownerProvider.notifier).fetchOwners(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditOwnerDialog(),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Owner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header Search & Metrics Banner
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search owners by name, phone, email...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF059669)),
                        const Gap(6),
                        Text(
                          '${allOwners.length} Registered Owners',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Text(
                        'Lead Privacy Protected',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Owner List
          Expanded(
            child: filteredOwners.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[400]),
                        const Gap(12),
                        Text(
                          _searchQuery.isNotEmpty ? 'No owners match "$_searchQuery"' : 'No property owners registered yet',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const Gap(8),
                        const Text(
                          'Tap the button below or add an owner while posting a property.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(20),
                        ElevatedButton.icon(
                          onPressed: () => _openAddEditOwnerDialog(),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text('Add First Owner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: filteredOwners.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      final owner = filteredOwners[index];
                      return _buildOwnerCard(owner);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(OwnerModel owner) {
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

    final allProperties = ref.watch(propertyProvider);
    final count = allProperties.where((p) => p.ownerId == owner.id || (p.ownerPhonePrimary == owner.phonePrimary && owner.phonePrimary.isNotEmpty)).length;
    final displayCount = count > 0 ? count : owner.propertyCount;

    return InkWell(
      onTap: () => context.push('/owner-details/${owner.id}', extra: owner),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header: Avatar, Name, Badge, Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    if (owner.idNumber.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.green[600]),
                          const Gap(4),
                          Text(
                            '${owner.idType}: ${owner.idNumber}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.iconColor),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openAddEditOwnerDialog(owner);
                  } else if (val == 'delete') {
                    _confirmDeleteOwner(owner);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), Gap(8), Text('Edit Details')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), Gap(8), Text('Delete Record', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),

          // Primary Phone with Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.primaryBlue),
                  const Gap(8),
                  Text(
                    owner.phonePrimary,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, size: 18, color: Color(0xFF059669)),
                    onPressed: () => _launchCall(owner.phonePrimary),
                    tooltip: 'Call Owner',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                    onPressed: () => _launchWhatsApp(owner.phonePrimary),
                    tooltip: 'WhatsApp Owner',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  if (owner.email.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.email_outlined, size: 18, color: AppColors.primaryBlue),
                      onPressed: () => _launchEmail(owner.email),
                      tooltip: 'Email Owner',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                ],
              ),
            ],
          ),

          // Alternate Phone
          if (owner.phoneSecondary.isNotEmpty) ...[
            const Gap(6),
            Row(
              children: [
                const Icon(Icons.phone_iphone, size: 16, color: AppColors.iconColor),
                const Gap(8),
                Text(
                  'Alt: ${owner.phoneSecondary}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],

          // Email
          if (owner.email.isNotEmpty) ...[
            const Gap(6),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: AppColors.iconColor),
                const Gap(8),
                Expanded(
                  child: Text(
                    owner.email,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Address
          if (owner.address.isNotEmpty) ...[
            const Gap(6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.iconColor),
                const Gap(8),
                Expanded(
                  child: Text(
                    owner.address,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Footer: Properties Linked Badge & View Details
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_work_outlined, size: 14, color: AppColors.primaryBlue),
                    const Gap(6),
                    Text(
                      '$displayCount ${displayCount == 1 ? 'Property' : 'Properties'} Listed',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                  Gap(4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryBlue),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
