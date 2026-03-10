const express = require('express');
const router = express.Router();
const TrackingController = require('../controllers/trackingController');
const authMiddleware = require('../middleware/authMiddleware');

// Protected routes
router.use(authMiddleware);

// Update courier location
router.post('/location', TrackingController.updateCourierLocation);

// Get live order tracking
router.get('/order/:orderId', TrackingController.getLiveOrderTracking);

// Get courier location route
router.get('/route/:orderId', TrackingController.getCourierLocationRoute);

// Estimate delivery time
router.post('/estimate/:courierId', TrackingController.estimateDeliveryTime);

// Store delivery event
router.post('/event/:orderId', TrackingController.storeDeliveryEvent);

// Get delivery events
router.get('/events/:orderId', TrackingController.getDeliveryEvents);

module.exports = router;
