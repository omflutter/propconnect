import { Router } from 'express';
import { getDeals, getDealById, createDeal, updateDealStatus } from '../controllers/deal.controller';

const router = Router();

router.get('/deals', getDeals);
router.get('/deals/:id', getDealById);
router.post('/deals', createDeal);
router.put('/deals/:id/status', updateDealStatus);

export default router;
