import 'dart:convert';
import 'package:flutter/foundation.dart';

class PropertyModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String price;
  final String negotiablePrice;
  final String securityDeposit;
  final String bhk;
  final String type; // Sale / Rent
  final String purpose; // Sale / Rent / Lease
  final bool isPublic;
  final int? agencyId;
  final String agencyName;
  final String propertyType;
  final String status;
  final String brokerName;
  
  // PRD Address & Geo Specifications
  final String country;
  final String stateName;
  final String city;
  final String area;
  final String address;
  final String googleMapUrl;

  // PRD Area Specifications
  final double areaSqft; // Built-up
  final double carpetArea; // Carpet Area

  // PRD Features Specifications
  final int bathrooms;
  final int balcony;
  final int parking;
  final String furnishedStatus;
  final int propertyAge;
  final String rawPropertyAge;
  final String maintenanceCharges;
  final List<String> amenities;
  final List<String> images;
  final List<String> floorPlans;
  final List<String> documents;

  // PRD Owner Info & KYC (Protected by Privacy Matrix)
  final int? ownerId;
  final String ownerName;
  final String ownerPhonePrimary;
  final String ownerPhoneSecondary;
  final String ownerEmail;
  final String ownerAddress;
  final List<String> ownerKycDocs;
  final String internalNotes;

  PropertyModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.location,
    required this.price,
    this.negotiablePrice = '',
    this.securityDeposit = '',
    required this.bhk,
    required this.type,
    this.purpose = 'Sale',
    this.isPublic = false,
    this.agencyId,
    required this.agencyName,
    required this.propertyType,
    required this.status,
    required this.brokerName,
    this.country = 'India',
    this.stateName = 'Maharashtra',
    this.city = 'Mumbai',
    this.area = '',
    this.address = '',
    this.googleMapUrl = '',
    required this.areaSqft,
    this.carpetArea = 0.0,
    required this.bathrooms,
    required this.balcony,
    required this.parking,
    required this.furnishedStatus,
    required this.propertyAge,
    this.rawPropertyAge = '',
    required this.maintenanceCharges,
    required this.amenities,
    required this.images,
    this.floorPlans = const [],
    this.documents = const [],
    this.ownerId,
    this.ownerName = '',
    this.ownerPhonePrimary = '',
    this.ownerPhoneSecondary = '',
    this.ownerEmail = '',
    this.ownerAddress = '',
    this.ownerKycDocs = const [],
    this.internalNotes = '',
  });

  String get displayPropertyAge {
    if (rawPropertyAge.trim().isNotEmpty) {
      return rawPropertyAge;
    }
    if (propertyAge <= 0) return 'Brand New / Ready';
    return '$propertyAge Year${propertyAge > 1 ? 's' : ''} Old';
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final clean = val.trim();
      final direct = int.tryParse(clean);
      if (direct != null) return direct;
      final match = RegExp(r'\d+').firstMatch(clean);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? fallback;
      }
    }
    return fallback;
  }

  static double _parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      return double.tryParse(clean) ?? fallback;
    }
    return fallback;
  }

  static bool _parseBool(dynamic val, [bool fallback = false]) {
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return fallback;
  }

  static String _parseString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    if (val is String) return val;
    return val.toString();
  }

  static List<String> _parseStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) {
      return val
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    if (val is String) {
      final s = val.trim();
      if (s.isEmpty) return [];
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            return decoded
                .map((e) => e?.toString() ?? '')
                .where((item) => item.trim().isNotEmpty)
                .toList();
          }
        } catch (_) {}
      }
      return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    try {
      final parsedAgencyId = json['agencyId'] != null
          ? _parseInt(json['agencyId'])
          : (json['agency'] is Map && json['agency']['id'] != null
              ? _parseInt(json['agency']['id'])
              : null);

      String parsedAgencyName = '';
      if (json['agencyName'] != null && json['agencyName'].toString().trim().isNotEmpty) {
        parsedAgencyName = json['agencyName'].toString().trim();
      } else if (json['agency'] is Map && json['agency']['name'] != null) {
        parsedAgencyName = json['agency']['name'].toString().trim();
      }

      final parsedArea = _parseDouble(json['areaSqft'] ?? json['builtUpArea'], 1000.0);
      final parsedCarpet = _parseDouble(json['carpetArea'], parsedArea * 0.8);

      final rawAge = _parseString(json['propertyAge'], '');
      final ageNum = _parseInt(json['propertyAge'], 0);

      return PropertyModel(
        id: _parseString(json['id'] ?? json['propertyCode'], '0'),
        title: _parseString(json['title'], 'Property Listing'),
        description: _parseString(json['description'], ''),
        location: _parseString(json['location'], 'Mumbai, Maharashtra'),
        price: _parseString(json['price'], '₹0'),
        negotiablePrice: _parseString(json['negotiablePrice'], ''),
        securityDeposit: _parseString(json['securityDeposit'], ''),
        bhk: _parseString(json['bhk'], '2 BHK'),
        type: _parseString(json['type'], 'Sale'),
        purpose: _parseString(json['purpose'] ?? json['type'], 'Sale'),
        brokerName: _parseString(json['brokerName'], ''),
        agencyId: parsedAgencyId,
        agencyName: parsedAgencyName,
        isPublic: _parseBool(json['isPublic'], false),
        propertyType: _parseString(json['propertyType'], 'Apartment'),
        status: _parseString(json['status'], 'Available'),
        country: _parseString(json['country'], 'India'),
        stateName: _parseString(json['state'] ?? json['stateName'], ''),
        city: _parseString(json['city'], ''),
        area: _parseString(json['area'], ''),
        address: _parseString(json['address'], ''),
        googleMapUrl: _parseString(json['googleMapUrl'], ''),
        areaSqft: parsedArea,
        carpetArea: parsedCarpet,
        bathrooms: _parseInt(json['bathrooms'], 2),
        balcony: _parseInt(json['balcony'], 1),
        parking: _parseInt(json['parking'], 1),
        furnishedStatus: _parseString(json['furnishedStatus'], 'Unfurnished'),
        propertyAge: ageNum,
        rawPropertyAge: rawAge.isNotEmpty ? rawAge : (ageNum > 0 ? '$ageNum Years' : '1-5 Years'),
        maintenanceCharges: _parseString(json['maintenanceCharges'], '₹0'),
        amenities: _parseStringList(json['amenities']),
        images: _parseStringList(json['images']),
        floorPlans: _parseStringList(json['floorPlans']),
        documents: _parseStringList(json['documents']),
        ownerId: _parseInt(json['ownerId'] ?? json['owner_id'], 0) == 0 ? null : _parseInt(json['ownerId'] ?? json['owner_id']),
        ownerName: _parseString(json['ownerName'], ''),
        ownerPhonePrimary: _parseString(json['ownerPhonePrimary'], ''),
        ownerPhoneSecondary: _parseString(json['ownerPhoneSecondary'], ''),
        ownerEmail: _parseString(json['ownerEmail'], ''),
        ownerAddress: _parseString(json['ownerAddress'], ''),
        ownerKycDocs: _parseStringList(json['ownerKycDocs']),
        internalNotes: _parseString(json['internalNotes'], ''),
      );
    } catch (e, stack) {
      debugPrint('Safe fallback triggered in PropertyModel.fromJson: $e\n$stack');
      return PropertyModel(
        id: (json['id'] ?? json['propertyCode'] ?? '0').toString(),
        title: (json['title'] ?? 'Listing').toString(),
        location: (json['location'] ?? 'Mumbai').toString(),
        price: (json['price'] ?? '₹0').toString(),
        bhk: (json['bhk'] ?? '2 BHK').toString(),
        type: (json['type'] ?? 'Sale').toString(),
        agencyName: (json['agencyName'] ?? '').toString(),
        propertyType: (json['propertyType'] ?? 'Apartment').toString(),
        status: (json['status'] ?? 'Available').toString(),
        brokerName: (json['brokerName'] ?? '').toString(),
        isPublic: false,
        areaSqft: 1000.0,
        bathrooms: 2,
        balcony: 1,
        parking: 1,
        furnishedStatus: 'Unfurnished',
        propertyAge: 0,
        maintenanceCharges: '₹0',
        amenities: const [],
        images: const [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'negotiablePrice': negotiablePrice,
      'securityDeposit': securityDeposit,
      'bhk': bhk,
      'type': type,
      'purpose': purpose,
      'isPublic': isPublic,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'propertyType': propertyType,
      'status': status,
      'brokerName': brokerName,
      'country': country,
      'state': stateName,
      'city': city,
      'area': area,
      'address': address,
      'googleMapUrl': googleMapUrl,
      'builtUpArea': areaSqft,
      'areaSqft': areaSqft,
      'carpetArea': carpetArea,
      'bathrooms': bathrooms,
      'balcony': balcony,
      'parking': parking,
      'furnishedStatus': furnishedStatus,
      'propertyAge': rawPropertyAge.isNotEmpty ? rawPropertyAge : propertyAge,
      'maintenanceCharges': maintenanceCharges,
      'amenities': amenities,
      'images': images,
      'floorPlans': floorPlans,
      'documents': documents,
      if (ownerId != null) 'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhonePrimary': ownerPhonePrimary,
      'ownerPhoneSecondary': ownerPhoneSecondary,
      'ownerEmail': ownerEmail,
      'ownerAddress': ownerAddress,
      'ownerKycDocs': ownerKycDocs,
      'internalNotes': internalNotes,
    };
  }
}
