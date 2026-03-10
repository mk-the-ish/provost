# DropCity Backend Setup Guide - Supabase & Firebase

## Overview
This guide covers the complete setup of Supabase (PostgreSQL + PostGIS) and Firebase (Cloud Firestore) for the DropCity platform.

---

## Part 1: Supabase Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Click **"New Project"**
4. Fill in project details:
   - **Name**: `dropcity-prod` (or `dropcity-dev` for development)
   - **Database Password**: Create a strong password (save it securely)
   - **Region**: Choose region closest to your users (e.g., US East for North America)
5. Click **"Create new project"** and wait for initialization (~2 minutes)

### Step 2: Enable PostGIS Extension

1. In Supabase dashboard, go to **SQL Editor**
2. Click **"New query"**
3. Paste the following SQL:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
```
4. Click **"Run"**
5. Verify PostGIS is enabled by running:
```sql
SELECT postgis_version();
```

### Step 3: Get API Keys

1. Go to **Settings** → **API**
2. Copy these keys (store in `.env` file):
   - `SUPABASE_URL`: Your project URL
   - `SUPABASE_ANON_KEY`: Public/Anon key (for client-side)
   - `SUPABASE_SERVICE_KEY`: Secret key (for backend only)

### Step 4: Setup Authentication

1. Go to **Auth** → **Providers**
2. Enable **Email Provider**:
   - Toggle "Enable Email provider"
   - Keep "Confirm email" enabled
3. Enable **Phone Provider** (for courier OTP):
   - Toggle "Enable Phone provider"
   - Configure SMS provider (e.g., Twilio)
4. Go to **Auth** → **URL Configuration**
   - Add redirect URLs for mobile apps:
     - `dropcity://auth/callback` (courier app)
     - `dropcity-client://auth/callback` (client app)
   - Add web URLs:
     - `http://localhost:3000/auth/callback` (local dev)
     - `https://admin.dropcity.app/auth/callback` (production)

### Step 5: Setup Row Level Security (RLS)

1. Go to **SQL Editor** → **New query**
2. Run [db-migrations/01_setup_rls.sql](./db-migrations/01_setup_rls.sql)
3. This creates RLS policies so:
   - Clients can only see their own orders
   - Couriers can only see their own routes and assigned jobs
   - Admin users have full access

---

## Part 2: Firebase Setup

### Step 1: Create Firebase Project

1. Go to [firebase.google.com](https://firebase.google.com)
2. Click **"Go to console"**
3. Click **"Create a project"**
4. Project name: `dropcity-prod`
5. Accept default settings and create project

### Step 2: Enable Cloud Firestore

1. In Firebase console, click **"Cloud Firestore"** in left sidebar
2. Click **"Create database"**
3. Select region (same as Supabase region)
4. Select **"Start in production mode"** (we'll add security rules next)
5. Click **"Create"** and wait for initialization

### Step 3: Create Firestore Collections

1. In Cloud Firestore, click **"Start collection"**
2. Create these collections with auto-ID documents:

#### Collection: `courier_locations`
- **Purpose**: Real-time courier GPS locations
- **Document Structure**:
```json
{
  "courier_id": "uuid-string",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "accuracy": 15,
  "timestamp": 1707504000000,
  "is_online": true,
  "route_id": "uuid-string",
  "last_sync": 1707504000000
}
```
- **TTL**: Set 30-day auto-deletion (Settings → Data → TTL)

#### Collection: `sync_queues`
- **Purpose**: Offline GPS pings waiting to sync
- **Document Structure**:
```json
{
  "courier_id": "uuid-string",
  "pings": [
    {
      "latitude": 37.7749,
      "longitude": -122.4194,
      "accuracy": 15,
      "timestamp": 1707504000000
    }
  ],
  "synced": false,
  "sync_attempts": 0,
  "created_at": 1707504000000,
  "last_attempt": 1707504000000
}
```

#### Collection: `order_updates`
- **Purpose**: Real-time order status updates for clients
- **Document Structure**:
```json
{
  "order_id": "uuid-string",
  "client_id": "uuid-string",
  "status": "in_transit",
  "courier_id": "uuid-string",
  "courier_name": "John Doe",
  "courier_phone": "+1234567890",
  "courier_location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "estimated_arrival": 1707504600000,
  "updated_at": 1707504000000
}
```

### Step 4: Setup Firebase Security Rules

1. In Cloud Firestore, go to **Rules** tab
2. Replace content with [firestore-rules.txt](./firestore-rules.txt)
3. Click **"Publish"**

### Step 5: Get Firebase Config

1. Go to **Project Settings** (gear icon)
2. Click **"Service accounts"** tab
3. Click **"Generate new private key"**
4. Save as `firebase-service-key.json`
5. Go back to **Project Settings** → **General**
6. Copy the Firebase config:
```javascript
{
  "apiKey": "YOUR_API_KEY",
  "authDomain": "dropcity-prod.firebaseapp.com",
  "projectId": "dropcity-prod",
  "storageBucket": "dropcity-prod.appspot.com",
  "messagingSenderId": "YOUR_SENDER_ID",
  "appId": "YOUR_APP_ID"
}
```

### Step 6: Enable Cloud Messaging (FCM) for Push Notifications

1. In Firebase console, go to **Cloud Messaging**
2. Copy **Server Key** and **Sender ID**
3. Store in `.env` file

---

## Part 3: Environment Variables

Create `.env.local` file in root directory:

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Firebase
FIREBASE_PROJECT_ID=dropcity-prod
FIREBASE_PRIVATE_KEY_ID=your_private_key_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@dropcity-prod.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your_client_id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/...
FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_STORAGE_BUCKET=dropcity-prod.appspot.com

# App Config
NODE_ENV=development
PORT=3000
```

---

## Part 4: Database Migrations

Run migrations in order:

1. **01_setup_rls.sql** - Row Level Security policies
2. **02_create_tables.sql** - Create all schemas (clients, couriers, orders, routes, jobs, gps_pings)
3. **03_create_indexes.sql** - Create spatial and performance indexes
4. **03_create_functions.sql** - Create database functions for matching logic

Execute with Supabase CLI:
```bash
supabase db push
```

Or manually in SQL Editor:
1. Go to SQL Editor
2. Open each migration file and run queries in order

**Execution order is critical**: RLS → Tables → Indexes → Functions

---

## Part 5: Verification Checklist

- [ ] Supabase project created
- [ ] PostGIS extension enabled
- [ ] API keys obtained and stored in `.env.local`
- [ ] Email & Phone authentication enabled
- [ ] RLS policies applied
- [ ] Firebase project created
- [ ] Cloud Firestore enabled
- [ ] Collections created (courier_locations, sync_queues, order_updates)
- [ ] Security rules published
- [ ] Firebase config obtained
- [ ] Cloud Messaging enabled and keys stored
- [ ] All database migrations executed
- [ ] Environment variables configured

---

## Next Steps

Once this setup is complete:
1. Backend developers can initialize Supabase client in Node.js
2. Mobile developers can initialize Firebase and Supabase SDKs in Flutter
3. Web developers can setup Supabase authentication in Next.js

See individual app READMEs for SDK initialization code.
