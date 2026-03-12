const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/authMiddleware');
const { RouteDeclarationController } = require('../controllers/routeDeclarationController');

/**
 * POST /api/routes/declare
 * Declare a new delivery route with encoded polyline
 * Body: {
 *   startLat: number,
 *   startLng: number,
 *   endLat: number,
 *   endLng: number,
 *   encodedPolyline: string (coordinates as "lat,lng|lat,lng|..."),
 *   distance: string (km),
 *   estimatedDuration: string,
 *   polylinePointCount: number,
 *   timestamp: string (ISO8601)
 * }
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
 * Match orders to a declared route
 * Returns orders within 500m of the route
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
