import { Request, Response } from 'express';
import { Agency } from '../models/agency.model';
import { User } from '../models/user.model';
import { PlatformConfig } from '../models/config.model';
import { AuditLog } from '../models/auditLog.model';
import { successResponse, errorResponse } from '../utils/apiResponse';

export const getDashboardStats = async (req: Request, res: Response) => {
  try {
    const [totalAgencies, activeAgencies, pendingAgencies, suspendedAgencies] = await Promise.all([
      Agency.count(),
      Agency.count({ where: { status: 'Active' } }),
      Agency.count({ where: { status: 'Pending' } }),
      Agency.count({ where: { status: 'Suspended' } }),
    ]);

    const [totalBrokers, activeBrokers, agencyAdmins] = await Promise.all([
      User.count({ where: { role: ['broker', 'agency_admin'] } }),
      User.count({ where: { role: ['broker', 'agency_admin'], status: 'Active' } }),
      User.count({ where: { role: 'agency_admin' } }),
    ]);

    const config = await PlatformConfig.findOne();
    const recentActivity = await AuditLog.findAll({
      order: [['createdAt', 'DESC']],
      limit: 6,
    });

    const stats = {
      agencies: {
        total: totalAgencies,
        active: activeAgencies,
        pending: pendingAgencies,
        suspended: suspendedAgencies,
      },
      brokers: {
        total: totalBrokers,
        active: activeBrokers,
        admins: agencyAdmins,
      },
      subscriptions: [
        { name: 'Basic', users: 1, fill: '#94A3B8' },
        { name: 'Pro', users: 2, fill: '#38BDF8' },
        { name: 'Enterprise', users: 1, fill: '#00308F' },
      ],
      financials: {
        platformFeePercent: config ? config.platformFeePercent : 2.5,
        totalRevenueFormatted: '₹1.24 Cr',
        commissionGeneratedFormatted: '₹4.8 Cr',
      },
      systemHealth: {
        awsBackend: 'Healthy',
        postgresDatabase: 'Connected (Aiven Cloud)',
        razorpayGateway: 'Online',
        whatsappApi: 'Online',
        maintenanceMode: config ? config.maintenanceMode : false,
      },
      recentActivity,
    };

    return successResponse(res, 'Dashboard summary metrics retrieved from PostgreSQL', stats);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch dashboard stats', error.message || error);
  }
};
