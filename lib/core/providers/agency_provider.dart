import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_model.dart';
import '../network/api_service.dart';
import 'dart:math';

class AgencyNotifier extends Notifier<AgencyModel> {
  @override
  AgencyModel build() {
    return AgencyModel(
      id: '',
      name: '',
      reraNumber: '',
      email: '',
      address: '',
      brokers: const [],
    );
  }

  Future<List<BrokerModel>> fetchBrokers({dynamic agencyId}) async {
    try {
      final endpoint = agencyId != null ? '/brokers?agencyId=$agencyId' : '/brokers';
      final res = await ApiService.get(endpoint);
      if (res['success'] == true && res['data'] is List) {
        final rawList = res['data'] as List;
        final fetchedBrokers = rawList.map((item) {
          final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
          return BrokerModel(
            id: map['id']?.toString() ?? '',
            name: map['name']?.toString() ?? '',
            email: map['email']?.toString() ?? '',
            phone: map['phone']?.toString() ?? '',
            role: map['role']?.toString() ?? 'Broker',
            isActive: map['status'] != 'Suspended' && map['status'] != 'Inactive',
            assignedPropertyIds: (map['assignedPropertyIds'] is List)
                ? (map['assignedPropertyIds'] as List).map((e) => e.toString()).toList()
                : const [],
          );
        }).toList();
        state = state.copyWith(brokers: fetchedBrokers);
        return fetchedBrokers;
      }
    } catch (_) {}
    return state.brokers;
  }

  void setBrokers(List<BrokerModel> brokers) {
    state = state.copyWith(brokers: brokers);
  }

  void updateAgencyDetails(String name, String rera, String email, String address) {
    state = state.copyWith(name: name, reraNumber: rera, email: email, address: address);
  }

  void addBroker(String name, String email, String phone, String role, {String? id, List<String>? assignedPropertyIds}) {
    final newBroker = BrokerModel(
      id: id ?? 'b${Random().nextInt(10000)}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      isActive: true,
      assignedPropertyIds: assignedPropertyIds ?? const [],
    );
    final exists = state.brokers.any((b) => b.id == newBroker.id || (b.email.isNotEmpty && b.email.toLowerCase() == newBroker.email.toLowerCase()));
    if (exists) {
      state = state.copyWith(
        brokers: state.brokers.map((b) => (b.id == newBroker.id || b.email.toLowerCase() == newBroker.email.toLowerCase()) ? newBroker : b).toList(),
      );
    } else {
      state = state.copyWith(brokers: [newBroker, ...state.brokers]);
    }
  }

  void updateBroker(String id, String name, String email, String phone, String role, {List<String>? assignedPropertyIds}) {
    final updatedBrokers = state.brokers.map((b) {
      if (b.id == id) {
        return b.copyWith(
          name: name,
          email: email,
          phone: phone,
          role: role,
          assignedPropertyIds: assignedPropertyIds ?? b.assignedPropertyIds,
        );
      }
      return b;
    }).toList();
    state = state.copyWith(brokers: updatedBrokers);
  }

  void deactivateBroker(String id) {
    final updatedBrokers = state.brokers.map((b) {
      if (b.id == id) {
        return b.copyWith(isActive: false);
      }
      return b;
    }).toList();
    state = state.copyWith(brokers: updatedBrokers);
  }

  void reactivateBroker(String id) {
    final updatedBrokers = state.brokers.map((b) {
      if (b.id == id) {
        return b.copyWith(isActive: true);
      }
      return b;
    }).toList();
    state = state.copyWith(brokers: updatedBrokers);
  }
}

final agencyProvider = NotifierProvider<AgencyNotifier, AgencyModel>(() {
  return AgencyNotifier();
});
