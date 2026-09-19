import { Router } from 'express';
import {
  getOwners,
  getOwnerById,
  createOwner,
  updateOwner,
  deleteOwner,
} from '../controllers/owner.controller';

const router = Router();

/**
 * @openapi
 * /owners:
 *   get:
 *     summary: List all Property Owners for Agency
 *     tags:
 *       - Owners
 *   post:
 *     summary: Create / Register a Property Owner
 *     tags:
 *       - Owners
 */
router.get('/', getOwners);
router.post('/', createOwner);

/**
 * @openapi
 * /owners/{id}:
 *   get:
 *     summary: Get Owner Details with Linked Properties
 *     tags:
 *       - Owners
 *   put:
 *     summary: Update Owner Information
 *     tags:
 *       - Owners
 *   delete:
 *     summary: Delete an Owner Record
 *     tags:
 *       - Owners
 */
router.get('/:id', getOwnerById);
router.put('/:id', updateOwner);
router.delete('/:id', deleteOwner);

export default router;
