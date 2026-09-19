import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { Owner } from '../models/owner.model';
import { Property } from '../models/property.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { AuditService } from '../services/audit.service';

/**
 * Helper to resolve agencyId from JWT token or request
 */
function resolveAgencyId(req: Request): number | null {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
      if (decoded.agencyId) return parseInt(String(decoded.agencyId), 10);
    } catch (_) {}
  }
  if (req.query.agencyId) {
    const parsed = parseInt(String(req.query.agencyId), 10);
    if (!isNaN(parsed)) return parsed;
  }
  if (req.body && req.body.agencyId) {
    const parsed = parseInt(String(req.body.agencyId), 10);
    if (!isNaN(parsed)) return parsed;
  }
  return null;
}

/**
 * List all Owners for agency with search and linked property counts
 * GET /api/v1/owners
 */
export const getOwners = async (req: Request, res: Response) => {
  try {
    const agencyId = resolveAgencyId(req);
    const searchQuery = (req.query.q as string || req.query.search as string || '').trim();

    const whereClause: any = {};
    if (agencyId) {
      whereClause.agencyId = agencyId;
    }

    if (searchQuery) {
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${searchQuery}%` } },
        { phonePrimary: { [Op.iLike]: `%${searchQuery}%` } },
        { phoneSecondary: { [Op.iLike]: `%${searchQuery}%` } },
        { email: { [Op.iLike]: `%${searchQuery}%` } },
        { address: { [Op.iLike]: `%${searchQuery}%` } },
      ];
    }

    const owners = await Owner.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
    });

    // Attach property count for each owner
    const ownersWithStats = await Promise.all(
      owners.map(async (owner) => {
        const count = await Property.count({
          where: {
            [Op.or]: [
              { ownerId: owner.id },
              {
                [Op.and]: [
                  { ownerName: owner.name },
                  { agencyId: owner.agencyId },
                ],
              },
            ],
          },
        });

        const ownerJson = owner.toJSON() as Record<string, any>;
        return {
          ...ownerJson,
          propertyCount: count,
        };
      })
    );

    return successResponse(res, 'Owners retrieved successfully', ownersWithStats);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch owners', error.message || error);
  }
};

/**
 * Get Owner details by ID with linked properties
 * GET /api/v1/owners/:id
 */
export const getOwnerById = async (req: Request, res: Response) => {
  try {
    const ownerId = parseInt(req.params.id, 10);
    if (isNaN(ownerId)) {
      return errorResponse(res, 'Invalid Owner ID', null, 400);
    }

    const owner = await Owner.findByPk(ownerId);
    if (!owner) {
      return errorResponse(res, 'Owner not found', null, 404);
    }

    const linkedProperties = await Property.findAll({
      where: {
        [Op.or]: [
          { ownerId: owner.id },
          {
            [Op.and]: [
              { ownerName: owner.name },
              { agencyId: owner.agencyId },
            ],
          },
        ],
      },
      attributes: ['id', 'propertyCode', 'title', 'price', 'type', 'propertyType', 'location', 'status'],
      order: [['createdAt', 'DESC']],
    });

    const data = {
      ...(owner.toJSON() as Record<string, any>),
      propertyCount: linkedProperties.length,
      properties: linkedProperties,
    };

    return successResponse(res, 'Owner details retrieved successfully', data);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch owner details', error.message || error);
  }
};

/**
 * Create a new Owner
 * POST /api/v1/owners
 */
export const createOwner = async (req: Request, res: Response) => {
  try {
    const { name, phonePrimary, phoneSecondary, email, address, idType, idNumber, notes, kycDocs } = req.body;

    if (!name || !name.trim()) {
      return errorResponse(res, 'Owner name is required', null, 400);
    }
    if (!phonePrimary || !phonePrimary.trim()) {
      return errorResponse(res, 'Owner primary phone is required', null, 400);
    }

    let agencyId = resolveAgencyId(req);
    if (!agencyId) {
      agencyId = 1; // Default agency fallback
    }

    // Check if an owner with same name and primary phone already exists under this agency
    const existing = await Owner.findOne({
      where: {
        agencyId,
        [Op.and]: [
          { name: name.trim() },
          { phonePrimary: phonePrimary.trim() },
        ],
      },
    });

    if (existing) {
      return successResponse(res, 'Existing owner record found', {
        ...(existing.toJSON() as Record<string, any>),
        propertyCount: 0,
      }, 200);
    }

    const owner = await Owner.create({
      agencyId,
      name: name.trim(),
      phonePrimary: phonePrimary.trim(),
      phoneSecondary: (phoneSecondary || '').trim(),
      email: (email || '').trim(),
      address: (address || '').trim(),
      idType: idType || 'Aadhaar',
      idNumber: (idNumber || '').trim(),
      notes: (notes || '').trim(),
      kycDocs: Array.isArray(kycDocs) ? kycDocs : [],
    });

    AuditService.logAction({
      action: 'Owner Created',
      target: `${owner.name} (${owner.phonePrimary})`,
      req,
      actorName: 'Agency Broker',
      actorRole: 'Broker',
      details: { ownerId: owner.id, agencyId },
    }).catch(() => {});

    return successResponse(res, 'Owner created successfully in PostgreSQL', {
      ...(owner.toJSON() as Record<string, any>),
      propertyCount: 0,
    }, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to create owner', error.message || error);
  }
};

/**
 * Update an existing Owner
 * PUT /api/v1/owners/:id
 */
export const updateOwner = async (req: Request, res: Response) => {
  try {
    const ownerId = parseInt(req.params.id, 10);
    if (isNaN(ownerId)) {
      return errorResponse(res, 'Invalid Owner ID', null, 400);
    }

    const owner = await Owner.findByPk(ownerId);
    if (!owner) {
      return errorResponse(res, 'Owner not found', null, 404);
    }

    const { name, phonePrimary, phoneSecondary, email, address, idType, idNumber, notes, kycDocs } = req.body;

    if (name !== undefined) owner.name = name.trim();
    if (phonePrimary !== undefined) owner.phonePrimary = phonePrimary.trim();
    if (phoneSecondary !== undefined) owner.phoneSecondary = phoneSecondary.trim();
    if (email !== undefined) owner.email = email.trim();
    if (address !== undefined) owner.address = address.trim();
    if (idType !== undefined) owner.idType = idType;
    if (idNumber !== undefined) owner.idNumber = idNumber.trim();
    if (notes !== undefined) owner.notes = notes.trim();
    if (kycDocs !== undefined && Array.isArray(kycDocs)) owner.kycDocs = kycDocs;

    await owner.save();

    // Also optionally sync name/phone to any properties linked to this owner
    if (name || phonePrimary) {
      await Property.update(
        {
          ...(name ? { ownerName: owner.name } : {}),
          ...(phonePrimary ? { ownerPhonePrimary: owner.phonePrimary } : {}),
        },
        { where: { ownerId: owner.id } }
      );
    }

    AuditService.logAction({
      action: 'Owner Updated',
      target: `${owner.name} (${owner.phonePrimary})`,
      req,
      actorName: 'Agency Broker',
      actorRole: 'Broker',
      details: { ownerId: owner.id },
    }).catch(() => {});

    return successResponse(res, 'Owner details updated successfully', owner);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update owner', error.message || error);
  }
};

/**
 * Delete an Owner
 * DELETE /api/v1/owners/:id
 */
export const deleteOwner = async (req: Request, res: Response) => {
  try {
    const ownerId = parseInt(req.params.id, 10);
    if (isNaN(ownerId)) {
      return errorResponse(res, 'Invalid Owner ID', null, 400);
    }

    const owner = await Owner.findByPk(ownerId);
    if (!owner) {
      return errorResponse(res, 'Owner not found', null, 404);
    }

    // Unlink properties before deletion
    await Property.update(
      { ownerId: null },
      { where: { ownerId: owner.id } }
    );

    const ownerName = owner.name;
    await owner.destroy();

    AuditService.logAction({
      action: 'Owner Deleted',
      target: ownerName,
      req,
      actorName: 'Agency Broker',
      actorRole: 'Broker',
      details: { ownerId },
    }).catch(() => {});

    return successResponse(res, 'Owner deleted successfully', { id: ownerId });
  } catch (error: any) {
    return errorResponse(res, 'Failed to delete owner', error.message || error);
  }
};
