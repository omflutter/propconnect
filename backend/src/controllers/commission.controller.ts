import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { Commission } from '../models/commission.model';
import { Settlement } from '../models/settlement.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';

/**
 * Fetch Commissions with Agency / Broker filtering & Super Admin support
 */
export const getCommissions = async (req: Request, res: Response) => {
  try {
    const { agencyId, brokerId, status, search } = req.query;

    let callerAgencyId: number | null = null;
    let callerRole: string | null = null;

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (decoded.agencyId) callerAgencyId = parseInt(String(decoded.agencyId), 10);
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
            { commissionCode: { [Op.iLike]: `%${query}%` } },
            { propertyName: { [Op.iLike]: `%${query}%` } },
            { brokerAName: { [Op.iLike]: `%${query}%` } },
            { brokerBName: { [Op.iLike]: `%${query}%` } },
            { agencyAName: { [Op.iLike]: `%${query}%` } },
            { agencyBName: { [Op.iLike]: `%${query}%` } },
          ],
        },
      ];
    }

    const commissions = await Commission.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
    });

    return successResponse(res, 'Commissions fetched successfully', commissions);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch commissions', error.message || error);
  }
};

/**
 * Create or Configure Commission Split for a Deal (PRD Section 12)
 */
export const createCommission = async (req: Request, res: Response) => {
  try {
    const {
      dealId,
      propertyId,
      propertyName,
      dealValue,
      commissionType,
      commissionRate,
      totalCommission,
      brokerASharePct,
      brokerBSharePct,
      brokerAAmount,
      brokerBAmount,
      brokerAId,
      brokerAName,
      brokerBId,
      brokerBName,
      agencyAId,
      agencyAName,
      agencyBId,
      agencyBName,
    } = req.body;

    const totalComms = await Commission.count();
    const commissionCode = `COMM-${800 + totalComms + 1}`;

    const comm = await Commission.create({
      commissionCode,
      dealId: dealId || 1,
      propertyId: propertyId || 1,
      propertyName: propertyName || 'Commercial Space',
      dealValue: dealValue || '₹1,00,00,000',
      commissionType: commissionType || 'Percentage',
      commissionRate: commissionRate || 2.0,
      totalCommission: totalCommission || '₹2,00,000',
      brokerASharePct: brokerASharePct !== undefined ? brokerASharePct : 50.0,
      brokerBSharePct: brokerBSharePct !== undefined ? brokerBSharePct : 50.0,
      brokerAAmount: brokerAAmount || '₹1,00,000',
      brokerBAmount: brokerBAmount || '₹1,00,000',
      brokerAId: brokerAId || 1,
      brokerAName: brokerAName || 'Om Shivam',
      brokerBId: brokerBId || 2,
      brokerBName: brokerBName || 'Rahul Singh',
      agencyAId: agencyAId || 1,
      agencyAName: agencyAName || 'Sunrise Properties',
      agencyBId: agencyBId || 1,
      agencyBName: agencyBName || 'Partner Agency',
      status: 'Pending',
    });

    return successResponse(res, `Commission ${comm.commissionCode} created successfully`, comm, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to create commission record', error.message || error);
  }
};

/**
 * Update Commission Status or Split terms
 */
export const updateCommission = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status, brokerASharePct, brokerBSharePct, brokerAAmount, brokerBAmount } = req.body;

    const comm = await Commission.findByPk(id);
    if (!comm) {
      return errorResponse(res, 'Commission record not found', null, 404);
    }

    if (status) comm.status = status;
    if (brokerASharePct !== undefined) comm.brokerASharePct = brokerASharePct;
    if (brokerBSharePct !== undefined) comm.brokerBSharePct = brokerBSharePct;
    if (brokerAAmount) comm.brokerAAmount = brokerAAmount;
    if (brokerBAmount) comm.brokerBAmount = brokerBAmount;

    await comm.save();
    return successResponse(res, `Commission ${comm.commissionCode} updated`, comm);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update commission', error.message || error);
  }
};

/**
 * Fetch Payment Settlements (PRD Section 13)
 */
export const getSettlements = async (req: Request, res: Response) => {
  try {
    const { agencyId, search, status } = req.query;

    const whereClause: any = {};
    if (agencyId && agencyId !== 'All') {
      whereClause.agencyId = parseInt(String(agencyId), 10);
    }
    if (status && status !== 'All') {
      whereClause.status = status;
    }
    if (search) {
      const query = String(search).trim();
      whereClause[Op.or] = [
        { settlementCode: { [Op.iLike]: `%${query}%` } },
        { referenceNumber: { [Op.iLike]: `%${query}%` } },
        { brokerName: { [Op.iLike]: `%${query}%` } },
        { agencyName: { [Op.iLike]: `%${query}%` } },
      ];
    }

    const settlements = await Settlement.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
    });

    return successResponse(res, 'Settlements retrieved successfully', settlements);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch settlements', error.message || error);
  }
};

/**
 * Record a Payment Settlement (PRD Section 13)
 */
export const createSettlement = async (req: Request, res: Response) => {
  try {
    const {
      commissionId,
      dealId,
      propertyName,
      agencyId,
      agencyName,
      brokerId,
      brokerName,
      dueDate,
      amountReceived,
      amountPending,
      paymentMethod,
      referenceNumber,
      settlementDate,
      remarks,
    } = req.body;

    const totalSettlements = await Settlement.count();
    const settlementCode = `SET-${900 + totalSettlements + 1}`;

    const settlement = await Settlement.create({
      settlementCode,
      commissionId: commissionId || 1,
      dealId: dealId || 1,
      propertyName: propertyName || '',
      agencyId: agencyId || 1,
      agencyName: agencyName || 'Sunrise Properties',
      brokerId: brokerId || 1,
      brokerName: brokerName || 'Om Shivam',
      dueDate: dueDate || new Date().toISOString().substring(0, 10),
      amountReceived: amountReceived || '₹0',
      amountPending: amountPending || '₹0',
      paymentMethod: paymentMethod || 'NEFT / Bank Transfer',
      referenceNumber: referenceNumber || `TXN-${Date.now().toString().substring(5)}`,
      settlementDate: settlementDate || new Date().toISOString().substring(0, 10),
      status: (amountPending === '₹0' || amountPending === '0') ? 'Settled' : 'Partially Settled',
      remarks: remarks || '',
    });

    // Update Commission record status if linked
    if (commissionId) {
      const comm = await Commission.findByPk(commissionId);
      if (comm) {
        comm.status = settlement.status === 'Settled' ? 'Paid' : 'Partially Paid';
        await comm.save();
      }
    }

    return successResponse(res, `Settlement ${settlement.settlementCode} recorded successfully`, settlement, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to record settlement', error.message || error);
  }
};
