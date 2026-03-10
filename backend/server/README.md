# DropCity Backend API Server

A comprehensive Node.js/Express backend server for the DropCity P2P logistics platform. Handles authentication, order management, courier operations, real-time tracking, and intelligent order-courier matching.

## Features

✅ **Authentication**
- Customer & Courier registration
- Email/password login
- JWT-based token authentication
- Secure password management

✅ **Order Management**
- Create and manage delivery orders
- Real-time order status tracking
- Order assignment and completion
- Order cancellation and rating system

✅ **Courier Operations**
- Courier profile management
- Online/offline status toggling
- Order acceptance/rejection
- Courier rating and statistics

✅ **Real-time Tracking**
- Live location updates
- Delivery event logging
- ETA calculation
- Location route history

✅ **Intelligent Matching**
- Find available couriers by distance
- Automatic order-courier matching
- Smart courier recommendations

✅ **Error Handling**
- Comprehensive error middleware
- Request validation
- Detailed error responses

✅ **Logging**
- Request/response logging
- Performance metrics
- Error tracking

---

## Tech Stack

- **Runtime**: Node.js 16+
- **Framework**: Express.js 4.x
- **Database**: Firebase Firestore + Supabase
- **Authentication**: Firebase Auth + JWT
- **Validation**: Built-in middleware
- **Environment**: dotenv

---

## Project Structure

```
backend/server/
├── src/
│   ├── index.js                    # Main server file
│   ├── middleware/
│   │   ├── authMiddleware.js       # JWT verification
│   │   ├── errorHandler.js         # Error handling
│   │   └── requestLogger.js        # Request logging
│   ├── routes/
│   │   ├── auth.routes.js          # Authentication endpoints
│   │   ├── order.routes.js         # Order management endpoints
│   │   ├── courier.routes.js       # Courier endpoints
│   │   ├── tracking.routes.js      # Tracking endpoints
│   │   └── matching.routes.js      # Matching endpoints
│   ├── controllers/
│   │   ├── authController.js       # Auth request handlers
│   │   ├── orderController.js      # Order request handlers
│   │   ├── courierController.js    # Courier request handlers
│   │   ├── matchingController.js   # Matching request handlers
│   │   └── trackingController.js   # Tracking request handlers
│   ├── services/
│   │   ├── authService.js          # Authentication logic
│   │   ├── orderService.js         # Order business logic
│   │   ├── courierService.js       # Courier business logic
│   │   ├── matchingService.js      # Matching algorithm
│   │   └── trackingService.js      # Tracking logic
│   └── utils/
│       ├── firebase.js             # Firebase initialization
│       └── supabase.js             # Supabase client
├── package.json                    # Dependencies & scripts
├── .env.example                    # Environment variables template
├── API_DOCUMENTATION.md            # Complete API documentation
└── README.md                       # This file
```

---

## Installation

### Prerequisites
- Node.js 16 or higher
- npm or yarn
- Firebase project (dropcity-aadac)
- Supabase instance

### Steps

1. **Clone and navigate to backend directory:**
   ```bash
   cd backend/server
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your configuration:
   ```env
   PORT=5000
   FIREBASE_PROJECT_ID=dropcity-aadac
   FIREBASE_PRIVATE_KEY=<your_private_key>
   FIREBASE_CLIENT_EMAIL=<your_client_email>
   SUPABASE_URL=https://jchieiiunnvjawmdsgqe.supabase.co
   SUPABASE_SERVICE_KEY=<your_service_key>
   JWT_SECRET=<your_jwt_secret_min_32_chars>
   ```

4. **Start the server:**
   ```bash
   npm start
   ```
   
   Server will run on `http://localhost:5000`

---

## Available Scripts

```bash
# Start server in development mode
npm start

# Start with nodemon (auto-restart on changes)
npm run dev

# Start server in production mode
npm run prod

# View available scripts
npm run
```

---

## API Endpoints Overview

### Authentication (`/api/auth`)
- `POST /register/customer` - Register new customer
- `POST /register/courier` - Register new courier
- `POST /login` - Login with email & password
- `POST /logout` - Logout (client-side token removal)
- `GET /me` - Get current user profile
- `PUT /update-password` - Update password

### Orders (`/api/orders`)
- `POST /` - Create new order
- `GET /` - Get customer's orders
- `GET /:orderId` - Get order details
- `PUT /:orderId/status` - Update order status
- `PUT /:orderId/assign` - Assign courier to order
- `PUT /:orderId/complete` - Mark order as completed
- `PUT /:orderId/cancel` - Cancel order
- `POST /:orderId/rate` - Rate order/courier

### Couriers (`/api/couriers`)
- `GET /profile` - Get courier profile
- `PUT /profile` - Update courier profile
- `PUT /status` - Toggle online/offline status
- `GET /orders` - Get courier's orders
- `POST /:orderId/accept` - Accept delivery order
- `POST /:orderId/reject` - Reject delivery order
- `GET /stats` - Get courier statistics
- `POST /:courierId/rate` - Rate courier

### Tracking (`/api/tracking`)
- `POST /location` - Update courier location
- `GET /order/:orderId` - Get live order tracking
- `GET /route/:orderId` - Get courier's route history
- `POST /estimate/:courierId` - Estimate delivery time
- `POST /event/:orderId` - Log delivery event
- `GET /events/:orderId` - Get order's delivery events

