import { Request, Response } from 'express';
import { WhatsAppService } from '../services/whatsapp.service';
import { successResponse, errorResponse } from '../utils/apiResponse';
import { WhatsAppLog } from '../models/whatsappLog.model';

/**
 * Get WhatsApp API connection status and metrics
 */
export const getWhatsAppStatus = async (_req: Request, res: Response) => {
  try {
    const status = await WhatsAppService.getConnectionStatus();
    return successResponse(res, 'WhatsApp connection status retrieved', status);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch WhatsApp status', error.message || error, 500);
  }
};

/**
 * Get outbound WhatsApp logs with filters
 */
export const getWhatsAppLogs = async (req: Request, res: Response) => {
  try {
    const { status, search, limit, offset } = req.query;

    const result = await WhatsAppService.getLogs({
      status: status ? String(status) : undefined,
      search: search ? String(search) : undefined,
      limit: limit ? parseInt(String(limit), 10) : 50,
      offset: offset ? parseInt(String(offset), 10) : 0,
    });

    return successResponse(res, 'WhatsApp logs retrieved successfully', result);
  } catch (error: any) {
    return errorResponse(res, 'Failed to fetch WhatsApp logs', error.message || error, 500);
  }
};

/**
 * Send a test WhatsApp message to verify connection
 */
export const sendTestWhatsAppMessage = async (req: Request, res: Response) => {
  try {
    const { phoneNumber, message, templateName } = req.body;

    if (!phoneNumber) {
      return errorResponse(res, 'Phone number is required', null, 400);
    }

    const { log, directWhatsAppUrl } = await WhatsAppService.sendTestMessage(phoneNumber, message, templateName);

    if (log.status === 'Failed') {
      return res.status(200).json({
        success: false,
        message: log.errorMessage || 'Interakt rejected template delivery. Meta requires pre-approved templates.',
        data: {
          ...(log.toJSON() as Record<string, any>),
          directWhatsAppUrl,
        },
        directWhatsAppUrl,
        error: log.errorMessage,
      });
    }

    return successResponse(res, `Test WhatsApp message sent to ${phoneNumber}`, {
      ...(log.toJSON() as Record<string, any>),
      directWhatsAppUrl,
    });
  } catch (error: any) {
    return errorResponse(res, 'Failed to send test WhatsApp message', error.message || error, 500);
  }
};

/**
 * Send a Property Brochure to Client WhatsApp
 */
export const sendPropertyBrochure = async (req: Request, res: Response) => {
  try {
    const {
      recipientPhone,
      clientName,
      propertyName,
      propertyPrice,
      propertyLocation,
      bhk,
      carpetArea,
      brochureUrl,
    } = req.body;

    if (!recipientPhone || !propertyName) {
      return errorResponse(res, 'Recipient phone and property name are required', null, 400);
    }

    const { log, directWhatsAppUrl } = await WhatsAppService.sendPropertyBrochure({
      recipientPhone,
      clientName,
      propertyName,
      propertyPrice: propertyPrice || 'Price on Request',
      propertyLocation: propertyLocation || 'Prime Location',
      bhk,
      carpetArea,
      brochureUrl,
    });

    if (log.status === 'Failed') {
      return res.status(200).json({
        success: false,
        message: log.errorMessage || 'Interakt rejected template delivery.',
        data: {
          ...(log.toJSON() as Record<string, any>),
          directWhatsAppUrl,
        },
        directWhatsAppUrl,
        error: log.errorMessage,
      });
    }

    return successResponse(res, `Property brochure sent to ${recipientPhone} via WhatsApp`, {
      ...(log.toJSON() as Record<string, any>),
      directWhatsAppUrl,
    });
  } catch (error: any) {
    return errorResponse(res, 'Failed to send property brochure', error.message || error, 500);
  }
};

/**
 * Resend a message from logs
 */
export const resendWhatsAppMessage = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const result = await WhatsAppService.resendMessage(id);

    if (!result) {
      return errorResponse(res, `Message log ${id} not found`, null, 404);
    }

    if (result.log.status === 'Failed') {
      return res.status(200).json({
        success: false,
        message: result.log.errorMessage || 'Resend rejected by Interakt/Meta',
        data: {
          ...(result.log.toJSON() as Record<string, any>),
          directWhatsAppUrl: result.directWhatsAppUrl,
        },
        directWhatsAppUrl: result.directWhatsAppUrl,
        error: result.log.errorMessage,
      });
    }

    return successResponse(res, `Message ${id} resent successfully`, {
      ...(result.log.toJSON() as Record<string, any>),
      directWhatsAppUrl: result.directWhatsAppUrl,
    });
  } catch (error: any) {
    return errorResponse(res, 'Failed to resend message', error.message || error, 500);
  }
};

/**
 * Handle Interakt Webhook updates (message delivered, read, failed)
 */
export const handleInteraktWebhook = async (req: Request, res: Response) => {
  try {
    const payload = req.body;
    console.log('[Interakt Webhook Received]:', JSON.stringify(payload));

    const messageId = payload?.data?.message?.id || payload?.id;
    const eventType = payload?.type || payload?.event;

    if (messageId && eventType) {
      let status: 'Sent' | 'Delivered' | 'Read' | 'Failed' | null = null;
      if (eventType.includes('delivered')) status = 'Delivered';
      if (eventType.includes('read') || eventType.includes('seen')) status = 'Read';
      if (eventType.includes('failed')) status = 'Failed';

      if (status) {
        await WhatsAppLog.update(
          { status },
          {
            where: {
              interaktId: messageId,
            },
          }
        );
      }
    }

    return res.status(200).json({ status: 'ok', received: true });
  } catch (error: any) {
    console.error('[Interakt Webhook Error]', error);
    return res.status(200).json({ status: 'ignored', error: error.message });
  }
};
