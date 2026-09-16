class DealAuditLog {
  final String status;
  final DateTime timestamp;
  final String? updatedBy;
  final String? notes;

  DealAuditLog({
    required this.status,
    required this.timestamp,
    this.updatedBy,
    this.notes,
  });

  factory DealAuditLog.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime = DateTime.now();
    if (json['timestamp'] != null) {
      parsedTime = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    }
    return DealAuditLog(
      status: json['status'] ?? '',
      timestamp: parsedTime,
      updatedBy: json['updatedBy'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'updatedBy': updatedBy,
      'notes': notes,
    };
  }
}

class DealModel {
  final String id;
  final String dealCode;
  final String propertyId;
  final String propertyName;
  final int? agencyAId;
  final String agencyAName;
  final int? brokerAId;
  final String brokerAName;
  final int? agencyBId;
  final String agencyBName;
  final int? brokerBId;
  final String brokerBName;
  final String partnerBroker;
  final String partnerAgency;
  final String status;
  final String amount;
  final double dealValue;
  final int? commissionId;
  final bool isRequest;
  final bool isIncomingRequest;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientRequirement;
  final String? expectedBudget;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final List<DealAuditLog> auditHistory;

  DealModel({
    required this.id,
    this.dealCode = '',
    required this.propertyId,
    required this.propertyName,
    this.agencyAId,
    this.agencyAName = '',
    this.brokerAId,
    this.brokerAName = '',
    this.agencyBId,
    this.agencyBName = '',
    this.brokerBId,
    this.brokerBName = '',
    required this.partnerBroker,
    required this.partnerAgency,
    required this.status,
    required this.amount,
    this.dealValue = 0.0,
    this.commissionId,
    this.isRequest = false,
    this.isIncomingRequest = false,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.clientRequirement,
    this.expectedBudget,
    this.remarks,
    this.createdAt,
    this.respondedAt,
    this.auditHistory = const [],
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }
    DateTime? responded;
    if (json['respondedAt'] != null) {
      responded = DateTime.tryParse(json['respondedAt'].toString());
    }

    List<DealAuditLog> history = [];
    if (json['auditHistory'] is List) {
      history = (json['auditHistory'] as List)
          .map((e) => DealAuditLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final val = double.tryParse((json['dealValue'] ?? json['amount'] ?? 0).toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final propName = json['propertyName'] ?? (json['property'] is Map ? json['property']['title'] : 'Property Listing');

    return DealModel(
      id: (json['id'] ?? json['dealCode'] ?? json['requestCode'] ?? '').toString(),
      dealCode: (json['dealCode'] ?? json['requestCode'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? '').toString(),
      propertyName: propName,
      agencyAId: json['agencyAId'] != null ? int.tryParse(json['agencyAId'].toString()) : null,
      agencyAName: json['agencyAName'] ?? json['agencyA'] ?? '',
      brokerAId: json['brokerAId'] != null ? int.tryParse(json['brokerAId'].toString()) : null,
      brokerAName: json['brokerAName'] ?? json['brokerA'] ?? '',
      agencyBId: json['agencyBId'] != null ? int.tryParse(json['agencyBId'].toString()) : null,
      agencyBName: json['agencyBName'] ?? json['agencyB'] ?? '',
      brokerBId: json['brokerBId'] != null ? int.tryParse(json['brokerBId'].toString()) : null,
      brokerBName: json['brokerBName'] ?? json['brokerB'] ?? '',
      partnerBroker: json['partnerBroker'] ?? json['brokerBName'] ?? json['brokerAName'] ?? 'Partner Broker',
      partnerAgency: json['partnerAgency'] ?? json['agencyBName'] ?? json['agencyAName'] ?? 'Partner Agency',
      status: json['status'] ?? 'Enquiry',
      amount: json['amount'] ?? '₹${val > 0 ? (val >= 10000000 ? '${(val / 10000000).toStringAsFixed(2)} Cr' : '${(val / 100000).toStringAsFixed(2)} L') : '0'}',
      dealValue: val,
      commissionId: json['commissionId'] != null ? int.tryParse(json['commissionId'].toString()) : null,
      isRequest: json['isRequest'] ?? false,
      isIncomingRequest: json['isIncomingRequest'] ?? false,
      clientName: json['clientName'],
      clientPhone: json['clientPhone'],
      clientEmail: json['clientEmail'],
      clientRequirement: json['clientRequirement'],
      expectedBudget: json['expectedBudget'],
      remarks: json['remarks'],
      createdAt: created,
      respondedAt: responded,
      auditHistory: history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dealCode': dealCode,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'agencyAId': agencyAId,
      'agencyAName': agencyAName,
      'brokerAId': brokerAId,
      'brokerAName': brokerAName,
      'agencyBId': agencyBId,
      'agencyBName': agencyBName,
      'brokerBId': brokerBId,
      'brokerBName': brokerBName,
      'partnerBroker': partnerBroker,
      'partnerAgency': partnerAgency,
      'status': status,
      'amount': amount,
      'dealValue': dealValue,
      'commissionId': commissionId,
      'isRequest': isRequest,
      'isIncomingRequest': isIncomingRequest,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'clientRequirement': clientRequirement,
      'expectedBudget': expectedBudget,
      'remarks': remarks,
      'createdAt': createdAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'auditHistory': auditHistory.map((e) => e.toJson()).toList(),
    };
  }
}
