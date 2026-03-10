const { db } = require('../utils/firebase');
const geolib = require('geolib');

class MatchingService {
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

  // Check if a point is near a line (route corridor)
  // Uses geolib for accurate geospatial calculations
  static isPointNearRoute(point, startPoint, endPoint, bufferMeters = 1000) {
    try {
      // Calculate distance from point to the line segment
      const distance = geolib.getDistanceFromLine(
        point,
        [startPoint, endPoint]
      );
      
      return distance <= bufferMeters;
    } catch (error) {
      console.error('Error checking point near route:', error);
      return false;
    }
  }

  // Find orders on courier's route (Simple Bounding Box + Route Corridor Logic)
  static async findOrdersOnRoute(courierStart, courierEnd, bufferMeters = 1000) {
    try {
      // Get all pending orders
      const ordersSnapshot = await db
        .collection('pending_orders')
        .where('status', '==', 'pending')
        .get();

      const matchedOrders = [];

      ordersSnapshot.forEach((doc) => {
        const order = doc.data();
        const pickupLocation = order.pickupLocation;
        const deliveryLocation = order.deliveryLocation;

        // Check if pickup is near the courier's route
        const pickupNearRoute = this.isPointNearRoute(
          pickupLocation,
          courierStart,
          courierEnd,
          bufferMeters
        );

        // Check if delivery is near the courier's route
        const deliveryNearRoute = this.isPointNearRoute(
          deliveryLocation,
          courierStart,
          courierEnd,
          bufferMeters
        );

        // Order matches if both pickup and delivery are on the route
        if (pickupNearRoute && deliveryNearRoute) {
          matchedOrders.push({
            ...order,
            alignmentScore: this.calculateAlignmentScore(
              pickupLocation,
              deliveryLocation,
              courierStart,
              courierEnd
            ),
          });
        }
      });

      // Sort by alignment score (lower = better)
      matchedOrders.sort((a, b) => a.alignmentScore - b.alignmentScore);

      return {
        success: true,
        count: matchedOrders.length,
        orders: matchedOrders,
      };
    } catch (error) {
      throw error;
    }
  }

  // Calculate alignment score (how well the order aligns with courier's route)
  static calculateAlignmentScore(pickupLoc, deliveryLoc, routeStart, routeEnd) {
    const pickupDistance = geolib.getDistanceFromLine(
      pickupLoc,
      [routeStart, routeEnd]
    );
    const deliveryDistance = geolib.getDistanceFromLine(
      deliveryLoc,
      [routeStart, routeEnd]
    );

    // Average distance from route (normalized 0-1, lower is better)
    return (pickupDistance + deliveryDistance) / 2;
  }

  // Find Available Couriers
  static async findAvailableCouriers(pickupLocation, maxDistance = 5) {
    try {
      // Get all online couriers
      const couriersSnapshot = await db
        .collection('couriers')
        .where('isOnline', '==', true)
        .get();

      const availableCouriers = [];

      couriersSnapshot.forEach((doc) => {
        const courier = doc.data();
        const currentLocation = courier.currentLocation;

        if (!currentLocation) return;

        const distance = this.calculateDistance(
          pickupLocation.latitude,
          pickupLocation.longitude,
          currentLocation.latitude,
          currentLocation.longitude
        );

        if (distance <= maxDistance) {
          availableCouriers.push({
            ...courier,
            distance,
          });
        }
      });

      // Sort by distance and rating
      availableCouriers.sort((a, b) => {
        if (a.distance === b.distance) {
          return b.rating - a.rating;
        }
        return a.distance - b.distance;
      });

      return {
        success: true,
        count: availableCouriers.length,
        couriers: availableCouriers.slice(0, 10), // Return top 10
      };
    } catch (error) {
      throw error;
    }
  }

  // Match Order with Courier
  static async matchOrder(orderId, courierId) {
    try {
      // Get order
      const orderDoc = await db.collection('pending_orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw { statusCode: 404, message: 'Order not found' };
      }

      const order = orderDoc.data();

      if (order.status !== 'pending') {
        throw {
          statusCode: 409,
          message: 'Order is not in pending status',
        };
      }

      // Get courier
      const courierDoc = await db.collection('couriers').doc(courierId).get();

      if (!courierDoc.exists) {
        throw { statusCode: 404, message: 'Courier not found' };
      }

      const courier = courierDoc.data();

      if (!courier.isOnline) {
        throw { statusCode: 400, message: 'Courier is not online' };
      }

      // Create match record
      await db.collection('pending_orders').doc(orderId).update({
        assignedCourierId: courierId,
        status: 'matched',
        matchedAt: new Date(),
      });

      // Create notification record
      await db.collection('notifications').doc().set({
        type: 'order_matched',
        courierId,
        orderId,
        message: `New delivery request: ${order.deliveryAddress}`,
        read: false,
        createdAt: new Date(),
      });

      return {
        success: true,
        message: 'Order matched with courier',
        orderId,
        courierId,
      };
    } catch (error) {
      throw error;
    }
  }

  // Get Matching Orders for Courier
  static async getMatchingOrders(courierId, maxDistance = 5) {
    try {
      // Get courier location
      const courierDoc = await db.collection('couriers').doc(courierId).get();

      if (!courierDoc.exists) {
        throw { statusCode: 404, message: 'Courier not found' };
      }

      const courier = courierDoc.data();
      const courierLocation = courier.currentLocation;

      if (!courierLocation) {
        throw {
          statusCode: 400,
          message: 'Courier location not available',
        };
      }

      // Get pending orders
      const ordersSnapshot = await db
        .collection('pending_orders')
        .where('status', '==', 'pending')
        .get();

      const matchingOrders = [];

      ordersSnapshot.forEach((doc) => {
        const order = doc.data();
        const distance = this.calculateDistance(
          courierLocation.latitude,
          courierLocation.longitude,
          order.pickupLocation.latitude,
          order.pickupLocation.longitude
        );

        if (distance <= maxDistance) {
          matchingOrders.push({
            ...order,
            distance,
          });
        }
      });

      // Sort by distance
      matchingOrders.sort((a, b) => a.distance - b.distance);

      return {
        success: true,
        count: matchingOrders.length,
        orders: matchingOrders,
      };
    } catch (error) {
      throw error;
    }
  }
}

module.exports = MatchingService;
