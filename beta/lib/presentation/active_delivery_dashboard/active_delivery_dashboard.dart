import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './active_delivery_dashboard_initial_page.dart';

class ActiveDeliveryDashboard extends StatefulWidget {
  const ActiveDeliveryDashboard({super.key});

  @override
  ActiveDeliveryDashboardState createState() => ActiveDeliveryDashboardState();
}

class ActiveDeliveryDashboardState extends State<ActiveDeliveryDashboard> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  final List routes = [
    '/active-delivery-dashboard',
    '/route-declaration-screen',
    '/pickup-workflow-screen',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/active-delivery-dashboard',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/active-delivery-dashboard' || '/':
              return MaterialPageRoute(
                builder: (context) =>
                    const ActiveDeliveryDashboardInitialPage(),
                settings: settings,
              );
            default:
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
