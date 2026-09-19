import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class AddEditPropertyScreen extends ConsumerStatefulWidget {
  final String propertyId; // 'new' for adding, otherwise editing

  const AddEditPropertyScreen({super.key, required this.propertyId});

  @override
  ConsumerState<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends ConsumerState<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Intent & Categorization
  String _intent = 'Sale'; // 'Sale' | 'Rent' | 'Lease'
  String _category = 'Residential'; // 'Residential' | 'Commercial' | 'Plot'
  String _propertyType = 'Apartment / Flat';
  String _selectedBhk = '2 BHK'; // '1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5 BHK', '5+ BHK'

  // 2. Title, Description & Location
  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _googleMapUrlCtrl;

  // 3. 99acres Pricing Engine & Confidential Targets
  String _pricingMode = 'Fixed Price'; // 'Fixed Price' | 'Price on Request'
  late TextEditingController _rawPriceCtrl;
  late TextEditingController _negotiablePriceCtrl;
  late TextEditingController _securityDepositCtrl;
  String _priceUnit = 'Cr'; // 'Cr', 'Lakh', 'K', '/mo', '/sqft'
  bool _isPriceNegotiable = false;
  bool _isMaintenanceIncluded = false;
  late TextEditingController _maintenanceCtrl;
  String _maintenanceFreq = 'Per Month';

  // 4. Area & Specifications
  late TextEditingController _areaSqftCtrl;
  late TextEditingController _carpetAreaCtrl;
  int _bathrooms = 2;
  int _balcony = 1;
  int _parking = 1;
  String _furnishedStatus = 'Semi-Furnished'; // 'Unfurnished', 'Semi-Furnished', 'Fully Furnished'
  String _propertyAge = '1-5 Years'; // 'Ready to Move', '0-1 Year', '1-5 Years', '5-10 Years', '10+ Years'

  // 5. Owner Info & KYC (Protected by Privacy Firewall)
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _ownerPhonePrimaryCtrl;
  late TextEditingController _ownerPhoneSecondaryCtrl;
  late TextEditingController _ownerEmailCtrl;
  late TextEditingController _ownerAddressCtrl;
  late TextEditingController _internalNotesCtrl;

  // 6. Visibility
  bool _isPublic = false;

  // 7. Photo Gallery & Amenities
  List<String> _propertyImages = [];
  bool _isUploadingImages = false;
  final List<String> _availableAmenities = [
    'Gym', 'Swimming Pool', '24/7 Security', 'Play Area', 'Club House',
    'Power Backup', 'Lift', 'Covered Parking', 'Garden / Park', 'Sea View', 'EV Charging'
  ];
  List<String> _selectedAmenities = [];

  // Options Lists
  final List<String> _bhkOptions = ['1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5 BHK', '5+ BHK'];
  final List<String> _residentialTypes = ['Apartment / Flat', 'Independent Villa / House', 'Penthouse', 'Studio Apartment'];
  final List<String> _commercialTypes = ['Office Space', 'Retail Shop', 'Showroom', 'Warehouse / Godown'];
  final List<String> _plotTypes = ['Residential Plot', 'Agricultural Land', 'Industrial Land'];

  final List<String> _popularLocations = [
    'Bandra West, Mumbai',
    'BKC (Bandra Kurla Complex), Mumbai',
    'Worli, Mumbai',
    'Juhu, Mumbai',
    'Andheri East, Mumbai',
    'Andheri West, Mumbai',
    'Powai, Mumbai',
    'Lower Parel, Mumbai',
    'Thane West, Mumbai',
    'Cyber City, Gurugram',
    'Golf Course Road, Gurugram',
    'Connaught Place, New Delhi',
    'Vasant Vihar, New Delhi',
    'Noida Sector 62, Noida',
    'Indiranagar, Bangalore',
    'HSR Layout, Bangalore',
    'Koramangala, Bangalore',
    'Whitefield, Bangalore',
    'Gachibowli, Hyderabad',
    'HITECH City, Hyderabad',
    'Koregaon Park, Pune',
  ];

  final List<Map<String, String>> _presetPhotoLibrary = [
    {'title': 'Luxury Living Room', 'url': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000'},
    {'title': 'Modern Kitchen', 'url': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=1000'},
    {'title': 'Master Bedroom Suite', 'url': 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=1000'},
    {'title': 'Sea View Balcony', 'url': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000'},
    {'title': 'Building Facade & Garden', 'url': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=1000'},
    {'title': 'Swimming Pool & Deck', 'url': 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?q=80&w=1000'},
    {'title': 'Clubhouse & Gym', 'url': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1000'},
  ];

  bool get isEditing => widget.propertyId != 'new';
  PropertyModel? existingProp;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    if (isEditing) {
      final properties = ref.read(propertyProvider);
      existingProp = properties.firstWhere((p) => p.id == widget.propertyId, orElse: () => properties.first);
    }

    _intent = existingProp?.purpose ?? existingProp?.type ?? 'Sale';
    _propertyType = existingProp?.propertyType ?? 'Apartment / Flat';
    if (_propertyType.contains('Office') || _propertyType.contains('Shop') || _propertyType.contains('Commercial')) {
      _category = 'Commercial';
    } else if (_propertyType.contains('Plot') || _propertyType.contains('Land')) {
      _category = 'Plot';
    } else {
      _category = 'Residential';
    }

    _selectedBhk = existingProp?.bhk ?? '2 BHK';
    _titleCtrl = TextEditingController(text: existingProp?.title ?? '');
    _descriptionCtrl = TextEditingController(text: existingProp?.description ?? '');
    _locationCtrl = TextEditingController(text: existingProp?.location ?? '');
    _countryCtrl = TextEditingController(text: existingProp?.country.isNotEmpty == true ? existingProp!.country : 'India');
    _stateCtrl = TextEditingController(text: existingProp?.stateName ?? '');
    _cityCtrl = TextEditingController(text: existingProp?.city ?? '');
    _areaCtrl = TextEditingController(text: existingProp?.area ?? '');
    _addressCtrl = TextEditingController(text: existingProp?.address ?? '');
    _googleMapUrlCtrl = TextEditingController(text: existingProp?.googleMapUrl ?? '');

    _areaSqftCtrl = TextEditingController(text: existingProp?.areaSqft.toString() ?? '1250.0');
    _carpetAreaCtrl = TextEditingController(text: (existingProp?.carpetArea != null && existingProp!.carpetArea > 0)
        ? existingProp!.carpetArea.toStringAsFixed(0)
        : ((existingProp?.areaSqft ?? 1250.0) * 0.8).toStringAsFixed(0));

    // Parse existing price into 99acres format
    final rawPriceStr = existingProp?.price ?? '';
    if (rawPriceStr.toLowerCase().contains('request') || rawPriceStr.toLowerCase().contains('contact')) {
      _pricingMode = 'Price on Request';
      _rawPriceCtrl = TextEditingController(text: '');
    } else {
      _pricingMode = 'Fixed Price';
      final cleanNumeric = rawPriceStr.replaceAll(RegExp(r'[^0-9.]'), '');
      _rawPriceCtrl = TextEditingController(text: cleanNumeric.isNotEmpty ? cleanNumeric : '3.5');
      if (rawPriceStr.contains('Cr')) {
        _priceUnit = 'Cr';
      } else if (rawPriceStr.contains('Lakh') || rawPriceStr.contains('L')) {
        _priceUnit = 'Lakh';
      } else if (rawPriceStr.contains('/mo')) {
        _priceUnit = '/mo';
      } else if (rawPriceStr.contains('/sqft')) {
        _priceUnit = '/sqft';
      } else if (rawPriceStr.contains('K')) {
        _priceUnit = 'K';
      }
    }

    _negotiablePriceCtrl = TextEditingController(text: existingProp?.negotiablePrice ?? '');
    _securityDepositCtrl = TextEditingController(text: existingProp?.securityDeposit ?? '');

    _bathrooms = existingProp?.bathrooms ?? 2;
    _balcony = existingProp?.balcony ?? 1;
    _parking = existingProp?.parking ?? 1;
    _furnishedStatus = existingProp?.furnishedStatus ?? 'Semi-Furnished';
    _isPublic = existingProp?.isPublic ?? false;

    _ownerNameCtrl = TextEditingController(text: existingProp?.ownerName ?? '');
    _ownerPhonePrimaryCtrl = TextEditingController(text: existingProp?.ownerPhonePrimary ?? '');
    _ownerPhoneSecondaryCtrl = TextEditingController(text: existingProp?.ownerPhoneSecondary ?? '');
    _ownerEmailCtrl = TextEditingController(text: existingProp?.ownerEmail ?? '');
    _ownerAddressCtrl = TextEditingController(text: existingProp?.ownerAddress ?? '');
    _internalNotesCtrl = TextEditingController(text: existingProp?.internalNotes ?? '');

    _maintenanceCtrl = TextEditingController(text: existingProp?.maintenanceCharges.replaceAll(RegExp(r'[^0-9]'), '') ?? '5000');
    _selectedAmenities = List.from(existingProp?.amenities ?? []);
    _propertyImages = List.from(existingProp?.images ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _countryCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    _googleMapUrlCtrl.dispose();
    _rawPriceCtrl.dispose();
    _negotiablePriceCtrl.dispose();
    _securityDepositCtrl.dispose();
    _areaSqftCtrl.dispose();
    _carpetAreaCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhonePrimaryCtrl.dispose();
    _ownerPhoneSecondaryCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _ownerAddressCtrl.dispose();
    _internalNotesCtrl.dispose();
    _maintenanceCtrl.dispose();
    super.dispose();
  }

  // 99acres Formatted Price String
  String get _formattedPrice {
    if (_pricingMode == 'Price on Request') {
      return 'Price on Request';
    }
    final rawText = _rawPriceCtrl.text.trim();
    if (rawText.isEmpty) return '₹0';

    String suffix = '';
    if (_priceUnit == 'Cr') {
      suffix = 'Cr';
    } else if (_priceUnit == 'Lakh') {
      suffix = 'Lakh';
    } else if (_priceUnit == 'K') {
      suffix = 'K';
    } else if (_priceUnit == '/mo') {
      suffix = '/mo';
    } else if (_priceUnit == '/sqft') {
      suffix = '/sqft';
    }

    final negotiableTag = _isPriceNegotiable ? ' (Negotiable)' : '';
    return '₹$rawText $suffix$negotiableTag'.trim();
  }

  // 99acres Indian Currency Words Formatter (e.g. 1.25 Cr -> One Crore Twenty-Five Lakh Rupees)
  String get _indianWordsPreview {
    if (_pricingMode == 'Price on Request') return 'Price details shared on request';
    final val = double.tryParse(_rawPriceCtrl.text.trim()) ?? 0;
    if (val == 0) return 'Enter price amount';

    if (_priceUnit == 'Cr') {
      return '₹$val Crores ($val Crore Rupees)';
    } else if (_priceUnit == 'Lakh') {
      return '₹$val Lakhs ($val Lakh Rupees)';
    } else if (_priceUnit == 'K') {
      return '₹$val Thousand Rupees';
    } else if (_priceUnit == '/mo') {
      return '₹${val.toStringAsFixed(0)} Monthly Rent';
    } else if (_priceUnit == '/sqft') {
      return '₹$val Per Square Feet';
    }
    return '₹$val';
  }

  void _showLocationSearchPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';
        List<String> apiResults = [];
        bool isLoadingApi = false;
        Timer? debounceTimer;

        void searchNominatim(String query, StateSetter setModalState) {
          debounceTimer?.cancel();
          if (query.trim().length < 2) {
            setModalState(() {
              apiResults = [];
              isLoadingApi = false;
            });
            return;
          }

          setModalState(() {
            isLoadingApi = true;
          });

          debounceTimer = Timer(const Duration(milliseconds: 400), () async {
            try {
              final url = Uri.parse(
                'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&countrycodes=in&limit=10',
              );
              final response = await http.get(url, headers: {
                'User-Agent': 'PropConnectApp/1.0',
              });

              if (response.statusCode == 200) {
                final List parsed = jsonDecode(response.body);
                final List<String> results = parsed.map((item) {
                  final String displayName = item['display_name'] ?? '';
                  return displayName;
                }).where((str) => str.isNotEmpty).toList();

                setModalState(() {
                  apiResults = results;
                  isLoadingApi = false;
                });
              } else {
                setModalState(() => isLoadingApi = false);
              }
            } catch (_) {
              setModalState(() => isLoadingApi = false);
            }
          });
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final popularFiltered = _popularLocations
                .where((loc) => loc.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.map_outlined, color: AppColors.primaryBlue, size: 22),
                          Gap(8),
                          Text(
                            'Search Property Location',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Gap(12),
                  TextField(
                    autofocus: true,
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val;
                      });
                      searchNominatim(val, setModalState);
                    },
                    decoration: InputDecoration(
                      hintText: 'Type city, neighborhood, area or locality...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                      suffixIcon: isLoadingApi
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const Gap(16),

                  if (searchQuery.trim().isNotEmpty && apiResults.isNotEmpty) ...[
                    const Text('Live Location Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    const Gap(8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: apiResults.length + 1,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index < apiResults.length) {
                            final locName = apiResults[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: AppColors.primaryBlue),
                              title: Text(locName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              onTap: () {
                                setState(() {
                                  _locationCtrl.text = locName;
                                });
                                Navigator.pop(context);
                              },
                            );
                          } else {
                            final customLoc = searchQuery.trim();
                            return ListTile(
                              leading: const Icon(Icons.add_location_alt_outlined, color: Colors.green),
                              title: Text('Use custom location "$customLoc"', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                              onTap: () {
                                setState(() {
                                  _locationCtrl.text = customLoc;
                                });
                                Navigator.pop(context);
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    const Text('Popular Real Estate Hubs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const Gap(8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: popularFiltered.length + (searchQuery.trim().isNotEmpty ? 1 : 0),
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index < popularFiltered.length) {
                            final loc = popularFiltered[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryBlue),
                              title: Text(loc, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              onTap: () {
                                setState(() {
                                  _locationCtrl.text = loc;
                                });
                                Navigator.pop(context);
                              },
                            );
                          } else {
                            final customLoc = searchQuery.trim();
                            return ListTile(
                              leading: const Icon(Icons.add_location_alt_outlined, color: Colors.green),
                              title: Text('Use custom location "$customLoc"', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                              onTap: () {
                                setState(() {
                                  _locationCtrl.text = customLoc;
                                });
                                Navigator.pop(context);
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImages({required ImageSource source, bool multi = false}) async {
    final picker = ImagePicker();
    try {
      List<XFile> pickedFiles = [];
      if (source == ImageSource.gallery && multi) {
        pickedFiles = await picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      } else {
        final single = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (single != null) {
          pickedFiles.add(single);
        }
      }

      if (pickedFiles.isEmpty) return;

      setState(() {
        _isUploadingImages = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const Gap(12),
                Text('Uploading ${pickedFiles.length} real photo(s) to server...'),
              ],
            ),
            backgroundColor: AppColors.primaryBlue,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      List<String> b64List = [];
      for (final f in pickedFiles) {
        final bytes = await f.readAsBytes();
        final b64 = base64Encode(bytes);
        final mimeType = f.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        b64List.add('data:$mimeType;base64,$b64');
      }

      final res = await ApiService.post('/upload/base64', {
        if (b64List.length == 1) ...{
          'image': b64List.first,
          'filename': pickedFiles.first.name,
        } else ...{
          'images': b64List,
        }
      });

      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'];
        List<String> newUrls = [];
        if (data is Map<String, dynamic>) {
          if (data['url'] != null) {
            newUrls.add(data['url'].toString());
          } else if (data['urls'] is List) {
            newUrls.addAll((data['urls'] as List).map((u) => u.toString()));
          }
        }

        setState(() {
          _propertyImages.addAll(newUrls);
          _isUploadingImages = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded ${newUrls.length} real photo(s)!'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        setState(() {
          _isUploadingImages = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Failed to upload photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerModal() {
    final customUrlCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue, size: 22),
                        Gap(8),
                        Text('Add Property Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(16),

                // Real Device File Upload Options
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUploadImages(source: ImageSource.gallery, multi: true);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue, size: 30),
                              Gap(8),
                              Text('Choose Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                              Gap(2),
                              Text('Select real photos', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUploadImages(source: ImageSource.camera);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.camera_alt_rounded, color: Colors.teal, size: 30),
                              Gap(8),
                              Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                              Gap(2),
                              Text('Use camera now', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Gap(20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR PASTE IMAGE URL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const Gap(12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customUrlCtrl,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/photo.jpg',
                          prefixIcon: const Icon(Icons.link, color: AppColors.iconColor),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const Gap(8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final url = customUrlCtrl.text.trim();
                        if (url.isNotEmpty) {
                          setState(() {
                            _propertyImages.add(url);
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo added to gallery!'), backgroundColor: Colors.teal),
                          );
                        }
                      },
                      child: const Text('Add URL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const Gap(20),
                const Text('Or Select Sample HD Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const Gap(8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetPhotoLibrary.length,
                    separatorBuilder: (context, index) => const Gap(10),
                    itemBuilder: (context, index) {
                      final item = _presetPhotoLibrary[index];
                      final isAlreadyAdded = _propertyImages.contains(item['url']);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isAlreadyAdded) {
                              _propertyImages.remove(item['url']);
                            } else {
                              _propertyImages.add(item['url']!);
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 125,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isAlreadyAdded ? AppColors.primaryBlue : AppColors.border, width: isAlreadyAdded ? 2 : 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Image.network(
                                item['url']!,
                                height: 160,
                                width: 125,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  color: Colors.black.withValues(alpha: 0.75),
                                  child: Text(
                                    item['title']!,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (isAlreadyAdded)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      final userData = AuthStorageService.getUserData();
      final userAgency = userData?['agency'] as Map<String, dynamic>?;
      final userAgencyId = userData?['agencyId'] ?? userAgency?['id'];
      final userAgencyName = (userAgency?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? (userData?['name'] != null ? '${userData!['name']}\'s Agency' : 'Partner Agency');
      final userName = (userData?['name'] as String?) ?? 'Broker';

      // Auto-generate title if empty
      String title = _titleCtrl.text.trim();
      if (title.isEmpty) {
        if (_category == 'Residential') {
          title = 'Luxury $_selectedBhk $_propertyType in ${_locationCtrl.text.split(',').first}';
        } else {
          title = 'Prime $_propertyType in ${_locationCtrl.text.split(',').first}';
        }
      }

      final maintenanceStr = _maintenanceCtrl.text.trim().isNotEmpty
          ? '₹${_maintenanceCtrl.text.trim()} / ${_maintenanceFreq.toLowerCase()}'
          : '₹0';

      final newProp = PropertyModel(
        id: isEditing ? existingProp!.id : 'PR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        title: title,
        description: _descriptionCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        price: _formattedPrice,
        negotiablePrice: _negotiablePriceCtrl.text.trim(),
        securityDeposit: _securityDepositCtrl.text.trim(),
        bhk: _category == 'Residential' ? _selectedBhk : 'N/A',
        type: _intent == 'Lease' ? 'Rent' : _intent,
        purpose: _intent,
        isPublic: _isPublic,
        agencyId: existingProp?.agencyId ?? (userAgencyId != null ? int.tryParse(userAgencyId.toString()) : null),
        agencyName: existingProp?.agencyName ?? userAgencyName,
        propertyType: _propertyType,
        status: existingProp?.status ?? 'Available',
        brokerName: existingProp?.brokerName ?? userName,
        country: _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : 'India',
        stateName: _stateCtrl.text.trim(),
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : (_locationCtrl.text.split(',').length > 1 ? _locationCtrl.text.split(',').last.trim() : ''),
        area: _areaCtrl.text.trim().isNotEmpty ? _areaCtrl.text.trim() : _locationCtrl.text.split(',').first.trim(),
        address: _addressCtrl.text.trim(),
        googleMapUrl: _googleMapUrlCtrl.text.trim(),
        bathrooms: _bathrooms,
        balcony: _balcony,
        parking: _parking,
        furnishedStatus: _furnishedStatus,
        propertyAge: 0,
        areaSqft: double.tryParse(_areaSqftCtrl.text) ?? 1000.0,
        carpetArea: double.tryParse(_carpetAreaCtrl.text) ?? ((double.tryParse(_areaSqftCtrl.text) ?? 1000.0) * 0.8),
        maintenanceCharges: maintenanceStr,
        amenities: _selectedAmenities,
        images: _propertyImages,
        ownerName: _ownerNameCtrl.text.trim(),
        ownerPhonePrimary: _ownerPhonePrimaryCtrl.text.trim(),
        ownerPhoneSecondary: _ownerPhoneSecondaryCtrl.text.trim(),
        ownerEmail: _ownerEmailCtrl.text.trim(),
        ownerAddress: _ownerAddressCtrl.text.trim(),
        internalNotes: _internalNotesCtrl.text.trim(),
      );

      if (isEditing) {
        await ref.read(propertyProvider.notifier).updateProperty(newProp);
      } else {
        await ref.read(propertyProvider.notifier).addProperty(newProp);
      }

      if (!mounted) return;

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Property Updated Successfully!' : 'Property Published Successfully to Database!'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<String> get _currentPropertyTypes {
    if (_category == 'Residential') return _residentialTypes;
    if (_category == 'Commercial') return _commercialTypes;
    return _plotTypes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(isEditing ? 'Edit Property Listing' : 'Post Property Listing', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // STEP 1: INTENT & CATEGORY (99acres Flow)
            _buildSectionCard(
              title: '1. Property Type & Intent',
              icon: Icons.real_estate_agent_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('I Want To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Sell Property')),
                          selected: _intent == 'Sale',
                          onSelected: (selected) {
                            if (selected) setState(() => _intent = 'Sale');
                          },
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          labelStyle: TextStyle(color: _intent == 'Sale' ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Rent Out')),
                          selected: _intent == 'Rent',
                          onSelected: (selected) {
                            if (selected) setState(() => _intent = 'Rent');
                          },
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          labelStyle: TextStyle(color: _intent == 'Rent' ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Lease')),
                          selected: _intent == 'Lease',
                          onSelected: (selected) {
                            if (selected) setState(() => _intent = 'Lease');
                          },
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          labelStyle: TextStyle(color: _intent == 'Lease' ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Gap(18),

                  const Text('Property Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const Gap(8),
                  Row(
                    children: ['Residential', 'Commercial', 'Plot'].map((cat) {
                      final isSel = _category == cat;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: FittedBox(child: Text(cat)),
                            selected: isSel,
                            onSelected: (s) {
                              if (s) {
                                setState(() {
                                  _category = cat;
                                  _propertyType = _currentPropertyTypes.first;
                                });
                              }
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(18),

                  const Text('Property Sub-Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const Gap(8),
                  DropdownButtonFormField<String>(
                    initialValue: _currentPropertyTypes.contains(_propertyType) ? _propertyType : _currentPropertyTypes.first,
                    items: _currentPropertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _propertyType = v);
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.apartment_outlined, color: AppColors.primaryBlue, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  if (_category == 'Residential') ...[
                    const Gap(20),
                    const Text('BHK Configuration (Select BHK Chip)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bhkOptions.map((bhk) {
                        final isSel = _selectedBhk == bhk;
                        return ChoiceChip(
                          label: Text(bhk),
                          selected: isSel,
                          onSelected: (s) {
                            if (s) setState(() => _selectedBhk = bhk);
                          },
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(color: isSel ? AppColors.primaryBlue : AppColors.border),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(20),

            // STEP 2: LOCATION & TITLE
            _buildSectionCard(
              title: '2. Location & Structured Address',
              icon: Icons.location_on_outlined,
              child: Column(
                children: [
                  _buildLocationField(),
                  const Gap(14),
                  TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Property Title / Headline (Optional)',
                      hintText: 'e.g. Sea Face 3 BHK Luxury Apartment',
                      prefixIcon: const Icon(Icons.title_outlined, color: AppColors.iconColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                    ),
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: InputDecoration(
                            labelText: 'City',
                            hintText: 'e.g. Mumbai',
                            prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.iconColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: TextFormField(
                          controller: _stateCtrl,
                          decoration: InputDecoration(
                            labelText: 'State',
                            hintText: 'e.g. Maharashtra',
                            prefixIcon: const Icon(Icons.map_outlined, color: AppColors.iconColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Street Address / Building Name',
                      hintText: 'e.g. Tower B, Flat 1402, Oberoi Sky City',
                      prefixIcon: const Icon(Icons.home_outlined, color: AppColors.iconColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _googleMapUrlCtrl,
                    decoration: InputDecoration(
                      labelText: 'Google Maps Pin URL (Optional)',
                      hintText: 'https://maps.google.com/?q=...',
                      prefixIcon: const Icon(Icons.pin_drop_outlined, color: AppColors.iconColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // STEP 3: 99ACRES INDIAN PRICING ENGINE
            _buildSectionCard(
              title: '3. Pricing & Maintenance (INR ₹)',
              icon: Icons.currency_rupee,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Fixed Price')),
                          selected: _pricingMode == 'Fixed Price',
                          onSelected: (s) {
                            if (s) setState(() => _pricingMode = 'Fixed Price');
                          },
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          labelStyle: TextStyle(color: _pricingMode == 'Fixed Price' ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Price on Request')),
                          selected: _pricingMode == 'Price on Request',
                          onSelected: (s) {
                            if (s) setState(() => _pricingMode = 'Price on Request');
                          },
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          labelStyle: TextStyle(color: _pricingMode == 'Price on Request' ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  if (_pricingMode == 'Fixed Price') ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _rawPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) => setState(() {}),
                            validator: (val) {
                              if (_pricingMode == 'Fixed Price' && (val == null || val.trim().isEmpty)) {
                                return 'Enter price';
                              }
                              return null;
                            },
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Price Amount',
                              hintText: 'e.g. 1.25 or 85',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('₹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _priceUnit,
                            items: const [
                              DropdownMenuItem(value: 'Cr', child: Text('Crore (Cr)')),
                              DropdownMenuItem(value: 'Lakh', child: Text('Lakh (L)')),
                              DropdownMenuItem(value: 'K', child: Text('Thousand (K)')),
                              DropdownMenuItem(value: '/mo', child: Text('/ Month')),
                              DropdownMenuItem(value: '/sqft', child: Text('/ Sqft')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _priceUnit = val);
                            },
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),

                    // 99acres Indian Currency Words Formatter Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('99acres Indian Price Format:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          const Gap(4),
                          Text(
                            _indianWordsPreview,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),

                    Row(
                      children: [
                        Checkbox(
                          value: _isPriceNegotiable,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (v) => setState(() => _isPriceNegotiable = v ?? false),
                        ),
                        const Text('Price Negotiable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Checkbox(
                          value: _isMaintenanceIncluded,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (v) => setState(() => _isMaintenanceIncluded = v ?? false),
                        ),
                        const Text('All-Inclusive', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const Gap(16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maintenanceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Maintenance Charges (₹)',
                            hintText: 'e.g. 5000',
                            prefixIcon: const Icon(Icons.build_circle_outlined, color: AppColors.iconColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _maintenanceFreq,
                          items: const [
                            DropdownMenuItem(value: 'Per Month', child: Text('Per Month')),
                            DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                            DropdownMenuItem(value: 'Per Year', child: Text('Per Year')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _maintenanceFreq = v);
                          },
                          decoration: InputDecoration(
                            labelText: 'Frequency',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_intent == 'Rent' || _intent == 'Lease') ...[
                    const Gap(14),
                    TextFormField(
                      controller: _securityDepositCtrl,
                      decoration: InputDecoration(
                        labelText: 'Security Deposit (₹)',
                        hintText: 'e.g. ₹2,00,000',
                        prefixIcon: const Icon(Icons.security_outlined, color: AppColors.iconColor, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ],

                  const Gap(14),
                  TextFormField(
                    controller: _negotiablePriceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Confidential Minimum Target Price (₹)',
                      hintText: 'e.g. ₹1.15 Cr (Internal Agency Floor)',
                      helperText: 'Confidential: Hidden from external collaborating brokers.',
                      helperStyle: const TextStyle(color: AppColors.primaryBlue, fontSize: 11),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFEFF6FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBFDBFE))),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // STEP 4: AREA & SPECIFICATIONS
            _buildSectionCard(
              title: '4. Area & Specifications',
              icon: Icons.square_foot_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _areaSqftCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Super area required' : null,
                          decoration: InputDecoration(
                            labelText: 'Super Built-up Area (Sqft)',
                            hintText: 'e.g. 1500',
                            prefixIcon: const Icon(Icons.straighten, color: AppColors.iconColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: TextFormField(
                          controller: _carpetAreaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Carpet Area (Sqft)',
                            hintText: 'e.g. 1200',
                            prefixIcon: const Icon(Icons.crop_free, color: AppColors.iconColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(18),

                  const Text('Bathrooms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const Gap(8),
                  Row(
                    children: [1, 2, 3, 4, 5].map((count) {
                      final isSel = _bathrooms == count;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text('$count'),
                            selected: isSel,
                            onSelected: (s) {
                              if (s) setState(() => _bathrooms = count);
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(14),

                  const Text('Balconies', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const Gap(8),
                  Row(
                    children: [0, 1, 2, 3, 4].map((count) {
                      final isSel = _balcony == count;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text('$count'),
                            selected: isSel,
                            onSelected: (s) {
                              if (s) setState(() => _balcony = count);
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(16),

                  DropdownButtonFormField<String>(
                    initialValue: _furnishedStatus,
                    items: const [
                      DropdownMenuItem(value: 'Unfurnished', child: Text('Unfurnished')),
                      DropdownMenuItem(value: 'Semi-Furnished', child: Text('Semi-Furnished')),
                      DropdownMenuItem(value: 'Fully Furnished', child: Text('Fully Furnished')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _furnishedStatus = v);
                    },
                    decoration: InputDecoration(
                      labelText: 'Furnishing Status',
                      prefixIcon: const Icon(Icons.chair_outlined, color: AppColors.primaryBlue, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const Gap(14),

                  DropdownButtonFormField<String>(
                    initialValue: _propertyAge,
                    items: const [
                      DropdownMenuItem(value: 'Ready to Move', child: Text('Ready to Move / New')),
                      DropdownMenuItem(value: '0-1 Year', child: Text('0-1 Year Old')),
                      DropdownMenuItem(value: '1-5 Years', child: Text('1-5 Years Old')),
                      DropdownMenuItem(value: '5-10 Years', child: Text('5-10 Years Old')),
                      DropdownMenuItem(value: '10+ Years', child: Text('10+ Years Old')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _propertyAge = v);
                    },
                    decoration: InputDecoration(
                      labelText: 'Property Age / Possession',
                      prefixIcon: const Icon(Icons.history_outlined, color: AppColors.primaryBlue, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // STEP 5: DESCRIPTION & OVERVIEW
            _buildSectionCard(
              title: '5. Description & Overview',
              icon: Icons.description_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Property Description',
                      hintText: 'Enter comprehensive property highlights, architecture, connectivity...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // STEP 6: PHOTO GALLERY & AMENITIES
            _buildSectionCard(
              title: '6. Photo Gallery & Amenities',
              icon: Icons.photo_library_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Property Photos (${_propertyImages.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue, size: 20),
                            tooltip: 'Pick from Gallery',
                            onPressed: _isUploadingImages ? null : () => _pickAndUploadImages(source: ImageSource.gallery, multi: true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, color: Colors.teal, size: 20),
                            tooltip: 'Take Photo',
                            onPressed: _isUploadingImages ? null : () => _pickAndUploadImages(source: ImageSource.camera),
                          ),
                          const Gap(4),
                          OutlinedButton(
                            onPressed: _isUploadingImages ? null : _showImagePickerModal,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: const BorderSide(color: AppColors.primaryBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('+ Options', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(12),

                  if (_isUploadingImages)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                          ),
                          Gap(12),
                          Expanded(
                            child: Text(
                              'Uploading real photo(s) to Hostinger server...',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_propertyImages.isEmpty)
                    GestureDetector(
                      onTap: _isUploadingImages ? null : _showImagePickerModal,
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 38, color: AppColors.primaryBlue),
                            Gap(6),
                            Text('No photos uploaded yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Gap(2),
                            Text('Tap to select from Gallery, Camera, or Presets', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _propertyImages.length + 1,
                        separatorBuilder: (context, index) => const Gap(10),
                        itemBuilder: (context, index) {
                          if (index == _propertyImages.length) {
                            return GestureDetector(
                              onTap: _isUploadingImages ? null : _showImagePickerModal,
                              child: Container(
                                width: 100,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 28),
                                    Gap(4),
                                    Text('Add More', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final imgUrl = _propertyImages[index];
                          final isCover = index == 0;

                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isCover ? AppColors.primaryBlue : AppColors.border, width: isCover ? 2 : 1),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.apartment, color: AppColors.primaryBlue)),
                                ),
                              ),
                              if (isCover)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Cover Photo', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _propertyImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const Gap(20),

                  const Text('Select Key Amenities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Gap(10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primaryBlue,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.border),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // STEP 7: OWNER INFORMATION & KYC (PRIVACY FIREWALL)
            _buildSectionCard(
              title: '7. Owner Information & KYC (Confidential)',
              icon: Icons.shield_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_rounded, color: AppColors.primaryBlue, size: 18),
                        Gap(10),
                        Expanded(
                          child: Text(
                            'PRD Lead Privacy Firewall: Owner identity and contact numbers are confidential to your agency and will NEVER be revealed to outside collaborating brokers.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _ownerNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Owner Full Name',
                      hintText: 'e.g. Ramesh Chandra Sharma',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.iconColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ownerPhonePrimaryCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Primary Phone',
                            hintText: '+91 98200 12345',
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.iconColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: TextFormField(
                          controller: _ownerPhoneSecondaryCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Secondary Phone',
                            hintText: '+91 98200 54321',
                            prefixIcon: const Icon(Icons.phone_iphone_outlined, color: AppColors.iconColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _ownerEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Owner Email Address',
                      hintText: 'ramesh.sharma@gmail.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.iconColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _ownerAddressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Owner Registered Address',
                      hintText: 'Current residential address of owner',
                      prefixIcon: const Icon(Icons.home_work_outlined, color: AppColors.iconColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _internalNotesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Private Agency Notes',
                      hintText: 'Internal deal points, keys location, owner availability...',
                      prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.iconColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // STEP 8: VISIBILITY & SHARING
            _buildSectionCard(
              title: '8. Visibility & Network Sharing',
              icon: Icons.visibility_outlined,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Make Property ${_isPublic ? 'Public' : 'Private'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Gap(4),
                          Text(
                            _isPublic ? 'Visible to external brokers for collaboration requests.' : 'Only visible to internal brokers within your agency.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.primaryBlue,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(32),

            // SUBMIT BUTTON
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _saveProperty,
                child: Text(
                  isEditing ? 'Save Changes' : 'Publish Property to Network',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const Gap(8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationCtrl,
      readOnly: true,
      onTap: _showLocationSearchPicker,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Location is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Location / City',
        hintText: 'Search & select locality...',
        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.iconColor, size: 20),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.iconColor),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        errorStyle: const TextStyle(color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      ),
    );
  }
}
