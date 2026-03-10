-- DropCity: Create Spatial and Performance Indexes
-- Purpose: Optimize queries for location matching, time-series GPS data, and common lookups
-- Execute after: 02_create_tables.sql
-- Execution time: ~30 seconds

-- =============================================================================
-- SPATIAL INDEXES (PostGIS GIST for O(log n) location queries)
-- =============================================================================

-- Index on courier current locations for fast proximity searches
-- Used by: find_matching_couriers() to find couriers within distance threshold
CREATE INDEX idx_couriers_location_gist
ON couriers USING GIST (current_location)
WHERE is_active = true AND is_online = true;

-- Index on order locations for fast geospatial queries
-- Used by: order matching and geocoding operations
CREATE INDEX idx_orders_location_gist
ON orders USING GIST (pickup_location);

CREATE INDEX idx_orders_dropoff_location_gist
ON orders USING GIST (dropoff_location);

-- Index on routes for proximity-based matching
-- Used by: route alignment and distance calculations
CREATE INDEX idx_routes_waypoints_gist
ON routes USING GIST (route_polyline);

-- Index on GPS ping locations for spatial time-series queries
-- Used by: courier path reconstruction and heat maps
CREATE INDEX idx_courier_gps_pings_location_gist
ON courier_gps_pings USING GIST (location)
WHERE synced = true;

-- =============================================================================
-- TIME-SERIES INDEXES (for GPS tracking and audit logs)
-- =============================================================================

-- Index on GPS ping timestamps for efficient range queries
-- Used by: retrieving GPS history for a time period (e.g., last 24 hours)
-- Query: SELECT * FROM courier_gps_pings WHERE courier_id = $1 AND recorded_at > NOW() - INTERVAL '24 hours'
CREATE INDEX idx_courier_gps_pings_timestamp
ON courier_gps_pings (recorded_at DESC, courier_id)
WHERE synced = true;

-- Composite index for efficient courier route tracking queries
-- Used by: find all GPS pings for a courier on a specific route within a time window
CREATE INDEX idx_courier_gps_pings_route_timestamp
ON courier_gps_pings (route_id, recorded_at DESC)
WHERE route_id IS NOT NULL;

-- Index on courier online status timeline
-- Used by: availability tracking and shift management
CREATE INDEX idx_couriers_online_history
ON couriers (is_online, last_status_change DESC)
WHERE is_active = true;

-- =============================================================================
-- FOREIGN KEY LOOKUP INDEXES
-- =============================================================================

-- Index on order courier assignments for fast job lookups
-- Used by: finding all jobs for a courier
CREATE INDEX idx_jobs_courier_id
ON jobs (courier_id)
WHERE status IN ('pending', 'accepted', 'in_transit');

-- Index on job order lookup
-- Used by: finding job details for an order
CREATE INDEX idx_jobs_order_id
ON jobs (order_id);

-- Index on courier route lookups
-- Used by: finding all active jobs on a route
CREATE INDEX idx_jobs_route_id
ON jobs (route_id, status);

-- Index on order client lookups
-- Used by: finding all orders for a client
CREATE INDEX idx_orders_client_id
ON orders (client_id, created_at DESC)
WHERE status IN ('pending', 'accepted', 'in_transit', 'delivered');

-- Index on route courier lookups
-- Used by: finding all active routes for a courier
CREATE INDEX idx_routes_courier_id
ON routes (courier_id, is_active DESC);

-- Index on ratings lookups
-- Used by: calculating average ratings and finding ratings for a courier/client
CREATE INDEX idx_ratings_courier_id
ON ratings (rated_courier_id, created_at DESC);

CREATE INDEX idx_ratings_client_id
ON ratings (rated_client_id, created_at DESC);

-- =============================================================================
-- BUSINESS LOGIC INDEXES
-- =============================================================================

-- Index for finding pending orders to match with couriers
-- Used by: order matching algorithm during request creation
CREATE INDEX idx_orders_pending_status
ON orders (created_at DESC, status)
WHERE status = 'pending'
AND created_at > NOW() - INTERVAL '2 hours';

-- Index for finding available couriers
-- Used by: route matching service to find active couriers
CREATE INDEX idx_couriers_available
ON couriers (is_online, is_active, current_load)
WHERE is_online = true
AND is_active = true;

