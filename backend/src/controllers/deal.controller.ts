import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { Deal } from '../models/deal.model';
import { Property } from '../models/property.model';
import { CollaborationRequest } from '../models/collaboration.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { WhatsAppService } from '../services/whatsapp.service';
import { NotificationService } from '../services/notification.service';
import { AuditService } from '../services/audit.service';

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
 * PRD Section 10: Lead Ownership Model Privacy Firewall
 * Broker B owns the client. Broker A owns the property.
 * Client data remains private.
 * In a cross-agency collaboration (agencyAId !== agencyBId):
 * - Broker A / Agency A CANNOT access client phone, email, or personal info.
 * - Only Broker B / Agency B and Super Admin have full visibility.
 * In a direct/internal agency deal (agencyAId === agencyBId or no partner agency):
 * - The listing agency owns both property and client, so their brokers have access.
 */
const canAccessClientData = (
  json: any,
  callerUserId: number | null,
  callerAgencyId: number | null,
  callerRole: string | null
): boolean => {
  if (callerRole === 'super_admin') return true;

  const aId = json.agencyAId ? parseInt(String(json.agencyAId), 10) : null;
  const bId = json.agencyBId ? parseInt(String(json.agencyBId), 10) : null;
  const isCollaboration = aId && bId && aId !== bId;

  if (isCollaboration) {
    const isPartyB =
      (callerUserId && callerUserId === json.brokerBId) ||
      (callerAgencyId && callerAgencyId === bId);
    return !!isPartyB;
  }

  const isParticipant =
    (callerUserId && (callerUserId === json.brokerAId || callerUserId === json.brokerBId)) ||
    (callerAgencyId && (callerAgencyId === aId || callerAgencyId === bId));

  return !!isParticipant;
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

    const andConditions: any[] = [];

    if (agencyId && agencyId !== 'All') {
      const parsedAgency = parseInt(String(agencyId), 10);
      andConditions.push({ [Op.or]: [{ agencyAId: parsedAgency }, { agencyBId: parsedAgency }] });
    } else if (callerAgencyId && callerRole !== 'super_admin') {
      andConditions.push({ [Op.or]: [{ agencyAId: callerAgencyId }, { agencyBId: callerAgencyId }] });
    }

    if (brokerId && brokerId !== 'All') {
      const parsedBroker = parseInt(String(brokerId), 10);
      andConditions.push({ [Op.or]: [{ brokerAId: parsedBroker }, { brokerBId: parsedBroker }] });
    }

    if (status && status !== 'All') {
      andConditions.push({ status });
    }

    if (search) {
      const query = String(search).trim();
      andConditions.push({
        [Op.or]: [
          { dealCode: { [Op.iLike]: `%${query}%` } },
          { propertyName: { [Op.iLike]: `%${query}%` } },
          { brokerAName: { [Op.iLike]: `%${query}%` } },
          { brokerBName: { [Op.iLike]: `%${query}%` } },
          { agencyAName: { [Op.iLike]: `%${query}%` } },
          { agencyBName: { [Op.iLike]: `%${query}%` } },
          { clientName: { [Op.iLike]: `%${query}%` } },
        ],
      });
    }

    const whereClause: any = andConditions.length > 0 ? { [Op.and]: andConditions } : {};

    const deals = await Deal.findAll({
      where: whereClause,
      order: [['updatedAt', 'DESC']],
    });

    // Apply Lead Privacy Firewall (PRD Section 10)
    // Broker B owns the client. Broker A owns the property.
    // In cross-agency collaboration deals, Broker A cannot access client phone, email, or personal info.
    const sanitizedDeals = deals.map((d) => {
      const json = d.toJSON();
      if (!canAccessClientData(json, callerUserId, callerAgencyId, callerRole)) {
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
    let deal: Deal | null = null;
    const numericId = parseInt(id, 10);
    if (!isNaN(numericId)) {
      deal = await Deal.findByPk(numericId);
    }
    if (!deal) {
      deal = await Deal.findOne({ where: { dealCode: id } });
    }

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
    if (!canAccessClientData(json, callerUserId, callerAgencyId, callerRole)) {
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
    const stage = req.body.newStage || req.body.status;
    const notes = req.body.remarks || req.body.notes || '';
    const newStage = stage;
    const remarks = notes;
    const updatedBy = req.body.updatedBy || 'Broker';
    const milestoneData = req.body.milestoneData || {};

    if (!stage) {
      return errorResponse(res, 'New stage is required', null, 400);
    }

    let deal: Deal | null = null;
    const numericId = parseInt(id, 10);
    if (!isNaN(numericId)) {
      deal = await Deal.findByPk(numericId);
    }
    if (!deal) {
      deal = await Deal.findOne({ where: { dealCode: id } });
    }
    if (!deal) {
      return errorResponse(res, 'Deal not found', null, 404);
    }

    const currentAudit = Array.isArray(deal.auditHistory) ? [...deal.auditHistory] : [];
    currentAudit.push({
      status: stage,
      timestamp: new Date().toISOString(),
      updatedBy,
      remarks: notes || `Stage progressed to ${stage}`,
      ...milestoneData,
    });

    deal.status = stage;
    if (milestoneData.dealValue || milestoneData.offerAmount) {
      deal.dealValue = milestoneData.dealValue || milestoneData.offerAmount;
    }
    deal.auditHistory = currentAudit;
    await deal.save();

    // Auto-sync linked Property status based on Deal Lifecycle (PRD Section 4 & 9)
    // CRITICAL: A property is only marked 'Sold' after a deal is actually Closed / Won!
    if (deal.propertyId) {
      const prop = await Property.findByPk(deal.propertyId);
      if (prop) {
        const lower = stage.toLowerCase();
        if (lower.includes('closed') || lower.includes('sold')) {
          prop.status = prop.purpose === 'Rent' || prop.type === 'Rent' ? 'Rented' : 'Sold';
          await prop.save();

          // Multiple agencies can collaborate on the same property:
          // Once sold with any deal, auto-update remarks of any other pending collaboration requests
          // so other agencies know it is sold (without leaking confidential buyer/counterparty details)
          await CollaborationRequest.update(
            { remarks: 'Listing is closed: Property has been sold.' },
            {
              where: {
                propertyId: deal.propertyId,
                status: 'Pending',
              },
            }
          ).catch(() => {});
        } else if (lower.includes('negotiat') || lower.includes('offer')) {
          if (prop.status !== 'Sold' && prop.status !== 'Rented') {
            prop.status = 'Under Negotiation';
            await prop.save();
          }
        } else if (lower.includes('token') || lower.includes('agreement') || lower.includes('booking')) {
          if (prop.status !== 'Sold' && prop.status !== 'Rented') {
            prop.status = 'Token Done';
            await prop.save();
          }
        } else if (lower.includes('lost') || lower.includes('cancel')) {
          // If this deal was cancelled/lost and no other deal on this property is closed, reset to Available
          const otherClosed = await Deal.findOne({
            where: {
              propertyId: deal.propertyId,
              id: { [Op.ne]: deal.id },
              status: { [Op.iLike]: '%closed%' },
            },
          });
          if (!otherClosed && prop.status !== 'Sold' && prop.status !== 'Rented') {
            prop.status = 'Available';
            await prop.save();
          }
        }
      }
    }

    // PRD Sec 16 & 17: Trigger WhatsApp deal status notification
    WhatsAppService.sendNotification({
      recipientPhone: '+91 99000 11223',
      event: `Deal Stage: ${newStage}`,
      templateName: 'wa_deal_update_v1',
      traits: {
        dealCode: deal.dealCode,
        propertyName: deal.propertyName,
        newStage,
        dealValue: deal.dealValue,
        updatedBy: updatedBy || 'Deal Collaborator',
      },
      bodyValues: [
        deal.dealCode,
        deal.propertyName,
        newStage,
        deal.dealValue,
      ],
    }).catch((err) => console.warn('[WhatsApp Deal Alert Error]', err));

    // PRD Sec 17: In-App & FCM Push for Deal Stage Update
    if (deal.brokerAId) {
      NotificationService.createAndSendNotification({
        userId: deal.brokerAId,
        agencyId: deal.agencyAId,
        title: `Deal Stage: ${newStage}`,
        message: `Deal ${deal.dealCode} (${deal.propertyName}) progressed to "${newStage}".`,
        type: 'deal',
        actionRoute: `/deals/${deal.id}`,
        metadata: { dealId: deal.id, dealCode: deal.dealCode, status: newStage },
        channels: ['in_app', 'push'],
      }).catch(() => {});
    }
    if (deal.brokerBId && deal.brokerBId !== deal.brokerAId) {
      NotificationService.createAndSendNotification({
        userId: deal.brokerBId,
        agencyId: deal.agencyBId,
        title: `Deal Stage: ${newStage}`,
        message: `Deal ${deal.dealCode} (${deal.propertyName}) progressed to "${newStage}".`,
        type: 'deal',
        actionRoute: `/deals/${deal.id}`,
        metadata: { dealId: deal.id, dealCode: deal.dealCode, status: newStage },
        channels: ['in_app', 'push'],
      }).catch(() => {});
    }

    // PRD Sec 18: Record Audit Log for Deal Status Changed
    AuditService.logAction({
      action: 'Deal Status Changed',
      target: `Deal ${deal.dealCode} (${deal.propertyName}) -> ${newStage}`,
      req,
      actorName: updatedBy || deal.brokerAName || 'Broker',
      actorRole: 'Broker',
      details: { dealId: deal.id, dealCode: deal.dealCode, newStage, remarks },
    }).catch(() => {});

    return successResponse(res, `Deal stage updated to "${newStage}"`, deal);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update deal status', error.message || error);
  }
};

/**
 * Upload / attach a deal document to the deal folder (PRD Sec 7.3)
 */
export const uploadDealDocument = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { title, documentType, fileUrl, uploadedBy, notes } = req.body;

    if (!title || !documentType) {
      return errorResponse(res, 'Title and documentType are required', null, 400);
    }

    const deal = await Deal.findByPk(id);
    if (!deal) {
      return errorResponse(res, 'Deal not found', null, 404);
    }

    const existingDocs = Array.isArray(deal.documents) ? [...deal.documents] : [];
    const docId = `DOC-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    const newDoc = {
      id: docId,
      title: title.trim(),
      documentType: documentType.trim(),
      fileUrl: fileUrl || `https://storage.propconnect.com/deals/${deal.id}/${encodeURIComponent(title)}.pdf`,
      uploadedBy: uploadedBy || deal.brokerAName || 'Broker',
      uploadedAt: new Date().toISOString(),
      notes: notes || '',
    };

    existingDocs.push(newDoc);
    deal.documents = existingDocs;
    await deal.save();

    // Notify counterparties about the uploaded document
    const notifyBrokers = [deal.brokerAId, deal.brokerBId].filter((bId) => bId && !isNaN(Number(bId)));
    for (const bId of notifyBrokers) {
      NotificationService.createAndSendNotification({
        userId: Number(bId),
        title: `Deal Document Added: ${deal.dealCode}`,
        message: `${newDoc.uploadedBy} uploaded "${newDoc.title}" (${newDoc.documentType}) for ${deal.propertyName}.`,
        type: 'deal',
        actionRoute: `/deals/${deal.id}`,
        metadata: { dealId: deal.id, dealCode: deal.dealCode, docId },
        channels: ['in_app', 'push'],
      }).catch(() => {});
    }

    return successResponse(res, 'Document uploaded successfully', { document: newDoc, documents: deal.documents });
  } catch (error: any) {
    return errorResponse(res, 'Failed to upload deal document', error.message || error);
  }
};

