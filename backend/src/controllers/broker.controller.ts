import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { User } from '../models/user.model';
import { Agency } from '../models/agency.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';

/**
 * Onboard / Register a new Broker under an Agency - 100% PostgreSQL
 */
export const createBroker = async (req: Request, res: Response) => {
  try {
    const { name, email, phone, role, agencyId, password } = req.body;

    if (!name || !email) {
      return errorResponse(res, 'Broker Name and Email are required', null, 400);
    }

    const cleanEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({ where: { email: cleanEmail } });
    if (existingUser) {
      return errorResponse(res, 'An account with this email address already exists', null, 400);
    }

    // Resolve agencyId: from body or from JWT token header
    let targetAgencyId = agencyId ? parseInt(String(agencyId), 10) : null;
    const authHeader = req.headers.authorization;
    if ((!targetAgencyId || isNaN(targetAgencyId)) && authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (decoded.agencyId) targetAgencyId = parseInt(String(decoded.agencyId), 10);
      } catch (_) {}
    }
    if (!targetAgencyId || isNaN(targetAgencyId)) {
      targetAgencyId = 1;
    }

    const salt = await bcrypt.genSalt(10);
    const defaultPassword = (password && String(password).trim()) ? String(password).trim() : 'broker123';
    const hashedPassword = await bcrypt.hash(defaultPassword, salt);

    const broker = await User.create({
      name: name.trim(),
      email: cleanEmail,
      password: hashedPassword,
      phone: phone ? String(phone).trim() : '',
      role: role === 'agency_admin' ? 'agency_admin' : 'broker',
      adminRoleTitle: role === 'agency_admin' ? 'Agency Tenant Admin' : 'Registered Broker',
      agencyId: targetAgencyId,
      status: 'Active',
    });

    const brokerResponse = {
      id: broker.id,
      name: broker.name,
      email: broker.email,
      phone: broker.phone,
      role: broker.role,
      agencyId: broker.agencyId,
      status: broker.status,
    };

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
    const { agencyId, search } = req.query;

    const whereClause: any = {
      role: { [Op.in]: ['broker', 'agency_admin'] },
    };

    let targetAgencyId: number | null = null;
    if (agencyId && agencyId !== 'All') {
      targetAgencyId = parseInt(String(agencyId), 10);
    } else {
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

    return successResponse(res, 'Brokers retrieved successfully from PostgreSQL', brokers);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch brokers', error.message || error);
  }
};

/**
 * Update Broker Details - 100% PostgreSQL
 */
export const updateBroker = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, email, phone, role } = req.body;

    const broker = await User.findByPk(id);
    if (!broker) {
      return errorResponse(res, 'Broker not found', null, 404);
    }

    if (name) broker.name = name.trim();
    if (email) broker.email = email.trim().toLowerCase();
    if (phone !== undefined) broker.phone = phone.trim();
    if (role) {
      broker.role = role === 'agency_admin' ? 'agency_admin' : 'broker';
      broker.adminRoleTitle = role === 'agency_admin' ? 'Agency Tenant Admin' : 'Registered Broker';
    }

    await broker.save();

    return successResponse(res, `Broker "${broker.name}" updated successfully in PostgreSQL`, broker);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update broker details', error.message || error);
  }
};

/**
 * Update broker status (Active / Suspended) - 100% PostgreSQL
 */
export const updateBrokerStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['Active', 'Suspended'].includes(status)) {
      return errorResponse(res, 'Valid status is required (Active, Suspended)', null, 400);
    }

    const broker = await User.findByPk(id);
    if (!broker) {
      return errorResponse(res, 'Broker not found', null, 404);
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
    const { id } = req.params;

    const broker = await User.findByPk(id);
    if (!broker) {
      return errorResponse(res, 'Broker not found', null, 404);
    }

    await broker.destroy();

    return successResponse(res, `Broker "${broker.name}" has been deleted from PostgreSQL.`);
  } catch (error: any) {
    return errorResponse(res, 'Failed to delete broker', error.message || error);
  }
};
