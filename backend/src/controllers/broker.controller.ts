import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { User } from '../models/user.model';
import { Agency } from '../models/agency.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { Property } from '../models/property.model';
import { WhatsAppService } from '../services/whatsapp.service';

/**
 * Helper to extract authenticated user's role and agencyId from JWT
 */
function extractCallerAuth(req: Request): { role: string | null; agencyId: number | null; id: number | null } {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
      return {
        role: decoded.role || null,
        agencyId: decoded.agencyId ? parseInt(String(decoded.agencyId), 10) : null,
        id: decoded.id ? parseInt(String(decoded.id), 10) : null,
      };
    } catch (_) {}
  }
  return { role: null, agencyId: null, id: null };
}

/**
 * Onboard / Register a new Broker under an Agency - 100% PostgreSQL
 */
export const createBroker = async (req: Request, res: Response) => {
  try {
    const caller = extractCallerAuth(req);
    if (caller.role === 'broker') {
      return errorResponse(res, 'Access denied. Brokers cannot onboard brokers or administrators.', null, 403);
    }

    const { name, email, phone, role, agencyId, password, assignedPropertyIds } = req.body;

    if (caller.role === 'agency_admin' && role === 'super_admin') {
      return errorResponse(res, 'Access denied. Agency admins cannot create super admin accounts.', null, 403);
    }

    if (!name || !email) {
      return errorResponse(res, 'Broker Name and Email are required', null, 400);
    }

    const cleanEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({ where: { email: cleanEmail } });
    if (existingUser) {
      return errorResponse(res, 'An account with this email address already exists', null, 400);
    }

    // Resolve agencyId: agency_admin is strictly bound to their own agency
    let targetAgencyId = (caller.role === 'agency_admin' && caller.agencyId)
      ? caller.agencyId
      : (agencyId ? parseInt(String(agencyId), 10) : caller.agencyId);
    if (!targetAgencyId || isNaN(targetAgencyId)) {
      targetAgencyId = 1;
    }

    const salt = await bcrypt.genSalt(10);
    const defaultPassword = (password && String(password).trim()) ? String(password).trim() : 'broker123';
    const hashedPassword = await bcrypt.hash(defaultPassword, salt);

    const cleanAssignedIds = Array.isArray(assignedPropertyIds)
      ? assignedPropertyIds.map((id: any) => parseInt(String(id), 10)).filter((id: number) => !isNaN(id))
      : [];

    const broker = await User.create({
      name: name.trim(),
      email: cleanEmail,
      password: hashedPassword,
      phone: phone ? String(phone).trim() : '',
      role: role === 'agency_admin' ? 'agency_admin' : 'broker',
      adminRoleTitle: role === 'agency_admin' ? 'Agency Tenant Admin' : 'Registered Broker',
      agencyId: targetAgencyId,
      status: 'Active',
      permissions: {
        assignedPropertyIds: cleanAssignedIds,
      } as any,
    });

    if (cleanAssignedIds.length > 0) {
      await Property.update(
        { brokerName: broker.name },
        { where: { id: { [Op.in]: cleanAssignedIds } } }
      ).catch((err) => console.warn('[Property Broker Link Warning]', err));
    }

    const brokerResponse = {
      id: broker.id,
      name: broker.name,
      email: broker.email,
      phone: broker.phone,
      role: broker.role,
      agencyId: broker.agencyId,
      status: broker.status,
      assignedPropertyIds: cleanAssignedIds,
      permissions: broker.permissions,
    };

    // PRD Sec 16 & 17: Send Welcome WhatsApp message to newly onboarded broker
    const targetPhone = broker.phone || '+91 98201 00000';
    WhatsAppService.sendNotification({
      recipientPhone: targetPhone,
      event: 'Broker Onboarded Welcome',
      templateName: 'wa_broker_welcome_v1',
      traits: {
        brokerName: broker.name,
        email: broker.email,
        temporaryPassword: defaultPassword,
        role: broker.role,
        portalUrl: 'https://propconnect-b89bd.web.app',
      },
      bodyValues: [
        broker.name,
        broker.email,
        defaultPassword,
        'https://propconnect-b89bd.web.app',
      ],
    }).catch((err) => console.warn('[WhatsApp Broker Welcome Error]', err));

    return successResponse(
      res,
      `Broker "${name}" onboarded successfully in PostgreSQL! Default password: ${defaultPassword}`,
      brokerResponse,
      201
    );
  } catch (error: any) {
    return errorResponse(res, 'Failed to onboard broker', error.message || error);
  }
};

/**
 * Get all brokers with agency filtering & search - 100% PostgreSQL
 */
