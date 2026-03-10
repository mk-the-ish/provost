const CourierService = require('../services/courierService');

class CourierController {
  // Get Courier Profile
  static async getCourierProfile(req, res, next) {
    try {
      const courierId = req.user.uid;

      const result = await CourierService.getCourierProfile(courierId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Update Courier Profile
  static async updateCourierProfile(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { fullName, phoneNumber, vehicleType, licenseNumber, bankDetails } =
        req.body;

      const result = await CourierService.updateCourierProfile(courierId, {
        fullName,
        phoneNumber,
        vehicleType,
        licenseNumber,
        bankDetails,
      });

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Update Courier Status (Online/Offline)
  static async updateCourierStatus(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { isOnline } = req.body;

      if (typeof isOnline !== 'boolean') {
        return res.status(400).json({
          success: false,
          message: 'isOnline must be a boolean',
        });
      }

      const result = await CourierService.updateCourierStatus(
        courierId,
        isOnline
      );

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Courier Orders
  static async getCourierOrders(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { status } = req.query;

      const result = await CourierService.getCourierOrders(courierId, status);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Accept Order
  static async acceptOrder(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { orderId } = req.params;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await CourierService.acceptOrder(courierId, orderId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Reject Order
  static async rejectOrder(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { orderId } = req.params;
      const { reason } = req.body;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await CourierService.rejectOrder(courierId, orderId, reason);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Courier Stats
  static async getCourierStats(req, res, next) {
    try {
      const courierId = req.user.uid;

      const result = await CourierService.getCourierStats(courierId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Rate Courier
  static async rateCourier(req, res, next) {
    try {
      const { courierId } = req.params;
      const { rating, review } = req.body;

      if (!courierId || !rating) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: courierId, rating',
        });
      }

      if (rating < 1 || rating > 5) {
        return res.status(400).json({
          success: false,
          message: 'Rating must be between 1 and 5',
        });
      }

      const result = await CourierService.rateCourier(courierId, rating, review);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = CourierController;
