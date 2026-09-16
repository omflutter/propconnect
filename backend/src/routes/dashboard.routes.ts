import { Router } from 'express';
import { getDashboardStats } from '../controllers/dashboard.controller';

const router = Router();

/**
 * @openapi
 * /dashboard/stats:
 *   get:
 *     summary: Retrieve Live Command Center Dashboard Metrics
 *     description: Fetch live counts for agencies, brokers, subscriptions, financials, system health, and recent audit activity.
 *     tags:
 *       - Command Center Dashboard
 *     responses:
 *       200:
 *         description: Dashboard stats object.
 */
router.get('/dashboard/stats', getDashboardStats);

export default router;
