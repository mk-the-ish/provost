const { supabaseClient } = require('../utils/supabase');
const { firestoreClient } = require('../utils/firebase');

/**
 * Controller for route declaration and management
 * Handles encoded polyline storage and route-order matching
 */
class RouteDeclarationController {
  /**
   * POST /api/routes/declare
   * Declare a new delivery route with encoded polyline
   */
  static async declareRoute(req, res, next) {
    try {
      const courierId = req.user.uid;
      const {
        startLat,
        startLng,
        endLat,
        endLng,
        encodedPolyline,
        distance,
        estimatedDuration,
        polylinePointCount,
        timestamp,
      } = req.body;

      // Validate input
      if (
        !startLat ||
        !startLng ||
        !endLat ||
        !endLng ||
        !encodedPolyline
      ) {
        return res.status(400).json({
          success: false,
          message: 'Missing required route fields',
          statusCode: 400,
        });
      }

      // Create route object
      const routeData = {
        courier_id: courierId,
        start_latitude: parseFloat(startLat),
        start_longitude: parseFloat(startLng),
        end_latitude: parseFloat(endLat),
        end_longitude: parseFloat(endLng),
        encoded_polyline: encodedPolyline, // Stores "lat,lng|lat,lng|..."
        distance_km: parseFloat(distance) || null,
        estimated_duration: estimatedDuration || null,
        polyline_point_count: parseInt(polylinePointCount) || 0,
        status: 'active', // active, completed, abandoned
        created_at: new Date(timestamp).toISOString(),
        updated_at: new Date().toISOString(),
      };

      // Save to Supabase
      const { data, error } = await supabaseClient
        .from('courier_routes')
        .insert([routeData])
        .select();

      if (error) {
        console.error('Supabase insert error:', error);
        throw new Error(`Failed to save route: ${error.message}`);
      }

      const route = data?.[0];

      // Also sync to Firestore for real-time updates
      if (route) {
        await firestoreClient
          .collection('courier_routes')
          .doc(route.id)
          .set({
            ...route,
            decodedPolylinePoints: decodePolylineString(encodedPolyline),
            lastUpdated: new Date(),
          });
      }

      res.status(201).json({
        success: true,
        message: 'Route declared successfully',
        statusCode: 201,
        data: {
          routeId: route?.id,
          ...routeData,
          matchedOrdersUrl: `/api/routes/${route?.id}/match-orders`,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/routes/:routeId
   * Get route details with decoded polyline
   */
  static async getRouteDetails(req, res, next) {
    try {
      const { routeId } = req.params;
      const courierId = req.user.uid;

      const { data, error } = await supabaseClient
        .from('courier_routes')
        .select('*')
        .eq('id', routeId)
        .eq('courier_id', courierId)
        .single();

      if (error || !data) {
        return res.status(404).json({
          success: false,
          message: 'Route not found',
          statusCode: 404,
        });
      }

      // Decode polyline for response
      const decodedPoints = decodePolylineString(data.encoded_polyline);

      res.json({
        success: true,
        data: {
          ...data,
          decodedPolylinePoints: decodedPoints,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/routes
   * Get all routes for logged-in courier
   */
  static async getCourierRoutes(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { status = 'active' } = req.query; // Filter by status

      let query = supabaseClient
        .from('courier_routes')
        .select('*')
        .eq('courier_id', courierId)
        .order('created_at', { ascending: false });

      if (status) {
        query = query.eq('status', status);
      }

      const { data, error } = await query;

      if (error) {
        throw new Error(`Failed to fetch routes: ${error.message}`);
      }

      res.json({
        success: true,
        data: data || [],
        count: data?.length || 0,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/routes/:routeId/match-orders
   * Match orders to a declared route using PostGIS
   * Returns orders within threshold distance of the route polyline
   */
  static async matchOrdersToRoute(req, res, next) {
    try {
      const { routeId } = req.params;
      const courierId = req.user.uid;
      const { threshold = 5000 } = req.body; // Default 5km

      // Get route details
      const { data: route, error: routeError } = await supabaseClient
        .from('courier_routes')
        .select('*')
        .eq('id', routeId)
        .eq('courier_id', courierId)
        .single();

      if (routeError || !route) {
        return res.status(404).json({
          success: false,
          message: 'Route not found',
          statusCode: 404,
        });
      }

      // Decode polyline to get route line string for PostGIS
      const polylinePoints = decodePolylineString(route.encoded_polyline);
      const lineString = pointsToLineString(polylinePoints);

      // Query Supabase PostGIS function to find matching orders
      // Assumes a function: find_orders_near_route(route_line geometry, threshold meters)
      const { data: matchedOrders, error: matchError } = await supabaseClient.rpc(
        'find_orders_near_route',
        {
          route_line: lineString,
          threshold_meters: threshold,
        }
      );

      if (matchError) {
        console.error('PostGIS match error:', matchError);
        throw new Error(`Failed to match orders: ${matchError.message}`);
      }

      // Store matching results
      if (matchedOrders && matchedOrders.length > 0) {
        await supabaseClient
          .from('courier_routes')
          .update({
            matched_orders: matchedOrders.map(o => o.id),
            matched_count: matchedOrders.length,
            updated_at: new Date().toISOString(),
          })
          .eq('id', routeId);
      }

      res.json({
        success: true,
        message: 'Orders matched to route',
        data: {
          routeId,
          matchedOrders: matchedOrders || [],
          matchCount: matchedOrders?.length || 0,
          threshold,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/routes/:routeId/complete
   * Mark route as completed
   */
  static async completeRoute(req, res, next) {
    try {
      const { routeId } = req.params;
      const courierId = req.user.uid;

      const { data, error } = await supabaseClient
        .from('courier_routes')
        .update({
          status: 'completed',
          completed_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', routeId)
        .eq('courier_id', courierId)
        .select();

      if (error) {
        throw new Error(`Failed to complete route: ${error.message}`);
      }

      res.json({
        success: true,
        message: 'Route completed',
        data: data?.[0],
      });
    } catch (error) {
      next(error);
    }
  }
}

/**
 * Utility: Decode polyline string "lat,lng|lat,lng|..." to array of {lat, lng}
 */
function decodePolylineString(encoded) {
  if (!encoded) return [];
  return encoded.split('|').map(pair => {
    const [lat, lng] = pair.split(',');
    return {
      latitude: parseFloat(lat),
      longitude: parseFloat(lng),
    };
  });
}

/**
 * Utility: Convert array of {latitude, longitude} to PostGIS LineString
 * Format: "LINESTRING(lng lat, lng lat, ...)"
 */
function pointsToLineString(points) {
  if (!points || points.length < 2) return '';
  const coords = points
    .map(p => `${p.longitude} ${p.latitude}`)
    .join(', ');
  return `LINESTRING(${coords})`;
}

module.exports = RouteDeclarationController;
