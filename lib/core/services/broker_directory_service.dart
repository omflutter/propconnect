import 'package:flutter/foundation.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/network/api_service.dart';

class BrokerDirectoryUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final int? agencyId;
  final String agencyName;

  BrokerDirectoryUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.agencyId,
    this.agencyName = '',
  });

  factory BrokerDirectoryUser.fromJson(Map<String, dynamic> json) {
    int? aId;
    String aName = '';
    if (json['agencyId'] != null) {
      aId = int.tryParse(json['agencyId'].toString());
    } else if (json['agency'] is Map && json['agency']['id'] != null) {
      aId = int.tryParse(json['agency']['id'].toString());
    }
    if (json['agency'] is Map && json['agency']['name'] != null) {
      aName = json['agency']['name'].toString();
    }

    return BrokerDirectoryUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'broker').toString(),
      agencyId: aId,
      agencyName: aName,
    );
  }
}

class BrokerDirectoryService {
  static final List<BrokerDirectoryUser> _cachedUsers = [];
  static DateTime? _lastFetchTime;

  /// Fetches all platform brokers & agency admins across agencies
  static Future<List<BrokerDirectoryUser>> fetchDirectory({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedUsers.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      return _cachedUsers;
    }

    try {
      final res = await ApiService.get('/brokers?allAgencies=true');
      if (res['success'] == true && res['data'] is List) {
        _cachedUsers.clear();
        for (final item in (res['data'] as List)) {
          if (item is Map) {
            _cachedUsers.add(BrokerDirectoryUser.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        _lastFetchTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('[BrokerDirectoryService] Error fetching directory: $e');
    }

    return _cachedUsers;
  }

  /// Resolves the partner user ID to chat with for a given property
  static String resolvePartnerForProperty(PropertyModel property, {String? fallbackUserId}) {
    // 1. If property has an explicit valid brokerId
    if (property.brokerId != null && property.brokerId! > 0) {
      return property.brokerId.toString();
    }

    final pAgencyId = property.agencyId;
    final pBrokerName = property.brokerName.trim().toLowerCase();

    // 2. Search cached directory by agencyId and broker name
    if (pAgencyId != null && _cachedUsers.isNotEmpty) {
      // Direct name match within the agency
      if (pBrokerName.isNotEmpty) {
        final match = _cachedUsers.firstWhere(
          (u) => u.agencyId == pAgencyId && u.name.trim().toLowerCase() == pBrokerName,
          orElse: () => BrokerDirectoryUser(id: '', name: '', email: '', role: ''),
        );
        if (match.id.isNotEmpty) return match.id;
      }

      // Agency admin of that agency
      final adminMatch = _cachedUsers.firstWhere(
        (u) => u.agencyId == pAgencyId && (u.role == 'agency_admin' || u.role == 'super_admin'),
        orElse: () => BrokerDirectoryUser(id: '', name: '', email: '', role: ''),
      );
      if (adminMatch.id.isNotEmpty) return adminMatch.id;

      // Any member of that agency
      final anyMember = _cachedUsers.firstWhere(
        (u) => u.agencyId == pAgencyId,
        orElse: () => BrokerDirectoryUser(id: '', name: '', email: '', role: ''),
      );
      if (anyMember.id.isNotEmpty) return anyMember.id;
    }

    // 3. Fallback to property agencyId or provided fallback
    if (pAgencyId != null && pAgencyId > 0) {
      return pAgencyId.toString();
    }

    return fallbackUserId ?? '1';
  }

  /// Retrieves a cached user by ID
  static BrokerDirectoryUser? getUserById(String id) {
    if (id.isEmpty) return null;
    for (final u in _cachedUsers) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Resolves the partner user ID, name, and agency name for a deal or collaboration
  static PartnerDetails resolvePartnerDetailsForDeal(DealModel deal, String currentUserId, {int? currentAgencyId}) {
    final curUserIdStr = currentUserId.trim();
    final curAgencyIdStr = currentAgencyId?.toString() ?? '';

    // Check if the current user represents Party A (Listing Owner)
    final isPartyA = (deal.brokerAId != null && deal.brokerAId.toString() == curUserIdStr) ||
        (deal.agencyAId != null && curAgencyIdStr.isNotEmpty && deal.agencyAId.toString() == curAgencyIdStr) ||
        deal.isIncomingRequest;

    if (isPartyA) {
      // Counterparty is Party B (Requester / Buyer's Broker)
      String partnerId = deal.brokerBId?.toString() ?? '';
      String partnerName = deal.brokerBName.trim();
      String partnerAgency = deal.agencyBName.trim();

      if (partnerId.isEmpty || partnerId == curUserIdStr) {
        if (deal.agencyBId != null) {
          final match = _cachedUsers.firstWhere(
            (u) => u.agencyId == deal.agencyBId && u.id != curUserIdStr,
            orElse: () => BrokerDirectoryUser(id: '', name: '', email: '', role: ''),
          );
          if (match.id.isNotEmpty) {
            partnerId = match.id;
            if (partnerName.isEmpty || partnerName == 'Broker' || partnerName == 'Partner Broker') {
              partnerName = match.name;
            }
            if (partnerAgency.isEmpty || partnerAgency == 'Partner Agency') {
              partnerAgency = match.agencyName;
            }
          } else {
            partnerId = deal.agencyBId.toString();
          }
        }
      }

      // If partnerName is still generic, lookup cached user by partnerId
      if (partnerName.isEmpty || partnerName == 'Broker' || partnerName == 'Partner Broker' || partnerName == 'Broker Agent') {
        final u = getUserById(partnerId);
        if (u != null) {
          partnerName = u.name;
          if (partnerAgency.isEmpty || partnerAgency == 'Partner Agency') partnerAgency = u.agencyName;
        }
      }

      return PartnerDetails(
        id: partnerId.isNotEmpty ? partnerId : '2',
        name: partnerName.isNotEmpty ? partnerName : 'Partner Broker',
        agencyName: partnerAgency.isNotEmpty ? partnerAgency : 'Partner Realty',
      );
    } else {
      // Counterparty is Party A (Listing Owner)
      String partnerId = deal.brokerAId?.toString() ?? '';
      String partnerName = deal.brokerAName.trim();
      String partnerAgency = deal.agencyAName.trim();

      if (partnerId.isEmpty || partnerId == curUserIdStr) {
        if (deal.agencyAId != null) {
          final match = _cachedUsers.firstWhere(
            (u) => u.agencyId == deal.agencyAId && u.id != curUserIdStr,
            orElse: () => BrokerDirectoryUser(id: '', name: '', email: '', role: ''),
          );
          if (match.id.isNotEmpty) {
            partnerId = match.id;
            if (partnerName.isEmpty || partnerName == 'Broker' || partnerName == 'Listing Broker') {
              partnerName = match.name;
            }
            if (partnerAgency.isEmpty || partnerAgency == 'Listing Agency') {
              partnerAgency = match.agencyName;
            }
          } else {
            partnerId = deal.agencyAId.toString();
          }
        }
      }

      // If partnerName is still generic, lookup cached user by partnerId
      if (partnerName.isEmpty || partnerName == 'Broker' || partnerName == 'Listing Broker' || partnerName == 'Partner Broker' || partnerName == 'Broker Agent') {
        final u = getUserById(partnerId);
        if (u != null) {
          partnerName = u.name;
          if (partnerAgency.isEmpty || partnerAgency == 'Listing Agency') partnerAgency = u.agencyName;
        }
      }

      return PartnerDetails(
        id: partnerId.isNotEmpty ? partnerId : '1',
        name: partnerName.isNotEmpty ? partnerName : 'Listing Broker',
        agencyName: partnerAgency.isNotEmpty ? partnerAgency : 'Listing Agency',
      );
    }
  }

  /// Resolves the partner user ID for a collaboration request or deal
  static String resolvePartnerForCollaboration(DealModel deal, String currentUserId) {
    return resolvePartnerDetailsForDeal(deal, currentUserId).id;
  }
}

class PartnerDetails {
  final String id;
  final String name;
  final String agencyName;

  PartnerDetails({
    required this.id,
    required this.name,
    required this.agencyName,
  });
}
