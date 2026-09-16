import { Request, Response } from 'express';
import { Op } from 'sequelize';
import { AuditLog } from '../models/auditLog.model';
import { successResponse, errorResponse } from '../utils/apiResponse';

export const recordAuditLog = async (
  actorName: string,
  actorRole: string,
  action: string,
  target: string,
  ipAddress: string = '103.22.180.4',
  status: 'Success' | 'Warning' | 'Error' = 'Success',
  details: Record<string, any> = {}
) => {
  try {
    const count = await AuditLog.count();
    const logCode = `LOG-${7001 + count}`;
    await AuditLog.create({
      logCode,
      actorName,
      actorRole,
      action,
      target,
      ipAddress,
      status,
      details,
    });
  } catch (err) {
    console.warn('[Audit Log Record Warning]', err);
  }
};

export const getAuditLogs = async (req: Request, res: Response) => {
  try {
    const { status, search, date } = req.query;

    const whereClause: any = {};
    if (status && status !== 'All') {
      whereClause.status = status;
    }

    if (date && date !== 'All') {
      const dateStr = String(date).trim();
      const startDate = new Date(`${dateStr}T00:00:00.000Z`);
      const endDate = new Date(`${dateStr}T23:59:59.999Z`);
      if (!isNaN(startDate.getTime()) && !isNaN(endDate.getTime())) {
        whereClause.createdAt = { [Op.between]: [startDate, endDate] };
      }
    }

    if (search) {
      const searchStr = String(search).trim();
      whereClause[Op.or] = [
        { logCode: { [Op.iLike]: `%${searchStr}%` } },
        { actorName: { [Op.iLike]: `%${searchStr}%` } },
        { action: { [Op.iLike]: `%${searchStr}%` } },
        { target: { [Op.iLike]: `%${searchStr}%` } },
        { ipAddress: { [Op.iLike]: `%${searchStr}%` } },
      ];
    }

    const logs = await AuditLog.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
      limit: 200,
    });

    return successResponse(res, 'Audit logs retrieved from PostgreSQL', logs);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch audit logs', error.message || error);
  }
};

export const createAuditLogEntry = async (req: Request, res: Response) => {
  try {
    const { actorName, actorRole, action, target, ipAddress, status, details } = req.body;

    if (!actorName || !action || !target) {
      return errorResponse(res, 'actorName, action, and target are required', null, 400);
    }

    const count = await AuditLog.count();
    const logCode = `LOG-${7001 + count}`;

    const log = await AuditLog.create({
      logCode,
      actorName,
      actorRole: actorRole || 'Super Admin',
      action,
      target,
      ipAddress: ipAddress || '103.22.180.4',
      status: status || 'Success',
      details: details || {},
    });

    return successResponse(res, 'Audit log created in PostgreSQL', log, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to create audit log', error.message || error);
  }
};
