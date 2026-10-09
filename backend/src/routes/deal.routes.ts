import { Router } from 'express';
import {
  getDeals,
  getDealById,
  createDeal,
  updateDealStatus,
  uploadDealDocument,
  deleteDealDocument,
  updateDealClient,
} from '../controllers/deal.controller';

const router = Router();

router.get('/deals', getDeals);
router.get('/deals/:id', getDealById);
router.post('/deals', createDeal);
router.put('/deals/:id/status', updateDealStatus);
router.put('/deals/:id/client', updateDealClient);
router.post('/deals/:id/documents', uploadDealDocument);
router.delete('/deals/:id/documents/:docId', deleteDealDocument);

export default router;
