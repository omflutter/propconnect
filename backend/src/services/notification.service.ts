import { Op } from 'sequelize';
import * as admin from 'firebase-admin';
import { Notification } from '../models/notification.model';
import { User } from '../models/user.model';
import { WhatsAppService } from './whatsapp.service';

// Safe initialization of Firebase Admin SDK for Cloud Functions and Local Environments
if (!admin.apps.length) {
  try {
    admin.initializeApp();
    console.log('[NotificationService] Firebase Admin SDK initialized for FCM push messaging.');
  } catch (err: any) {
    console.warn('[NotificationService] Firebase Admin initialization note:', err.message || err);
  }
}

export interface SendNotificationParams {
  userId: number;
  agencyId?: number | null;
  title: string;
  message: string;
  type?: 'collaboration' | 'deal' | 'commission' | 'subscription' | 'system';
  actionRoute?: string;
  metadata?: Record<string, any>;
  channels?: string[]; // ['in_app', 'push', 'whatsapp']
  recipientPhone?: string;
}

export class NotificationService {
  /**
   * Primary method to create in-app notification in PostgreSQL and dispatch FCM push and WhatsApp
   */
  public static async createAndSendNotification(params: SendNotificationParams): Promise<Notification> {
    const totalCount = await Notification.count().catch(() => 0);
    const notificationCode = `NTF-${100 + totalCount + 1}`;
    const channelsList = params.channels && params.channels.length > 0 ? params.channels.join(',') : 'in_app,push';

    // 1. Create In-App Notification in PostgreSQL
    const notif = await Notification.create({
      notificationCode,
      userId: params.userId,
      agencyId: params.agencyId || null,
      title: params.title,
      message: params.message,
      type: params.type || 'system',
      actionRoute: params.actionRoute || null,
      metadata: params.metadata || null,
      isRead: false,
      channels: channelsList,
    });

    // 2. Lookup recipient user for FCM token and phone
    const recipient = await User.findByPk(params.userId).catch(() => null);

    // 3. Dispatch FCM Push Notification if recipient has an active FCM device token
    if (recipient?.fcmToken && channelsList.includes('push')) {
      try {
        const unreadCount = await Notification.count({
          where: { userId: params.userId, isRead: false },
        }).catch(() => 1);

        const pushPayload: admin.messaging.Message = {
          token: recipient.fcmToken,
          notification: {
            title: params.title,
            body: params.message,
          },
          data: {
            notificationId: String(notif.id),
            notificationCode: notif.notificationCode,
            type: params.type || 'system',
            actionRoute: params.actionRoute || '',
            metadata: JSON.stringify(params.metadata || {}),
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'propconnect_notifications',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: unreadCount,
              },
            },
          },
        };

        const fcmRes = await admin.messaging().send(pushPayload);
        notif.fcmMessageId = fcmRes;
        await notif.save();
        console.log(`[FCM Push Sent] To User ${params.userId}, FCM Msg ID: ${fcmRes}`);
      } catch (fcmErr: any) {
        console.warn(`[FCM Push Error] User ${params.userId}:`, fcmErr.message || fcmErr);
      }
    }

    // 4. Dispatch WhatsApp notification if requested and recipient phone available
    const phone = params.recipientPhone || recipient?.phone;
    if (channelsList.includes('whatsapp') && phone) {
      try {
        WhatsAppService.sendNotification({
          recipientPhone: phone,
          event: params.title,
          templateName: 'wa_notification_v1',
          traits: {
            title: params.title,
            message: params.message,
            ...(params.metadata || {}),
          },
          bodyValues: [recipient?.name || 'Broker Partner', params.title, params.message],
        }).catch(() => {});
      } catch (_) {}
    }

    return notif;
  }

  /**
   * Save / update client device FCM push token in PostgreSQL
   */
  public static async registerFcmToken(userId: number, fcmToken: string): Promise<boolean> {
    const [updatedCount] = await User.update(
      { fcmToken },
      { where: { id: userId } }
    );
    console.log(`[FCM Token Registered] User ${userId}, rows affected: ${updatedCount}`);
    return updatedCount > 0;
  }

  /**
   * Fetch In-App notifications for a user with unread counter
   */
  public static async getUserNotifications(params: {
    userId: number;
    filter?: string; // 'all' | 'unread' | 'deal' | 'collaboration' | 'commission'
    limit?: number;
    offset?: number;
  }) {
    const where: any = { userId: params.userId };

    if (params.filter === 'unread') {
      where.isRead = false;
    } else if (params.filter && params.filter !== 'all') {
      where.type = params.filter;
    }

    const [total, unreadCount, notifications] = await Promise.all([
      Notification.count({ where }),
      Notification.count({ where: { userId: params.userId, isRead: false } }),
      Notification.findAll({
        where,
        order: [['createdAt', 'DESC']],
        limit: params.limit || 50,
        offset: params.offset || 0,
      }),
    ]);

    return { total, unreadCount, notifications };
  }

  /**
   * Mark a single notification as read
   */
  public static async markAsRead(notificationId: number, userId: number): Promise<boolean> {
    const [updated] = await Notification.update(
      { isRead: true, readAt: new Date() },
      { where: { id: notificationId, userId } }
    );
    return updated > 0;
  }

  /**
   * Mark all notifications as read for a user
   */
  public static async markAllAsRead(userId: number): Promise<number> {
    const [updated] = await Notification.update(
      { isRead: true, readAt: new Date() },
      { where: { userId, isRead: false } }
    );
    return updated;
  }

  /**
   * Delete / remove a notification
   */
  public static async deleteNotification(notificationId: number, userId: number): Promise<boolean> {
    const deleted = await Notification.destroy({
      where: { id: notificationId, userId },
    });
    return deleted > 0;
  }

  /**
   * Super Admin Broadcast to all active users
   */
  public static async broadcastSystemNotification(params: {
    title: string;
    message: string;
    targetGroup?: string;
    actionRoute?: string;
  }): Promise<{ dispatchedCount: number; fcmSent: number }> {
    const users = await User.findAll({
      where: { status: 'Active' },
      attributes: ['id', 'agencyId', 'name', 'phone', 'fcmToken'],
    });

    let dispatchedCount = 0;
    const fcmTokens: string[] = [];

    const notifRecords = users.map((u, idx) => {
      if (u.fcmToken) fcmTokens.push(u.fcmToken);
      return {
        notificationCode: `NTF-BRD-${Date.now().toString().slice(-4)}-${idx + 1}`,
        userId: u.id,
        agencyId: u.agencyId,
        title: params.title,
        message: params.message,
        type: 'system' as const,
        actionRoute: params.actionRoute || '/',
        metadata: { targetGroup: params.targetGroup || 'All Users', broadcast: true },
        isRead: false,
        channels: 'in_app,push',
      };
    });

    if (notifRecords.length > 0) {
      await Notification.bulkCreate(notifRecords);
      dispatchedCount = notifRecords.length;
    }

    let fcmSent = 0;
    if (fcmTokens.length > 0) {
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: fcmTokens,
          notification: {
            title: params.title,
            body: params.message,
          },
          data: {
            type: 'system',
            actionRoute: params.actionRoute || '/',
          },
        });
        fcmSent = response.successCount;
        console.log(`[FCM Multicast Broadcast] Sent to ${fcmSent} / ${fcmTokens.length} devices.`);
      } catch (err: any) {
        console.warn('[FCM Broadcast Warning]', err.message || err);
      }
    }

    return { dispatchedCount, fcmSent };
  }
}
