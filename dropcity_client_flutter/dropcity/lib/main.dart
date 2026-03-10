import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'config/router.dart';
import 'config/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp.router(
          title: 'DropCity Client',
          // ✅ Phase 5: Material 3 Theme Integration
          // Light theme with comprehensive Material 3 design system
          theme: AppTheme.lightTheme,
          // Dark theme (ready for implementation)
          darkTheme: AppTheme.darkTheme,
          // Default to light theme
          themeMode: ThemeMode.light,
          // ✅ Go Router Navigation Integration
          // Handles all routing and auth redirects
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}



