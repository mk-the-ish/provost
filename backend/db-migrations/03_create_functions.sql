-- DropCity Route Alignment Matching Functions
-- These PostGIS functions power the core matching algorithm

-- ============================================
-- STAGE 1: Route Alignment Check
-- ============================================

-- Function: Find couriers whose routes align with delivery request
-- Input: pickup point, dropoff point, alignment threshold (meters)
-- Output: List of matching courier IDs with alignment scores

CREATE OR REPLACE FUNCTION find_matching_couriers(
  p_pickup_location GEOMETRY(POINT, 4326),
  p_dropoff_location GEOMETRY(POINT, 4326),
  p_alignment_threshold INT DEFAULT 500,
  p_schedule_start TIMESTAMP WITH TIME ZONE,
  p_schedule_end TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
  courier_id UUID,
  route_id UUID,
  alignment_score FLOAT,
  distance_to_pickup_meters INT,
  distance_to_dropoff_meters INT,
  courier_name VARCHAR,
  vehicle_type VARCHAR,
  capacity_remaining_kg FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    r.id,
    (
      (ST_Distance(p_pickup_location::geography, r.route_polyline::geography) +
       ST_Distance(p_dropoff_location::geography, r.route_polyline::geography)) / 2.0
    ) / p_alignment_threshold::FLOAT AS alignment_score,
    ST_Distance(p_pickup_location::geography, r.route_polyline::geography)::INT,
    ST_Distance(p_dropoff_location::geography, r.route_polyline::geography)::INT,
    c.name,
    c.vehicle_type,
    c.capacity_kg - c.current_load_kg AS capacity_remaining_kg
  FROM routes r
  JOIN couriers c ON r.courier_id = c.id
  WHERE
    -- Pickup and dropoff within threshold
    ST_DWithin(p_pickup_location::geography, r.route_polyline::geography, p_alignment_threshold) AND
    ST_DWithin(p_dropoff_location::geography, r.route_polyline::geography, p_alignment_threshold) AND
    -- Route timing overlaps with order request
    r.scheduled_start_time <= p_schedule_end AND
    r.scheduled_end_time >= p_schedule_start AND
    -- Courier is active and has capacity
    c.is_active = TRUE AND
    (c.capacity_kg - c.current_load_kg) >= 0 AND
    -- Route is not completed
    r.status IN ('declared', 'in_progress')
  ORDER BY alignment_score ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Utility: Calculate distance from point to linestring
-- ============================================

CREATE OR REPLACE FUNCTION distance_to_route(
  p_point GEOMETRY(POINT, 4326),
  p_route GEOMETRY(LINESTRING, 4326)
)
RETURNS FLOAT AS $$
BEGIN
  RETURN ST_Distance(p_point::geography, p_route::geography);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Utility: Check if two locations are within threshold
-- ============================================

CREATE OR REPLACE FUNCTION is_within_alignment_threshold(
  p_location GEOMETRY(POINT, 4326),
  p_route GEOMETRY(LINESTRING, 4326),
  p_threshold INT DEFAULT 500
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN ST_DWithin(p_location::geography, p_route::geography, p_threshold);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Utility: Get closest point on route to a location
-- ============================================

CREATE OR REPLACE FUNCTION closest_point_on_route(
  p_location GEOMETRY(POINT, 4326),
  p_route GEOMETRY(LINESTRING, 4326)
)
RETURNS GEOMETRY(POINT, 4326) AS $$
BEGIN
  RETURN ST_ClosestPoint(p_route, p_location);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Matching Algorithm: Complete Orchestration
-- ============================================

CREATE OR REPLACE FUNCTION match_delivery_to_couriers(
  p_order_id UUID,
  p_alignment_threshold INT DEFAULT 500
)
RETURNS TABLE (
  courier_id UUID,
  route_id UUID,
  alignment_score FLOAT,
  match_rank INT
) AS $$
DECLARE
  v_pickup GEOMETRY(POINT, 4326);
  v_dropoff GEOMETRY(POINT, 4326);
  v_weight FLOAT;
  v_created_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Fetch order details
  SELECT o.pickup_location, o.dropoff_location, o.weight_kg, o.created_at
  INTO v_pickup, v_dropoff, v_weight, v_created_at
  FROM orders o
  WHERE o.id = p_order_id;

  IF v_pickup IS NULL THEN
    RAISE EXCEPTION 'Order % not found', p_order_id;
  END IF;

  -- Find matching couriers with alignment scores
  RETURN QUERY
  WITH ranked_matches AS (
    SELECT
      c.id,
      r.id,
      (
        (ST_Distance(v_pickup::geography, r.route_polyline::geography) +
         ST_Distance(v_dropoff::geography, r.route_polyline::geography)) / 2.0
      ) / p_alignment_threshold::FLOAT AS alignment_score,
      ROW_NUMBER() OVER (ORDER BY
        (ST_Distance(v_pickup::geography, r.route_polyline::geography) +
         ST_Distance(v_dropoff::geography, r.route_polyline::geography)) / 2.0
      ) AS match_rank
    FROM routes r
    JOIN couriers c ON r.courier_id = c.id
    WHERE
      ST_DWithin(v_pickup::geography, r.route_polyline::geography, p_alignment_threshold) AND
      ST_DWithin(v_dropoff::geography, r.route_polyline::geography, p_alignment_threshold) AND
      c.is_active = TRUE AND
      (c.capacity_kg - c.current_load_kg) >= v_weight AND
      r.status IN ('declared', 'in_progress')
  )
  SELECT rm.id, rm.id, rm.alignment_score, rm.match_rank
  FROM ranked_matches rm
  WHERE rm.alignment_score <= 1.0; -- Only scores within threshold
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Insert audit log function
-- ============================================

CREATE OR REPLACE FUNCTION log_audit(
  p_user_id UUID,
  p_action VARCHAR,
  p_table_name VARCHAR,
  p_record_id UUID,
  p_old_values JSONB,
  p_new_values JSONB
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values)
  VALUES (p_user_id, p_action, p_table_name, p_record_id, p_old_values, p_new_values);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Helper: Calculate courier current load
-- ============================================

CREATE OR REPLACE FUNCTION update_courier_load(
  p_courier_id UUID
)
RETURNS FLOAT AS $$
DECLARE
  v_total_load FLOAT;
BEGIN
  SELECT COALESCE(SUM(o.weight_kg), 0)
  INTO v_total_load
  FROM jobs j
  JOIN orders o ON j.order_id = o.id
  WHERE j.courier_id = p_courier_id
  AND j.status IN ('accepted', 'in_transit');

  UPDATE couriers
  SET current_load_kg = v_total_load
  WHERE id = p_courier_id;

  RETURN v_total_load;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Trigger: Update courier load on job status change
-- ============================================

CREATE OR REPLACE FUNCTION trigger_update_courier_load()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_courier_load(NEW.courier_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_job_status_update_load
AFTER INSERT OR UPDATE ON jobs
FOR EACH ROW
EXECUTE FUNCTION trigger_update_courier_load();
