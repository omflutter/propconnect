import { Router } from 'express';
import { getConversations, getMessages, sendMessage } from '../controllers/chat.controller';

const router = Router();

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

export default router;
