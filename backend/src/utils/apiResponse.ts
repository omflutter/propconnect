import { Response } from 'express';

export interface ApiResponsePayload<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: any;
}

export const successResponse = <T>(
  res: Response,
  message: string,
  data?: T,
  statusCode: number = 200
): Response => {
  const payload: ApiResponsePayload<T> = {
    success: true,
    message,
    data,
  };
  return res.status(statusCode).json(payload);
};

export const errorResponse = (
  res: Response,
  message: string,
  error: any = null,
  statusCode: number = 500
): Response => {
  const payload: ApiResponsePayload = {
    success: false,
    message,
    error: error instanceof Error ? error.message : error,
  };
  return res.status(statusCode).json(payload);
};
