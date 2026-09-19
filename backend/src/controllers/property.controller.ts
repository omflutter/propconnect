import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { Property } from '../models/property.model';
import { Agency } from '../models/agency.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { AuditService } from '../services/audit.service';

/**
 * Privacy Firewall helper: Masks confidential owner details and negotiable price
 * for external brokers / collaborator brokers per PRD Section 4, 8 & 10.
 */
const sanitizePropertyForCaller = (
  property: Property,
  callerAgencyId: number | null,
  callerRole: string | null
) => {
  const json = property.toJSON ? property.toJSON() : { ...property };
  const isOwnerAgency =
    callerRole === 'super_admin' ||
    (callerAgencyId && callerAgencyId === json.agencyId);

  if (!isOwnerAgency) {
    json.negotiablePrice = '';
    json.internalNotes = '';
    if (json.ownerName) json.ownerName = 'Verified Owner';
    if (json.ownerPhonePrimary) json.ownerPhonePrimary = 'Protected (Connect via Collab)';
    if (json.ownerPhoneSecondary) json.ownerPhoneSecondary = '';
    if (json.ownerEmail) json.ownerEmail = 'Protected (Connect via Collab)';
    if (json.ownerAddress) json.ownerAddress = 'Protected';
    json.ownerKycDocs = [];
  }
  return json;
};

/**
 * Fetch Property Inventory Listings with Search & Filters - 100% PostgreSQL
 */
export const getProperties = async (req: Request, res: Response) => {
  try {
    const { agencyId, search, type, purpose, propertyType, status, city, area } = req.query;

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
      whereClause.agencyId = parseInt(String(agencyId), 10);
    }

    if (type && type !== 'All') {
      whereClause.type = type;
    }

    if (purpose && purpose !== 'All') {
      whereClause.purpose = purpose;
    }

    if (propertyType && propertyType !== 'All') {
      whereClause.propertyType = propertyType;
    }

    if (status && status !== 'All') {
      whereClause.status = status;
    }

    if (city && city !== 'All') {
      whereClause.city = { [Op.iLike]: `%${String(city).trim()}%` };
    }

    if (area && area !== 'All') {
      whereClause.area = { [Op.iLike]: `%${String(area).trim()}%` };
    }

    if (search) {
      const query = String(search).trim();
      whereClause[Op.or] = [
        { title: { [Op.iLike]: `%${query}%` } },
        { location: { [Op.iLike]: `%${query}%` } },
        { city: { [Op.iLike]: `%${query}%` } },
        { area: { [Op.iLike]: `%${query}%` } },
        { propertyCode: { [Op.iLike]: `%${query}%` } },
        { agencyName: { [Op.iLike]: `%${query}%` } },
      ];
    }

    const properties = await Property.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
    });

    const sanitized = properties.map((p) =>
      sanitizePropertyForCaller(p, callerAgencyId, callerRole)
    );

    return successResponse(res, 'Properties retrieved successfully from PostgreSQL', sanitized);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch properties', error.message || error);
  }
};

/**
 * Fetch Single Property Details - 100% PostgreSQL
 */
export const getPropertyById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

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

    const property = await Property.findOne({
      where: {
        [Op.or]: [{ id: isNaN(Number(id)) ? 0 : Number(id) }, { propertyCode: id }],
      },
    });

    if (!property) {
      return errorResponse(res, 'Property not found', null, 404);
    }

    const sanitized = sanitizePropertyForCaller(property, callerAgencyId, callerRole);
    return successResponse(res, 'Property details retrieved from PostgreSQL', sanitized);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch property details', error.message || error);
  }
};

/**
 * Onboard / Create New Property Listing - 100% PostgreSQL
 */
