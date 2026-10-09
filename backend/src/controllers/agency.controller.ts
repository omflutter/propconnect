import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { Agency } from '../models/agency.model';
import { User } from '../models/user.model';
import { Referral } from '../models/referral.model';
import { env } from '../config/env';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { AuditService } from '../services/audit.service';
import { NotificationService } from '../services/notification.service';

/**
 * Onboard / Register a New Agency (From App or Super Admin Panel) - 100% PostgreSQL
 */
export const createAgency = async (req: Request, res: Response) => {
  try {
    const {
      name,
      reraNumber,
      location,
      address,
      adminName,
      adminEmail,
      adminPhone,
      subscriptionTier,
      userQuota,
      password,
    } = req.body;

    if (!name || !name.trim()) {
      return errorResponse(res, 'Agency Name is required', null, 400);
    }

    // Check if this is a public user/agency registration
    const isPublicRegistration =
      req.originalUrl?.includes('/auth/register') ||
      req.path?.includes('/register') ||
      req.originalUrl?.includes('/create-profile');

    // Determine calling user from JWT header if present (only for authenticated routes, NOT registration)
    let authenticatedUserId: number | null = null;
    let authenticatedUserEmail: string | null = null;
    if (!isPublicRegistration) {
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        try {
          const decoded = jwt.verify(authHeader.split(' ')[1], env.JWT_SECRET) as any;
          authenticatedUserId = decoded.id;
          authenticatedUserEmail = decoded.email;
        } catch (_) {}
      }
    }

    const cleanEmail = (adminEmail && adminEmail.trim())
      ? adminEmail.trim().toLowerCase()
      : (authenticatedUserEmail ? authenticatedUserEmail.toLowerCase() : '');

    if (!cleanEmail) {
      return errorResponse(res, 'Admin / Agency contact email is required', null, 400);
    }

    // If this is a registration, enforce strict email uniqueness across all platform users
    if (isPublicRegistration) {
      const emailInUse = await User.findOne({ where: { email: cleanEmail } });
      if (emailInUse) {
        return errorResponse(
          res,
          `An account with email "${cleanEmail}" already exists. Please log in or use a different email.`,
          null,
          400
        );
      }
    }

    // Check if an existing authenticated user is explicitly creating this agency (non-registration flow)
    let existingUser: User | null = null;
    if (authenticatedUserId && !isPublicRegistration) {
      existingUser = await User.findByPk(authenticatedUserId);
    }

    const totalAgencies = await Agency.count();
    const agencyCode = `AG-${String(totalAgencies + 1).padStart(3, '0')}`;

    const incomingRefCode = (req.body.referralCode || req.body.referredByCode || '').toString().trim().toUpperCase();
    let referringAgency: Agency | null = null;
    let initialCoins = 100; // Default starter bonus for new agencies
    let referredById: number | null = null;

    if (incomingRefCode) {
      referringAgency = await Agency.findOne({
        where: {
          [Op.or]: [
            { referralCode: incomingRefCode },
            { agencyCode: incomingRefCode },
            { referralCode: incomingRefCode.replace('PROP-', '') },
            { agencyCode: incomingRefCode.replace('PROP-', '') },
          ],
        },
      });

      if (referringAgency) {
        referredById = referringAgency.id;
        initialCoins = 500; // Boosted 500 PropCoins welcome bonus for joining via referral
      }
    }

    const agency = await Agency.create({
      agencyCode,
      referralCode: agencyCode,
      coinsBalance: initialCoins,
      referredByAgencyId: referredById,
      referralCount: 0,
      name: name.trim(),
      reraNumber: (reraNumber && reraNumber.trim()) ? reraNumber.trim() : '',
      location: (location && location.trim()) ? location.trim() : 'Mumbai',
      address: (address && address.trim()) ? address.trim() : '',
      pincode: (req.body.pincode && String(req.body.pincode).trim()) ? String(req.body.pincode).trim() : '',
      adminName: (adminName && adminName.trim()) ? adminName.trim() : (existingUser?.name || 'Agency Admin'),
      adminEmail: cleanEmail,
      adminPhone: (adminPhone && adminPhone.trim()) ? adminPhone.trim() : (existingUser?.phone || ''),
      subscriptionTier: subscriptionTier || 'Pro (₹5,999/mo)',
      userQuota: userQuota ? parseInt(userQuota, 10) : 10,
      propertiesCount: 0,
      dealsCount: 0,
      status: 'Active',
    });

    // Award referrer agency 1,000 PropCoins
    if (referringAgency) {
      try {
        referringAgency.coinsBalance = (referringAgency.coinsBalance || 0) + 1000;
        referringAgency.referralCount = (referringAgency.referralCount || 0) + 1;
        await referringAgency.save();

        await Referral.create({
          referrerAgencyId: referringAgency.id,
          referredAgencyId: agency.id,
          referralCode: incomingRefCode,
          coinsEarned: 1000,
          status: 'Completed',
        });

        NotificationService.createAndSendNotification({
          userId: referringAgency.id,
          agencyId: referringAgency.id,
          title: '🎉 1,000 PropCoins Credited!',
          message: `Agency "${agency.name}" joined using your referral code (${incomingRefCode}). 1,000 PropCoins added to your balance!`,
          type: 'subscription',
        }).catch(() => {});
      } catch (refErr) {
        console.warn('[Referral Reward Note]', refErr);
      }
    }

    // PRD Sec 18: Record Audit Log for Subscription Purchased on Agency Onboard
    AuditService.logAction({
      action: 'Subscription Purchased',
      target: `${agency.name} (${agency.subscriptionTier})`,
      req,
      actorName: agency.adminName,
      actorRole: 'Agency Admin',
      details: { agencyId: agency.id, tier: agency.subscriptionTier, quota: agency.userQuota, referralCode: incomingRefCode || null },
    }).catch(() => {});

    if (existingUser) {
      // In-App Registration: Promote current user to agency_admin and associate with new Agency
      const updateData: any = {
        agencyId: agency.id,
        role: 'agency_admin',
        name: (adminName && adminName.trim()) ? adminName.trim() : existingUser.name,
        phone: (adminPhone && adminPhone.trim()) ? adminPhone.trim() : existingUser.phone,
      };
      if (password && password.trim()) {
        const salt = await bcrypt.genSalt(10);
        updateData.password = await bcrypt.hash(password.trim(), salt);
      }
      await existingUser.update(updateData);

      // Generate refreshed JWT session token
      const freshToken = jwt.sign(
        {
          id: existingUser.id,
          email: existingUser.email,
          role: 'agency_admin',
          agencyId: agency.id,
        },
        env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      return successResponse(
        res,
        `Agency "${agency.name}" (${agency.agencyCode}) successfully registered!`,
        {
          agency,
          token: freshToken,
          user: {
            id: existingUser.id,
            name: existingUser.name,
            email: existingUser.email,
            phone: existingUser.phone,
            role: 'agency_admin',
            agencyId: agency.id,
            agency: {
              id: agency.id,
              agencyCode: agency.agencyCode,
              name: agency.name,
              reraNumber: agency.reraNumber,
              location: agency.location,
              address: agency.address,
              email: agency.adminEmail,
            },
          },
        },
        201
      );
    } else {
      // Provision brand new agency admin credentials
      const initialPassword = password && password.trim() ? password.trim() : 'agency123';
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(initialPassword, salt);

      const adminUser = await User.create({
        name: (adminName && adminName.trim()) ? adminName.trim() : 'Agency Admin',
        email: cleanEmail,
        password: hashedPassword,
        phone: (adminPhone && adminPhone.trim()) ? adminPhone.trim() : '',
        role: 'agency_admin',
        agencyId: agency.id,
        status: 'Active',
      });

      const token = jwt.sign(
        {
          id: adminUser.id,
          email: adminUser.email,
          role: 'agency_admin',
          agencyId: agency.id,
        },
        env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      return successResponse(
        res,
        `Agency "${name}" successfully registered in PostgreSQL!`,
        {
          agency,
          token,
          user: {
            id: adminUser.id,
            name: adminUser.name,
            email: adminUser.email,
            phone: adminUser.phone,
            role: adminUser.role,
            agencyId: agency.id,
            agency: {
              id: agency.id,
              agencyCode: agency.agencyCode,
              name: agency.name,
              reraNumber: agency.reraNumber,
              location: agency.location,
              address: agency.address,
              email: agency.adminEmail,
            },
          },
          credentials: {
            agencyCode: agency.agencyCode,
            adminEmail: agency.adminEmail,
            adminName: agency.adminName,
            password: initialPassword,
            loginUrl: 'https://propconnect-b89bd.web.app/login',
          },
          adminUser: {
            id: adminUser.id,
            name: adminUser.name,
            email: adminUser.email,
            role: adminUser.role,
          },
        },
        201
      );
    }
  } catch (error: any) {
    return errorResponse(res, 'Failed to onboard agency', error.message || error);
  }
};

/**
 * List all agencies with filtering & search - 100% PostgreSQL
 */
export const getAgencies = async (req: Request, res: Response) => {
  try {
    const { status, search } = req.query;

    const whereClause: any = {};
    if (status && status !== 'All') {
      whereClause.status = status;
    }

    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { location: { [Op.iLike]: `%${search}%` } },
        { adminName: { [Op.iLike]: `%${search}%` } },
        { agencyCode: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const agencies = await Agency.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
    });

    return successResponse(res, 'Agencies retrieved successfully from PostgreSQL', agencies);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch agencies', error.message || error);
  }
};

