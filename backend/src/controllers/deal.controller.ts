import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { Deal } from '../models/deal.model';
import { Property } from '../models/property.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';

/**
 * Mask sensitive contact info per PRD Section 10 Lead Privacy Firewall
 */
const maskPhone = (phone?: string) => {
  if (!phone || phone.length < 5) return 'Protected';
  return `${phone.substring(0, 4)}***${phone.substring(phone.length - 2)}`;
};

const maskEmail = (email?: string) => {
  if (!email || !email.includes('@')) return 'Protected';
  const parts = email.split('@');
  return `${parts[0].substring(0, 2)}***@${parts[1]}`;
};

/**
 * Fetch all Deals with Lead Privacy Firewall & Agency Filtering
 */
export const getDeals = async (req: Request, res: Response) => {
  try {
    const { agencyId, brokerId, status, search } = req.query;

    let callerAgencyId: number | null = null;
    let callerUserId: number | null = null;
    let callerRole: string | null = null;

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        callerAgencyId = decoded.agencyId ? parseInt(String(decoded.agencyId), 10) : null;
        callerUserId = decoded.id ? parseInt(String(decoded.id), 10) : null;
        callerRole = decoded.role;
      } catch (_) {}
    }

    const whereClause: any = {};

    if (agencyId && agencyId !== 'All') {
      const parsedAgency = parseInt(String(agencyId), 10);
      whereClause[Op.or] = [{ agencyAId: parsedAgency }, { agencyBId: parsedAgency }];
    } else if (callerAgencyId && callerRole !== 'super_admin') {
      whereClause[Op.or] = [{ agencyAId: callerAgencyId }, { agencyBId: callerAgencyId }];
    }

    if (brokerId && brokerId !== 'All') {
      const parsedBroker = parseInt(String(brokerId), 10);
      whereClause[Op.or] = [{ brokerAId: parsedBroker }, { brokerBId: parsedBroker }];
    }

    if (status && status !== 'All') {
      whereClause.status = status;
    }

    if (search) {
      const query = String(search).trim();
      whereClause[Op.and] = [
        {
          [Op.or]: [
            { dealCode: { [Op.iLike]: `%${query}%` } },
            { propertyName: { [Op.iLike]: `%${query}%` } },
            { brokerAName: { [Op.iLike]: `%${query}%` } },
            { brokerBName: { [Op.iLike]: `%${query}%` } },
            { agencyAName: { [Op.iLike]: `%${query}%` } },
            { agencyBName: { [Op.iLike]: `%${query}%` } },
          ],
        },
      ];
    }

    const deals = await Deal.findAll({
      where: whereClause,
      order: [['updatedAt', 'DESC']],
    });

    // Apply Lead Privacy Firewall (PRD Section 10)
    // Broker B owns client; Broker A CANNOT access client phone/email!
    const sanitizedDeals = deals.map((d) => {
      const json = d.toJSON();
      const isClientOwner =
        callerRole === 'super_admin' ||
        (callerUserId && callerUserId === json.brokerBId) ||
        (callerAgencyId && callerAgencyId === json.agencyBId);

      if (!isClientOwner) {
        json.clientPhone = maskPhone(json.clientPhone);
        json.clientEmail = maskEmail(json.clientEmail);
      }
      return json;
    });

    return successResponse(res, 'Deals retrieved successfully', sanitizedDeals);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch deals', error.message || error);
  }
};

/**
 * Get Deal By ID with Permissions Matrix & Lead Privacy
 */
export const getDealById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const deal = await Deal.findByPk(id);

    if (!deal) {
      return errorResponse(res, 'Deal not found', null, 404);
    }

    let callerAgencyId: number | null = null;
    let callerUserId: number | null = null;
    let callerRole: string | null = null;

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        callerAgencyId = decoded.agencyId ? parseInt(String(decoded.agencyId), 10) : null;
        callerUserId = decoded.id ? parseInt(String(decoded.id), 10) : null;
        callerRole = decoded.role;
      } catch (_) {}
    }

    const json = deal.toJSON();
    const isClientOwner =
      callerRole === 'super_admin' ||
      (callerUserId && callerUserId === json.brokerBId) ||
      (callerAgencyId && callerAgencyId === json.agencyBId);

    if (!isClientOwner) {
      json.clientPhone = maskPhone(json.clientPhone);
      json.clientEmail = maskEmail(json.clientEmail);
    }

    return successResponse(res, 'Deal details retrieved', json);
  } catch (error: any) {
    return errorResponse(res, 'Failed to retrieve deal', error.message || error);
  }
};

