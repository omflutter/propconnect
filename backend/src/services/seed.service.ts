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
import { WhatsAppLog } from '../models/whatsappLog.model';
import { Notification } from '../models/notification.model';

export const seedInitialData = async () => {
  try {
    // 1. Ensure Platform Super Admin exists for Web Admin Portal & Platform Governance
    const adminUser = await User.findOne({ where: { email: 'admin@propconnect.in' } });
    if (!adminUser) {
      console.log('[Seed] Initializing Platform Super Admin...');
      const salt = await bcrypt.genSalt(10);
      const adminPasswordHash = await bcrypt.hash('admin123', salt);

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
      console.log('[Seed] Platform Super Admin initialized successfully.');
    }

    // 2. Ensure Platform Config exists
    const configCount = await PlatformConfig.count();
    if (configCount === 0) {
      await PlatformConfig.create({
        platformFeePercent: 2.5,
        basicTierFee: 2999,
        proTierFee: 5999,
        enterpriseTierFee: 14999,
        maintenanceMode: false,
      });
      console.log('[Seed] PlatformConfig initialized.');
    }

    console.log('[Seed] Database integrity verified: Clean state ready for real users & agencies.');
  } catch (error: any) {
    console.error('[Seed Error] Failed to verify initial database records:', error.message || error);
  }
};
