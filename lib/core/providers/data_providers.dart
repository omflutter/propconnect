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
  @override
  List<PropertyModel> build() {
    final cached = AuthStorageService.getCachedProperties();
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
}

final propertyProvider = NotifierProvider<PropertyNotifier, List<PropertyModel>>(() {
  return PropertyNotifier();
});

class DealNotifier extends Notifier<List<DealModel>> {
  @override
  List<DealModel> build() {
    Future.microtask(() {
      fetchDeals();
    });
    return [];
  }

  Future<void> fetchDeals() async {
    try {
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
        
        for (final item in (collabsRes['data'] as List)) {
          final map = Map<String, dynamic>.from(item);
          final isIncoming = currentAgencyId != null && map['targetAgencyId'].toString() == currentAgencyId.toString();
          
          fetched.add(DealModel.fromJson({
            ...map,
            'isRequest': map['status'] == 'Pending',
            'isIncomingRequest': isIncoming,
            'propertyName': map['propertyTitle'] ?? 'Property Inquiry',
            'amount': map['expectedBudget'] ?? '₹0',
            'partnerBroker': isIncoming ? map['requestingBrokerName'] : map['targetBrokerName'],
            'partnerAgency': isIncoming ? map['requestingAgencyName'] : map['targetAgencyName'],
          }));
        }
      }

      state = fetched;
    } catch (_) {}
  }

  Future<void> addDeal(DealModel deal) async {
    state = [deal, ...state];
    try {
      if (deal.isRequest) {
        await ApiService.post('/collaborations', deal.toJson());
      } else {
        await ApiService.post('/deals', deal.toJson());
      }
      await fetchDeals();
    } catch (_) {}
  }
  
  Future<void> updateDealStatus(String id, String newStatus, [String? notes]) async {
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
            isRequest: (newStatus == 'Approved' || newStatus == 'Rejected') ? false : deal.isRequest,
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
              DealAuditLog(status: newStatus, timestamp: DateTime.now(), updatedBy: 'Current User', notes: notes),
            ],
          )
        else
          deal,
    ];

    try {
      await ApiService.put('/deals/$id/status', {
        'status': newStatus,
        'notes': notes,
      });
      // Refresh properties as deal progression might update property status (PRD Sec 9)
      ref.read(propertyProvider.notifier).fetchProperties();
    } catch (_) {}
  }

  Future<void> respondRequest(String id, String action, [String? remarks]) async {
    final newStatus = action == 'approve' ? 'Approved' : 'Rejected';
    updateDealStatus(id, newStatus, remarks);

    try {
      await ApiService.post('/collaborations/$id/respond', {
        'action': action,
        'remarks': remarks,
      });
      await fetchDeals();
      ref.read(commissionProvider.notifier).fetchCommissions();
    } catch (_) {}
  }
}

final dealProvider = NotifierProvider<DealNotifier, List<DealModel>>(() {
  return DealNotifier();
});

class CommissionNotifier extends Notifier<List<CommissionModel>> {
  @override
  List<CommissionModel> build() {
    Future.microtask(() => fetchCommissions());
    return [];
  }

  Future<void> fetchCommissions() async {
    try {
      final res = await ApiService.get('/commissions');
      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => CommissionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        state = list;
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
    fetchUnreadCount();
    ref.onDispose(() {
      try {
        _subscription?.cancel();
      } catch (_) {}
    });
    return 0;
  }

  Future<void> fetchUnreadCount() async {
    try {
      final userData = AuthStorageService.getUserData();
      final currentUserId = userData?['id']?.toString() ?? '1';
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
    _fcmSubscription = PushNotificationService.onMessageReceivedStream.stream.listen((_) {
      fetchUnreadCount();
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
        final count = (res['unreadCount'] as num? ?? res['count'] as num? ?? 0).toInt();
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
    fetchOwners();
    return [];
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
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final ownerProvider = NotifierProvider<OwnerNotifier, List<OwnerModel>>(() {
  return OwnerNotifier();
});



