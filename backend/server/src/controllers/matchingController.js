const MatchingService = require('../services/matchingService');

class MatchingController {
  // Find Available Couriers
  static async findAvailableCouriers(req, res, next) {
    try {
      const { latitude, longitude, maxDistance = 5 } = req.body;

      if (latitude === undefined || longitude === undefined) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: latitude, longitude',
        });
      }

      const result = await MatchingService.findAvailableCouriers(
        { latitude, longitude },
        maxDistance
      );

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Match Order with Courier
  static async matchOrderWithCourier(req, res, next) {
    try {
      const { orderId, courierId } = req.body;

      if (!orderId || !courierId) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: orderId, courierId',
        });
      }

      const result = await MatchingService.matchOrder(orderId, courierId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Matching Orders for Courier
  static async getMatchingOrders(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { maxDistance = 5 } = req.query;

      const result = await MatchingService.getMatchingOrders(
        courierId,
        parseInt(maxDistance)
      );

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = MatchingController;