/**
 * Delete a deal document
 */
export const deleteDealDocument = async (req: Request, res: Response) => {
  try {
    const { id, docId } = req.params;
    const deal = await Deal.findByPk(id);
    if (!deal) {
      return errorResponse(res, 'Deal not found', null, 404);
    }

    const existingDocs = Array.isArray(deal.documents) ? [...deal.documents] : [];
    const filtered = existingDocs.filter((d: any) => d.id !== docId);
    deal.documents = filtered;
    await deal.save();

    return successResponse(res, 'Document removed successfully', { documents: deal.documents });
  } catch (error: any) {
    return errorResponse(res, 'Failed to delete deal document', error.message || error);
  }
};

/**
 * Update Client Information for Deal (PRD Sec 10)
 */
export const updateDealClient = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { clientName, clientPhone, clientEmail, clientRequirement } = req.body;

    let deal: Deal | null = null;
    const numericId = parseInt(id, 10);
    if (!isNaN(numericId)) {
      deal = await Deal.findByPk(numericId);
    }
    if (!deal) {
      deal = await Deal.findOne({ where: { dealCode: id } });
    }
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

    if (!canAccessClientData(deal.toJSON(), callerUserId, callerAgencyId, callerRole)) {
      return errorResponse(res, 'Access denied: Only the client owner (Broker B) can edit client details per PRD Section 10.', null, 403);
    }

    if (clientName !== undefined) deal.clientName = clientName;
    if (clientPhone !== undefined) deal.clientPhone = clientPhone;
    if (clientEmail !== undefined) deal.clientEmail = clientEmail;
    if (clientRequirement !== undefined) deal.clientRequirement = clientRequirement;

    await deal.save();

    return successResponse(res, 'Client details updated successfully', deal);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update client details', error.message || error);
  }
};


