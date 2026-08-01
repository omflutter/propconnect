import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../models/deal_model.dart';

class PropertyNotifier extends Notifier<List<PropertyModel>> {
  @override
  List<PropertyModel> build() {
    return [
      PropertyModel(id: 'P-101', title: '3 BHK Luxury Apartment', location: 'Bandra West, Mumbai', price: '₹3.5 Cr', bhk: '3 BHK', type: 'Sale', isPublic: true, agencyName: 'Sunrise Properties', propertyType: 'Apartment', status: 'Available', brokerName: 'Amit Patel', bathrooms: 3, balcony: 2, parking: 1, furnishedStatus: 'Semi-Furnished', propertyAge: 2, areaSqft: 1500.0, maintenanceCharges: '₹12,000/mo', amenities: ['Gym', 'Swimming Pool', '24/7 Security'], images: ['/Users/omshivam/.gemini/antigravity/brain/cc5ae647-c36c-4a92-bce3-7a0aa26a1e5a/premium_villa_1784394156677.jpg']),
      PropertyModel(id: 'P-102', title: 'Commercial Office Space', location: 'Andheri East, Mumbai', price: '₹1.5 L/mo', bhk: 'N/A', type: 'Rent', isPublic: false, agencyName: 'Sunrise Properties', propertyType: 'Office', status: 'Available', brokerName: 'Neha Gupta', bathrooms: 2, balcony: 0, parking: 2, furnishedStatus: 'Fully Furnished', propertyAge: 5, areaSqft: 2000.0, maintenanceCharges: '₹25,000/mo', amenities: ['Central AC', 'Cafeteria', 'Conference Room'], images: []),
      PropertyModel(id: 'P-103', title: '4 BHK Sea-Facing Villa', location: 'Worli, Mumbai', price: '₹12 Cr', bhk: '4 BHK', type: 'Sale', isPublic: true, agencyName: 'Singh Realty', propertyType: 'Villa', status: 'Under Negotiation', brokerName: 'Rahul Singh', bathrooms: 5, balcony: 4, parking: 3, furnishedStatus: 'Fully Furnished', propertyAge: 1, areaSqft: 4500.0, maintenanceCharges: '₹50,000/mo', amenities: ['Private Pool', 'Gym', 'Sea View', 'Garden'], images: ['/Users/omshivam/.gemini/antigravity/brain/cc5ae647-c36c-4a92-bce3-7a0aa26a1e5a/premium_villa_1784394156677.jpg', '/Users/omshivam/.gemini/antigravity/brain/cc5ae647-c36c-4a92-bce3-7a0aa26a1e5a/premium_interior_1784394931695.jpg']),
      PropertyModel(id: 'P-104', title: '2 BHK Cozy Apartment', location: 'Malad West, Mumbai', price: '₹1.2 Cr', bhk: '2 BHK', type: 'Sale', isPublic: true, agencyName: 'Sunrise Properties', propertyType: 'Apartment', status: 'Available', brokerName: 'Amit Patel', bathrooms: 2, balcony: 1, parking: 1, furnishedStatus: 'Unfurnished', propertyAge: 10, areaSqft: 950.0, maintenanceCharges: '₹5,000/mo', amenities: ['Play Area', 'Security'], images: []),
    ];
  }

  void addProperty(PropertyModel property) {
    state = [...state, property];
  }

  void updateProperty(PropertyModel updatedProp) {
    state = [
      for (final prop in state)
        if (prop.id == updatedProp.id) updatedProp else prop,
    ];
  }
}

final propertyProvider = NotifierProvider<PropertyNotifier, List<PropertyModel>>(() {
  return PropertyNotifier();
});

