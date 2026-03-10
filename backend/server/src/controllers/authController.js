const AuthService = require('../services/authService');

class AuthController {
  // Register Customer
  static async registerCustomer(req, res, next) {
    try {
      const { email, password, fullName, phoneNumber } = req.body;

      // Validate request
      if (!email || !password || !fullName || !phoneNumber) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: email, password, fullName, phoneNumber',
        });
      }

      const result = await AuthService.registerCustomer({
        email,
        password,
        fullName,
        phoneNumber,
      });

      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Register Courier
  static async registerCourier(req, res, next) {
    try {
      const {
        email,
        password,
        fullName,
        phoneNumber,
        vehicleType,
        vehicleNumber,
        licenseNumber,
      } = req.body;

      // Validate request
      if (
        !email ||
        !password ||
        !fullName ||
        !phoneNumber ||
        !vehicleType ||
        !vehicleNumber ||
        !licenseNumber
      ) {
        return res.status(400).json({
          success: false,
          message:
            'Missing required fields: email, password, fullName, phoneNumber, vehicleType, vehicleNumber, licenseNumber',
        });
      }

      const result = await AuthService.registerCourier({
        email,
        password,
        fullName,
        phoneNumber,
        vehicleType,
        vehicleNumber,
        licenseNumber,
      });

      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Login
  static async login(req, res, next) {
    try {
      const { email, password } = req.body;

      // Validate request
      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: email, password',
        });
      }

      const result = await AuthService.login(email, password);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Logout
  static async logout(req, res, next) {
    try {
      // In a token-based system, logout is typically handled on the client
      // by discarding the token. This endpoint can be used for cleanup
      // (e.g., invalidating tokens in a blacklist)

      return res.status(200).json({
        success: true,
        message: 'Logged out successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  // Get Current User
  static async getCurrentUser(req, res, next) {
    try {
      // User ID is extracted from JWT in authMiddleware
      const userId = req.user.uid;
      const userType = req.user.userType; // 'customer' or 'courier'

      const result = await AuthService.getCurrentUser(userId, userType);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Update Password
  static async updatePassword(req, res, next) {
    try {
      const userId = req.user.uid;
      const { currentPassword, newPassword } = req.body;

      if (!currentPassword || !newPassword) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: currentPassword, newPassword',
        });
      }

      const result = await AuthService.updatePassword(
        userId,
        currentPassword,
        newPassword
      );

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AuthController;
