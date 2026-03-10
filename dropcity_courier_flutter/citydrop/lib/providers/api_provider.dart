import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

// Create a single instance of ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Get authentication token
final authTokenProvider = FutureProvider<String?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAuthToken();
});
