import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_model.dart';
import 'dart:math';

class AgencyNotifier extends Notifier<AgencyModel> {
  @override
  AgencyModel build() {
    return AgencyModel(
      id: 'a1',
      name: 'Sunrise Properties',
      reraNumber: 'PR/GJ/AHMEDABAD/AUDA/CAA08234',
      email: 'contact@sunriseproperties.in',
      address: '123 Business Park, SG Highway, Ahmedabad',
      brokers: [
        BrokerModel(id: 'b1', name: 'Amit Verma', email: 'amit@sunriseproperties.in', phone: '+91 9876543210', role: 'Agency Admin'),
        BrokerModel(id: 'b2', name: 'Rahul Singh', email: 'rahul@sunriseproperties.in', phone: '+91 9876543211', role: 'Broker / Agent'),
        BrokerModel(id: 'b3', name: 'Neha Gupta', email: 'neha@sunriseproperties.in', phone: '+91 9876543212', role: 'Broker / Agent'),
      ],
    );
  }

  void updateAgencyDetails(String name, String rera, String email, String address) {
    state = state.copyWith(name: name, reraNumber: rera, email: email, address: address);
  }

  void addBroker(String name, String email, String phone, String role) {
    final newBroker = BrokerModel(
      id: 'b${Random().nextInt(10000)}',
      name: name,
      email: email,
      phone: phone,
      role: role,
    );
    state = state.copyWith(brokers: [...state.brokers, newBroker]);
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
