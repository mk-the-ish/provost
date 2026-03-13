`# Google Directions API Integration for Route Declaration

This document explains how the DropCity courier app integrates with Google Directions API to fetch real road routes instead of straight-line paths.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter Courier App                       │
│         (route_declaration_screen.dart)                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │  DirectionsService         │
        │  (directions_service.dart) │
        │                            │
        │  - getRoutePoints()        │
        │  - getRouteDetails()       │
        │  - encodePolyline()        │
        │  - decodePolyline()        │
        └────────────┬───────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────┐
        │  Google Directions API                 │
        │  flutter_polyline_points package       │
        │                                        │
        │  Returns:                              │
        │  - Encoded polyline string             │
        │  - Distance                            │
        │  - Duration                            │
        │  - Polyline points count               │
        └────────────┬───────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │  Encoded Polyline          │
        │  "lat1,lng1|lat2,lng2|..." │
        └────────────┬───────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────┐
        │  Backend API (Node.js/Express)         │
        │  POST /api/routes/declare              │
        │                                        │
        │  Receives:                             │
        │  - Encoded polyline                    │
        │  - Start/end coordinates               │
        │  - Distance & duration                 │
        │  - Point count                         │
        └────────────┬───────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────┐
        │  Supabase PostgreSQL                   │
        │  courier_routes table                  │
        │                                        │
        │  Stores:                               │
        │  - encoded_polyline (TEXT)             │
        │  - distance_km (DECIMAL)               │
        │  - status, timestamps, etc.            │
        └────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────┐
        │  PostGIS Spatial Queries               │
        │  find_orders_near_route()              │
        │                                        │
        │  Matches orders to courier route       │
        │  using actual road paths               │
        └────────────────────────────────────────┘
```

## Step-by-Step Flow

### 1. **Courier Declares Route on Mobile**

```dart
// User taps map to set start location
_onMapTap(LatLng position) {
  _startLocation = position;
  _drawPolyline(); // Fetch real route
}

// User taps map to set end location
_onMapTap(LatLng position) {
  _endLocation = position;
  _drawPolyline(); // Fetch real route
}

// Courier clicks "Declare Route" button
_declareRoute() {
  _sendRouteToBackend(); // Send encoded polyline
}
```

### 2. **DirectionsService Fetches Road Path**

```dart
// From directions_service.dart
Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
  final result = await _polylinePoints.getRouteBetweenCoordinates(
    googleApiKey: 'YOUR_API_KEY',
    request: PolylineRequest(
      origin: PointLatLng(start.latitude, start.longitude),
      destination: PointLatLng(end.latitude, end.longitude),
      mode: TravelMode.driving,
    ),
  );
  
  // Returns ~50-200+ points following actual roads
  return result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
}
```

### 3. **Polyline Encoded for Transmission**

```dart
// Encode route points to compact string
String encodePolyline(List<LatLng> points) {
  return points.map((p) => '${p.latitude},${p.longitude}').join('|');
}

// Example output:
// "40.7128,-74.0060|40.7138,-74.0058|40.7148,-74.0056|..."
```

### 4. **Backend Receives and Stores**

```javascript
// POST /api/routes/declare
router.post('/declare', authMiddleware, async (req, res) => {
  const {
    startLat, startLng,
    endLat, endLng,
    encodedPolyline,    // "lat,lng|lat,lng|..."
    distance,           // "12.5" km
    estimatedDuration,  // "45 mins"
    polylinePointCount  // 156 points
  } = req.body;

  // Save to Supabase
  await supabaseClient.from('courier_routes').insert({
    encoded_polyline: encodedPolyline,
    distance_km: parseFloat(distance),
    estimated_duration: estimatedDuration,
    // ... other fields
  });
});
```

### 5. **PostGIS Matches Orders to Route**

