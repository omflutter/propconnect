import { Router } from 'express';
import {
  getConversations,
  getAdminConversations,
  getMessages,
  sendMessage,
  getChatContacts,
  markConversationAsRead,
} from '../controllers/chat.controller';

const router = Router();

/**
 * @openapi
 * /chat/contacts:
 *   get:
 *     summary: Get All Platform Contacts by Agency for Starting Chats
 *     tags:
 *       - Chat
 */
router.get('/chat/contacts', getChatContacts);

/**
 * @openapi
 * /chat/admin/conversations:
 *   get:
 *     summary: Get All Platform Conversations for Moderation (PRD Sec 11)
 *     tags:
 *       - Chat
 */
router.get('/chat/admin/conversations', getAdminConversations);

/**
 * @openapi
 * /chat/conversations:
 *   get:
 *     summary: Get Active User Conversations
 *     tags:
 *       - Chat
 */
router.get('/chat/conversations', getConversations);

/**
 * @openapi
 * /chat/messages/{conversationId}:
 *   get:
 *     summary: Get Message History for Conversation
 *     tags:
 *       - Chat
 */
router.get('/chat/messages/:conversationId', getMessages);

/**
 * @openapi
 * /chat/send:
 *   post:
 *     summary: Send Message or Attachment
 *     tags:
 *       - Chat
 */
router.post('/chat/send', sendMessage);

/**
 * @openapi
 * /chat/read/{conversationId}:
 *   put:
 *     summary: Mark Conversation Messages as Read
 *     tags:
 *       - Chat
 */
router.put('/chat/read/:conversationId', markConversationAsRead);

export default router;
