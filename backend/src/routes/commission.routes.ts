import { Router } from 'express';
import {
  getCommissions,
  createCommission,
  updateCommission,
  getSettlements,
  createSettlement,
} from '../controllers/commission.controller';

const router = Router();

router.get('/commissions', getCommissions);
router.post('/commissions', createCommission);
router.put('/commissions/:id', updateCommission);

router.get('/settlements', getSettlements);
router.post('/settlements', createSettlement);
router.get('/commissions/settlements', getSettlements);
router.post('/commissions/settlements', createSettlement);

export default router;
