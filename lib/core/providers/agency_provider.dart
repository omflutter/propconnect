import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_model.dart';
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

  void setBrokers(List<BrokerModel> brokers) {
    state = state.copyWith(brokers: brokers);
  }

  void updateAgencyDetails(String name, String rera, String email, String address) {
    state = state.copyWith(name: name, reraNumber: rera, email: email, address: address);
  }

  void addBroker(String name, String email, String phone, String role, {String? id}) {
    final newBroker = BrokerModel(
      id: id ?? 'b${Random().nextInt(10000)}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      isActive: true,
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

  void updateBroker(String id, String name, String email, String phone, String role) {
    final updatedBrokers = state.brokers.map((b) {
      if (b.id == id) {
        return b.copyWith(name: name, email: email, phone: phone, role: role);
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
