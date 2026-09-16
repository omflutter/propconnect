class CommissionModel {
  final String id;
  final String commissionCode;
  final String dealId;
  final String? propertyName;
  final double dealValue;
  final String commissionType; // 'Percentage' | 'Flat'
  final double commissionRate;
  final double totalCommission;
  final double brokerASharePct;
  final double brokerBSharePct;
  final double brokerAAmount;
  final double brokerBAAmount;
  final String? brokerAName;
  final String? brokerBName;
  final String? agencyAName;
  final String? agencyBName;
  final String status; // 'Pending' | 'Partial' | 'Settled' | 'Disputed'
  final String? remarks;
  final DateTime? createdAt;

  CommissionModel({
    required this.id,
    required this.commissionCode,
    required this.dealId,
    this.propertyName,
    required this.dealValue,
    required this.commissionType,
    required this.commissionRate,
    required this.totalCommission,
    this.brokerASharePct = 50.0,
    this.brokerBSharePct = 50.0,
    required this.brokerAAmount,
    required this.brokerBAAmount,
    this.brokerAName,
    this.brokerBName,
    this.agencyAName,
    this.agencyBName,
    this.status = 'Pending',
    this.remarks,
    this.createdAt,
  });

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }

    return CommissionModel(
      id: (json['id'] ?? json['commissionCode'] ?? '').toString(),
      commissionCode: json['commissionCode'] ?? '',
      dealId: (json['dealId'] ?? '').toString(),
      propertyName: json['propertyName'],
      dealValue: double.tryParse((json['dealValue'] ?? 0).toString().replaceAll('₹', '').replaceAll(',', '')) ?? 0.0,
      commissionType: json['commissionType'] ?? 'Percentage',
      commissionRate: double.tryParse((json['commissionRate'] ?? 0).toString()) ?? 0.0,
      totalCommission: double.tryParse((json['totalCommission'] ?? 0).toString().replaceAll('₹', '').replaceAll(',', '')) ?? 0.0,
      brokerASharePct: double.tryParse((json['brokerASharePct'] ?? 50).toString()) ?? 50.0,
      brokerBSharePct: double.tryParse((json['brokerBSharePct'] ?? 50).toString()) ?? 50.0,
      brokerAAmount: double.tryParse((json['brokerAAmount'] ?? 0).toString().replaceAll('₹', '').replaceAll(',', '')) ?? 0.0,
      brokerBAAmount: double.tryParse((json['brokerBAmount'] ?? 0).toString().replaceAll('₹', '').replaceAll(',', '')) ?? 0.0,
      brokerAName: json['brokerAName'],
      brokerBName: json['brokerBName'],
      agencyAName: json['agencyAName'],
      agencyBName: json['agencyBName'],
      status: json['status'] ?? 'Pending',
      remarks: json['remarks'],
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commissionCode': commissionCode,
      'dealId': dealId,
      'propertyName': propertyName,
      'dealValue': dealValue,
      'commissionType': commissionType,
      'commissionRate': commissionRate,
      'totalCommission': totalCommission,
      'brokerASharePct': brokerASharePct,
      'brokerBSharePct': brokerBSharePct,
      'brokerAAmount': brokerAAmount,
      'brokerBAmount': brokerBAAmount,
      'brokerAName': brokerAName,
      'brokerBName': brokerBName,
      'agencyAName': agencyAName,
      'agencyBName': agencyBName,
      'status': status,
      'remarks': remarks,
    };
  }
}

class SettlementModel {
  final String id;
  final String settlementCode;
  final String commissionId;
  final String dealId;
  final String? propertyName;
  final String? brokerName;
  final String? agencyName;
  final DateTime? dueDate;
  final double amountReceived;
  final double amountPending;
  final String paymentMethod;
  final String referenceNumber;
  final DateTime? settlementDate;
  final String status;
  final String? remarks;

  SettlementModel({
    required this.id,
    required this.settlementCode,
    required this.commissionId,
    required this.dealId,
    this.propertyName,
    this.brokerName,
    this.agencyName,
    this.dueDate,
    required this.amountReceived,
    required this.amountPending,
    required this.paymentMethod,
    required this.referenceNumber,
    this.settlementDate,
    required this.status,
    this.remarks,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: (json['id'] ?? json['settlementCode'] ?? '').toString(),
      settlementCode: json['settlementCode'] ?? '',
      commissionId: (json['commissionId'] ?? '').toString(),
      dealId: (json['dealId'] ?? '').toString(),
      propertyName: json['propertyName'],
      brokerName: json['brokerName'],
      agencyName: json['agencyName'],
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      amountReceived: double.tryParse((json['amountReceived'] ?? 0).toString().replaceAll('₹', '').replaceAll(',', '')) ?? 0.0,
      amountPending: double.tryParse((json['amountPending'] ?? 0).toString().replaceAll('₹', '').replaceAll(',', '')) ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'NEFT',
      referenceNumber: json['referenceNumber'] ?? '',
      settlementDate: json['settlementDate'] != null ? DateTime.tryParse(json['settlementDate'].toString()) : null,
      status: json['status'] ?? 'Pending',
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'settlementCode': settlementCode,
      'commissionId': commissionId,
      'dealId': dealId,
      'propertyName': propertyName,
      'brokerName': brokerName,
      'agencyName': agencyName,
      'dueDate': dueDate?.toIso8601String(),
      'amountReceived': amountReceived,
      'amountPending': amountPending,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'settlementDate': settlementDate?.toIso8601String(),
      'status': status,
      'remarks': remarks,
    };
  }
}