```sql
-- Find all orders within 5km of courier's road path
SELECT * FROM find_orders_near_route(
  route_line := decode_polyline_to_linestring('40.7128,-74.0060|40.7138,...'),
  threshold_meters := 5000
);

-- Returns orders whose pickup/delivery is close to actual route
-- Not just straight-line distance!
```

## Key Advantages

1. **Real Road Paths**: Uses actual road networks instead of straight lines
2. **Accurate Matching**: Orders matched to courier routes follow real driving paths
3. **Distance Accuracy**: True driving distance (not as-the-crow-flies)
4. **Compact Storage**: Polyline encoding reduces storage vs. full coordinate array
5. **Spatial Indexing**: GIST indexes enable fast distance queries

## Setup Instructions

### 1. Get Google Directions API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create/select project
3. Enable "Maps SDK for Android" and "Maps SDK for iOS"
4. Enable "Directions API"
5. Create API Key credential
6. Copy key to `directions_service.dart`:

```dart
static const String _googleMapsApiKey = 'AIzaSy...YOUR_KEY...';
```

### 2. Run Database Migrations

Apply migrations in order:

```sql
-- 1. Create courier_routes table
psql -U postgres -d dropcity -f 04_courier_routes_table.sql

-- 2. Create PostGIS functions
psql -U postgres -d dropcity -f 05_postgis_route_matching.sql
```

Or paste directly in Supabase SQL Editor.

### 3. Update Backend Server

Routes are automatically registered:

```javascript
// In src/index.js
app.use('/api/routes', routeDeclarationRoutes);
```

### 4. Test the Flow

```bash
# 1. Start backend server
cd backend/server
npm start

# 2. Run courier app
cd dropcity_courier_flutter/citydrop
flutter run -d <device_id>

# 3. On app:
# - Tap map to set start location
# - Tap map to set end location
# - Click "Declare Route"
# - Watch real polyline draw on map
# - Backend receives encoded polyline
```

## API Endpoints

### Declare Route

```http
POST /api/routes/declare
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>

{
  "startLat": 40.7128,
  "startLng": -74.0060,
  "endLat": 40.7580,
  "endLng": -73.9855,
  "encodedPolyline": "40.7128,-74.0060|40.7138,-74.0058|40.7148,-74.0056|...",
  "distance": "12.5",
  "estimatedDuration": "45 mins",
  "polylinePointCount": 156,
  "timestamp": "2024-03-12T10:30:00Z"
}

Response:
{
  "success": true,
  "data": {
    "routeId": 12345,
    "distance": "12.5",
    "estimatedDuration": "45 mins",
    "matchedOrdersUrl": "/api/routes/12345/match-orders"
  }
}
```

### Match Orders to Route

```http
POST /api/routes/:routeId/match-orders
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>

{
  "threshold": 5000  // meters (5km)
}

Response:
{
  "success": true,
  "data": {
    "routeId": 12345,
    "matchedOrders": [
      {
        "id": 1,
        "order_id": "ORD-001",
        "pickup_latitude": 40.7200,
        "pickup_longitude": -74.0050,
        "distance_to_route": 2340  // meters from route
      },
      ...
    ],
    "matchCount": 4
  }
}
```

### Get Route Details

```http
GET /api/routes/:routeId
Authorization: Bearer <JWT_TOKEN>

Response:
{
  "success": true,
  "data": {
    "id": 12345,
    "courier_id": "uuid-...",
    "start_latitude": 40.7128,
    "start_longitude": -74.0060,
    "end_latitude": 40.7580,
    "end_longitude": -73.9855,
    "encoded_polyline": "40.7128,-74.0060|40.7138,-74.0058|...",
    "distance_km": 12.5,
    "estimated_duration": "45 mins",
    "decodedPolylinePoints": [
      {"latitude": 40.7128, "longitude": -74.0060},
      {"latitude": 40.7138, "longitude": -74.0058},
      ...
    ],
    "status": "active",
    "matched_count": 4,
    "created_at": "2024-03-12T10:30:00Z"
  }
}
```

