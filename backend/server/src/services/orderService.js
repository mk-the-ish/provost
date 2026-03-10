const { db } = require('../utils/firebase');
const { v4: uuidv4 } = require('uuid');

class OrderService {
  // Create Order
  static async createOrder({
    customerId,
    pickupLocation,
    pickupAddress,
    deliveryLocation,
    deliveryAddress,
    description,
    weight,
    estimatedDistance,
  }) {
    try {
      const orderId = uuidv4();
      const timestamp = new Date();
      // Generate 4-digit delivery PIN for trust verification
      const deliveryPin = Math.floor(1000 + Math.random() * 9000).toString();

      const orderData = {
        id: orderId,
        customerId,
        pickupLocation, // { lat, lng }
        pickupAddress,
        deliveryLocation, // { lat, lng }
        deliveryAddress,
        description,
        weight,
        estimatedDistance,
        status: 'pending', // pending, matched, accepted, in_progress, completed, cancelled
        assignedCourierId: null,
        createdAt: timestamp,
        acceptedAt: null,
        completedAt: null,
        estimatedDeliveryTime: null,
        actualDeliveryTime: null,
        deliveryPin, // 4-digit PIN for delivery verification (sent to client)
        pickupPhotoUrl: null, // Filled by courier at pickup
        deliveryPhotoUrl: null, // Filled by courier at delivery
        otp: Math.floor(100000 + Math.random() * 900000).toString(),
        ratings: {
          courierRating: null,
          customerRating: null,
          courierFeedback: '',
          customerFeedback: '',
        },
      };

      await db.collection('pending_orders').doc(orderId).set(orderData);

      return {
        success: true,
        message: 'Order created successfully',
        orderId,
        order: orderData,
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Order Details
  static async getOrderDetails(orderId) {
    try {
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      return {
        success: true,
        order: orderDoc.data(),
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Customer Orders
  static async getCustomerOrders(customerId, status = null) {
    try {
      let query = db.collection('pending_orders').where('customerId', '==', customerId);

      if (status) {
        query = query.where('status', '==', status);
      }

      const snapshot = await query.get();
      const orders = [];

      snapshot.forEach((doc) => {
        orders.push(doc.data());
      });

      return {
        success: true,
        count: orders.length,
        orders,
      };
    } catch (error) {
      throw error;
    }
  }

  // Update Order Status
  static async updateOrderStatus(orderId, status, additionalData = {}) {
    try {
      const updateData = {
        status,
        ...additionalData,
      };

      // Add timestamp based on status
      if (status === 'accepted') {
        updateData.acceptedAt = new Date();
      } else if (status === 'completed') {
        updateData.completedAt = new Date();
      }

      await db.collection('pending_orders').doc(orderId).update(updateData);

      return {
        success: true,
        message: `Order status updated to ${status}`,
      };
    } catch (error) {
      throw error;
    }
  }

  // Assign Courier
  static async assignCourier(orderId, courierId) {
    try {
      await db.collection('pending_orders').doc(orderId).update({
        assignedCourierId: courierId,
        status: 'matched',
      });

      return {
        success: true,
        message: 'Courier assigned successfully',
      };
    } catch (error) {
      throw error;
    }
  }

  // Complete Order
  static async completeOrder(orderId, deliveredAt = new Date()) {
    try {
      await db.collection('pending_orders').doc(orderId).update({
        status: 'completed',
        completedAt: deliveredAt,
      });

      return {
        success: true,
        message: 'Order completed successfully',
      };
    } catch (error) {
      throw error;
    }
  }

  // Cancel Order
  static async cancelOrder(orderId, reason = '') {
    try {
      await db.collection('pending_orders').doc(orderId).update({
        status: 'cancelled',
        cancellationReason: reason,
        cancelledAt: new Date(),
      });

      return {
        success: true,
        message: 'Order cancelled successfully',
      };
    } catch (error) {
      throw error;
    }
  }

  // Rate Order
  static async rateOrder(orderId, rating, review = '') {
    try {
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      const order = orderDoc.data();
      const courierId = order.assignedCourierId;

      // Update order with rating
      await db.collection('pending_orders').doc(orderId).update({
        'ratings.courierRating': rating,
        'ratings.courierFeedback': review,
        ratedAt: new Date(),
      });

      // Update courier's average rating
      if (courierId) {
        const courierDoc = await db.collection('couriers').doc(courierId).get();

        if (courierDoc.exists) {
          const courier = courierDoc.data();
          const currentRating = courier.rating || 0;
          const ratingCount = courier.ratingCount || 0;

          // Calculate new average rating
          const newRatingCount = ratingCount + 1;
          const newRating = (currentRating * ratingCount + rating) / newRatingCount;

          await db.collection('couriers').doc(courierId).update({
            rating: parseFloat(newRating.toFixed(1)),
            ratingCount: newRatingCount,
          });
        }
      }

      return {
        success: true,
        message: 'Order rated successfully',
        orderId,
        rating,
        feedback: review,
      };
    } catch (error) {
      throw error;
    }
  }

  // Update photo URLs for pickup and delivery
  static async updatePhotos(orderId, pickupPhotoUrl = null, deliveryPhotoUrl = null) {
    try {
      const updateData = {};
      
      if (pickupPhotoUrl) {
        updateData.pickupPhotoUrl = pickupPhotoUrl;
      }
      
      if (deliveryPhotoUrl) {
        updateData.deliveryPhotoUrl = deliveryPhotoUrl;
      }

      await db.collection('pending_orders').doc(orderId).update(updateData);

      return {
        success: true,
        message: 'Photos updated successfully',
      };
    } catch (error) {
      throw error;
    }
  }

  // Verify delivery using PIN
  static async verifyDelivery(orderId, enteredPin) {
    try {
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      const order = orderDoc.data();

      if (order.deliveryPin !== enteredPin) {
        throw { statusCode: 400, message: 'Invalid PIN' };
      }

      // Update order status to completed
      await db.collection('pending_orders').doc(orderId).update({
        status: 'completed',
        completedAt: new Date(),
      });

      return {
        success: true,
        message: 'Delivery Verified!',
        orderId,
      };
    } catch (error) {
      throw error;
    }
  }
}

module.exports = OrderService;
