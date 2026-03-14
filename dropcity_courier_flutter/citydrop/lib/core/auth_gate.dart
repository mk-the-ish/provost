import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state_provider.dart';
import '../screens/auth/login_screen.dart';
import '../presentation/active_delivery_dashboard/active_delivery_dashboard.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isLoading = ref.watch(authLoadingProvider);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!isLoggedIn) {
      return const LoginScreen();
    }
    return const ActiveDeliveryDashboard();
  }
}
