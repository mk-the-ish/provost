import '../presentation/profile_screen/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import '../presentation/pickup_workflow_screen/pickup_workflow_screen.dart';
import '../presentation/route_declaration_screen/route_declaration_screen.dart';
import '../presentation/active_delivery_dashboard/active_delivery_dashboard.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pickupWorkflow = '/pickup-workflow-screen';
  static const String routeDeclaration = '/route-declaration-screen';
  static const String activeDeliveryDashboard = '/active-delivery-dashboard';
  static const String profileScreen = '/profile-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const ActiveDeliveryDashboard(),
    pickupWorkflow: (context) => const PickupWorkflowScreen(),
    routeDeclaration: (context) => const RouteDeclarationScreen(),
    activeDeliveryDashboard: (context) => const ActiveDeliveryDashboard(),
    profileScreen: (context) => const ProfileScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    // TODO: Add your other routes here
  };
}
