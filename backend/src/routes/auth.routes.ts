import { Router } from 'express';
import { adminLogin, loginUser, logoutUser, getCurrentUser, updateUserProfile, changePassword } from '../controllers/auth.controller';
import { createAgency } from '../controllers/agency.controller';
import { authenticateJwt } from '../middlewares/auth.middleware';

const router = Router();

/**
 * @openapi
 * /auth/logout:
 *   post:
 *     summary: User Logout
 *     description: Logs user logout action in audit logs (PRD Sec 18).
 *     tags:
 *       - Authentication
 */
router.post('/auth/logout', logoutUser);

/**
 * @openapi
 * /auth/register:
 *   post:
 *     summary: Register Agency & Agency Admin
 *     description: Creates an Agency and provisions or links the Agency Admin user account, returning JWT Bearer token.
 *     tags:
 *       - Authentication
 */
router.post('/auth/register', createAgency);

/**
 * @openapi
 * /auth/admin-login:
 *   post:
 *     summary: Super Admin & Agency Admin Login
 *     description: Authenticates Super Admin or Agency Admin and returns JWT Bearer token.
 *     tags:
 *       - Authentication
 */
router.post('/auth/admin-login', adminLogin);

/**
 * @openapi
 * /auth/login:
 *   post:
 *     summary: Unified Broker & Agency Login
 *     description: Authenticates Brokers or Agency Users for the mobile app and portals.
 *     tags:
 *       - Authentication
 */
router.post('/auth/login', loginUser);

/**
 * @openapi
 * /auth/me:
 *   get:
 *     summary: Get Current Authenticated User
 *     description: Fetches current user profile and agency details using JWT token.
 *     tags:
 *       - Authentication
 *     security:
 *       - bearerAuth: []
 */
router.get('/auth/me', authenticateJwt, getCurrentUser);

/**
 * @openapi
 * /auth/profile:
 *   put:
 *     summary: Update Current User Profile
 *     description: Updates current authenticated user's name and phone in PostgreSQL.
 *     tags:
 *       - Authentication
 *     security:
 *       - bearerAuth: []
 */
router.put('/auth/profile', authenticateJwt, updateUserProfile);

/**
 * @openapi
 * /auth/change-password:
 *   put:
 *     summary: Change User Password
 *     description: Verifies current password and updates to new hashed bcrypt password in PostgreSQL.
 *     tags:
 *       - Authentication
 *     security:
 *       - bearerAuth: []
 */
router.put('/auth/change-password', authenticateJwt, changePassword);

export default router;
