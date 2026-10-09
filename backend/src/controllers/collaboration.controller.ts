import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { CollaborationRequest } from '../models/collaboration.model';
import { Deal } from '../models/deal.model';
import { Commission } from '../models/commission.model';
import { Property } from '../models/property.model';
import { User } from '../models/user.model';
import { Agency } from '../models/agency.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { WhatsAppService } from '../services/whatsapp.service';
import { NotificationService } from '../services/notification.service';
import { AuditService } from '../services/audit.service';

/**
 * Submit a Collaboration Request (Broker B requests collaboration on Broker A's Property)
 */
export const createCollaboration = async (req: Request, res: Response) => {
  try {
    const {
      propertyId,
      propertyName,
      propertyLocation,
      propertyPrice,
      targetAgencyId,
      targetAgencyName,
      targetBrokerId,
      targetBrokerName,
      clientRequirement,
      expectedBudget,
      remarks,
    } = req.body;

    if (!propertyId || !clientRequirement) {
      return errorResponse(res, 'Property ID and Client Requirement are required', null, 400);
    }

    let callerAgencyId = req.body.requestingAgencyId ? parseInt(String(req.body.requestingAgencyId), 10) : 1;
    let callerAgencyName = req.body.requestingAgencyName || 'Partner Realty';
    let callerUserId = req.body.requestingBrokerId ? parseInt(String(req.body.requestingBrokerId), 10) : 2;
    let callerUserName = req.body.requestingBrokerName || 'Broker Agent';
    let callerRole = '';

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (decoded.agencyId) callerAgencyId = parseInt(String(decoded.agencyId), 10);
        callerUserId = parseInt(String(decoded.id), 10);
        if (decoded.name) callerUserName = decoded.name;
        if (decoded.role) callerRole = decoded.role;
        if (decoded.agency?.name) callerAgencyName = decoded.agency.name;
        else if (decoded.agencyName) callerAgencyName = decoded.agencyName;
      } catch (_) {}
    }

    // If an attached/assigned broker is explicitly provided (e.g. by Agency Admin), use that broker
    if (req.body.requestingBrokerId) {
      const explicitBrokerId = parseInt(String(req.body.requestingBrokerId), 10);
      if (!isNaN(explicitBrokerId) && explicitBrokerId > 0) {
        callerUserId = explicitBrokerId;
        if (req.body.requestingBrokerName) {
          callerUserName = req.body.requestingBrokerName;
        }
      }
    }

    // Lookup real property details from PostgreSQL
    const propRecord = await Property.findByPk(propertyId).catch(() => null);
    let resolvedTargetAgencyId = targetAgencyId ? parseInt(String(targetAgencyId), 10) : (propRecord?.agencyId || 1);
    let resolvedTargetAgencyName = targetAgencyName || propRecord?.agencyName || '';
    let resolvedTargetBrokerId = targetBrokerId ? parseInt(String(targetBrokerId), 10) : (propRecord?.brokerId || 0);
    let resolvedTargetBrokerName = targetBrokerName || propRecord?.brokerName || '';
    const resolvedPropertyName = propertyName || propRecord?.title || 'Featured Property';
    const resolvedPropertyLocation = propertyLocation || propRecord?.location || 'Mumbai';
    const resolvedPropertyPrice = propertyPrice || propRecord?.price || 'Price on Request';

    // If targetBrokerId is 0 or 1, and property has a brokerId, use it
    if ((!resolvedTargetBrokerId || resolvedTargetBrokerId === 1) && propRecord?.brokerId) {
      resolvedTargetBrokerId = propRecord.brokerId;
    }

    // If targetBrokerId is still 0 or 1, but we have a valid targetAgencyId > 1, find the agency's broker/admin
    if ((!resolvedTargetBrokerId || resolvedTargetBrokerId === 1) && resolvedTargetAgencyId > 1) {
      const agencyUser = await User.findOne({
        where: { agencyId: resolvedTargetAgencyId },
        order: [['id', 'ASC']],
      }).catch(() => null);
      if (agencyUser) {
        resolvedTargetBrokerId = agencyUser.id;
        resolvedTargetBrokerName = agencyUser.name;
      }
    }

    if (!resolvedTargetAgencyName && resolvedTargetAgencyId > 0) {
      const ag = await Agency.findByPk(resolvedTargetAgencyId).catch(() => null);
      if (ag?.name) resolvedTargetAgencyName = ag.name;
    }

    // If target broker name is generic or missing, look up user
    if (!resolvedTargetBrokerName || resolvedTargetBrokerName === 'Broker' || resolvedTargetBrokerName === 'Om Shivam' || resolvedTargetBrokerName === 'Partner Broker') {
      const targetUser = await User.findByPk(resolvedTargetBrokerId).catch(() => null);
      if (targetUser?.name) {
        resolvedTargetBrokerName = targetUser.name;
        if (!resolvedTargetAgencyName && targetUser.agencyId) {
          const targetAgency = await Agency.findByPk(targetUser.agencyId).catch(() => null);
          if (targetAgency?.name) resolvedTargetAgencyName = targetAgency.name;
        }
      }
    }

    // Resolve caller user details from DB
    if (callerUserId) {
      const callerUser = await User.findByPk(callerUserId).catch(() => null);
      if (callerUser) {
        if (callerUser.name) callerUserName = callerUser.name;
        if (!callerAgencyId && callerUser.agencyId) {
          callerAgencyId = callerUser.agencyId;
        }
      }
    }

    if (callerAgencyId) {
      const callerAgency = await Agency.findByPk(callerAgencyId).catch(() => null);
      if (callerAgency?.name) callerAgencyName = callerAgency.name;
    }

    const totalRequests = await CollaborationRequest.count();
    const requestCode = `REQ-${100 + totalRequests + 1}`;

    const newRequest = await CollaborationRequest.create({
      requestCode,
      propertyId,
      propertyName: resolvedPropertyName,
      propertyLocation: resolvedPropertyLocation,
      propertyPrice: resolvedPropertyPrice,
      targetAgencyId: resolvedTargetAgencyId,
      targetAgencyName: resolvedTargetAgencyName || 'Partner Agency',
      targetBrokerId: resolvedTargetBrokerId,
      targetBrokerName: resolvedTargetBrokerName || 'Partner Broker',
      requestingAgencyId: callerAgencyId,
      requestingAgencyName: callerAgencyName,
      requestingBrokerId: callerUserId,
      requestingBrokerName: callerUserName,
      clientRequirement,
      expectedBudget: expectedBudget || resolvedPropertyPrice || '',
      remarks: remarks || '',
      status: 'Pending',
    });

    // PRD Sec 16 & 17: Trigger WhatsApp notification to target broker
    WhatsAppService.sendNotification({
      recipientPhone: '+91 98765 43210',
      event: 'Collaboration Request Alert',
      templateName: 'wa_collab_req_v2',
      traits: {
        propertyName: newRequest.propertyName,
        requestCode: newRequest.requestCode,
        requesterName: callerUserName,
        agency: callerAgencyName,
        budget: expectedBudget || 'Standard',
        requirement: clientRequirement,
      },
      bodyValues: [
        resolvedTargetBrokerName || 'Partner Broker',
        callerUserName,
        newRequest.propertyName,
        newRequest.requestCode,
      ],
    }).catch((err) => console.warn('[WhatsApp Collab Error]', err));

    // PRD Sec 17: In-App Alert & FCM Push to Target Broker
    NotificationService.createAndSendNotification({
      userId: resolvedTargetBrokerId,
      agencyId: resolvedTargetAgencyId,
      title: 'New Collaboration Request',
      message: `${callerUserName} from ${callerAgencyName} requested to collaborate on ${newRequest.propertyName}.`,
      type: 'collaboration',
      actionRoute: '/collaborations',
      metadata: { requestCode: newRequest.requestCode, propertyId: newRequest.propertyId },
      channels: ['in_app', 'push'],
    }).catch(() => {});

    // PRD Sec 18: Record Audit Log for Collaboration Requested
    AuditService.logAction({
      action: 'Collaboration Requested',
      target: `${newRequest.requestCode} (${newRequest.propertyName})`,
      req,
      actorName: callerUserName,
      actorRole: 'Broker',
      details: {
        requestCode: newRequest.requestCode,
        propertyId: newRequest.propertyId,
        targetAgency: targetAgencyName,
      },
    }).catch(() => {});

    return successResponse(res, `Collaboration request ${newRequest.requestCode} submitted`, newRequest, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to create collaboration request', error.message || error);
  }
};

