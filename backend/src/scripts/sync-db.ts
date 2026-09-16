import { sequelize, initDatabase } from '../config/database';
import { User } from '../models/user.model';
import { Agency } from '../models/agency.model';
import { PlatformConfig } from '../models/config.model';
import { AuditLog } from '../models/auditLog.model';
import { Property } from '../models/property.model';
import { Deal } from '../models/deal.model';
import { CollaborationRequest } from '../models/collaboration.model';
import { Commission } from '../models/commission.model';
import { Settlement } from '../models/settlement.model';
import { Message } from '../models/chat.model';
import { WhatsAppLog } from '../models/whatsappLog.model';
import { Notification } from '../models/notification.model';
import { seedInitialData } from '../services/seed.service';

async function runSync() {
  console.log('[DB Sync] Starting schema synchronization with Aiven PostgreSQL Cloud Database...');
  
  try {
    // 1. Authenticate connection
    await sequelize.authenticate();
    console.log('✅ Connection to PostgreSQL established successfully.');

    // 2. Synchronize all tables (alter existing tables to add new columns)
    await sequelize.sync({ alter: true });
    console.log('✅ All Sequelize models synchronized (alter: true) across PostgreSQL tables:');
    console.log('   - users');
    console.log('   - agencies');
    console.log('   - properties (PRD Sec 4 Owner KYC, carpet area, confidential floor price)');
    console.log('   - deals (PRD Sec 9 12 lifecycle stages & lead privacy audit)');
    console.log('   - collaboration_requests (PRD Sec 6 & 8)');
    console.log('   - commissions (PRD Sec 12 50/50 multi-broker split)');
    console.log('   - settlements (PRD Sec 13 payment reference & ledger)');
    console.log('   - messages (PRD Sec 11 contextual chat)');
    console.log('   - whatsapp_logs (PRD Sec 16 Interakt WhatsApp notifications)');
    console.log('   - notifications (PRD Sec 17 In-App & FCM Push Notification Center)');
    console.log('   - audit_logs & platform_configs');

    // 3. Seed Initial Seed Data
    console.log('[DB Sync] Verifying and applying seed data...');
    await seedInitialData();
    console.log('✅ Seed data verified and populated.');

    console.log('\n🎉 Database sync completed successfully!');
    process.exit(0);
  } catch (error: any) {
    console.error('❌ Database sync failed:', error.message || error);
    process.exit(1);
  }
}

runSync();
