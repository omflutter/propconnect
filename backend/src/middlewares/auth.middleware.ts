import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { errorResponse } from '../utils/apiResponse';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: number;
    email: string;
    role: 'super_admin' | 'agency_admin' | 'broker';
    agencyId?: number | null;
  };
}

export const authenticateJwt = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse(res, 'Authorization token missing or invalid format', null, 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as any;
    req.user = decoded;
    next();
  } catch (error) {
    return errorResponse(res, 'Invalid or expired authentication token', null, 401);
  }
};

export const requireRole = (roles: Array<'super_admin' | 'agency_admin' | 'broker'>) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return errorResponse(res, 'Unauthorized access', null, 401);
    }

    if (!roles.includes(req.user.role)) {
      return errorResponse(res, 'Forbidden: Insufficient permissions for this resource', null, 403);
    }

    next();
  };
};
