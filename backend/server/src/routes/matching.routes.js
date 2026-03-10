const express = require('express');
const router = express.Router();
const MatchingController = require('../controllers/matchingController');
const authMiddleware = require('../middleware/authMiddleware');

// Find available couriers (public - for order creation)
router.post('/find-couriers', MatchingController.findAvailableCouriers);

// Protected routes
router.use(authMiddleware);

// Match order with courier
router.post('/match', MatchingController.matchOrderWithCourier);

// Get matching orders for courier
router.get('/orders', MatchingController.getMatchingOrders);

module.exports = router;