export const getBrokers = async (req: Request, res: Response) => {
  try {
    const { agencyId, search, allAgencies } = req.query;

    const whereClause: any = {
      role: { [Op.in]: ['broker', 'agency_admin'] },
    };

    let targetAgencyId: number | null = null;
    if (agencyId && agencyId !== 'All') {
      targetAgencyId = parseInt(String(agencyId), 10);
    } else if (allAgencies !== 'true') {
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        try {
          const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
          if (decoded.agencyId && decoded.role !== 'super_admin') {
            targetAgencyId = parseInt(String(decoded.agencyId), 10);
          }
        } catch (_) {}
      }
    }

    if (targetAgencyId && !isNaN(targetAgencyId)) {
      whereClause.agencyId = targetAgencyId;
    }

    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const brokers = await User.findAll({
      where: whereClause,
      attributes: { exclude: ['password'] },
      include: [{ model: Agency, as: 'agency', attributes: ['id', 'name', 'agencyCode', 'location'] }],
      order: [['createdAt', 'DESC']],
    });

    const serializedBrokers = brokers.map((b) => {
      const data = b.toJSON() as any;
      data.assignedPropertyIds = data.permissions?.assignedPropertyIds || [];
      return data;
    });

    return successResponse(res, 'Brokers retrieved successfully from PostgreSQL', serializedBrokers);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch brokers', error.message || error);
  }
};

/**
 * Update Broker Details - 100% PostgreSQL
 */
export const updateBroker = async (req: Request, res: Response) => {
  try {
    const caller = extractCallerAuth(req);
    if (caller.role === 'broker') {
      return errorResponse(res, 'Access denied. Brokers cannot modify broker accounts.', null, 403);
    }

    const { id } = req.params;
    const { name, email, phone, role, assignedPropertyIds } = req.body;

    const broker = await User.findByPk(id);
    if (!broker) {
      return errorResponse(res, 'Broker not found', null, 404);
    }

    if (caller.role === 'agency_admin' && caller.agencyId && broker.agencyId !== caller.agencyId) {
      return errorResponse(res, 'Access denied. Cannot update brokers from other agencies.', null, 403);
    }

    if (caller.role === 'agency_admin' && role === 'super_admin') {
      return errorResponse(res, 'Access denied. Agency admins cannot elevate users to super admin.', null, 403);
    }

    if (name) broker.name = name.trim();
    if (email) broker.email = email.trim().toLowerCase();
    if (phone !== undefined) broker.phone = phone.trim();
    if (role) {
      broker.role = role === 'agency_admin' ? 'agency_admin' : 'broker';
      broker.adminRoleTitle = role === 'agency_admin' ? 'Agency Tenant Admin' : 'Registered Broker';
    }

    if (assignedPropertyIds !== undefined && Array.isArray(assignedPropertyIds)) {
      const cleanAssignedIds = assignedPropertyIds
        .map((pid: any) => parseInt(String(pid), 10))
        .filter((pid: number) => !isNaN(pid));
      const currentPermissions = (broker.permissions as any) || {};
      broker.permissions = {
        ...currentPermissions,
        assignedPropertyIds: cleanAssignedIds,
      };

      if (cleanAssignedIds.length > 0) {
        await Property.update(
          { brokerName: broker.name },
          { where: { id: { [Op.in]: cleanAssignedIds } } }
        ).catch((err) => console.warn('[Property Broker Link Warning]', err));
      }
    }

    await broker.save();

    const responseData = broker.toJSON() as any;
    responseData.assignedPropertyIds = responseData.permissions?.assignedPropertyIds || [];

    return successResponse(res, `Broker "${broker.name}" updated successfully in PostgreSQL`, responseData);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update broker details', error.message || error);
  }
};

/**
 * Update broker status (Active / Suspended) - 100% PostgreSQL
 */
export const updateBrokerStatus = async (req: Request, res: Response) => {
  try {
    const caller = extractCallerAuth(req);
    if (caller.role === 'broker') {
      return errorResponse(res, 'Access denied. Brokers cannot change broker account status.', null, 403);
    }

    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['Active', 'Suspended'].includes(status)) {
      return errorResponse(res, 'Valid status is required (Active, Suspended)', null, 400);
    }

    const broker = await User.findByPk(id);
    if (!broker) {
      return errorResponse(res, 'Broker not found', null, 404);
    }

    if (caller.role === 'agency_admin' && caller.agencyId && broker.agencyId !== caller.agencyId) {
      return errorResponse(res, 'Access denied. Cannot change status of brokers from other agencies.', null, 403);
    }

    broker.status = status;
    await broker.save();

    return successResponse(res, `Broker account status updated to ${status} in PostgreSQL`, broker);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update broker status', error.message || error);
  }
};

/**
 * Delete Broker Account - 100% PostgreSQL
 */
export const deleteBroker = async (req: Request, res: Response) => {
  try {
    const caller = extractCallerAuth(req);
    if (caller.role === 'broker') {
      return errorResponse(res, 'Access denied. Brokers cannot delete broker accounts.', null, 403);
    }

    const { id } = req.params;

    const broker = await User.findByPk(id);
    if (!broker) {
      return errorResponse(res, 'Broker not found', null, 404);
    }

    if (caller.role === 'agency_admin' && caller.agencyId && broker.agencyId !== caller.agencyId) {
      return errorResponse(res, 'Access denied. Cannot delete brokers from other agencies.', null, 403);
    }

    await broker.destroy();

    return successResponse(res, `Broker "${broker.name}" has been deleted from PostgreSQL.`);
  } catch (error: any) {
    return errorResponse(res, 'Failed to delete broker', error.message || error);
  }
};
