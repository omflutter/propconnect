import { Request, Response } from 'express';
import { successResponse } from '../utils/apiResponse';
import { sequelize } from '../config/database';

export const checkHealth = async (req: Request, res: Response) => {
  let dbStatus = 'disconnected';
  try {
    await sequelize.authenticate();
    dbStatus = 'connected';
  } catch (err) {
    dbStatus = 'error';
  }

  const healthData = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: `${Math.floor(process.uptime())}s`,
    database: {
      type: 'MySQL',
      status: dbStatus,
    },
  };

  return successResponse(res, 'PropConnect backend service is healthy', healthData);
};
