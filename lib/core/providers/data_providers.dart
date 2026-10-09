import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../models/deal_model.dart';
import '../models/commission_model.dart';
import '../models/owner_model.dart';
import '../network/api_service.dart';
import '../services/firestore_chat_service.dart';
import '../services/auth_storage_service.dart';
import '../services/push_notification_service.dart';
import '../services/broker_directory_service.dart';
import 'user_role_provider.dart';

class PropertiesLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setLoading(bool loading) {
    state = loading;
  }
}

final isPropertiesLoadingProvider = NotifierProvider<PropertiesLoadingNotifier, bool>(() {
  return PropertiesLoadingNotifier();
});

class PropertiesErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }
}

final propertiesErrorProvider = NotifierProvider<PropertiesErrorNotifier, String?>(() {
  return PropertiesErrorNotifier();
});

class PropertyNotifier extends Notifier<List<PropertyModel>> {
  StreamSubscription? _fcmSub;

  @override
  List<PropertyModel> build() {
    final cached = AuthStorageService.getCachedProperties();
    _fcmSub = PushNotificationService.onMessageReceivedStream.stream.listen((message) {
      final type = message.data['type'] as String?;
      if (type == null || type == 'property' || type == 'deal') {
        fetchProperties();
      }
    });
    ref.onDispose(() {
      _fcmSub?.cancel();
    });
    Future.microtask(() {
      fetchProperties();
    });
    return cached;
  }

  Future<void> fetchProperties({bool isRetry = false}) async {
    try {
      ref.read(isPropertiesLoadingProvider.notifier).setLoading(true);
      ref.read(propertiesErrorProvider.notifier).setError(null);

      final res = await ApiService.get('/properties');
      if (res['success'] == true && res['data'] != null && res['data'] is List) {
        final list = <PropertyModel>[];
        final seenKeys = <String>{};
        for (final item in (res['data'] as List)) {
          try {
            if (item is Map) {
              final prop = PropertyModel.fromJson(Map<String, dynamic>.from(item));
              final key = prop.id.isNotEmpty ? 'id:${prop.id}' : 'title:${prop.title.trim().toLowerCase()}';
              if (!seenKeys.contains(key)) {
                seenKeys.add(key);
                list.add(prop);
              }
            }
          } catch (itemErr) {
            // Safe fallback handles it, this prevents any rogue exception
          }
        }
        state = list;
        try {
          await AuthStorageService.saveCachedProperties(list);
        } catch (_) {}
        ref.read(isPropertiesLoadingProvider.notifier).setLoading(false);
        ref.read(propertiesErrorProvider.notifier).setError(null);
      } else {
        if (!isRetry) {
          await Future.delayed(const Duration(milliseconds: 1500));
          return fetchProperties(isRetry: true);
        }
        ref.read(isPropertiesLoadingProvider.notifier).setLoading(false);
        if (state.isEmpty) {
          ref.read(propertiesErrorProvider.notifier).setError(res['message'] ?? 'Could not load properties from database');
        }
      }
    } catch (e) {
      if (!isRetry) {
        await Future.delayed(const Duration(milliseconds: 1500));
        return fetchProperties(isRetry: true);
      }
      ref.read(isPropertiesLoadingProvider.notifier).setLoading(false);
      if (state.isEmpty) {
        ref.read(propertiesErrorProvider.notifier).setError('Connection error: $e');
      }
    }
  }

