class DealAuditLog {
  final String status;
  final DateTime timestamp;
  final String? updatedBy;
  final String? notes;
  final Map<String, dynamic>? metadata;

  DealAuditLog({
    required this.status,
    required this.timestamp,
    this.updatedBy,
    this.notes,
    this.metadata,
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
      notes: json['notes'] ?? json['remarks'],
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'updatedBy': updatedBy,
      'notes': notes,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class DealModel {
  static const List<String> prdMilestones = [
    'Lead Assigned',
    'Property Shared',
    'Site Visit Scheduled',
    'Site Visit Completed',
    'Negotiation Started',
    'Offer Submitted',
    'Token Generated',
    'Agreement Signed',
    'Registry Scheduled',
    'Registry Completed',
    'Deal Closed',
    'Deal Lost',
  ];

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

  // PRD Section 4.4 Milestone Metadata
  final String? tokenAmount;
  final String? tokenDate;
  final String? agreementDate;
  final String? bankName;
  final String? loanAmount;
  final String? registryDate;
  final String? registrationNumber;
  final String? possessionDate;
  final List<Map<String, dynamic>> documents;

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
    this.tokenAmount,
    this.tokenDate,
    this.agreementDate,
    this.bankName,
    this.loanAmount,
    this.registryDate,
    this.registrationNumber,
    this.possessionDate,
    this.documents = const [],
  });

  DealModel copyWith({
    String? id,
    String? dealCode,
    String? propertyId,
    String? propertyName,
    int? agencyAId,
    String? agencyAName,
    int? brokerAId,
    String? brokerAName,
    int? agencyBId,
    String? agencyBName,
    int? brokerBId,
    String? brokerBName,
    String? partnerBroker,
    String? partnerAgency,
    String? status,
    String? amount,
    double? dealValue,
    int? commissionId,
    bool? isRequest,
    bool? isIncomingRequest,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? clientRequirement,
    String? expectedBudget,
    String? remarks,
    DateTime? createdAt,
    DateTime? respondedAt,
    List<DealAuditLog>? auditHistory,
    String? tokenAmount,
    String? tokenDate,
    String? agreementDate,
    String? bankName,
    String? loanAmount,
    String? registryDate,
    String? registrationNumber,
    String? possessionDate,
    List<Map<String, dynamic>>? documents,
  }) {
    return DealModel(
      id: id ?? this.id,
      dealCode: dealCode ?? this.dealCode,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      agencyAId: agencyAId ?? this.agencyAId,
      agencyAName: agencyAName ?? this.agencyAName,
      brokerAId: brokerAId ?? this.brokerAId,
      brokerAName: brokerAName ?? this.brokerAName,
      agencyBId: agencyBId ?? this.agencyBId,
      agencyBName: agencyBName ?? this.agencyBName,
      brokerBId: brokerBId ?? this.brokerBId,
      brokerBName: brokerBName ?? this.brokerBName,
      partnerBroker: partnerBroker ?? this.partnerBroker,
      partnerAgency: partnerAgency ?? this.partnerAgency,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      dealValue: dealValue ?? this.dealValue,
      commissionId: commissionId ?? this.commissionId,
      isRequest: isRequest ?? this.isRequest,
      isIncomingRequest: isIncomingRequest ?? this.isIncomingRequest,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientRequirement: clientRequirement ?? this.clientRequirement,
      expectedBudget: expectedBudget ?? this.expectedBudget,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      auditHistory: auditHistory ?? this.auditHistory,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      tokenDate: tokenDate ?? this.tokenDate,
      agreementDate: agreementDate ?? this.agreementDate,
      bankName: bankName ?? this.bankName,
      loanAmount: loanAmount ?? this.loanAmount,
      registryDate: registryDate ?? this.registryDate,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      possessionDate: possessionDate ?? this.possessionDate,
      documents: documents ?? this.documents,
    );
  }

  /// Normalizes any variant stage string to the 12 Canonical PRD Section 9 Milestones
  String get normalizedStage {
    final s = status.trim().toLowerCase();
    if (s.contains('lost') || s.contains('cancel') || s.contains('reject')) return 'Deal Lost';
    if (s.contains('close') || s.contains('settled') || s.contains('paid') || s.contains('possession')) return 'Deal Closed';
    if (s.contains('registry comp') || s.contains('registered')) return 'Registry Completed';
    if (s.contains('registry') || s.contains('regist')) return 'Registry Scheduled';
    if (s.contains('agree') || s.contains('loan') || s.contains('contract')) return 'Agreement Signed';
    if (s.contains('token') || s.contains('book')) return 'Token Generated';
    if (s.contains('offer')) return 'Offer Submitted';
    if (s.contains('negot')) return 'Negotiation Started';
    if (s.contains('visit comp') || s.contains('visited')) return 'Site Visit Completed';
    if (s.contains('visit')) return 'Site Visit Scheduled';
    if (s.contains('shared') || s.contains('sent') || s.contains('shortlist')) return 'Property Shared';
    return 'Lead Assigned';
  }

  int get milestoneIndex {
    final idx = prdMilestones.indexOf(normalizedStage);
    return idx >= 0 ? idx : 0;
  }

  double get progressPercentage {
    if (normalizedStage == 'Deal Lost') return 0.0;
    if (normalizedStage == 'Deal Closed') return 1.0;
    final idx = milestoneIndex;
    return ((idx + 1) / 11).clamp(0.0, 1.0);
  }

  static double parsePriceToNumeric(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    String str = raw.toString().trim();
    if (str.isEmpty || str.toLowerCase().contains('request')) return 0.0;

    final lower = str.toLowerCase();
    double multiplier = 1.0;
    if (lower.contains('cr') || lower.contains('crore')) {
      multiplier = 10000000.0;
    } else if (lower.contains('lac') || lower.contains('lakh') || RegExp(r'\b[lL]\b').hasMatch(str)) {
      multiplier = 100000.0;
    } else if (lower.contains('k') || lower.contains('thousand')) {
      multiplier = 1000.0;
    }

    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(str.replaceAll(',', ''));
    if (match != null) {
      final parsed = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      return parsed * multiplier;
    }
    return 0.0;
  }

  static String formatNumericToPrice(double value) {
    if (value <= 0) return '₹0';
    if (value >= 10000000) {
      final cr = value / 10000000;
      final formatted = cr.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return '₹$formatted Cr';
    } else if (value >= 100000) {
      final l = value / 100000;
      final formatted = l.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return '₹$formatted L';
    } else if (value >= 1000) {
      final k = value / 1000;
      final formatted = k.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
      return '₹$formatted K';
    }
    return '₹${value.toInt()}';
  }

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

    List<Map<String, dynamic>> docList = [];
    if (json['documents'] is List) {
      docList = (json['documents'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    final rawVal = json['dealValue'] ?? json['amount'] ?? json['expectedBudget'] ?? json['propertyPrice'];
    final double val = parsePriceToNumeric(rawVal);

    String formattedAmount = '';
    if (rawVal != null) {
      final str = rawVal.toString().trim();
      if ((str.startsWith('₹') || str.toLowerCase().contains('cr') || str.toLowerCase().contains('l')) &&
          !str.toLowerCase().contains('request')) {
        formattedAmount = str.startsWith('₹') ? str : '₹$str';
      }
    }
    if (formattedAmount.isEmpty) {
      formattedAmount = formatNumericToPrice(val);
    }

    // Milestone metadata: check top-level or search in auditHistory for milestone fields
    String? tokenAmount = json['tokenAmount']?.toString();
    String? tokenDate = json['tokenDate']?.toString();
    String? agreementDate = json['agreementDate']?.toString();
    String? bankName = json['bankName']?.toString();
    String? loanAmount = json['loanAmount']?.toString();
    String? registryDate = json['registryDate']?.toString();
    String? registrationNumber = json['registrationNumber']?.toString();
    String? possessionDate = json['possessionDate']?.toString();

    if (json['auditHistory'] is List) {
      for (final item in (json['auditHistory'] as List).reversed) {
        if (item is Map) {
          tokenAmount ??= item['tokenAmount']?.toString();
          tokenDate ??= item['tokenDate']?.toString();
          agreementDate ??= item['agreementDate']?.toString();
          bankName ??= item['bankName']?.toString();
          loanAmount ??= item['loanAmount']?.toString();
          registryDate ??= item['registryDate']?.toString();
          registrationNumber ??= item['registrationNumber']?.toString();
          possessionDate ??= item['possessionDate']?.toString();
        }
      }
    }

    final propName = json['propertyName'] ?? (json['property'] is Map ? json['property']['title'] : 'Property Listing');

    return DealModel(
      id: (json['id'] ?? json['dealCode'] ?? json['requestCode'] ?? '').toString(),
      dealCode: (json['dealCode'] ?? json['requestCode'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? '').toString(),
      propertyName: propName,
      agencyAId: json['agencyAId'] != null
          ? int.tryParse(json['agencyAId'].toString())
          : (json['targetAgencyId'] != null ? int.tryParse(json['targetAgencyId'].toString()) : null),
      agencyAName: json['agencyAName'] ?? json['targetAgencyName'] ?? json['agencyA'] ?? '',
      brokerAId: json['brokerAId'] != null
          ? int.tryParse(json['brokerAId'].toString())
          : (json['targetBrokerId'] != null ? int.tryParse(json['targetBrokerId'].toString()) : null),
      brokerAName: json['brokerAName'] ?? json['targetBrokerName'] ?? json['brokerA'] ?? '',
      agencyBId: json['agencyBId'] != null
          ? int.tryParse(json['agencyBId'].toString())
          : (json['requestingAgencyId'] != null ? int.tryParse(json['requestingAgencyId'].toString()) : null),
      agencyBName: json['agencyBName'] ?? json['requestingAgencyName'] ?? json['agencyB'] ?? '',
      brokerBId: json['brokerBId'] != null
          ? int.tryParse(json['brokerBId'].toString())
          : (json['requestingBrokerId'] != null ? int.tryParse(json['requestingBrokerId'].toString()) : null),
      brokerBName: json['brokerBName'] ?? json['requestingBrokerName'] ?? json['brokerB'] ?? '',
      partnerBroker: json['partnerBroker'] ?? json['requestingBrokerName'] ?? json['targetBrokerName'] ?? json['brokerBName'] ?? json['brokerAName'] ?? 'Partner Broker',
      partnerAgency: json['partnerAgency'] ?? json['requestingAgencyName'] ?? json['targetAgencyName'] ?? json['agencyBName'] ?? json['agencyAName'] ?? 'Partner Agency',
      status: json['status'] ?? 'Inquiry',
      amount: formattedAmount,
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
      tokenAmount: tokenAmount,
      tokenDate: tokenDate,
      agreementDate: agreementDate,
      bankName: bankName,
      loanAmount: loanAmount,
      registryDate: registryDate,
      registrationNumber: registrationNumber,
      possessionDate: possessionDate,
      documents: docList,
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
      if (tokenAmount != null) 'tokenAmount': tokenAmount,
      if (tokenDate != null) 'tokenDate': tokenDate,
      if (agreementDate != null) 'agreementDate': agreementDate,
      if (bankName != null) 'bankName': bankName,
      if (loanAmount != null) 'loanAmount': loanAmount,
      if (registryDate != null) 'registryDate': registryDate,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (possessionDate != null) 'possessionDate': possessionDate,
      if (documents.isNotEmpty) 'documents': documents,
    };
  }
}
