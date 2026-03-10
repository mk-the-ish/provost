# DropCity Copilot Instructions

**Project**: P2P Logistics Platform (Phase 1: Foundation Complete)  
**Tech Stack**: Flutter (Dart) + Node.js Backend + Supabase + Firebase  
**Status**: Three interconnected services ready; expanding Phase 2-3 features

---

## 🏗️ System Architecture (Critical Context)

### Data Flow Architecture
```
Client/Courier Mobile Apps (Flutter)
    ├─ Supabase: Persistent data (auth, orders, routes, jobs)
    ├─ Firebase Firestore: Real-time sync + offline persistence
    └─ SQLite (courier app): Offline GPS queue (device-local)
    
Backend (Node.js/Express)
    └─ Bridges Supabase ↔ Firebase for data sync
```

### Key Design Principles (Non-Obvious)
1. **Offline-First Courier App**: Couriers operate in areas with poor connectivity; GPS pings queue locally in SQLite and batch-sync when online (30-second intervals)
2. **Route-Alignment Matching** (Not distance-minimization): Clients must meet couriers ON their declared route within ~5km buffer; no detours. Uses PostGIS spatial queries
3. **Three Backend Services Provided** (ready to integrate into screens):
   - `OfflineGpsQueue` – SQLite management for GPS pings
   - `ConnectivityAwareGpsTracker` – Auto-detects online/offline, syncs intelligently
   - `RouteMatchingService` – Calls Supabase PostGIS functions

---

## 📁 Project Structure (What Goes Where)

### Courier App (`dropcity_courier_flutter/citydrop/`)
```
lib/
├── main.dart                           # Entry point (ProviderScope + GoRouter)
├── config/router.dart                  # Navigation (GoRouter) + auth redirects
├── providers/                          # Riverpod state (auth, location, courier data)
├── screens/                            # UI components organized by feature
│   ├── auth/                          # Login, register, phone verification
│   ├── home/                          # Dashboard (HomeScreenV2)
│   ├── route/                         # Route declaration (RouteDeclarationScreenV2)
│   ├── delivery/                      # GPS tracking, offline queue monitor
│   └── matching/                      # Real-time order matching display
├── services/                          # Business logic (✅ 3 ready-to-use)
│   ├── connectivity_aware_gps_tracker.dart  # Online/offline + sync
│   ├── offline_gps_queue.dart         # SQLite GPS storage
│   └── route_matching_service.dart    # Supabase PostGIS integration
└── firebase_options.dart              # Auto-generated Firebase config
```

### Client App (`dropcity_client_flutter/dropcity/`)
- **Similar structure** but focuses on order creation, real-time tracking (Firestore), no GPS collection
- Uses same Firebase, Supabase, and state management patterns

### Backend Server (`backend/server/`)
```
src/
├── index.js                           # Express app setup + route mounting
├── routes/                            # API endpoints (auth, orders, couriers, tracking, matching)
├── controllers/                       # Request handlers + response formatting
├── services/                          # Business logic (auth, matching, tracking)
├── middleware/                        # Auth verification, error handling, logging
└── utils/                             # Firebase + Supabase client initialization
```

### Database (`backend/db-migrations/`)
```
01_setup_rls.sql         # Row-Level Security policies (data isolation by user role)
02_create_tables.sql     # 7 core tables (clients, couriers, orders, routes, jobs, gps_pings, audit_logs)
03_create_functions.sql  # PostGIS matching functions (spatial queries)
03_create_indexes.sql    # GIST indexes (O(log n) for location queries)
```

---

## 🔌 Key Integration Points

### 1. Firebase Firestore Collections (Real-Time Sync)
- **`courier_locations`**: Current courier position (updates ~30 sec), consumed by clients for live tracking
- **`sync_queues`**: Offline GPS pings staged for backend processing (batch written from mobile)
- **`order_updates`**: Order status changes pushed to clients in real-time

