import { Router } from 'express';
import { uploadMultipart, uploadBase64, multerUpload } from '../controllers/upload.controller';

const router = Router();

// Multipart File Upload (single file 'file' or multiple files 'files')
router.post('/', multerUpload.array('files', 15), uploadMultipart);
router.post('/single', multerUpload.single('file'), uploadMultipart);

// Base64 JSON Upload (single or array of base64 strings)
router.post('/base64', uploadBase64);

export default router;
