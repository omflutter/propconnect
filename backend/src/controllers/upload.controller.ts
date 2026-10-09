import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import multer from 'multer';
import { successResponse, errorResponse } from '../utils/apiResponse';

// Ensure uploads directory exists
const UPLOADS_DIR = path.resolve(__dirname, '../../uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Configure Multer Disk Storage
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, UPLOADS_DIR);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    const cleanBase = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9]/g, '_').substring(0, 30);
    const uniqueSuffix = `${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    cb(null, `prop_${cleanBase}_${uniqueSuffix}${ext}`);
  },
});

export const multerUpload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB max per file
  fileFilter: (_req, file, cb) => {
    if (
      file.mimetype.startsWith('image/') ||
      file.mimetype === 'application/pdf' ||
      file.mimetype.includes('pdf') ||
      file.mimetype.includes('word') ||
      file.mimetype.includes('document') ||
      file.mimetype.includes('text')
    ) {
      cb(null, true);
    } else {
      cb(new Error('Only images, PDFs, and document files are allowed.'));
    }
  },
});

const buildFileUrl = (req: Request, filename: string): string => {
  const protocol = req.headers['x-forwarded-proto'] || req.protocol || 'http';
  const host = req.headers['x-forwarded-host'] || req.headers.host || '72.61.229.6:5000';
  return `${protocol}://${host}/uploads/${filename}`;
};

/**
 * Upload Multipart File(s) Handler
 */
export const uploadMultipart = async (req: Request, res: Response) => {
  try {
    const files = req.files as Express.Multer.File[] | undefined;
    const file = req.file as Express.Multer.File | undefined;

    if (!file && (!files || files.length === 0)) {
      return errorResponse(res, 'No image file uploaded', null, 400);
    }

    if (file) {
      const url = buildFileUrl(req, file.filename);
      return successResponse(res, 'Image uploaded successfully', {
        url,
        filename: file.filename,
        size: file.size,
        mimetype: file.mimetype,
      });
    }

    if (files && files.length > 0) {
      const uploaded = files.map(f => ({
        url: buildFileUrl(req, f.filename),
        filename: f.filename,
        size: f.size,
        mimetype: f.mimetype,
      }));
      return successResponse(res, `${files.length} images uploaded successfully`, {
        urls: uploaded.map(u => u.url),
        files: uploaded,
      });
    }
  } catch (error: any) {
    return errorResponse(res, 'File upload failed', error.message || error, 500);
  }
};

/**
 * Upload Base64 Image(s) Handler
 * Accepts:
 * { "image": "data:image/jpeg;base64,...", "filename": "photo.jpg" }
 * OR
 * { "images": ["data:image/jpeg;base64,...", ...] }
 */
export const uploadBase64 = async (req: Request, res: Response) => {
  try {
    const rawSingle = req.body.image || req.body.document || req.body.file;
    const rawMultiple = req.body.images || req.body.documents || req.body.files;
    const customName = req.body.filename || req.body.title || req.body.name;

    if (!rawSingle && (!rawMultiple || !Array.isArray(rawMultiple) || rawMultiple.length === 0)) {
      return errorResponse(res, 'File or image base64 payload is required', null, 400);
    }

    const processBase64String = (b64: string, name?: string): { url: string; filename: string; mimeType: string } => {
      let mimeType = 'image/jpeg';
      let cleanData = b64;

      if (b64.startsWith('data:')) {
        const matches = b64.match(/^data:([A-Za-z-+\/0-9.]+);base64,(.+)$/);
        if (matches && matches.length === 3) {
          mimeType = matches[1];
          cleanData = matches[2];
        }
      }

      let ext = '.jpg';
      const mLower = mimeType.toLowerCase();
      if (mLower.includes('pdf')) ext = '.pdf';
      else if (mLower.includes('png')) ext = '.png';
      else if (mLower.includes('webp')) ext = '.webp';
      else if (mLower.includes('gif')) ext = '.gif';
      else if (mLower.includes('word') || mLower.includes('document') || mLower.includes('docx')) ext = '.docx';
      else if (mLower.includes('doc')) ext = '.doc';
      else if (mLower.includes('text') || mLower.includes('plain')) ext = '.txt';

      const prefix = name ? name.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 30) : 'doc';
      const uniqueFilename = `${prefix}_${Date.now()}_${Math.random().toString(36).substring(2, 8)}${ext}`;
      const filePath = path.join(UPLOADS_DIR, uniqueFilename);

      const buffer = Buffer.from(cleanData, 'base64');
      fs.writeFileSync(filePath, buffer);

      return {
        url: buildFileUrl(req, uniqueFilename),
        filename: uniqueFilename,
        mimeType,
      };
    };

    // Single item
    if (rawSingle) {
      const result = processBase64String(rawSingle, customName);
      return successResponse(res, 'File uploaded successfully', result, 201);
    }

    // Multiple items
    if (Array.isArray(rawMultiple)) {
      const results = rawMultiple.map((b64Item: string, idx: number) => 
        processBase64String(b64Item, customName ? `${customName}_${idx + 1}` : `file_${idx + 1}`)
      );
      return successResponse(res, `${results.length} files uploaded successfully`, {
        urls: results.map(r => r.url),
        files: results,
      }, 201);
    }
  } catch (error: any) {
    return errorResponse(res, 'Base64 file upload failed', error.message || error, 500);
  }
};
