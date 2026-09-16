import { Router } from 'express';
import { getAuditLogs, createAuditLogEntry } from '../controllers/auditLog.controller';

const router = Router();

/**
 * @openapi
 * /audit-logs:
 *   get:
 *     summary: Retrieve Platform Live Audit Logs
 *     description: Fetch tamper-proof audit trail logs from MySQL with filtering (status, date, search).
 *     tags:
 *       - Audit Logs
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [All, Success, Warning, Error]
 *       - in: query
 *         name: date
 *         description: Specific date string in YYYY-MM-DD format
 *         schema:
 *           type: string
 *           example: 2026-08-11
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of audit logs.
 * 
 *   post:
 *     summary: Record Audit Log Entry
 *     description: Log a system event or action into MySQL audit logs.
 *     tags:
 *       - Audit Logs
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - actorName
 *               - action
 *               - target
 *             properties:
 *               actorName:
 *                 type: string
 *                 example: Om Shivam
 *               actorRole:
 *                 type: string
 *                 example: Super Admin
 *               action:
 *                 type: string
 *                 example: Platform Config Updated
 *               target:
 *                 type: string
 *                 example: Platform Fees Policy
 *               ipAddress:
 *                 type: string
 *                 example: 103.22.180.4
 *               status:
 *                 type: string
 *                 enum: [Success, Warning, Error]
 *                 example: Success
 *               details:
 *                 type: object
 *                 example: {"feePercent":2.5,"updatedBy":"Om Shivam"}
 *     responses:
 *       201:
 *         description: Audit log recorded.
 */
router.get('/audit-logs', getAuditLogs);
router.post('/audit-logs', createAuditLogEntry);

export default router;
