const express = require('express');
const router = express.Router();

// FIXED: Removed the curly braces. authMiddleware.js exports the function directly
// via module.exports = authMiddleware.
const authMiddleware = require('../middleware/authMiddleware');

// Ensure this path is correct relative to this routes file
const RouteDeclarationController = require('../controllers/routeDeclarationController');

/**
 * POST /api/routes/declare
 * Declare a new delivery route with encoded polyline
 */
router.post('/declare', authMiddleware, RouteDeclarationController.declareRoute);

/**
 * GET /api/routes/:routeId
 * Get route details with polyline
 */
router.get('/:routeId', authMiddleware, RouteDeclarationController.getRouteDetails);

/**
 * GET /api/routes
 * Get all routes for logged-in courier
 */
router.get('/', authMiddleware, RouteDeclarationController.getCourierRoutes);

/**
 * POST /api/routes/:routeId/match-orders
 * Match orders to a declared route using PostGIS matching
 */
router.post(
  '/:routeId/match-orders',
  authMiddleware,
  RouteDeclarationController.matchOrdersToRoute
);

/**
 * PATCH /api/routes/:routeId/complete
 * Mark route as completed
 */
router.patch(
  '/:routeId/complete',
  authMiddleware,
  RouteDeclarationController.completeRoute
);

module.exports = router;