-- Index for finding incomplete jobs
-- Used by: job status tracking and notifications
CREATE INDEX idx_jobs_incomplete
ON jobs (created_at DESC, status)
WHERE status NOT IN ('delivered', 'cancelled');

-- Index for audit trail queries
-- Used by: compliance and debugging
CREATE INDEX idx_audit_logs_timestamp
ON audit_logs (created_at DESC)
WHERE action IN ('order_created', 'job_assigned', 'status_changed');

-- Index for user action tracking
-- Used by: user activity analysis
CREATE INDEX idx_audit_logs_actor
ON audit_logs (actor_id, created_at DESC);

-- =============================================================================
-- UNIQUE INDEXES (enforce uniqueness)
-- =============================================================================

-- Ensure each courier has only one active route
CREATE UNIQUE INDEX idx_routes_courier_unique_active
ON routes (courier_id)
WHERE is_active = true;

-- Ensure each order has only one assigned job at a time
CREATE UNIQUE INDEX idx_jobs_order_unique_active
ON jobs (order_id)
WHERE status IN ('pending', 'accepted', 'in_transit');

-- =============================================================================
-- PARTIAL INDEXES (optimize for active data)
-- =============================================================================

-- Index for active orders (most common query pattern)
-- Reduces index size by excluding old/completed orders
CREATE INDEX idx_orders_active
ON orders (updated_at DESC)
WHERE status IN ('pending', 'accepted', 'in_transit');

-- Index for active routes (most common query pattern)
-- Reduces index size by only indexing active routes
CREATE INDEX idx_routes_active
ON routes (updated_at DESC)
WHERE is_active = true;

-- Index for online couriers (most common query pattern)
-- Reduces index size by only indexing available couriers
CREATE INDEX idx_couriers_online
ON couriers (updated_at DESC, id)
WHERE is_online = true;

-- =============================================================================
-- ANALYZE TABLES (update query planner statistics)
-- =============================================================================

-- Update statistics for optimized query planning
ANALYZE clients;
ANALYZE couriers;
ANALYZE orders;
ANALYZE routes;
ANALYZE jobs;
ANALYZE courier_gps_pings;
ANALYZE ratings;
ANALYZE audit_logs;

-- =============================================================================
-- INDEX STATISTICS
-- =============================================================================

-- Note: After running this migration, you can verify indexes with:
-- SELECT * FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;

-- Monitor index usage to identify unused indexes:
-- SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
-- FROM pg_stat_user_indexes
-- ORDER BY idx_scan DESC;

-- Check index size:
-- SELECT indexname, pg_size_pretty(pg_relation_size(indexrelid))
-- FROM pg_stat_user_indexes
-- ORDER BY pg_relation_size(indexrelid) DESC;

-- =============================================================================
-- EXPECTED PERFORMANCE IMPROVEMENTS
-- =============================================================================

/*
After running this migration, expect these query improvements:

1. Location-based Queries (find_matching_couriers):
   - Before: O(n) full table scan
   - After: O(log n) with GIST spatial index
   - Expected improvement: 100-1000x faster for typical dataset

2. GPS Time-Series Queries (courier history):
   - Before: O(n log n) with full table scan
   - After: O(log n) with composite timestamp index
   - Expected improvement: 50-500x faster

3. Order Status Lookups:
   - Before: O(n) full table scan
   - After: O(log n) with partial index
   - Expected improvement: 10-100x faster

4. Courier Availability Checks:
   - Before: O(n) with filtering
   - After: O(log n) with online index
   - Expected improvement: 10-50x faster

5. Job Assignment Lookups:
   - Before: O(n) with filtering
   - After: O(log n) with composite index
   - Expected improvement: 10-30x faster

Overall database performance:
- Write performance: Minimal impact (indexes slow writes slightly)
- Read performance: 10-1000x improvement depending on query
- Disk usage: +15-25% for index storage
*/

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================
-- Tables are now optimized for:
-- ✓ Spatial location queries (PostGIS)
-- ✓ Time-series GPS data (timestamp ranges)
-- ✓ Foreign key relationships (lookups)
-- ✓ Common business queries (active records)
-- ✓ User actions and auditing
