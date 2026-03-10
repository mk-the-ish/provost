const { db } = require('../utils/firebase');

class CourierService {
  // Get Courier Profile
  static async getCourierProfile(courierId) {
    try {
      const doc = await db.collection('couriers').doc(courierId).get();

      if (!doc.exists) {
        throw { statusCode: 404, message: 'Courier not found' };
      }

      return {
        success: true,
        courier: doc.data(),
      };
    } catch (error) {
      throw error;
    }
  }

  // Update Courier Profile
  static async updateCourierProfile(courierId, updateData) {
    try {
      await db.collection('couriers').doc(courierId).update(updateData);

      const doc = await db.collection('couriers').doc(courierId).get();

      return {
        success: true,
        message: 'Profile updated successfully',
        courier: doc.data(),
      };
    } catch (error) {
      throw error;
    }
  }

  // Update Courier Status
  static async updateCourierStatus(courierId, isOnline, location = null) {
    try {
      const updateData = { isOnline };

      if (location) {
        updateData.currentLocation = {
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: new Date(),
        };
      }

      await db.collection('couriers').doc(courierId).update(updateData);

      return {
        success: true,
        message: `Courier status updated to ${isOnline ? 'online' : 'offline'}`,
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Courier Orders
  static async getCourierOrders(courierId, status = null) {
    try {
      let query = db.collection('pending_orders').where('assignedCourierId', '==', courierId);

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

  // Accept Order
  static async acceptOrder(courierId, orderId) {
    try {
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      const order = orderDoc.data();

      if (order.assignedCourierId && order.assignedCourierId !== courierId) {
        throw {
          statusCode: 409,
          message: 'Order already assigned to another courier',
        };
      }

      await db.collection('pending_orders').doc(orderId).update({
        assignedCourierId: courierId,
        status: 'accepted',
        acceptedAt: new Date(),
      });

      // Create delivery job
      await db.collection('delivery_jobs').doc(orderId).set({
        orderId,
        courierId,
        status: 'accepted', // accepted, in_progress, completed
        startTime: new Date(),
        pickupCompleted: false,
        pickupTime: null,
        deliveryCompleted: false,
        deliveryTime: null,
      });

      return {
        success: true,
        message: 'Order accepted successfully',
      };
    } catch (error) {
      throw error;
    }
  }

  // Reject Order
  static async rejectOrder(courierId, orderId, reason = '') {
    try {
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      const order = orderDoc.data();

      if (order.assignedCourierId !== courierId) {
        throw {
          statusCode: 403,
          message: 'You are not assigned to this order',
        };
      }

      // Reset order to pending
      await db.collection('pending_orders').doc(orderId).update({
        assignedCourierId: null,
        status: 'pending',
      });

      return {
        success: true,
        message: 'Order rejected successfully',
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Courier Stats
  static async getCourierStats(courierId) {
    try {
      const courier = await db.collection('couriers').doc(courierId).get();

      if (!courier.exists) {
        throw { statusCode: 404, message: 'Courier not found' };
      }

      const completedOrders = await db
        .collection('pending_orders')
        .where('assignedCourierId', '==', courierId)
        .where('status', '==', 'completed')
        .get();

      const totalEarnings = completedOrders.docs.reduce((sum, doc) => {
        return sum + (doc.data().earnings || 0);
      }, 0);

      return {
        success: true,
        stats: {
          totalDeliveries: courier.data().totalDeliveries,
          rating: courier.data().rating,
          completedOrders: completedOrders.size,
          totalEarnings,
          isOnline: courier.data().isOnline,
        },
      };
    } catch (error) {
      throw error;
    }
  }
}

module.exports = CourierService;