/**
 * Get single agency by ID with users and broker count - 100% PostgreSQL
 */
export const getAgencyById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const agency = await Agency.findByPk(id, {
      include: [{ model: User, as: 'users', attributes: { exclude: ['password'] } }],
    });

    if (!agency) {
      return errorResponse(res, 'Agency not found', null, 404);
    }

    const usersList = (agency as any).users || [];
    const brokersCount = usersList.filter((u: any) => u.role === 'broker').length;

    const result = {
      ...agency.toJSON(),
      brokersCount,
      users: usersList,
    };

    return successResponse(res, 'Agency details fetched from PostgreSQL', result);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch agency details', error.message || error);
  }
};

/**
 * Update Agency Details - 100% PostgreSQL
 */
export const updateAgency = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const agency = await Agency.findByPk(id);
    if (!agency) {
      return errorResponse(res, 'Agency not found', null, 404);
    }

    if (req.body.name) agency.name = req.body.name;
    if (req.body.reraNumber !== undefined) agency.reraNumber = req.body.reraNumber;
    if (req.body.location) agency.location = req.body.location;
    if (req.body.address !== undefined) agency.address = req.body.address;
    if (req.body.pincode !== undefined) agency.pincode = req.body.pincode;
    if (req.body.adminName) agency.adminName = req.body.adminName;
    if (req.body.adminEmail) agency.adminEmail = req.body.adminEmail;
    if (req.body.adminPhone !== undefined) agency.adminPhone = req.body.adminPhone;
    const oldTier = agency.subscriptionTier;
    if (req.body.subscriptionTier) agency.subscriptionTier = req.body.subscriptionTier;
    if (req.body.userQuota !== undefined) agency.userQuota = parseInt(req.body.userQuota, 10);
    if (req.body.status && ['Active', 'Pending', 'Suspended'].includes(req.body.status)) agency.status = req.body.status;

    await agency.save();

    // PRD Sec 18: Record Audit Log for Subscription Purchased if tier changed
    if (req.body.subscriptionTier && req.body.subscriptionTier !== oldTier) {
      AuditService.logAction({
        action: 'Subscription Purchased',
        target: `${agency.name} upgraded from ${oldTier} to ${req.body.subscriptionTier}`,
        req,
        actorName: agency.adminName,
        actorRole: 'Agency Admin',
        details: { agencyId: agency.id, oldTier, newTier: req.body.subscriptionTier },
      }).catch(() => {});
    }

    return successResponse(res, 'Agency updated successfully in PostgreSQL', agency);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update agency', error.message || error);
  }
};

