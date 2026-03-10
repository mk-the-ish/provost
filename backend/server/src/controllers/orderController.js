const OrderService = require('../services/orderService');

class OrderController {
  // Create Order
  static async createOrder(req, res, next) {
    try {
      const customerId = req.user.uid;
      const {
        pickupLocation,
        pickupAddress,
        deliveryLocation,
        deliveryAddress,
        description,
        weight,
        estimatedDistance,
        packageType,
        specialInstructions,
        paymentMethod,
      } = req.body;

      // Validate request
      if (
        !pickupLocation ||
        !pickupAddress ||
        !deliveryLocation ||
        !deliveryAddress ||
        !description ||
        !weight ||
        !estimatedDistance
      ) {
        return res.status(400).json({
          success: false,
          message:
            'Missing required fields: pickupLocation, pickupAddress, deliveryLocation, deliveryAddress, description, weight, estimatedDistance',
        });
      }

      const result = await OrderService.createOrder({
        customerId,
        pickupLocation,
        pickupAddress,
        deliveryLocation,
        deliveryAddress,
        description,
        weight,
        estimatedDistance,
        packageType,
        specialInstructions,
        paymentMethod,
      });

      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Order Details
  static async getOrderDetails(req, res, next) {
    try {
      const { orderId } = req.params;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await OrderService.getOrderDetails(orderId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Get Customer Orders
  static async getCustomerOrders(req, res, next) {
    try {
      const customerId = req.user.uid;
      const { status } = req.query;

      const result = await OrderService.getCustomerOrders(customerId, status);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Update Order Status
  static async updateOrderStatus(req, res, next) {
    try {
      const { orderId } = req.params;
      const { status } = req.body;

      if (!orderId || !status) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: orderId, status',
        });
      }

      const validStatuses = [
        'pending',
        'matched',
        'picked_up',
        'in_transit',
        'completed',
        'cancelled',
      ];

      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: `Invalid status. Valid statuses: ${validStatuses.join(', ')}`,
        });
      }

      const result = await OrderService.updateOrderStatus(orderId, status);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Assign Courier
  static async assignCourier(req, res, next) {
    try {
      const { orderId } = req.params;
      const { courierId } = req.body;

      if (!orderId || !courierId) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: orderId, courierId',
        });
      }

      const result = await OrderService.assignCourier(orderId, courierId);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Complete Order
  static async completeOrder(req, res, next) {
    try {
      const { orderId } = req.params;
      const { deliveryNotes, signature } = req.body;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await OrderService.completeOrder(
        orderId,
        deliveryNotes,
        signature
      );

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Cancel Order
  static async cancelOrder(req, res, next) {
    try {
      const { orderId } = req.params;
      const { reason } = req.body;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await OrderService.cancelOrder(orderId, reason);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Rate Order
  static async rateOrder(req, res, next) {
    try {
      const { orderId } = req.params;
      const { rating, review } = req.body;

      if (!orderId || !rating) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: orderId, rating',
        });
      }

      if (rating < 1 || rating > 5) {
        return res.status(400).json({
          success: false,
          message: 'Rating must be between 1 and 5',
        });
      }

      const result = await OrderService.rateOrder(orderId, rating, review);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Verify Delivery using PIN
  static async verifyDelivery(req, res, next) {
    try {
      const { orderId, enteredPin } = req.body;

      if (!orderId || !enteredPin) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: orderId, enteredPin',
        });
      }

      const result = await OrderService.verifyDelivery(orderId, enteredPin);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  // Update Pickup/Delivery Photos
  static async updatePhotos(req, res, next) {
    try {
      const { orderId } = req.params;
      const { pickupPhotoUrl, deliveryPhotoUrl } = req.body;

      if (!orderId) {
        return res.status(400).json({
          success: false,
          message: 'Missing orderId parameter',
        });
      }

      const result = await OrderService.updatePhotos(orderId, pickupPhotoUrl, deliveryPhotoUrl);

      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = OrderController;
