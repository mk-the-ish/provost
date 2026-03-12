# Activate Backend API Integration

Once the backend server is running, uncomment the actual API call in the route declaration screen to send polylines to the server.

## Current State (Mock/Offline)

The route declaration currently prints the data to console but doesn't send to backend:

```dart
// In route_declaration_screen.dart _sendRouteToBackend()
print('Route data ready for backend: $routeData');
// TODO: Send to backend API
// final apiProvider = ref.read(apiProvider);
// await apiProvider.post('/api/routes/declare', routeData);
```

## Step 1: Verify Backend is Running

```bash
# Terminal 1: Start backend server
cd backend/server
npm start

# Check it's running
curl http://localhost:5000/health
# Expected: {"status":"ok","timestamp":"2024-03-12..."}
```

## Step 2: Enable API Integration in Flutter

### Option A: Using Existing ApiProvider (Riverpod)

If you have an `api_provider.dart`, it's already configured:

```dart
// lib/providers/api_provider.dart should have:
final apiProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: 'http://localhost:5000/api', // ADB reverse or WiFi IP
  );
});
```

**In route_declaration_screen.dart:**

```dart
// 1. Import Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 2. Make StatefulWidget → ConsumerStatefulWidget
class RouteDeclarationScreen extends ConsumerStatefulWidget {
  const RouteDeclarationScreen({super.key});

  @override
  ConsumerState<RouteDeclarationScreen> createState() => 
    _RouteDeclarationScreenState();
}

class _RouteDeclarationScreenState 
    extends ConsumerState<RouteDeclarationScreen> {
  // ... existing code ...

  void _sendRouteToBackend() async {
    try {
      final routeData = {
        'startLat': _startLocation!.latitude,
        'startLng': _startLocation!.longitude,
        'endLat': _endLocation!.latitude,
        'endLng': _endLocation!.longitude,
        'encodedPolyline': _encodedPolyline,
        'distance': _routeDetails?.distance.toStringAsFixed(2),
        'estimatedDuration': _routeDetails?.duration,
        'polylinePointCount': _routeDetails?.pointCount,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // UNCOMMENT THIS BLOCK:
      final apiProvider = ref.read(apiProvider);
      final response = await apiProvider.post(
        '/routes/declare',
        data: routeData,
      );

      if (response['success'] == true) {
        final routeId = response['data']['routeId'];
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _routeDeclared = true;
          });
          _addOrderMarkers();
          _showOrderBottomSheet();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Route declared! Route ID: $routeId\n'
                '${_routeDetails?.distance.toStringAsFixed(1)}km, '
                '${_routeDetails?.duration}',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

### Option B: Manual Dio Implementation

If no Riverpod provider exists, use Dio directly:

```dart
// In route_declaration_screen.dart

import 'package:dio/dio.dart';

void _sendRouteToBackend() async {
  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:5000/api',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    final routeData = {
      'startLat': _startLocation!.latitude,
      'startLng': _startLocation!.longitude,
      'endLat': _endLocation!.latitude,
      'endLng': _endLocation!.longitude,
      'encodedPolyline': _encodedPolyline,
      'distance': _routeDetails?.distance.toStringAsFixed(2),
      'estimatedDuration': _routeDetails?.duration,
      'polylinePointCount': _routeDetails?.pointCount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Get JWT token from Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final token = await user.getIdToken();

    // Send to backend
    final response = await dio.post(
      '/routes/declare',
      data: routeData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data['success'] == true) {
      final routeId = response.data['data']['routeId'];
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _routeDeclared = true;
        });
        _addOrderMarkers();
        _showOrderBottomSheet();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Route declared! ID: $routeId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  } on DioException catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

## Step 3: Test the Integration

### Using cURL

