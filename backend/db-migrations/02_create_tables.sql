-- DropCity Database Schema: Complete Table Definitions
-- Execute this BEFORE running 01_setup_rls.sql
-- This creates all core tables with PostGIS support

-- ============================================
-- CLIENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  rating FLOAT DEFAULT 5.0 CHECK (rating >= 0 AND rating <= 5),
  total_orders INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_clients_phone ON clients(phone);
CREATE INDEX idx_clients_active ON clients(is_active);

-- ============================================
-- COURIERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS couriers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  vehicle_type VARCHAR(50) NOT NULL, -- bike, motorcycle, car, truck
  capacity_kg FLOAT NOT NULL,
  current_load_kg FLOAT DEFAULT 0,
  rating FLOAT DEFAULT 5.0 CHECK (rating >= 0 AND rating <= 5),
  total_deliveries INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  connectivity_status VARCHAR(20) DEFAULT 'offline', -- online, offline, low_signal
  last_ping_time TIMESTAMP WITH TIME ZONE,
  document_verified BOOLEAN DEFAULT FALSE,
  verification_date TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_couriers_phone ON couriers(phone);
CREATE INDEX idx_couriers_active ON couriers(is_active);
CREATE INDEX idx_couriers_vehicle_type ON couriers(vehicle_type);

-- ============================================
-- GPS PINGS TABLE (Time-Series)
-- ============================================
CREATE TABLE IF NOT EXISTS courier_gps_pings (
  id BIGSERIAL PRIMARY KEY,
  courier_id UUID NOT NULL REFERENCES couriers(id) ON DELETE CASCADE,
  location GEOMETRY(POINT, 4326) NOT NULL,
  accuracy_meters INT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  synced BOOLEAN DEFAULT FALSE,
  sync_timestamp TIMESTAMP WITH TIME ZONE
);

-- Spatial index for efficient location queries
CREATE INDEX idx_courier_gps_location ON courier_gps_pings USING GIST(location);

-- Time-series index for efficient range queries
CREATE INDEX idx_courier_gps_timestamp ON courier_gps_pings(courier_id, timestamp DESC);

-- Index for finding unsynced pings
CREATE INDEX idx_courier_gps_synced ON courier_gps_pings(courier_id, synced) WHERE synced = FALSE;

-- Enable time-series compression (optional, requires pg_tsp extension)
-- SELECT create_hypertable('courier_gps_pings', 'timestamp', if_not_exists => TRUE);

-- ============================================
-- ORDERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  pickup_location GEOMETRY(POINT, 4326) NOT NULL,
  dropoff_location GEOMETRY(POINT, 4326) NOT NULL,
  pickup_address VARCHAR(500),
  dropoff_address VARCHAR(500),
  item_description VARCHAR(1000),
  weight_kg FLOAT NOT NULL CHECK (weight_kg > 0),
  special_instructions TEXT,
  alignment_threshold_meters INT DEFAULT 500, -- max distance from route
  status VARCHAR(50) DEFAULT 'pending', -- pending, matched, in_transit, delivered, failed, cancelled
  estimated_amount DECIMAL(10, 2),
  actual_amount DECIMAL(10, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  assigned_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_orders_client ON orders(client_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_pickup ON orders USING GIST(pickup_location);
CREATE INDEX idx_orders_dropoff ON orders USING GIST(dropoff_location);

-- ============================================
-- ROUTES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID NOT NULL REFERENCES couriers(id) ON DELETE CASCADE,
  route_polyline GEOMETRY(LINESTRING, 4326) NOT NULL,
  route_waypoints JSONB NOT NULL, -- Array of {lat, lng, sequence, name}
  total_distance_km FLOAT,
  estimated_duration_minutes INT,
  scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  scheduled_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(50) DEFAULT 'declared', -- declared, in_progress, completed, cancelled
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT
);

CREATE INDEX idx_routes_courier ON routes(courier_id);
CREATE INDEX idx_routes_status ON routes(status);
CREATE INDEX idx_routes_scheduled_time ON routes(scheduled_start_time, scheduled_end_time);

-- Spatial index for route corridor queries
CREATE INDEX idx_routes_polyline ON routes USING GIST(route_polyline);

-- ============================================
-- JOBS TABLE (Delivery Assignments)
-- ============================================
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  courier_id UUID NOT NULL REFERENCES couriers(id) ON DELETE CASCADE,
  sequence_in_route INT NOT NULL,
  alignment_score FLOAT NOT NULL, -- distance-to-route / threshold (0.0 to 1.0)
  estimated_arrival_client TIMESTAMP WITH TIME ZONE,
  actual_arrival_client TIMESTAMP WITH TIME ZONE,
  estimated_delivery_time TIMESTAMP WITH TIME ZONE,
  actual_delivery_time TIMESTAMP WITH TIME ZONE,
  proof_of_delivery VARCHAR(500), -- photo URL or signature hash
  delivery_notes TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, rejected, in_transit, delivered, failed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_jobs_order ON jobs(order_id);
CREATE INDEX idx_jobs_route ON jobs(route_id);
CREATE INDEX idx_jobs_courier ON jobs(courier_id);
CREATE INDEX idx_jobs_status ON jobs(status);

-- ============================================
-- AUDIT LOG TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  action VARCHAR(100) NOT NULL, -- create, update, delete, accept, reject, etc.
  table_name VARCHAR(100) NOT NULL,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_record_id ON audit_logs(record_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ============================================
-- RATINGS & REVIEWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  rater_id UUID NOT NULL, -- client_id or courier_id
  rater_type VARCHAR(20) NOT NULL, -- client or courier
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ratings_job_id ON ratings(job_id);
CREATE INDEX idx_ratings_rater_id ON ratings(rater_id);

-- ============================================
-- AUTO-UPDATE TIMESTAMP FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to update timestamps
CREATE TRIGGER clients_updated_at BEFORE UPDATE ON clients
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER couriers_updated_at BEFORE UPDATE ON couriers
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER orders_updated_at BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER routes_updated_at BEFORE UPDATE ON routes
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER jobs_updated_at BEFORE UPDATE ON jobs
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER ratings_updated_at BEFORE UPDATE ON ratings
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