class DealNotifier extends Notifier<List<DealModel>> {
  @override
  List<DealModel> build() {
    final now = DateTime.now();
    return [
      DealModel(id: 'D-1256', propertyId: 'P-101', propertyName: '3 BHK Apartment', partnerBroker: 'Rahul Singh', partnerAgency: 'Singh Realty', status: 'Token Generated', amount: '₹1.25 Cr', createdAt: now.subtract(const Duration(days: 2))),
      DealModel(id: 'D-1255', propertyId: 'P-103', propertyName: '4 BHK Villa', partnerBroker: 'Neha Gupta', partnerAgency: 'Sunrise Properties', status: 'Negotiation', amount: '₹3.50 Cr', createdAt: now.subtract(const Duration(days: 5))),
      DealModel(id: 'D-1254', propertyId: 'P-102', propertyName: 'Office Space', partnerBroker: 'Vikram Joshi', partnerAgency: 'Elite Real Estate', status: 'Agreement Signed', amount: '₹1.20 Cr', createdAt: now.subtract(const Duration(days: 10))),
      // Sent Requests (isRequest: true, isIncomingRequest: false)
      DealModel(id: 'R-001', propertyId: 'P-103', propertyName: 'Luxury Penthouse', partnerBroker: 'Arun Sharma', partnerAgency: 'Skyline Homes', status: 'Pending', amount: '₹5.5 Cr', isRequest: true, clientRequirement: 'Client is looking for a sea-facing penthouse with a private pool.', remarks: 'Urgent requirement, client is moving in next month.', createdAt: now.subtract(const Duration(hours: 2))),
      // Incoming Requests (isRequest: true, isIncomingRequest: true)
      DealModel(id: 'R-002', propertyId: 'P-102', propertyName: 'Retail Shop', partnerBroker: 'Kiran Patel', partnerAgency: 'Prime Spaces', status: 'Pending', amount: '₹80 L', isRequest: true, isIncomingRequest: true, clientRequirement: 'Need a shop with heavy footfall for a bakery.', createdAt: now.subtract(const Duration(hours: 5))),
      // Responded Requests (isRequest: false, but status shows it was a request)
      DealModel(id: 'R-003', propertyId: 'P-103', propertyName: 'Sea-Facing Villa', partnerBroker: 'Ravi Verma', partnerAgency: 'Verma Properties', status: 'Rejected', amount: '₹12 Cr', isRequest: false, isIncomingRequest: true, clientRequirement: 'Requires 4 parking spots minimum.', createdAt: now.subtract(const Duration(days: 1)), respondedAt: now.subtract(const Duration(hours: 10))),
      DealModel(id: 'R-004', propertyId: 'P-104', propertyName: 'Cozy Apartment', partnerBroker: 'Neha Gupta', partnerAgency: 'Sunrise Properties', status: 'Approved', amount: '₹1.2 Cr', isRequest: false, isIncomingRequest: true, clientRequirement: 'Fully furnished required for a young couple.', remarks: 'Let me know if price is negotiable.', createdAt: now.subtract(const Duration(days: 2)), respondedAt: now.subtract(const Duration(days: 1))),
      // Sent Requests that they responded to
      DealModel(id: 'R-005', propertyId: 'P-101', propertyName: '3 BHK Apartment', partnerBroker: 'Amit Patel', partnerAgency: 'Patel Realty', status: 'Approved', amount: '₹3.4 Cr', isRequest: false, isIncomingRequest: false, createdAt: now.subtract(const Duration(days: 4)), respondedAt: now.subtract(const Duration(days: 3))),
    ];
  }

  void addDeal(DealModel deal) {
    final newDeal = DealModel(
      id: deal.id,
      propertyId: deal.propertyId,
      propertyName: deal.propertyName,
      partnerBroker: deal.partnerBroker,
      partnerAgency: deal.partnerAgency,
      status: deal.status,
      amount: deal.amount,
      isRequest: deal.isRequest,
      isIncomingRequest: deal.isIncomingRequest,
      clientRequirement: deal.clientRequirement,
      remarks: deal.remarks,
      createdAt: deal.createdAt ?? DateTime.now(),
      auditHistory: deal.auditHistory.isNotEmpty 
          ? deal.auditHistory 
          : [DealAuditLog(status: deal.status, timestamp: DateTime.now(), updatedBy: 'Current User')],
    );
    state = [...state, newDeal];
  }
  
  void updateDealStatus(String id, String newStatus) {
    state = [
      for (final deal in state)
        if (deal.id == id)
          DealModel(
            id: deal.id,
            propertyId: deal.propertyId,
            propertyName: deal.propertyName,
            partnerBroker: deal.partnerBroker,
            partnerAgency: deal.partnerAgency,
            status: newStatus,
            amount: deal.amount,
            isRequest: (newStatus == 'Approved' || newStatus == 'Rejected') ? false : deal.isRequest,
            isIncomingRequest: deal.isIncomingRequest,
            clientRequirement: deal.clientRequirement,
            remarks: deal.remarks,
            createdAt: deal.createdAt,
            respondedAt: (newStatus == 'Approved' || newStatus == 'Rejected') ? DateTime.now() : deal.respondedAt,
            auditHistory: [
              ...deal.auditHistory,
              DealAuditLog(status: newStatus, timestamp: DateTime.now(), updatedBy: 'Current User'),
            ],
          )
        else
          deal,
    ];
  }
}

final dealProvider = NotifierProvider<DealNotifier, List<DealModel>>(() {
  return DealNotifier();
});

class AnalyticsModel {
  final int activeBrokers;
  final List<double> monthlyCommission;
  final List<double> monthlyLeads;

  AnalyticsModel({
    required this.activeBrokers,
    required this.monthlyCommission,
    required this.monthlyLeads,
  });
}

class AnalyticsNotifier extends Notifier<AnalyticsModel> {
  @override
  AnalyticsModel build() {
    return AnalyticsModel(
      activeBrokers: 12, // Number of brokers in 'Sunrise Properties'
      monthlyCommission: [120000, 150000, 180000, 100000, 250000, 300000],
      monthlyLeads: [5, 8, 12, 10, 18, 25],
    );
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsModel>(() {
  return AnalyticsNotifier();
});
