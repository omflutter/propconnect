class BrokerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'Owner', 'Admin', 'Broker Agent'
  final bool isActive;

  BrokerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
  });

  BrokerModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
  }) {
    return BrokerModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AgencyModel {
  final String id;
  final String name;
  final String reraNumber;
  final String email;
  final String address;
  final List<BrokerModel> brokers;

  AgencyModel({
    required this.id,
    required this.name,
    required this.reraNumber,
    required this.email,
    required this.address,
    required this.brokers,
  });

  AgencyModel copyWith({
    String? name,
    String? reraNumber,
    String? email,
    String? address,
    List<BrokerModel>? brokers,
  }) {
    return AgencyModel(
      id: id,
      name: name ?? this.name,
      reraNumber: reraNumber ?? this.reraNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      brokers: brokers ?? this.brokers,
    );
  }
}
