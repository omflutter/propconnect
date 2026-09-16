import { Request } from 'express';
import jwt from 'jsonwebtoken';
import { AuditLog } from '../models/auditLog.model';
import { env } from '../config/env';

export interface LogActionParams {
  action: string;
  target: string;
  actorName?: string;
  actorRole?: string;
  ipAddress?: string;
  status?: 'Success' | 'Warning' | 'Error';
  details?: Record<string, any>;
  req?: Request;
}

export class AuditService {
  /**
   * Universal Audit Log Recorder (PRD Section 18)
   * Tracks all 11 required system actions:
   * 1. Property Created
   * 2. Property Updated
   * 3. Property Deleted
   * 4. Collaboration Requested
   * 5. Collaboration Approved
   * 6. Deal Status Changed
   * 7. Commission Updated
   * 8. Subscription Purchased
   * 9. Payment Completed
   * 10. User Login
   * 11. User Logout
   */
  static async logAction(params: LogActionParams): Promise<void> {
    try {
      let actorName = params.actorName;
      let actorRole = params.actorRole;
      let ipAddress = params.ipAddress;

      // Automatically inspect request context if provided
      if (params.req) {
        const req = params.req;

        // Extract IP address from request headers or socket
        if (!ipAddress) {
          const forwarded = req.headers['x-forwarded-for'];
          if (typeof forwarded === 'string') {
            ipAddress = forwarded.split(',')[0].trim();
          } else if (req.socket?.remoteAddress) {
            ipAddress = req.socket.remoteAddress;
          } else {
            ipAddress = req.ip || '127.0.0.1';
          }
        }

        // Extract actor and role from JWT token if available
        if (!actorName || !actorRole) {
          const authHeader = req.headers.authorization;
          if (authHeader && authHeader.startsWith('Bearer ')) {
            try {
              const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
              if (decoded) {
                if (!actorName) actorName = decoded.name || decoded.email || 'Authenticated User';
                if (!actorRole) actorRole = decoded.role || 'Broker';
              }
            } catch (_) {}
          }
        }

        // If still missing, check req.body or req.user
        if (!actorName && (req as any).user) {
          actorName = (req as any).user.name || (req as any).user.email;
          actorRole = (req as any).user.role;
        }
      }

      const finalActorName = actorName || 'System';
      const finalActorRole = actorRole || 'System';
      const finalIp = ipAddress || '127.0.0.1';
      const finalStatus = params.status || 'Success';
      const finalDetails = params.details || {};

      const count = await AuditLog.count();
      const logCode = `LOG-${7001 + count}`;

      await AuditLog.create({
        logCode,
        actorName: finalActorName,
        actorRole: finalActorRole,
        action: params.action,
        target: params.target,
        ipAddress: finalIp,
        status: finalStatus,
        details: finalDetails,
      });

      console.log(`[AuditLog] ${logCode} recorded: ${params.action} on "${params.target}" by ${finalActorName} (${finalActorRole})`);
    } catch (error) {
      console.warn('[AuditService] Failed to record audit log:', error);
    }
  }
}
