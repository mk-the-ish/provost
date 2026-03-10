import 'package:flutter/material.dart';
import '../presentation/live_tracking_map_screen/live_tracking_map_screen.dart';
import '../presentation/create_order_screen/create_order_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String liveTrackingMap = '/live-tracking-map-screen';
  static const String createOrder = '/create-order-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LiveTrackingMapScreen(),
    liveTrackingMap: (context) => const LiveTrackingMapScreen(),
    createOrder: (context) => const CreateOrderScreen(),
    // TODO: Add your other routes here
  };
}
