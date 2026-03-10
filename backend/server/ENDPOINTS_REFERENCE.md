# DropCity API - Complete Endpoint Reference

**Last Updated:** February 26, 2026 | **API Version:** v1

---

## Quick Start

**Base URL:** `http://localhost:5000/api`  
**Authentication:** Add header `Authorization: Bearer <JWT_TOKEN>` to protected endpoints

---

## 1. AUTHENTICATION

### Register Customer
```
POST /auth/register/customer
```
**Body:** `{ email, password, fullName, phoneNumber }`  
**Response:** `{ success, message, customerId, email, fullName }`

### Register Courier
```
POST /auth/register/courier
```
**Body:** `{ email, password, fullName, phoneNumber, vehicleType, vehicleNumber, licenseNumber }`  
**Response:** `{ success, message, courierId, email, fullName, vehicleType, rating, ratingCount }`

### Login
```
POST /auth/login
```
**Body:** `{ email, password }`  
**Response:** `{ success, message, token, userId, email, userType }`

---

## 2. ORDERS

### Create Order
```
POST /orders
```
**Auth:** Required  
**Body:**
```json
{
  "pickupLocation": { "latitude": 40.7128, "longitude": -74.0060 },
  "pickupAddress": "123 Main St",
  "deliveryLocation": { "latitude": 40.7580, "longitude": -73.9855 },
  "deliveryAddress": "456 Park Ave",
  "description": "Package",
  "weight": 2.5,
  "estimatedDistance": 5.2
}
```

### Get All Customer Orders
```
GET /orders
```
**Auth:** Required  
**Query:** `?status=pending` (optional)

### Get Order Details
```
GET /orders/:orderId
```
**Auth:** Required

### Update Order Status
```
PUT /orders/:orderId/status
```
**Auth:** Required  
**Body:** `{ status: "in_progress|pending|matched|accepted|completed|cancelled" }`

### Assign Courier to Order
```
PUT /orders/:orderId/assign
```
**Auth:** Required  
**Body:** `{ courierId: "uuid" }`

### Complete Order
```
PUT /orders/:orderId/complete
```
**Auth:** Required

### Cancel Order
```
PUT /orders/:orderId/cancel
```
**Auth:** Required  
**Body:** `{ reason: "string" }`

### Rate Order (Rate Courier)
```
POST /orders/:orderId/rate
```
**Auth:** Required  
**Body:**
```json
{
  "rating": 4,
  "review": "Excellent service!"
}
```
**Note:** Updates courier's average rating and rating count

---

## 3. TRACKING

### Update Courier Location
```
POST /tracking/location
```
**Auth:** Required  
**Body:** `{ latitude, longitude, accuracy }`

### Get Live Order Tracking
```
GET /tracking/order/:orderId
```
**Auth:** Required  
**Response includes:** Courier details, current location, order status, ETA

### Get Courier Location Route
```
GET /tracking/route/:orderId
```
**Auth:** Required  
**Returns:** Complete route history with timestamps

### Estimate Delivery Time
```
POST /tracking/estimate/:courierId
```
**Auth:** Required  
**Body:** `{ latitude, longitude }`  
**Response:** `{ distance, estimatedMinutes, estimatedArrivalTime }`

### Store Delivery Event
```
POST /tracking/event/:orderId
```
**Auth:** Required  
**Body:**
```json
{
  "eventType": "picked_up | in_transit | near_delivery | delivered | cancelled",
  "details": { "latitude", "longitude", "notes" }
}
```

### Get Delivery Events
```
GET /tracking/events/:orderId
```
**Auth:** Required  
**Returns:** Array of events in chronological order

---

## 4. COURIER MATCHING

### Find Available Couriers
```
POST /matching/find-couriers
```
**Auth:** NOT Required  
**Body:** `{ latitude, longitude, maxDistance }`  
**Response:** List of available couriers sorted by distance & rating

### Match Order with Courier
```
POST /matching/match
```
**Auth:** Required  
**Body:** `{ orderId, courierId }`

### Get Matching Orders for Courier
```
GET /matching/orders
```
**Auth:** Required  
**Returns:** Available orders near courier location

---

## 5. COURIER MANAGEMENT

### Get Courier Profile
```
GET /couriers/profile
```
**Auth:** Required  
**Response:** Complete courier details, rating, vehicle info, online status

### Update Courier Status
```
PUT /couriers/status
```
**Auth:** Required  
**Body:** `{ isOnline: true|false }`

### Get Courier Orders
```
GET /couriers/orders
```
**Auth:** Required  
**Query:** `?status=completed` (optional)

---

## KEY FEATURES IMPLEMENTED

✅ **Order Management**
- Full order lifecycle: create → match → accept → in_progress → complete/cancel
- Order rating system (1-5 stars with feedback)
- OTP for delivery verification
- Order status tracking

✅ **Courier Matching**
- Geolocation-based courier discovery
- Distance calculation (Haversine formula)
- Matching by proximity and rating
- Real-time courier availability

✅ **Real-time Tracking**
- Live courier location updates
- Delivery event logging (picked_up, in_transit, delivered, etc.)
- ETA calculation based on distance & speed
- Complete route history with timestamps

✅ **Rating System**
- Customers rate couriers after delivery (1-5 scale)
- Automatic average rating calculation
- Rating count tracking for courier reputation

✅ **Authentication**
- Separate registration for customers and couriers
- JWT token-based authentication
- Firebase & Supabase integration
- Secure password handling

---

## RESPONSE FORMAT

**All responses follow this format:**

```json
{
  "success": true|false,
  "message": "string",
  "statusCode": 200|201|400|401|404|500,
  "data": "endpoint-specific"
}
```

---

## ERROR HANDLING

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (missing/invalid fields) |
| 401 | Unauthorized (invalid/missing token) |
| 404 | Not Found |
| 500 | Server Error |

---

## TESTING WITH CURL

**Register Customer:**
```bash
curl -X POST http://localhost:5000/api/auth/register/customer \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "fullName": "Test User",
    "phoneNumber": "+1234567890"
  }'
```

**Create Order:**
```bash
curl -X POST http://localhost:5000/api/orders \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pickupLocation": {"latitude": 40.7128, "longitude": -74.0060},
    "pickupAddress": "123 Main St",
    "deliveryLocation": {"latitude": 40.7580, "longitude": -73.9855},
    "deliveryAddress": "456 Park Ave",
    "description": "Package",
    "weight": 2.5,
    "estimatedDistance": 5.2
  }'
```

**Update Courier Location:**
```bash
curl -X POST http://localhost:5000/api/tracking/location \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 40.7150,
    "longitude": -74.0070,
    "accuracy": 15
  }'
```

---

**API Status:** ✅ Fully Operational  
**Next Phase:** Frontend integration & WebSocket real-time updates
