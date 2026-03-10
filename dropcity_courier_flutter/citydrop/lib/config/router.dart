import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/phone_verification_screen.dart';
import '../screens/home/home_screen_v2.dart';
import '../screens/route/route_declaration_screen_v2.dart';
import '../screens/matching/real_time_matching_screen.dart';
import '../screens/order/order_acceptance_screen_v2.dart';
import '../screens/delivery/delivery_tracking_screen_v2.dart';
import '../screens/delivery/offline_queue_monitor_screen.dart';
import '../screens/delivery/pickup_photo_screen.dart';
import '../screens/delivery/delivery_confirmation_screen.dart';

/// Global router configuration for DropCity Courier App
/// Uses GoRouter with Riverpod for state management

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isLoggedIn;
      final isLoggingIn = state.matchedLocation.startsWith('/login');

      // Not logged in and not on auth page → go to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // Logged in and on auth page → go to home
      if (isAuthenticated && isLoggingIn) {
        return '/home';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'phone-verification',
            name: 'phone-verification',
            builder: (context, state) {
              final phone = state.extra as String?;
              return PhoneVerificationScreen(phone: phone ?? '');
            },
          ),
        ],
      ),

      // Main App Routes (Nested under ShellRoute for persistent AppBar/BottomNav)
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            // Will add BottomNavigationBar in the shell if needed
          );
        },
        routes: [
          // Home / Dashboard
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreenV2(),
          ),

          // Route Declaration (Courier declares their route)
          GoRoute(
            path: '/route-declaration',
            name: 'route-declaration',
            builder: (context, state) => const RouteDeclarationScreenV2(),
          ),

          // Real-time Matching (Core feature - display matching orders)
          GoRoute(
            path: '/matching',
            name: 'matching',
            builder: (context, state) => const RealTimeMatchingScreen(),
          ),

          // Order Acceptance (Accept specific order)
          GoRoute(
            path: '/order-acceptance',
            name: 'order-acceptance',
            builder: (context, state) {
              final orderId = state.extra as String?;
              return OrderAcceptanceScreenV2(orderId: orderId ?? '');
            },
          ),

          // Delivery Tracking (Track active delivery with GPS & Maps)
          GoRoute(
            path: '/delivery-tracking',
            name: 'delivery-tracking',
            builder: (context, state) => const DeliveryTrackingScreenV2(),
          ),

          // Offline Queue Monitor
          GoRoute(
            path: '/offline-queue',
            name: 'offline-queue',
            builder: (context, state) => const OfflineQueueMonitorScreen(),
          ),

          // Pickup Photo Capture (Take photo at pickup location)
          GoRoute(
            path: '/pickup-photo',
            name: 'pickup-photo',
            builder: (context, state) {
              final params = state.extra as Map<String, String>?;
              return PickupPhotoScreen(
                orderId: params?['orderId'] ?? '',
                courierId: params?['courierId'] ?? '',
              );
            },
          ),

          // Delivery Confirmation (Capture delivery photo + verify PIN)
          GoRoute(
            path: '/delivery-confirmation',
            name: 'delivery-confirmation',
            builder: (context, state) {
              final params = state.extra as Map<String, String>?;
              return DeliveryConfirmationScreen(
                orderId: params?['orderId'] ?? '',
                courierId: params?['courierId'] ?? '',
                deliveryPin: params?['deliveryPin'] ?? '',
              );
            },
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Route not found: ${state.uri}'),
        ),
      );
    },
  );
});
