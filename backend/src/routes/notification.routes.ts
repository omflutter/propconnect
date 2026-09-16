import { Router } from 'express';
import {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification,
  registerFcmToken,
  broadcastNotification,
} from '../controllers/notification.controller';

const router = Router();

router.get('/notifications', getNotifications);
router.put('/notifications/read-all', markAllNotificationsAsRead);
router.put('/notifications/:id/read', markNotificationAsRead);
router.delete('/notifications/:id', deleteNotification);
router.post('/notifications/register-token', registerFcmToken);
router.post('/notifications/broadcast', broadcastNotification);

export default router;
