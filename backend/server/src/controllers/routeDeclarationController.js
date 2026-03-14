const { supabaseClient } = require('../utils/supabase');
const { firestoreClient } = require('../utils/firebase');

/**
 * Controller for route declaration and management
 * Uses PostGIS for road-accurate matching along "curvy" routes
 */
class RouteDeclarationController {
  /**
   * POST /api/routes/declare
   * Declare a new delivery route with encoded polyline from Google Directions
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

      // 1. Validation
      if (!startLat || !startLng || !endLat || !endLng || !encodedPolyline) {
        return res.status(400).json({
          success: false,
          message: 'Missing required route fields: start/end points and encoded polyline are mandatory.',
        });
      }

      // 2. Prepare Data for Supabase
      const routeData = {
        courier_id: courierId,
        start_latitude: Number(startLat),
        start_longitude: Number(startLng),
        end_latitude: Number(endLat),
        end_longitude: Number(endLng),
        encoded_polyline: encodedPolyline,
        distance_km: distance ? Number(distance) : null,
        estimated_duration: estimatedDuration || null,
        polyline_point_count: parseInt(polylinePointCount) || 0,
        status: 'active',
        created_at: timestamp ? new Date(timestamp).toISOString() : new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      // 3. Save to Supabase (PostgreSQL)
      const { data: route, error } = await supabaseClient
        .from('courier_routes')
        .insert([routeData])
        .select()
        .single();

      if (error) {
        console.error('Supabase insert error:', error);
        throw new Error(`Failed to save route: ${error.message}`);
      }

      // 4. Sync to Firestore for real-time tracking
      // Note: We don't decode here to save server resources; client decodes on the fly
      if (route) {
        await firestoreClient
          .collection('courier_routes')
          .doc(route.id)
          .set({
            ...route,
            lastUpdated: new Date(),
          });
      }

      res.status(201).json({
        success: true,
        message: 'Route declared successfully',
        data: route,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/routes/:routeId
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
        return res.status(404).json({ success: false, message: 'Route not found' });
      }

      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/routes
   */
  static async getCourierRoutes(req, res, next) {
    try {
      const courierId = req.user.uid;
      const { status = 'active' } = req.query;

      const { data, error } = await supabaseClient
        .from('courier_routes')
        .select('*')
        .eq('courier_id', courierId)
        .eq('status', status)
        .order('created_at', { ascending: false });

      if (error) throw error;

      res.json({ success: true, data: data || [], count: data?.length || 0 });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/routes/:routeId/match-orders
   * Uses the RPC function to match orders within the 500m "corridor"
   */
  static async matchOrdersToRoute(req, res, next) {
    try {
      const { routeId } = req.params;
      const courierId = req.user.uid;
      // Default to 500m threshold as per blueprint
      const thresholdMeters = req.body.threshold || 500;

      // 1. Ownership check
      const { data: route, error: routeError } = await supabaseClient
        .from('courier_routes')
        .select('id')
        .eq('id', routeId)
        .eq('courier_id', courierId)
        .single();

      if (routeError || !route) {
        return res.status(403).json({ success: false, message: 'Unauthorized or route not found' });
      }

      // 2. Call PostGIS RPC (Handles encoded polyline internally)
      const { data: matchedOrders, error: matchError } = await supabaseClient.rpc(
        'match_delivery_to_couriers',
        {
          p_route_id: routeId,
          p_threshold_meters: thresholdMeters,
        }
      );

      if (matchError) {
        console.error('PostGIS matching error:', matchError);
        throw new Error(`Matching failed: ${matchError.message}`);
      }

      // 3. Update the route with match count for the dashboard
      if (matchedOrders) {
        await supabaseClient
          .from('courier_routes')
          .update({
            matched_count: matchedOrders.length,
            updated_at: new Date().toISOString(),
          })
          .eq('id', routeId);
      }

      res.json({
        success: true,
        message: `Found ${matchedOrders?.length || 0} orders along this road path.`,
        data: matchedOrders || [],
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/routes/:routeId/complete
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
        .select()
        .single();

      if (error) throw error;

      res.json({ success: true, message: 'Route completed', data });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = RouteDeclarationController;