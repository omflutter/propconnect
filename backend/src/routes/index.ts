import { Router } from 'express';
import healthRoutes from './health.routes';
import authRoutes from './auth.routes';
import agencyRoutes from './agency.routes';
import configRoutes from './config.routes';
import brokerRoutes from './broker.routes';
import auditLogRoutes from './auditLog.routes';
import dashboardRoutes from './dashboard.routes';
import propertyRoutes from './property.routes';
import chatRoutes from './chat.routes';
import dealRoutes from './deal.routes';
import collaborationRoutes from './collaboration.routes';
import commissionRoutes from './commission.routes';
import whatsappRoutes from './whatsapp.routes';
import notificationRoutes from './notification.routes';

const router = Router();

router.use(healthRoutes);
router.use(authRoutes);
router.use(agencyRoutes);
router.use(configRoutes);
router.use(brokerRoutes);
router.use(auditLogRoutes);
router.use(dashboardRoutes);
router.use('/properties', propertyRoutes);
router.use(chatRoutes);
router.use(dealRoutes);
router.use(collaborationRoutes);
router.use(commissionRoutes);
router.use(whatsappRoutes);
router.use(notificationRoutes);

export default router;
