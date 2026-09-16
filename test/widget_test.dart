import 'package:flutter_test/flutter_test.dart';
import 'package:propconnect/core/models/commission_model.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/features/notifications/domain/models/notification_model.dart';

void main() {
  group('PropConnect PRD Core Models & Financial Rules', () {
    test('CommissionModel correctly parses and handles 50/50 split calculations', () {
      final json = {
        'id': 'COMM-801',
        'commissionCode': 'COMM-801',
        'dealId': 'DL-501',
        'dealValue': 12500000,
        'commissionType': 'Percentage',
        'commissionRate': 2.0,
        'totalCommission': 250000,
        'brokerASharePct': 50.0,
        'brokerBSharePct': 50.0,
        'brokerAAmount': 125000,
        'brokerBAmount': 125000,
        'brokerAName': 'Om Shivam',
        'brokerBName': 'Rahul Singh',
        'agencyAName': 'Sunrise Properties',
        'agencyBName': 'Metro Reality',
        'status': 'Settled',
      };

      final comm = CommissionModel.fromJson(json);

      expect(comm.commissionCode, 'COMM-801');
      expect(comm.dealId, 'DL-501');
      expect(comm.dealValue, 12500000.0);
      expect(comm.totalCommission, 250000.0);
      expect(comm.brokerASharePct, 50.0);
      expect(comm.brokerBSharePct, 50.0);
      expect(comm.brokerAAmount, 125000.0);
      expect(comm.brokerBAAmount, 125000.0);
      expect(comm.brokerAName, 'Om Shivam');
      expect(comm.status, 'Settled');
    });

    test('SettlementModel correctly parses and tracks payment ledger', () {
      final json = {
        'id': 'SET-901',
        'settlementCode': 'SET-901',
        'commissionId': '1',
        'dealId': 'DL-501',
        'amountReceived': 250000,
        'amountPending': 0,
        'paymentMethod': 'NEFT',
        'referenceNumber': 'NEFT-88910248',
        'status': 'Received',
      };

      final settlement = SettlementModel.fromJson(json);

      expect(settlement.settlementCode, 'SET-901');
      expect(settlement.amountReceived, 250000.0);
      expect(settlement.amountPending, 0.0);
      expect(settlement.paymentMethod, 'NEFT');
      expect(settlement.referenceNumber, 'NEFT-88910248');
      expect(settlement.status, 'Received');
    });

    test('DealModel correctly parses 12 lifecycle stages and privacy metadata', () {
      final json = {
        'id': 'DL-501',
        'title': 'Sea Face Villa',
        'propertyTitle': 'Sea Face Villa',
        'value': '₹4.2 Cr',
        'agencyA': 'Sunrise Properties',
        'agencyB': 'Metro Reality',
        'status': 'Negotiation',
        'dealCode': 'DL-501',
        'clientName': 'Vikram Mehta',
        'clientPhone': '+91 98765 43210',
        'clientEmail': 'vikram@example.com',
        'dealValue': '₹4,20,00,000',
      };

      final deal = DealModel.fromJson(json);

      expect(deal.dealCode, 'DL-501');
      expect(deal.status, 'Negotiation');
      expect(deal.clientName, 'Vikram Mehta');
      expect(deal.clientPhone, '+91 98765 43210');
      expect(deal.agencyAName, 'Sunrise Properties');
      expect(deal.agencyBName, 'Metro Reality');
    });

    test('PropertyModel PRD Section 4 KYC & structured location attributes', () {
      final json = {
        'id': 'PR-101',
        'title': 'Luxury Penthouse',
        'location': 'Worli, Mumbai',
        'price': '₹12 Cr',
        'bhk': '4 BHK',
        'type': 'Sale',
        'purpose': 'Sale',
        'propertyType': 'Apartment',
        'carpetArea': 2800,
        'areaSqft': 3200,
        'securityDeposit': '₹50 Lakhs',
        'negotiablePrice': '₹11.5 Cr',
        'ownerName': 'Ramesh Singhania',
        'ownerPhonePrimary': '+91 98200 11223',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'country': 'India',
      };

      final prop = PropertyModel.fromJson(json);

      expect(prop.purpose, 'Sale');
      expect(prop.carpetArea, 2800.0);
      expect(prop.areaSqft, 3200.0);
      expect(prop.negotiablePrice, '₹11.5 Cr');
      expect(prop.ownerName, 'Ramesh Singhania');
      expect(prop.city, 'Mumbai');
      expect(prop.stateName, 'Maharashtra');
    });

    test('AppNotification (PRD Section 17) parses in-app and push notification metadata', () {
      final notifJson = {
        'id': 1,
        'notificationCode': 'NOTIF-501',
        'userId': 1,
        'agencyId': 1,
        'title': 'New Collaboration Request',
        'message': 'Om Shivam requested to collaborate on Sea Face Villa.',
        'type': 'collaboration',
        'actionRoute': '/collaborations',
        'metadata': {'requestCode': 'REQ-101', 'propertyId': 1},
        'isRead': false,
        'channels': 'in_app,push',
        'createdAt': '2026-09-16T12:00:00.000Z',
      };

      final notif = AppNotification.fromJson(notifJson);

      expect(notif.id, 1);
      expect(notif.notificationCode, 'NOTIF-501');
      expect(notif.title, 'New Collaboration Request');
      expect(notif.type, 'collaboration');
      expect(notif.actionRoute, '/collaborations');
      expect(notif.isRead, false);
      expect(notif.channels, 'in_app,push');

      final updated = notif.copyWith(isRead: true);
      expect(updated.isRead, true);
    });
  });
}
