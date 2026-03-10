import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

// Authentication state
class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? email;
  final String? userType;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.email,
    this.userType,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? email,
    String? userType,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Auth notifier for Courier
class CourierAuthNotifier extends StateNotifier<AuthState> {
  final ApiClient apiClient;

  CourierAuthNotifier(this.apiClient) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final token = await apiClient.getAuthToken();
      if (token != null) {
        state = state.copyWith(
          isLoggedIn: true,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
      );
    }
  }

  Future<void> registerCourier({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String vehicleType,
    required String vehicleNumber,
    required String licenseNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await apiClient.registerCourier(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
      );

      if (result['success'] == true) {
        // Save token if provided
        if (result['token'] != null) {
          await apiClient.saveAuthToken(result['token']);
        }

        // Extract user data
        final userId = result['userId'] ?? result['user']?['id'];
        final userType = result['user']?['userType'] ?? 'courier';

        state = state.copyWith(
          isLoggedIn: result['token'] != null, // Auto-login if token provided
          userId: userId,
          email: email,
          userType: userType,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await apiClient.login(
        email: email,
        password: password,
      );

      if (result['success'] == true && result['token'] != null) {
        state = state.copyWith(
          isLoggedIn: true,
          userId: result['userId'],
          email: result['email'],
          userType: result['userType'],
          isLoading: false,
          error: null,
        );
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await apiClient.logout();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

// Auth provider for Courier
final authProvider = StateNotifierProvider<CourierAuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CourierAuthNotifier(apiClient);
});

// Convenience selectors
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).userId;
});

final userEmailProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).email;
});

final userTypeProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).userType;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
