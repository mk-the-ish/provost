require('dotenv').config();
require('express-async-errors');
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIO = require('socket.io');

// Import Firebase and Supabase utils to ensure initialization
require('./utils/firebase');
require('./utils/supabase');

// Import routes
const authRoutes = require('./routes/auth.routes');
const orderRoutes = require('./routes/order.routes');
const courierRoutes = require('./routes/courier.routes');
const trackingRoutes = require('./routes/tracking.routes');
const matchingRoutes = require('./routes/matching.routes');
const routeDeclarationRoutes = require('./routes/routes.routes');

// Import middleware
const { errorHandler } = require('./middleware/errorHandler');
const { requestLogger } = require('./middleware/requestLogger');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env.PORT || 5000;

// Store active client connections for location tracking
// Key: clientId, Value: { socketId, userId, userType, orderId }
const activeConnections = new Map();
// Key: courierId, Value: { socketId, currentLocation }
const courierLocations = new Map();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/couriers', courierRoutes);
app.use('/api/tracking', trackingRoutes);
app.use('/api/matching', matchingRoutes);
app.use('/api/routes', routeDeclarationRoutes);

// ============================================================
// SOCKET.IO REAL-TIME TRACKING
// ============================================================
io.on('connection', (socket) => {
  console.log(`📡 Client connected: ${socket.id}`);

  // Client joins a specific order tracking room
  socket.on('join-order', (data) => {
    const { orderId, userId, userType } = data; // userType: 'client' or 'courier'
    const roomId = `order-${orderId}`;

    socket.join(roomId);
    activeConnections.set(socket.id, { orderId, userId, userType, roomId });

    console.log(`✅ ${userType} joined order ${orderId}: ${socket.id}`);
  });

  // Courier broadcasts live location update
  socket.on('location-update', (data) => {
    const { courierId, orderId, latitude, longitude, accuracy } = data;
    const roomId = `order-${orderId}`;

    // Store courier location
    courierLocations.set(courierId, {
      socketId: socket.id,
      latitude,
      longitude,
      accuracy,
      timestamp: new Date().toISOString(),
    });

    // Broadcast location ONLY to clients in this order's room
    io.to(roomId).emit('courier-location-update', {
      courierId,
      latitude,
      longitude,
      accuracy,
      timestamp: new Date().toISOString(),
    });

    console.log(`📍 Courier ${courierId} updated location for order ${orderId}`);
  });

  // Client receives delivery PIN (sent once when order is matched)
  socket.on('request-delivery-pin', (data) => {
    const { orderId, deliveryPin } = data;
    const roomId = `order-${orderId}`;

    io.to(roomId).emit('delivery-pin-update', {
      orderId,
      deliveryPin,
      message: 'Share this PIN with the courier for delivery verification',
    });

    console.log(`🔐 Delivery PIN sent for order ${orderId}`);
  });

  // Courier sends photo (pickup or delivery)
  socket.on('photo-update', (data) => {
    const { courierId, orderId, photoType, photoUrl } = data; // photoType: 'pickup' or 'delivery'
    const roomId = `order-${orderId}`;

    io.to(roomId).emit('photo-received', {
      courierId,
      orderId,
      photoType,
      photoUrl,
      timestamp: new Date().toISOString(),
    });

    console.log(`📷 ${photoType} photo received for order ${orderId}`);
  });

  // Order status updates (broadcasted to all in room)
  socket.on('order-status-update', (data) => {
    const { orderId, status, message } = data;
    const roomId = `order-${orderId}`;

    io.to(roomId).emit('status-changed', {
      orderId,
      status,
      message,
      timestamp: new Date().toISOString(),
    });

    console.log(`🔄 Order ${orderId} status updated to ${status}`);
  });

  // Client or Courier disconnects
  socket.on('disconnect', () => {
    const connection = activeConnections.get(socket.id);
    
    if (connection) {
      const { orderId, userType, roomId } = connection;
      activeConnections.delete(socket.id);

      io.to(roomId).emit('user-disconnected', {
        orderId,
        userType,
        message: `${userType} disconnected from tracking`,
      });

      console.log(`❌ ${userType} disconnected from order ${orderId}: ${socket.id}`);
    }

    // Clean up courier location if it was a courier
    courierLocations.forEach((value, key) => {
      if (value.socketId === socket.id) {
        courierLocations.delete(key);
        console.log(`📍 Courier location cleared for ${key}`);
      }
    });
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.path,
  });
});

// Error Handler (must be last)
app.use(errorHandler);

// Start Server
server.listen(PORT, () => {
  console.log(`🚀 DropCity Backend running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔐 Firebase Project: ${process.env.FIREBASE_PROJECT_ID}`);
  console.log(`🔌 Socket.io ready for real-time tracking`);
});

module.exports = app;