## Data Models

### Courier Routes Table (Supabase)

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| courier_id | UUID | Reference to auth.users |
| start_latitude | DECIMAL | Pickup location latitude |
| start_longitude | DECIMAL | Pickup location longitude |
| end_latitude | DECIMAL | Delivery location latitude |
| end_longitude | DECIMAL | Delivery location longitude |
| encoded_polyline | TEXT | "lat,lng\|lat,lng\|..." |
| distance_km | DECIMAL | Driving distance |
| estimated_duration | VARCHAR | "45 mins", "1h 30m" |
| polyline_point_count | INTEGER | Number of route points |
| status | VARCHAR | active, completed, abandoned |
| matched_orders | JSONB | Array of matched order IDs |
| matched_count | INTEGER | Count of matched orders |
| created_at | TIMESTAMP | Route creation time |
| updated_at | TIMESTAMP | Last update time |
| completed_at | TIMESTAMP | Completion time |

### Route Matching Algorithm

```sql
WHERE
  -- Orders must be pending
  o.status IN ('pending', 'accepted', 'in_transit')
  -- AND pickup/delivery within 5km of route (using PostGIS)
  AND ST_DWithin(
    ST_GeomFromText('POINT(lng lat)', 4326),
    route_line,
    5000 / 111000  -- Convert meters to degrees
  )
ORDER BY distance_to_route ASC
```

## Performance Considerations

1. **Google Directions API Calls**:
   - ~0.5-1 second per request
   - Rate limited to 50 requests/second
   - Consider caching for repeated routes

2. **Polyline Encoding**:
   - ~100-200 points for typical 20km route
   - Encoded string ~2-4KB
   - Saves 20-30% vs full coordinate arrays

3. **PostGIS Queries**:
   - GIST index on order locations (~50-100ms for 10k orders)
   - Linear scan without index (~5-10 seconds)

4. **Database**:
   - RLS policies: Minimal overhead (<1ms)
   - Indexes: Essential for sub-second queries

## Troubleshooting

### "Error: Google Directions API key invalid"
- Check API key is correct in `directions_service.dart`
- Verify API key has Directions API enabled
- Check quota limits in Google Cloud Console

### "Backend not receiving polyline"
- Verify API client has `http://localhost:5000/api` base URL
- Check network connectivity (use `flutter run -vvv` for debug)
- Confirm JWT token is valid

### "Orders not matching to route"
- Check PostGIS functions are created
- Verify order locations are valid (not NULL)
- Test threshold distance (default 5000m)
- Run: `SELECT find_orders_near_route(route_line, 5000);`

### "Polyline points mismatch"
- Encoding/decoding should be reversible
- Test: `decode_polyline_to_linestring(encode_polyline(points))`
- Check for rounding errors (use 8 decimal places)

## Future Enhancements

1. **Route Optimization**: 
   - Add multiple stops to optimize order sequence
   - Use Google Routes Optimization API

2. **Real-time Route Updates**:
   - Update polyline as courier travels
   - Recalculate matching orders dynamically

3. **Offline Polylines**:
   - Cache polylines locally
   - Use offline maps (e.g., OsmAnd)

4. **Alternative Routes**:
   - Show multiple route options
   - Let courier choose preferred path

5. **Cost Integration**:
   - Calculate tolls/fuel costs
   - Factor into courier payment

## References

- [Google Directions API Docs](https://developers.google.com/maps/documentation/directions)
- [flutter_polyline_points Package](https://pub.dev/packages/flutter_polyline_points)
- [PostGIS Distance Functions](https://postgis.net/docs/ST_Distance.html)
- [Polyline Encoding Algorithm](https://developers.google.com/maps/documentation/utilities/polylinealgorithm)
- [Supabase PostGIS Guide](https://supabase.com/docs/guides/database/extensions/postgis)