export const createProperty = async (req: Request, res: Response) => {
  try {
    const { title, location, price } = req.body;

    if (!title || !location || !price) {
      return errorResponse(res, 'Title, Location, and Price are required', null, 400);
    }

    const totalCount = await Property.count();
    const propertyCode = `PR-${101 + totalCount}`;

    let targetAgencyId = req.body.agencyId ? parseInt(req.body.agencyId, 10) : null;
    let targetAgencyName = req.body.agencyName && String(req.body.agencyName).trim() ? String(req.body.agencyName).trim() : '';
    let targetBrokerName = req.body.brokerName && String(req.body.brokerName).trim() ? String(req.body.brokerName).trim() : '';

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (!targetAgencyId && decoded.agencyId) targetAgencyId = parseInt(String(decoded.agencyId), 10);
        if (!targetBrokerName && decoded.name) targetBrokerName = decoded.name;
      } catch (_) {}
    }

    if (targetAgencyId) {
      const dbAgency = await Agency.findByPk(targetAgencyId);
      if (dbAgency && !targetAgencyName) {
        targetAgencyName = dbAgency.name;
      }
    }

    if (!targetAgencyId) targetAgencyId = 1;
    if (!targetAgencyName) targetAgencyName = 'Partner Agency';
    if (!targetBrokerName) targetBrokerName = 'Broker Agent';

    const purposeVal = req.body.purpose || req.body.type || 'Sale';

    const property = await Property.create({
      propertyCode,
      title,
      description: req.body.description || '',
      location,
      price,
      bhk: req.body.bhk || '2 BHK',
      type: purposeVal,
      purpose: purposeVal,
      propertyType: req.body.propertyType || 'Apartment',
      areaSqft: req.body.areaSqft ? parseFloat(req.body.areaSqft) : 1000.0,
      builtUpArea: req.body.builtUpArea ? parseFloat(req.body.builtUpArea) : (req.body.areaSqft ? parseFloat(req.body.areaSqft) : 1000.0),
      carpetArea: req.body.carpetArea ? parseFloat(req.body.carpetArea) : 850.0,
      status: req.body.status || 'Available',
      isPublic: req.body.isPublic !== undefined ? Boolean(req.body.isPublic) : false,
      agencyId: targetAgencyId,
      agencyName: targetAgencyName,
      brokerName: targetBrokerName,
      bathrooms: req.body.bathrooms ? parseInt(req.body.bathrooms, 10) : 2,
      balcony: req.body.balcony ? parseInt(req.body.balcony, 10) : 1,
      parking: req.body.parking ? parseInt(req.body.parking, 10) : 1,
      furnishedStatus: req.body.furnishedStatus || 'Unfurnished',
      propertyAge: req.body.propertyAge || '1-5 Years',
      maintenanceCharges: req.body.maintenanceCharges || '₹0',
      securityDeposit: req.body.securityDeposit || '₹0',
      negotiablePrice: req.body.negotiablePrice || '',
      country: req.body.country || 'India',
      state: req.body.state || 'Maharashtra',
      city: req.body.city || 'Mumbai',
      area: req.body.area || '',
      address: req.body.address || '',
      googleMapUrl: req.body.googleMapUrl || '',
      latitude: req.body.latitude ? parseFloat(req.body.latitude) : 19.076,
      longitude: req.body.longitude ? parseFloat(req.body.longitude) : 72.8777,
      ownerName: req.body.ownerName || '',
      ownerPhonePrimary: req.body.ownerPhonePrimary || '',
      ownerPhoneSecondary: req.body.ownerPhoneSecondary || '',
      ownerEmail: req.body.ownerEmail || '',
      ownerAddress: req.body.ownerAddress || '',
      ownerKycDocs: req.body.ownerKycDocs || [],
      internalNotes: req.body.internalNotes || '',
      amenities: req.body.amenities || [],
      images: req.body.images || [],
      floorPlans: req.body.floorPlans || [],
      videos: req.body.videos || [],
      documents: req.body.documents || [],
    });

    // PRD Sec 18: Record Audit Log for Property Created
    AuditService.logAction({
      action: 'Property Created',
      target: `${property.title} (${property.propertyCode})`,
      req,
      actorName: property.brokerName,
      actorRole: 'Broker',
      details: { propertyId: property.id, price: property.price, type: property.type },
    }).catch(() => {});

    return successResponse(res, 'Property listing created successfully in PostgreSQL', property, 201);
  } catch (error: any) {
    return errorResponse(res, 'Failed to create property', error.message || error);
  }
};

/**
 * Bulk Import Properties from 99acres, MagicBricks, Housing.com, Custom APIs - 100% PostgreSQL
 */
