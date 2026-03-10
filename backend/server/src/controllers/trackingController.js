const TrackingService = require('../services/trackingService');

class TrackingController {
  // Update Courier Location
  static async updateCourierLocation(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { latitude, longitude, accuracy = 0 } = req.body;

      if (latitude === undefined || longitude === undefined) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: latitude, longitude',
        });
      }

      const result = await TrackingService.updateCourierLocation(
        courierId,
        latitude,
        longitude,
        accuracy
      );

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Live Order Tracking
  static async getLiveOrderTracking(req, res, next) {
    try {
      const { orderId } = req.params;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await TrackingService.getLiveOrderTracking(orderId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Courier Location Route
  static async getCourierLocationRoute(req, res, next) {
    try {
      const { orderId } = req.params;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await TrackingService.getCourierLocationRoute(orderId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Estimated Time of Arrival
  static async estimateDeliveryTime(req, res, next) {
    try {
      const { courierId } = req.params;
      const { latitude, longitude } = req.body;

      if (!courierId || latitude === undefined || longitude === undefined) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: courierId, latitude, longitude',
        });
      }

      const result = await TrackingService.estimateDeliveryTime(courierId, {
        latitude,
        longitude,
      });

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Store Delivery Event
  static async storeDeliveryEvent(req, res, next) {
    try {
      const { orderId } = req.params;
      const { eventType, details = {} } = req.body;

      if (!orderId || !eventType) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: orderId, eventType',
        });
      }

      const result = await TrackingService.storeDeliveryEvent(
        orderId,
        eventType,
        details
      );

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Delivery Events
  static async getDeliveryEvents(req, res, next) {
    try {
      const { orderId } = req.params;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await TrackingService.getDeliveryEvents(orderId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = TrackingController;