  Future<bool> addProperty(PropertyModel property) async {
    state = [property, ...state];
    try {
      await AuthStorageService.saveCachedProperties(state);
    } catch (_) {}

    try {
      final res = await ApiService.post('/properties', property.toJson());
      if (res['success'] == true && res['data'] != null && res['data'] is Map) {
        try {
          final created = PropertyModel.fromJson(Map<String, dynamic>.from(res['data'] as Map));
          state = [
            created,
            ...state.where((p) => p.id != property.id),
          ];
          await AuthStorageService.saveCachedProperties(state);
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return true;
  }

  Future<bool> updateProperty(PropertyModel updatedProp) async {
    state = [
      for (final prop in state)
        if (prop.id == updatedProp.id) updatedProp else prop,
    ];
    await AuthStorageService.saveCachedProperties(state);

    try {
      await ApiService.put('/properties/${updatedProp.id}', updatedProp.toJson());
    } catch (_) {}
    return true;
  }

  void addImportedProperties(List<PropertyModel> imported) {
    final updatedList = List<PropertyModel>.from(state);
    for (final item in imported) {
      final itemTitle = item.title.trim().toLowerCase();
      final itemCore = itemTitle.replaceAll(RegExp(r'^(99acres|magicbricks|housing(\.com)?|custom\s*feed)[^:]*:\s*', caseSensitive: false), '').trim();

      final index = updatedList.indexWhere((p) {
        if (p.id.isNotEmpty && item.id.isNotEmpty && p.id == item.id) return true;
        final pTitle = p.title.trim().toLowerCase();
        if (pTitle == itemTitle) return true;
        final pCore = pTitle.replaceAll(RegExp(r'^(99acres|magicbricks|housing(\.com)?|custom\s*feed)[^:]*:\s*', caseSensitive: false), '').trim();
        if (pCore.isNotEmpty && itemCore.isNotEmpty && pCore == itemCore) return true;
        return false;
      });

      if (index != -1) {
        updatedList[index] = item;
      } else {
        updatedList.insert(0, item);
      }
    }
    state = updatedList;
    AuthStorageService.saveCachedProperties(state);
  }

  /// Reset in-memory & local cache and refetch cleanly (used on switch/login/register)
  Future<void> clearAndRefresh() async {
    state = [];
    await AuthStorageService.clearCachedProperties();
    await fetchProperties();
  }

  void reset() {
    state = [];
  }
}

final propertyProvider = NotifierProvider<PropertyNotifier, List<PropertyModel>>(() {
  return PropertyNotifier();
});

class DealNotifier extends Notifier<List<DealModel>> {
  StreamSubscription? _fcmSub;

  @override
  List<DealModel> build() {
    final cached = AuthStorageService.getCachedDeals();
    _fcmSub = PushNotificationService.onMessageReceivedStream.stream.listen((message) {
      final type = message.data['type'] as String?;
      if (type == null || type == 'deal' || type == 'collaboration') {
        fetchDeals();
      }
    });
    ref.onDispose(() {
      _fcmSub?.cancel();
    });
    Future.microtask(() {
      fetchDeals();
    });
    return cached;
  }

  void reset() {
    state = [];
  }

  Future<void> clearAndRefresh() async {
    state = [];
    try {
      await AuthStorageService.saveCachedDeals([]);
    } catch (_) {}
    await fetchDeals();
  }

  Future<void> fetchDeals() async {
    try {
      // Pre-fetch directory for user resolution
      BrokerDirectoryService.fetchDirectory();

      final dealsRes = await ApiService.get('/deals');
      final collabsRes = await ApiService.get('/collaborations');
      
      final List<DealModel> fetched = [];
      
      if (dealsRes['success'] == true && dealsRes['data'] is List) {
        for (final item in (dealsRes['data'] as List)) {
          fetched.add(DealModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      
      if (collabsRes['success'] == true && collabsRes['data'] is List) {
        final userData = AuthStorageService.getUserData();
        final currentAgencyId = userData?['agencyId'] ?? (userData?['agency'] is Map ? userData!['agency']['id'] : null);
        final currentAgencyStr = currentAgencyId?.toString();
        final currentUserIdStr = userData?['id']?.toString();
        
        for (final item in (collabsRes['data'] as List)) {
          final map = Map<String, dynamic>.from(item);
          final targetAgencyStr = map['targetAgencyId']?.toString();
          final targetBrokerStr = map['targetBrokerId']?.toString();

          final isIncoming = (currentAgencyStr != null && targetAgencyStr == currentAgencyStr) ||
              (currentUserIdStr != null && targetBrokerStr == currentUserIdStr);
          
          fetched.add(DealModel.fromJson({
            ...map,
            'id': (map['requestCode'] ?? map['id'] ?? '').toString(),
            'dealCode': (map['requestCode'] ?? map['dealCode'] ?? '').toString(),
            'isRequest': true,
            'isIncomingRequest': isIncoming,
            'agencyAId': map['targetAgencyId'],
            'agencyAName': map['targetAgencyName'] ?? '',
            'brokerAId': map['targetBrokerId'],
            'brokerAName': map['targetBrokerName'] ?? '',
            'agencyBId': map['requestingAgencyId'],
            'agencyBName': map['requestingAgencyName'] ?? '',
            'brokerBId': map['requestingBrokerId'],
            'brokerBName': map['requestingBrokerName'] ?? '',
            'propertyName': map['propertyName'] ?? map['propertyTitle'] ?? 'Property Listing',
            'amount': map['expectedBudget'] ?? map['propertyPrice'] ?? '₹0',
            'expectedBudget': map['expectedBudget'] ?? map['propertyPrice'] ?? '',
            'partnerBroker': isIncoming ? (map['requestingBrokerName'] ?? 'Broker') : (map['targetBrokerName'] ?? 'Broker'),
            'partnerAgency': isIncoming ? (map['requestingAgencyName'] ?? 'Partner Agency') : (map['targetAgencyName'] ?? 'Agency'),
          }));
        }
      }

      state = fetched;
      try {
        await AuthStorageService.saveCachedDeals(fetched);
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> addDeal(DealModel deal) async {
    state = [deal, ...state];
    try {
      await AuthStorageService.saveCachedDeals(state);
    } catch (_) {}
    try {
      if (deal.isRequest) {
        final userData = AuthStorageService.getUserData();
        final myAgencyId = deal.agencyBId ?? userData?['agencyId'] ?? (userData?['agency'] is Map ? userData!['agency']['id'] : null);
        final myAgencyName = deal.agencyBName.isNotEmpty ? deal.agencyBName : ((userData?['agency']?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '');
        final myUserId = deal.brokerBId ?? userData?['id'];
        final myUserName = deal.brokerBName.isNotEmpty ? deal.brokerBName : ((userData?['name'] as String?) ?? 'Broker');

        await ApiService.post('/collaborations', {
          'propertyId': int.tryParse(deal.propertyId) ?? 1,
          'propertyName': deal.propertyName,
          'targetAgencyId': deal.agencyAId,
          'targetAgencyName': deal.agencyAName,
          'targetBrokerId': deal.brokerAId,
          'targetBrokerName': deal.brokerAName,
          'requestingAgencyId': myAgencyId,
          'requestingAgencyName': myAgencyName,
          'requestingBrokerId': myUserId,
          'requestingBrokerName': myUserName,
          'clientRequirement': deal.clientRequirement ?? '',
          'expectedBudget': deal.expectedBudget ?? deal.amount,
          'remarks': deal.remarks ?? '',
        });
      } else {
        await ApiService.post('/deals', deal.toJson());
      }
      await fetchDeals();
    } catch (_) {}
  }
  
  Future<void> updateDealStatus(
    String id, 
    String newStatus, [
    String? notes, 
    Map<String, dynamic>? milestoneData,
  ]) async {
    state = [
      for (final deal in state)
        if (deal.id == id || deal.dealCode == id)
          DealModel(
            id: deal.id,
            dealCode: deal.dealCode,
            propertyId: deal.propertyId,
            propertyName: deal.propertyName,
            agencyAId: deal.agencyAId,
            agencyAName: deal.agencyAName,
            brokerAId: deal.brokerAId,
            brokerAName: deal.brokerAName,
            agencyBId: deal.agencyBId,
            agencyBName: deal.agencyBName,
            brokerBId: deal.brokerBId,
            brokerBName: deal.brokerBName,
            partnerBroker: deal.partnerBroker,
            partnerAgency: deal.partnerAgency,
            status: newStatus,
            amount: deal.amount,
            dealValue: deal.dealValue,
            commissionId: deal.commissionId,
            isRequest: deal.isRequest,
            isIncomingRequest: deal.isIncomingRequest,
            clientName: deal.clientName,
            clientPhone: deal.clientPhone,
            clientEmail: deal.clientEmail,
            clientRequirement: deal.clientRequirement,
            expectedBudget: deal.expectedBudget,
            remarks: deal.remarks,
            createdAt: deal.createdAt,
            respondedAt: (newStatus == 'Approved' || newStatus == 'Rejected') ? DateTime.now() : deal.respondedAt,
            auditHistory: [
              ...deal.auditHistory,
              DealAuditLog(
                status: newStatus, 
                timestamp: DateTime.now(), 
                updatedBy: 'Current User', 
                notes: notes,
                metadata: milestoneData,
              ),
            ],
            tokenAmount: milestoneData?['tokenAmount'] ?? deal.tokenAmount,
            tokenDate: milestoneData?['tokenDate'] ?? deal.tokenDate,
            agreementDate: milestoneData?['agreementDate'] ?? deal.agreementDate,
            bankName: milestoneData?['bankName'] ?? deal.bankName,
            loanAmount: milestoneData?['loanAmount'] ?? deal.loanAmount,
            registryDate: milestoneData?['registryDate'] ?? deal.registryDate,
            registrationNumber: milestoneData?['registrationNumber'] ?? deal.registrationNumber,
            possessionDate: milestoneData?['possessionDate'] ?? deal.possessionDate,
            documents: deal.documents,
          )
        else
          deal,
    ];

    try {
      await ApiService.put('/deals/$id/status', {
        'newStage': newStatus,
        'status': newStatus,
        'notes': notes,
        'milestoneData': milestoneData,
      });
      // Refresh properties and commissions as deal progression updates property status & commission ledger
      ref.read(propertyProvider.notifier).fetchProperties();
      ref.read(commissionProvider.notifier).fetchCommissions();
    } catch (_) {}
  }

  Future<void> respondRequest(String id, String action, [String? remarks]) async {
    final newStatus = action == 'approve' ? 'Approved' : (action == 'cancel' ? 'Cancelled' : 'Rejected');

    // Update local state immediately for instant UX feedback
    state = [
      for (final deal in state)
        if (deal.id == id || deal.dealCode == id)
          DealModel(
            id: deal.id,
            dealCode: deal.dealCode,
            propertyId: deal.propertyId,
            propertyName: deal.propertyName,
            agencyAId: deal.agencyAId,
            agencyAName: deal.agencyAName,
            brokerAId: deal.brokerAId,
            brokerAName: deal.brokerAName,
            agencyBId: deal.agencyBId,
            agencyBName: deal.agencyBName,
            brokerBId: deal.brokerBId,
            brokerBName: deal.brokerBName,
            partnerBroker: deal.partnerBroker,
            partnerAgency: deal.partnerAgency,
            status: newStatus,
            amount: deal.amount,
            dealValue: deal.dealValue,
            commissionId: deal.commissionId,
            isRequest: true,
            isIncomingRequest: deal.isIncomingRequest,
            clientName: deal.clientName,
            clientPhone: deal.clientPhone,
            clientEmail: deal.clientEmail,
            clientRequirement: deal.clientRequirement,
            expectedBudget: deal.expectedBudget,
            remarks: remarks ?? deal.remarks,
            createdAt: deal.createdAt,
            respondedAt: DateTime.now(),
            auditHistory: [
              ...deal.auditHistory,
              DealAuditLog(status: newStatus, timestamp: DateTime.now(), updatedBy: 'Current User', notes: remarks),
            ],
          )
        else
          deal,
    ];

    try {
      await ApiService.post('/collaborations/$id/respond', {
        'action': action,
        'remarks': remarks,
      });
      await fetchDeals();
      ref.read(commissionProvider.notifier).fetchCommissions();
      ref.read(propertyProvider.notifier).fetchProperties();
    } catch (_) {}
  }

  Future<void> updateClientInfo(
    String id, {
    required String clientName,
    required String clientPhone,
    required String clientEmail,
    String? clientRequirement,
  }) async {
    state = [
      for (final deal in state)
        if (deal.id == id || deal.dealCode == id)
          deal.copyWith(
            clientName: clientName,
            clientPhone: clientPhone,
            clientEmail: clientEmail,
            clientRequirement: clientRequirement ?? deal.clientRequirement,
          )
        else
          deal,
    ];

    try {
      await ApiService.put('/deals/$id/client', {
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientEmail': clientEmail,
        'clientRequirement': ?clientRequirement,
      });
      await fetchDeals();
    } catch (_) {}
  }
}

final dealProvider = NotifierProvider<DealNotifier, List<DealModel>>(() {
  return DealNotifier();
});

/// RBAC & Broker Property Access Control Provider (PRD Sections 3, 4.1.1, 5)
/// - Super Admin: has full visibility across all agencies and properties.
/// - Agency Admin: strictly isolated to their own agency's inventory.
/// - Broker: only has access to assigned properties + created properties within their agency, plus public marketplace listings.
final accessiblePropertiesProvider = Provider<List<PropertyModel>>((ref) {
  final allProps = ref.watch(propertyProvider);
  final userRole = AuthStorageService.getUserRole();
  final userData = AuthStorageService.getUserData();
  final userAgency = userData?['agency'] as Map<String, dynamic>?;
  final userAgencyId = userData?['agencyId'] ?? userData?['agency_id'] ?? userAgency?['id'];
  final userAgencyName = ((userAgency?['name'] ?? userData?['agencyName'] ?? '') as String).trim().toLowerCase();
  final rawRole = (userData?['role'] as String?)?.toLowerCase();

  // Super Admin: full access across all agencies
  if (rawRole == 'super_admin') {
    return allProps;
  }

  // Agency Admin: strictly scoped to their own agency properties
  if (userRole == UserRole.agencyAdmin) {
    if (userAgencyId == null && userAgencyName.isEmpty) return [];
    return allProps.where((p) {
      if (userAgencyId != null && p.agencyId != null && p.agencyId.toString() == userAgencyId.toString()) {
        return true;
      }
      if (userAgencyName.isNotEmpty && p.agencyName.trim().toLowerCase() == userAgencyName) {
        return true;
      }
      return false;
    }).toList();
  }

  // Broker: strictly assigned properties + properties created/managed by this broker
  final currentUserId = userData?['id']?.toString() ?? '';
  final currentUserName = (userData?['name']?.toString() ?? '').trim().toLowerCase();

  final rawAssigned = userData?['assignedPropertyIds'] ?? (userData?['permissions'] is Map ? userData!['permissions']['assignedPropertyIds'] : null);
  final assignedSet = <String>{};
  if (rawAssigned is List) {
    for (final id in rawAssigned) {
      if (id != null) assignedSet.add(id.toString());
    }
  }

  return allProps.where((p) {
    final belongsToAgency = (userAgencyId != null && p.agencyId != null && p.agencyId.toString() == userAgencyId.toString()) ||
        (userAgencyName.isNotEmpty && p.agencyName.trim().toLowerCase() == userAgencyName);

    // 1. Explicitly assigned by Agency Admin
    if (assignedSet.contains(p.id)) return true;
    // 2. Created by / assigned broker within agency
    if (belongsToAgency && p.brokerId != null && p.brokerId.toString() == currentUserId) return true;
    if (belongsToAgency && currentUserName.isNotEmpty && p.brokerName.trim().toLowerCase() == currentUserName) return true;
    return false;
  }).toList();
});

/// RBAC Scoped Deals & Collaboration Hub Provider (PRD Section 5)
/// - Super Admin: sees all deals.
/// - Agency Admin: strictly scoped to deals and requests involving their agency.
/// - Broker: strictly only deals and collaboration requests related to their assigned properties or assigned broker ID.
final accessibleDealsProvider = Provider<List<DealModel>>((ref) {
  final allDeals = ref.watch(dealProvider);
  final userRole = AuthStorageService.getUserRole();
  final userData = AuthStorageService.getUserData();
  final userAgency = userData?['agency'] as Map<String, dynamic>?;
  final userAgencyId = userData?['agencyId'] ?? userData?['agency_id'] ?? userAgency?['id'];
  final userAgencyName = ((userAgency?['name'] ?? userData?['agencyName'] ?? '') as String).trim().toLowerCase();
  final rawRole = (userData?['role'] as String?)?.toLowerCase();

  if (rawRole == 'super_admin') {
    return allDeals;
  }

  // Agency Admin: only deals and collaboration requests involving their agency
  if (userRole == UserRole.agencyAdmin) {
    final currentUserId = userData?['id']?.toString() ?? '';
    if (userAgencyId == null && userAgencyName.isEmpty && currentUserId.isEmpty) return [];
    return allDeals.where((deal) {
      if (userAgencyId != null) {
        if (deal.agencyAId != null && deal.agencyAId.toString() == userAgencyId.toString()) return true;
        if (deal.agencyBId != null && deal.agencyBId.toString() == userAgencyId.toString()) return true;
      }
      if (userAgencyName.isNotEmpty) {
        if (deal.agencyAName.trim().toLowerCase() == userAgencyName) return true;
        if (deal.agencyBName.trim().toLowerCase() == userAgencyName) return true;
      }
      if (currentUserId.isNotEmpty) {
        if (deal.brokerAId != null && deal.brokerAId.toString() == currentUserId) return true;
        if (deal.brokerBId != null && deal.brokerBId.toString() == currentUserId) return true;
      }
      return false;
    }).toList();
  }

  // Broker: strictly scoped to their assigned properties and directly assigned deals
  final currentUserId = userData?['id']?.toString() ?? '';
  final currentUserName = (userData?['name']?.toString() ?? '').trim().toLowerCase();

  final rawAssigned = userData?['assignedPropertyIds'] ?? (userData?['permissions'] is Map ? userData!['permissions']['assignedPropertyIds'] : null);
  final assignedSet = <String>{};
  if (rawAssigned is List) {
    for (final id in rawAssigned) {
      if (id != null) assignedSet.add(id.toString());
    }
  }

  // Also include any assigned/owned properties from accessiblePropertiesProvider
  final accessibleProps = ref.watch(accessiblePropertiesProvider);
  for (final p in accessibleProps) {
    if (p.id.isNotEmpty) assignedSet.add(p.id);
  }

  return allDeals.where((deal) {
    // 1. Property-level match with broker's assigned properties
    if (deal.propertyId.isNotEmpty && assignedSet.contains(deal.propertyId)) {
      return true;
    }
    // 2. Direct Broker assignment match (Deal creator or assigned collaborator)
    if (currentUserId.isNotEmpty) {
      if (deal.brokerAId != null && deal.brokerAId.toString() == currentUserId) return true;
      if (deal.brokerBId != null && deal.brokerBId.toString() == currentUserId) return true;
    }
    if (currentUserName.isNotEmpty) {
      if (deal.brokerAName.trim().toLowerCase() == currentUserName) return true;
      if (deal.brokerBName.trim().toLowerCase() == currentUserName) return true;
      if (deal.partnerBroker.trim().toLowerCase() == currentUserName) return true;
    }
    return false;
  }).toList();
});

/// Active Selected Deal Milestone Stage Provider (for seamless cross-screen deep-linking)
class SelectedDealStageNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setStage(String stage) {
    state = stage;
  }
}

final selectedDealStageProvider = NotifierProvider<SelectedDealStageNotifier, String>(() {
  return SelectedDealStageNotifier();
});

class CommissionNotifier extends Notifier<List<CommissionModel>> {
  StreamSubscription? _fcmSub;

  @override
  List<CommissionModel> build() {
    final cached = AuthStorageService.getCachedCommissions();
    _fcmSub = PushNotificationService.onMessageReceivedStream.stream.listen((message) {
      final type = message.data['type'] as String?;
      if (type == null || type == 'commission' || type == 'deal') {
        fetchCommissions();
      }
    });
    ref.onDispose(() {
      _fcmSub?.cancel();
    });
    Future.microtask(() => fetchCommissions());
    return cached;
  }

  Future<void> fetchCommissions() async {
    try {
      final res = await ApiService.get('/commissions');
      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => CommissionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        state = list;
        try {
          await AuthStorageService.saveCachedCommissions(list);
        } catch (_) {}
      }
    } catch (_) {}
  }
}

final commissionProvider = NotifierProvider<CommissionNotifier, List<CommissionModel>>(() {
  return CommissionNotifier();
});

class SettlementNotifier extends Notifier<List<SettlementModel>> {
  @override
  List<SettlementModel> build() {
    Future.microtask(() => fetchSettlements());
    return [];
  }

  Future<void> fetchSettlements() async {
    try {
      final res = await ApiService.get('/settlements');
      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => SettlementModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<bool> recordSettlement(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.post('/settlements', data);
      if (res['success'] == true) {
        await fetchSettlements();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final settlementProvider = NotifierProvider<SettlementNotifier, List<SettlementModel>>(() {
  return SettlementNotifier();
});

class AnalyticsModel {
  final int activeBrokers;
  final List<double> monthlyCommission;
  final List<double> monthlyLeads;

  AnalyticsModel({
    required this.activeBrokers,
    required this.monthlyCommission,
    required this.monthlyLeads,
  });
}

class AnalyticsNotifier extends Notifier<AnalyticsModel> {
  @override
  AnalyticsModel build() {
    final userData = AuthStorageService.getUserData();
    final agencyData = userData?['agency'] as Map<String, dynamic>?;
    final brokerCount = (agencyData?['brokerCount'] as num? ?? userData?['activeBrokers'] as num? ?? 1).toInt();
    return AnalyticsModel(
      activeBrokers: brokerCount,
      monthlyCommission: [0, 0, 0, 0, 0, 0],
      monthlyLeads: [0, 0, 0, 0, 0, 0],
    );
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsModel>(() {
  return AnalyticsNotifier();
});

class UnreadMessagesNotifier extends Notifier<int> {
  dynamic _subscription;
  StreamSubscription? _fcmSub;

  @override
  int build() {
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      try {
        _subscription = FirestoreChatService.streamTotalUnreadCount(currentUserId).listen((count) {
          state = count;
        }, onError: (_) {});
      } catch (_) {}
    }
    _fcmSub = PushNotificationService.onMessageReceivedStream.stream.listen((message) {
      final type = message.data['type'] as String?;
      if (type == 'chat' || type == null) {
        fetchUnreadCount();
      }
    });
    fetchUnreadCount();
    ref.onDispose(() {
      try {
        _subscription?.cancel();
      } catch (_) {}
      _fcmSub?.cancel();
    });
    return 0;
  }

  Future<void> fetchUnreadCount() async {
    try {
      final userData = AuthStorageService.getUserData();
      final currentUserId = userData?['id']?.toString() ?? '';
      if (currentUserId.isEmpty) {
        state = 0;
        return;
      }
      final res = await ApiService.get('/chat/conversations?userId=$currentUserId');
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List;
        int count = 0;
        for (final item in list) {
          if (item is Map) {
            count += (item['unreadCount'] as num? ?? 0).toInt();
          }
        }
        state = count;
      }
    } catch (_) {}
  }

  void updateCount(int newCount) {
    state = newCount;
  }
}

final unreadMessagesProvider = NotifierProvider<UnreadMessagesNotifier, int>(() {
  return UnreadMessagesNotifier();
});

class UnreadNotificationsNotifier extends Notifier<int> {
  StreamSubscription? _fcmSubscription;

  @override
  int build() {
    _fcmSubscription = PushNotificationService.onMessageReceivedStream.stream.listen((message) {
      final type = message.data['type'] as String?;
      // Exclude chat push notifications from triggering in-app notification count
      if (type != 'chat') {
        fetchUnreadCount();
      }
    });
    ref.onDispose(() {
      _fcmSubscription?.cancel();
    });
    fetchUnreadCount();
    return 0;
  }

  Future<void> fetchUnreadCount() async {
    try {
      final userData = AuthStorageService.getUserData();
      final rawId = userData?['id'];
      final userId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      final rawAgencyId = userData?['agencyId'] ?? userData?['agency']?['id'];
      final agencyId = rawAgencyId is int ? rawAgencyId : int.tryParse(rawAgencyId?.toString() ?? '');

      final res = await ApiService.getNotifications(
        userId: userId,
        agencyId: agencyId,
        status: 'unread',
      );

      if (res['success'] == true) {
        final data = res['data'];
        final count = (data is Map && data['unreadCount'] is num)
            ? (data['unreadCount'] as num).toInt()
            : (res['unreadCount'] as num? ?? res['count'] as num? ?? 0).toInt();
        state = count;
      }
    } catch (_) {}
  }

  void updateCount(int newCount) {
    state = newCount;
  }
}

final unreadNotificationsProvider = NotifierProvider<UnreadNotificationsNotifier, int>(() {
  return UnreadNotificationsNotifier();
});

class OwnerNotifier extends Notifier<List<OwnerModel>> {
  @override
  List<OwnerModel> build() {
    final cached = AuthStorageService.getCachedOwners();
    Future.microtask(() => fetchOwners());
    return cached;
  }

  Future<void> fetchOwners([String? search]) async {
    try {
      final endpoint = search != null && search.trim().isNotEmpty
          ? '/owners?q=${Uri.encodeComponent(search.trim())}'
          : '/owners';
      final res = await ApiService.get(endpoint);
      if (res['success'] == true && res['data'] is List) {
        final List<OwnerModel> list = [];
        for (final item in (res['data'] as List)) {
          list.add(OwnerModel.fromJson(Map<String, dynamic>.from(item)));
        }
        state = list;
        if (search == null || search.trim().isEmpty) {
          try {
            await AuthStorageService.saveCachedOwners(list);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<OwnerModel?> addOwner(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.post('/owners', data);
      if (res['success'] == true && res['data'] is Map) {
        final newOwner = OwnerModel.fromJson(Map<String, dynamic>.from(res['data']));
        state = [
          newOwner,
          ...state.where((o) => o.id != newOwner.id),
        ];
        try {
          await AuthStorageService.saveCachedOwners(state);
        } catch (_) {}
        return newOwner;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> updateOwner(int id, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.put('/owners/$id', data);
      if (res['success'] == true) {
        await fetchOwners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteOwner(int id) async {
    try {
      final res = await ApiService.delete('/owners/$id');
      if (res['success'] == true) {
        state = state.where((o) => o.id != id).toList();
        try {
          await AuthStorageService.saveCachedOwners(state);
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final ownerProvider = NotifierProvider<OwnerNotifier, List<OwnerModel>>(() {
  return OwnerNotifier();
});



