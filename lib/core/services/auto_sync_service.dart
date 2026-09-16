import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';
import '../network/api_service.dart';
import '../providers/data_providers.dart';
import 'auth_storage_service.dart';

class FeedFetchResult {
  final bool isRealFeed;
  final bool isSuccess;
  final String? errorMessage;
  final List<Map<String, dynamic>> listings;

  const FeedFetchResult({
    required this.isRealFeed,
    required this.isSuccess,
    this.errorMessage,
    required this.listings,
  });
}

class AutoSyncConfig {
  final String platform;
  final String frequency; // 'Realtime Webhook' | 'Daily Auto-Sync' | 'Manual Sync Only'
  final String apiKey;
  final String feedUrl;
  final bool isEnabled;
  final DateTime? lastSyncedAt;

  AutoSyncConfig({
    required this.platform,
    required this.frequency,
    required this.apiKey,
    required this.feedUrl,
    required this.isEnabled,
    this.lastSyncedAt,
  });

  factory AutoSyncConfig.fromMap(Map<String, dynamic> map) {
    return AutoSyncConfig(
      platform: map['platform'] as String? ?? '99acres',
      frequency: map['frequency'] as String? ?? 'Daily Auto-Sync',
      apiKey: map['apiKey'] as String? ?? '',
      feedUrl: map['feedUrl'] as String? ?? '',
      isEnabled: map['isEnabled'] as bool? ?? false,
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.tryParse(map['lastSyncedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'frequency': frequency,
      'apiKey': apiKey,
      'feedUrl': feedUrl,
      'isEnabled': isEnabled,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  AutoSyncConfig copyWith({
    String? platform,
    String? frequency,
    String? apiKey,
    String? feedUrl,
    bool? isEnabled,
    DateTime? lastSyncedAt,
  }) {
    return AutoSyncConfig(
      platform: platform ?? this.platform,
      frequency: frequency ?? this.frequency,
      apiKey: apiKey ?? this.apiKey,
      feedUrl: feedUrl ?? this.feedUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class AutoSyncState {
  final AutoSyncConfig? config;
  final bool isSyncing;
  final String? lastMessage;

  AutoSyncState({
    this.config,
    this.isSyncing = false,
    this.lastMessage,
  });

  AutoSyncState copyWith({
    AutoSyncConfig? config,
    bool? isSyncing,
    String? lastMessage,
  }) {
    return AutoSyncState(
      config: config ?? this.config,
      isSyncing: isSyncing ?? this.isSyncing,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class AutoSyncNotifier extends Notifier<AutoSyncState> {
  Timer? _periodicTimer;

  @override
  AutoSyncState build() {
    final raw = AuthStorageService.getAutoSyncConfig();
    AutoSyncConfig? config;
    if (raw != null) {
      config = AutoSyncConfig.fromMap(raw);
    }
    
    // Start background check timer
    _startPeriodicChecker();

    ref.onDispose(() {
      _periodicTimer?.cancel();
    });

    return AutoSyncState(config: config);
  }

  void _startPeriodicChecker() {
    _periodicTimer?.cancel();
    // Check every 5 minutes if a scheduled sync is due
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      checkAndRunScheduledSync();
    });
  }

  /// Checks whether a sync is due based on the configured frequency
  Future<void> checkAndRunScheduledSync() async {
    final config = state.config;
    if (config == null || !config.isEnabled || config.lastSyncedAt == null) return;
    if (config.frequency == 'Manual Sync Only') return;

    final now = DateTime.now();
    final elapsed = now.difference(config.lastSyncedAt!);

    bool shouldSync = false;
    if (config.frequency == 'Realtime Webhook') {
      // For real-time webhook mode, sync if more than 15 minutes since last sync
      shouldSync = elapsed.inMinutes >= 15;
    } else if (config.frequency == 'Daily Auto-Sync') {
      // For daily auto-sync, sync if more than 24 hours (or 1 day) since last sync
      shouldSync = elapsed.inHours >= 24;
    }

    if (shouldSync && !state.isSyncing) {
      debugPrint('[AutoSync] Scheduled auto-sync triggered for ${config.platform} (${config.frequency})');
      await syncFeedNow();
    }
  }

  /// Update the auto-sync configuration and persist to storage
  Future<void> updateConfig({
    required String platform,
    required String frequency,
    required String apiKey,
    required String feedUrl,
    required bool isEnabled,
  }) async {
    final now = DateTime.now();
    final newConfig = AutoSyncConfig(
      platform: platform,
      frequency: frequency,
      apiKey: apiKey,
      feedUrl: feedUrl,
      isEnabled: isEnabled,
      lastSyncedAt: now,
    );

    await AuthStorageService.saveAutoSyncConfig(
      platform: platform,
      frequency: frequency,
      apiKey: apiKey,
      feedUrl: feedUrl,
      isEnabled: isEnabled,
      lastSyncedAt: now,
    );

    state = state.copyWith(config: newConfig);
  }

  /// Triggers a live sync from the selected partner feed into PostgreSQL
  Future<bool> syncFeedNow() async {
    final config = state.config;
    final platform = config?.platform ?? '99acres';

    state = state.copyWith(isSyncing: true, lastMessage: 'Connecting to $platform feed...');

    try {
      final userData = AuthStorageService.getUserData();
      final userAgency = userData?['agency'] as Map<String, dynamic>?;
      final userAgencyName = (userAgency?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? (userData?['agency_name'] as String?) ?? '';
      final userAgencyId = userData?['agencyId'] ?? userData?['agency_id'] ?? userAgency?['id'];
      final userName = (userData?['name'] as String?) ?? '';
      final parsedAgencyId = userAgencyId != null ? int.tryParse(userAgencyId.toString()) : null;

      // Fetch listings: from real live HTTP endpoint if modified, or template if default
      final feedResult = await fetchFeedListings(
        platform: platform,
        feedUrl: config?.feedUrl ?? '',
        apiKey: config?.apiKey ?? '',
      );

      if (!feedResult.isSuccess && feedResult.isRealFeed) {
        state = state.copyWith(
          isSyncing: false,
          lastMessage: feedResult.errorMessage ?? 'Failed to fetch from live feed endpoint',
        );
        return false;
      }

      final sampleList = feedResult.listings;

      final payload = <String, dynamic>{
        'platform': platform,
        'syncFrequency': config?.frequency ?? 'Realtime Webhook',
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
        final now = DateTime.now();
        await AuthStorageService.updateLastSyncedAt(now);

        if (config != null) {
          state = state.copyWith(
            config: config.copyWith(lastSyncedAt: now),
            isSyncing: false,
            lastMessage: 'Synced ${sampleList.length} listings from $platform',
          );
        } else {
          final defaultConfig = AutoSyncConfig(
            platform: platform,
            frequency: 'Realtime Webhook',
            apiKey: 'AUTO-KEY',
            feedUrl: 'https://feed.$platform.com',
            isEnabled: true,
            lastSyncedAt: now,
          );
          await AuthStorageService.saveAutoSyncConfig(
            platform: platform,
            frequency: defaultConfig.frequency,
            apiKey: defaultConfig.apiKey,
            feedUrl: defaultConfig.feedUrl,
            isEnabled: true,
            lastSyncedAt: now,
          );
          state = state.copyWith(
            config: defaultConfig,
            isSyncing: false,
            lastMessage: 'Synced ${sampleList.length} listings from $platform',
          );
        }

        // Add newly imported properties to state immediately
        if (res['data'] != null && res['data'] is List) {
          final list = (res['data'] as List)
              .map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          ref.read(propertyProvider.notifier).addImportedProperties(list);
        }

        // Fetch to ensure full sync with PostgreSQL
        ref.read(propertyProvider.notifier).fetchProperties();
        return true;
      } else {
        state = state.copyWith(
          isSyncing: false,
          lastMessage: res['message'] ?? 'Sync failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastMessage: 'Sync error: $e',
      );
      return false;
    }
  }

  /// Determines if a URL is a default template placeholder
  static bool isTemplateUrl(String url) {
    final clean = url.trim().toLowerCase();
    if (clean.isEmpty) return true;
    if (clean.contains('feed.99acres.com') ||
        clean.contains('feed.magicbricks.com') ||
        clean.contains('feed.housing.com') ||
        clean.contains('feed.customapi.com')) {
      return true;
    }
    return false;
  }

  /// Fetches listings: performs live HTTP GET request if actual link is provided,
  /// or returns pre-configured template listings if placeholder URL is used.
  static Future<FeedFetchResult> fetchFeedListings({
    required String platform,
    required String feedUrl,
    required String apiKey,
  }) async {
    final cleanUrl = feedUrl.trim();

    // 1. If empty or known template URL, return platform template listings
    if (isTemplateUrl(cleanUrl)) {
      return FeedFetchResult(
        isRealFeed: false,
        isSuccess: true,
        listings: getPlatformSampleListings(platform),
      );
    }

    // 2. Real link: execute genuine live HTTP request
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return const FeedFetchResult(
        isRealFeed: true,
        isSuccess: false,
        errorMessage: 'Invalid feed URL format. Please start with https:// or http://',
        listings: [],
      );
    }

    try {
      final headers = <String, String>{
        'Accept': 'application/json, text/plain, */*',
      };
      final cleanKey = apiKey.trim();
      if (cleanKey.isNotEmpty && !cleanKey.contains('API-KEY') && !cleanKey.contains('API-SEC')) {
        headers['Authorization'] = cleanKey.startsWith('Bearer ') ? cleanKey : 'Bearer $cleanKey';
        headers['X-API-Key'] = cleanKey;
        headers['ApiKey'] = cleanKey;
      }

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bodyText = response.body.trim();
        if (bodyText.isEmpty) {
          return const FeedFetchResult(
            isRealFeed: true,
            isSuccess: false,
            errorMessage: 'Endpoint returned an empty response body.',
            listings: [],
          );
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(bodyText);
        } catch (_) {
          return const FeedFetchResult(
            isRealFeed: true,
            isSuccess: false,
            errorMessage: 'Response from endpoint is not valid JSON. Ensure endpoint returns JSON property listings.',
            listings: [],
          );
        }

        List<dynamic> rawListings = [];
        if (decoded is List) {
          rawListings = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final candidate = map['properties'] ??
              map['data'] ??
              map['listings'] ??
              map['results'] ??
              map['items'] ??
              map['feed'];

          if (candidate is List) {
            rawListings = candidate;
          } else if (map.containsKey('title') || map.containsKey('name') || map.containsKey('price')) {
            // Single property object
            rawListings = [map];
          }
        }

        if (rawListings.isEmpty) {
          return const FeedFetchResult(
            isRealFeed: true,
            isSuccess: false,
            errorMessage: 'No listings found in feed response. Ensure response contains a list of properties.',
            listings: [],
          );
        }

        final parsedListings = rawListings
            .whereType<Map>()
            .map((item) => normalizeFeedProperty(Map<String, dynamic>.from(item)))
            .toList();

        return FeedFetchResult(
          isRealFeed: true,
          isSuccess: true,
          listings: parsedListings,
        );
      } else {
        return FeedFetchResult(
          isRealFeed: true,
          isSuccess: false,
          errorMessage: 'Endpoint returned HTTP ${response.statusCode} (${response.reasonPhrase}). Verify your API key and URL.',
          listings: [],
        );
      }
    } on TimeoutException {
      return const FeedFetchResult(
        isRealFeed: true,
        isSuccess: false,
        errorMessage: 'Connection timed out after 15 seconds. Ensure the server is online and accessible.',
        listings: [],
      );
    } catch (e) {
      return FeedFetchResult(
        isRealFeed: true,
        isSuccess: false,
        errorMessage: 'Could not connect to endpoint: $e',
        listings: [],
      );
    }
  }

  /// Normalizes arbitrary property JSON keys into standard PropConnect property maps
  static Map<String, dynamic> normalizeFeedProperty(Map<String, dynamic> raw) {
    // Title
    final title = raw['title']?.toString() ??
        raw['name']?.toString() ??
        raw['propertyName']?.toString() ??
        raw['headline']?.toString() ??
        'Imported Property';

    // Location
    final location = raw['location']?.toString() ??
        raw['address']?.toString() ??
        raw['locality']?.toString() ??
        raw['city']?.toString() ??
        'Mumbai, Maharashtra';

    // Price
    String price = 'Price on Request';
    if (raw['price'] != null) {
      price = raw['price'].toString();
      if (!price.startsWith('₹') && !price.toLowerCase().contains('cr') && !price.toLowerCase().contains('lakh')) {
        price = '₹$price';
      }
    } else if (raw['cost'] != null) {
      price = '₹${raw['cost']}';
    } else if (raw['amount'] != null) {
      price = '₹${raw['amount']}';
    }

    // BHK
    String bhk = '2 BHK';
    if (raw['bhk'] != null) {
      bhk = raw['bhk'].toString();
    } else if (raw['bedrooms'] != null) {
      bhk = '${raw['bedrooms']} BHK';
    }

    // Type
    final type = raw['type']?.toString() ??
        raw['listingType']?.toString() ??
        (raw['forRent'] == true ? 'Rent' : 'Sale');

    // Property Type
    final propertyType = raw['propertyType']?.toString() ??
        raw['category']?.toString() ??
        raw['typeOfProperty']?.toString() ??
        'Apartment';

    // Area
    final areaSqft = int.tryParse(raw['areaSqft']?.toString() ?? '') ??
        int.tryParse(raw['area']?.toString() ?? '') ??
        int.tryParse(raw['superArea']?.toString() ?? '') ??
        int.tryParse(raw['carpetArea']?.toString() ?? '') ??
        1200;

    // Bathrooms
    final bathrooms = int.tryParse(raw['bathrooms']?.toString() ?? '') ??
        int.tryParse(raw['baths']?.toString() ?? '') ??
        2;

    // Balcony
    final balcony = int.tryParse(raw['balcony']?.toString() ?? '') ??
        int.tryParse(raw['balconies']?.toString() ?? '') ??
        1;

    // Parking
    final parking = int.tryParse(raw['parking']?.toString() ?? '') ??
        int.tryParse(raw['carParking']?.toString() ?? '') ??
        1;

    // Furnished
    final furnishedStatus = raw['furnishedStatus']?.toString() ??
        raw['furnishing']?.toString() ??
        'Semi-Furnished';

    // Maintenance
    final maintenanceCharges = raw['maintenanceCharges']?.toString() ??
        raw['maintenance']?.toString() ??
        '₹3,500/mo';

    // Amenities
    List<String> amenities = ['Gym', 'Security', 'Lift', 'Power Backup'];
    if (raw['amenities'] is List) {
      amenities = (raw['amenities'] as List).map((e) => e.toString()).toList();
    } else if (raw['features'] is List) {
      amenities = (raw['features'] as List).map((e) => e.toString()).toList();
    } else if (raw['amenities'] is String) {
      amenities = (raw['amenities'] as String).split(',').map((e) => e.trim()).toList();
    }

    // Images
    List<String> images = ['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000'];
    if (raw['images'] is List && (raw['images'] as List).isNotEmpty) {
      images = (raw['images'] as List).map((e) => e.toString()).toList();
    } else if (raw['photos'] is List && (raw['photos'] as List).isNotEmpty) {
      images = (raw['photos'] as List).map((e) => e.toString()).toList();
    } else if (raw['image'] is String && (raw['image'] as String).isNotEmpty) {
      images = [raw['image'] as String];
    } else if (raw['photo'] is String && (raw['photo'] as String).isNotEmpty) {
      images = [raw['photo'] as String];
    }

    return {
      'title': title,
      'location': location,
      'price': price,
      'bhk': bhk,
      'type': type,
      'propertyType': propertyType,
      'areaSqft': areaSqft,
      'bathrooms': bathrooms,
      'balcony': balcony,
      'parking': parking,
      'furnishedStatus': furnishedStatus,
      'maintenanceCharges': maintenanceCharges,
      'amenities': amenities,
      'images': images,
    };
  }

  static List<Map<String, dynamic>> getPlatformSampleListings(String platform) {
    if (platform == 'MagicBricks') {
      return [
        {
          'title': 'MagicBricks Prime: Modern 2 BHK Apartment',
          'location': 'BKC (Bandra Kurla Complex), Mumbai',
          'price': '₹2.8 Cr',
          'bhk': '2 BHK',
          'type': 'Sale',
          'propertyType': 'Apartment',
          'areaSqft': 1150,
          'bathrooms': 2,
          'balcony': 1,
          'parking': 1,
          'furnishedStatus': 'Semi-Furnished',
          'maintenanceCharges': '₹5,500/mo',
          'amenities': ['Gym', 'Lift', 'Security', 'Power Backup'],
          'images': ['https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=1000'],
        },
        {
          'title': 'MagicBricks Prime: Commercial Office Space',
          'location': 'Lower Parel, Mumbai',
          'price': '₹1.5 Lakh /mo',
          'bhk': 'N/A',
          'type': 'Rent',
          'propertyType': 'Office Space',
          'areaSqft': 1500,
          'bathrooms': 2,
          'balcony': 0,
          'parking': 2,
          'furnishedStatus': 'Fully Furnished',
          'maintenanceCharges': '₹10,000/mo',
          'amenities': ['Central AC', 'Conference Room', 'Power Backup', '24/7 Access'],
          'images': ['https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1000'],
        },
      ];
    } else if (platform == 'Housing.com') {
      return [
        {
          'title': 'Housing.com Verified: 3 BHK Penthouse in Powai',
          'location': 'Powai, Mumbai',
          'price': '₹3.6 Cr',
          'bhk': '3 BHK',
          'type': 'Sale',
          'propertyType': 'Penthouse',
          'areaSqft': 1900,
          'bathrooms': 3,
          'balcony': 2,
          'parking': 2,
          'furnishedStatus': 'Fully Furnished',
          'maintenanceCharges': '₹7,500/mo',
          'amenities': ['Lake View', 'Gym', 'Swimming Pool', '24/7 Security'],
          'images': ['https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=1000'],
        },
      ];
    } else if (platform == 'Custom API') {
      return [
        {
          'title': 'Custom Feed: 3 BHK Luxury Seafront Apartment',
          'location': 'Juhu, Mumbai',
          'price': '₹5.5 Cr',
          'bhk': '3 BHK',
          'type': 'Sale',
          'propertyType': 'Apartment',
          'areaSqft': 2100,
          'bathrooms': 3,
          'balcony': 2,
          'parking': 2,
          'furnishedStatus': 'Fully Furnished',
          'maintenanceCharges': '₹9,500/mo',
          'amenities': ['Private Elevator', 'Sea View', 'Gym', '24/7 Concierge'],
          'images': ['https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000'],
        },
        {
          'title': 'Custom Feed: 4 BHK Sky Villa with Private Deck',
          'location': 'Worli Sea Face, Mumbai',
          'price': '₹12.0 Cr',
          'bhk': '4 BHK',
          'type': 'Sale',
          'propertyType': 'Villa',
          'areaSqft': 3800,
          'bathrooms': 4,
          'balcony': 3,
          'parking': 3,
          'furnishedStatus': 'Semi-Furnished',
          'maintenanceCharges': '₹15,000/mo',
          'amenities': ['Private Deck', 'Infinity Pool', 'Smart Home Automation'],
          'images': ['https://images.unsplash.com/photo-1600585154526-990dced4db0d?q=80&w=1000'],
        },
      ];
    } else {
      return [
        {
          'title': '99acres Verified: 3 BHK Sea View Apartment',
          'location': 'Worli, Mumbai',
          'price': '₹4.2 Cr',
          'bhk': '3 BHK',
          'type': 'Sale',
          'propertyType': 'Apartment',
          'areaSqft': 1750,
          'bathrooms': 3,
          'balcony': 2,
          'parking': 2,
          'furnishedStatus': 'Fully Furnished',
          'maintenanceCharges': '₹8,000/mo',
          'amenities': ['Sea View', 'Gym', 'Swimming Pool', '24/7 Security', 'Power Backup'],
          'images': ['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000'],
        },
        {
          'title': '99acres Verified: Luxury 4 BHK Independent Villa',
          'location': 'Bandra West, Mumbai',
          'price': '₹8.5 Cr',
          'bhk': '4 BHK',
          'type': 'Sale',
          'propertyType': 'Villa',
          'areaSqft': 3200,
          'bathrooms': 4,
          'balcony': 3,
          'parking': 3,
          'furnishedStatus': 'Semi-Furnished',
          'maintenanceCharges': '₹12,000/mo',
          'amenities': ['Private Pool', 'Garden', 'Security', 'Club House', 'EV Charging'],
          'images': ['https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=1000'],
        },
      ];
    }
  }
}

final autoSyncProvider = NotifierProvider<AutoSyncNotifier, AutoSyncState>(() {
  return AutoSyncNotifier();
});