### 2. Supabase PostGIS Functions
**Called by**: `RouteMatchingService.findMatchingCouriers(pickup, dropoff, threshold)`  
**Does**: Finds all couriers whose declared route falls within `threshold` meters of pickup/dropoff  
**Returns**: Ranked list with `alignment_score = distance_to_route / threshold`

### 3. Row-Level Security (RLS) Policies
- Couriers can only read/write their own GPS pings, routes, jobs
- Clients can only read/write their own orders
- System role (backend) bypasses RLS using `SUPABASE_SERVICE_KEY`

---

## 📱 Critical Service Patterns

### Pattern 1: Offline-First GPS Sync (ConnectivityAwareGpsTracker)
```dart
// Usage (in delivery_tracking_screen.dart)
final tracker = ConnectivityAwareGpsTracker();
await tracker.initialize(courierId);
await tracker.startTracking(courierId);
```
**Auto-Behavior**: 
- Online → Direct Firebase write every 30 seconds
- Offline → Queue to SQLite, batch sync when online
- Detects connectivity changes; auto-restarts sync when back online

### Pattern 2: Querying Offline Queue (OfflineGpsQueue)
```dart
// Get stats for UI display
final queue = OfflineGpsQueue();
final stats = await queue.getQueueStats();
// stats.unsyncedPings → show warning if > 50
```
**Schema** (SQLite on device):
- `id, latitude, longitude, accuracy, timestamp, synced (boolean), sync_attempt_count`

### Pattern 3: Riverpod Providers (State Management)
```dart
// In providers/courier_providers.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
final offlineQueueStatsProvider = StreamProvider<OfflineQueueStats>((ref) {
  // Real-time queue stats every 5 seconds
});
```
**Convention**: Providers ending in `Provider` are accessed via `ref.watch()`; use `StateNotifierProvider` for auth/settings

### Pattern 4: GoRouter Navigation with Auth Guard
```dart
// In config/router.dart
redirect: (context, state) {
  if (!isAuthenticated && !isLoggingIn) return '/login';
  if (isAuthenticated && isLoggingIn) return '/home';
  return null;
}
```

---

## 🛠️ Developer Workflows

### Building & Testing Courier App
```bash
cd dropcity_courier_flutter/citydrop
flutter pub get                 # Install dependencies
dart run build_runner build    # Generate Riverpod/Hive code
flutter run -d android         # or: -d iphone
```

### Backend API Testing
```bash
cd backend/server
npm install
npm start                       # Runs on http://localhost:5000
# Test endpoints: curl http://localhost:5000/health
```

### Database Setup
```bash
# Apply migrations to Supabase
# 1. Copy SQL from db-migrations/ into Supabase SQL Editor (in order)
# 2. Verify RLS policies applied: SELECT count(*) FROM information_schema.table_constraints WHERE constraint_name LIKE '%_rls';
# 3. Test PostGIS: SELECT * FROM match_delivery_to_couriers('lat', 'lng', 5000);
```

---

## ⚠️ Critical Gotchas & Conventions

1. **SQLite vs Firestore vs Supabase**: Three databases with distinct purposes
   - **SQLite** = Device-local GPS queue (offline survives crashes)
   - **Firestore** = Real-time sync engine (no RLS, used by mobile apps)
   - **Supabase** = Persistent authority (RLS enforced, source of truth)

2. **Service Keys vs User Keys**:
   - Use `SUPABASE_ANON_KEY` + user auth in mobile apps
   - Use `SUPABASE_SERVICE_KEY` in backend only (bypasses RLS)

3. **GPS Tracking Frequency**:
   - **30-second intervals** (ConnectivityAwareGpsTracker default)
   - Configurable via `_trackingIntervalSeconds` constant if battery drain is concern

4. **Offline Queue Cleanup**:
   - Auto-deletes synced pings > 30 days old
   - Monitor queue size for growing local storage issues

5. **PostGIS Spatial Index**:
   - Queries against `courier_gps_pings.location GEOMETRY(POINT, 4326)` MUST use GIST index
   - Threshold for matching ~5000 meters (configurable)

