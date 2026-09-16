import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { CollaborationRequest } from '../models/collaboration.model';
import { Deal } from '../models/deal.model';
import { Commission } from '../models/commission.model';
import { Property } from '../models/property.model';
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

    let callerAgencyId = 1;
    let callerAgencyName = 'Partner Realty';
    let callerUserId = 2;
    let callerUserName = 'Broker Agent';

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (decoded.agencyId) callerAgencyId = parseInt(String(decoded.agencyId), 10);
        if (decoded.id) callerUserId = parseInt(String(decoded.id), 10);
        if (decoded.name) callerUserName = decoded.name;
        if (decoded.agency?.name) callerAgencyName = decoded.agency.name;
      } catch (_) {}
    }

    const totalRequests = await CollaborationRequest.count();
    const requestCode = `REQ-${100 + totalRequests + 1}`;

    const newRequest = await CollaborationRequest.create({
      requestCode,
      propertyId,
      propertyName: propertyName || 'Featured Property',
      propertyLocation: propertyLocation || 'Mumbai',
      propertyPrice: propertyPrice || 'Price on Request',
      targetAgencyId: targetAgencyId || 1,
      targetAgencyName: targetAgencyName || 'Sunrise Properties',
      targetBrokerId: targetBrokerId || 1,
      targetBrokerName: targetBrokerName || 'Om Shivam',
      requestingAgencyId: callerAgencyId,
      requestingAgencyName: callerAgencyName,
      requestingBrokerId: callerUserId,
      requestingBrokerName: callerUserName,
      clientRequirement,
      expectedBudget: expectedBudget || propertyPrice || '',
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
        targetBrokerName || 'Partner Broker',
        callerUserName,
        newRequest.propertyName,
        newRequest.requestCode,
      ],
    }).catch((err) => console.warn('[WhatsApp Collab Error]', err));

    // PRD Sec 17: In-App Alert & FCM Push to Target Broker
    NotificationService.createAndSendNotification({
      userId: targetBrokerId || 1,
      agencyId: targetAgencyId || 1,
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
    const { type, agencyId } = req.query;

    let callerAgencyId: number | null = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (decoded.agencyId) callerAgencyId = parseInt(String(decoded.agencyId), 10);
      } catch (_) {}
    }

    const targetAgency = agencyId ? parseInt(String(agencyId), 10) : callerAgencyId;

    let whereClause: any = {};
    if (type === 'incoming' && targetAgency) {
      whereClause.targetAgencyId = targetAgency;
    } else if (type === 'outgoing' && targetAgency) {
      whereClause.requestingAgencyId = targetAgency;
    } else if (targetAgency) {
      whereClause[Op.or] = [
        { targetAgencyId: targetAgency },
        { requestingAgencyId: targetAgency },
      ];
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

    const collabReq = await CollaborationRequest.findByPk(id);
    if (!collabReq) {
      return errorResponse(res, 'Collaboration request not found', null, 404);
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

      // 1. Auto-create Deal in PostgreSQL (PRD Section 6 Step 6)
      const totalDeals = await Deal.count();
      const dealCode = `DL-${500 + totalDeals + 1}`;
      const now = new Date().toISOString();

      const deal = await Deal.create({
        dealCode,
        propertyId: collabReq.propertyId,
        propertyName: collabReq.propertyName,
        agencyAId: collabReq.targetAgencyId,
        agencyAName: collabReq.targetAgencyName,
        brokerAId: collabReq.targetBrokerId,
        brokerAName: collabReq.targetBrokerName,
        agencyBId: collabReq.requestingAgencyId,
        agencyBName: collabReq.requestingAgencyName,
        brokerBId: collabReq.requestingBrokerId,
        brokerBName: collabReq.requestingBrokerName,
        clientName: 'Collaborated Client',
        clientPhone: '',
        clientEmail: '',
        clientRequirement: collabReq.clientRequirement,
        expectedBudget: collabReq.expectedBudget,
        status: 'Lead Assigned',
        dealValue: collabReq.expectedBudget || collabReq.propertyPrice || '₹1.0 Cr',
        remarks: `Collaboration approved from request ${collabReq.requestCode}`,
        auditHistory: [
          {
            status: 'Lead Assigned',
            timestamp: now,
            updatedBy: collabReq.targetBrokerName || 'Listing Broker',
            remarks: `Approved collaboration request ${collabReq.requestCode}`,
          },
        ],
      });

      // 2. Auto-create Commission Record with 50/50 split (PRD Section 12)
      const totalComms = await Commission.count();
      const commCode = `COMM-${800 + totalComms + 1}`;

      const commission = await Commission.create({
        commissionCode: commCode,
        dealId: deal.id,
        propertyId: collabReq.propertyId,
        propertyName: collabReq.propertyName,
        dealValue: deal.dealValue,
        commissionType: 'Percentage',
        commissionRate: 2.0,
        totalCommission: '₹2,00,000',
        brokerASharePct: 50.0,
        brokerBSharePct: 50.0,
        brokerAAmount: '₹1,00,000',
        brokerBAmount: '₹1,00,000',
        brokerAId: collabReq.targetBrokerId,
        brokerAName: collabReq.targetBrokerName,
        brokerBId: collabReq.requestingBrokerId,
        brokerBName: collabReq.requestingBrokerName,
        agencyAId: collabReq.targetAgencyId,
        agencyAName: collabReq.targetAgencyName,
        agencyBId: collabReq.requestingAgencyId,
        agencyBName: collabReq.requestingAgencyName,
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
          collabReq.requestingBrokerName,
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
        actionRoute: '/deals',
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
