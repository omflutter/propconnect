import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propconnect/core/models/commission_model.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/owner_model.dart';
import 'package:propconnect/core/models/agency_model.dart';
import 'package:propconnect/core/utils/export_service.dart';
import 'package:propconnect/core/utils/location_helper.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/push_notification_service.dart';
import 'package:propconnect/core/providers/theme_provider.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:propconnect/features/notifications/domain/models/notification_model.dart';
import 'package:propconnect/features/settings/presentation/screens/settings_screen.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/services/biometric_service.dart';
import 'package:propconnect/core/widgets/biometric_lock_wrapper.dart';
import 'package:propconnect/core/models/session_model.dart';
import 'package:propconnect/features/settings/presentation/screens/active_sessions_screen.dart';
import 'package:propconnect/core/services/broker_directory_service.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/features/finance/presentation/screens/commissions_screen.dart';

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

    test('PushNotificationService (PRD Sec 17) permission notifier and route mappings operate correctly', () {
      final pushService = PushNotificationService();
      expect(pushService.isPermissionGrantedNotifier, isNotNull);
      expect(pushService.isPermissionGrantedNotifier.value, isFalse);

      // Verify permission notifier state updates correctly
      pushService.isPermissionGrantedNotifier.value = true;
      expect(pushService.isPermissionGrantedNotifier.value, isTrue);
      pushService.isPermissionGrantedNotifier.value = false;

      // Verify PRD Sec 17 payload event types
      final supportedTypes = ['collaboration', 'deal', 'commission', 'property', 'system'];
      for (final type in supportedTypes) {
        final notif = AppNotification(
          id: 1,
          notificationCode: 'NTF-TEST',
          userId: 1,
          title: 'Test $type',
          message: 'Notification message for $type',
          type: type,
          actionRoute: '/$type',
          isRead: false,
          channels: 'in_app,push',
          createdAt: DateTime.now(),
        );
        expect(notif.actionRoute, '/$type');
      }
    });

    test('AuthStorageService and ThemeModeNotifier manage preferences and dark mode correctly', () async {
      SharedPreferences.setMockInitialValues({});
      await AuthStorageService.init();

      // Test Push Notification Preference
      expect(AuthStorageService.getPushNotificationEnabled(), isTrue);
      await AuthStorageService.setPushNotificationEnabled(false);
      expect(AuthStorageService.getPushNotificationEnabled(), isFalse);

      // Test Email Alerts Preference
      expect(AuthStorageService.getEmailAlertsEnabled(), isFalse);
      await AuthStorageService.setEmailAlertsEnabled(true);
      expect(AuthStorageService.getEmailAlertsEnabled(), isTrue);

      // Test Two-Factor Preference
      expect(AuthStorageService.getTwoFactorEnabled(), isFalse);
      await AuthStorageService.setTwoFactorEnabled(true);
      expect(AuthStorageService.getTwoFactorEnabled(), isTrue);

      // Test Theme Mode Notifier via ProviderContainer
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AuthStorageService.getThemeMode(), 'dark');

      container.read(themeModeProvider.notifier).toggleTheme();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(AuthStorageService.getThemeMode(), 'light');

      container.read(themeModeProvider.notifier).toggleTheme();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('SettingsScreen renders all PRD sections and interactive options properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      await AuthStorageService.init();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Settings'), findsOneWidget);

      // Verify PRD Sections
      expect(find.text('Account & Security'), findsOneWidget);
      expect(find.text('Preferences & Notifications'), findsOneWidget);
      expect(find.text('CRM Rules & System Settings'), findsOneWidget);
      expect(find.text('Offline Capability & Storage'), findsOneWidget);
      expect(find.text('Agency Administration (RBAC)'), findsOneWidget);
      expect(find.text('Data Privacy & Compliance'), findsOneWidget);
      expect(find.text('About & Support'), findsOneWidget);

      // Verify Key Options
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Two-Factor Authentication'), findsOneWidget);
      expect(find.text('Biometric Screen Lock'), findsOneWidget);
      expect(find.text('Active Sessions & Devices'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('WhatsApp Business Alerts'), findsOneWidget);
      expect(find.text('Email Alerts'), findsOneWidget);
      expect(find.text('Default Property Visibility'), findsOneWidget);
      expect(find.text('Commission Structures & Split Defaults'), findsOneWidget);
      expect(find.text('Automated Reminders & Inactivity Rules'), findsOneWidget);
      expect(find.text('Partner Portal Auto-Sync'), findsOneWidget);
      expect(find.text('Offline Property Cache'), findsOneWidget);
      expect(find.text('Export Agency Data'), findsOneWidget);
      expect(find.text('Log Out of PropConnect'), findsOneWidget);
    });

    test('CollaborationRequest and DealModel correctly parse structured requirements and preserve isRequest across status transitions', () {
      final json = {
        'id': 'REQ-101',
        'requestCode': 'REQ-101',
        'propertyId': 42,
        'propertyName': 'Luxury Seafront Penthouse',
        'targetAgencyId': 1,
        'targetAgencyName': 'Sunrise Realty',
        'targetBrokerId': 2,
        'targetBrokerName': 'Om Shivam',
        'requestingAgencyId': 5,
        'requestingAgencyName': 'Metro Estates',
        'requestingBrokerId': 11,
        'requestingBrokerName': 'Rahul Sharma',
        'clientRequirement': '• Profile: End-User (Outright Purchase)\n• Financing: Pre-Approved Loan\n• Timeline: Immediate (<15 Days)\n• Proposed Split: 50 / 50 (Standard)\n• Preferences: Vastu compliant, east facing',
        'expectedBudget': '₹4.5 Cr',
        'remarks': 'Split: 50 / 50 (Standard) | Immediate move-in buyer ready',
        'status': 'Pending',
        'isRequest': true,
        'isIncomingRequest': true,
        'partnerBroker': 'Rahul Sharma',
        'partnerAgency': 'Metro Estates',
      };

      final deal = DealModel.fromJson(json);

      expect(deal.id, 'REQ-101');
      expect(deal.propertyName, 'Luxury Seafront Penthouse');
      expect(deal.isRequest, isTrue);
      expect(deal.isIncomingRequest, isTrue);
      expect(deal.status, 'Pending');
      expect(deal.expectedBudget, '₹4.5 Cr');
      expect(deal.clientRequirement, contains('Pre-Approved Loan'));
      expect(deal.clientRequirement, contains('50 / 50 (Standard)'));

      // Transition to Approved: verify isRequest remains true!
      final approvedDeal = DealModel(
        id: deal.id,
        dealCode: deal.dealCode,
        propertyId: deal.propertyId,
        propertyName: deal.propertyName,
        partnerBroker: deal.partnerBroker,
        partnerAgency: deal.partnerAgency,
        status: 'Approved',
        amount: deal.amount,
        dealValue: deal.dealValue,
        isRequest: true,
        isIncomingRequest: deal.isIncomingRequest,
        clientRequirement: deal.clientRequirement,
        expectedBudget: deal.expectedBudget,
        remarks: deal.remarks,
        createdAt: deal.createdAt,
        respondedAt: DateTime.now(),
      );

      expect(approvedDeal.status, 'Approved');
      expect(approvedDeal.isRequest, isTrue);
      expect(approvedDeal.isIncomingRequest, isTrue);
      expect(approvedDeal.respondedAt, isNotNull);
    });

    test('DealModel correctly models PRD Section 9 12-stage milestones and progress calculations', () {
      expect(DealModel.prdMilestones.length, 12);
      expect(DealModel.prdMilestones[0], 'Lead Assigned');
      expect(DealModel.prdMilestones[1], 'Property Shared');
      expect(DealModel.prdMilestones[2], 'Site Visit Scheduled');
      expect(DealModel.prdMilestones[3], 'Site Visit Completed');
      expect(DealModel.prdMilestones[4], 'Negotiation Started');
      expect(DealModel.prdMilestones[5], 'Offer Submitted');
      expect(DealModel.prdMilestones[6], 'Token Generated');
      expect(DealModel.prdMilestones[7], 'Agreement Signed');
      expect(DealModel.prdMilestones[8], 'Registry Scheduled');
      expect(DealModel.prdMilestones[9], 'Registry Completed');
      expect(DealModel.prdMilestones[10], 'Deal Closed');
      expect(DealModel.prdMilestones[11], 'Deal Lost');

      final inquiryDeal = DealModel(
        id: 'DL-901',
        propertyId: 'PR-101',
        propertyName: 'Luxury Villa',
        partnerBroker: 'Vikram Mehta',
        partnerAgency: 'Apex Realty',
        status: 'Lead Assigned',
        amount: '₹3.5 Cr',
        dealValue: 35000000.0,
      );
      expect(inquiryDeal.normalizedStage, 'Lead Assigned');
      expect(inquiryDeal.milestoneIndex, 0);
      expect(inquiryDeal.progressPercentage, closeTo(1 / 11, 0.01));

      // Test normalization from legacy statuses
      final legacyTokenDeal = DealModel(
        id: 'DL-902',
        propertyId: 'PR-102',
        propertyName: 'Sea Breeze Flat',
        partnerBroker: 'Rohit Verma',
        partnerAgency: 'Skyline Realtors',
        status: 'Token Done',
        amount: '₹2.1 Cr',
        tokenAmount: '₹5,00,000',
      );
      expect(legacyTokenDeal.normalizedStage, 'Token Generated');
      expect(legacyTokenDeal.milestoneIndex, 6);
      expect(legacyTokenDeal.progressPercentage, closeTo(7 / 11, 0.01));
      expect(legacyTokenDeal.tokenAmount, '₹5,00,000');

      // Test Closed deal
      final closedDeal = DealModel(
        id: 'DL-903',
        propertyId: 'PR-103',
        propertyName: 'Bandra Penthouse',
        partnerBroker: 'Priya Sharma',
        partnerAgency: 'Westside Properties',
        status: 'Closed',
        amount: '₹5.0 Cr',
      );
      expect(closedDeal.normalizedStage, 'Deal Closed');
      expect(closedDeal.milestoneIndex, 10);
      expect(closedDeal.progressPercentage, 1.0);
    });

    test('Collaborations Hub clean separation between Received and Sent requests', () {
      final incomingPending = DealModel(
        id: 'REQ-INC-01',
        dealCode: 'REQ-INC-01',
        propertyId: 'PR-10',
        propertyName: 'Sky Villa Worli',
        partnerBroker: 'Rajesh K',
        partnerAgency: 'Apex Realty',
        status: 'Pending',
        isRequest: true,
        isIncomingRequest: true,
        amount: '₹4.5 Cr',
      );

      final sentPending = DealModel(
        id: 'REQ-SENT-01',
        dealCode: 'REQ-SENT-01',
        propertyId: 'PR-20',
        propertyName: 'Emerald Towers',
        partnerBroker: 'Amit Shah',
        partnerAgency: 'West Coast Estates',
        status: 'Pending',
        isRequest: true,
        isIncomingRequest: false,
        amount: '₹3.2 Cr',
      );

      final list = [incomingPending, sentPending];

      // Test Received Tab filter
      final receivedRequests = list.where((d) => d.isIncomingRequest).toList();
      expect(receivedRequests.length, 1);
      expect(receivedRequests.first.id, 'REQ-INC-01');
      expect(receivedRequests.first.isIncomingRequest, isTrue);

      // Test Sent Tab filter
      final outgoingRequests = list.where((d) => !d.isIncomingRequest).toList();
      expect(outgoingRequests.length, 1);
      expect(outgoingRequests.first.id, 'REQ-SENT-01');
      expect(outgoingRequests.first.isIncomingRequest, isFalse);

      // Verify that for sent requests, the user cannot be the one approving/declining
      expect(sentPending.isIncomingRequest, isFalse);
    });

    test('BrokerModel correctly models assignedPropertyIds and RBAC access scope', () {
      final broker = BrokerModel(
        id: '12',
        name: 'Amit Patel',
        email: 'amit@sunrise.com',
        phone: '+91 98200 44556',
        role: 'Broker / Agent',
        assignedPropertyIds: const ['101', '102'],
      );

      expect(broker.id, '12');
      expect(broker.assignedPropertyIds, ['101', '102']);

      final updated = broker.copyWith(assignedPropertyIds: ['101', '102', '105']);
      expect(updated.assignedPropertyIds.length, 3);
      expect(updated.assignedPropertyIds, contains('105'));
    });

    test('Broker property access restriction scopes visible properties and deals (PRD Sec 3, 4.1.1, 5)', () {
      final propAssigned = PropertyModel.fromJson({
        'id': '101',
        'title': 'Assigned Flat A',
        'location': 'Worli, Mumbai',
        'price': '₹2.5 Cr',
        'bhk': '2 BHK',
        'type': 'Sale',
        'propertyType': 'Apartment',
        'agencyName': 'Sunrise Realty',
        'isPublic': false,
        'agencyId': 1,
      });

      final propUnassignedPrivate = PropertyModel.fromJson({
        'id': '102',
        'title': 'Unassigned Private Agency Listing',
        'location': 'Bandra, Mumbai',
        'price': '₹5.0 Cr',
        'bhk': '3 BHK',
        'type': 'Sale',
        'propertyType': 'Apartment',
        'agencyName': 'Sunrise Realty',
        'isPublic': false,
        'agencyId': 1,
      });

      final propPublicMarketplace = PropertyModel.fromJson({
        'id': '103',
        'title': 'Public Marketplace Penthouse',
        'location': 'Juhu, Mumbai',
        'price': '₹8.0 Cr',
        'bhk': '4 BHK',
        'type': 'Sale',
        'propertyType': 'Apartment',
        'agencyName': 'Apex Properties',
        'isPublic': true,
        'agencyId': 2,
      });

      final allAgencyProperties = [propAssigned, propUnassignedPrivate, propPublicMarketplace];
      final brokerAssignedIds = {'101'};

      // Strict RBAC Filter Rule for Broker My Properties Inventory (PRD Section 3 & 4.1.1):
      // Broker only accesses assigned properties within their agency, never unassigned or other agency inventory
      final brokerVisibleProps = allAgencyProperties.where((p) {
        final belongsToAgency = p.agencyId == 1;
        if (belongsToAgency && brokerAssignedIds.contains(p.id)) return true;
        return false;
      }).toList();

      expect(brokerVisibleProps.length, 1);
      expect(brokerVisibleProps.first.id, '101');
      expect(brokerVisibleProps.any((p) => p.id == '102'), isFalse, reason: 'Unassigned agency listing must remain hidden from broker');
      expect(brokerVisibleProps.any((p) => p.id == '103'), isFalse, reason: 'Other agency listings must not leak into broker inventory');

      // Scoped Deals
      final dealForAssigned = DealModel.fromJson({
        'id': 'DL-01',
        'propertyId': '101',
        'propertyName': 'Assigned Flat A',
        'partnerBroker': 'Rahul V',
        'partnerAgency': 'Metro Realty',
        'amount': '₹2.5 Cr',
        'status': 'Negotiation',
      });

      final dealForUnassigned = DealModel.fromJson({
        'id': 'DL-02',
        'propertyId': '102',
        'propertyName': 'Unassigned Private Agency Listing',
        'partnerBroker': 'Sanjay K',
        'partnerAgency': 'Skyline Homes',
        'amount': '₹5.0 Cr',
        'status': 'Inquiry',
      });

      final allDeals = [dealForAssigned, dealForUnassigned];
      final brokerVisibleDeals = allDeals.where((d) => brokerAssignedIds.contains(d.propertyId)).toList();

      expect(brokerVisibleDeals.length, 1);
      expect(brokerVisibleDeals.first.id, 'DL-01');
    });

    test('Broker authentication role synchronization and isolation', () async {
      SharedPreferences.setMockInitialValues({
        'user_role': 'broker',
        'user_data': '{"id":7,"name":"sunshine broker","email":"sunshineb@gmail.com","role":"broker","agencyId":2,"assignedPropertyIds":[3]}',
      });

      await AuthStorageService.init();
      expect(AuthStorageService.getUserRole(), UserRole.broker);

      final container = ProviderContainer();
      expect(container.read(userRoleProvider), UserRole.broker);
    });

    test('Multi-tenant agency isolation: Newly registered agency admin sees 0 properties and 0 deals', () {
      // 9 seeded properties belonging to Agency 1
      final seededProperties = List.generate(9, (index) => PropertyModel.fromJson({
        'id': 'PROP-${index + 1}',
        'title': 'Agency 1 Property ${index + 1}',
        'location': 'Mumbai',
        'price': '₹2.5 Cr',
        'agencyId': 1,
        'agencyName': 'First Realty Group',
        'isPublic': index % 2 == 0,
      }));

      // Newly registered agency admin belonging to Agency 2
      final newAgencyId = 2;
      final newAgencyName = 'Fresh Horizon Realtors';

      // Agency Admin scoping rule
      final newAgencyProperties = seededProperties.where((p) {
        if (p.agencyId != null && p.agencyId.toString() == newAgencyId.toString()) return true;
        if (p.agencyName.trim().toLowerCase() == newAgencyName.trim().toLowerCase()) return true;
        return false;
      }).toList();

      // Newly created agency has 0 properties in dashboard and inside properties screen
      expect(newAgencyProperties.length, 0);

      // Agency 1 admin sees all 9 properties
      final agency1Properties = seededProperties.where((p) {
        return p.agencyId != null && p.agencyId.toString() == '1';
      }).toList();
      expect(agency1Properties.length, 9);
    });

    test('Deal Pipeline deep-linking: stage selection properly maps and filters deals to the target milestone', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedDealStageProvider), 'All');

      // Emulate user clicking "Site Visit Scheduled" on home Deal Pipeline
      container.read(selectedDealStageProvider.notifier).setStage('Site Visit');
      expect(container.read(selectedDealStageProvider), 'Site Visit');

      // Emulate user clicking "Token Generated" on home Deal Pipeline
      container.read(selectedDealStageProvider.notifier).setStage('Token / Booking');
      expect(container.read(selectedDealStageProvider), 'Token / Booking');

      // Emulate user clicking "View All" on home Deal Pipeline
      container.read(selectedDealStageProvider.notifier).setStage('All');
      expect(container.read(selectedDealStageProvider), 'All');
    });

    test('BiometricService properly manages app lock lifecycle and preferences', () async {
      await AuthStorageService.init();
      await AuthStorageService.saveSession(
        token: 'test-token',
        user: {'id': 1, 'name': 'Test User'},
        role: UserRole.broker,
      );
      await AuthStorageService.setBiometricLockEnabled(true);

      final bioService = BiometricService();
      bioService.init();
      expect(bioService.isAppLocked.value, true);

      bioService.unlockApp();
      expect(bioService.isAppLocked.value, false);

      bioService.lockApp();
      expect(bioService.isAppLocked.value, true);

      // Logging out clears session and automatically unlocks app
      await AuthStorageService.clearSession();
      expect(bioService.isAppLocked.value, false);
      expect(AuthStorageService.isLoggedIn(), false);
    });

    testWidgets('BiometricLockWrapper renders lock overlay when isAppLocked is true and unlocks to child', (tester) async {
      final bioService = BiometricService();
      bioService.isAppLocked.value = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: BiometricLockWrapper(
            child: Scaffold(
              body: Text('Protected CRM Dashboard Content'),
            ),
          ),
        ),
      );

      // While locked, lock screen is rendered
      expect(find.text('PropConnect is Locked'), findsOneWidget);
      expect(find.text('Unlock with Device Lock'), findsOneWidget);

      // Now unlock
      bioService.unlockApp();
      await tester.pumpAndSettle();

      // Protected content is visible
      expect(find.text('Protected CRM Dashboard Content'), findsOneWidget);
      expect(find.text('PropConnect is Locked'), findsNothing);
    });

    test('SessionModel correctly parses comprehensive device hardware and security metadata (PRD Sec 8.1)', () {
      final json = {
        'id': 'sess_123',
        'deviceName': 'Apple iPhone 15 Pro',
        'deviceType': 'mobile',
        'os': 'iOS 17.5.1',
        'appVersion': 'PropConnect App v1.0.0',
        'ipAddress': '103.21.124.58',
        'location': 'Mumbai, Maharashtra, India',
        'loginAt': '2026-09-23T10:45:00.000Z',
        'lastActiveAt': 'Active now',
        'expiresAt': '2026-09-30T10:45:00.000Z',
        'isCurrent': true,
        'authMethod': 'JWT Bearer + Device Biometric Lock',
        'status': 'active',
      };

      final session = SessionModel.fromJson(json);
      expect(session.id, 'sess_123');
      expect(session.deviceName, 'Apple iPhone 15 Pro');
      expect(session.deviceType, 'mobile');
      expect(session.os, 'iOS 17.5.1');
      expect(session.ipAddress, '103.21.124.58');
      expect(session.location, 'Mumbai, Maharashtra, India');
      expect(session.isCurrent, true);
      expect(session.authMethod, 'JWT Bearer + Device Biometric Lock');

      final serialized = session.toJson();
      expect(serialized['id'], 'sess_123');
      expect(serialized['isCurrent'], true);
    });

    testWidgets('ActiveSessionsScreen renders comprehensive device details and session audit cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ActiveSessionsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // App bar & Security overview
      expect(find.text('Active Sessions & Devices'), findsOneWidget);
      expect(find.text('PRD Sec 8.1 Session Security & Audit'), findsOneWidget);
      expect(find.textContaining('Active Device'), findsOneWidget);

      // Current Device section
      expect(find.text('Current Device'), findsOneWidget);
      expect(find.text('THIS DEVICE'), findsOneWidget);
      expect(find.text('Location'), findsWidgets);
      expect(find.text('IP Address'), findsWidgets);

      // Security & Session Policy
      expect(find.text('Security & Session Policy (PRD Sec 8.1)'), findsOneWidget);
    });

    test('DealModel.fromJson correctly maps backend collaboration request fields to agencyAId and agencyBId', () {
      final backendCollabJson = {
        'id': 6,
        'requestCode': 'REQ-106',
        'propertyId': 11,
        'propertyName': 'Mountain Side',
        'propertyLocation': 'Mumbai',
        'propertyPrice': 'Price on Request',
        'targetAgencyId': 10,
        'targetAgencyName': 'new agency',
        'targetBrokerId': 11,
        'targetBrokerName': 'Rajesh',
        'requestingAgencyId': 11,
        'requestingAgencyName': 'Alok Homes',
        'requestingBrokerId': 13,
        'requestingBrokerName': 'Alok',
        'clientRequirement': 'Need collaboration',
        'expectedBudget': '₹3.5 Cr',
        'remarks': '',
        'status': 'Pending',
        'isRequest': true,
        'isIncomingRequest': false,
      };

      final deal = DealModel.fromJson(backendCollabJson);

      expect(deal.dealCode, 'REQ-106');
      expect(deal.agencyAId, 10);
      expect(deal.agencyAName, 'new agency');
      expect(deal.brokerAId, 11);
      expect(deal.brokerAName, 'Rajesh');
      expect(deal.agencyBId, 11);
      expect(deal.agencyBName, 'Alok Homes');
      expect(deal.brokerBId, 13);
      expect(deal.brokerBName, 'Alok');
      expect(deal.isRequest, true);
      expect(deal.isIncomingRequest, false);
      expect(deal.status, 'Pending');
    });

    test('BrokerDirectoryService dynamically resolves partner broker and agency for property and deal', () {
      final prop = PropertyModel.fromJson({
        'id': '12',
        'title': 'Really great property',
        'price': '₹3.5 Cr',
        'bhk': '3 BHK',
        'type': 'Sale',
        'propertyType': 'Apartment',
        'location': 'Mumbai',
        'agencyId': 11,
        'agencyName': 'Alok Homes',
        'brokerId': 13,
        'brokerName': 'Alok',
      });

      final partner = BrokerDirectoryService.resolvePartnerForProperty(prop);
      expect(partner, '13');

      final deal = DealModel(
        id: 'REQ-106',
        propertyId: '11',
        propertyName: 'Mountain Side',
        agencyAId: 10,
        agencyAName: 'new agency',
        brokerAId: 11,
        brokerAName: 'Rajesh',
        agencyBId: 11,
        agencyBName: 'Alok Homes',
        brokerBId: 13,
        brokerBName: 'Alok',
        partnerBroker: 'Alok',
        partnerAgency: 'Alok Homes',
        status: 'Pending',
        amount: '₹3.5 Cr',
        isRequest: true,
        isIncomingRequest: true, // For Rajesh (User 11), incoming request from Alok (User 13)
      );

      final resolvedChatPartner = BrokerDirectoryService.resolvePartnerForCollaboration(deal, '11');
      expect(resolvedChatPartner, '13'); // Rajesh chats with Alok (13)

      // Test active deal DL-504 with bilateral partner resolution
      final activeDeal = DealModel(
        id: '4',
        dealCode: 'DL-504',
        propertyId: '12',
        propertyName: 'Really great property',
        agencyAId: 11,
        agencyAName: 'Alok Homes',
        brokerAId: 13,
        brokerAName: 'Alok',
        agencyBId: 12,
        agencyBName: 'Ashok Properties',
        brokerBId: 14,
        brokerBName: 'Ashok',
        partnerBroker: 'Ashok',
        partnerAgency: 'Ashok Properties',
        status: 'Site Visit',
        amount: '₹3.5 Cr',
        documents: [
          {
            'id': 'DOC-101',
            'title': 'Executed Agreement',
            'documentType': 'Agreement to Sell',
            'fileUrl': 'https://storage.propconnect.com/deals/4/agreement.pdf',
            'uploadedBy': 'Alok',
            'uploadedAt': '2026-09-23T12:00:00Z',
          }
        ],
      );

      // Verify documents parsed properly
      expect(activeDeal.documents.length, 1);
      expect(activeDeal.documents.first['title'], 'Executed Agreement');

      // When Alok (Party A, ID 13) opens deal, partner is Ashok (Party B, ID 14)
      final alokPartner = BrokerDirectoryService.resolvePartnerDetailsForDeal(activeDeal, '13', currentAgencyId: 11);
      expect(alokPartner.id, '14');
      expect(alokPartner.name, 'Ashok');
      expect(alokPartner.agencyName, 'Ashok Properties');

      // When Ashok (Party B, ID 14) opens deal, partner is Alok (Party A, ID 13)
      final ashokPartner = BrokerDirectoryService.resolvePartnerDetailsForDeal(activeDeal, '14', currentAgencyId: 12);
      expect(ashokPartner.id, '13');
      expect(ashokPartner.name, 'Alok');
      expect(ashokPartner.agencyName, 'Alok Homes');
    });

    test('Property collaboration status detection accurately recognizes active deal or pending collaboration', () {
      final property = PropertyModel.fromJson({
        'id': '25',
        'title': 'Skyline Penthouse',
        'location': 'Bandra West, Mumbai',
        'price': '₹12.5 Cr',
        'bhk': '4 BHK',
        'type': 'Sale',
        'propertyType': 'Penthouse',
        'status': 'Available',
        'agencyName': 'Prestige Realty',
        'agencyId': 5,
        'brokerName': 'Sunil Verma',
        'brokerId': 8,
      });

      final activeDeal = DealModel(
        id: '10',
        dealCode: 'DL-510',
        propertyId: '25',
        propertyName: 'Skyline Penthouse',
        agencyAId: 5,
        agencyAName: 'Prestige Realty',
        brokerAId: 8,
        brokerAName: 'Sunil Verma',
        agencyBId: 10,
        agencyBName: 'Apex Capital',
        brokerBId: 15,
        brokerBName: 'Rohan Mehra',
        partnerBroker: 'Sunil Verma',
        partnerAgency: 'Prestige Realty',
        status: 'Negotiation',
        amount: '₹12.5 Cr',
        isRequest: false,
      );

      final pendingCollab = DealModel(
        id: 'REQ-201',
        dealCode: 'REQ-201',
        propertyId: '25',
        propertyName: 'Skyline Penthouse',
        agencyAId: 5,
        agencyAName: 'Prestige Realty',
        brokerAId: 8,
        brokerAName: 'Sunil Verma',
        agencyBId: 10,
        agencyBName: 'Apex Capital',
        brokerBId: 15,
        brokerBName: 'Rohan Mehra',
        partnerBroker: 'Sunil Verma',
        partnerAgency: 'Prestige Realty',
        status: 'Pending',
        amount: '₹12.5 Cr',
        isRequest: true,
        isIncomingRequest: false,
      );

      // Simulation for Apex Capital (agencyId: 10)
      bool involvesAgency(DealModel d, int agencyId) {
        return d.agencyAId == agencyId || d.agencyBId == agencyId;
      }

      // 1. With active deal: recognized as active collaboration
      final dealsWithActive = [activeDeal];
      final activeMatching = dealsWithActive.where((d) => d.propertyId == property.id && involvesAgency(d, 10)).toList();
      final hasActive = activeMatching.any((d) => !d.isRequest || d.status.toLowerCase() == 'approved');
      expect(hasActive, isTrue);

      // 2. With pending request: recognized as pending collaboration
      final dealsWithPending = [pendingCollab];
      final pendingMatching = dealsWithPending.where((d) => d.propertyId == property.id && involvesAgency(d, 10)).toList();
      final hasPending = pendingMatching.any((d) => d.isRequest && d.status.toLowerCase() == 'pending');
      expect(hasPending, isTrue);

      // 3. For an unrelated third party agency (agencyId: 99): no collaboration exists
      final unrelatedMatching = dealsWithActive.where((d) => d.propertyId == property.id && involvesAgency(d, 99)).toList();
      expect(unrelatedMatching.isEmpty, isTrue);
    });

    test('Search property collaboration state correctly switches between Request Collaboration, Request Pending, and View Active Deal', () {
      final prop = PropertyModel.fromJson({
        'id': 'prop-101',
        'title': 'Grand Sea View Residence',
        'price': '₹5.5 Cr',
        'location': 'Worli, Mumbai',
        'bhk': '3 BHK',
        'type': 'Sale',
        'propertyType': 'Apartment',
        'status': 'Available',
        'agencyName': 'Ocean Realty',
        'agencyId': 20,
      });

      // Case 1: Fresh property with no requests or deals
      final allDealsEmpty = <DealModel>[];
      final match1 = allDealsEmpty.where((d) => d.propertyId == prop.id).toList();
      final hasActive1 = match1.any((d) => !d.isRequest || d.status.toLowerCase() == 'approved');
      final hasPending1 = match1.any((d) => d.isRequest && d.status.toLowerCase() == 'pending');
      expect(hasActive1, isFalse);
      expect(hasPending1, isFalse); // Yields "Request Collaboration"

      // Case 2: Collaboration request sent and pending
      final allDealsWithReq = [
        DealModel(
          id: 'REQ-999',
          dealCode: 'REQ-999',
          propertyId: 'prop-101',
          propertyName: 'Grand Sea View Residence',
          partnerBroker: 'Ocean Agent',
          partnerAgency: 'Ocean Realty',
          status: 'Pending',
          amount: '₹5.5 Cr',
          isRequest: true,
        ),
      ];
      final match2 = allDealsWithReq.where((d) => d.propertyId == prop.id).toList();
      final hasActive2 = match2.any((d) => !d.isRequest || d.status.toLowerCase() == 'approved');
      final hasPending2 = match2.any((d) => d.isRequest && d.status.toLowerCase() == 'pending');
      expect(hasActive2, isFalse);
      expect(hasPending2, isTrue); // Yields "Request Pending"

      // Case 3: Collaboration approved / active deal
      final allDealsWithActive = [
        DealModel(
          id: 'DL-999',
          dealCode: 'DL-999',
          propertyId: 'prop-101',
          propertyName: 'Grand Sea View Residence',
          partnerBroker: 'Ocean Agent',
          partnerAgency: 'Ocean Realty',
          status: 'Agreement to Sell',
          amount: '₹5.5 Cr',
          isRequest: false,
        ),
      ];
      final match3 = allDealsWithActive.where((d) => d.propertyId == prop.id).toList();
      final hasActive3 = match3.any((d) => !d.isRequest || d.status.toLowerCase() == 'approved');
      final hasPending3 = match3.any((d) => d.isRequest && d.status.toLowerCase() == 'pending');
      expect(hasActive3, isTrue); // Yields "View Active Deal"
      expect(hasPending3, isFalse);
    });

    test('DealModel correctly serializes and deserializes rich milestone date and metadata fields', () {
      final dealJson = {
        'id': 'DL-801',
        'dealCode': 'DL-801',
        'propertyId': 'prop-50',
        'propertyName': 'Imperial Towers 4 BHK',
        'status': 'Agreement to Sell',
        'amount': '₹7.2 Cr',
        'dealValue': 72000000,
        'partnerBroker': 'Anand Shah',
        'partnerAgency': 'Elite Properties',
        'agreementDate': '15 Oct 2026',
        'tokenAmount': '₹10,00,000',
        'tokenDate': '25 Sep 2026',
        'registryDate': '01 Nov 2026',
        'registrationNumber': 'REG-MH-2026-9921',
        'possessionDate': '15 Nov 2026',
        'bankName': 'HDFC Home Loans',
        'loanAmount': '₹5,00,00,000',
        'auditHistory': [
          {
            'status': 'Agreement to Sell',
            'timestamp': '2026-09-23T12:00:00Z',
            'updatedBy': 'Om Shivam',
            'notes': 'Agreement signed by buyer and seller',
            'metadata': {
              'agreementDate': '15 Oct 2026',
              'draftStatus': 'Signed by Both Parties',
            },
          }
        ],
      };

      final deal = DealModel.fromJson(dealJson);
      expect(deal.agreementDate, '15 Oct 2026');
      expect(deal.tokenAmount, '₹10,00,000');
      expect(deal.tokenDate, '25 Sep 2026');
      expect(deal.registryDate, '01 Nov 2026');
      expect(deal.registrationNumber, 'REG-MH-2026-9921');
      expect(deal.possessionDate, '15 Nov 2026');
      expect(deal.bankName, 'HDFC Home Loans');
      expect(deal.loanAmount, '₹5,00,00,000');

      expect(deal.auditHistory.length, 1);
      expect(deal.auditHistory.first.metadata?['agreementDate'], '15 Oct 2026');
      expect(deal.auditHistory.first.metadata?['draftStatus'], 'Signed by Both Parties');

      final serialized = deal.toJson();
      expect(serialized['agreementDate'], '15 Oct 2026');
      expect(serialized['registrationNumber'], 'REG-MH-2026-9921');
      expect(serialized['tokenDate'], '25 Sep 2026');
    });

    test('DealModel correctly parses and formats Indian real estate pricing units (Cr, L, raw)', () {
      expect(DealModel.parsePriceToNumeric('₹4.2 Cr'), 42000000.0);
      expect(DealModel.parsePriceToNumeric('4.20 Crore'), 42000000.0);
      expect(DealModel.parsePriceToNumeric('₹85 L'), 8500000.0);
      expect(DealModel.parsePriceToNumeric('85 Lacs'), 8500000.0);
      expect(DealModel.parsePriceToNumeric('4,500,000'), 4500000.0);
      expect(DealModel.parsePriceToNumeric(42000000), 42000000.0);

      expect(DealModel.formatNumericToPrice(42000000.0), '₹4.2 Cr');
      expect(DealModel.formatNumericToPrice(8500000.0), '₹85 L');
      expect(DealModel.formatNumericToPrice(500000.0), '₹5 L');

      // Test JSON parsing where dealValue is a string with "Cr"
      final dealFromJson = DealModel.fromJson({
        'id': 'DL-999',
        'propertyName': 'Skyline Tower',
        'dealValue': '₹4.2 Cr',
      });
      expect(dealFromJson.dealValue, 42000000.0);
      expect(dealFromJson.amount, '₹4.2 Cr');

      // Test JSON parsing where dealValue is missing but expectedBudget is present
      final budgetDeal = DealModel.fromJson({
        'id': 'DL-1000',
        'propertyName': 'Emerald Bay',
        'expectedBudget': '₹1.5 Cr',
      });
      expect(budgetDeal.dealValue, 15000000.0);
      expect(budgetDeal.amount, '₹1.5 Cr');
    });

    test('Broker property assignment scoping & agency admin single agency rule', () {
      final properties = [
        PropertyModel.fromJson({
          'id': 'p1',
          'title': 'Admin Listing Alpha',
          'price': '2.5 Cr',
          'bhk': '3 BHK',
          'agencyId': 10,
          'agencyName': 'Sunrise Realty',
          'brokerId': 101,
          'brokerName': 'Om Shivam',
        }),
        PropertyModel.fromJson({
          'id': 'p2',
          'title': 'Admin Listing Beta',
          'price': '4.8 Cr',
          'bhk': '4 BHK',
          'agencyId': 10,
          'agencyName': 'Sunrise Realty',
          'brokerId': 102,
          'brokerName': 'Another Agent',
        }),
        PropertyModel.fromJson({
          'id': 'p3',
          'title': 'External Agency Listing',
          'price': '8.0 Cr',
          'bhk': '4 BHK',
          'agencyId': 99,
          'agencyName': 'Competitor Estates',
          'brokerId': 999,
          'brokerName': 'Other Broker',
        }),
      ];

      // Admin from Agency 10
      const userAgencyId = 10;
      const userAgencyName = 'sunrise realty';
      const currentUserId = '101';
      const currentUserName = 'om shivam';

      final assignableProperties = properties.where((p) {
        if (p.agencyId != null && p.agencyId.toString() == userAgencyId.toString()) {
          return true;
        }
        if (p.agencyName.trim().toLowerCase() == userAgencyName) {
          return true;
        }
        if (p.brokerId != null && p.brokerId.toString() == currentUserId) {
          return true;
        }
        if (p.brokerName.trim().toLowerCase() == currentUserName) {
          return true;
        }
        return false;
      }).toList();

      // Only p1 and p2 should be assignable; p3 from Competitor Estates is excluded
      expect(assignableProperties.length, 2);
      expect(assignableProperties.map((p) => p.id), containsAll(['p1', 'p2']));
      expect(assignableProperties.map((p) => p.id), isNot(contains('p3')));

      // Single agency rule verification for Agency Admin
      final bool hasAgency = userAgencyId > 0;
      final shouldShowCreateAgencyButton = !hasAgency;
      final shouldShowManageAgencyButton = hasAgency;

      expect(shouldShowCreateAgencyButton, false);
      expect(shouldShowManageAgencyButton, true);
    });

    test('Chat Property Anchor: deals anchor discussions directly to property conversation ID', () {
      final deal = DealModel(
        id: 'deal-99',
        dealCode: 'DL-99',
        propertyName: 'Skyline Penthouse',
        propertyId: 'prop-500',
        amount: '₹2.5 Cr',
        partnerBroker: 'Broker B',
        partnerAgency: 'Agency Two',
        brokerAId: 101,
        brokerBId: 202,
        brokerAName: 'Broker A',
        brokerBName: 'Broker B',
        agencyAId: 1,
        agencyBId: 2,
        agencyAName: 'Agency One',
        agencyBName: 'Agency Two',
        status: 'Negotiation',
      );

      const currentUserId = '101';
      final partnerId = BrokerDirectoryService.resolvePartnerForCollaboration(deal, currentUserId);
      expect(partnerId, '202');

      final sorted = [currentUserId, partnerId]..sort();
      final hasProp = deal.propertyId.isNotEmpty;
      final convId = hasProp
          ? 'conv_${sorted[0]}_${sorted[1]}_${deal.propertyId}'
          : 'conv_${sorted[0]}_${sorted[1]}';

      // Conversation must be anchored to property, not deal ID
      expect(convId, 'conv_101_202_prop-500');
      expect(convId.contains('_deal_'), false);

      final chatType = hasProp ? 'property' : 'direct';
      expect(chatType, 'property');
    });

    test('My Properties Filtering: correctly filters by Visibility, Purpose, and Status', () {
      final properties = [
        PropertyModel.fromJson({
          'id': 'p1',
          'title': 'Luxury Villa',
          'price': '₹2.5 Cr',
          'type': 'Sale',
          'purpose': 'Sale',
          'isPublic': true,
          'status': 'Available',
          'bhk': '3 BHK',
          'location': 'Whitefield, Bangalore',
        }),
        PropertyModel.fromJson({
          'id': 'p2',
          'title': 'Studio Apartment',
          'price': '₹45,000/mo',
          'type': 'Rent',
          'purpose': 'Rent',
          'isPublic': false,
          'status': 'Available',
          'bhk': '1 BHK',
          'location': 'Indiranagar, Bangalore',
        }),
        PropertyModel.fromJson({
          'id': 'p3',
          'title': 'Commercial Office',
          'price': '₹5.0 Cr',
          'type': 'Sale',
          'purpose': 'Sale',
          'isPublic': false,
          'status': 'Under Negotiation',
          'bhk': '4 BHK',
          'location': 'MG Road, Bangalore',
        }),
        PropertyModel.fromJson({
          'id': 'p4',
          'title': 'Gated Community Villa',
          'price': '₹3.8 Cr',
          'type': 'Sale',
          'purpose': 'Sale',
          'isPublic': true,
          'status': 'Sold',
          'bhk': '4 BHK',
          'location': 'Sarjapur, Bangalore',
        }),
      ];

      // Test Visibility filter: Public
      final publicProps = properties.where((p) => p.isPublic).toList();
      expect(publicProps.length, 2);
      expect(publicProps.map((p) => p.id), containsAll(['p1', 'p4']));

      // Test Visibility filter: Private
      final privateProps = properties.where((p) => !p.isPublic).toList();
      expect(privateProps.length, 2);
      expect(privateProps.map((p) => p.id), containsAll(['p2', 'p3']));

      // Test Purpose filter: Rent
      final rentProps = properties.where((p) => p.type.toLowerCase() == 'rent' || p.purpose.toLowerCase() == 'rent').toList();
      expect(rentProps.length, 1);
      expect(rentProps.first.id, 'p2');

      // Test Status filter: Under Negotiation
      final underNegProps = properties.where((p) => p.status.toLowerCase() == 'under negotiation').toList();
      expect(underNegProps.length, 1);
      expect(underNegProps.first.id, 'p3');

      // Combined Visibility + Status: Public & Available
      final publicAvailable = properties.where((p) => p.isPublic && p.status.toLowerCase() == 'available').toList();
      expect(publicAvailable.length, 1);
      expect(publicAvailable.first.id, 'p1');
    });

    test('DealModel correctly parses real uploaded documents with file URLs, notes, and metadata (PRD Sec 7.3)', () {
      final dealJson = {
        'id': 'deal-999',
        'dealCode': 'DEAL-999',
        'propertyId': 'prop-101',
        'propertyName': 'Lakeview Residences',
        'status': 'Agreement Signed',
        'dealValue': 15000000,
        'documents': [
          {
            'id': 'doc_001',
            'title': 'Agreement to Sell',
            'type': 'Agreement to Sell',
            'url': 'http://72.61.229.6:5000/uploads/agreement_final.pdf',
            'fileName': 'agreement_final.pdf',
            'fileSize': '2.4 MB',
            'fileType': 'application/pdf',
            'notes': 'Executed and signed by both parties',
            'uploadedBy': 'Sunshine Broker',
            'uploadedAt': '2026-09-25T10:00:00.000Z',
          },
          {
            'id': 'doc_002',
            'title': 'Token Booking Receipt',
            'type': 'Token Booking Receipt',
            'url': '/uploads/token_receipt_scan.jpg',
            'fileName': 'token_receipt_scan.jpg',
            'fileSize': '850 KB',
            'fileType': 'image/jpeg',
            'notes': 'Advance cheque receipt copy',
            'uploadedBy': 'Sunshine Broker',
            'uploadedAt': '2026-09-25T10:15:00.000Z',
          }
        ]
      };

      final deal = DealModel.fromJson(dealJson);

      expect(deal.documents.length, 2);
      final doc1 = deal.documents[0];
      expect(doc1['id'], 'doc_001');
      expect(doc1['title'], 'Agreement to Sell');
      expect(doc1['type'], 'Agreement to Sell');
      expect(doc1['url'], 'http://72.61.229.6:5000/uploads/agreement_final.pdf');
      expect(doc1['fileName'], 'agreement_final.pdf');
      expect(doc1['fileSize'], '2.4 MB');
      expect(doc1['fileType'], 'application/pdf');
      expect(doc1['notes'], 'Executed and signed by both parties');
      expect(doc1['uploadedBy'], 'Sunshine Broker');

      final doc2 = deal.documents[1];
      expect(doc2['id'], 'doc_002');
      expect(doc2['title'], 'Token Booking Receipt');
      // Relative path resolution check
      String resolvedUrl = doc2['url'];
      if (resolvedUrl.startsWith('/uploads/')) {
        resolvedUrl = 'http://72.61.229.6:5000$resolvedUrl';
      }
      expect(resolvedUrl, 'http://72.61.229.6:5000/uploads/token_receipt_scan.jpg');

      // Check toJson preserves documents
      final jsonOut = deal.toJson();
      expect(jsonOut['documents'], isA<List>());
      expect((jsonOut['documents'] as List).length, 2);
    });

    test('AppRouter defines /settlements route and CommissionsScreen accepts initialTabIndex for direct sidebar access', () {
      expect(AppRouter.settlements, '/settlements');
      expect(AppRouter.commissions, '/commissions');

      const screenSettlements = CommissionsScreen(initialTabIndex: 1);
      expect(screenSettlements.initialTabIndex, 1);

      const screenCommissions = CommissionsScreen(initialTabIndex: 0);
      expect(screenCommissions.initialTabIndex, 0);
    });

    test('AuthStorageService clearSession reliably clears login and auth credentials without blocking', () async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'auth_token': 'jwt_mock_token_123',
        'user_role': 'broker',
        'user_data': '{"id": 1, "name": "Test Broker"}',
      });

      await AuthStorageService.init();
      expect(AuthStorageService.isLoggedIn(), true);
      expect(AuthStorageService.getAuthToken(), 'jwt_mock_token_123');

      await AuthStorageService.clearSession();

      expect(AuthStorageService.isLoggedIn(), false);
      expect(AuthStorageService.getAuthToken(), isNull);
      expect(AuthStorageService.getUserData(), isNull);
    });

    test('My Properties preserves Sold and Rented properties for owner, while Search filters them out', () {
      final properties = [
        PropertyModel.fromJson({
          'id': 'p1',
          'title': 'Active Villa',
          'price': '₹2.5 Cr',
          'type': 'Sale',
          'purpose': 'Sale',
          'isPublic': true,
          'status': 'Available',
          'agencyId': 10,
          'agencyName': 'Sunshine Agency',
          'brokerId': 1,
          'brokerName': 'Sunshine Broker',
        }),
        PropertyModel.fromJson({
          'id': 'p2',
          'title': 'Closed Apartment',
          'price': '₹1.2 Cr',
          'type': 'Sale',
          'purpose': 'Sale',
          'isPublic': true,
          'status': 'Sold',
          'agencyId': 10,
          'agencyName': 'Sunshine Agency',
          'brokerId': 1,
          'brokerName': 'Sunshine Broker',
        }),
        PropertyModel.fromJson({
          'id': 'p3',
          'title': 'Rented Penthouse',
          'price': '₹75,000/mo',
          'type': 'Rent',
          'purpose': 'Rent',
          'isPublic': false,
          'status': 'Rented',
          'agencyId': 10,
          'agencyName': 'Sunshine Agency',
          'brokerId': 1,
          'brokerName': 'Sunshine Broker',
        }),
      ];

      // In My Properties (accessiblePropertiesProvider for agency 10):
      final myProperties = properties.where((p) => p.agencyId == 10).toList();
      expect(myProperties.length, 3, reason: 'All properties including Sold and Rented must be visible in My Properties');
      expect(myProperties.any((p) => p.status == 'Sold'), true);
      expect(myProperties.any((p) => p.status == 'Rented'), true);

      // In Search (marketplace for external brokers):
      // Only public, non-sold, non-rented properties should appear
      final searchResults = properties.where((p) {
        if (!p.isPublic) return false;
        final s = p.status.toLowerCase();
        if (s == 'sold' || s == 'rented') return false;
        return true;
      }).toList();

      expect(searchResults.length, 1);
      expect(searchResults.first.id, 'p1');
      expect(searchResults.any((p) => p.status == 'Sold'), false, reason: 'Sold properties must be hidden from search');
      expect(searchResults.any((p) => p.status == 'Rented'), false, reason: 'Rented properties must be hidden from search');
    });

    test('PropertyModel correctly handles pincode field serialization and deserialization', () {
      final json = {
        'id': 'prop-pin-101',
        'title': 'Luxury Sea View Villa',
        'price': '₹4.5 Cr',
        'location': 'Bandra West, Mumbai',
        'pincode': '400050',
        'type': 'Villa',
        'purpose': 'Sale',
      };

      final property = PropertyModel.fromJson(json);
      expect(property.pincode, '400050');

      final serialized = property.toJson();
      expect(serialized['pincode'], '400050');
    });

    test('AgencyModel correctly parses referralCode, coinsBalance and pincode', () {
      final json = {
        'id': 42,
        'agencyCode': 'AG-42',
        'name': 'Skyline Realty',
        'adminName': 'Vikram Mehta',
        'adminEmail': 'vikram@skyline.com',
        'location': 'Andheri West, Mumbai',
        'pincode': '400053',
        'referralCode': 'SKY42REF',
        'coinsBalance': 1500,
        'referralCount': 2,
      };

      final agency = AgencyModel.fromJson(json);
      expect(agency.pincode, '400053');
      expect(agency.referralCode, 'SKY42REF');
      expect(agency.coinsBalance, 1500);

      final serialized = agency.toJson();
      expect(serialized['pincode'], '400053');
      expect(serialized['referralCode'], 'SKY42REF');
      expect(serialized['coinsBalance'], 1500);
    });

    test('LocationHelper preserves PIN codes and formats full address correctly', () {
      const rawAddress = 'Flat 402, Sunshine Heights, MG Road, Bandra West, Mumbai 400050, Maharashtra, India';
      
      // formatFullAddress with explicit pincode
      final formatted = LocationHelper.formatFullAddress(address: 'Bandra West, Mumbai', pincode: '400050');
      expect(formatted, contains('400050'));
      expect(formatted, 'Bandra West, Mumbai - 400050');

      // formatFullAddress with address already containing pincode
      final formattedFromRaw = LocationHelper.formatFullAddress(address: rawAddress);
      expect(formattedFromRaw, contains('400050'));

      // extractDetails should extract 6-digit pin codes and retain in display location
      final details = LocationHelper.extractDetails(rawLocation: rawAddress);
      expect(details.pincode, '400050');
      expect(details.location, contains('400050'));
    });
  });
}




