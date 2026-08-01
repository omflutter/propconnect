class DealAuditLog {
  final String status;
  final DateTime timestamp;
  final String? updatedBy;

  DealAuditLog({
    required this.status,
    required this.timestamp,
    this.updatedBy,
  });
}

class DealModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String partnerBroker;
  final String partnerAgency;
  final String status;
  final String amount;
  final bool isRequest;
  final bool isIncomingRequest;
  final String? clientRequirement;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final List<DealAuditLog> auditHistory;

  DealModel({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.partnerBroker,
    required this.partnerAgency,
    required this.status,
    required this.amount,
    this.isRequest = false,
    this.isIncomingRequest = false,
    this.clientRequirement,
    this.remarks,
    this.createdAt,
    this.respondedAt,
    this.auditHistory = const [],
  });
}
