-- Courier Routes Table
-- Stores declared routes with encoded polylines from Google Directions API

CREATE TABLE IF NOT EXISTS courier_routes (
  id BIGSERIAL PRIMARY KEY,
  courier_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Route geometry
  start_latitude DECIMAL(10, 8) NOT NULL,
  start_longitude DECIMAL(11, 8) NOT NULL,
  end_latitude DECIMAL(10, 8) NOT NULL,
  end_longitude DECIMAL(11, 8) NOT NULL,
  
  -- Encoded polyline from Google Directions API
  -- Format: "lat,lng|lat,lng|lat,lng|..." for compact storage
  encoded_polyline TEXT NOT NULL,
  
  -- Route metadata
  distance_km DECIMAL(10, 2),
  estimated_duration VARCHAR(50), -- e.g., "45 mins", "1h 30m"
  polyline_point_count INTEGER,
  
  -- Status tracking
  status VARCHAR(20) DEFAULT 'active', -- active, completed, abandoned
  matched_orders JSONB DEFAULT '[]'::jsonb, -- Array of matched order IDs
  matched_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Indexes for faster queries
  CONSTRAINT status_check CHECK (status IN ('active', 'completed', 'abandoned'))
);

-- Index for courier_id queries
CREATE INDEX IF NOT EXISTS idx_courier_routes_courier_id 
ON courier_routes(courier_id, status);

-- Index for created_at ordering
CREATE INDEX IF NOT EXISTS idx_courier_routes_created_at 
ON courier_routes(created_at DESC);

-- Enable Row Level Security
ALTER TABLE courier_routes ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Couriers can only view their own routes
CREATE POLICY "couriers_view_own_routes" ON courier_routes
  FOR SELECT
  USING (auth.uid() = courier_id OR auth.jwt() ->> 'role' = 'service_role');

-- RLS Policy: Couriers can insert their own routes
CREATE POLICY "couriers_insert_own_routes" ON courier_routes
  FOR INSERT
  WITH CHECK (auth.uid() = courier_id);

-- RLS Policy: Couriers can update their own routes
CREATE POLICY "couriers_update_own_routes" ON courier_routes
  FOR UPDATE
  USING (auth.uid() = courier_id OR auth.jwt() ->> 'role' = 'service_role');

-- Add audit logging trigger
CREATE TRIGGER update_courier_routes_updated_at
BEFORE UPDATE ON courier_routes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
