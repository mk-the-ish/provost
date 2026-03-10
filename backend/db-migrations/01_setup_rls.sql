-- DropCity Database Setup: Row Level Security (RLS) Policies
-- Execute this AFTER creating all tables in 02_create_tables.sql
-- This ensures data isolation between users

-- Enable RLS on all tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE couriers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE courier_gps_pings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- CLIENTS TABLE RLS POLICIES
-- ============================================

-- Clients can only view their own profile
CREATE POLICY "Clients can view own profile"
ON clients FOR SELECT
USING (auth.uid()::text = id::text);

-- Clients can update their own profile
CREATE POLICY "Clients can update own profile"
ON clients FOR UPDATE
USING (auth.uid()::text = id::text)
WITH CHECK (auth.uid()::text = id::text);

-- ============================================
-- COURIERS TABLE RLS POLICIES
-- ============================================

-- Couriers can view their own profile
CREATE POLICY "Couriers can view own profile"
ON couriers FOR SELECT
USING (auth.uid()::text = id::text);

-- Couriers can update their own profile
CREATE POLICY "Couriers can update own profile"
ON couriers FOR UPDATE
USING (auth.uid()::text = id::text)
WITH CHECK (auth.uid()::text = id::text);

-- Clients can view public courier info (needed for tracking)
CREATE POLICY "Clients can view assigned courier public info"
ON couriers FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM jobs j
    JOIN orders o ON j.order_id = o.id
    WHERE j.courier_id = couriers.id
    AND o.client_id = auth.uid()::text
  )
);

-- ============================================
-- ORDERS TABLE RLS POLICIES
-- ============================================

-- Clients can view their own orders
CREATE POLICY "Clients can view own orders"
ON orders FOR SELECT
USING (auth.uid()::text = client_id::text);

-- Clients can create orders
CREATE POLICY "Clients can create orders"
ON orders FOR INSERT
WITH CHECK (auth.uid()::text = client_id::text);

-- Clients can update their own orders (only non-matched ones)
CREATE POLICY "Clients can update own pending orders"
ON orders FOR UPDATE
USING (auth.uid()::text = client_id::text AND status = 'pending')
WITH CHECK (auth.uid()::text = client_id::text AND status = 'pending');

-- Couriers can view orders they're assigned to
CREATE POLICY "Couriers can view assigned orders"
ON orders FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.order_id = orders.id
    AND jobs.courier_id = auth.uid()::text
  )
);

-- ============================================
-- ROUTES TABLE RLS POLICIES
-- ============================================

-- Couriers can view their own routes
CREATE POLICY "Couriers can view own routes"
ON routes FOR SELECT
USING (auth.uid()::text = courier_id::text);

-- Couriers can create new routes
CREATE POLICY "Couriers can create routes"
ON routes FOR INSERT
WITH CHECK (auth.uid()::text = courier_id::text);

-- Couriers can update their own routes
CREATE POLICY "Couriers can update own routes"
ON routes FOR UPDATE
USING (auth.uid()::text = courier_id::text)
WITH CHECK (auth.uid()::text = courier_id::text);

-- Admin and matching engine can view all routes (for matching)
CREATE POLICY "Matching engine can view all routes"
ON routes FOR SELECT
USING (current_setting('app.user_role') = 'admin' OR current_setting('app.user_role') = 'system');

-- ============================================
-- JOBS TABLE RLS POLICIES
-- ============================================

-- Couriers can view their own jobs
CREATE POLICY "Couriers can view own jobs"
ON jobs FOR SELECT
USING (auth.uid()::text = courier_id::text);

-- Couriers can update their assigned jobs
CREATE POLICY "Couriers can update own jobs"
ON jobs FOR UPDATE
USING (auth.uid()::text = courier_id::text)
WITH CHECK (auth.uid()::text = courier_id::text);

-- Clients can view jobs for their orders
CREATE POLICY "Clients can view jobs for their orders"
ON jobs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = jobs.order_id
    AND orders.client_id = auth.uid()::text
  )
);

-- System can insert jobs (matching engine)
CREATE POLICY "System can create jobs"
ON jobs FOR INSERT
WITH CHECK (current_setting('app.user_role') = 'system');

-- ============================================
-- GPS PINGS TABLE RLS POLICIES
-- ============================================

-- Couriers can only view their own GPS pings
CREATE POLICY "Couriers can view own GPS pings"
ON courier_gps_pings FOR SELECT
USING (auth.uid()::text = courier_id::text);

-- Couriers can insert their own GPS pings
CREATE POLICY "Couriers can insert own GPS pings"
ON courier_gps_pings FOR INSERT
WITH CHECK (auth.uid()::text = courier_id::text);

-- System can insert GPS pings (sync from offline queue)
CREATE POLICY "System can insert GPS pings"
ON courier_gps_pings FOR INSERT
WITH CHECK (current_setting('app.user_role') = 'system');

-- System can query GPS pings for admin dashboard
CREATE POLICY "System can query GPS pings"
ON courier_gps_pings FOR SELECT
USING (current_setting('app.user_role') = 'admin' OR current_setting('app.user_role') = 'system');

-- ============================================
-- ADMIN BYPASS (use service key only)
-- ============================================

-- Grant full access to service role (backend can bypass RLS)
-- Service role is configured in Supabase and has full database access
-- Use SUPABASE_SERVICE_KEY for admin operations only