### Matching (`/api/matching`)
- `POST /find-couriers` - Find available couriers
- `POST /match` - Match order with courier
- `GET /orders` - Get matching orders for courier

---

## Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

**Token Structure:**
```json
{
  "uid": "user_id",
  "email": "user@example.com",
  "userType": "customer|courier",
  "iat": 1234567890,
  "exp": 1234567890
}
```

---

## Error Handling

The API returns consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errorCode": "ERROR_CODE",
  "statusCode": 400
}
```

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request / Validation Error
- `401` - Unauthorized / Invalid Token
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict (e.g., duplicate order)
- `500` - Server Error

---

## Database Schema

### Collections (Firestore)

**Users (implicit via Auth)**
- uid, email, userType (customer/courier), createdAt

**Customers**
- customerId, fullName, phoneNumber, email, profileImage, createdAt

**Couriers**
- courierId, fullName, phoneNumber, email, vehicleType, licenseNumber
- currentLocation, isOnline, rating, deliveriesCompleted, createdAt

**Pending Orders**
- orderId, customerId, courierId, status, pickupLocation, deliveryLocation
- packageType, estimatedCost, createdAt, matchedAt, completedAt

**Location History**
- courierId, latitude, longitude, accuracy, timestamp

**Delivery Events**
- orderId, eventType (picked_up, delivered, etc.), timestamp

**Notifications**
- type, userId, orderId, message, read, createdAt

---

## Testing

### Using cURL

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

**Login:**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

**Create Order (requires token):**
```bash
curl -X POST http://localhost:5000/api/orders \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pickupLocation": {"latitude": 12.9716, "longitude": 77.5946},
    "deliveryLocation": {"latitude": 12.9352, "longitude": 77.6245},
    "deliveryAddress": "123 Main Street, City",
    "packageType": "parcel"
  }'
```

### Using Postman

1. Import the collection from API_DOCUMENTATION.md
2. Set `Authorization` type to Bearer Token
3. Paste your JWT token
4. Test endpoints

---

## Environment Variables

See `.env.example` for all available options:

- `PORT` - Server port (default: 5000)
- `NODE_ENV` - Environment (development/production)
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Firebase private key
- `FIREBASE_CLIENT_EMAIL` - Firebase service account email
- `SUPABASE_URL` - Supabase instance URL
- `SUPABASE_SERVICE_KEY` - Supabase service role key
- `JWT_SECRET` - JWT signing secret (min 32 chars)
- `JWT_EXPIRE` - JWT expiration time (default: 7d)
- `GOOGLE_MAPS_API_KEY` - Google Maps API key

---

## Performance Optimization

### Current Implementation
- Express middleware for request validation
- Error boundary handling
- Async/await for non-blocking operations
- Firestore indexing for queries

### Recommendations
- Add caching layer (Redis)
- Implement rate limiting
- Add database connection pooling
- Compress responses (gzip)
- Implement pagination for list endpoints
- Add request timeouts

---

## Security Considerations

✅ **Implemented**
- JWT token-based authentication
- Password hashing (via Firebase)
- Request validation middleware
- CORS enabled
- Error message sanitization

🔄 **Recommended for Production**
- HTTPS/SSL enforcement
- Rate limiting per IP/user
- Input sanitization for NoSQL injection
- Helmet.js for security headers
- Request body size limits
- CSRF protection if using sessions

---

## Deployment

### To Heroku:
```bash
# Install Heroku CLI
npm i -g heroku

# Login
heroku login

# Create app
heroku create dropcity-backend

# Set environment variables
heroku config:set PORT=5000 -a dropcity-backend
heroku config:set FIREBASE_PROJECT_ID=dropcity-aadac -a dropcity-backend

# Deploy
git push heroku main
```

### To Firebase Functions:
```bash
npm install -g firebase-tools
firebase deploy --only functions
```

---

## Troubleshooting

### Port Already in Use
```bash
# macOS/Linux
lsof -i :5000
kill -9 <PID>

# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

### Firebase Connection Issues
- Verify FIREBASE_PROJECT_ID is correct
- Check private key formatting (include `\n` for line breaks)
- Ensure service account has Firestore access

### JWT Token Expired
- Token expires after 7 days by default
- Client must refresh by logging in again

### CORS Errors
- Check CORS_ORIGIN in .env matches client URL
- Update CORS configuration if adding new frontend URLs

---

## Contributing

1. Create a feature branch: `git checkout -b feature/new-feature`
2. Commit changes: `git commit -am 'Add feature'`
3. Push branch: `git push origin feature/new-feature`
4. Open a Pull Request

---

## License

MIT License - See LICENSE file for details

---

## Support

For issues or questions:
- Check API_DOCUMENTATION.md
- Review error logs in console
- Verify .env configuration
- Check Firebase/Supabase project settings

---

## Roadmap

- [ ] WebSocket support for real-time updates
- [ ] Email notifications
- [ ] SMS notifications
- [ ] Payment gateway integration
- [ ] Analytics dashboard
- [ ] Admin panel
- [ ] API rate limiting
- [ ] Automated testing
- [ ] API versioning (v1, v2, etc.)
- [ ] GraphQL support

---

**Last Updated:** 2024
**API Version:** 1.0.0
**Status:** Ready for Development/Testing
