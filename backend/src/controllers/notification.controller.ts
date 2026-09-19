import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Notification } from '../models/notification.model';
import { NotificationService } from '../services/notification.service';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';

const getUserIdFromAuth = (req: Request): number => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
      if (decoded.id) return parseInt(String(decoded.id), 10);
    } catch (_) {}
  }
  return 1; // Default to Om Shivam (demo session)
};

/**
 * Get In-App Notifications for authenticated user
 */
export const getNotifications = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromAuth(req);
    const { filter, limit, offset } = req.query;

    const result = await NotificationService.getUserNotifications({
      userId,
      filter: filter ? String(filter) : undefined,
      limit: limit ? parseInt(String(limit), 10) : 50,
      offset: offset ? parseInt(String(offset), 10) : 0,
    });

    return successResponse(res, 'Notifications retrieved', result);
  } catch (error: any) {
    return errorResponse(res, 'Failed to retrieve notifications', error.message || error);
  }
};

/**
 * Mark a single notification as read
 */
export const markNotificationAsRead = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromAuth(req);
    const { id } = req.params;

    const success = await NotificationService.markAsRead(parseInt(id, 10), userId);
    if (!success) {
      return errorResponse(res, 'Notification not found or already read', null, 404);
    }

    return successResponse(res, 'Notification marked as read', { id, isRead: true });
  } catch (error: any) {
    return errorResponse(res, 'Failed to update notification', error.message || error);
  }
};

/**
 * Mark all notifications as read for the user
 */
export const markAllNotificationsAsRead = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromAuth(req);
    const count = await NotificationService.markAllAsRead(userId);

    return successResponse(res, `Marked ${count} notifications as read`, { count });
  } catch (error: any) {
    return errorResponse(res, 'Failed to mark notifications as read', error.message || error);
  }
};

/**
 * Delete a notification
 */
export const deleteNotification = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromAuth(req);
    const { id } = req.params;

    const success = await NotificationService.deleteNotification(parseInt(id, 10), userId);
    if (!success) {
      return errorResponse(res, 'Notification not found', null, 404);
    }

    return successResponse(res, 'Notification deleted successfully');
  } catch (error: any) {
    return errorResponse(res, 'Failed to delete notification', error.message || error);
  }
};

/**
 * Register or update client device FCM Token
 */
export const registerFcmToken = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromAuth(req);
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return errorResponse(res, 'FCM token is required', null, 400);
    }

    await NotificationService.registerFcmToken(userId, fcmToken);
    return successResponse(res, 'FCM token registered successfully', { userId });
  } catch (error: any) {
    return errorResponse(res, 'Failed to register FCM token', error.message || error);
  }
};

/**
 * Super Admin Broadcast Notification
 */
export const broadcastNotification = async (req: Request, res: Response) => {
  try {
    const { title, message, targetGroup, actionRoute } = req.body;

    if (!title || !message) {
      return errorResponse(res, 'Title and Message are required', null, 400);
    }

    const result = await NotificationService.broadcastSystemNotification({
      title,
      message,
      targetGroup,
      actionRoute,
    });

    return successResponse(
      res,
      `Broadcast sent to ${result.dispatchedCount} in-app feeds (${result.fcmSent} push notifications delivered)`,
      result,
      201
    );
  } catch (error: any) {
    return errorResponse(res, 'Failed to broadcast notification', error.message || error);
  }
};

/**
 * Super Admin Get Broadcast History (PRD Sec 17)
 */
export const getAdminBroadcasts = async (_req: Request, res: Response) => {
  try {
    const broadcasts = await Notification.findAll({
      where: { type: 'system' },
      order: [['createdAt', 'DESC']],
      limit: 50,
    });

    // Group by notificationCode/title/createdAt to avoid repeating per-user rows
    const uniqueMap = new Map<string, any>();
    for (const b of broadcasts) {
      const data = b.dataValues || b.get();
      const key = `${data.title}_${new Date(data.createdAt).toISOString().substring(0, 16)}`;
      if (!uniqueMap.has(key)) {
        uniqueMap.set(key, {
          id: data.notificationCode || `NOTIF-${data.id}`,
          title: data.title,
          targetGroup: 'All Registered Agencies & Brokers',
          channels: (data.channels || 'in_app,push').replace(',', ' + ').toUpperCase(),
          sentCount: 'Broadcast Dispatched',
          date: new Date(data.createdAt).toISOString().replace('T', ' ').substring(0, 16),
          status: 'Sent',
        });
      }
    }

    return successResponse(res, 'System broadcasts retrieved', Array.from(uniqueMap.values()));
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch broadcasts', error.message || error);
  }
};