export const importProperties = async (req: Request, res: Response) => {
  try {
    const { platform, properties: importList, agencyName, brokerName, agencyId } = req.body;

    if (!importList || !Array.isArray(importList) || importList.length === 0) {
      return errorResponse(res, 'No properties provided for import', null, 400);
    }

    let targetAgencyId = agencyId ? parseInt(String(agencyId), 10) : null;
    let targetAgencyName = agencyName && String(agencyName).trim() ? String(agencyName).trim() : '';
    let targetBrokerName = brokerName && String(brokerName).trim() ? String(brokerName).trim() : '';

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
        if (!targetAgencyId && decoded.agencyId) targetAgencyId = parseInt(String(decoded.agencyId), 10);
        if (!targetBrokerName && decoded.name) targetBrokerName = decoded.name;
      } catch (_) {}
    }

    if (targetAgencyId) {
      const dbAgency = await Agency.findByPk(targetAgencyId);
      if (dbAgency && !targetAgencyName) {
        targetAgencyName = dbAgency.name;
      }
    }

    if (!targetAgencyId) targetAgencyId = 1;
    if (!targetAgencyName) targetAgencyName = 'Partner Agency';
    if (!targetBrokerName) targetBrokerName = 'Broker Agent';

    const syncedList: any[] = [];
    let updatedCount = 0;
    let createdCount = 0;
    let currentCount = await Property.count();

    const parseSafeInt = (val: any, fallback = 0): number => {
      if (val === null || val === undefined) return fallback;
      if (typeof val === 'number') return isNaN(val) ? fallback : Math.floor(val);
      const str = String(val).trim();
      const match = str.match(/\d+/);
      if (match) {
        const num = parseInt(match[0], 10);
        return isNaN(num) ? fallback : num;
      }
      return fallback;
    };

    const parseSafeFloat = (val: any, fallback = 0.0): number => {
      if (val === null || val === undefined) return fallback;
      if (typeof val === 'number') return isNaN(val) ? fallback : val;
      const str = String(val).replace(/[^0-9.]/g, '').trim();
      const num = parseFloat(str);
      return isNaN(num) ? fallback : num;
    };

    const parseSafeStringList = (val: any, fallback: string[] = []): string[] => {
      if (!val) return fallback;
      if (Array.isArray(val)) return val.map((e) => String(e).trim()).filter(Boolean);
      if (typeof val === 'string') {
        const s = val.trim();
        if (s.startsWith('[') && s.endsWith(']')) {
          try {
            const decoded = JSON.parse(s);
            if (Array.isArray(decoded)) return decoded.map((e) => String(e).trim()).filter(Boolean);
          } catch (_) {}
        }
        return s.split(',').map((e) => e.trim()).filter(Boolean);
      }
      return fallback;
    };

    for (const item of importList) {
      try {
        let existing: any = null;
        const cleanTitle = String(item.title || '').trim();
        const coreTitle = cleanTitle.replace(/^(99acres|magicbricks|housing(\.com)?|custom\s*feed)[^:]*:\s*/i, '').trim();

        // 1. By explicit propertyCode
        if (item.propertyCode) {
          existing = await Property.findOne({
            where: { propertyCode: item.propertyCode, agencyId: targetAgencyId },
          });
        }

        // 2. By externalId or feed id
        if (!existing && (item.externalId || item.id)) {
          const extId = String(item.externalId || item.id).trim();
          existing = await Property.findOne({
            where: {
              agencyId: targetAgencyId,
              [Op.or]: [
                { propertyCode: extId },
                { propertyCode: `IMP-${extId}` },
              ],
            },
          });
        }

        // 3. Case-insensitive exact title match within this agency
        if (!existing && cleanTitle) {
          existing = await Property.findOne({
            where: {
              agencyId: targetAgencyId,
              title: { [Op.iLike]: cleanTitle },
            },
          });
        }

        // 4. Case-insensitive core title match (ignoring platform prefix like "99acres Verified: ")
        if (!existing && coreTitle.length >= 6) {
          existing = await Property.findOne({
            where: {
              agencyId: targetAgencyId,
              title: { [Op.iLike]: `%${coreTitle}%` },
            },
          });
        }

        if (existing) {
          await existing.update({
            price: item.price !== undefined ? String(item.price) : existing.price,
            location: item.location ? String(item.location) : existing.location,
            status: item.status ? String(item.status) : existing.status,
            images: item.images && item.images.length > 0 ? parseSafeStringList(item.images) : existing.images,
            areaSqft: item.areaSqft !== undefined ? parseSafeFloat(item.areaSqft, existing.areaSqft) : existing.areaSqft,
            builtUpArea: item.builtUpArea !== undefined ? parseSafeFloat(item.builtUpArea, existing.builtUpArea) : existing.builtUpArea,
            carpetArea: item.carpetArea !== undefined ? parseSafeFloat(item.carpetArea, existing.carpetArea) : existing.carpetArea,
            bathrooms: item.bathrooms !== undefined ? parseSafeInt(item.bathrooms, existing.bathrooms) : existing.bathrooms,
            balcony: item.balcony !== undefined ? parseSafeInt(item.balcony, existing.balcony) : existing.balcony,
            parking: item.parking !== undefined ? parseSafeInt(item.parking, existing.parking) : existing.parking,
            furnishedStatus: item.furnishedStatus ? String(item.furnishedStatus) : existing.furnishedStatus,
            propertyAge: item.propertyAge ? String(item.propertyAge) : existing.propertyAge,
            maintenanceCharges: item.maintenanceCharges ? String(item.maintenanceCharges) : existing.maintenanceCharges,
            amenities: item.amenities ? parseSafeStringList(item.amenities, existing.amenities) : existing.amenities,
          });
          syncedList.push(existing);
          updatedCount++;
        } else {
          currentCount++;
          const propertyCode =
            item.propertyCode ||
            `IMP-${platform ? platform.substring(0, 3).toUpperCase() : 'EXT'}-${100 + currentCount}`;

          const purposeVal = String(item.purpose || item.type || 'Sale');

          const created = await Property.create({
            propertyCode,
            title: String(item.title || `Imported ${item.propertyType || 'Property'}`),
            description: String(item.description || ''),
            location: String(item.location || 'Mumbai, Maharashtra'),
            price: String(item.price || 'Price on Request'),
            bhk: String(item.bhk || '2 BHK'),
            type: purposeVal,
            purpose: purposeVal,
            propertyType: String(item.propertyType || 'Apartment'),
            areaSqft: parseSafeFloat(item.areaSqft, 1200.0),
            builtUpArea: parseSafeFloat(item.builtUpArea || item.areaSqft, 1200.0),
            carpetArea: parseSafeFloat(item.carpetArea, 950.0),
            status: 'Available',
            isPublic: item.isPublic !== undefined ? Boolean(item.isPublic) : true,
            agencyId: targetAgencyId,
            agencyName: targetAgencyName,
            brokerName: targetBrokerName,
            bathrooms: parseSafeInt(item.bathrooms, 2),
            balcony: parseSafeInt(item.balcony, 1),
            parking: parseSafeInt(item.parking, 1),
            furnishedStatus: String(item.furnishedStatus || 'Semi-Furnished'),
            propertyAge: item.propertyAge ? String(item.propertyAge) : '1-5 Years',
            maintenanceCharges: String(item.maintenanceCharges || '₹3,500/mo'),
            securityDeposit: '₹0',
            negotiablePrice: '',
            country: 'India',
            state: 'Maharashtra',
            city: 'Mumbai',
            area: '',
            address: '',
            googleMapUrl: '',
            latitude: 19.076,
            longitude: 72.8777,
            ownerName: '',
            ownerPhonePrimary: '',
            ownerPhoneSecondary: '',
            ownerEmail: '',
            ownerAddress: '',
            ownerKycDocs: [],
            internalNotes: '',
            amenities: parseSafeStringList(item.amenities, ['Gym', 'Security', 'Lift']),
            images:
              item.images && item.images.length > 0
                ? parseSafeStringList(item.images)
                : ['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000'],
            floorPlans: [],
            videos: [],
            documents: [],
          });

          syncedList.push(created);
          createdCount++;
        }
      } catch (itemErr) {
        console.warn(`[Import] Skipping malformed property item: ${itemErr}`);
      }
    }

    const summaryMsg =
      updatedCount > 0
        ? `Successfully synced ${syncedList.length} properties (${createdCount} added, ${updatedCount} updated) from ${platform || 'feed'} into PostgreSQL!`
        : `Successfully imported ${syncedList.length} properties from ${platform || 'feed'} into PostgreSQL!`;

    // PRD Sec 18: Record Audit Log for Properties Synced
    AuditService.logAction({
      action: 'Properties Synced',
      target: `${platform || 'External'} Feed Sync (${syncedList.length} total, ${createdCount} new, ${updatedCount} updated)`,
      req,
      actorName: targetBrokerName,
      actorRole: 'Broker',
      details: { platform, count: syncedList.length, createdCount, updatedCount },
    }).catch(() => {});

    return successResponse(res, summaryMsg, syncedList, 201);
  } catch (error: any) {
    return errorResponse(res, 'Bulk property import failed', error.message || error);
  }
};

