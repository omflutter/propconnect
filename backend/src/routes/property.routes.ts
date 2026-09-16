import { Router } from 'express';
import {
  getProperties,
  getPropertyById,
  createProperty,
  importProperties,
  updateProperty,
  deleteProperty,
} from '../controllers/property.controller';

const router = Router();

/**
 * @openapi
 * /properties:
 *   get:
 *     summary: List Property Inventory Listings
 *     description: Retrieve all properties with optional filtering by agencyId, search, type (Sale/Rent), propertyType, and status.
 *     tags:
 *       - Properties
 */
router.get('/', getProperties);
router.post('/', createProperty);

/**
 * @openapi
 * /properties/import:
 *   post:
 *     summary: Bulk Import Properties from 99acres, MagicBricks, Housing.com
 *     description: Import listings in bulk from partner broker portals directly into PostgreSQL.
 *     tags:
 *       - Properties
 */
router.post('/import', importProperties);

/**
 * @openapi
 * /properties/{id}:
 *   get:
 *     summary: Get Property Details by ID or Code
 *     tags:
 *       - Properties
 */
router.get('/:id', getPropertyById);
router.put('/:id', updateProperty);
router.delete('/:id', deleteProperty);

export default router;
