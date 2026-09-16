import { Router } from 'express';
import {
  createCollaboration,
  getCollaborations,
  respondCollaboration,
} from '../controllers/collaboration.controller';

const router = Router();

router.post('/collaborations', createCollaboration);
router.get('/collaborations', getCollaborations);
router.put('/collaborations/:id/respond', respondCollaboration);

export default router;
