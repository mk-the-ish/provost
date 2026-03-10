const express = require('express');
const router = express.Router();
const CourierController = require('../controllers/courierController');
const authMiddleware = require('../middleware/authMiddleware');

// All courier routes are protected
router.use(authMiddleware);

// Get courier profile
router.get('/profile', CourierController.getCourierProfile);

// Update courier profile
router.put('/profile', CourierController.updateCourierProfile);

// Update courier status (online/offline)
router.put('/status', CourierController.updateCourierStatus);

// Get courier orders
router.get('/orders', CourierController.getCourierOrders);

// Accept order
router.post('/:orderId/accept', CourierController.acceptOrder);

// Reject order
router.post('/:orderId/reject', CourierController.rejectOrder);

// Get courier stats
router.get('/stats', CourierController.getCourierStats);

// Rate courier
router.post('/:courierId/rate', CourierController.rateCourier);

module.exports = router;
