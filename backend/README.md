# DropCity Backend - Environment Configuration

This directory contains database migrations, configuration files, and setup scripts for DropCity's backend infrastructure.

## Structure

```
backend/
├── SETUP_GUIDE.md              # Step-by-step Supabase + Firebase setup
├── firestore-rules.txt         # Firebase security rules
├── .env.example                # Example environment variables
├── db-migrations/
│   ├── 01_setup_rls.sql       # Row-Level Security policies
│   ├── 02_create_tables.sql   # Database schema with PostGIS
│   └── 03_create_functions.sql # Matching algorithm functions
└── config/
    └── supabase.json          # Supabase project config (auto-generated)
```

## Quick Start

1. **Follow SETUP_GUIDE.md** to create Supabase and Firebase projects
2. **Execute migrations** in Supabase SQL Editor (in order):
   - `02_create_tables.sql` - Create schema
   - `01_setup_rls.sql` - Enable Row-Level Security
   - `03_create_functions.sql` - Create matching functions
3. **Deploy Firestore rules** from Firebase Console
4. **Configure `.env.local`** with API keys

## Key Components

### Supabase (PostgreSQL + PostGIS)
- **Authentication**: Email + phone OTP for couriers and clients
- **Database**: 7 core tables optimized with spatial indexes
- **RLS Policies**: Isolate client/courier data automatically
- **PostGIS Functions**: Spatial queries for route alignment

### Firebase (Cloud Firestore)
- **Real-time Tracking**: `courier_locations` collection for live GPS
- **Offline Sync Queue**: `sync_queues` for batched GPS ping sync
- **Order Updates**: `order_updates` for real-time client notifications
- **Offline Persistence**: Native support for unreliable networks

## Database Migrations

### 02_create_tables.sql
Creates all core tables:
- `clients` - User profiles
- `couriers` - Transporter profiles
- `orders` - Delivery requests
- `routes` - Courier route declarations
- `jobs` - Delivery assignments
- `courier_gps_pings` - GPS tracking history (time-series)
- `audit_logs` - System audit trail
- `ratings` - Delivery ratings and reviews

All tables include:
- **UUID primary keys** for distributed systems
- **Timestamp tracking** (created_at, updated_at)
- **Spatial indexes** for geographic queries
- **Foreign key constraints** for referential integrity

### 01_setup_rls.sql
Implements Row-Level Security:
- **Clients**: See only own orders
- **Couriers**: See only own routes and assigned jobs
- **Admin**: Full access via service role
- **System**: Backend can insert data for matching/sync

### 03_create_functions.sql
Core matching and utility functions:
- `find_matching_couriers()` - Stage 1 route alignment
- `match_delivery_to_couriers()` - Complete matching orchestration
- `distance_to_route()` - Calculate distance from point to polyline
- `update_courier_load()` - Track active delivery weight

## Deployment

### Development
```bash
cp .env.example .env.local
# Fill in Supabase and Firebase keys
# Run migrations locally
```

### Production
Use Supabase's built-in replication and backups:
1. Enable Point-in-Time Recovery (PITR)
2. Configure automated daily backups
3. Setup read replicas for analytics queries
4. Monitor with Supabase dashboard

## API Integration

Apps connect using:

**Supabase SDK** (auth, data):
```typescript
import { createClient } from '@supabase/supabase-js';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

**Firebase SDK** (real-time):
```typescript
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
const db = getFirestore(initializeApp(firebaseConfig));
```

## Security

- **RLS Enabled**: All queries respect user isolation
- **Auth Required**: All API calls require JWT token
- **Service Role**: Backend-only operations via service key
- **Firestore Rules**: Restrict data access per user role
- **No SQL Injection**: Using prepared statements and parameterized queries

## Monitoring

Check Supabase dashboard for:
- API call counts and response times
- Database query performance
- Authentication events
- Storage usage

Check Firebase console for:
- Firestore reads/writes
- Data usage
- Active connections

## Next Steps

Once backend is set up:
1. **Mobile developers** initialize Supabase + Firebase SDKs in Flutter apps
2. **Web developers** setup Supabase authentication in Next.js admin dashboard
3. **Test** route matching with sample courier routes and orders
