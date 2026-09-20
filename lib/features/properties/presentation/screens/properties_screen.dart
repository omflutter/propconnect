import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/auto_sync_service.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/utils/export_service.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final props = ref.read(propertyProvider);
      if (props.isEmpty) {
        ref.read(propertyProvider.notifier).fetchProperties();
      }
      final syncConfig = ref.read(autoSyncProvider).config;
      if (syncConfig != null && syncConfig.isEnabled && syncConfig.lastSyncedAt != null) {
        ref.read(autoSyncProvider.notifier).checkAndRunScheduledSync();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Handle Live Bulk Import
  Future<bool> _handleBulkImport(String platform, List<Map<String, dynamic>> sampleList, {String syncFreq = 'Daily Auto-Sync'}) async {
    final userData = AuthStorageService.getUserData();
    final userAgency = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyName = (userAgency?['name'] as String?) ??
        (userData?['agencyName'] as String?) ??
        (userData?['agency_name'] as String?) ??
        ref.read(agencyProvider).name;
    final userAgencyId = userData?['agencyId'] ?? userData?['agency_id'] ?? userAgency?['id'];
    final userName = (userData?['name'] as String?) ?? '';
    final parsedAgencyId = userAgencyId != null ? int.tryParse(userAgencyId.toString()) : null;

    try {
      final payload = <String, dynamic>{
        'platform': platform,
        'syncFrequency': syncFreq,
        'properties': sampleList,
      };
      if (parsedAgencyId != null) {
        payload['agencyId'] = parsedAgencyId;
      }
      if (userAgencyName.trim().isNotEmpty) {
        payload['agencyName'] = userAgencyName.trim();
      }
      if (userName.trim().isNotEmpty) {
        payload['brokerName'] = userName.trim();
      }

      final res = await ApiService.post('/properties/import', payload);

      if (res['success'] == true) {
        if (res['data'] != null && res['data'] is List) {
          final list = <PropertyModel>[];
          for (final item in (res['data'] as List)) {
            try {
              if (item is Map) {
                list.add(PropertyModel.fromJson(Map<String, dynamic>.from(item)));
              }
            } catch (err) {
              debugPrint('Error parsing imported item: $err');
            }
          }
          if (list.isNotEmpty) {
            ref.read(propertyProvider.notifier).addImportedProperties(list);
          }
        }

        try {
          await ref.read(propertyProvider.notifier).fetchProperties();
        } catch (fetchErr) {
          debugPrint('Error refetching properties: $fetchErr');
        }

        if (mounted) {
          final serverMsg = res['message'] as String? ??
              'Successfully synced ${sampleList.length} properties from $platform without duplicates! ($syncFreq)';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Colors.white, size: 20),
                  const Gap(10),
                  Expanded(
                    child: Text(serverMsg),
                  ),
                ],
              ),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Import failed'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  // Interactive Export to Excel Modal
  void _showExportModal(List<PropertyModel> displayedProperties) {
    final allProperties = ref.read(propertyProvider);
    bool exportOnlyFiltered = _searchQuery.isNotEmpty && displayedProperties.length != allProperties.length;
    bool isExporting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final targetList = exportOnlyFiltered ? displayedProperties : allProperties;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.table_view_rounded, color: Color(0xFF16A34A), size: 24),
                    ),
                    const Gap(12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Export Properties to Excel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Gap(2),
                          Text('Generate a clean .xlsx / CSV spreadsheet file', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Gap(18),

                // Options Selection
                const Text('Choose Export Scope', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const Gap(8),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setModalState(() => exportOnlyFiltered = false),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                !exportOnlyFiltered ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: !exportOnlyFiltered ? const Color(0xFF16A34A) : Colors.grey,
                                size: 20,
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('All Properties (${allProperties.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const Text('Export complete property portfolio with all details', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const Divider(height: 1),
                        InkWell(
                          onTap: () => setModalState(() => exportOnlyFiltered = true),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  exportOnlyFiltered ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: exportOnlyFiltered ? const Color(0xFF16A34A) : Colors.grey,
                                  size: 20,
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Filtered Results (${displayedProperties.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text('Matching search query "$_searchQuery"', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Gap(16),
                const Text('Included Excel Columns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const Gap(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildColumnChip('Code & Title'),
                    _buildColumnChip('Price & Status'),
                    _buildColumnChip('BHK & Area (Sqft)'),
                    _buildColumnChip('Carpet Area'),
                    _buildColumnChip('Location & City'),
                    _buildColumnChip('Owner Name & Phone'),
                    _buildColumnChip('Amenities'),
                    _buildColumnChip('Listing Date'),
                  ],
                ),

                const Gap(24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isExporting || targetList.isEmpty
                        ? null
                        : () async {
                            setModalState(() => isExporting = true);
                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Generating Excel export file...'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            final filePath = await ExportService.exportPropertiesToExcel(
                              properties: targetList,
                              title: exportOnlyFiltered ? 'Filtered_Properties' : 'My_Properties',
                            );

                            if (!context.mounted) return;
                            if (filePath != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Exported ${targetList.length} properties to Excel (.csv)!'),
                                  backgroundColor: const Color(0xFF059669),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Export completed or shared successfully.'),
                                  backgroundColor: Color(0xFF059669),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    icon: isExporting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                    label: Text(
                      isExporting ? 'Exporting...' : 'Export ${targetList.length} Properties to Excel',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const Gap(12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColumnChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: Color(0xFF16A34A)),
          const Gap(4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // Interactive Import & Feed Preview Modal Sheet
  void _showImportModal() {
    final currentSyncConfig = ref.read(autoSyncProvider).config;
    final userData = AuthStorageService.getUserData();
    final userAgency = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyName = (userAgency?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? (userData?['name'] != null ? '${userData!['name']}\'s Agency' : 'My Agency');
    final agencySlug = userAgencyName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final defaultUrl = 'https://feed.99acres.com/v1/agency/${agencySlug.isNotEmpty ? agencySlug : "partner"}';

    String selectedPlatform = currentSyncConfig?.platform ?? '99acres';
    final apiKeyCtrl = TextEditingController(text: currentSyncConfig?.apiKey.isNotEmpty == true ? currentSyncConfig!.apiKey : '99ACRES-API-SEC-98421');
    final feedUrlCtrl = TextEditingController(text: currentSyncConfig?.feedUrl.isNotEmpty == true ? currentSyncConfig!.feedUrl : defaultUrl);
    bool obscureApiKey = true;
    String syncFreq = currentSyncConfig?.frequency ?? 'Daily Auto-Sync';

    // State for Preview & Multi-Step Flow
    bool isPreviewMode = false;
    bool isFetchingPreview = false;
    bool isImportingModal = false;
    bool isLiveFeedSource = false;
    String? feedErrorMessage;
    List<Map<String, dynamic>> previewListings = [];
    Set<int> selectedIndices = {};

    final allCurrentProps = ref.read(propertyProvider);
    final existingTitles = allCurrentProps.map((p) => p.title.trim().toLowerCase()).toSet();
    final existingCoreTitles = allCurrentProps.map((p) =>
      p.title.trim().toLowerCase().replaceAll(RegExp(r'^(99acres|magicbricks|housing(\.com)?|custom\s*feed)[^:]*:\s*', caseSensitive: false), '').trim()
    ).where((s) => s.length >= 6).toSet();

    bool isItemInDb(Map<String, dynamic> item) {
      final t = (item['title'] as String? ?? '').trim().toLowerCase();
      if (existingTitles.contains(t)) return true;
      final core = t.replaceAll(RegExp(r'^(99acres|magicbricks|housing(\.com)?|custom\s*feed)[^:]*:\s*', caseSensitive: false), '').trim();
      if (core.length >= 6 && existingCoreTitles.contains(core)) return true;
      return false;
    }

    final List<Map<String, dynamic>> platforms = [
      {
        'id': '99acres',
        'name': '99acres',
        'badge': 'VERIFIED PARTNER',
        'color': const Color(0xFF003366),
        'bgLight': const Color(0xFFEBF3FA),
        'icon': Icons.apartment,
        'desc': 'Direct API & XML Feed Sync',
      },
      {
        'id': 'MagicBricks',
        'name': 'MagicBricks',
        'badge': 'PRIME FEED',
        'color': const Color(0xFFD92525),
        'bgLight': const Color(0xFFFDE8E8),
        'icon': Icons.home_work_outlined,
        'desc': 'Realtime Partner Webhook',
      },
      {
        'id': 'Housing.com',
        'name': 'Housing.com',
        'badge': 'SMART SYNC',
        'color': const Color(0xFF5E2B97),
        'bgLight': const Color(0xFFF3EDF9),
        'icon': Icons.holiday_village_outlined,
        'desc': 'JSON Feed & Partner Key',
      },
      {
        'id': 'Custom API',
        'name': 'Custom API Feed',
        'badge': 'GENERIC FEED',
        'color': Colors.teal,
        'bgLight': const Color(0xFFE6F4F1),
        'icon': Icons.code_outlined,
        'desc': 'CSV / REST API Integration',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activePlatform = platforms.firstWhere((p) => p['id'] == selectedPlatform);

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isPreviewMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modal Title Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cloud_download_outlined, color: AppColors.primaryBlue, size: 24),
                              Gap(10),
                              Text('Import Properties', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Text(
                        'Import inventory from 99acres, MagicBricks, Housing.com, or custom API feeds. Review listings in live preview before saving to database.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                      ),
                      const Gap(20),

                      // Step 1: Platform Cards Grid
                      const Text('1. Select Partner Platform', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const Gap(10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: platforms.length,
                        itemBuilder: (context, index) {
                          final item = platforms[index];
                          final isSel = selectedPlatform == item['id'];
                          final Color brandColor = item['color'] as Color;
                          final Color bgLight = item['bgLight'] as Color;

                          return GestureDetector(
                            onTap: isFetchingPreview
                                ? null
                                : () {
                                    setModalState(() {
                                      selectedPlatform = item['id'] as String;
                                      apiKeyCtrl.text = '${item['id']}-API-KEY-89421'.toUpperCase();
                                      feedUrlCtrl.text = 'https://feed.${(item['id'] as String).toLowerCase().replaceAll(' ', '')}.com/v1/agency/sync';
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSel ? bgLight : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel ? brandColor : AppColors.border,
                                  width: isSel ? 2 : 1,
                                ),
                                boxShadow: isSel
                                    ? [BoxShadow(color: brandColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSel ? brandColor : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(item['icon'] as IconData, color: isSel ? Colors.white : AppColors.textSecondary, size: 20),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSel ? brandColor : AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Gap(2),
                                        Text(
                                          item['badge'] as String,
                                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: isSel ? brandColor : AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const Gap(20),

                      // Step 2: Credentials & Feed Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.vpn_key_outlined, color: activePlatform['color'] as Color, size: 18),
                                const Gap(8),
                                Text('2. Configure $selectedPlatform API Key & Feed', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            const Gap(14),
                            TextFormField(
                              controller: apiKeyCtrl,
                              obscureText: obscureApiKey,
                              enabled: !isFetchingPreview,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: '$selectedPlatform API Secret Token',
                                labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                prefixIcon: const Icon(Icons.key_outlined, color: AppColors.iconColor, size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.iconColor),
                                  onPressed: () => setModalState(() => obscureApiKey = !obscureApiKey),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const Gap(12),
                            TextFormField(
                              controller: feedUrlCtrl,
                              enabled: !isFetchingPreview,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Inventory Feed Endpoint / Webhook URL',
                                labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                prefixIcon: const Icon(Icons.link_outlined, color: AppColors.iconColor, size: 18),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const Gap(14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Auto-Sync Frequency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                DropdownButton<String>(
                                  value: syncFreq,
                                  underline: const SizedBox(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                  items: const [
                                    DropdownMenuItem(value: 'Realtime Webhook', child: Text('Realtime Webhook')),
                                    DropdownMenuItem(value: 'Daily Auto-Sync', child: Text('Daily Auto-Sync')),
                                    DropdownMenuItem(value: 'Manual Sync Only', child: Text('Manual Sync Only')),
                                  ],
                                  onChanged: isFetchingPreview
                                      ? null
                                      : (v) {
                                          if (v != null) setModalState(() => syncFreq = v);
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Feed Validation & Preview Info Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (activePlatform['bgLight'] as Color),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (activePlatform['color'] as Color).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, color: activePlatform['color'] as Color, size: 20),
                            const Gap(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Preview Before Adding', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: activePlatform['color'] as Color)),
                                  Text('Fetch feed listings to review property photos, prices, and specifications before importing into PostgreSQL.', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(20),

                      // Live Feed Connection Error Banner (if real link failed)
                      if (feedErrorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                                  Gap(8),
                                  Text(
                                    'Live Feed Connection Failed',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  ),
                                ],
                              ),
                              const Gap(6),
                              Text(
                                feedErrorMessage!,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)),
                              ),
                              const Gap(8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      final fallbackListings = AutoSyncNotifier.getPlatformSampleListings(selectedPlatform);
                                      setModalState(() {
                                        previewListings = fallbackListings;
                                        isLiveFeedSource = false;
                                        selectedIndices = Set<int>.from(List.generate(fallbackListings.length, (i) => i));
                                        feedErrorMessage = null;
                                        isPreviewMode = true;
                                      });
                                    },
                                    icon: const Icon(Icons.play_circle_outline, size: 14, color: Color(0xFFDC2626)),
                                    label: const Text(
                                      'Load Sample Template Instead',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.red.shade200)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Gap(14),
                      ],

                      // Primary Button: Connect & Fetch Feed Preview
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activePlatform['color'] as Color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: isFetchingPreview
                              ? null
                              : () async {
                                  setModalState(() {
                                    isFetchingPreview = true;
                                    feedErrorMessage = null;
                                  });

                                  final result = await AutoSyncNotifier.fetchFeedListings(
                                    platform: selectedPlatform,
                                    feedUrl: feedUrlCtrl.text,
                                    apiKey: apiKeyCtrl.text,
                                  );

                                  if (!result.isSuccess) {
                                    setModalState(() {
                                      isFetchingPreview = false;
                                      feedErrorMessage = result.errorMessage;
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    previewListings = result.listings;
                                    isLiveFeedSource = result.isRealFeed;
                                    final newIndices = <int>{};
                                    for (int i = 0; i < result.listings.length; i++) {
                                      if (!isItemInDb(result.listings[i])) {
                                        newIndices.add(i);
                                      }
                                    }
                                    selectedIndices = newIndices.isNotEmpty
                                        ? newIndices
                                        : Set<int>.from(List.generate(result.listings.length, (i) => i));
                                    isFetchingPreview = false;
                                    isPreviewMode = true;
                                    feedErrorMessage = null;
                                  });
                                },
                          icon: isFetchingPreview
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : const Icon(Icons.preview_outlined, color: Colors.white, size: 20),
                          label: Text(
                            isFetchingPreview
                                ? 'Connecting & Fetching $selectedPlatform Feed...'
                                : 'Connect & Preview Feed Listings',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      const Gap(16),
                    ],
                  ),
                  secondChild: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview Header with Back Button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                            onPressed: isImportingModal ? null : () => setModalState(() => isPreviewMode = false),
                          ),
                          const Gap(4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Feed Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    const Gap(8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isLiveFeedSource ? const Color(0xFFDCFCE7) : (activePlatform['bgLight'] as Color),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: isLiveFeedSource ? const Color(0xFF16A34A) : (activePlatform['color'] as Color).withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isLiveFeedSource) ...[
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                                            ),
                                            const Gap(4),
                                          ],
                                          Text(
                                            isLiveFeedSource ? 'LIVE FEED (LIVE)' : (activePlatform['name'] as String),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isLiveFeedSource ? const Color(0xFF15803D) : (activePlatform['color'] as Color),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isLiveFeedSource
                                      ? '${previewListings.length} live properties fetched from actual endpoint'
                                      : '${previewListings.length} properties detected in feed • Select items to import',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isLiveFeedSource ? const Color(0xFF15803D) : AppColors.textSecondary,
                                    fontWeight: isLiveFeedSource ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                            onPressed: isImportingModal ? null : () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Gap(12),

                      // Selection Toolbar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.checklist, size: 18, color: activePlatform['color'] as Color),
                                const Gap(6),
                                Builder(
                                  builder: (context) {
                                    final selInDb = selectedIndices.where((i) => i < previewListings.length && isItemInDb(previewListings[i])).length;
                                    final selNew = selectedIndices.length - selInDb;
                                    return Text(
                                      selInDb > 0
                                          ? '${selectedIndices.length} selected ($selNew new, $selInDb updates)'
                                          : '${selectedIndices.length} of ${previewListings.length} selected',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.textPrimary),
                                    );
                                  },
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: isImportingModal
                                  ? null
                                  : () {
                                      setModalState(() {
                                        if (selectedIndices.length == previewListings.length) {
                                          selectedIndices.clear();
                                        } else {
                                          selectedIndices = Set<int>.from(List.generate(previewListings.length, (i) => i));
                                        }
                                      });
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                selectedIndices.length == previewListings.length ? 'Deselect All' : 'Select All',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: activePlatform['color'] as Color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),

                      // Scrollable Preview Cards
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.42,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: previewListings.length,
                          separatorBuilder: (context, index) => const Gap(10),
                          itemBuilder: (context, idx) {
                            final item = previewListings[idx];
                            final isSelected = selectedIndices.contains(idx);
                            final images = (item['images'] as List?)?.cast<String>() ?? [];
                            final imgUrl = images.isNotEmpty ? images.first : '';

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: isImportingModal
                                  ? null
                                  : () {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedIndices.remove(idx);
                                        } else {
                                          selectedIndices.add(idx);
                                        }
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? (activePlatform['color'] as Color) : AppColors.border,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: (activePlatform['color'] as Color).withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Checkbox
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, right: 4),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: isSelected,
                                          activeColor: activePlatform['color'] as Color,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: isImportingModal
                                              ? null
                                              : (val) {
                                                  setModalState(() {
                                                    if (val == true) {
                                                      selectedIndices.add(idx);
                                                    } else {
                                                      selectedIndices.remove(idx);
                                                    }
                                                  });
                                                },
                                        ),
                                      ),
                                    ),
                                    // Thumbnail
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imgUrl.isNotEmpty
                                          ? Image.network(
                                              imgUrl,
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 72,
                                                height: 72,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.home_outlined, color: Colors.grey),
                                              ),
                                            )
                                          : Container(
                                              width: 72,
                                              height: 72,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.home_outlined, color: Colors.grey),
                                            ),
                                    ),
                                    const Gap(10),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Synced / New Status Badge
                                          Builder(
                                            builder: (context) {
                                              final inDb = isItemInDb(item);
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: inDb ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: inDb ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      inDb ? Icons.sync : Icons.add_circle_outline,
                                                      size: 11,
                                                      color: inDb ? const Color(0xFF2563EB) : const Color(0xFF059669),
                                                    ),
                                                    const Gap(3),
                                                    Text(
                                                      inDb ? 'Synced • Will update in-place' : 'New Listing • Will be added',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: inDb ? const Color(0xFF1D4ED8) : const Color(0xFF047857),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          Text(
                                            item['title'] as String? ?? 'Untitled Listing',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Gap(3),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                                              const Gap(2),
                                              Expanded(
                                                child: Text(
                                                  item['location'] as String? ?? '',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Gap(4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item['price'] as String? ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: activePlatform['color'] as Color,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${item['bhk'] ?? ''} • ${item['areaSqft'] ?? ''} sqft',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Gap(12),

                      // Target Database Info
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_upload_outlined, size: 18, color: Color(0xFF16A34A)),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                'Saving to Aiven PostgreSQL for agency "$userAgencyName" • Auto-Sync: $syncFreq',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Confirmation Buttons with Loading State
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: isImportingModal ? null : () => setModalState(() => isPreviewMode = false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Back'),
                          ),
                          const Gap(10),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activePlatform['color'] as Color,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: (isImportingModal || selectedIndices.isEmpty)
                                    ? null
                                    : () async {
                                        setModalState(() => isImportingModal = true);

                                        // Persist auto-sync settings
                                        await ref.read(autoSyncProvider.notifier).updateConfig(
                                          platform: selectedPlatform,
                                          frequency: syncFreq,
                                          apiKey: apiKeyCtrl.text,
                                          feedUrl: feedUrlCtrl.text,
                                          isEnabled: true,
                                        );

                                        final selectedProperties = selectedIndices.map((i) => previewListings[i]).toList();
                                        final ok = await _handleBulkImport(selectedPlatform, selectedProperties, syncFreq: syncFreq);

                                        if (modalContext.mounted) {
                                          setModalState(() => isImportingModal = false);
                                          if (ok) {
                                            Navigator.of(modalContext).pop();
                                          }
                                        }
                                      },
                                icon: isImportingModal
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.cloud_download, color: Colors.white, size: 18),
                                label: Builder(
                                  builder: (context) {
                                    final selInDbCount = selectedIndices.where((i) => i < previewListings.length && isItemInDb(previewListings[i])).length;
                                    final selNewCount = selectedIndices.length - selInDbCount;
                                    final String btnText;
                                    if (isImportingModal) {
                                      btnText = 'Syncing ${selectedIndices.length} to PostgreSQL...';
                                    } else if (selNewCount > 0 && selInDbCount > 0) {
                                      btnText = 'Confirm & Sync ($selNewCount New, $selInDbCount Updates)';
                                    } else if (selInDbCount > 0) {
                                      btnText = 'Update In-Place ($selInDbCount Existing)';
                                    } else {
                                      btnText = 'Confirm & Import ($selNewCount New)';
                                    }
                                    return Text(
                                      btnText,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertyProvider);
    final isLoading = ref.watch(isPropertiesLoadingProvider);
    final loadError = ref.watch(propertiesErrorProvider);
    final autoSyncState = ref.watch(autoSyncProvider);
    final userData = AuthStorageService.getUserData();
    final userAgency = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userData?['agency_id'] ?? userAgency?['id'];
    final userAgencyName = (userAgency?['name'] as String?) ??
        (userData?['agencyName'] as String?) ??
        (userData?['agency_name'] as String?) ??
        ref.watch(agencyProvider).name;
    final userName = (userData?['name'] as String?) ?? '';
    final userRole = (userData?['role'] as String?)?.toLowerCase();

    // Only show properties created by / belonging to the current user or agency
    var myProperties = properties.where((p) {
      if (userRole == 'super_admin') return true;
      // 1. Strict agencyId check if available
      if (userAgencyId != null && p.agencyId != null) {
        if (p.agencyId.toString() == userAgencyId.toString()) return true;
      }
      // 2. Exact agency name match if not empty
      if (userAgencyName.trim().isNotEmpty && p.agencyName.trim().isNotEmpty) {
        if (p.agencyName.toLowerCase().trim() == userAgencyName.toLowerCase().trim()) return true;
      }
      // 3. Exact broker name match if not empty
      if (userName.trim().isNotEmpty && p.brokerName.trim().isNotEmpty) {
        if (p.brokerName.toLowerCase().trim() == userName.toLowerCase().trim()) return true;
      }
      return false;
    }).toList();

    // Apply Search Filter
    if (_searchQuery.isNotEmpty) {
      myProperties = myProperties.where((p) =>
        p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.price.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Properties', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/owners'),
            icon: const Icon(Icons.people_alt_outlined, color: AppColors.primaryBlue),
            tooltip: 'Property Owners & Settings',
          ),
          OutlinedButton.icon(
            onPressed: () => _showExportModal(myProperties),
            icon: const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF16A34A)),
            label: const Text('Export', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF16A34A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton.icon(
              onPressed: _showImportModal,
              icon: const Icon(Icons.cloud_download_outlined, size: 16, color: AppColors.primaryBlue),
              label: const Text('Import', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search my properties by title, location, or price...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(height: 1),

          // Active Feed Auto-Sync Status Bar
          if (autoSyncState.config != null && autoSyncState.config!.isEnabled && autoSyncState.config!.lastSyncedAt != null) ...[
            _buildAutoSyncStatusBar(autoSyncState),
            const Divider(height: 1),
          ],

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(propertyProvider.notifier).fetchProperties(),
              color: AppColors.primaryBlue,
              child: _buildPropertyList(myProperties, isLoading, loadError),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-property/new'),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text('Add Property', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPropertyList(List<PropertyModel> list, bool isLoading, String? loadError) {
    if (isLoading && list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Gap(20),
              const Text(
                'Connecting to Cloud Database...',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Gap(6),
              const Text(
                'Retrieving live inventory from Aiven PostgreSQL...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (!isLoading && loadError != null && list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
              ),
              const Gap(16),
              const Text(
                'Database Connection Delay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Gap(8),
              Text(
                loadError,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Gap(20),
              ElevatedButton.icon(
                onPressed: () => ref.read(propertyProvider.notifier).fetchProperties(),
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                label: const Text('Retry Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.house_outlined, size: 48, color: AppColors.primaryBlue),
              ),
              const Gap(16),
              const Text(
                'No Properties Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Gap(8),
              const Text(
                'Properties posted by your agency or imported from 99acres / MagicBricks will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const Gap(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/add-edit-property/new'),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Post Property', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Gap(12),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(propertyProvider.notifier).fetchProperties(),
                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.primaryBlue),
                    label: const Text('Refresh', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (isLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                ),
                Gap(8),
                Text(
                  'Syncing latest listings with cloud database...',
                  style: TextStyle(fontSize: 11.5, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final prop = list[index];
        return GestureDetector(
          onTap: () => context.push('/property-details/${prop.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: prop.images.isNotEmpty
                          ? Image.network(prop.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.apartment, size: 48, color: AppColors.primaryBlue)))
                          : const Center(child: Icon(Icons.apartment, size: 48, color: AppColors.primaryBlue)),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: prop.type == 'Sale' ? AppColors.primaryBlue : Colors.teal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'For ${prop.type}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prop.bhk,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              prop.price,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primaryBlue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
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
                      const Gap(6),
                      Text(prop.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                      const Gap(4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                          const Gap(4),
                          Expanded(
                            child: Text(prop.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const Gap(12),
                      const Divider(height: 1),
                      const Gap(12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFeatureIcon(Icons.king_bed_outlined, prop.bhk),
                                  const Gap(14),
                                  _buildFeatureIcon(Icons.bathtub_outlined, '${prop.bathrooms} Baths'),
                                  const Gap(14),
                                  _buildFeatureIcon(Icons.square_foot_outlined, '${prop.areaSqft} sqft'),
                                ],
                              ),
                            ),
                          ),
                          const Gap(6),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),
],
);
}

  Widget _buildFeatureIcon(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.iconColor),
        const Gap(4),
        Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAutoSyncStatusBar(AutoSyncState autoSync) {
    final cfg = autoSync.config;
    if (cfg == null || !cfg.isEnabled) return const SizedBox.shrink();

    final lastSync = cfg.lastSyncedAt;
    final isLive = !AutoSyncNotifier.isTemplateUrl(cfg.feedUrl);

    String timeAgo = 'Just now';
    if (lastSync != null) {
      final diff = DateTime.now().difference(lastSync);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}m ago';
      }
    } else {
      timeAgo = 'Never';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border(bottom: BorderSide(color: Colors.green.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_sync, size: 16, color: Color(0xFF16A34A)),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      '${cfg.platform} Feed Auto-Sync',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF15803D)),
                    ),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF16A34A), width: 0.8),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cfg.frequency,
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  autoSync.isSyncing
                      ? 'Fetching live inventory from feed...'
                      : (isLive ? 'Live endpoint • Last synced $timeAgo' : 'Active • Last synced $timeAgo'),
                  style: TextStyle(fontSize: 10.5, color: Colors.green.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Gap(8),
          TextButton.icon(
            onPressed: autoSync.isSyncing
                ? null
                : () async {
                    final ok = await ref.read(autoSyncProvider.notifier).syncFeedNow();
                    if (mounted) {
                      final msg = ref.read(autoSyncProvider).lastMessage;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg ?? (ok ? 'Sync completed from ${cfg.platform}!' : 'Sync failed. Check connection.')),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: ok ? Colors.teal : AppColors.error,
                        ),
                      );
                    }
                  },
            icon: autoSync.isSyncing
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF15803D)),
                  )
                : const Icon(Icons.sync, size: 14, color: Color(0xFF15803D)),
            label: Text(
              autoSync.isSyncing ? 'Syncing...' : 'Sync Now',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.green.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

