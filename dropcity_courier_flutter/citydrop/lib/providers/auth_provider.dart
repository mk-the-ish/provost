import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// AUTHENTICATION PROVIDERS
// =============================================================================

/// Manages authentication state and operations
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  final _supabase = Supabase.instance.client;

  /// Login with email and password (using Supabase to avoid Firebase reCAPTCHA issues)
  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  /// Register new courier account
  Future<void> registerCourier({
    required String email,
    required String password,
    required String phone,
    required String name,
    required String vehicleType,
    required int capacity,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Create Supabase Auth account
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = response.user!.id;

      // Create courier record in Supabase
      await _supabase.from('couriers').insert({
        'auth_id': userId,
        'email': email,
        'phone': phone,
        'name': name,
        'vehicle_type': vehicleType,
        'capacity': capacity,
        'is_online': false,
        'rating': 5.0,
      });

      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  /// Send phone verification OTP
  Future<String?> sendPhoneOtp(String phone) async {
    // Placeholder - would need Supabase phone auth setup
    state = AsyncValue.error('Phone auth not yet implemented', StackTrace.current);
    return null;
  }

  /// Verify phone OTP
  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String otp,
  }) async {
    // Placeholder - would need Supabase phone auth setup
    state = AsyncValue.error('Phone auth not yet implemented', StackTrace.current);
  }

  /// Logout
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  /// Update online status
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('couriers').update({
        'is_online': isOnline,
        'last_status_change': DateTime.now().toIso8601String(),
      }).eq('auth_id', user.id);
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

/// Current authentication user (from Supabase)
final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((data) => data.session?.user);
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user != null).value ?? false;
});
