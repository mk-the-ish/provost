const express = require('express');
const router = express.Router();
const OrderController = require('../controllers/orderController');
const authMiddleware = require('../middleware/authMiddleware');

// All order routes are protected
router.use(authMiddleware);

// Create order
router.post('/', OrderController.createOrder);

// Get customer orders
router.get('/', OrderController.getCustomerOrders);

// Get order details
router.get('/:orderId', OrderController.getOrderDetails);

// Update order status
router.put('/:orderId/status', OrderController.updateOrderStatus);

// Assign courier
router.put('/:orderId/assign', OrderController.assignCourier);

// Complete order
router.put('/:orderId/complete', OrderController.completeOrder);

// Cancel order
router.put('/:orderId/cancel', OrderController.cancelOrder);

// Rate order
router.post('/:orderId/rate', OrderController.rateOrder);

// Verify delivery with PIN
router.post('/:orderId/verify-delivery', OrderController.verifyDelivery);

// Update pickup/delivery photos
router.put('/:orderId/photos', OrderController.updatePhotos);

module.exports = router;