6. **Error Handling Pattern** (Backend):
   - All routes wrapped with `express-async-errors` middleware
   - Errors caught by centralized `errorHandler` middleware (no try-catch needed in most routes)
   - Returns `{success: false, message: "...", details: {...}}`

---

## 🔍 Where to Find Things

| Need | File | Key Function |
|------|------|---------------|
| Add new API endpoint | `backend/server/src/routes/*.routes.js` | Define route + controller |
| Modify database schema | `backend/db-migrations/02_create_tables.sql` | Create table, then migrate Supabase |
| Add new screen | `dropcity_courier_flutter/citydrop/lib/screens/*/` | Create widget, add route in `router.dart` |
| Fix GPS sync issues | `dropcity_courier_flutter/citydrop/lib/services/connectivity_aware_gps_tracker.dart` | Check `_syncOfflineQueue()` method |
| Adjust matching algorithm | `backend/db-migrations/03_create_functions.sql` | Modify `match_delivery_to_couriers()` SQL function |
| State management | `dropcity_courier_flutter/citydrop/lib/providers/*.dart` | Create new provider or watch existing |

---

## 📦 Dependencies (Why They Matter)

**Flutter-Specific**:
- `flutter_riverpod` – State management (chosen over Provider for better code gen)
- `go_router` – Navigation with deep linking support
- `geolocator` – High-accuracy GPS (respects permissions)
- `connectivity_plus` – Online/offline detection
- `sqflite` – SQLite on device (offline queue persistence)
- `firebase_core`, `cloud_firestore`, `firebase_messaging` – Real-time sync

**Backend-Specific**:
- `express-async-errors` – Auto-catches promise rejections in route handlers
- `dotenv` – Environment variable management (`.env` file loaded at startup)

---

## 🚀 Common Tasks

### Task: Add a new Riverpod provider
1. Create in `lib/providers/[feature]_provider.dart`
2. Use `StateNotifierProvider<NotifierClass, StateClass>` for mutable state
3. Use `FutureProvider` for async computation, `StreamProvider` for real-time data
4. Access in widgets via `ref.watch(myProvider)`

### Task: Integrate a new API endpoint
1. Add route handler in `backend/server/src/routes/[feature].routes.js`
2. Implement service logic in `src/services/[feature]Service.js`
3. Add controller to handle response in `src/controllers/[feature]Controller.js`
4. Call from Flutter via `ApiProvider` or `DioClient`

### Task: Fix offline sync delay
1. Check `ConnectivityAwareGpsTracker._trackingIntervalSeconds` (currently 30)
2. Verify `_isOnline` flag correctly reflects device state
3. Check `OfflineGpsQueue.getUnsyncedPings()` is returning data
4. Inspect Firebase logs for batch write failures

---

## 📚 Essential Documentation Files

- **[blueprint.md](../blueprint.md)** – Full system architecture, data models, matching algorithm explanation
- **[PHASE_2_3_COURIER_APP.md](../PHASE_2_3_COURIER_APP.md)** – Detailed courier app feature roadmap with code examples
- **[backend/server/README.md](../backend/server/README.md)** – API endpoints reference + setup guide
- **[backend/db-migrations/](../backend/db-migrations/)** – SQL migration scripts with comments

---

## ❓ Quick Reference

- **Where do couriers' GPS pings go?** SQLite (local) → Firebase (sync_queues) → Supabase (gps_pings table) → Firestore (courier_locations) → Client app (live tracking)
- **How does offline-first work?** Device tracks GPS even when offline, queues pings in SQLite. When online, batches send to Firebase every 30 seconds.
- **Who handles authentication?** Supabase Auth for signup/login (OTP + password). JWT stored in secure storage.
- **How are orders matched?** Client creates order → triggers `match_delivery_to_couriers()` PostGIS function → finds couriers within 5km of route → push notifications sent.

