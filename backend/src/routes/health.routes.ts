import { Router } from 'express';
import { checkHealth } from '../controllers/health.controller';

const router = Router();

/**
 * @openapi
 * /health:
 *   get:
 *     summary: Health Check Endpoint
 *     description: Returns current operational status of the PropConnect backend service and MySQL database connection.
 *     tags:
 *       - System Health
 *     responses:
 *       200:
 *         description: Backend service is operational.
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/StandardResponse'
 */
router.get('/health', checkHealth);

export default router;
