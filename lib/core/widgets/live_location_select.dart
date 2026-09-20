import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/utils/location_helper.dart';

class LiveLocationSelect extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final ValueChanged<LocationDetails>? onLocationDetailsSelected;
  final String label;
  final String placeholder;
  final String searchPlaceholder;
  final bool isRequired;
  final String? Function(String?)? validator;

  const LiveLocationSelect({
    super.key,
    required this.value,
    required this.onChanged,
    this.onLocationDetailsSelected,
    this.label = 'Operating Cities / Location',
    this.placeholder = 'Search & select location...',
    this.searchPlaceholder = 'Type city, locality, district or PIN code...',
    this.isRequired = false,
    this.validator,
  });

  static const List<String> defaultPopular = [
    'Mumbai (MMR), Maharashtra',
    'Delhi NCR (Delhi, Gurugram, Noida)',
    'Bengaluru, Karnataka',
    'Hyderabad, Telangana',
    'Pune, Maharashtra',
    'Chennai, Tamil Nadu',
    'Kolkata, West Bengal',
    'Ahmedabad, Gujarat',
    'Jaipur, Rajasthan',
    'Surat, Gujarat',
    'Chandigarh Tri-City',
    'Lucknow, Uttar Pradesh',
  ];

  @override
  State<LiveLocationSelect> createState() => _LiveLocationSelectState();
}

class _LiveLocationSelectState extends State<LiveLocationSelect> {
  void _openLocationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationSearchModal(
        initialValue: widget.value ?? '',
        searchPlaceholder: widget.searchPlaceholder,
        onSelected: (loc) {
          widget.onChanged(loc);
        },
        onDetailsSelected: widget.onLocationDetailsSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.trim().isNotEmpty;

    return FormField<String>(
      initialValue: widget.value,
      validator: widget.validator ??
          (widget.isRequired
              ? (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please select a location';
                  }
                  return null;
                }
              : null),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.isRequired)
                  const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ],
            ),
            const Gap(6),
            InkWell(
              onTap: _openLocationSearchSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasError ? AppColors.error : AppColors.border,
                    width: state.hasError ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 20),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        hasValue ? widget.value! : widget.placeholder,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                          color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasValue)
                      GestureDetector(
                        onTap: () {
                          widget.onChanged('');
                          state.didChange('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            if (state.hasError) ...[
              const Gap(5),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.error),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LocationSearchModal extends StatefulWidget {
  final String initialValue;
  final String searchPlaceholder;
  final ValueChanged<String> onSelected;
  final ValueChanged<LocationDetails>? onDetailsSelected;

  const _LocationSearchModal({
    required this.initialValue,
    required this.searchPlaceholder,
    required this.onSelected,
    this.onDetailsSelected,
  });

  @override
  State<_LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<_LocationSearchModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  List<String> _apiResults = [];
  List<Map<String, dynamic>> _rawApiResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue.isNotEmpty) {
      _searchCtrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _apiResults = [];
        _rawApiResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&countrycodes=in&limit=10',
        );

        final res = await http.get(url, headers: {
          'User-Agent': 'PropConnectApp/1.0',
        });

        if (res.statusCode == 200 && mounted) {
          final List parsed = jsonDecode(res.body);
          final raw = parsed
              .map((item) => Map<String, dynamic>.from(item as Map))
              .where((item) => ((item['display_name'] as String?) ?? '').isNotEmpty)
              .toList();

          setState(() {
            _rawApiResults = raw;
            _apiResults = raw.map((r) => (r['display_name'] as String?) ?? '').toList();
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    final filteredPopular = LiveLocationSelect.defaultPopular
        .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_searching_rounded, color: AppColors.primaryBlue, size: 20),
                    ),
                    const Gap(10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Location',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Real-time Indian cities, districts & PIN codes',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                hintText: widget.searchPlaceholder,
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                        ),
                      )
                    : query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Results List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              children: [
                // Custom typed option if user typed something
                if (query.isNotEmpty) ...[
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: AppColors.primaryBlue.withValues(alpha: 0.05),
                    leading: const Icon(Icons.add_location_alt_rounded, color: AppColors.primaryBlue),
                    title: Text(
                      'Use "$query"',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                    ),
                    subtitle: const Text(
                      'Use as custom entered location',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    onTap: () {
                      widget.onSelected(query);
                      Navigator.pop(context);
                    },
                  ),
                  const Gap(8),
                ],

                // Live API Results Section
                if (_apiResults.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'LIVE SEARCH RESULTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...List.generate(_apiResults.length, (index) {
                    final res = _apiResults[index];
                    final rawItem = _rawApiResults.length > index ? _rawApiResults[index] : null;
                    final address = rawItem?['address'] as Map<String, dynamic>?;
                    final lat = double.tryParse(rawItem?['lat']?.toString() ?? '');
                    final lon = double.tryParse(rawItem?['lon']?.toString() ?? '');
                    final details = LocationHelper.extractDetails(
                      rawLocation: res,
                      addressDetails: address,
                      latitude: lat,
                      longitude: lon,
                    );

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: const Icon(Icons.place_rounded, color: AppColors.primaryBlue, size: 18),
                      title: Text(
                        details.location,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      subtitle: details.city.isNotEmpty
                          ? Text(
                              'Auto-picks: ${details.city}, ${details.state}',
                              style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600),
                            )
                          : null,
                      onTap: () {
                        widget.onSelected(details.location);
                        widget.onDetailsSelected?.call(details);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const Gap(12),
                ],

                // Popular Indian Cities Section
                if (filteredPopular.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                        Gap(6),
                        Text(
                          'POPULAR INDIAN CITIES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...filteredPopular.map(
                    (city) {
                      final details = LocationHelper.extractFromText(city);
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: const Icon(Icons.location_city_rounded, color: AppColors.textSecondary, size: 18),
                        title: Text(
                          details.location,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        subtitle: details.city.isNotEmpty
                            ? Text(
                                'Auto-picks: ${details.city}, ${details.state}',
                                style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600),
                              )
                            : null,
                        trailing: widget.initialValue == city
                            ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 18)
                            : null,
                        onTap: () {
                          widget.onSelected(details.location);
                          widget.onDetailsSelected?.call(details);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ],

                if (query.isNotEmpty && _apiResults.isEmpty && filteredPopular.isEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.location_off_rounded, size: 36, color: Colors.grey.shade400),
                          const Gap(8),
                          Text(
                            'No locations found for "$query"',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const Gap(12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              widget.onSelected(query);
                              Navigator.pop(context);
                            },
                            child: Text('Use "$query" Anyway'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