/**
 * Create a New Deal
 */
export const createDeal = async (req: Request, res: Response) => {
  try {
    const {
      propertyId,
      propertyName,
      agencyAId,
      agencyAName,
      brokerAId,
      brokerAName,
      agencyBId,
      agencyBName,
      brokerBId,
      brokerBName,
      clientName,
      clientPhone,
      clientEmail,
      clientRequirement,
      expectedBudget,
      dealValue,
      remarks,
    } = req.body;

    const totalDeals = await Deal.count();
    const dealCode = `DL-${500 + totalDeals + 1}`;

    const now = new Date().toISOString();
    const initialAudit = [
      {
        status: 'Lead Assigned',
        timestamp: now,
        updatedBy: brokerBName || 'System',
        remarks: 'Deal pipeline initiated',
      },
    ];

    const deal = await Deal.create({
      dealCode,
      propertyId: propertyId || 1,
      propertyName: propertyName || 'Commercial Space',
      agencyAId: agencyAId || 1,
      agencyAName: agencyAName || 'Sunrise Properties',
      brokerAId: brokerAId || 1,
      brokerAName: brokerAName || 'Om Shivam',
      agencyBId: agencyBId || 1,
      agencyBName: agencyBName || 'Partner Agency',
      brokerBId: brokerBId || 2,
      brokerBName: brokerBName || 'Broker Agent',
      clientName: clientName || 'Client Lead',
      clientPhone: clientPhone || '',
      clientEmail: clientEmail || '',
      clientRequirement: clientRequirement || '',
      expectedBudget: expectedBudget || dealValue || '₹1.0 Cr',
      status: 'Lead Assigned',
      dealValue: dealValue || '₹1.0 Cr',
      remarks: remarks || '',
      auditHistory: initialAudit,
    });

    return successResponse(res, `Deal ${deal.dealCode} created successfully`, deal, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to create deal', error.message || error);
  }
};

/**
 * Update Deal Stage (12 Stages) with Automatic Property Status Synchronization
 */
export const updateDealStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { newStage, updatedBy, remarks } = req.body;

    if (!newStage) {
      return errorResponse(res, 'New stage is required', null, 400);
    }

    const deal = await Deal.findByPk(id);
    if (!deal) {
      return errorResponse(res, 'Deal not found', null, 404);
    }

    const currentAudit = Array.isArray(deal.auditHistory) ? [...deal.auditHistory] : [];
    currentAudit.push({
      status: newStage,
      timestamp: new Date().toISOString(),
      updatedBy: updatedBy || 'Broker',
      remarks: remarks || `Stage progressed to ${newStage}`,
    });

    deal.status = newStage;
    deal.auditHistory = currentAudit;
    await deal.save();

    // Auto-sync linked Property status based on Deal Lifecycle (PRD Section 4 & 9)
    if (deal.propertyId) {
      const prop = await Property.findByPk(deal.propertyId);
      if (prop) {
        if (newStage === 'Negotiation Started' || newStage === 'Offer Submitted') {
          prop.status = 'Under Negotiation';
          await prop.save();
        } else if (newStage === 'Token Generated' || newStage === 'Agreement Signed') {
          prop.status = 'Token Done';
          await prop.save();
        } else if (newStage === 'Deal Closed' || newStage === 'Registry Completed') {
          prop.status = prop.purpose === 'Rent' || prop.type === 'Rent' ? 'Rented' : 'Sold';
          await prop.save();
        } else if (newStage === 'Deal Lost') {
          prop.status = 'Available';
          await prop.save();
        }
      }
    }

    return successResponse(res, `Deal stage updated to "${newStage}"`, deal);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update deal status', error.message || error);
  }
};
