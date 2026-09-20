import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocationDetails {
  final String location;
  final String city;
  final String state;
  final String country;
  final String area;
  final String pincode;
  final String? googleMapUrl;
  final double? latitude;
  final double? longitude;

  const LocationDetails({
    required this.location,
    required this.city,
    required this.state,
    this.country = 'India',
    this.area = '',
    this.pincode = '',
    this.googleMapUrl,
    this.latitude,
    this.longitude,
  });

  @override
  String toString() {
    return 'LocationDetails(location: $location, city: $city, state: $state, area: $area, pincode: $pincode, lat: $latitude, lon: $longitude)';
  }
}

class LocationHelper {
  /// Comprehensive Indian States & Union Territories
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    // Union Territories
    'Delhi',
    'Chandigarh',
    'Puducherry',
    'Jammu and Kashmir',
    'Ladakh',
    'Andaman and Nicobar Islands',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Lakshadweep',
  ];

  /// Dictionary mapping key Indian real-estate cities to their respective states
  static const Map<String, String> cityToStateMap = {
    'mumbai': 'Maharashtra',
    'navi mumbai': 'Maharashtra',
    'thane': 'Maharashtra',
    'pune': 'Maharashtra',
    'nagpur': 'Maharashtra',
    'nashik': 'Maharashtra',
    'aurangabad': 'Maharashtra',
    'chhatrapati sambhajinagar': 'Maharashtra',
    'kolhapur': 'Maharashtra',
    'solapur': 'Maharashtra',
    'vasai': 'Maharashtra',
    'virar': 'Maharashtra',
    'kalyan': 'Maharashtra',
    'dombivli': 'Maharashtra',
    'mira bhayandar': 'Maharashtra',
    'panvel': 'Maharashtra',
    'delhi': 'Delhi',
    'new delhi': 'Delhi',
    'gurugram': 'Haryana',
    'gurgaon': 'Haryana',
    'faridabad': 'Haryana',
    'panipat': 'Haryana',
    'sonipat': 'Haryana',
    'karnal': 'Haryana',
    'rohtak': 'Haryana',
    'noida': 'Uttar Pradesh',
    'greater noida': 'Uttar Pradesh',
    'ghaziabad': 'Uttar Pradesh',
    'lucknow': 'Uttar Pradesh',
    'kanpur': 'Uttar Pradesh',
    'varanasi': 'Uttar Pradesh',
    'agra': 'Uttar Pradesh',
    'prayagraj': 'Uttar Pradesh',
    'allahabad': 'Uttar Pradesh',
    'meerut': 'Uttar Pradesh',
    'bareilly': 'Uttar Pradesh',
    'aligarh': 'Uttar Pradesh',
    'moradabad': 'Uttar Pradesh',
    'gorakhpur': 'Uttar Pradesh',
    'bengaluru': 'Karnataka',
    'bangalore': 'Karnataka',
    'mysuru': 'Karnataka',
    'mysore': 'Karnataka',
    'mangaluru': 'Karnataka',
    'mangalore': 'Karnataka',
    'hubballi': 'Karnataka',
    'belagavi': 'Karnataka',
    'hyderabad': 'Telangana',
    'secunderabad': 'Telangana',
    'warangal': 'Telangana',
    'chennai': 'Tamil Nadu',
    'coimbatore': 'Tamil Nadu',
    'madurai': 'Tamil Nadu',
    'tiruchirappalli': 'Tamil Nadu',
    'salem': 'Tamil Nadu',
    'kolkata': 'West Bengal',
    'howrah': 'West Bengal',
    'durgapur': 'West Bengal',
    'siliguri': 'West Bengal',
    'asansol': 'West Bengal',
    'ahmedabad': 'Gujarat',
    'surat': 'Gujarat',
    'vadodara': 'Gujarat',
    'rajkot': 'Gujarat',
    'bhavnagar': 'Gujarat',
    'jamnagar': 'Gujarat',
    'gandhinagar': 'Gujarat',
    'jaipur': 'Rajasthan',
    'jodhpur': 'Rajasthan',
    'udaipur': 'Rajasthan',
    'kota': 'Rajasthan',
    'bikaner': 'Rajasthan',
    'ajmer': 'Rajasthan',
    'chandigarh': 'Chandigarh',
    'mohali': 'Punjab',
    'panchkula': 'Haryana',
    'ludhiana': 'Punjab',
    'amritsar': 'Punjab',
    'jalandhar': 'Punjab',
    'indore': 'Madhya Pradesh',
    'bhopal': 'Madhya Pradesh',
    'gwalior': 'Madhya Pradesh',
    'jabalpur': 'Madhya Pradesh',
    'kochi': 'Kerala',
    'cochin': 'Kerala',
    'thiruvananthapuram': 'Kerala',
    'trivandrum': 'Kerala',
    'kozhikode': 'Kerala',
    'thrissur': 'Kerala',
    'bhubaneswar': 'Odisha',
    'cuttack': 'Odisha',
    'patna': 'Bihar',
    'gaya': 'Bihar',
    'muzaffarpur': 'Bihar',
    'ranchi': 'Jharkhand',
    'jamshedpur': 'Jharkhand',
    'dhanbad': 'Jharkhand',
    'dehradun': 'Uttarakhand',
    'haridwar': 'Uttarakhand',
    'rishikesh': 'Uttarakhand',
    'guwahati': 'Assam',
    'goa': 'Goa',
    'panaji': 'Goa',
    'margao': 'Goa',
    'visakhapatnam': 'Andhra Pradesh',
    'vijayawada': 'Andhra Pradesh',
    'guntur': 'Andhra Pradesh',
    'raipur': 'Chhattisgarh',
    'shimla': 'Himachal Pradesh',
    'srinagar': 'Jammu and Kashmir',
    'jammu': 'Jammu and Kashmir',
  };

  /// Auto-extracts city, state, area, pincode, and Google Maps URL from a location string
  /// or Nominatim structured address details.
  static LocationDetails extractDetails({
    required String rawLocation,
    Map<String, dynamic>? addressDetails,
    double? latitude,
    double? longitude,
  }) {
    String city = '';
    String state = '';
    String area = '';
    String country = 'India';
    String pincode = '';

    // 1. Extract from Nominatim structured address if provided
    if (addressDetails != null && addressDetails.isNotEmpty) {
      country = (addressDetails['country'] as String?)?.trim() ?? 'India';
      state = (addressDetails['state'] as String?)?.trim() ??
          (addressDetails['state_district'] as String?)?.trim() ??
          (addressDetails['region'] as String?)?.trim() ??
          '';

      pincode = (addressDetails['postcode'] as String?)?.trim() ?? '';

      // Priority resolution for city
      city = (addressDetails['city'] as String?)?.trim() ??
          (addressDetails['town'] as String?)?.trim() ??
          (addressDetails['municipality'] as String?)?.trim() ??
          (addressDetails['city_district'] as String?)?.trim() ??
          (addressDetails['suburb'] as String?)?.trim() ??
          (addressDetails['county'] as String?)?.trim() ??
          (addressDetails['village'] as String?)?.trim() ??
          '';

      // Special handling for Mumbai / Delhi districts
      if (city.toLowerCase().contains('mumbai')) {
        city = 'Mumbai';
        state = 'Maharashtra';
      } else if (city.toLowerCase().contains('delhi')) {
        city = 'New Delhi';
        state = 'Delhi';
      }

      // Priority resolution for area
      area = (addressDetails['suburb'] as String?)?.trim() ??
          (addressDetails['neighbourhood'] as String?)?.trim() ??
          (addressDetails['residential'] as String?)?.trim() ??
          (addressDetails['road'] as String?)?.trim() ??
          '';
    }

    // 2. Fallback / supplementary string extraction from rawLocation
    if (city.isEmpty || state.isEmpty || area.isEmpty) {
      final textDetails = extractFromText(rawLocation);
      if (city.isEmpty) city = textDetails.city;
      if (state.isEmpty) state = textDetails.state;
      if (area.isEmpty) area = textDetails.area;
      if (pincode.isEmpty) pincode = textDetails.pincode;
      if (country.isEmpty || country == 'India') country = textDetails.country;
    }

    // 3. Resolve state from city if still empty
    if (state.isEmpty && city.isNotEmpty) {
      final resolvedState = resolveStateFromCity(city);
      if (resolvedState != null) {
        state = resolvedState;
      }
    }

    // 4. Construct clean display location title
    String displayLoc = rawLocation.trim();
    if (displayLoc.contains(',')) {
      final segments = displayLoc
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.toLowerCase() != 'india' && !RegExp(r'^\d{5,6}$').hasMatch(s))
          .toList();

      if (segments.length >= 2) {
        // Take primary 2-3 segments (e.g. "Worli, Mumbai" instead of "Worli, Mumbai, Mumbai Suburban, Maharashtra, India")
        displayLoc = '${segments[0]}, ${segments[1]}';
      }
    }

    // 5. Build Google Maps URL if coordinates exist or from query
    String? mapUrl;
    if (latitude != null && longitude != null) {
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    } else if (displayLoc.isNotEmpty) {
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(displayLoc)}';
    }

    return LocationDetails(
      location: displayLoc.isNotEmpty ? displayLoc : rawLocation.trim(),
      city: city,
      state: state,
      country: country,
      area: area,
      pincode: pincode,
      googleMapUrl: mapUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Parses text strings such as:
  /// - "Worli, Mumbai"
  /// - "Indiranagar, Bangalore"
  /// - "Cyber City, Gurugram, Haryana"
  /// - "Connaught Place, New Delhi"
  /// - "Bandra West, Mumbai - 400050"
  /// - "Mumbai (MMR), Maharashtra"
  static LocationDetails extractFromText(String text) {
    if (text.trim().isEmpty) {
      return const LocationDetails(location: '', city: '', state: '');
    }

    String working = text.trim();

    // Check for 6-digit Indian PIN code
    final pinMatch = RegExp(r'\b(\d{6})\b').firstMatch(working);
    String pincode = pinMatch != null ? pinMatch.group(1)! : '';
    if (pincode.isNotEmpty) {
      working = working.replaceAll(pincode, '').trim();
    }

    // Clean brackets e.g. "Mumbai (MMR)" -> "Mumbai"
    working = working.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

    // Split by commas or dashes
    final parts = working
        .split(RegExp(r'[,–\-]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    String area = '';
    String city = '';
    String state = '';
    String country = 'India';

    // 1. Check for recognized city from right to left
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i];
      if (part.toLowerCase() == 'india') continue;

      final matchedStateFromCity = resolveStateFromCity(part);
      if (matchedStateFromCity != null) {
        city = _standardizeCityName(part);
        if (state.isEmpty) {
          state = matchedStateFromCity;
        }
        parts.removeAt(i);
        break;
      }
    }

    // 2. Check if any remaining part is a recognized Indian state
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i];
      if (part.toLowerCase() == 'india') continue;

      final matchedState = findMatchingState(part);
      if (matchedState != null) {
        state = matchedState;
        parts.removeAt(i);
        break;
      }
    }

    // 3. If city still not found, use the last remaining part as city
    if (city.isEmpty && parts.isNotEmpty) {
      city = parts.last;
      parts.removeLast();
    }

    // 4. If area not found, remaining parts form the area / neighborhood
    if (parts.isNotEmpty) {
      area = parts.join(', ');
    } else if (city.isNotEmpty) {
      area = city;
    }

    // Final state resolution if still empty
    if (state.isEmpty && city.isNotEmpty) {
      state = resolveStateFromCity(city) ?? '';
    }

    return LocationDetails(
      location: text.trim(),
      city: city,
      state: state,
      country: country,
      area: area,
      pincode: pincode,
    );
  }

  /// Resolve state from city name (case-insensitive substring and exact matching)
  static String? resolveStateFromCity(String cityName) {
    final clean = cityName.toLowerCase().trim();
    if (clean.isEmpty) return null;

    if (cityToStateMap.containsKey(clean)) {
      return cityToStateMap[clean];
    }

    for (final entry in cityToStateMap.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Match a string to a recognized Indian state
  static String? findMatchingState(String str) {
    final clean = str.toLowerCase().trim();
    for (final state in indianStates) {
      if (state.toLowerCase() == clean) {
        return state;
      }
    }
    for (final state in indianStates) {
      if (clean.contains(state.toLowerCase()) || state.toLowerCase().contains(clean)) {
        return state;
      }
    }
    return null;
  }

  static String _standardizeCityName(String city) {
    final lower = city.toLowerCase().trim();
    if (lower.contains('mumbai')) return 'Mumbai';
    if (lower.contains('delhi')) return 'New Delhi';
    if (lower.contains('bangalore') || lower.contains('bengaluru')) return 'Bengaluru';
    if (lower.contains('gurugram') || lower.contains('gurgaon')) return 'Gurugram';
    if (lower.contains('pune')) return 'Pune';
    if (lower.contains('hyderabad')) return 'Hyderabad';
    if (lower.contains('chennai')) return 'Chennai';
    if (lower.contains('kolkata')) return 'Kolkata';
    if (lower.contains('ahmedabad')) return 'Ahmedabad';
    if (lower.contains('jaipur')) return 'Jaipur';
    if (lower.contains('noida')) return 'Noida';
    return city.trim();
  }

  /// Extracts location, coordinates, city, and state directly from a Google Maps URL or query.
  /// Handles formats like:
  /// - https://maps.google.com/?q=19.0176,72.8302
  /// - https://www.google.com/maps/place/Worli,+Mumbai,+Maharashtra/@19.0176,72.8302,15z
  /// - https://www.google.com/maps/search/?api=1&query=Worli%20Mumbai
  /// - geo:19.0176,72.8302
  static LocationDetails? parseGoogleMapsUrl(String url) {
    if (url.trim().isEmpty) return null;

    final trimmed = url.trim();

    // 1. Check for coordinates in URL (@19.0176,72.8302 or q=19.0176,72.8302)
    final coordMatch = RegExp(r'[@=](-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    double? lat;
    double? lon;
    if (coordMatch != null) {
      lat = double.tryParse(coordMatch.group(1)!);
      lon = double.tryParse(coordMatch.group(2)!);
    }

    // 2. Check for place name in URL (/place/Worli,+Mumbai,+Maharashtra/)
    final placeMatch = RegExp(r'/place/([^/@]+)').firstMatch(trimmed);
    String placeName = '';
    if (placeMatch != null) {
      placeName = Uri.decodeComponent(placeMatch.group(1)!).replaceAll('+', ' ');
    } else {
      // Check query parameter q= or query=
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final q = uri.queryParameters['q'] ?? uri.queryParameters['query'];
        if (q != null && !RegExp(r'^-?\d+\.\d+,-?\d+\.\d+$').hasMatch(q)) {
          placeName = q.replaceAll('+', ' ');
        }
      }
    }

    if (placeName.isNotEmpty) {
      return extractDetails(
        rawLocation: placeName,
        latitude: lat,
        longitude: lon,
      );
    } else if (lat != null && lon != null) {
      return LocationDetails(
        location: '$lat, $lon',
        city: '',
        state: '',
        latitude: lat,
        longitude: lon,
        googleMapUrl: trimmed,
      );
    }

    return null;
  }

  /// Reverse geocodes latitude/longitude via OpenStreetMap/Nominatim to retrieve
  /// full verified address, city, state, area, and pincode.
  static Future<LocationDetails?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'PropConnectApp/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] as String?) ?? '';
        final address = data['address'] as Map<String, dynamic>?;

        return extractDetails(
          rawLocation: displayName,
          addressDetails: address,
          latitude: lat,
          longitude: lon,
        );
      }
    } catch (e) {
      debugPrint('Error reverse geocoding coordinates ($lat, $lon): $e');
    }
    return null;
  }
}