/**
 * Update Property Listing - 100% PostgreSQL
 */
export const updateProperty = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const property = await Property.findOne({
      where: {
        [Op.or]: [{ id: isNaN(Number(id)) ? 0 : Number(id) }, { propertyCode: id }],
      },
    });

    if (!property) {
      return errorResponse(res, 'Property not found', null, 404);
    }

    if (req.body.title) property.title = req.body.title;
    if (req.body.description !== undefined) property.description = req.body.description;
    if (req.body.location) property.location = req.body.location;
    if (req.body.price) property.price = req.body.price;
    if (req.body.bhk) property.bhk = req.body.bhk;
    if (req.body.type) {
      property.type = req.body.type;
      property.purpose = req.body.type;
    }
    if (req.body.purpose) {
      property.purpose = req.body.purpose;
      property.type = req.body.purpose;
    }
    if (req.body.propertyType) property.propertyType = req.body.propertyType;
    if (req.body.areaSqft !== undefined) property.areaSqft = parseFloat(req.body.areaSqft);
    if (req.body.builtUpArea !== undefined) property.builtUpArea = parseFloat(req.body.builtUpArea);
    if (req.body.carpetArea !== undefined) property.carpetArea = parseFloat(req.body.carpetArea);
    if (req.body.status) property.status = req.body.status;
    if (req.body.isPublic !== undefined) property.isPublic = Boolean(req.body.isPublic);
    if (req.body.bathrooms !== undefined) property.bathrooms = parseInt(req.body.bathrooms, 10);
    if (req.body.balcony !== undefined) property.balcony = parseInt(req.body.balcony, 10);
    if (req.body.parking !== undefined) property.parking = parseInt(req.body.parking, 10);
    if (req.body.furnishedStatus) property.furnishedStatus = req.body.furnishedStatus;
    if (req.body.propertyAge) property.propertyAge = req.body.propertyAge;
    if (req.body.maintenanceCharges !== undefined) property.maintenanceCharges = req.body.maintenanceCharges;
    if (req.body.securityDeposit !== undefined) property.securityDeposit = req.body.securityDeposit;
    if (req.body.negotiablePrice !== undefined) property.negotiablePrice = req.body.negotiablePrice;
    if (req.body.country) property.country = req.body.country;
    if (req.body.state) property.state = req.body.state;
    if (req.body.city) property.city = req.body.city;
    if (req.body.area) property.area = req.body.area;
    if (req.body.address) property.address = req.body.address;
    if (req.body.googleMapUrl !== undefined) property.googleMapUrl = req.body.googleMapUrl;
    if (req.body.latitude !== undefined) property.latitude = parseFloat(req.body.latitude);
    if (req.body.longitude !== undefined) property.longitude = parseFloat(req.body.longitude);
    if (req.body.ownerName !== undefined) property.ownerName = req.body.ownerName;
    if (req.body.ownerPhonePrimary !== undefined) property.ownerPhonePrimary = req.body.ownerPhonePrimary;
    if (req.body.ownerPhoneSecondary !== undefined) property.ownerPhoneSecondary = req.body.ownerPhoneSecondary;
    if (req.body.ownerEmail !== undefined) property.ownerEmail = req.body.ownerEmail;
    if (req.body.ownerAddress !== undefined) property.ownerAddress = req.body.ownerAddress;
    if (req.body.ownerKycDocs !== undefined) property.ownerKycDocs = req.body.ownerKycDocs;
    if (req.body.internalNotes !== undefined) property.internalNotes = req.body.internalNotes;
    if (req.body.amenities) property.amenities = req.body.amenities;
    if (req.body.images) property.images = req.body.images;
    if (req.body.floorPlans !== undefined) property.floorPlans = req.body.floorPlans;
    if (req.body.videos !== undefined) property.videos = req.body.videos;
    if (req.body.documents !== undefined) property.documents = req.body.documents;

    await property.save();

    // PRD Sec 18: Record Audit Log for Property Updated
    AuditService.logAction({
      action: 'Property Updated',
      target: `${property.title} (${property.propertyCode})`,
      req,
      actorName: property.brokerName,
      actorRole: 'Broker',
      details: { propertyId: property.id, status: property.status, price: property.price },
    }).catch(() => {});

    return successResponse(res, 'Property updated successfully in PostgreSQL', property);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update property', error.message || error);
  }
};

/**
 * Delete Property Listing - 100% PostgreSQL
 */
export const deleteProperty = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const property = await Property.findOne({
      where: {
        [Op.or]: [{ id: isNaN(Number(id)) ? 0 : Number(id) }, { propertyCode: id }],
      },
    });

    if (!property) {
      return errorResponse(res, 'Property not found', null, 404);
    }

    const propTitle = property.title;
    const propCode = property.propertyCode;
    const propId = property.id;
    const brokerName = property.brokerName;

    await property.destroy();

    // PRD Sec 18: Record Audit Log for Property Deleted
    AuditService.logAction({
      action: 'Property Deleted',
      target: `${propTitle} (${propCode})`,
      req,
      actorName: brokerName,
      actorRole: 'Broker',
      details: { propertyId: propId },
    }).catch(() => {});

    return successResponse(res, 'Property deleted successfully from PostgreSQL');
  } catch (error: any) {
    return errorResponse(res, 'Failed to delete property', error.message || error);
  }
};
