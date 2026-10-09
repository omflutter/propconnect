class BrokerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'Owner', 'Admin', 'Broker Agent'
  final bool isActive;
  final List<String> assignedPropertyIds;

  BrokerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.assignedPropertyIds = const [],
  });

  BrokerModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    List<String>? assignedPropertyIds,
  }) {
    return BrokerModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      assignedPropertyIds: assignedPropertyIds ?? this.assignedPropertyIds,
    );
  }
}

class AgencyModel {
  final String id;
  final String name;
  final String reraNumber;
  final String email;
  final String address;
  final String pincode;
  final String referralCode;
  final int coinsBalance;
  final List<BrokerModel> brokers;

  AgencyModel({
    required this.id,
    required this.name,
    required this.reraNumber,
    required this.email,
    required this.address,
    this.pincode = '',
    this.referralCode = '',
    this.coinsBalance = 0,
    required this.brokers,
  });

  AgencyModel copyWith({
    String? name,
    String? reraNumber,
    String? email,
    String? address,
    String? pincode,
    String? referralCode,
    int? coinsBalance,
    List<BrokerModel>? brokers,
  }) {
    return AgencyModel(
      id: id,
      name: name ?? this.name,
      reraNumber: reraNumber ?? this.reraNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      referralCode: referralCode ?? this.referralCode,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      brokers: brokers ?? this.brokers,
    );
  }

  factory AgencyModel.fromJson(Map<String, dynamic> json) {
    return AgencyModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      reraNumber: json['reraNumber'] as String? ?? '',
      email: (json['email'] ?? json['adminEmail']) as String? ?? '',
      address: json['address'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      referralCode: json['referralCode'] as String? ?? '',
      coinsBalance: (json['coinsBalance'] as num?)?.toInt() ?? 0,
      brokers: (json['brokers'] as List?)
              ?.map((b) => BrokerModel(
                    id: b['id']?.toString() ?? '',
                    name: b['name'] as String? ?? '',
                    email: b['email'] as String? ?? '',
                    phone: b['phone'] as String? ?? '',
                    role: b['role'] as String? ?? 'Broker Agent',
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reraNumber': reraNumber,
      'email': email,
      'address': address,
      'pincode': pincode,
      'referralCode': referralCode,
      'coinsBalance': coinsBalance,
      'brokers': brokers.map((b) => {
        'id': b.id,
        'name': b.name,
        'email': b.email,
        'phone': b.phone,
        'role': b.role,
      }).toList(),
    };
  }
}
