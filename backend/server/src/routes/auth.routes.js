const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Public routes
router.post('/register/customer', AuthController.registerCustomer);
router.post('/register/courier', AuthController.registerCourier);
router.post('/login', AuthController.login);
router.post('/logout', AuthController.logout);

// Protected routes
router.get('/me', authMiddleware, AuthController.getCurrentUser);
router.put('/update-password', authMiddleware, AuthController.updatePassword);

module.exports = router;
