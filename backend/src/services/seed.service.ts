import bcrypt from 'bcryptjs';
import { User } from '../models/user.model';
import { Agency } from '../models/agency.model';
import { PlatformConfig } from '../models/config.model';
import { AuditLog } from '../models/auditLog.model';
import { Property } from '../models/property.model';
import { Deal } from '../models/deal.model';
import { CollaborationRequest } from '../models/collaboration.model';
import { Commission } from '../models/commission.model';
import { Settlement } from '../models/settlement.model';

export const seedInitialData = async () => {
  try {
    const auditCount = await AuditLog.count();
    if (auditCount === 0) {
      await AuditLog.bulkCreate([
        {
          logCode: 'LOG-7001',
          actorName: 'Om Shivam',
          actorRole: 'Super Admin',
          action: 'Property Inventory Created',
          target: 'Sea Face Villa (PR-104)',
          ipAddress: '103.22.180.4',
          status: 'Success',
          details: { propertyId: 'PR-104', location: 'Bandra West, Mumbai', price: '₹4.5 Cr' },
        },
        {
          logCode: 'LOG-7002',
          actorName: 'Rajesh Kumar',
          actorRole: 'Agency Admin',
          action: 'Collaboration Requested',
          target: 'REQ-301 (DL-501)',
          ipAddress: '115.240.90.12',
          status: 'Success',
          details: { dealId: 'DL-501', initiatingAgency: 'Metro Realty India', commissionShare: '50/50' },
        },
        {
          logCode: 'LOG-7003',
          actorName: 'Priya Sharma',
          actorRole: 'Broker',
          action: 'Deal Status Changed',
          target: 'DL-502 -> Closed',
          ipAddress: '49.207.140.88',
          status: 'Success',
          details: { dealId: 'DL-502', newStatus: 'Closed', dealValue: '₹1.8 Cr' },
        },
        {
          logCode: 'LOG-7004',
          actorName: 'System Webhook',
          actorRole: 'Razorpay API',
          action: 'Subscription Payment Received',
          target: 'INV-2026-001 (₹7,999)',
          ipAddress: '52.66.190.22',
          status: 'Success',
          details: { invoiceId: 'INV-2026-001', amount: 7999, currency: 'INR', gateway: 'Razorpay' },
        },
        {
          logCode: 'LOG-7005',
          actorName: 'Vikram Malhotra',
          actorRole: 'Operations Admin',
          action: 'Agency Onboarded',
          target: 'Sunrise Properties (AG-001)',
          ipAddress: '103.88.220.10',
          status: 'Success',
          details: { agencyCode: 'AG-001', adminEmail: 'om@propconnect.in', tier: 'Enterprise' },
        },
        {
          logCode: 'LOG-7006',
          actorName: 'Om Shivam',
          actorRole: 'Super Admin',
          action: 'Commission Rule Updated',
          target: 'COMM-801 (₹8.4 Lakhs)',
          ipAddress: '103.22.180.4',
          status: 'Success',
          details: { commissionId: 'COMM-801', splitRatio: '2.5%' },
        },
        {
          logCode: 'LOG-7007',
          actorName: 'Guest / Unknown',
          actorRole: 'Unknown',
          action: 'User Login Failed',
          target: 'Auth / Invalid Token Attempt',
          ipAddress: '185.220.101.5',
          status: 'Warning',
          details: { attemptCount: 3, userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', reason: 'Invalid JWT signature' },
        },
      ]);
      console.log('[Seed] Default Audit Logs seeded.');
    }
    const configCount = await PlatformConfig.count();
    if (configCount === 0) {
      await PlatformConfig.create({
        platformFeePercent: 2.5,
        basicTierFee: 2999,
        proTierFee: 5999,
        enterpriseTierFee: 14999,
        maintenanceMode: false,
      });
      console.log('[Seed] Default PlatformConfig initialized.');
    }

    // Seed Demo Deals if empty
    const dealCount = await Deal.count();
    if (dealCount === 0) {
      await Deal.bulkCreate([
        {
          dealCode: 'DL-501',
          propertyId: 1,
          propertyName: 'Sea Face Villa (Bandra West)',
          agencyAId: 1,
          agencyAName: 'Sunrise Properties',
          brokerAId: 1,
          brokerAName: 'Om Shivam',
          agencyBId: 2,
          agencyBName: 'Metro Reality India',
          brokerBId: 2,
          brokerBName: 'Rajesh Kumar',
          clientName: 'Sunil Mittal',
          clientPhone: '+91 98200 12345',
          clientEmail: 'sunil.m@gmail.com',
          clientRequirement: 'Looking for 4+ BHK sea-facing independent villa with private swimming pool and parking.',
          expectedBudget: '₹4.2 Cr',
          status: 'Negotiation Started',
          dealValue: '₹4.2 Cr',
          commissionId: 1,
          remarks: 'Client interested in price negotiation. Site visit completed.',
          auditHistory: [
            { status: 'Lead Assigned', timestamp: '2026-07-20T10:00:00Z', updatedBy: 'Rajesh Kumar', remarks: 'Client lead registered' },
            { status: 'Property Shared', timestamp: '2026-07-20T14:30:00Z', updatedBy: 'Om Shivam', remarks: 'Brochure and floor plans shared' },
            { status: 'Site Visit Completed', timestamp: '2026-07-21T11:00:00Z', updatedBy: 'Rajesh Kumar', remarks: 'Client visited property with family' },
            { status: 'Negotiation Started', timestamp: '2026-07-22T09:30:00Z', updatedBy: 'Om Shivam', remarks: 'Negotiating token and closing terms' },
          ],
        },
        {
          dealCode: 'DL-502',
          propertyId: 2,
          propertyName: 'DLF Cyber City Office Space',
          agencyAId: 2,
          agencyAName: 'Metro Reality India',
          brokerAId: 2,
          brokerAName: 'Rajesh Kumar',
          agencyBId: 3,
          agencyBName: 'Bangalore Estates',
          brokerBId: 3,
          brokerBName: 'Priya Sharma',
          clientName: 'TechCorp Solutions',
          clientPhone: '+91 98450 98765',
          clientEmail: 'admin@techcorp.in',
          clientRequirement: 'Grade-A fully furnished IT office space for 150 workstations.',
          expectedBudget: '₹8.5 Cr',
          status: 'Deal Closed',
          dealValue: '₹8.5 Cr',
          commissionId: 2,
          remarks: 'Registry completed and keys handed over.',
          auditHistory: [
            { status: 'Lead Assigned', timestamp: '2026-07-10T10:00:00Z', updatedBy: 'Priya Sharma' },
            { status: 'Site Visit Completed', timestamp: '2026-07-12T15:00:00Z', updatedBy: 'Priya Sharma' },
            { status: 'Token Generated', timestamp: '2026-07-14T12:00:00Z', updatedBy: 'Rajesh Kumar' },
            { status: 'Agreement Signed', timestamp: '2026-07-15T16:00:00Z', updatedBy: 'Rajesh Kumar' },
            { status: 'Deal Closed', timestamp: '2026-07-18T17:00:00Z', updatedBy: 'Rajesh Kumar' },
          ],
        },
        {
          dealCode: 'DL-503',
          propertyId: 3,
          propertyName: 'Worli Penthouse & Sky Villa',
          agencyAId: 1,
          agencyAName: 'Sunrise Properties',
          brokerAId: 1,
          brokerAName: 'Om Shivam',
          agencyBId: 1,
          agencyBName: 'Sunrise Properties',
          brokerBId: 4,
          brokerBName: 'Amit Verma',
          clientName: 'Rohit Khandelwal',
          clientPhone: '+91 98111 22334',
          clientEmail: 'rohit.k@yahoo.com',
          clientRequirement: 'Ultra-luxury penthouse with private deck and panoramic Arabian sea view.',
          expectedBudget: '₹12.0 Cr',
          status: 'Token Generated',
          dealValue: '₹12.0 Cr',
          commissionId: 3,
          remarks: 'Token amount of ₹10 Lakhs paid. Drafting Sale Agreement.',
          auditHistory: [
            { status: 'Lead Assigned', timestamp: '2026-07-22T08:00:00Z', updatedBy: 'Amit Verma' },
            { status: 'Offer Submitted', timestamp: '2026-07-23T14:00:00Z', updatedBy: 'Amit Verma' },
            { status: 'Token Generated', timestamp: '2026-07-24T18:00:00Z', updatedBy: 'Om Shivam' },
          ],
        },
      ]);
      console.log('[Seed] Demo Deals seeded with PRD 12 stages.');
    }

    // Seed Demo Commissions if empty (PRD Section 12)
    const commCount = await Commission.count();
    if (commCount === 0) {
      await Commission.bulkCreate([
        {
          commissionCode: 'COMM-801',
          dealId: 1,
          propertyId: 1,
          propertyName: 'Sea Face Villa (Bandra West)',
          dealValue: '₹4,20,00,000',
          commissionType: 'Percentage',
          commissionRate: 2.0,
          totalCommission: '₹8,40,000',
          brokerASharePct: 50.0,
          brokerBSharePct: 50.0,
          brokerAAmount: '₹4,20,000',
          brokerBAmount: '₹4,20,000',
          brokerAId: 1,
          brokerAName: 'Om Shivam',
          brokerBId: 2,
          brokerBName: 'Rajesh Kumar',
          agencyAId: 1,
          agencyAName: 'Sunrise Properties',
          agencyBId: 2,
          agencyBName: 'Metro Reality India',
          status: 'Paid',
        },
        {
          commissionCode: 'COMM-802',
          dealId: 2,
          propertyId: 2,
          propertyName: 'DLF Cyber City Office Space',
          dealValue: '₹8,50,00,000',
          commissionType: 'Percentage',
          commissionRate: 1.5,
          totalCommission: '₹12,75,000',
          brokerASharePct: 60.0,
          brokerBSharePct: 40.0,
          brokerAAmount: '₹7,65,000',
          brokerBAmount: '₹5,10,000',
          brokerAId: 2,
          brokerAName: 'Rajesh Kumar',
          brokerBId: 3,
          brokerBName: 'Priya Sharma',
          agencyAId: 2,
          agencyAName: 'Metro Reality India',
          agencyBId: 3,
          agencyBName: 'Bangalore Estates',
          status: 'Partially Paid',
        },
        {
          commissionCode: 'COMM-803',
          dealId: 3,
          propertyId: 3,
          propertyName: 'Worli Penthouse & Sky Villa',
          dealValue: '₹12,00,00,000',
          commissionType: 'Percentage',
          commissionRate: 2.0,
          totalCommission: '₹24,00,000',
          brokerASharePct: 50.0,
          brokerBSharePct: 50.0,
          brokerAAmount: '₹12,00,000',
          brokerBAmount: '₹12,00,000',
          brokerAId: 1,
          brokerAName: 'Om Shivam',
          brokerBId: 4,
          brokerBName: 'Amit Verma',
          agencyAId: 1,
          agencyAName: 'Sunrise Properties',
          agencyBId: 1,
          agencyBName: 'Sunrise Properties',
          status: 'Pending',
        },
      ]);
      console.log('[Seed] Demo Commissions seeded with PRD 50/50 splits.');
    }

    // Seed Demo Settlements if empty (PRD Section 13)
    const settCount = await Settlement.count();
    if (settCount === 0) {
      await Settlement.bulkCreate([
        {
          settlementCode: 'SET-901',
          commissionId: 1,
          dealId: 1,
          propertyName: 'Sea Face Villa (Bandra West)',
          agencyId: 1,
          agencyName: 'Sunrise Properties',
          brokerId: 1,
          brokerName: 'Om Shivam',
          dueDate: '2026-07-25',
          amountReceived: '₹4,20,000',
          amountPending: '₹0',
          paymentMethod: 'NEFT / Bank Transfer',
          referenceNumber: 'HDFC-NEFT-981240918',
          settlementDate: '2026-07-22',
          status: 'Settled',
          remarks: 'Full settlement received via corporate bank transfer.',
        },
        {
          settlementCode: 'SET-902',
          commissionId: 2,
          dealId: 2,
          propertyName: 'DLF Cyber City Office Space',
          agencyId: 2,
          agencyName: 'Metro Reality India',
          brokerId: 2,
          brokerName: 'Rajesh Kumar',
          dueDate: '2026-08-15',
          amountReceived: '₹4,00,000',
          amountPending: '₹3,65,000',
          paymentMethod: 'UPI',
          referenceNumber: 'UPI-AXIS-0091823901',
          settlementDate: '2026-07-20',
          status: 'Partially Settled',
          remarks: 'First tranche received. Second tranche due upon registry.',
        },
      ]);
      console.log('[Seed] Demo Settlements seeded.');
    }

    // Seed Demo Collaboration Requests if empty (PRD Section 6)
    const collabCount = await CollaborationRequest.count();
    if (collabCount === 0) {
      await CollaborationRequest.bulkCreate([
        {
          requestCode: 'REQ-101',
          propertyId: 1,
          propertyName: 'Sea Face Villa (Bandra West)',
          propertyLocation: 'Bandra West, Mumbai',
          propertyPrice: '₹4.2 Cr',
          targetAgencyId: 1,
          targetAgencyName: 'Sunrise Properties',
          targetBrokerId: 1,
          targetBrokerName: 'Om Shivam',
          requestingAgencyId: 2,
          requestingAgencyName: 'Metro Reality India',
          requestingBrokerId: 2,
          requestingBrokerName: 'Rajesh Kumar',
          clientRequirement: 'Client looking for sea-facing villa with 4 BHK, immediate purchase.',
          expectedBudget: '₹4.0 - 4.5 Cr',
          remarks: 'Client is pre-approved for HDFC Home Loan.',
          status: 'Approved',
          dealId: 1,
        },
        {
          requestCode: 'REQ-102',
          propertyId: 3,
          propertyName: 'Worli Penthouse & Sky Villa',
          propertyLocation: 'Worli, Mumbai',
          propertyPrice: '₹12.0 Cr',
          targetAgencyId: 1,
          targetAgencyName: 'Sunrise Properties',
          targetBrokerId: 1,
          targetBrokerName: 'Om Shivam',
          requestingAgencyId: 3,
          requestingAgencyName: 'Bangalore Estates',
          requestingBrokerId: 3,
          requestingBrokerName: 'Priya Sharma',
          clientRequirement: 'High Net-worth Individual looking for duplex penthouse in Worli.',
          expectedBudget: '₹11.5 - 12.0 Cr',
          remarks: 'Can schedule site visit this weekend.',
          status: 'Pending',
        },
      ]);
      console.log('[Seed] Demo Collaboration Requests seeded.');
    }

    const userCount = await User.count();
    if (userCount > 0) {
      console.log('[Seed] Database already contains user seed data.');
      return;
    }

    console.log('[Seed] Seeding initial users, agencies, and admin team members into MySQL...');

    const salt = await bcrypt.genSalt(10);
    const adminPasswordHash = await bcrypt.hash('admin123', salt);
    const agencyPasswordHash = await bcrypt.hash('agency123', salt);
    const brokerPasswordHash = await bcrypt.hash('broker123', salt);

    // Full permissions matrix for Super Admin
    const fullPermissions = {
      agencies: ['view', 'edit', 'delete'],
      brokers: ['view', 'edit', 'delete'],
      properties: ['view', 'edit', 'delete'],
      deals: ['view', 'edit', 'delete'],
      finance: ['view', 'edit', 'delete'],
      gateways: ['view', 'edit', 'delete'],
      whatsapp: ['view', 'edit', 'delete'],
      settings: ['view', 'edit', 'delete'],
    };

    const opsPermissions = {
      agencies: ['view', 'edit', 'delete'],
      brokers: ['view', 'edit'],
      properties: ['view', 'edit'],
      deals: ['view'],
    };

    const financePermissions = {
      finance: ['view', 'edit', 'delete'],
      gateways: ['view', 'edit'],
      agencies: ['view'],
    };

    // Seed Demo Agencies
    const agency1 = await Agency.create({
      agencyCode: 'AG-001',
      name: 'Sunrise Properties',
      reraNumber: 'PRM/KA/RERA/1251/310/PR/171015/000456',
      location: 'Mumbai',
      address: 'Suite 402, Bandra Kurla Complex, Mumbai',
      adminName: 'Om Shivam',
      adminEmail: 'om@propconnect.in',
      adminPhone: '+91 98765 43210',
      subscriptionTier: 'Enterprise (₹14,999/mo)',
      userQuota: 25,
      propertiesCount: 45,
      dealsCount: 12,
      status: 'Active',
    });

    await Agency.create({
      agencyCode: 'AG-002',
      name: 'Metro Realty India',
      reraNumber: 'PRM/DL/RERA/2210/405/PR/180211/000789',
      location: 'Delhi NCR',
      address: 'Cyber City, Tower B, Gurugram',
      adminName: 'Rajesh Kumar',
      adminEmail: 'rajesh@metrorealty.in',
      adminPhone: '+91 98111 22233',
      subscriptionTier: 'Pro (₹5,999/mo)',
      userQuota: 15,
      propertiesCount: 128,
      dealsCount: 34,
      status: 'Active',
    });

    await Agency.create({
      agencyCode: 'AG-003',
      name: 'Bangalore Estates',
      reraNumber: 'PRM/KA/RERA/3340/512/PR/190504/000999',
      location: 'Bangalore',
      address: '100 Feet Road, Indiranagar, Bangalore',
      adminName: 'Priya Sharma',
      adminEmail: 'priya@bangaloreestates.in',
      adminPhone: '+91 98450 12345',
      subscriptionTier: 'Basic (₹2,999/mo)',
      userQuota: 5,
      propertiesCount: 12,
      dealsCount: 3,
      status: 'Pending',
    });

    // Seed Super Admin User (ADM-01)
    await User.create({
      name: 'Platform Super Admin',
      email: 'admin@propconnect.in',
      password: adminPasswordHash,
      phone: '+91 99999 00000',
      role: 'super_admin',
      adminRoleTitle: 'Super Admin (Full Access)',
      permissions: fullPermissions,
      agencyId: null,
      status: 'Active',
    });

    // Seed Operations Admin User (ADM-02)
    await User.create({
      name: 'Vikram Malhotra',
      email: 'vikram.m@propconnect.in',
      password: adminPasswordHash,
      phone: '+91 98765 11111',
      role: 'super_admin',
      adminRoleTitle: 'Operations & Onboarding Manager',
      permissions: opsPermissions,
      agencyId: null,
      status: 'Active',
    });

    // Seed Finance Lead User (ADM-03)
    await User.create({
      name: 'Sneha Kapoor',
      email: 'sneha.k@propconnect.in',
      password: adminPasswordHash,
      phone: '+91 98765 22222',
      role: 'super_admin',
      adminRoleTitle: 'Finance & Payouts Lead',
      permissions: financePermissions,
      agencyId: null,
      status: 'Active',
    });

    // Seed Agency Admin User
    await User.create({
      name: 'Om Shivam',
      email: 'om@propconnect.in',
      password: agencyPasswordHash,
      phone: '+91 98765 43210',
      role: 'agency_admin',
      adminRoleTitle: 'Agency Tenant Admin',
      agencyId: agency1.id,
      status: 'Active',
    });

    // Seed Broker User
    await User.create({
      name: 'Broker User',
      email: 'broker@propconnect.in',
      password: brokerPasswordHash,
      phone: '+91 98222 33344',
      role: 'broker',
      adminRoleTitle: 'Registered Broker',
      agencyId: agency1.id,
      status: 'Active',
    });

    console.log('[Seed] Database seeded successfully with Admin Team & Granular Permissions.');
  } catch (error: any) {
    console.error('[Seed Error] Failed to seed initial database records:', error.message || error);
  }
};
