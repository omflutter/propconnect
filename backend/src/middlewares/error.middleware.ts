import { Request, Response, NextFunction } from 'express';
import { errorResponse } from '../utils/apiResponse';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error('[Error Handler]', err);

  const statusCode = err.statusCode || err.status || 500;
  const message = err.message || 'Internal Server Error';

  return errorResponse(res, message, err.stack || err, statusCode);
};

export const notFoundHandler = (req: Request, res: Response) => {
  return errorResponse(
    res,
    `Route ${req.method} ${req.originalUrl} not found`,
    null,
    404
  );
};
