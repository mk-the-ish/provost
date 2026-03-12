-- PostGIS Function: Find orders near a route polyline
-- This function uses the PostGIS distance operator to find orders
-- within a specified distance threshold of the route
-- Works with GEOMETRY columns: pickup_location, dropoff_location

CREATE OR REPLACE FUNCTION find_orders_near_route(
  route_line GEOMETRY,
  threshold_meters INTEGER DEFAULT 5000
)
RETURNS TABLE(
  id UUID,
  client_id UUID,
  pickup_location GEOMETRY,
  dropoff_location GEOMETRY,
  status VARCHAR,
  distance_to_route FLOAT,
  distance_to_pickup FLOAT,
  distance_to_delivery FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    o.id,
    o.client_id,
    o.pickup_location,
    o.dropoff_location,
    o.status,
    -- Distance from pickup to nearest point on route (in meters)
    ST_Distance(o.pickup_location::geography, route_line::geography) AS distance_to_route,
    -- Distance from route start to pickup (in meters)
    ST_Distance(o.pickup_location::geography, ST_StartPoint(route_line)::geography) AS distance_to_pickup,
    -- Distance from route end to delivery (in meters)
    ST_Distance(o.dropoff_location::geography, ST_EndPoint(route_line)::geography) AS distance_to_delivery
  FROM orders o
  WHERE
    -- Orders must be pending/matched/in_transit
    o.status IN ('pending', 'matched', 'in_transit')
    -- Pickup or delivery point is within threshold of route (using geography for meters)
    AND (
      ST_DWithin(o.pickup_location::geography, route_line::geography, threshold_meters)
      OR
      ST_DWithin(o.dropoff_location::geography, route_line::geography, threshold_meters)
    )
  -- Order by distance to route (closest first)
  ORDER BY distance_to_route ASC;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to convert encoded polyline string to PostGIS LineString
-- Input format: "lat1,lng1|lat2,lng2|lat3,lng3"
-- Output: GEOMETRY LINESTRING with SRID 4326

CREATE OR REPLACE FUNCTION decode_polyline_to_linestring(encoded_polyline TEXT)
RETURNS GEOMETRY AS $$
DECLARE
  points TEXT[];
  linestring_coords TEXT := '';
  i INTEGER;
  lat TEXT;
  lng TEXT;
BEGIN
  -- Split the encoded string by pipe delimiter
  points := string_to_array(encoded_polyline, '|');
  
  IF array_length(points, 1) < 2 THEN
    RAISE EXCEPTION 'Polyline must contain at least 2 points';
  END IF;
  
  -- Build linestring from points
  FOR i IN 1..array_length(points, 1) LOOP
    IF i > 1 THEN
      linestring_coords := linestring_coords || ', ';
    END IF;
    -- Extract lat and lng from "lat,lng" format
    lat := (string_to_array(points[i], ','))[1];
    lng := (string_to_array(points[i], ','))[2];
    -- Add to linestring in lng,lat order (required by PostGIS)
    linestring_coords := linestring_coords || lng || ' ' || lat;
  END LOOP;
  
  RETURN ST_GeomFromText('LINESTRING(' || linestring_coords || ')', 4326);
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Error decoding polyline: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
-- Spatial indexes are already created in 02_create_tables.sql:
-- - idx_orders_pickup on orders(pickup_location)
-- - idx_orders_dropoff on orders(dropoff_location)
-- These GIST indexes enable efficient spatial distance queries
