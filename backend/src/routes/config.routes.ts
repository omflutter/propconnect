import { Router } from 'express';
import {
  getConfig,
  updatePolicies,
  getGateways,
  updateGateways,
  getAdminTeam,
  createAdminMember,
  updateAdminMember,
  deleteAdminMember,
  updateAdminProfile,
} from '../controllers/config.controller';

const router = Router();

router.get('/config', getConfig);
router.put('/config/policies', updatePolicies);

router.get('/config/gateways', getGateways);
router.put('/config/gateways', updateGateways);

router.get('/config/admins', getAdminTeam);
router.post('/config/admins', createAdminMember);
router.put('/config/admins/:id', updateAdminMember);
router.delete('/config/admins/:id', deleteAdminMember);

router.put('/config/profile', updateAdminProfile);

export default router;
