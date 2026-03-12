-- PostGIS Function: Find orders near a route polyline
-- This function uses the PostGIS distance operator <-> to find orders
-- within a specified distance threshold of the route

CREATE OR REPLACE FUNCTION find_orders_near_route(
  route_line GEOMETRY,
  threshold_meters INTEGER DEFAULT 5000
)
RETURNS TABLE(
  id BIGINT,
  order_id VARCHAR,
  customer_id UUID,
  pickup_latitude DECIMAL,
  pickup_longitude DECIMAL,
  delivery_latitude DECIMAL,
  delivery_longitude DECIMAL,
  status VARCHAR,
  distance_to_route DECIMAL,
  distance_to_pickup DECIMAL,
  distance_to_delivery DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    o.id,
    o.order_id,
    o.customer_id,
    o.pickup_latitude,
    o.pickup_longitude,
    o.delivery_latitude,
    o.delivery_longitude,
    o.status,
    -- Distance from pickup to nearest point on route
    ST_Distance(
      ST_GeomFromText('POINT(' || o.pickup_longitude || ' ' || o.pickup_latitude || ')', 4326),
      route_line
    ) * 111000 AS distance_to_route, -- Convert degrees to meters (approx)
    -- Distance from route start to pickup
    ST_Distance(
      ST_GeomFromText('POINT(' || o.pickup_longitude || ' ' || o.pickup_latitude || ')', 4326),
      ST_StartPoint(route_line)
    ) * 111000 AS distance_to_pickup,
    -- Distance from route end to delivery
    ST_Distance(
      ST_GeomFromText('POINT(' || o.delivery_longitude || ' ' || o.delivery_latitude || ')', 4326),
      ST_EndPoint(route_line)
    ) * 111000 AS distance_to_delivery
  FROM orders o
  WHERE
    -- Orders must be pending/active
    o.status IN ('pending', 'accepted', 'in_transit')
    -- Pickup or delivery point is within threshold of route
    AND (
      ST_DWithin(
        ST_GeomFromText('POINT(' || o.pickup_longitude || ' ' || o.pickup_latitude || ')', 4326),
        route_line,
        threshold_meters / 111000 -- Convert meters to degrees (approx)
      )
      OR
      ST_DWithin(
        ST_GeomFromText('POINT(' || o.delivery_longitude || ' ' || o.delivery_latitude || ')', 4326),
        route_line,
        threshold_meters / 111000
      )
    )
  -- Order by distance to route (closest first)
  ORDER BY distance_to_route ASC;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to convert encoded polyline string to PostGIS LineString
-- Input format: "lat1,lng1|lat2,lng2|lat3,lng3"
-- Output format: "LINESTRING(lng1 lat1, lng2 lat2, lng3 lat3)"

CREATE OR REPLACE FUNCTION decode_polyline_to_linestring(encoded_polyline TEXT)
RETURNS GEOMETRY AS $$
DECLARE
  points TEXT[];
  linestring_coords TEXT := '';
  i INTEGER;
BEGIN
  -- Split the encoded string by pipe delimiter
  points := string_to_array(encoded_polyline, '|');
  
  -- Build linestring from points
  FOR i IN 1..array_length(points, 1) LOOP
    IF i > 1 THEN
      linestring_coords := linestring_coords || ', ';
    END IF;
    -- Swap order from lat,lng to lng,lat for PostGIS (lon,lat order)
    linestring_coords := linestring_coords || 
      (string_to_array(points[i], ','))[2] || ' ' || 
      (string_to_array(points[i], ','))[1];
  END LOOP;
  
  RETURN ST_GeomFromText('LINESTRING(' || linestring_coords || ')', 4326);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create GIST index on orders for efficient distance queries
CREATE INDEX IF NOT EXISTS idx_orders_pickup_location 
ON orders USING GIST(
  ST_GeomFromText('POINT(' || pickup_longitude || ' ' || pickup_latitude || ')', 4326)
);

CREATE INDEX IF NOT EXISTS idx_orders_delivery_location 
ON orders USING GIST(
  ST_GeomFromText('POINT(' || delivery_longitude || ' ' || delivery_latitude || ')', 4326)
);
