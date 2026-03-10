// ============================================================================
// App Export - Centralized Imports
// ============================================================================
// This file exports all commonly used dependencies and modules.
// Use: `import '../../core/app_export.dart';` in any screen or widget.
//
// Structure:
// - Flutter core imports (Material, Widgets)
// - Theme & Configuration
// - Riverpod state management
// - Router & Navigation
// - Custom utilities
// ============================================================================

// ============================================================================
// FLUTTER CORE IMPORTS
// ============================================================================
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';

// ============================================================================
// STATE MANAGEMENT (Riverpod)
// ============================================================================
export 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// NAVIGATION (Go Router)
// ============================================================================
export 'package:go_router/go_router.dart';

// ============================================================================
// RESPONSIVE DESIGN
// ============================================================================
export 'package:sizer/sizer.dart';

// ============================================================================
// CONFIGURATION
// ============================================================================
export '../config/theme.dart';
export '../config/router.dart';

// ============================================================================
// PROVIDERS
// ============================================================================
export '../providers/auth_state_provider.dart';

// ============================================================================
// CONSTANTS & UTILITIES
// ============================================================================
// Add constants here as needed

// ============================================================================
// CUSTOM EXCEPTIONS
// ============================================================================
// Add custom exceptions here as needed

// ============================================================================
// Usage Example:
// ============================================================================
// ```dart
// import '../../core/app_export.dart';
//
// class MyWidget extends ConsumerWidget {
//   const MyWidget({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(title: Text('Title')),
//       body: Container(
//         padding: EdgeInsets.all(4.w), // Sizer: 4% of width
//         child: Text('Hello', style: theme.textTheme.titleLarge),
//       ),
//     );
//   }
// }
// ```
// ============================================================================

