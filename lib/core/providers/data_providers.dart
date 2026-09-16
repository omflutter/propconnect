import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../models/deal_model.dart';
import '../models/commission_model.dart';
import '../network/api_service.dart';
import '../services/firestore_chat_service.dart';
import '../services/auth_storage_service.dart';

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
      if (res['success'] == true && res['data'] != null) {
        final list = (res['data'] as List)
            .map((item) => PropertyModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = list;
        await AuthStorageService.saveCachedProperties(list);
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
    await AuthStorageService.saveCachedProperties(state);

    try {
      final res = await ApiService.post('/properties', property.toJson());
      if (res['success'] == true && res['data'] != null) {
        final created = PropertyModel.fromJson(res['data'] as Map<String, dynamic>);
        state = [
          created,
          ...state.where((p) => p.id != property.id),
        ];
        await AuthStorageService.saveCachedProperties(state);
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
      final index = updatedList.indexWhere(
        (p) => p.id == item.id || (p.title.trim().toLowerCase() == item.title.trim().toLowerCase() && p.agencyName == item.agencyName),
      );
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
    return _initialMockDeals();
  }

  List<DealModel> _initialMockDeals() {
    final now = DateTime.now();
    return [
      DealModel(id: 'D-1256', dealCode: 'DL-501', propertyId: 'P-101', propertyName: '3 BHK Apartment', partnerBroker: 'Rahul Singh', partnerAgency: 'Singh Realty', status: 'Token Done', amount: '₹1.25 Cr', dealValue: 12500000, createdAt: now.subtract(const Duration(days: 2))),
      DealModel(id: 'D-1255', dealCode: 'DL-502', propertyId: 'P-103', propertyName: '4 BHK Villa', partnerBroker: 'Neha Gupta', partnerAgency: 'Sunrise Properties', status: 'Negotiation', amount: '₹3.50 Cr', dealValue: 35000000, createdAt: now.subtract(const Duration(days: 5))),
      DealModel(id: 'D-1254', dealCode: 'DL-503', propertyId: 'P-102', propertyName: 'Office Space', partnerBroker: 'Vikram Joshi', partnerAgency: 'Elite Real Estate', status: 'Agreement Signed', amount: '₹1.20 Cr', dealValue: 12000000, createdAt: now.subtract(const Duration(days: 10))),
      // Sent Requests (isRequest: true, isIncomingRequest: false)
      DealModel(id: 'R-001', dealCode: 'REQ-101', propertyId: 'P-103', propertyName: 'Luxury Penthouse', partnerBroker: 'Arun Sharma', partnerAgency: 'Skyline Homes', status: 'Pending', amount: '₹5.5 Cr', dealValue: 55000000, isRequest: true, clientRequirement: 'Client is looking for a sea-facing penthouse with a private pool.', remarks: 'Urgent requirement, client is moving in next month.', createdAt: now.subtract(const Duration(hours: 2))),
      // Incoming Requests (isRequest: true, isIncomingRequest: true)
      DealModel(id: 'R-002', dealCode: 'REQ-102', propertyId: 'P-102', propertyName: 'Retail Shop', partnerBroker: 'Kiran Patel', partnerAgency: 'Prime Spaces', status: 'Pending', amount: '₹80 L', dealValue: 8000000, isRequest: true, isIncomingRequest: true, clientRequirement: 'Need a shop with heavy footfall for a bakery.', createdAt: now.subtract(const Duration(hours: 5))),
      // Responded Requests (isRequest: false, but status shows it was a request)
      DealModel(id: 'R-003', dealCode: 'REQ-103', propertyId: 'P-103', propertyName: 'Sea-Facing Villa', partnerBroker: 'Ravi Verma', partnerAgency: 'Verma Properties', status: 'Rejected', amount: '₹12 Cr', dealValue: 120000000, isRequest: false, isIncomingRequest: true, clientRequirement: 'Requires 4 parking spots minimum.', createdAt: now.subtract(const Duration(days: 1)), respondedAt: now.subtract(const Duration(hours: 10))),
      DealModel(id: 'R-004', dealCode: 'REQ-104', propertyId: 'P-104', propertyName: 'Cozy Apartment', partnerBroker: 'Neha Gupta', partnerAgency: 'Sunrise Properties', status: 'Approved', amount: '₹1.2 Cr', dealValue: 12000000, isRequest: false, isIncomingRequest: true, clientRequirement: 'Fully furnished required for a young couple.', remarks: 'Let me know if price is negotiable.', createdAt: now.subtract(const Duration(days: 2)), respondedAt: now.subtract(const Duration(days: 1))),
      // Sent Requests that they responded to
      DealModel(id: 'R-005', dealCode: 'REQ-105', propertyId: 'P-101', propertyName: '3 BHK Apartment', partnerBroker: 'Amit Patel', partnerAgency: 'Patel Realty', status: 'Approved', amount: '₹3.4 Cr', dealValue: 34000000, isRequest: false, isIncomingRequest: false, createdAt: now.subtract(const Duration(days: 4)), respondedAt: now.subtract(const Duration(days: 3))),
    ];
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

      if (fetched.isNotEmpty) {
        state = fetched;
      }
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
    return _initialMockCommissions();
  }

  List<CommissionModel> _initialMockCommissions() {
    return [
      CommissionModel(
        id: '1',
        commissionCode: 'COMM-801',
        dealId: 'DL-501',
        dealValue: 12500000,
        commissionType: 'Percentage',
        commissionRate: 2.0,
        totalCommission: 250000,
        brokerASharePct: 50.0,
        brokerBSharePct: 50.0,
        brokerAAmount: 125000,
        brokerBAAmount: 125000,
        status: 'Settled',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      CommissionModel(
        id: '2',
        commissionCode: 'COMM-802',
        dealId: 'DL-502',
        dealValue: 35000000,
        commissionType: 'Percentage',
        commissionRate: 2.0,
        totalCommission: 700000,
        brokerASharePct: 50.0,
        brokerBSharePct: 50.0,
        brokerAAmount: 350000,
        brokerBAAmount: 350000,
        status: 'Partial',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      CommissionModel(
        id: '3',
        commissionCode: 'COMM-803',
        dealId: 'DL-503',
        dealValue: 12000000,
        commissionType: 'Percentage',
        commissionRate: 2.0,
        totalCommission: 240000,
        brokerASharePct: 50.0,
        brokerBSharePct: 50.0,
        brokerAAmount: 120000,
        brokerBAAmount: 120000,
        status: 'Pending',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];
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
    return _initialMockSettlements();
  }

  List<SettlementModel> _initialMockSettlements() {
    return [
      SettlementModel(
        id: '1',
        settlementCode: 'SET-901',
        commissionId: '1',
        dealId: 'DL-501',
        amountReceived: 250000,
        amountPending: 0,
        paymentMethod: 'NEFT',
        referenceNumber: 'NEFT-88910248',
        settlementDate: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Received',
      ),
      SettlementModel(
        id: '2',
        settlementCode: 'SET-902',
        commissionId: '2',
        dealId: 'DL-502',
        amountReceived: 350000,
        amountPending: 350000,
        paymentMethod: 'UPI',
        referenceNumber: 'UPI-99281729',
        settlementDate: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Pending',
      ),
    ];
  }

  Future<void> fetchSettlements() async {
    try {
      final res = await ApiService.get('/commissions/settlements');
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
      final res = await ApiService.post('/commissions/settlements', data);
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
    return AnalyticsModel(
      activeBrokers: 12, // Number of brokers in 'Sunrise Properties'
      monthlyCommission: [120000, 150000, 180000, 100000, 250000, 300000],
      monthlyLeads: [5, 8, 12, 10, 18, 25],
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


