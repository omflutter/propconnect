import { Router } from 'express';
import {
  getBrokers,
  createBroker,
  updateBroker,
  updateBrokerStatus,
  deleteBroker,
} from '../controllers/broker.controller';

const router = Router();

/**
 * @openapi
 * /brokers:
 *   get:
 *     summary: List Platform Brokers
 *     tags:
 *       - Brokers
 *   post:
 *     summary: Onboard New Broker
 *     tags:
 *       - Brokers
 */
router.get('/brokers', getBrokers);
router.post('/brokers', createBroker);

/**
 * @openapi
 * /brokers/{id}:
 *   put:
 *     summary: Update Broker Details
 *     tags:
 *       - Brokers
 *   delete:
 *     summary: Delete Broker User
 *     tags:
 *       - Brokers
 */
router.put('/brokers/:id', updateBroker);
router.delete('/brokers/:id', deleteBroker);

/**
 * @openapi
 * /brokers/{id}/status:
 *   patch:
 *     summary: Update Broker Status
 *     tags:
 *       - Brokers
 */
router.patch('/brokers/:id/status', updateBrokerStatus);

export default router;
