import { Router } from 'express';
import {
  getWhatsAppStatus,
  getWhatsAppLogs,
  sendTestWhatsAppMessage,
  sendPropertyBrochure,
  resendWhatsAppMessage,
  handleInteraktWebhook,
} from '../controllers/whatsapp.controller';

const router = Router();

router.get('/whatsapp/status', getWhatsAppStatus);
router.get('/whatsapp/logs', getWhatsAppLogs);
router.post('/whatsapp/send-test', sendTestWhatsAppMessage);
router.post('/whatsapp/send-brochure', sendPropertyBrochure);
router.post('/whatsapp/resend/:id', resendWhatsAppMessage);
router.post('/whatsapp/webhook', handleInteraktWebhook);

export default router;
