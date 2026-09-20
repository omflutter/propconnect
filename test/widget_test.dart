import 'package:flutter_test/flutter_test.dart';
import 'package:propconnect/core/models/commission_model.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/owner_model.dart';
import 'package:propconnect/core/utils/export_service.dart';
import 'package:propconnect/core/utils/location_helper.dart';
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

    test('PropertyModel parses string/dirty feeds safely without throwing subtype errors', () {
      final dirtyFeedJson = {
        'id': '99A-1234',
        'title': '99acres Verified 3 BHK',
        'location': 'Worli, Mumbai',
        'price': '₹ 2.5 Cr',
        'bhk': '3 BHK',
        'type': 'Sale',
        'propertyType': 'Apartment',
        // String instead of int:
        'propertyAge': '1-5 Years',
        'areaSqft': '1,450 sq.ft',
        'carpetArea': '1,200',
        'bathrooms': '3 Baths',
        'balcony': '2 Balconies',
        'parking': '1 Covered',
        'isPublic': 'true',
        'amenities': 'Gym, Lift, Swimming Pool',
      };

      final prop = PropertyModel.fromJson(dirtyFeedJson);

      expect(prop.title, '99acres Verified 3 BHK');
      expect(prop.price, '₹ 2.5 Cr');
      expect(prop.propertyAge, 1);
      expect(prop.rawPropertyAge, '1-5 Years');
      expect(prop.displayPropertyAge, '1-5 Years');
      expect(prop.areaSqft, 1450.0);
      expect(prop.carpetArea, 1200.0);
      expect(prop.bathrooms, 3);
      expect(prop.balcony, 2);
      expect(prop.parking, 1);
      expect(prop.isPublic, true);
      expect(prop.amenities, ['Gym', 'Lift', 'Swimming Pool']);
    });

    test('OwnerModel and PropertyModel ownerId directory linkage', () {
      final ownerJson = {
        'id': 14,
        'agencyId': 1,
        'name': 'Ramesh Chandra Sharma',
        'phonePrimary': '+91 98200 12345',
        'phoneSecondary': '+91 98200 54321',
        'email': 'ramesh@sharmaholdings.com',
        'address': 'Flat 1204, Sea Breeze, Worli, Mumbai',
        'idType': 'Aadhaar',
        'idNumber': 'XXXX-XXXX-1234',
        'notes': 'Prefers morning calls between 10am-12pm',
        'propertyCount': 3,
        'createdAt': '2026-09-19T10:00:00.000Z',
      };

      final owner = OwnerModel.fromJson(ownerJson);
      expect(owner.id, 14);
      expect(owner.name, 'Ramesh Chandra Sharma');
      expect(owner.phonePrimary, '+91 98200 12345');
      expect(owner.email, 'ramesh@sharmaholdings.com');
      expect(owner.propertyCount, 3);

      final propJson = {
        'id': 'PR-102',
        'title': 'Worli 4BHK Penthouse',
        'ownerId': 14,
        'ownerName': owner.name,
        'ownerPhonePrimary': owner.phonePrimary,
      };
      final prop = PropertyModel.fromJson(propJson);
      expect(prop.ownerId, 14);
      expect(prop.ownerName, 'Ramesh Chandra Sharma');
      expect(prop.ownerPhonePrimary, '+91 98200 12345');
    });

    test('PropertyModel handles negotiable prices and rate parsing without zero anomalies', () {
      final propSale = PropertyModel.fromJson({
        'id': 'PR-103',
        'title': 'Bandra Luxury Villa',
        'price': '₹3.5 Cr (Negotiable)',
        'type': 'Sale',
        'areaSqft': 2500,
      });

      expect(propSale.price, '₹3.5 Cr (Negotiable)');
      expect(propSale.areaSqft, 2500.0);
    });

    test('ExportService generates valid Excel-compliant CSV with UTF-8 BOM and columns', () {
      final prop = PropertyModel.fromJson({
        'id': 'PR-901',
        'title': 'Worli Penthouse',
        'price': '₹4.5 Cr',
        'type': 'Sale',
        'purpose': 'Sale',
        'bhk': '3 BHK',
        'location': 'Worli, Mumbai',
        'city': 'Mumbai',
        'ownerName': 'Vikram Singhania',
        'ownerPhonePrimary': '+91 98200 99887',
      });

      final owner = OwnerModel.fromJson({
        'id': 101,
        'name': 'Vikram Singhania',
        'phonePrimary': '+91 98200 99887',
        'email': 'vikram@singhania.com',
        'idType': 'Aadhaar',
        'idNumber': 'XXXX-XXXX-9988',
        'notes': 'High net worth client',
      });

      // 1. Test Properties CSV Generation
      final propertiesCsv = ExportService.generatePropertiesCsv([prop]);
      expect(propertiesCsv.startsWith('\uFEFF'), isTrue, reason: 'Must include UTF-8 BOM for Microsoft Excel');
      expect(propertiesCsv.contains('Property ID,Title,Type / Purpose,Property Type,Price'), isTrue);
      expect(propertiesCsv.contains('Worli Penthouse'), isTrue);
      expect(propertiesCsv.contains('Vikram Singhania'), isTrue);
      expect(propertiesCsv.contains('₹4.5 Cr'), isTrue);

      // 2. Test Owner Portfolio CSV Generation
      final portfolioCsv = ExportService.generateOwnerPortfolioCsv(
        owner: owner,
        ownerProperties: [prop],
      );
      expect(portfolioCsv.startsWith('\uFEFF'), isTrue);
      expect(portfolioCsv.contains('PROPCONNECT - OWNER PORTFOLIO REPORT'), isTrue);
      expect(portfolioCsv.contains('Vikram Singhania'), isTrue);
      expect(portfolioCsv.contains('Worli Penthouse'), isTrue);
      expect(portfolioCsv.contains('High net worth client'), isTrue);

      // 3. Test Owners Directory CSV Generation
      final directoryCsv = ExportService.generateOwnersDirectoryCsv(
        owners: [owner],
        allProperties: [prop],
      );
      expect(directoryCsv.startsWith('\uFEFF'), isTrue);
      expect(directoryCsv.contains('Owner ID,Full Name,Primary Phone,Secondary Phone'), isTrue);
      expect(directoryCsv.contains('Vikram Singhania'), isTrue);
      expect(directoryCsv.contains('vikram@singhania.com'), isTrue);
    });

    test('LocationHelper automatically extracts City, State, and Area without manual re-typing', () {
      // 1. Popular Indian Real Estate Hubs
      final mumbai = LocationHelper.extractFromText('Bandra West, Mumbai');
      expect(mumbai.city, 'Mumbai');
      expect(mumbai.state, 'Maharashtra');
      expect(mumbai.area, 'Bandra West');

      final bangalore = LocationHelper.extractFromText('Indiranagar, Bangalore');
      expect(bangalore.city, 'Bengaluru');
      expect(bangalore.state, 'Karnataka');
      expect(bangalore.area, 'Indiranagar');

      final gurugram = LocationHelper.extractFromText('Cyber City, Gurugram');
      expect(gurugram.city, 'Gurugram');
      expect(gurugram.state, 'Haryana');
      expect(gurugram.area, 'Cyber City');

      final delhi = LocationHelper.extractFromText('Connaught Place, New Delhi');
      expect(delhi.city, 'New Delhi');
      expect(delhi.state, 'Delhi');

      final pune = LocationHelper.extractFromText('Koregaon Park, Pune');
      expect(pune.city, 'Pune');
      expect(pune.state, 'Maharashtra');

      // 2. Structured Nominatim OpenStreetMap response (live search)
      final nominatimAddress = {
        'suburb': 'Worli',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'country': 'India',
        'postcode': '400018',
      };
      final liveSearch = LocationHelper.extractDetails(
        rawLocation: 'Worli, Mumbai, Mumbai Suburban, Maharashtra, 400018, India',
        addressDetails: nominatimAddress,
        latitude: 19.0176,
        longitude: 72.8302,
      );
      expect(liveSearch.city, 'Mumbai');
      expect(liveSearch.state, 'Maharashtra');
      expect(liveSearch.area, 'Worli');
      expect(liveSearch.location, 'Worli, Mumbai');
      expect(liveSearch.googleMapUrl, 'https://www.google.com/maps/search/?api=1&query=19.0176,72.8302');

      // 3. Google Maps URL parsing
      final googleMapPlace = LocationHelper.parseGoogleMapsUrl(
        'https://www.google.com/maps/place/Worli,+Mumbai,+Maharashtra/@19.0176,72.8302,15z',
      );
      expect(googleMapPlace, isNotNull);
      expect(googleMapPlace!.city, 'Mumbai');
      expect(googleMapPlace.state, 'Maharashtra');
      expect(googleMapPlace.latitude, 19.0176);
      expect(googleMapPlace.longitude, 72.8302);
    });
  });
}