```bash
# 1. Get JWT token (replace with your test user)
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "courier@example.com",
    "password": "password123"
  }'

# Extract token from response
# TOKEN="eyJhbGciOiJIUzI1NiIs..."

# 2. Declare route
curl -X POST http://localhost:5000/api/routes/declare \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startLat": 40.7128,
    "startLng": -74.0060,
    "endLat": 40.7580,
    "endLng": -73.9855,
    "encodedPolyline": "40.7128,-74.0060|40.7138,-74.0058|40.7148,-74.0056",
    "distance": "12.5",
    "estimatedDuration": "45 mins",
    "polylinePointCount": 156,
    "timestamp": "2024-03-12T10:30:00Z"
  }'

# Expected response:
# {
#   "success": true,
#   "message": "Route declared successfully",
#   "data": {
#     "routeId": 12345,
#     "distance": "12.5",
#     "matchedOrdersUrl": "/api/routes/12345/match-orders"
#   }
# }
```

### In Flutter App

1. **Start backend server**:
   ```bash
   cd backend/server && npm start
   ```

2. **Run courier app**:
   ```bash
   cd dropcity_courier_flutter/citydrop
   flutter run -d <device_id>
   ```

3. **Test route declaration**:
   - Tap map to set start location
   - Tap map to set end location
   - Wait for polyline to calculate
   - Click "Declare Route" button
   - Check logs for API response

4. **Verify backend received it**:
   ```bash
   # Query database
   SELECT * FROM courier_routes WHERE courier_id = '<user_id>' 
   ORDER BY created_at DESC LIMIT 1;
   ```

## Step 4: Implement Order Matching

Once route is saved, match orders to it:

```dart
// In route_declaration_screen.dart
void _showOrderBottomSheet() {
  // Get route ID from backend response
  final routeId = response.data['data']['routeId'];
  
  // Call match orders endpoint
  _matchOrdersToRoute(routeId);
}

Future<void> _matchOrdersToRoute(int routeId) async {
  try {
    final response = await dio.post(
      '/routes/$routeId/match-orders',
      data: {'threshold': 5000}, // 5km
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final matchedOrders = response.data['data']['matchedOrders'] as List;
    
    // Update UI with matched orders
    setState(() {
      _matchedOrders = matchedOrders.cast<Map<String, dynamic>>();
    });

    if (matchedOrders.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${matchedOrders.length} orders matched!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print('Error matching orders: $e');
  }
}
```

## Step 5: Network Configuration

### For Android Device on Same Network

**Option 1: WiFi IP Address**
```dart
// In api_provider.dart
baseUrl: 'http://192.168.1.100:5000/api', // Your PC's WiFi IP
```

Find your PC's IP:
```bash
# Windows
ipconfig
# Look for "IPv4 Address" (e.g., 192.168.1.100)

# macOS/Linux
ifconfig
```

**Option 2: ADB Reverse Tunneling**
```bash
adb reverse tcp:5000 tcp:5000
```

Then use localhost:
```dart
baseUrl: 'http://localhost:5000/api'
```

## Debugging

### Enable HTTP Logging

```dart
// Add this to see all HTTP requests
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final dio = Dio();
dio.interceptors.add(
  PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    compact: true,
  ),
);
```

### Check Backend Logs

```bash
# Terminal with running backend
# You should see:
# POST /api/routes/declare
# {
#   body: { startLat, startLng, ... },
#   statusCode: 201
# }
```

### Test Route Matching

```bash
# After declaring a route, test matching:
curl -X POST http://localhost:5000/api/routes/12345/match-orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"threshold": 5000}'

# Expected: List of orders within 5km of route polyline
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection refused | Backend not running | `npm start` in backend/server |
| 401 Unauthorized | Invalid/expired token | Get fresh token via login |
| 404 Not Found | Endpoint not registered | Verify routes.routes.js imported in index.js |
| 500 Server Error | Database error | Check Supabase connection, run migrations |
| encodedPolyline null | Google Directions API failed | Check API key, network |

## Next: Complete Integration

Once this works:

1. ✅ Routes saved to Supabase
2. ✅ Polylines stored with routes
3. ✅ Orders matched via PostGIS
4. ✅ UI shows matched orders

Then implement:
- [ ] Route completion tracking
- [ ] Real-time location sync to route
- [ ] Order pickup/delivery confirmation
- [ ] Route statistics (distance, time, earnings)
- [ ] Offline route caching
