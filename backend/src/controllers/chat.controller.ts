import { Request, Response } from 'express';
import { Op } from 'sequelize';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { Message } from '../models/chat.model';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';

/**
 * Helper to extract userId and userName from request (JWT, middleware, or query/body)
 */
function resolveUserFromRequest(req: Request): { id: string | null; name: string | null } {
  const authReq = req as AuthenticatedRequest;
  if (authReq.user?.id) {
    return {
      id: String(authReq.user.id),
      name: authReq.user.email || null,
    };
  }

  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, env.JWT_SECRET) as any;
      return {
        id: decoded.id ? String(decoded.id) : null,
        name: decoded.name || decoded.email || null,
      };
    } catch (_) {}
  }

  if (req.query.userId) {
    return {
      id: String(req.query.userId),
      name: (req.query.userName as string) || null,
    };
  }

  if (req.body?.senderId) {
    return {
      id: String(req.body.senderId),
      name: req.body.senderName || null,
    };
  }

  return { id: null, name: null };
}

/**
 * Fetch Conversations List for Authenticated User - 100% PostgreSQL
 */
export const getConversations = async (req: Request, res: Response) => {
  try {
    const { id: userId } = resolveUserFromRequest(req);

    if (!userId) {
      return successResponse(res, 'No user identifier provided', []);
    }

    const messages = await Message.findAll({
      where: {
        [Op.or]: [{ senderId: userId }, { receiverId: userId }],
        conversationId: { [Op.ne]: 'null' },
      },
      order: [['createdAt', 'DESC']],
    });

    // Group messages into distinct conversations
    const conversationMap = new Map<string, any>();

    for (const msg of messages) {
      const data = msg.dataValues || msg.get();
      const convId = data.conversationId;
      if (!convId || convId === 'null') continue;

      if (!conversationMap.has(convId)) {
        const partnerName = data.senderId === userId ? data.receiverName : data.senderName;
        const partnerId = data.senderId === userId ? data.receiverId : data.senderId;

        conversationMap.set(convId, {
          conversationId: convId,
          partnerId,
          partnerName,
          lastMessage: data.messageText,
          attachmentType: data.attachmentType,
          lastMessageTime: data.createdAt,
          isUnread: !data.isRead && data.receiverId === userId,
          unreadCount: (!data.isRead && data.receiverId === userId) ? 1 : 0,
        });
      } else if (!data.isRead && data.receiverId === userId) {
        const existing = conversationMap.get(convId);
        existing.unreadCount = (existing.unreadCount || 0) + 1;
        existing.isUnread = true;
      }
    }

    const conversations = Array.from(conversationMap.values());
    return successResponse(res, 'Conversations retrieved successfully from PostgreSQL', conversations);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch conversations', error.message || error);
  }
};

/**
 * Fetch Message History for Conversation - 100% PostgreSQL
 */
export const getMessages = async (req: Request, res: Response) => {
  try {
    const { conversationId } = req.params;

    if (!conversationId || conversationId === 'null') {
      return successResponse(res, 'Messages retrieved from PostgreSQL', []);
    }

    const messages = await Message.findAll({
      where: { conversationId },
      order: [['createdAt', 'ASC']],
    });

    const plainMessages = messages.map((m) => m.dataValues || m.get());
    return successResponse(res, 'Messages retrieved from PostgreSQL', plainMessages);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch messages', error.message || error);
  }
};

/**
 * Send New Chat Message or Attachment - 100% PostgreSQL
 */
export const sendMessage = async (req: Request, res: Response) => {
  try {
    let { conversationId, receiverId, receiverName, messageText, attachmentType, attachmentData } = req.body;
    const resolved = resolveUserFromRequest(req);
    const senderId = resolved.id || '1';
    const senderName = req.body.senderName || resolved.name || 'Broker';

    if (!receiverId || !messageText) {
      return errorResponse(res, 'receiverId and messageText are required', null, 400);
    }

    if (!conversationId || conversationId === 'null') {
      const sorted = [String(senderId), String(receiverId)].sort();
      conversationId = `conv_${sorted[0]}_${sorted[1]}`;
    }

    const message = await Message.create({
      conversationId,
      senderId: String(senderId),
      senderName: String(senderName),
      receiverId: String(receiverId),
      receiverName: receiverName || 'Partner Broker',
      messageText: messageText.trim(),
      attachmentType: attachmentType || 'text',
      attachmentData: attachmentData || null,
      isRead: false,
    });

    const plainMsg = message.dataValues || message.get();
    return successResponse(res, 'Message sent successfully in PostgreSQL!', plainMsg, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to send message', error.message || error);
  }
};