/**
 * Fetch Collaboration Requests (Incoming for Listing Agency, Outgoing for Requester)
 */
export const getCollaborations = async (req: Request, res: Response) => {
  try {
    const { type, agencyId, brokerId } = req.query;

    let callerAgencyId: number | null = null;
    let callerUserId: number | null = null;
    let callerRole: string | null = null;

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (decoded.agencyId) callerAgencyId = parseInt(String(decoded.agencyId), 10);
        if (decoded.id) callerUserId = parseInt(String(decoded.id), 10);
        if (decoded.role) callerRole = decoded.role;
      } catch (_) {}
    }

    const targetAgency = agencyId ? parseInt(String(agencyId), 10) : callerAgencyId;
    const targetBroker = brokerId ? parseInt(String(brokerId), 10) : (callerRole === 'broker' ? callerUserId : null);

    let whereClause: any = {};
    if (callerRole === 'super_admin' && !agencyId && !brokerId) {
      // Super Admin sees all requests
    } else if (targetBroker) {
      // For a specific broker: include requests assigned to/requested by this broker,
      // or involving their agency
      if (type === 'incoming') {
        whereClause[Op.or] = [
          { targetBrokerId: targetBroker },
          ...(targetAgency ? [{ targetAgencyId: targetAgency }] : []),
        ];
      } else if (type === 'outgoing') {
        whereClause[Op.or] = [
          { requestingBrokerId: targetBroker },
          ...(targetAgency ? [{ requestingAgencyId: targetAgency }] : []),
        ];
      } else {
        whereClause[Op.or] = [
          { targetBrokerId: targetBroker },
          { requestingBrokerId: targetBroker },
          ...(targetAgency ? [{ targetAgencyId: targetAgency }, { requestingAgencyId: targetAgency }] : []),
        ];
      }
    } else if (targetAgency) {
      // For Agency Admin: all incoming/outgoing requests for the agency
      if (type === 'incoming') {
        whereClause.targetAgencyId = targetAgency;
      } else if (type === 'outgoing') {
        whereClause.requestingAgencyId = targetAgency;
      } else {
        whereClause[Op.or] = [
          { targetAgencyId: targetAgency },
          { requestingAgencyId: targetAgency },
        ];
      }
    }

    const requests = await CollaborationRequest.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
    });

    return successResponse(res, 'Collaboration requests fetched', requests);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch collaboration requests', error.message || error);
  }
};

