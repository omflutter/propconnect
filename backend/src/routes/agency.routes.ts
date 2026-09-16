import { Router } from 'express';
import {
  createAgency,
  getAgencies,
  getAgencyById,
  updateAgency,
  updateAgencyStatus,
  deleteAgency,
} from '../controllers/agency.controller';

const router = Router();

/**
 * @openapi
 * /agencies:
 *   post:
 *     summary: Register / Onboard New Agency
 *     description: Admin endpoint to onboard a new multi-tenant real estate agency and automatically provision an Agency Admin user account.
 *     tags:
 *       - Agencies Matrix
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - adminName
 *               - adminEmail
 *             properties:
 *               name:
 *                 type: string
 *                 example: Skyline Realty
 *               reraNumber:
 *                 type: string
 *                 example: PRM/KA/RERA/1251/310/PR/171015/000456
 *               location:
 *                 type: string
 *                 example: Mumbai
 *               address:
 *                 type: string
 *                 example: Bandra West, Mumbai
 *               adminName:
 *                 type: string
 *                 example: Vikram Malhotra
 *               adminEmail:
 *                 type: string
 *                 example: vikram@skyline.in
 *               adminPhone:
 *                 type: string
 *                 example: +91 98765 12345
 *               subscriptionTier:
 *                 type: string
 *                 example: Pro (₹5,999/mo)
 *               userQuota:
 *                 type: integer
 *                 example: 10
 *     responses:
 *       201:
 *         description: Agency registered successfully.
 * 
 *   get:
 *     summary: List All Agencies
 *     description: Retrieve all onboarded agencies with optional status tab and search query filtering.
 *     tags:
 *       - Agencies Matrix
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [All, Active, Pending, Suspended]
 *         description: Filter by status
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by agency name, location, or admin
 *     responses:
 *       200:
 *         description: List of agencies.
 */
router.post('/agencies', createAgency);
router.post('/agencies/create-profile', createAgency);
router.get('/agencies', getAgencies);

/**
 * @openapi
 * /agencies/{id}:
 *   get:
 *     summary: Get Agency Profile Details
 *     description: Fetch detailed agency profile including associated brokers and users.
 *     tags:
 *       - Agencies Matrix
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Agency detail object.
 *       404:
 *         description: Agency not found.
 * 
 *   put:
 *     summary: Update Agency Profile
 *     description: Update existing agency profile information.
 *     tags:
 *       - Agencies Matrix
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               reraNumber:
 *                 type: string
 *               location:
 *                 type: string
 *               address:
 *                 type: string
 *               adminName:
 *                 type: string
 *               adminEmail:
 *                 type: string
 *               adminPhone:
 *                 type: string
 *               subscriptionTier:
 *                 type: string
 *               userQuota:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Agency updated.
 * 
 *   delete:
 *     summary: Delete Agency
 *     description: Remove an agency from the system.
 *     tags:
 *       - Agencies Matrix
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Agency deleted.
 */
router.get('/agencies/:id', getAgencyById);
router.put('/agencies/:id', updateAgency);
router.delete('/agencies/:id', deleteAgency);

/**
 * @openapi
 * /agencies/{id}/status:
 *   patch:
 *     summary: Update Agency Status
 *     description: Approve, suspend, or update status of an agency.
 *     tags:
 *       - Agencies Matrix
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [Active, Pending, Suspended]
 *     responses:
 *       200:
 *         description: Agency status updated.
 */
router.patch('/agencies/:id/status', updateAgencyStatus);

export default router;