/**
 * Update Agency status (Active / Suspended / Pending) - 100% PostgreSQL
 */
export const updateAgencyStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['Active', 'Pending', 'Suspended'].includes(status)) {
      return errorResponse(res, 'Valid status is required (Active, Pending, Suspended)', null, 400);
    }

    const agency = await Agency.findByPk(id);
    if (!agency) {
      return errorResponse(res, 'Agency not found', null, 404);
    }

    agency.status = status;
    await agency.save();
    return successResponse(res, `Agency status updated to ${status} in PostgreSQL`, agency);
  } catch (error: any) {
    return errorResponse(res, 'Failed to update agency status', error.message || error);
  }
};

/**
 * Delete Agency - 100% PostgreSQL
 */
export const deleteAgency = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const agency = await Agency.findByPk(id);
    if (!agency) {
      return errorResponse(res, 'Agency not found', null, 404);
    }

    await agency.destroy();
    return successResponse(res, `Agency "${agency.name}" has been deleted from PostgreSQL.`);
  } catch (error: any) {
    return errorResponse(res, 'Failed to delete agency', error.message || error);
  }
};

/**
 * Fetch Agency Referral Stats, PropCoins Balance & History - 100% PostgreSQL
 */
export const getAgencyReferralStats = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const agency = await Agency.findByPk(id);
    if (!agency) {
      return errorResponse(res, 'Agency not found', null, 404);
    }

    const referralCode = agency.referralCode || agency.agencyCode;
    const coinsBalance = agency.coinsBalance || 0;
    const referralCount = agency.referralCount || 0;

    // Fetch referred agencies details
    const referrals = await Referral.findAll({
      where: { referrerAgencyId: agency.id },
      order: [['createdAt', 'DESC']],
    });

    const referredAgencyIds = referrals.map((r) => r.referredAgencyId);
    let agencyMap = new Map<number, any>();
    if (referredAgencyIds.length > 0) {
      const referredAgencies = await Agency.findAll({
        where: { id: { [Op.in]: referredAgencyIds } },
        attributes: ['id', 'agencyCode', 'name', 'location', 'createdAt', 'status'],
      });
      agencyMap = new Map(referredAgencies.map((a) => [a.id, a]));
    }

    const history = referrals.map((r) => {
      const refAgency = agencyMap.get(r.referredAgencyId);
      return {
        id: r.id,
        referredAgencyId: r.referredAgencyId,
        referredAgencyName: refAgency ? refAgency.name : 'Partner Agency',
        referredAgencyCode: refAgency ? refAgency.agencyCode : '',
        coinsEarned: r.coinsEarned,
        status: r.status,
        createdAt: r.createdAt,
      };
    });

    return successResponse(res, 'Referral stats fetched successfully', {
      referralCode,
      coinsBalance,
      referralCount,
      coinValueInr: 1, // 1 PropCoin = ₹1 INR
      referrals: history,
    });
  } catch (err: any) {
    return errorResponse(res, 'Failed to fetch referral stats', err.message || err);
  }
};