/**
 * Respond to Collaboration Request (Approve / Reject)
 * If Approved: Auto-provisions Deal and Commission record in PostgreSQL!
 */
export const respondCollaboration = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { action, remarks } = req.body; // action: 'approve' | 'reject'

    let collabReq: CollaborationRequest | null = null;
    const numericId = parseInt(id, 10);
    if (!isNaN(numericId)) {
      collabReq = await CollaborationRequest.findByPk(numericId);
    }
    if (!collabReq) {
      collabReq = await CollaborationRequest.findOne({ where: { requestCode: id } });
    }
    if (!collabReq) {
      return errorResponse(res, 'Collaboration request not found', null, 404);
    }

    if (action === 'cancel') {
      collabReq.status = 'Cancelled';
      if (remarks) collabReq.remarks = remarks;
      await collabReq.save();

      AuditService.logAction({
        action: 'Collaboration Cancelled',
        target: `${collabReq.requestCode} (${collabReq.propertyName})`,
        req,
        actorName: collabReq.requestingBrokerName,
        actorRole: 'Broker',
        details: { requestCode: collabReq.requestCode, remarks: remarks || 'Cancelled by requester' },
      }).catch(() => {});

      return successResponse(res, `Collaboration request ${collabReq.requestCode} cancelled`, collabReq);
    }

    if (action === 'reject') {
      collabReq.status = 'Rejected';
      if (remarks) collabReq.remarks = remarks;
      await collabReq.save();

      // PRD Sec 16 & 17: Trigger WhatsApp notification to requesting broker
      WhatsAppService.sendNotification({
        recipientPhone: '+91 98222 33344',
        event: 'Collaboration Request Rejected',
        templateName: 'wa_collab_rejected_v1',
        traits: {
          requestCode: collabReq.requestCode,
          propertyName: collabReq.propertyName,
          remarks: remarks || 'Not available for co-broking at this time',
          status: 'Rejected',
        },
        bodyValues: [
          collabReq.requestingBrokerName,
          collabReq.propertyName,
          remarks || 'Not available',
        ],
      }).catch(() => {});

      // PRD Sec 17: In-App & FCM Push notification to requesting broker
      NotificationService.createAndSendNotification({
        userId: collabReq.requestingBrokerId,
        agencyId: collabReq.requestingAgencyId,
        title: 'Collaboration Request Declined',
        message: `Your request for ${collabReq.propertyName} was declined: ${remarks || 'No reason provided'}.`,
        type: 'collaboration',
        actionRoute: '/collaborations',
        metadata: { requestCode: collabReq.requestCode, propertyId: collabReq.propertyId, status: 'Rejected' },
        channels: ['in_app', 'push'],
      }).catch(() => {});

      // PRD Sec 18: Record Audit Log for Collaboration Rejected
      AuditService.logAction({
        action: 'Collaboration Rejected',
        target: `${collabReq.requestCode} (${collabReq.propertyName})`,
        req,
        actorName: collabReq.targetBrokerName,
        actorRole: 'Broker',
        details: { requestCode: collabReq.requestCode, remarks },
      }).catch(() => {});

      return successResponse(res, `Collaboration request ${collabReq.requestCode} rejected`, collabReq);
    }

    if (action === 'approve') {
      collabReq.status = 'Approved';

      // 1. Resolve true participant names if missing or generic
      let finalBrokerAName = collabReq.targetBrokerName;
      let finalAgencyAName = collabReq.targetAgencyName;
      let finalBrokerBName = collabReq.requestingBrokerName;
      let finalAgencyBName = collabReq.requestingAgencyName;

      if (!finalBrokerAName || finalBrokerAName === 'Broker' || finalBrokerAName === 'Om Shivam' || finalBrokerAName === 'Partner Broker' || collabReq.targetBrokerId === 1) {
        let uA = (collabReq.targetBrokerId && collabReq.targetBrokerId > 1) ? await User.findByPk(collabReq.targetBrokerId).catch(() => null) : null;
        if (!uA && collabReq.targetAgencyId && collabReq.targetAgencyId > 1) {
          uA = await User.findOne({ where: { agencyId: collabReq.targetAgencyId }, order: [['id', 'ASC']] }).catch(() => null);
          if (uA) {
            collabReq.targetBrokerId = uA.id;
            collabReq.targetBrokerName = uA.name;
          }
        }
        if (uA?.name) {
          finalBrokerAName = uA.name;
          if (!finalAgencyAName && uA.agencyId) {
            const agA = await Agency.findByPk(uA.agencyId).catch(() => null);
            if (agA?.name) finalAgencyAName = agA.name;
          }
        }
      }

      if (!finalBrokerBName || finalBrokerBName === 'Broker' || finalBrokerBName === 'Broker Agent' || finalBrokerBName === 'Partner Broker') {
        const uB = await User.findByPk(collabReq.requestingBrokerId).catch(() => null);
        if (uB?.name) {
          finalBrokerBName = uB.name;
          if (!finalAgencyBName && uB.agencyId) {
            const agB = await Agency.findByPk(uB.agencyId).catch(() => null);
            if (agB?.name) finalAgencyBName = agB.name;
          }
        }
      }

      // 2. Auto-create Deal in PostgreSQL (PRD Section 6 Step 6)
      const totalDeals = await Deal.count();
      const dealCode = `DL-${500 + totalDeals + 1}`;
      const now = new Date().toISOString();

      // Resolve reliable dealValue from budget, propertyPrice, or Property record
      let resolvedDealValue = '₹1.0 Cr';
      if (collabReq.expectedBudget && !collabReq.expectedBudget.toLowerCase().includes('request')) {
        resolvedDealValue = collabReq.expectedBudget;
      } else if (collabReq.propertyPrice && !collabReq.propertyPrice.toLowerCase().includes('request')) {
        resolvedDealValue = collabReq.propertyPrice;
      } else {
        const propRecord = await Property.findByPk(collabReq.propertyId).catch(() => null);
        if (propRecord?.price && !propRecord.price.toLowerCase().includes('request')) {
          resolvedDealValue = propRecord.price;
        }
      }

      const deal = await Deal.create({
        dealCode,
        propertyId: collabReq.propertyId,
        propertyName: collabReq.propertyName,
        agencyAId: collabReq.targetAgencyId,
        agencyAName: finalAgencyAName || 'Listing Agency',
        brokerAId: collabReq.targetBrokerId,
        brokerAName: finalBrokerAName || 'Listing Broker',
        agencyBId: collabReq.requestingAgencyId,
        agencyBName: finalAgencyBName || 'Partner Agency',
        brokerBId: collabReq.requestingBrokerId,
        brokerBName: finalBrokerBName || 'Co-broker',
        clientName: 'Collaborated Client',
        clientPhone: '',
        clientEmail: '',
        clientRequirement: collabReq.clientRequirement,
        expectedBudget: collabReq.expectedBudget || resolvedDealValue,
        status: 'Lead Assigned',
        dealValue: resolvedDealValue,
        remarks: `Collaboration approved from request ${collabReq.requestCode}`,
        documents: [],
        auditHistory: [
          {
            status: 'Lead Assigned',
            timestamp: now,
            updatedBy: finalBrokerAName || 'Listing Broker',
            remarks: `Approved collaboration request ${collabReq.requestCode}`,
          },
        ],
      });

      // 3. Auto-create Commission Record with 50/50 split (PRD Section 12)
      const totalComms = await Commission.count();
      const commCode = `COMM-${800 + totalComms + 1}`;

      let numericVal = 10000000;
      const lowerDeal = resolvedDealValue.toLowerCase();
      const numMatch = resolvedDealValue.replace(/,/g, '').match(/([0-9]+(?:\.[0-9]+)?)/);
      if (numMatch) {
        const parsed = parseFloat(numMatch[1]);
        if (lowerDeal.includes('cr') || lowerDeal.includes('crore')) {
          numericVal = parsed * 10000000;
        } else if (lowerDeal.includes('lac') || lowerDeal.includes('lakh') || /\b[lL]\b/.test(resolvedDealValue)) {
          numericVal = parsed * 100000;
        } else if (parsed > 0) {
          numericVal = parsed;
        }
      }
      const totalCommissionNum = Math.round(numericVal * 0.02);
      const halfCommissionNum = Math.round(totalCommissionNum / 2);
      const formatInr = (n: number) => `₹${n.toLocaleString('en-IN')}`;

      const commission = await Commission.create({
        commissionCode: commCode,
        dealId: deal.id,
        propertyId: collabReq.propertyId,
        propertyName: collabReq.propertyName,
        dealValue: deal.dealValue,
        commissionType: 'Percentage',
        commissionRate: 2.0,
        totalCommission: formatInr(totalCommissionNum),
        brokerASharePct: 50.0,
        brokerBSharePct: 50.0,
        brokerAAmount: formatInr(halfCommissionNum),
        brokerBAmount: formatInr(halfCommissionNum),
        brokerAId: collabReq.targetBrokerId,
        brokerAName: finalBrokerAName || 'Listing Broker',
        brokerBId: collabReq.requestingBrokerId,
        brokerBName: finalBrokerBName || 'Co-broker',
        agencyAId: collabReq.targetAgencyId,
        agencyAName: finalAgencyAName || 'Listing Agency',
        agencyBId: collabReq.requestingAgencyId,
        agencyBName: finalAgencyBName || 'Partner Agency',
        status: 'Pending',
      });

      deal.commissionId = commission.id;
      await deal.save();

      collabReq.dealId = deal.id;
      await collabReq.save();

      // Update property status
      const prop = await Property.findByPk(collabReq.propertyId);
      if (prop) {
        prop.status = 'Under Negotiation';
        await prop.save();
      }

      // PRD Sec 16 & 17: Trigger WhatsApp notification to requesting broker
      WhatsAppService.sendNotification({
        recipientPhone: '+91 98222 33344',
        event: 'Collaboration Request Approved',
        templateName: 'wa_collab_req_v2',
        traits: {
          requestCode: collabReq.requestCode,
          propertyName: collabReq.propertyName,
          dealCode: deal.dealCode,
          status: 'Approved',
          commissionSplit: '50/50',
        },
        bodyValues: [
          finalBrokerBName || 'Partner Broker',
          collabReq.propertyName,
          deal.dealCode,
        ],
      }).catch((err) => console.warn('[WhatsApp Collab Approval Error]', err));

      // PRD Sec 17: In-App & FCM Push to requesting broker
      NotificationService.createAndSendNotification({
        userId: collabReq.requestingBrokerId,
        agencyId: collabReq.requestingAgencyId,
        title: 'Collaboration Request Approved! 🎉',
        message: `Your request for ${collabReq.propertyName} was approved! Deal ${deal.dealCode} has been created.`,
        type: 'collaboration',
        actionRoute: `/deals/${deal.id}`,
        metadata: { requestCode: collabReq.requestCode, dealId: deal.id, dealCode: deal.dealCode, propertyId: collabReq.propertyId },
        channels: ['in_app', 'push'],
      }).catch(() => {});

      // PRD Sec 17: In-App & FCM Push to target (approving) broker
      NotificationService.createAndSendNotification({
        userId: collabReq.targetBrokerId,
        agencyId: collabReq.targetAgencyId,
        title: 'Deal Activated: ' + deal.dealCode,
        message: `Collaboration for ${collabReq.propertyName} confirmed! Deal ${deal.dealCode} is now active in pipeline.`,
        type: 'collaboration',
        actionRoute: `/deals/${deal.id}`,
        metadata: { requestCode: collabReq.requestCode, dealId: deal.id, dealCode: deal.dealCode, propertyId: collabReq.propertyId },
        channels: ['in_app', 'push'],
      }).catch(() => {});

      // PRD Sec 18: Record Audit Log for Collaboration Approved
      AuditService.logAction({
        action: 'Collaboration Approved',
        target: `${collabReq.requestCode} -> Deal ${deal.dealCode}`,
        req,
        actorName: collabReq.targetBrokerName,
        actorRole: 'Broker',
        details: {
          requestCode: collabReq.requestCode,
          dealId: deal.id,
          dealCode: deal.dealCode,
          commissionCode: commission.commissionCode,
        },
      }).catch(() => {});

      return successResponse(
        res,
        `Collaboration approved! Deal ${deal.dealCode} & Commission ${commission.commissionCode} created.`,
        { collaboration: collabReq, deal, commission }
      );
    }

    return errorResponse(res, 'Invalid action specified. Use "approve" or "reject"', null, 400);
  } catch (error: any) {
    return errorResponse(res, 'Failed to respond to collaboration', error.message || error);
  }
};
