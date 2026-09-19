class OwnerModel {
  final int id;
  final int agencyId;
  final String name;
  final String phonePrimary;
  final String phoneSecondary;
  final String email;
  final String address;
  final String idType;
  final String idNumber;
  final String notes;
  final List<String> kycDocs;
  final int propertyCount;
  final DateTime? createdAt;

  OwnerModel({
    required this.id,
    required this.agencyId,
    required this.name,
    required this.phonePrimary,
    this.phoneSecondary = '',
    this.email = '',
    this.address = '',
    this.idType = 'Aadhaar',
    this.idNumber = '',
    this.notes = '',
    this.kycDocs = const [],
    this.propertyCount = 0,
    this.createdAt,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return OwnerModel(
      id: parseInt(json['id']),
      agencyId: parseInt(json['agencyId'] ?? json['agency_id'], 1),
      name: (json['name'] ?? '').toString(),
      phonePrimary: (json['phonePrimary'] ?? json['phone_primary'] ?? json['phone'] ?? '').toString(),
      phoneSecondary: (json['phoneSecondary'] ?? json['phone_secondary'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      idType: (json['idType'] ?? json['id_type'] ?? 'Aadhaar').toString(),
      idNumber: (json['idNumber'] ?? json['id_number'] ?? '').toString(),
      notes: (json['notes'] ?? json['internalNotes'] ?? '').toString(),
      kycDocs: parseList(json['kycDocs'] ?? json['kyc_docs']),
      propertyCount: parseInt(json['propertyCount'] ?? json['properties_count'] ?? 0),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agencyId': agencyId,
      'name': name,
      'phonePrimary': phonePrimary,
      'phoneSecondary': phoneSecondary,
      'email': email,
      'address': address,
      'idType': idType,
      'idNumber': idNumber,
      'notes': notes,
      'kycDocs': kycDocs,
      'propertyCount': propertyCount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  OwnerModel copyWith({
    int? id,
    int? agencyId,
    String? name,
    String? phonePrimary,
    String? phoneSecondary,
    String? email,
    String? address,
    String? idType,
    String? idNumber,
    String? notes,
    List<String>? kycDocs,
    int? propertyCount,
    DateTime? createdAt,
  }) {
    return OwnerModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      name: name ?? this.name,
      phonePrimary: phonePrimary ?? this.phonePrimary,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      email: email ?? this.email,
      address: address ?? this.address,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      notes: notes ?? this.notes,
      kycDocs: kycDocs ?? this.kycDocs,
      propertyCount: propertyCount ?? this.propertyCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