/**
 * Redeem PropCoins for Membership / SaaS Subscription - 100% PostgreSQL
 */
export const redeemAgencyCoins = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { coinsToRedeem, targetTier } = req.body;

    const agency = await Agency.findByPk(id);
    if (!agency) {
      return errorResponse(res, 'Agency not found', null, 404);
    }

    const currentBalance = agency.coinsBalance || 0;
    const coins = parseInt(String(coinsToRedeem || 0), 10);

    if (isNaN(coins) || coins <= 0) {
      return errorResponse(res, 'Invalid coins amount to redeem', null, 400);
    }

    if (coins > currentBalance) {
      return errorResponse(
        res,
        `Insufficient coins. Available balance is ${currentBalance} PropCoins.`,
        null,
        400
      );
    }

    agency.coinsBalance = currentBalance - coins;
    if (targetTier) {
      agency.subscriptionTier = targetTier;
    }
    await agency.save();

    AuditService.logAction({
      action: 'Coins Redeemed for Subscription',
      target: `Agency ${agency.name} redeemed ${coins} PropCoins`,
      req,
      actorName: agency.adminName,
      actorRole: 'Agency Admin',
      details: {
        agencyId: agency.id,
        coinsRedeemed: coins,
        targetTier: targetTier || agency.subscriptionTier,
        remainingBalance: agency.coinsBalance,
      },
    }).catch(() => {});

    return successResponse(res, `Successfully redeemed ${coins} PropCoins for membership upgrade!`, {
      agencyId: agency.id,
      coinsRedeemed: coins,
      remainingCoins: agency.coinsBalance,
      subscriptionTier: agency.subscriptionTier,
    });
  } catch (err: any) {
    return errorResponse(res, 'Failed to redeem coins', err.message || err);
  }
};

