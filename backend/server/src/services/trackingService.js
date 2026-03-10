const { db } = require('../utils/firebase');

class TrackingService {
  // Update Courier Location
  static async updateCourierLocation(courierId, latitude, longitude, accuracy = 0) {
    try {
      const timestamp = new Date();

      // Update courier current location
      await db.collection('couriers').doc(courierId).update({
        currentLocation: {
          latitude,
          longitude,
          accuracy,
        },
        locationUpdatedAt: timestamp,
      });

      // Store location history
      await db.collection('location_history').doc().set({
        courierId,
        latitude,
        longitude,
        accuracy,
        timestamp,
      });

      return {
        success: true,
        message: 'Location updated',
        courierId,
        location: { latitude, longitude },
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Live Order Tracking
  static async getLiveOrderTracking(orderId) {
    try {
      // Get order details
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      const order = orderDoc.data();
      const courierId = order.assignedCourierId;

      if (!courierId) {
        throw {
          statusCode: 400,
          message: 'No courier assigned to this order',
        };
      }

      // Get courier details
      const courierDoc = await db.collection('couriers').doc(courierId).get();

      if (!courierDoc.exists) {
        throw { statusCode: 404, message: 'Courier not found' };
      }

      const courier = courierDoc.data();

      // Get recent location history
      const locationSnapshot = await db
        .collection('location_history')
        .where('courierId', '==', courierId)
        .orderBy('timestamp', 'desc')
        .limit(50)
        .get();

      const locations = [];
      locationSnapshot.forEach((doc) => {
        locations.push(doc.data());
      });

      return {
        success: true,
        orderId,
        order: {
          status: order.status,
          pickupLocation: order.pickupLocation,
          deliveryLocation: order.deliveryLocation,
        },
        courier: {
          id: courierId,
          name: courier.fullName,
          phone: courier.phoneNumber,
          vehicle: courier.vehicleType,
          currentLocation: courier.currentLocation,
          rating: courier.rating,
        },
        locationHistory: locations,
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Courier Location Route
  static async getCourierLocationRoute(orderId) {
    try {
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      const order = orderDoc.data();
      const courierId = order.assignedCourierId;

      if (!courierId) {
        throw {
          statusCode: 400,
          message: 'No courier assigned to this order',
        };
      }

      // Get location history since order assignment
      const locationSnapshot = await db
        .collection('location_history')
        .where('courierId', '==', courierId)
        .where('timestamp', '>=', order.matchedAt || order.createdAt)
        .orderBy('timestamp', 'asc')
        .get();

      const route = [];
      locationSnapshot.forEach((doc) => {
        const data = doc.data();
        route.push({
          latitude: data.latitude,
          longitude: data.longitude,
          timestamp: data.timestamp,
        });
      });

      return {
        success: true,
        orderId,
        courierId,
        route,
        pickupLocation: order.pickupLocation,
        deliveryLocation: order.deliveryLocation,
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Estimated Time of Arrival (ETA)
  static async estimateDeliveryTime(courierId, deliveryLocation) {
    try {
      // Get courier current location
      const courierDoc = await db.collection('couriers').doc(courierId).get();

      if (!courierDoc.exists) {
        throw { statusCode: 404, message: 'Courier not found' };
      }

      const courier = courierDoc.data();
      const currentLocation = courier.currentLocation;

      if (!currentLocation) {
        throw {
          statusCode: 400,
          message: 'Courier location not available',
        };
      }

      // Calculate distance
      const distance = this.calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        deliveryLocation.latitude,
        deliveryLocation.longitude
      );

      // Estimate time (assuming average speed of 30 km/h in city)
      const averageSpeed = 30; // km/h
      const estimatedMinutes = Math.round((distance / averageSpeed) * 60);

      // Add 2 minutes buffer for pickup/dropoff
      const totalEstimatedMinutes = estimatedMinutes + 2;

      const estimatedArrivalTime = new Date(
        new Date().getTime() + totalEstimatedMinutes * 60000
      );

      return {
        success: true,
        distance: distance.toFixed(2),
        estimatedMinutes: totalEstimatedMinutes,
        estimatedArrivalTime,
      };
    } catch (error) {
      throw error;
    }
  }

  // Calculate distance between two coordinates
  static calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the Earth in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distance in km
  }

  // Store Delivery Event
  static async storeDeliveryEvent(orderId, eventType, details = {}) {
    try {
      await db.collection('delivery_events').doc().set({
        orderId,
        eventType, // 'picked_up', 'in_transit', 'near_delivery', 'delivered', 'cancelled'
        details,
        timestamp: new Date(),
      });

      // Update order status if needed
      const statusMap = {
        picked_up: 'in_transit',
        delivered: 'completed',
        cancelled: 'cancelled',
      };

      if (statusMap[eventType]) {
        await db.collection('pending_orders').doc(orderId).update({
          status: statusMap[eventType],
          [`${eventType}At`]: new Date(),
        });
      }

      return {
        success: true,
        message: `Event ${eventType} recorded`,
        orderId,
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Delivery Events
  static async getDeliveryEvents(orderId) {
    try {
      const eventsSnapshot = await db
        .collection('delivery_events')
        .where('orderId', '==', orderId)
        .orderBy('timestamp', 'asc')
        .get();

      const events = [];
      eventsSnapshot.forEach((doc) => {
        events.push(doc.data());
      });

      return {
        success: true,
        orderId,
        events,
      };
    } catch (error) {
      throw error;
    }
  }
}

module.exports = TrackingService;
